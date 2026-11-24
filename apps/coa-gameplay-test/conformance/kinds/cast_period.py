from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, reagent_steps, waited_ms
from bonus import bonus_band
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import (FORCE_CRIT_RATINGS, FORCED_CRIT_RATING, Expectation, TARGET, dataset, facts_of,
                    required_aura_steps)

KIND = 'cast_period'
ORDER = 5


CAST_PERIOD_METRIC = 'owned_creature_spell_cast_count'
CAST_PERIOD_MINIMUM_CASTS = 3
ARMS = ('treatment', 'control')
OWNED_AURA_METRIC = 'owned_creature_count'
CRIT_METRIC = 'spell_damage_count'
FIXTURE_METRIC = 'aura'
TEN_PERCENT_OFF = (0.9, 1.1)
ARM_EVENTS = 3


@dataclass(frozen=True)
class CastPeriodSpec:
    spell: int
    name: str
    quote: str
    setup_spell: int
    setup_wait_ms: int
    trigger_spell: int
    entry: int
    cast_spell: int
    expected_ms: int
    control_ms: int
    window_ms: int
    poll_ms: int = 100
    label_suffix: str = 'cast_period'
    minion_auras: tuple[tuple[int, int, int], ...] = ()
    casts_per_event: int = 1
    gaps_ms: tuple[int, ...] = ()
    pet_attack: bool = False
    force_crit: str | None = None
    learn: tuple[int, ...] = ()
    caster_auras: tuple[tuple[int, int], ...] = ()
    arm: str | None = None
    gap_reduction_ms: int | None = None
    owned_aura: tuple[int, int, int] | None = None
    aura_quote: str | None = None
    aura_expiry: tuple[int, int] | None = None


def minion_auras_of(raw) -> tuple[tuple[int, int, int], ...]:
    found = tuple(tuple(item) for item in raw)
    if any(len(item) != 3 or not all(type(value) is int and value > 0 for value in item) for item in found):
        raise ValueError(f'cast_period minion_auras are [spell, owned entry, ms after the trigger], positive '
                         f'integers, not {raw!r}')
    return found


def caster_auras_of(raw) -> tuple[tuple[int, int], ...]:
    found = tuple(tuple(item) for item in raw)
    if any(len(item) != 2 or not all(type(value) is int and value > 0 for value in item) for item in found):
        raise ValueError(f'cast_period caster_auras are [spell, stacks], positive integers, not {raw!r}')
    return found


def owned_aura_of(raw) -> tuple[int, int, int] | None:
    if raw is None:
        return None
    found = tuple(raw)
    if len(found) != 3 or not all(type(value) is int and value > 0 for value in found):
        raise ValueError(f'cast_period owned_aura is [spell, owned entry, ms after the trigger], not {raw!r}')
    return found


def aura_expiry_of(raw) -> tuple[int, int] | None:
    if raw is None:
        return None
    if not isinstance(raw, dict) or set(raw) != {'expected_ms', 'gone_after_ms'} or not all(
            type(raw[key]) is int and raw[key] > 0 for key in raw):
        raise ValueError(f'cast_period aura_expiry is {{"expected_ms": ms, "gone_after_ms": ms}}, positive integers, '
                         f'not {raw!r}')
    return raw['expected_ms'], raw['gone_after_ms']


def arm_checks(spec: CastPeriodSpec):
    armed = (spec.gap_reduction_ms, spec.owned_aura, spec.aura_quote)
    if spec.arm is None:
        if any(value is not None for value in armed):
            raise ValueError(f'{spec.spell} cast_period gap_reduction_ms, owned_aura and aura_quote need an arm')
        return
    if spec.arm not in ARMS:
        raise ValueError(f'{spec.spell} cast_period arm is one of {list(ARMS)}, not {spec.arm!r}')
    if spec.minion_auras or spec.gaps_ms:
        raise ValueError(f'{spec.spell} cast_period arms are judged against each other, without minion_auras or '
                         f'gaps_ms')
    if spec.gap_reduction_ms is None and spec.owned_aura is None:
        raise ValueError(f'{spec.spell} cast_period arm needs gap_reduction_ms or owned_aura')
    if spec.gap_reduction_ms is not None and (type(spec.gap_reduction_ms) is not int
                                              or not 0 < spec.gap_reduction_ms < spec.expected_ms):
        raise ValueError(f'{spec.spell} cast_period gap_reduction_ms is a positive integer below expected_ms')
    if (spec.owned_aura is None) != (spec.aura_quote is None):
        raise ValueError(f'{spec.spell} cast_period owned_aura and aura_quote go together')
    if spec.owned_aura is not None and not spec.pet_attack:
        raise ValueError(f'{spec.spell} cast_period owned_aura is read before the pet attack command, so before the '
                         f'first leap: it needs pet_attack')
    if spec.aura_expiry is not None:
        if spec.owned_aura is None:
            raise ValueError(f'{spec.spell} cast_period aura_expiry needs an owned_aura read')
        expected, gone = spec.aura_expiry
        if not spec.owned_aura[2] < expected < spec.owned_aura[2] + gone:
            raise ValueError(f'{spec.spell} cast_period aura_expiry reads the aura present before {expected} ms and '
                             f'gone after it')


def cast_period_spec(entry: dict) -> CastPeriodSpec:
    spec = CastPeriodSpec(entry['spell'], entry['name'], entry['quote'], int(entry['setup_spell']),
                          int(entry['setup_wait_ms']), int(entry['trigger_spell']), int(entry['entry']),
                          int(entry['cast_spell']), int(entry['expected_ms']), int(entry['control_ms']),
                          int(entry['window_ms']), int(entry.get('poll_ms', 100)),
                          entry.get('label_suffix', 'cast_period'), minion_auras_of(entry.get('minion_auras', ())),
                          entry.get('casts_per_event', 1), tuple(entry.get('gaps_ms', ())),
                          entry.get('pet_attack', False), entry.get('force_crit'), tuple(entry.get('learn', ())),
                          caster_auras_of(entry.get('caster_auras', ())), entry.get('arm'),
                          entry.get('gap_reduction_ms'), owned_aura_of(entry.get('owned_aura')),
                          entry.get('aura_quote'), aura_expiry_of(entry.get('aura_expiry')))
    if spec.force_crit is not None and spec.force_crit not in FORCE_CRIT_RATINGS:
        raise ValueError(f'{spec.spell} cast_period force_crit {spec.force_crit!r} is not one of '
                         f'{sorted(FORCE_CRIT_RATINGS)}')
    if not all(type(spell) is int and spell > 0 for spell in spec.learn):
        raise ValueError(f'{spec.spell} cast_period learn is a list of spell ids, not {list(spec.learn)!r}')
    if type(spec.pet_attack) is not bool:
        raise ValueError(f'{spec.spell} cast_period pet_attack is a boolean, not {spec.pet_attack!r}')
    if type(spec.casts_per_event) is not int or spec.casts_per_event < 1 or not all(
            type(gap) is int and gap > 0 for gap in spec.gaps_ms):
        raise ValueError(f'{spec.spell} cast_period casts_per_event is a positive integer and gaps_ms positive '
                         f'integers')
    if spec.minion_auras and (not spec.gaps_ms or any(after >= spec.window_ms for _, _, after in spec.minion_auras)):
        raise ValueError(f'{spec.spell} cast_period sets minion auras inside the window, for a gaps_ms judge only')
    if spec.gaps_ms and sum(spec.gaps_ms) >= spec.window_ms:
        raise ValueError(f'{spec.spell} cast_period gaps_ms {list(spec.gaps_ms)} do not fit in the window')
    if spec.poll_ms < 25 or spec.poll_ms * 2 > spec.expected_ms:
        raise ValueError(f'{spec.spell} cast_period polls at least every 25 ms and at most half the period')
    if spec.window_ms < CAST_PERIOD_MINIMUM_CASTS * spec.expected_ms or spec.control_ms < 2 * spec.expected_ms:
        raise ValueError(f'{spec.spell} cast_period needs a window of {CAST_PERIOD_MINIMUM_CASTS} periods and a '
                         f'control of two')
    arm_checks(spec)
    return spec


def cast_steps(records: Records, spell: int, target: str) -> list[dict]:
    facts = facts_of(records, spell)
    steps = [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spell}]
    if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
        steps.insert(0, {'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                         'value': facts.mana_cost})
    return (steps + required_aura_steps(facts) + reagent_steps(records, spell)
            + [{'action': 'cast', 'actor': CASTER, 'spell': spell, 'target': target}])


def cast_period_label(spec: CastPeriodSpec, read: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {read}'


def cast_period_scenario(class_file: dict, spec: CastPeriodSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'cast_period', spec.quote, float(spec.expected_ms))
    counted = {'spell': spec.cast_spell, 'entry': spec.entry}

    def cast(spell: int, target: str) -> list[dict]:
        return cast_steps(records, spell, target)

    control = cast_period_label(spec, 'control')
    start = cast_period_label(spec, 'start')
    reads = []
    polls = []
    auras = {}
    for spell, owned, after in spec.minion_auras:
        auras.setdefault(after // spec.poll_ms, []).append(
            {'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': 1, 'owned_entry': owned})
    for index in range(spec.window_ms // spec.poll_ms + 1):
        labels = [cast_period_label(spec, f'{index} time'), cast_period_label(spec, f'{index} casts')]
        polls += auras.get(index, [])
        polls += [measurement(labels[0], CASTER, 'game_time_ms'),
                  measurement(labels[1], CASTER, CAST_PERIOD_METRIC, **counted),
                  {'action': 'wait', 'label': 'cast period poll', 'ms': spec.poll_ms}]
        reads.append(labels)
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in (spec.setup_spell,
                                                                                 spec.trigger_spell)]
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in spec.learn]
             + cast(spec.setup_spell, CASTER) + [{'action': 'wait', 'label': 'summon', 'ms': spec.setup_wait_ms},
                                                  {'action': 'wait', 'label': 'uncommanded control',
                                                   'ms': spec.control_ms},
                                                  measurement(control, CASTER, CAST_PERIOD_METRIC, **counted),
                                                  measurement(start, CASTER, 'game_time_ms')]
             + cast(spec.trigger_spell, TARGET)
             + ([{'action': 'attack', 'actor': CASTER, 'target': TARGET, 'pet': True}] if spec.pet_attack else [])
             + polls)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour cast period',
        'contract': (f'A real {spec.setup_spell} cast raises creature {spec.entry}; uncommanded for {spec.control_ms} '
                     f'ms (control) it must cast no {spec.cast_spell}. Then {spec.trigger_spell} at the dummy, and '
                     f'every {spec.poll_ms} ms over {spec.window_ms} ms the game time and the creature\'s casts of '
                     f'{spec.cast_spell} are read; the first and the last cast are bracketed in game time and the '
                     f'period (last - first) / (casts - 1) must lie inside {spec.expected_ms} ms +- the G-19 band.'),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    if spec.force_crit is not None:
        scenario['players'][0][FORCE_CRIT_RATINGS[spec.force_crit]] = FORCED_CRIT_RATING
        scenario['contract'] += (f' The caster holds {FORCED_CRIT_RATING} {FORCE_CRIT_RATINGS[spec.force_crit]}, so '
                                 f'its {spec.force_crit} hits crit.')
    if spec.learn:
        scenario['contract'] += f' The caster also learns {list(spec.learn)} at the start.'
    model = {'kind': 'cast_period', 'metric': CAST_PERIOD_METRIC, 'quote': entry.quote,
             'expected_ms': spec.expected_ms, 'band_ms': bonus_band(float(spec.expected_ms)), 'reads': reads,
             'control_label': control, 'start_label': start}
    if spec.gaps_ms:
        model['gaps'] = {'expected_ms': list(spec.gaps_ms), 'band_ms': [bonus_band(float(gap)) for gap in spec.gaps_ms],
                         'casts_per_event': spec.casts_per_event}
        scenario['contract'] += ((' Right after the trigger the caster commands its pet to attack the dummy.'
                                  if spec.pet_attack else '') + f' Every {spec.casts_per_event} casts are one event; the gaps between the first '
                                 f'{len(spec.gaps_ms) + 1} events must lie inside {list(spec.gaps_ms)} ms +- the G-19 '
                                 f'band each.' + (f' {[(spell, owned) for spell, owned, _ in spec.minion_auras]} are set '
                                                  f'on the owned creatures {[after for _, _, after in spec.minion_auras]} '
                                                  f'ms after the trigger.' if spec.minion_auras else ''))
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}', BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.cast_spell, None, str(spec.expected_ms),
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def cast_period_verdict(base, run, model: dict):
    from compare import missing_measurement
    labels = [model['control_label'], model['start_label'], *(label for pair in model['reads'] for label in pair)]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    control = run.values[model['control_label']]
    times = [run.values[pair[0]] for pair in model['reads']]
    casts = [run.values[pair[1]] for pair in model['reads']]
    expected, band = float(model['expected_ms']), float(model['band_ms'])
    if control != 0:
        return replace(base, status='alert', measured=control, expected=0.0,
                       explanation=f'the control read before the trigger counts {control:g} (expected none)')
    if 'gaps' in model:
        return cast_gaps_verdict(base, model, times, casts, run.values[model['start_label']])
    count = int(casts[-1])
    if count < CAST_PERIOD_MINIMUM_CASTS or casts[0] != 0:
        return replace(base, status='unmeasured' if casts[0] == 0 else 'alert', measured=float(count),
                       explanation=f'{count:g} casts in the window, {casts[0]:g} at its first read: the period needs '
                                   f'at least {CAST_PERIOD_MINIMUM_CASTS} casts after a read of none')
    if any(later - earlier > 1 for earlier, later in zip(casts, casts[1:])) or casts != sorted(casts):
        return replace(base, status='alert', measured=float(count),
                       explanation='two casts fell between two reads, or the count fell: the polls do not bracket '
                                   'each cast')
    first = next(index for index, value in enumerate(casts) if value >= 1)
    last = casts.index(count)
    low = (times[last - 1] - times[first]) / (count - 1)
    high = (times[last] - times[first - 1]) / (count - 1)
    start = run.values[model['start_label']]
    if model.get('first_at_cast') and first != 1:
        return replace(base, status='alert', measured=float(count),
                       explanation=f'the first hit lies in ({times[first - 1] - start:g}, {times[first] - start:g}] '
                                   f'ms of game time after the command, not in the first poll after the cast: no '
                                   f'tick at the cast')
    status = 'ok' if expected - band <= low and high <= expected + band else 'alert'
    return replace(base, status=status, measured=(low + high) / 2, expected=expected, low=expected - band,
                   high=expected + band,
                   explanation=f'{count} casts; the first in ({times[first - 1] - start:g}, {times[first] - start:g}] '
                               f'ms of game time after the command, the last in ({times[last - 1] - start:g}, '
                               f'{times[last] - start:g}]: a period between {low:.1f} and {high:.1f} ms against '
                               f'{expected:g} +- {band:g} (G-19); none in the control read before the trigger')


def cast_gaps_verdict(base, model: dict, times: list[float], casts: list[float], start: float):
    gaps = model['gaps']
    per_event = gaps['casts_per_event']
    if casts[0] != 0 or any(value % per_event for value in casts) or casts != sorted(casts) or any(
            later - earlier > per_event for earlier, later in zip(casts, casts[1:])):
        return replace(base, status='alert', measured=float(casts[-1]),
                       explanation=f'the counts {sorted(set(casts))} are not events of {per_event} casts bracketed by '
                                   f'the polls one at a time, after a first read of none')
    events = int(casts[-1]) // per_event
    needed = len(gaps['expected_ms']) + 1
    if events < needed:
        return replace(base, status='unmeasured', measured=float(events),
                       explanation=f'{events} events in the window, the gaps need {needed}')
    reads = [casts.index(event * per_event) for event in range(1, needed + 1)]
    brackets = [((times[later - 1] - times[earlier]), (times[later] - times[earlier - 1]))
                for earlier, later in zip(reads, reads[1:])]
    within = [expected - band <= low and high <= expected + band for (low, high), expected, band in
              zip(brackets, gaps['expected_ms'], gaps['band_ms'])]
    shown = '; '.join(f'gap {index + 1} between {low:g} and {high:g} ms against {expected:g} +- {band:g}'
                      for index, ((low, high), expected, band) in
                      enumerate(zip(brackets, gaps['expected_ms'], gaps['band_ms'])))
    first = reads[0]
    return replace(base, status='ok' if all(within) else 'alert', measured=(brackets[1][0] + brackets[1][1]) / 2
                   if len(brackets) > 1 else (brackets[0][0] + brackets[0][1]) / 2,
                   expected=float(gaps['expected_ms'][min(1, len(brackets) - 1)]),
                   explanation=f'{events} events of {per_event} casts, the first in ({times[first - 1] - start:g}, '
                               f'{times[first] - start:g}] ms of game time after the trigger; {shown} (G-19); none in '
                               f'the control read before the trigger')


def arm_label(spec: CastPeriodSpec, arm: str, read: str) -> str:
    return cast_period_label(spec, f'{arm} {read}')


def arm_reads(spec: CastPeriodSpec, arm: str) -> dict:
    return {'control': arm_label(spec, arm, 'control'), 'start': arm_label(spec, arm, 'start'),
            'reads': [[arm_label(spec, arm, f'{index} time'), arm_label(spec, arm, f'{index} casts')]
                      for index in range(spec.window_ms // spec.poll_ms + 1)],
            'crits': arm_label(spec, arm, 'trigger crits'), 'noncrits': arm_label(spec, arm, 'trigger noncrits'),
            'aura': arm_label(spec, arm, 'owned aura') if spec.owned_aura else None,
            'fixture': arm_label(spec, arm, 'fixture'),
            **({'trigger_done': arm_label(spec, arm, 'trigger done'), 'aura_time': arm_label(spec, arm, 'aura time'),
                'aura_gone_time': arm_label(spec, arm, 'aura gone time'),
                'aura_gone': arm_label(spec, arm, 'owned aura gone')} if spec.aura_expiry else {})}


def leap_arms_label(spec: CastPeriodSpec) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}'


def owned_aura_label(spec: CastPeriodSpec) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} owned_aura'


def cast_arm_scenario(class_file: dict, spec: CastPeriodSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    labels = arm_reads(spec, spec.arm)
    counted = {'spell': spec.cast_spell, 'entry': spec.entry}
    trigger = {'spell': spec.trigger_spell, 'target': TARGET}
    fixtures = []
    for aura, stacks in spec.caster_auras:
        fixtures += [{'action': 'set_aura', 'actor': CASTER, 'spell': aura, 'stacks': stacks,
                      'label': f'precondition fixture {aura}'},
                     measurement(f'{labels["fixture"]} {aura}', CASTER, FIXTURE_METRIC, spell=aura)]
    aura_read = []
    if spec.owned_aura is not None:
        aura, owned, after = spec.owned_aura
        aura_read = [{'action': 'wait', 'label': 'owned aura settle', 'ms': after},
                     measurement(labels['aura'], CASTER, OWNED_AURA_METRIC, spell=aura, entry=owned)]
        if spec.aura_expiry is not None:
            aura_read = [measurement(labels['trigger_done'], CASTER, 'game_time_ms'),
                         {'action': 'wait', 'label': 'owned aura settle', 'ms': after},
                         measurement(labels['aura_time'], CASTER, 'game_time_ms'),
                         measurement(labels['aura'], CASTER, OWNED_AURA_METRIC, spell=aura, entry=owned),
                         {'action': 'wait', 'label': 'owned aura expiry settle', 'ms': spec.aura_expiry[1]},
                         measurement(labels['aura_gone_time'], CASTER, 'game_time_ms'),
                         measurement(labels['aura_gone'], CASTER, OWNED_AURA_METRIC, spell=aura, entry=owned)]
    polls = []
    for time_label, casts_label in labels['reads']:
        polls += [measurement(time_label, CASTER, 'game_time_ms'),
                  measurement(casts_label, CASTER, CAST_PERIOD_METRIC, **counted),
                  {'action': 'wait', 'label': 'cast period poll', 'ms': spec.poll_ms}]
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in (spec.setup_spell,
                                                                                 spec.trigger_spell)]
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in spec.learn]
             + cast_steps(records, spec.setup_spell, CASTER)
             + [{'action': 'wait', 'label': 'summon', 'ms': spec.setup_wait_ms},
                {'action': 'wait', 'label': 'uncommanded control', 'ms': spec.control_ms},
                measurement(labels['control'], CASTER, CAST_PERIOD_METRIC, **counted),
                measurement(labels['start'], CASTER, 'game_time_ms')]
             + fixtures + cast_steps(records, spec.trigger_spell, TARGET) + aura_read
             + ([{'action': 'attack', 'actor': CASTER, 'target': TARGET, 'pet': True}] if spec.pet_attack else [])
             + polls
             + [measurement(labels['crits'], CASTER, CRIT_METRIC, **trigger, critical=True),
                measurement(labels['noncrits'], CASTER, CRIT_METRIC, **trigger, critical=False)])
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour cast period {spec.arm} arm',
        'contract': (f'The {spec.arm} arm of a two-arm case. A real {spec.setup_spell} cast raises creature '
                     f'{spec.entry}; uncommanded for {spec.control_ms} ms it must cast no {spec.cast_spell}. Then '
                     f'{spec.trigger_spell} at the dummy, and every {spec.poll_ms} ms over {spec.window_ms} ms the '
                     f'game time and the creature\'s casts of {spec.cast_spell} are read; every {spec.casts_per_event} '
                     f'casts are one event. The trigger\'s critical and non-critical hits on the dummy are read at the '
                     f'end: the treatment arm must crit, the control arm must not.'),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    if spec.force_crit is not None:
        scenario['players'][0][FORCE_CRIT_RATINGS[spec.force_crit]] = FORCED_CRIT_RATING
        scenario['contract'] += (f' The caster holds {FORCED_CRIT_RATING} {FORCE_CRIT_RATINGS[spec.force_crit]}, so '
                                 f'its {spec.force_crit} hits crit.')
    if spec.learn:
        scenario['contract'] += f' The caster also learns {list(spec.learn)} at the start.'
    if spec.caster_auras:
        scenario['contract'] += (f' Precondition fixtures {[list(item) for item in spec.caster_auras]} are set on the '
                                 f'caster right before the trigger and read back.')
    if spec.owned_aura is not None:
        scenario['contract'] += (f' {spec.owned_aura[2]} ms after the trigger, before the pet attack command (the '
                                 f'creature has no victim and cannot leap yet), the creatures {spec.owned_aura[1]} '
                                 f'holding {spec.owned_aura[0]} are counted.')
    if spec.pet_attack:
        scenario['contract'] += ' After the trigger the caster commands its pet to attack the dummy.'
    shared = {'kind': KIND, 'parts': len(ARMS), 'arms': {arm: arm_reads(spec, arm) for arm in ARMS}}
    expectations = []
    if spec.gap_reduction_ms is not None:
        entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, float(spec.gap_reduction_ms))
        model = {**shared, 'judge': 'leap_arms', 'metric': CAST_PERIOD_METRIC, 'quote': entry.quote,
                 'casts_per_event': spec.casts_per_event, 'reduction_ms': spec.gap_reduction_ms,
                 'band_ms': bonus_band(float(spec.gap_reduction_ms))}
        expectations.append(Expectation(leap_arms_label(spec), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.cast_spell,
                                        None, str(spec.gap_reduction_ms), prose_rule(entry.quote, spec.spell),
                                        model))
        scenario['contract'] += (f' Judged with the other arm: the control\'s first gap minus the treatment\'s first '
                                 f'gap must lie inside {spec.gap_reduction_ms} ms +- the G-19 band, and the '
                                 f'treatment\'s second gap must equal the control\'s first inside the G-19 band.')
    if spec.owned_aura is not None:
        stated = float(spec.aura_expiry[0]) if spec.aura_expiry else 1.0
        entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.aura_quote, stated)
        model = {**shared, 'judge': 'owned_aura', 'metric': OWNED_AURA_METRIC, 'quote': entry.quote,
                 'aura': spec.owned_aura[0], 'entry': spec.owned_aura[1]}
        if spec.aura_expiry:
            model['expiry'] = {'expected_ms': spec.aura_expiry[0], 'band_ms': bonus_band(stated)}
            scenario['contract'] += (f' The aura is read again {spec.aura_expiry[1]} ms later, and the game time is '
                                     f'stamped before the trigger, right after it and at both reads: present before '
                                     f'{spec.aura_expiry[0]} ms of age and gone after it, inside the G-19 band.')
        expectations.append(Expectation(owned_aura_label(spec), BEHAVIOUR_METRIC_DELTA, spec.spell,
                                        spec.owned_aura[0], None, f'{stated:g}' if spec.aura_expiry else '1',
                                        prose_rule(entry.quote, spec.spell), model))
    return timed(scenario, waited_ms(steps)), expectations


def arm_runs(runs: list, model: dict, need: list[str]) -> tuple[dict, str | None]:
    found = {}
    for arm, labels in model['arms'].items():
        run = next((run for run in runs if labels['start'] in run.values), None)
        if run is None:
            return found, f'the {arm} arm did not run'
        missing = next((label for label in need_labels(labels, need) if run.values.get(label) is None), None)
        if missing is not None:
            return found, f'the {arm} arm has no read {missing!r}'
        found[arm] = run
    return found, None


def need_labels(labels: dict, need: list[str]) -> list[str]:
    found = []
    for name in need:
        found += [label for pair in labels['reads'] for label in pair] if name == 'reads' else [labels[name]]
    return found


def fixtures_named(run, labels: dict) -> str:
    prefix = f'{labels["fixture"]} '
    reads = sorted((label.removeprefix(prefix), value) for label, value in run.values.items()
                   if label.startswith(prefix))
    return ', '.join(f'{spell} read {value:g}' for spell, value in reads) or 'none'


def crit_outcome(runs: dict, model: dict) -> tuple[str | None, str]:
    crits = {arm: (runs[arm].values[model['arms'][arm]['crits']], runs[arm].values[model['arms'][arm]['noncrits']])
             for arm in ARMS}
    text = (f'trigger crits/non-crits: treatment {crits["treatment"][0]:g}/{crits["treatment"][1]:g}, control '
            f'{crits["control"][0]:g}/{crits["control"][1]:g} (control fixtures '
            f'{fixtures_named(runs["control"], model["arms"]["control"])})')
    if crits['control'][0] > 0:
        return 'alert', f'a crit in the control arm; {text}'
    if crits['control'][1] < 1 or crits['treatment'][0] < 1 or crits['treatment'][1] > 0:
        return 'unmeasured', f'held: an arm\'s trigger outcome is not the one the arm needs; {text}'
    return None, text


def arm_gaps(model: dict, run, arm: str) -> tuple[list[tuple[float, float]] | None, str]:
    labels = model['arms'][arm]
    per_event = model['casts_per_event']
    times = [run.values[pair[0]] for pair in labels['reads']]
    casts = [run.values[pair[1]] for pair in labels['reads']]
    if run.values[labels['control']] != 0:
        return None, f'alert: the {arm} arm\'s uncommanded control counts {run.values[labels["control"]]:g}'
    if casts[0] != 0 or any(value % per_event for value in casts) or casts != sorted(casts) or any(
            later - earlier > per_event for earlier, later in zip(casts, casts[1:])):
        return None, (f'alert: the {arm} arm\'s counts {sorted(set(casts))} are not events of {per_event} casts '
                      f'bracketed one at a time after a first read of none')
    events = int(casts[-1]) // per_event
    if events < ARM_EVENTS:
        return None, f'unmeasured: {events} events in the {arm} arm, the gaps need {ARM_EVENTS}'
    reads = [casts.index(event * per_event) for event in range(1, ARM_EVENTS + 1)]
    return [(times[later - 1] - times[earlier], times[later] - times[earlier - 1])
            for earlier, later in zip(reads, reads[1:])], ''


def interval_status(low: float, high: float, expected: float, band: float, probes: tuple[float, float]) -> str:
    if expected - band <= low and high <= expected + band and not any(low <= probe <= high for probe in probes):
        return 'ok'
    if high < expected - band or low > expected + band:
        return 'alert'
    return 'unmeasured'


def leap_arms_verdict(base, runs: list, model: dict):
    found, missing = arm_runs(runs, model, ['control', 'start', 'reads', 'crits', 'noncrits'])
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing)
    status, crit_text = crit_outcome(found, model)
    if status is not None:
        return replace(base, status=status, explanation=crit_text)
    gaps = {}
    for arm in ARMS:
        gaps[arm], reason = arm_gaps(model, found[arm], arm)
        if gaps[arm] is None:
            status, text = reason.split(': ', 1)
            return replace(base, status=status, explanation=f'{text}; {crit_text}')
    (control_low, control_high), _ = gaps['control']
    (first_low, first_high), (second_low, second_high) = gaps['treatment']
    reduction, band = float(model['reduction_ms']), float(model['band_ms'])
    cut = (control_low - first_high, control_high - first_low)
    cut_status = interval_status(*cut, reduction, band, tuple(reduction * factor for factor in TEN_PERCENT_OFF))
    control_mid = (control_low + control_high) / 2
    same_band = bonus_band(control_mid)
    same = (second_low - control_high, second_high - control_low)
    same_status = interval_status(*same, 0.0, same_band,
                                  tuple(control_mid * (factor - 1) for factor in TEN_PERCENT_OFF))
    statuses = {cut_status, same_status}
    status = 'alert' if 'alert' in statuses else 'unmeasured' if 'unmeasured' in statuses else 'ok'
    return replace(base, status=status, measured=(cut[0] + cut[1]) / 2, expected=reduction, low=reduction - band,
                   high=reduction + band,
                   explanation=(f'control gap 1 between {control_low:g} and {control_high:g} ms, treatment gaps '
                                f'between {first_low:g} and {first_high:g} then {second_low:g} and {second_high:g} ms; '
                                f'reduction (control gap 1 - treatment gap 1) between {cut[0]:g} and {cut[1]:g} ms '
                                f'against {reduction:g} +- {band:g} (G-19), {reduction * 0.9:g} and '
                                f'{reduction * 1.1:g} (10% off, D-200) excluded: {cut_status}; treatment gap 2 - '
                                f'control gap 1 between {same[0]:g} and {same[1]:g} ms against 0 +- {same_band:g}, '
                                f'10% off excluded: {same_status}; {crit_text}'))


def owned_aura_verdict(base, runs: list, model: dict):
    expiry = model.get('expiry')
    found, missing = arm_runs(runs, model, ['aura', 'crits', 'noncrits']
                              + (['start', 'trigger_done', 'aura_time', 'aura_gone_time', 'aura_gone']
                                 if expiry else []))
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing)
    status, crit_text = crit_outcome(found, model)
    if status is not None:
        return replace(base, status=status, explanation=crit_text)
    held = {arm: found[arm].values[model['arms'][arm]['aura']] for arm in ARMS}
    status = 'ok' if held['treatment'] >= 1 and held['control'] == 0 else 'alert'
    if expiry and status == 'ok':
        return expiry_verdict(base, found, model, held, crit_text)
    return replace(base, status=status, measured=held['treatment'], expected=1.0,
                   explanation=(f'creatures {model["entry"]} holding {model["aura"]} after the trigger, before the '
                                f'first leap: treatment {held["treatment"]:g}, control {held["control"]:g} (expected '
                                f'1 and 0); {crit_text}'))


def expiry_verdict(base, found: dict, model: dict, held: dict, crit_text: str):
    labels = model['arms']['treatment']
    values = found['treatment'].values
    start, done = values[labels['start']], values[labels['trigger_done']]
    seen, gone_seen = values[labels['aura_time']], values[labels['aura_gone_time']]
    gone = {arm: found[arm].values[model['arms'][arm]['aura_gone']] for arm in ARMS}
    expected, band = float(model['expiry']['expected_ms']), float(model['expiry']['band_ms'])
    present_age = (seen - done, seen - start)
    gone_age = (gone_seen - done, gone_seen - start)
    text = (f'creatures {model["entry"]} holding {model["aura"]}: treatment {held["treatment"]:g} at an age of '
            f'{present_age[0]:g} to {present_age[1]:g} ms and {gone["treatment"]:g} at {gone_age[0]:g} to '
            f'{gone_age[1]:g} ms, control {held["control"]:g} then {gone["control"]:g}, against {expected:g} +- '
            f'{band:g} (G-19); {crit_text}')
    if gone['control'] != 0:
        return replace(base, status='alert', explanation=f'the control holds the aura at the second read: {text}')
    if gone['treatment'] >= 1:
        status = 'alert' if gone_age[0] > expected + band else 'unmeasured'
        return replace(base, status=status, measured=gone_age[0], expected=expected,
                       explanation=f'the aura outlasts its stated duration: {text}')
    inside = present_age[0] >= expected - band and gone_age[1] <= expected + band
    return replace(base, status='ok' if inside else 'unmeasured', measured=(present_age[0] + gone_age[1]) / 2,
                   expected=expected, low=expected - band, high=expected + band,
                   explanation=text if inside else f'the reads do not bracket the band: {text}')


def cast_period_pooled_verdict(base, runs: list, model: dict):
    return (leap_arms_verdict if model['judge'] == 'leap_arms' else owned_aura_verdict)(base, runs, model)


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    spec = cast_period_spec(entry)
    return cast_arm_scenario(class_file, spec) if spec.arm else cast_period_scenario(class_file, spec)


def label(entry: dict) -> list[str]:
    base = f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'cast_period')}"
    if entry.get('arm') is None:
        return [base]
    return ([base] if entry.get('gap_reduction_ms') is not None else []) + (
        [f'{base} owned_aura'] if entry.get('owned_aura') is not None else [])


JUDGES = {BEHAVIOUR_METRIC_DELTA: cast_period_verdict}
POOLED_JUDGE = cast_period_pooled_verdict