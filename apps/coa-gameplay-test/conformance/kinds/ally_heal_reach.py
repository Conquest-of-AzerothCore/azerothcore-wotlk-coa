import math
from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import (BEHAVIOUR_METRIC_DELTA, RELOCATE_STEP_LIMIT_YD, behaviour_entry, prose_rule,
                        required_aura_steps, waited_ms)
from hits import base_mana_steps, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, dataset, facts_of

KIND = 'ally_heal_reach'
ORDER = 46

COUNT_METRIC = 'spell_heal_count'
TOTAL_METRIC = 'spell_heal_total'
EFFECTIVE_METRIC = 'spell_effective_heal_total'
READ_METRICS = {'count': COUNT_METRIC, 'total': TOTAL_METRIC, 'effective': EFFECTIVE_METRIC}
JUDGES_BY_NAME = ('reach', 'offsets', 'per_source', 'share')
CONTROL, TREATMENT = 'control', 'treatment'
DEFAULT_POLL_MS = 250
MAXIMUM_ALLIES = 7
PARTY_ALLIES = 4


@dataclass(frozen=True)
class ReachAlly:
    id: str
    dx: float
    dy: float
    grouped: bool = True
    health: int | None = None
    maximum: int | None = None


@dataclass(frozen=True)
class ReachCast:
    spell: int
    target: str
    watch_ms: int
    refill_power: int | None = None
    poll_ms: int = DEFAULT_POLL_MS
    end_ms: int = 0


@dataclass(frozen=True)
class ReachCheck:
    name: str
    judge: str
    spell: int
    quote: str
    reference: str | None = None
    minimum: int = 1
    healed: tuple[str, ...] = ()
    unhealed: tuple[str, ...] = ()
    witness_spell: int | None = None
    offsets: tuple[tuple[str, int], ...] = ()
    source: int | None = None
    per_event: int | None = None
    expected: float | None = None
    band: tuple[float, float] = (0.0, 0.0)
    band_reason: str = ''


@dataclass(frozen=True)
class AllyHealReachSpec:
    spell: int
    name: str
    quote: str
    allies: tuple[ReachAlly, ...]
    casts: tuple[ReachCast, ...]
    checks: tuple[ReachCheck, ...]
    gate_spell: int | None = None
    learn: tuple[int, ...] = ()


def reach_ally(raw: dict) -> ReachAlly:
    return ReachAlly(raw['id'], float(raw.get('dx', 0.0)), float(raw.get('dy', 0.0)), bool(raw.get('grouped', True)),
                     raw.get('health'), raw.get('maximum'))


def reach_cast(raw: dict) -> ReachCast:
    return ReachCast(int(raw['spell']), raw['target'], int(raw['watch_ms']), raw.get('refill_power'),
                     int(raw.get('poll_ms', DEFAULT_POLL_MS)), int(raw.get('end_ms', 0)))


def reach_check(raw: dict, quote: str) -> ReachCheck:
    band = raw.get('band', [0.0, 0.0])
    return ReachCheck(raw['name'], raw['judge'], int(raw['spell']), raw.get('quote', quote), raw.get('reference'),
                      int(raw.get('minimum', 1)), tuple(raw.get('healed', ())), tuple(raw.get('unhealed', ())),
                      raw.get('witness_spell'), tuple((ally, int(offset)) for ally, offset in
                                                      raw.get('offsets', {}).items()),
                      raw.get('source'), raw.get('per_event'), raw.get('expected'),
                      (float(band[0]), float(band[1])), raw.get('band_reason', ''))


def ally_heal_reach_spec(entry: dict) -> AllyHealReachSpec:
    spec = AllyHealReachSpec(entry['spell'], entry['name'], entry['quote'],
                             tuple(reach_ally(raw) for raw in entry['allies']),
                             tuple(reach_cast(raw) for raw in entry['casts']),
                             tuple(reach_check(raw, entry['quote']) for raw in entry['checks']),
                             entry.get('gate_spell'), tuple(int(spell) for spell in entry.get('learn', ())))
    validate(spec)
    return spec


def validate(spec: AllyHealReachSpec) -> None:
    ids = [ally.id for ally in spec.allies]
    if not ids or len(ids) > MAXIMUM_ALLIES or len(set(ids)) != len(ids) or CASTER in ids:
        raise ValueError(f'{spec.spell} {KIND} needs 1 to {MAXIMUM_ALLIES} allies with distinct ids other than '
                         f'{CASTER!r}')
    for ally in spec.allies:
        if (ally.health is None) != (ally.maximum is None) or (ally.health is not None and
                                                                not 0 < ally.health < ally.maximum):
            raise ValueError(f'{spec.spell} {KIND} ally {ally.id!r} sets health and maximum together, with the '
                             f'health below the maximum')
    if spec.gate_spell is not None and spec.gate_spell in spec.learn:
        raise ValueError(f'{spec.spell} {KIND} learns its gate spell {spec.gate_spell} before the control phase')
    if not spec.casts:
        raise ValueError(f'{spec.spell} {KIND} needs at least one cast')
    for cast in spec.casts:
        if cast.target not in ids and cast.target != CASTER:
            raise ValueError(f'{spec.spell} {KIND} cast {cast.spell} targets {cast.target!r}, not an ally')
        if cast.watch_ms <= 0 or cast.poll_ms < 25 or cast.watch_ms % cast.poll_ms:
            raise ValueError(f'{spec.spell} {KIND} cast {cast.spell} watches a positive whole number of polls of at '
                             f'least 25 ms')
    names = [check.name for check in spec.checks]
    if not names or len(set(names)) != len(names):
        raise ValueError(f'{spec.spell} {KIND} needs checks with distinct names')
    for check in spec.checks:
        known = set(ids)
        if check.judge not in JUDGES_BY_NAME:
            raise ValueError(f'{spec.spell} {KIND} check {check.name} judge {check.judge!r} is not one of '
                             f'{JUDGES_BY_NAME}')
        named = set(check.healed) | set(check.unhealed) | {ally for ally, _ in check.offsets}
        if check.reference is not None:
            named.add(check.reference)
        if not named <= known:
            raise ValueError(f'{spec.spell} {KIND} check {check.name} names unknown allies {sorted(named - known)}')
        if check.judge == 'reach' and (not check.healed or check.reference is None):
            raise ValueError(f'{spec.spell} {KIND} check {check.name} needs healed allies and a reference ally')
        if check.judge == 'offsets' and (not check.offsets or check.reference is None or check.minimum < 2):
            raise ValueError(f'{spec.spell} {KIND} check {check.name} needs offsets, a reference ally and a minimum '
                             f'of at least 2')
        if check.judge == 'per_source' and (check.source is None or not check.per_event):
            raise ValueError(f'{spec.spell} {KIND} check {check.name} needs a source spell and a per_event count')
        if check.judge == 'share' and (check.source is None or check.expected is None or not check.band_reason
                                       or check.band[0] > check.band[1]):
            raise ValueError(f'{spec.spell} {KIND} check {check.name} needs a source spell, an expected share and a '
                             f'stated band with its reason')
        if check.judge in ('per_source', 'share') and spec.gate_spell is None:
            raise ValueError(f'{spec.spell} {KIND} check {check.name} needs a gate_spell: its control phase reads '
                             f'the heal without the gate')


def phases(spec: AllyHealReachSpec) -> tuple[str, ...]:
    return (CONTROL, TREATMENT) if spec.gate_spell is not None else (TREATMENT,)


def read_spells(spec: AllyHealReachSpec) -> tuple[int, ...]:
    spells = []
    for check in spec.checks:
        for spell in (check.spell, check.source, check.witness_spell):
            if spell is not None and spell not in spells:
                spells.append(int(spell))
    return tuple(spells)


def read_label(spec: AllyHealReachSpec, phase: str, moment: str, ally: str, spell: int, field: str) -> str:
    return f'{spec.spell} {KIND} {phase} {moment} {ally} {spell} {field}'


def position_steps(ally: ReachAlly) -> list[dict]:
    chunks = math.ceil(max(abs(ally.dx), abs(ally.dy)) / RELOCATE_STEP_LIMIT_YD)
    return [{'action': 'relocate', 'actor': ally.id, 'dx': ally.dx / chunks, 'dy': ally.dy / chunks}
            for _ in range(chunks)]


def read_steps(spec: AllyHealReachSpec, phase: str, moment: str) -> list[dict]:
    return [measurement(read_label(spec, phase, moment, ally.id, spell, field), CASTER, metric, spell=spell,
                        target=ally.id)
            for ally in spec.allies for spell in read_spells(spec) for field, metric in READ_METRICS.items()]


def cast_steps(class_file: dict, records: Records, cast: ReachCast) -> list[dict]:
    facts = facts_of(records, cast.spell)
    steps = base_mana_steps(class_file, facts)
    if not steps and facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
        steps = [{'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': facts.mana_cost}]
    steps += [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': cast.spell}]
    steps += [{**step, 'actor': CASTER} for step in required_aura_steps(facts)]
    steps.append({'action': 'cast', 'actor': CASTER, 'spell': cast.spell, 'target': cast.target})
    for _ in range(cast.watch_ms // cast.poll_ms):
        steps.append({'action': 'wait', 'label': f'{KIND} watch', 'ms': cast.poll_ms})
        if cast.refill_power is not None:
            steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                          'value': int(cast.refill_power)})
    return steps


def health_steps(spec: AllyHealReachSpec) -> list[dict]:
    return [{'action': 'set_health', 'actor': ally.id, 'value': int(ally.health), 'maximum': int(ally.maximum)}
            for ally in spec.allies if ally.health is not None]


def phase_steps(class_file: dict, records: Records, spec: AllyHealReachSpec, phase: str) -> list[dict]:
    steps = health_steps(spec) + read_steps(spec, phase, 'start')
    for cast in spec.casts:
        steps += cast_steps(class_file, records, cast)
    steps += read_steps(spec, phase, 'end')
    for cast in spec.casts:
        if cast.end_ms:
            steps.append({'action': 'wait', 'label': f'{KIND} end', 'ms': cast.end_ms})
    return steps


def reads_model(spec: AllyHealReachSpec) -> dict:
    return {phase: {ally.id: {str(spell): {field: [read_label(spec, phase, 'start', ally.id, spell, field),
                                                   read_label(spec, phase, 'end', ally.id, spell, field)]
                                           for field in READ_METRICS}
                              for spell in read_spells(spec)}
                    for ally in spec.allies}
            for phase in phases(spec)}


def check_label(spec: AllyHealReachSpec, check: ReachCheck) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {check.name}'


def check_model(spec: AllyHealReachSpec, check: ReachCheck, reads: dict) -> dict:
    return {'kind': KIND, 'metric': TOTAL_METRIC if check.judge == 'share' else COUNT_METRIC, 'quote': check.quote,
            'judge': check.judge, 'spell': check.spell, 'reference': check.reference, 'minimum': check.minimum,
            'healed': list(check.healed), 'unhealed': list(check.unhealed), 'witness_spell': check.witness_spell,
            'offsets': dict(check.offsets), 'source': check.source, 'per_event': check.per_event,
            'expected': check.expected, 'band': list(check.band), 'band_reason': check.band_reason,
            'allies': [ally.id for ally in spec.allies], 'phases': list(phases(spec)), 'reads': reads}


def ally_heal_reach_scenario(class_file: dict, spec: AllyHealReachSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    for check in spec.checks:
        behaviour_entry(records, spec.spell, spec.name, KIND, check.quote, float(check.expected or 0))
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
        steps += phase_steps(class_file, records, spec, phase)
    layout = '; '.join(f'{ally.id} at ({ally.dx:g}, {ally.dy:g}) yd'
                       + ('' if ally.grouped else ' ungrouped')
                       + (f', health {ally.health} of {ally.maximum}' if ally.health is not None else '')
                       for ally in spec.allies)
    casts = '; '.join(f'{cast.spell} at {cast.target}, watched {cast.watch_ms} ms'
                      + (f' with the power refilled to {cast.refill_power} every {cast.poll_ms} ms'
                         if cast.refill_power is not None else '')
                      for cast in spec.casts)
    gate = (f' The control phase runs without {spec.gate_spell}; it is learned before the treatment phase.'
            if spec.gate_spell is not None else ' One treatment phase, no gate.')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour ally heal reach',
        'contract': (f'Ally players placed from the caster: {layout}. Real casts per phase: {casts}. Every ally\'s '
                     f'heal count, total and effective total of {list(read_spells(spec))} from the caster are read at '
                     f'the start and the end of each phase window, and each check judges the window\'s '
                     f'increments.{gate}{required_aura_text(records, spec)}{raid_text(spec)}'),
        'players': [player_fixture(class_file)] + allies,
        'steps': steps}
    reads = reads_model(spec)
    expectations = [Expectation(check_label(spec, check), BEHAVIOUR_METRIC_DELTA, spec.spell, check.spell, None,
                                expected_text(check), prose_rule(check.quote, spec.spell),
                                check_model(spec, check, reads))
                    for check in spec.checks]
    return timed(scenario, waited_ms(steps)), expectations


def required_auras(records: Records, spec: AllyHealReachSpec) -> dict[int, int]:
    found = {}
    for cast in spec.casts:
        aura = facts_of(records, cast.spell).caster_aura_spell
        if aura:
            found.setdefault(cast.spell, int(aura))
    return found


def required_aura_text(records: Records, spec: AllyHealReachSpec) -> str:
    auras = required_auras(records, spec)
    if not auras:
        return ''
    named = ', '.join(f'{aura} before each {spell}' for spell, aura in auras.items())
    return (f' Precondition fixtures: the CasterAuraSpell of a cast is set on the caster with set_aura before that '
            f'cast ({named}), so the cast is not refused for its caster aura; that aura is not the subject of any '
            f'check.')


def raid_text(spec: AllyHealReachSpec) -> str:
    grouped = [ally.id for ally in spec.allies if ally.grouped]
    if len(grouped) <= PARTY_ALLIES:
        return ''
    return (f' {len(grouped)} grouped allies exceed a party: the harness group step converts the full party to a raid '
            f'before it adds {grouped[PARTY_ALLIES]}, which joins another raid subgroup, so a party-only search does '
            f'not see {grouped[PARTY_ALLIES:]}.')


def expected_text(check: ReachCheck) -> str:
    if check.judge == 'reach':
        return str(len(check.healed))
    if check.judge == 'offsets':
        return ', '.join(f'{ally} {offset:+d}' for ally, offset in check.offsets)
    if check.judge == 'per_source':
        return str(check.per_event)
    return f'{check.expected:g}'


def increment(run, model: dict, phase: str, ally: str, spell: int, field: str) -> float | str:
    start, end = model['reads'][phase][ally][str(spell)][field]
    for label in (start, end):
        if run.values.get(label) is None:
            from compare import missing_measurement
            return missing_measurement(run, label)
    return float(run.values[end]) - float(run.values[start])


def increments(run, model: dict, phase: str, spell: int, field: str = 'count') -> dict[str, float] | str:
    found = {}
    for ally in model['allies']:
        value = increment(run, model, phase, ally, spell, field)
        if isinstance(value, str):
            return value
        found[ally] = value
    return found


def control_heals(run, model: dict, spell: int) -> dict[str, float] | str | None:
    if CONTROL not in model['phases']:
        return None
    return increments(run, model, CONTROL, spell)


def listed(counts: dict[str, float]) -> str:
    return ', '.join(f'{ally} {value:g}' for ally, value in counts.items())


def reach_verdict(base, run, model: dict):
    spell, reference = model['spell'], model['reference']
    treatment = increments(run, model, TREATMENT, spell)
    if isinstance(treatment, str):
        return replace(base, explanation=treatment)
    anchor_spell = model['witness_spell'] or spell
    anchor = increments(run, model, TREATMENT, anchor_spell)
    if isinstance(anchor, str):
        return replace(base, explanation=anchor)
    if anchor[reference] < model['minimum']:
        return replace(base, status='unmeasured', measured=anchor[reference],
                       explanation=f'reference {reference} took {anchor[reference]:g} heals of {anchor_spell} in the '
                                   f'treatment window, fewer than {model["minimum"]}: the cast did not run')
    unreached = [ally for ally in model['unhealed'] if model['witness_spell'] and anchor[ally] <= 0]
    if unreached:
        return replace(base, status='unmeasured',
                       explanation=f'{unreached} took no {anchor_spell} heal, so their 0 {spell} heals do not show a '
                                   f'selection: they were not reachable')
    control = control_heals(run, model, spell)
    if isinstance(control, str):
        return replace(base, explanation=control)
    healed = [ally for ally in model['healed'] if treatment[ally] > 0]
    wrong = [ally for ally in model['unhealed'] if treatment[ally] != 0]
    leaked = [ally for ally, value in (control or {}).items() if value != 0]
    status = 'ok' if len(healed) == len(model['healed']) and not wrong and not leaked else 'alert'
    control_text = (f'; control phase without the gate: {listed(control)} (all must be 0)' if control is not None
                    else '')
    unwitnessed = (f'; no witness spell: the 0 of {model["unhealed"]} does not exclude a line of sight or placement '
                   f'fault' if model['unhealed'] and not model['witness_spell'] else '')
    return replace(base, status=status, measured=float(len(healed)), expected=float(len(model['healed'])),
                   low=float(len(model['healed'])), high=float(len(model['healed'])),
                   explanation=f'treatment heals of {spell}: {listed(treatment)}; {model["healed"]} must each take at '
                               f'least one, {model["unhealed"]} none{control_text}; a count is compared '
                               f'exactly{unwitnessed}')


def offsets_verdict(base, run, model: dict):
    spell, reference = model['spell'], model['reference']
    treatment = increments(run, model, TREATMENT, spell)
    if isinstance(treatment, str):
        return replace(base, explanation=treatment)
    anchor = treatment[reference]
    if anchor < model['minimum']:
        return replace(base, status='unmeasured', measured=anchor,
                       explanation=f'reference {reference} took {anchor:g} heals of {spell}, fewer than '
                                   f'{model["minimum"]}: an offset cannot be told from a missing heal')
    wrong = {ally: treatment[ally] - anchor for ally, offset in model['offsets'].items()
             if treatment[ally] - anchor != offset}
    status = 'ok' if not wrong else 'alert'
    return replace(base, status=status, measured=anchor, expected=anchor, low=anchor, high=anchor,
                   explanation=f'treatment heals of {spell}: {listed(treatment)}; against reference {reference} '
                               f'({anchor:g}) each ally must read its offset {model["offsets"]}'
                               + (f'; read offsets {wrong}' if wrong else '') + '; counts are compared exactly')


def per_source_verdict(base, run, model: dict):
    spell, source = model['spell'], model['source']
    treatment = increments(run, model, TREATMENT, spell)
    sources = increments(run, model, TREATMENT, source)
    totals = increments(run, model, TREATMENT, source, 'total')
    effective = increments(run, model, TREATMENT, source, 'effective')
    for value in (treatment, sources, totals, effective):
        if isinstance(value, str):
            return replace(base, explanation=value)
    source_events = sum(sources.values())
    if source_events < model['minimum']:
        return replace(base, status='unmeasured', measured=source_events,
                       explanation=f'{source_events:g} heals of {source}, fewer than {model["minimum"]}')
    if sum(totals.values()) != sum(effective.values()):
        return replace(base, status='unmeasured',
                       explanation=f'{source} overhealed ({sum(totals.values()) - sum(effective.values()):g}): an '
                                   f'overheal can leave no effective healing to share, so the count per heal is not '
                                   f'judged')
    control = control_heals(run, model, spell)
    if isinstance(control, str):
        return replace(base, explanation=control)
    expected = float(model['per_event']) * source_events
    measured = sum(treatment.values())
    leaked = sum((control or {}).values())
    status = 'ok' if measured == expected and leaked == 0 else 'alert'
    return replace(base, status=status, measured=measured, expected=expected, low=expected, high=expected,
                   explanation=f'{measured:g} heals of {spell} ({listed(treatment)}) for {source_events:g} heals of '
                               f'{source}: {model["per_event"]} per heal gives {expected:g}; control phase '
                               f'{leaked:g} (must be 0); a count is compared exactly')


def share_verdict(base, run, model: dict):
    spell, source = model['spell'], model['source']
    reads = {}
    for name, (read_spell, field) in {'count': (spell, 'count'), 'total': (spell, 'total'),
                                      'source_count': (source, 'count'),
                                      'source_effective': (source, 'effective')}.items():
        value = increments(run, model, TREATMENT, read_spell, field)
        if isinstance(value, str):
            return replace(base, explanation=value)
        reads[name] = sum(value.values())
    if reads['count'] < model['minimum'] or reads['source_count'] < model['minimum']:
        return replace(base, status='unmeasured', measured=reads['count'],
                       explanation=f'{reads["count"]:g} heals of {spell} and {reads["source_count"]:g} of {source}, '
                                   f'fewer than {model["minimum"]}')
    control = control_heals(run, model, spell)
    if isinstance(control, str):
        return replace(base, explanation=control)
    mean = reads['total'] / reads['count']
    source_mean = reads['source_effective'] / reads['source_count']
    centre = float(model['expected']) * source_mean
    low, high = centre + model['band'][0], centre + model['band'][1]
    leaked = sum((control or {}).values())
    status = 'ok' if low - 1e-9 <= mean <= high + 1e-9 and leaked == 0 else 'alert'
    return replace(base, status=status, measured=mean, expected=centre, low=low, high=high,
                   explanation=f'mean {spell} heal {mean:g} over {reads["count"]:g} heals against '
                               f'{model["expected"]:g} x the mean effective {source} heal {source_mean:g} '
                               f'({reads["source_count"]:g} heals) = {centre:g}, band [{low:g}, {high:g}] '
                               f'({model["band_reason"]}); control phase {leaked:g} heals of {spell} (must be 0); '
                               f'ratio {mean / source_mean:.4f}')


VERDICTS = {'reach': reach_verdict, 'offsets': offsets_verdict, 'per_source': per_source_verdict,
            'share': share_verdict}


def ally_heal_reach_verdict(base, run, model: dict):
    return VERDICTS[model['judge']](base, run, model)


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return ally_heal_reach_scenario(class_file, ally_heal_reach_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} {BEHAVIOUR_METRIC_DELTA} {check['name']}" for check in entry['checks']]


JUDGES = {BEHAVIOUR_METRIC_DELTA: ally_heal_reach_verdict}
