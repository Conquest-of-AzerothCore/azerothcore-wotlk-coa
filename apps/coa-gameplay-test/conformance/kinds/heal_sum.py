from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, waited_ms
from hits import timed
from kinds.ally_heal_reach import (ReachAlly, ReachCast, cast_steps, health_steps, position_steps, reach_ally,
                                   reach_cast, required_aura_text)
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, dataset

KIND = 'heal_sum'
ORDER = 47

READ_METRICS = {'count': 'spell_heal_count', 'total': 'spell_heal_total', 'effective': 'spell_effective_heal_total'}
JUDGES_BY_NAME = ('cap', 'pair')
WITNESS_PHASES = ('control', 'treatment')
CONTROL, TREATMENT = 'control', 'treatment'
MAXIMUM_ALLIES = 7
MAXIMUM_CREATURES = 8
FRIENDLY_FACTION = 35
CREATURE_LEVEL = 60


@dataclass(frozen=True)
class SumCreature:
    id: str
    entry: int
    distance: float
    faction: int = FRIENDLY_FACTION


@dataclass(frozen=True)
class SumCheck:
    name: str
    judge: str
    spell: int
    quote: str
    expected: float
    control_expected: int | None = None
    witness: str | None = None
    on: str | None = None
    source: int | None = None
    source_on: str | None = None
    band: tuple[float, float] = (0.0, 0.0)
    band_reason: str = ''


@dataclass(frozen=True)
class HealSumSpec:
    spell: int
    name: str
    quote: str
    allies: tuple[ReachAlly, ...]
    creatures: tuple[SumCreature, ...]
    casts: tuple[ReachCast, ...]
    checks: tuple[SumCheck, ...]
    gate_spell: int | None = None
    learn: tuple[int, ...] = ()
    caster_health: tuple[int, int] | None = None


def sum_creature(raw: dict) -> SumCreature:
    return SumCreature(raw['id'], int(raw['entry']), float(raw['distance']), int(raw.get('faction', FRIENDLY_FACTION)))


def sum_check(raw: dict, quote: str) -> SumCheck:
    band = raw.get('band', [0.0, 0.0])
    control = raw.get('control_expected')
    return SumCheck(raw['name'], raw['judge'], int(raw['spell']), raw.get('quote', quote), float(raw['expected']),
                    None if control is None else int(control), raw.get('witness'), raw.get('on'),
                    None if raw.get('source') is None else int(raw['source']), raw.get('source_on'),
                    (float(band[0]), float(band[1])), raw.get('band_reason', ''))


def heal_sum_spec(entry: dict) -> HealSumSpec:
    spec = HealSumSpec(entry['spell'], entry['name'], entry['quote'],
                       tuple(reach_ally(raw) for raw in entry.get('allies', ())),
                       tuple(sum_creature(raw) for raw in entry.get('creatures', ())),
                       tuple(reach_cast(raw) for raw in entry['casts']),
                       tuple(sum_check(raw, entry['quote']) for raw in entry['checks']),
                       entry.get('gate_spell'), tuple(int(spell) for spell in entry.get('learn', ())))
    validate(spec)
    return spec


def unit_ids(spec: HealSumSpec) -> list[str]:
    return [CASTER, *(ally.id for ally in spec.allies), *(creature.id for creature in spec.creatures)]


def validate(spec: HealSumSpec) -> None:
    ids = unit_ids(spec)
    if len(set(ids)) != len(ids) or len(ids) < 2:
        raise ValueError(f'{spec.spell} {KIND} needs allies or creatures with distinct ids other than {CASTER!r}')
    if len(spec.allies) > MAXIMUM_ALLIES or len(spec.creatures) > MAXIMUM_CREATURES:
        raise ValueError(f'{spec.spell} {KIND} holds at most {MAXIMUM_ALLIES} allies and {MAXIMUM_CREATURES} '
                         f'creatures')
    for ally in spec.allies:
        if (ally.health is None) != (ally.maximum is None) or (ally.health is not None and
                                                                not 0 < ally.health < ally.maximum):
            raise ValueError(f'{spec.spell} {KIND} ally {ally.id!r} sets health and maximum together, with the '
                             f'health below the maximum')
    for creature in spec.creatures:
        if creature.entry < 1 or not 0 < creature.distance <= 30:
            raise ValueError(f'{spec.spell} {KIND} creature {creature.id!r} needs an entry and a distance in (0, 30]')
    if spec.gate_spell is not None and spec.gate_spell in spec.learn:
        raise ValueError(f'{spec.spell} {KIND} learns its gate spell {spec.gate_spell} before the control phase')
    if not spec.casts:
        raise ValueError(f'{spec.spell} {KIND} needs at least one cast')
    for cast in spec.casts:
        if cast.target not in ids[:1 + len(spec.allies)]:
            raise ValueError(f'{spec.spell} {KIND} cast {cast.spell} targets {cast.target!r}, not the caster or an '
                             f'ally')
        if cast.watch_ms <= 0 or cast.poll_ms < 25 or cast.watch_ms % cast.poll_ms:
            raise ValueError(f'{spec.spell} {KIND} cast {cast.spell} watches a positive whole number of polls of at '
                             f'least 25 ms')
    names = [check.name for check in spec.checks]
    if not names or len(set(names)) != len(names):
        raise ValueError(f'{spec.spell} {KIND} needs checks with distinct names')
    for check in spec.checks:
        if check.judge not in JUDGES_BY_NAME:
            raise ValueError(f'{spec.spell} {KIND} check {check.name} judge {check.judge!r} is not one of '
                             f'{JUDGES_BY_NAME}')
        if (check.control_expected is not None) != (spec.gate_spell is not None and check.judge == 'cap'):
            raise ValueError(f'{spec.spell} {KIND} check {check.name} states a control total exactly when a cap '
                             f'check has a gate')
        if check.judge == 'cap' and (check.witness not in WITNESS_PHASES or check.expected < 0 or
                                     check.expected != int(check.expected) or
                                     (check.witness == CONTROL and spec.gate_spell is None)):
            raise ValueError(f'{spec.spell} {KIND} check {check.name} needs a whole expected total and a witness '
                             f'phase of {WITNESS_PHASES} that the entry runs')
        if check.judge == 'pair' and (check.on not in ids or check.source_on not in ids or check.source is None
                                      or check.expected <= 0 or not check.band_reason
                                      or check.band[0] > check.band[1]):
            raise ValueError(f'{spec.spell} {KIND} check {check.name} needs the units on and source_on, a source '
                             f'spell, a positive expected share and a stated band with its reason')


def phases(spec: HealSumSpec) -> tuple[str, ...]:
    return (CONTROL, TREATMENT) if spec.gate_spell is not None else (TREATMENT,)


def read_spells(spec: HealSumSpec) -> tuple[int, ...]:
    spells = []
    for check in spec.checks:
        for spell in (check.spell, check.source):
            if spell is not None and spell not in spells:
                spells.append(int(spell))
    return tuple(spells)


def read_label(spec: HealSumSpec, phase: str, moment: str, unit: str, spell: int, field: str) -> str:
    return f'{spec.spell} {KIND} {phase} {moment} {unit} {spell} {field}'


def read_steps(spec: HealSumSpec, phase: str, moment: str) -> list[dict]:
    return [measurement(read_label(spec, phase, moment, unit, spell, field), CASTER, metric, spell=spell,
                        target=unit)
            for unit in unit_ids(spec) for spell in read_spells(spec) for field, metric in READ_METRICS.items()]


def reads_model(spec: HealSumSpec) -> dict:
    return {phase: {unit: {str(spell): {field: [read_label(spec, phase, 'start', unit, spell, field),
                                                read_label(spec, phase, 'end', unit, spell, field)]
                                        for field in READ_METRICS}
                           for spell in read_spells(spec)}
                    for unit in unit_ids(spec)}
            for phase in phases(spec)}


def creature_fixture(creature: SumCreature) -> dict:
    return {'id': creature.id, 'owner': CASTER, 'entry': creature.entry, 'distance': creature.distance,
            'faction': creature.faction, 'level': CREATURE_LEVEL}


def heal_sum_scenario(class_file: dict, spec: HealSumSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    for check in spec.checks:
        behaviour_entry(records, spec.spell, spec.name, KIND, check.quote, check.expected)
    allies = [{**player_fixture(class_file), 'id': ally.id,
               **({'allow_regeneration': False} if ally.health is not None else {})} for ally in spec.allies]
    steps = base_steps(class_file)
    for ally in spec.allies:
        steps += position_steps(ally)
        if ally.grouped:
            steps.append({'action': 'group', 'actor': CASTER, 'target': ally.id})
    for spell in dict.fromkeys([*spec.learn, *(cast.spell for cast in spec.casts)]):
        steps.append({'action': 'learn', 'actor': CASTER, 'spell': spell})
    for phase in phases(spec):
        if phase == TREATMENT and spec.gate_spell is not None:
            steps.append({'action': 'learn', 'actor': CASTER, 'spell': spec.gate_spell})
        steps += health_steps(spec) + read_steps(spec, phase, 'start')
        for index, cast in enumerate(spec.casts):
            steps += cast_steps(class_file, records, cast, spec, phase, index)
        steps += read_steps(spec, phase, 'end')
        for cast in spec.casts:
            if cast.end_ms:
                steps.append({'action': 'wait', 'label': f'{KIND} end', 'ms': cast.end_ms})
    layout = '; '.join([f'{ally.id} at ({ally.dx:g}, {ally.dy:g}) yd' + ('' if ally.grouped else ' ungrouped')
                        + (f', health {ally.health} of {ally.maximum}' if ally.health is not None else '')
                        for ally in spec.allies] +
                       [f'{creature.id} (creature {creature.entry}, faction {creature.faction}) {creature.distance:g} '
                        f'yd along x' for creature in spec.creatures])
    casts = '; '.join(f'{cast.spell} at {cast.target}, watched {cast.watch_ms} ms' for cast in spec.casts)
    gate = (f' The control phase runs without {spec.gate_spell}; it is learned before the treatment phase.'
            if spec.gate_spell is not None else ' One treatment phase, no gate.')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour heal sum',
        'contract': (f'Units placed from the caster: {layout}. Real casts per phase: {casts}. The heal count, total '
                     f'and effective total of {list(read_spells(spec))} from the caster on the caster and on every '
                     f'unit are read at the start and the end of each phase window, and each check judges the '
                     f'window\'s increments summed over the units or paired between two units.{gate}'
                     f'{required_aura_text(records, spec)}'),
        'players': [player_fixture(class_file)] + allies,
        'steps': steps}
    if spec.creatures:
        scenario['creatures'] = [creature_fixture(creature) for creature in spec.creatures]
    reads = reads_model(spec)
    expectations = [Expectation(check_label(spec, check), BEHAVIOUR_METRIC_DELTA, spec.spell, check.spell, None,
                                f'{check.expected:g}', prose_rule(check.quote, spec.spell),
                                check_model(spec, check, reads))
                    for check in spec.checks]
    return timed(scenario, waited_ms(steps)), expectations


def check_label(spec: HealSumSpec, check: SumCheck) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {check.name}'


def check_model(spec: HealSumSpec, check: SumCheck, reads: dict) -> dict:
    model = {'kind': KIND, 'metric': READ_METRICS['count'] if check.judge == 'cap' else READ_METRICS['total'],
             'quote': check.quote, 'judge': check.judge, 'spell': check.spell, 'expected': check.expected,
             'units': unit_ids(spec), 'phases': list(phases(spec)), 'reads': reads}
    if check.judge == 'cap':
        model.update({'control_expected': check.control_expected, 'witness': check.witness})
    else:
        model.update({'on': check.on, 'source': check.source, 'source_on': check.source_on,
                      'band': list(check.band), 'band_reason': check.band_reason})
    return model


def increment(run, model: dict, phase: str, unit: str, spell: int, field: str) -> float | str:
    start, end = model['reads'][phase][unit][str(spell)][field]
    for label in (start, end):
        if run.values.get(label) is None:
            from compare import missing_measurement
            return missing_measurement(run, label)
    return float(run.values[end]) - float(run.values[start])


def increments(run, model: dict, phase: str, spell: int, field: str = 'count') -> dict[str, float] | str:
    found = {}
    for unit in model['units']:
        value = increment(run, model, phase, unit, spell, field)
        if isinstance(value, str):
            return value
        found[unit] = value
    return found


def listed(counts: dict[str, float]) -> str:
    return ', '.join(f'{unit} {value:g}' for unit, value in counts.items())


def cap_verdict(base, run, model: dict):
    spell = model['spell']
    treatment = increments(run, model, TREATMENT, spell)
    if isinstance(treatment, str):
        return replace(base, explanation=treatment)
    control = increments(run, model, CONTROL, spell) if CONTROL in model['phases'] else None
    if isinstance(control, str):
        return replace(base, explanation=control)
    witnessed = control if model['witness'] == CONTROL else treatment
    unreached = [unit for unit, value in witnessed.items() if value < 1]
    if unreached:
        return replace(base, status='unmeasured',
                       explanation=f'{unreached} took no {spell} heal in the {model["witness"]} window ('
                                   f'{listed(witnessed)}): a unit no heal reaches does not show a cap')
    total = sum(treatment.values())
    control_total = None if control is None else sum(control.values())
    status = 'ok' if total == model['expected'] and (control is None or
                                                       control_total == model['control_expected']) else 'alert'
    control_text = ('' if control is None else
                    f'; control window without the gate {control_total:g} ({listed(control)}), expected '
                    f'{model["control_expected"]}')
    return replace(base, status=status, measured=total, expected=model['expected'], low=model['expected'],
                   high=model['expected'],
                   explanation=f'treatment heals of {spell}: {total:g} ({listed(treatment)}), expected '
                               f'{model["expected"]:g}{control_text}; every unit took a heal in the '
                               f'{model["witness"]} window, so each was a candidate; counts are compared exactly')


def pair_verdict(base, run, model: dict):
    spell, source = model['spell'], model['source']
    reads = {}
    for name, (phase, unit, read_spell, field) in {
            'measured': (TREATMENT, model['on'], spell, 'total'),
            'source_count': (TREATMENT, model['source_on'], source, 'count'),
            'source_total': (TREATMENT, model['source_on'], source, 'total'),
            'source_effective': (TREATMENT, model['source_on'], source, 'effective')}.items():
        value = increment(run, model, phase, unit, read_spell, field)
        if isinstance(value, str):
            return replace(base, explanation=value)
        reads[name] = value
    if reads['source_count'] < 1:
        return replace(base, status='unmeasured', measured=reads['measured'],
                       explanation=f'{model["source_on"]} took no {source} heal: nothing to pair')
    if reads['source_total'] != reads['source_effective']:
        return replace(base, status='unmeasured', measured=reads['measured'],
                       explanation=f'{source} overhealed {model["source_on"]} by '
                                   f'{reads["source_total"] - reads["source_effective"]:g}: the healing done is not '
                                   f'the heal amount')
    control = (increment(run, model, CONTROL, model['on'], spell, 'total') if CONTROL in model['phases'] else 0.0)
    if isinstance(control, str):
        return replace(base, explanation=control)
    centre = model['expected'] * reads['source_effective']
    low, high = centre + model['band'][0], centre + model['band'][1]
    status = 'ok' if low - 1e-9 <= reads['measured'] <= high + 1e-9 and control == 0 else 'alert'
    return replace(base, status=status, measured=reads['measured'], expected=centre, low=low, high=high,
                   explanation=f'{spell} healed {model["on"]} for {reads["measured"]:g} in the treatment window '
                               f'against {model["expected"]:g} x the {reads["source_effective"]:g} effective '
                               f'healing of {source} on {model["source_on"]} ({reads["source_count"]:g} heals) = '
                               f'{centre:g}, band [{low:g}, {high:g}] ({model["band_reason"]}); control window '
                               f'{control:g} (must be 0)')


VERDICTS = {'cap': cap_verdict, 'pair': pair_verdict}


def heal_sum_verdict(base, run, model: dict):
    return VERDICTS[model['judge']](base, run, model)


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return heal_sum_scenario(class_file, heal_sum_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} {BEHAVIOUR_METRIC_DELTA} {check['name']}" for check in entry['checks']]


JUDGES = {BEHAVIOUR_METRIC_DELTA: heal_sum_verdict}
