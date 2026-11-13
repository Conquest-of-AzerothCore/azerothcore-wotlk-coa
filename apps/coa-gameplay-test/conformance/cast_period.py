from dataclasses import dataclass, replace
from pathlib import Path

from bonus import bonus_band
from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, reagent_steps, waited_ms
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import TARGET, Expectation, dataset, facts_of, required_aura_steps

CAST_PERIOD_METRIC = 'owned_creature_spell_cast_count'
CAST_PERIOD_MINIMUM_CASTS = 3


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


def cast_period_spec(entry: dict) -> CastPeriodSpec:
    spec = CastPeriodSpec(entry['spell'], entry['name'], entry['quote'], int(entry['setup_spell']),
                          int(entry['setup_wait_ms']), int(entry['trigger_spell']), int(entry['entry']),
                          int(entry['cast_spell']), int(entry['expected_ms']), int(entry['control_ms']),
                          int(entry['window_ms']), int(entry.get('poll_ms', 100)),
                          entry.get('label_suffix', 'cast_period'))
    if spec.poll_ms < 25 or spec.poll_ms * 2 > spec.expected_ms:
        raise ValueError(f'{spec.spell} cast_period polls at least every 25 ms and at most half the period')
    if spec.window_ms < CAST_PERIOD_MINIMUM_CASTS * spec.expected_ms or spec.control_ms < 2 * spec.expected_ms:
        raise ValueError(f'{spec.spell} cast_period needs a window of {CAST_PERIOD_MINIMUM_CASTS} periods and a '
                         f'control of two')
    return spec


def cast_period_label(spec: CastPeriodSpec, read: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {read}'


def cast_period_scenario(class_file: dict, spec: CastPeriodSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'cast_period', spec.quote, float(spec.expected_ms))
    counted = {'spell': spec.cast_spell, 'entry': spec.entry}

    def cast(spell: int, target: str) -> list[dict]:
        facts = facts_of(records, spell)
        steps = [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spell}]
        if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
            steps.insert(0, {'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                             'value': facts.mana_cost})
        return (steps + required_aura_steps(facts) + reagent_steps(records, spell)
                + [{'action': 'cast', 'actor': CASTER, 'spell': spell, 'target': target}])

    control = cast_period_label(spec, 'control')
    start = cast_period_label(spec, 'start')
    reads = []
    polls = []
    for index in range(spec.window_ms // spec.poll_ms + 1):
        labels = [cast_period_label(spec, f'{index} time'), cast_period_label(spec, f'{index} casts')]
        polls += [measurement(labels[0], CASTER, 'game_time_ms'),
                  measurement(labels[1], CASTER, CAST_PERIOD_METRIC, **counted),
                  {'action': 'wait', 'label': 'cast period poll', 'ms': spec.poll_ms}]
        reads.append(labels)
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in (spec.setup_spell,
                                                                                 spec.trigger_spell)]
             + cast(spec.setup_spell, CASTER) + [{'action': 'wait', 'label': 'summon', 'ms': spec.setup_wait_ms},
                                                  {'action': 'wait', 'label': 'uncommanded control',
                                                   'ms': spec.control_ms},
                                                  measurement(control, CASTER, CAST_PERIOD_METRIC, **counted),
                                                  measurement(start, CASTER, 'game_time_ms')]
             + cast(spec.trigger_spell, TARGET) + polls)
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
    model = {'kind': 'cast_period', 'metric': CAST_PERIOD_METRIC, 'quote': entry.quote,
             'expected_ms': spec.expected_ms, 'band_ms': bonus_band(float(spec.expected_ms)), 'reads': reads,
             'control_label': control, 'start_label': start}
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
    status = 'ok' if expected - band <= low and high <= expected + band else 'alert'
    return replace(base, status=status, measured=(low + high) / 2, expected=expected, low=expected - band,
                   high=expected + band,
                   explanation=f'{count} casts; the first in ({times[first - 1] - start:g}, {times[first] - start:g}] '
                               f'ms of game time after the command, the last in ({times[last - 1] - start:g}, '
                               f'{times[last] - start:g}]: a period between {low:.1f} and {high:.1f} ms against '
                               f'{expected:g} +- {band:g} (G-19); none in the control read before the trigger')


PULSE_TARGETS_METRIC = 'spell_damage_count'
PULSE_TARGETS_FAR_MARGIN_YD = 5.0
PULSE_TARGETS_MINIMUM_PULSES = 3


@dataclass(frozen=True)
class PulseTargetsSpec:
    spell: int
    name: str
    quote: str
    setup_spell: int
    trigger_spell: int
    hit_spell: int
    caster_entry: int
    expected: int
    dummies: int
    radius: float
    window_ms: int
    poll_ms: int = 50
    label_suffix: str = 'pulse_targets'


def pulse_targets_spec(entry: dict) -> PulseTargetsSpec:
    spec = PulseTargetsSpec(entry['spell'], entry['name'], entry['quote'], int(entry['setup_spell']),
                            int(entry['trigger_spell']), int(entry['hit_spell']), int(entry['caster_entry']),
                            int(entry['expected']), int(entry['dummies']), float(entry['radius']),
                            int(entry['window_ms']), int(entry.get('poll_ms', 50)),
                            entry.get('label_suffix', 'pulse_targets'))
    if spec.dummies <= spec.expected or spec.radius <= 0 or spec.poll_ms < 25:
        raise ValueError(f'{spec.spell} pulse_targets needs more dummies than the stated cap, a radius and polls of '
                         f'at least 25 ms')
    return spec


def pulse_dummy(index: int) -> str:
    return 'primary' if index == 0 else f'extra{index}'


def pulse_targets_scenario(class_file: dict, spec: PulseTargetsSpec) -> tuple[dict, list[Expectation]]:
    from behaviours import hit_ratio_cast
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'pulse_targets', spec.quote, float(spec.expected))
    far = spec.dummies
    distances = [spec.radius * (index + 1) / (spec.dummies + 1) for index in range(spec.dummies)]
    distances.append(spec.radius + PULSE_TARGETS_FAR_MARGIN_YD)
    creatures = [{**creature_fixture(class_file), 'id': pulse_dummy(index), 'distance': distance}
                 for index, distance in enumerate(distances)]

    def label(index: int, read: str) -> str:
        return cast_period_label(spec, f'{index} {read}')

    def poll(index: int) -> list[dict]:
        return ([measurement(label(index, 'time'), CASTER, 'game_time_ms')]
                + [measurement(label(index, pulse_dummy(dummy)), CASTER, PULSE_TARGETS_METRIC, spell=spec.hit_spell,
                               target=pulse_dummy(dummy), caster_entry=spec.caster_entry)
                   for dummy in range(spec.dummies + 1)])

    polls = spec.window_ms // spec.poll_ms + 1
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in (spec.setup_spell,
                                                                                 spec.trigger_spell)]
             + hit_ratio_cast(records, spec.setup_spell, CASTER, CASTER) + poll(0)
             + hit_ratio_cast(records, spec.trigger_spell, CASTER, pulse_dummy(0))[:-1])
    for index in range(1, polls + 1):
        steps += [{'action': 'wait', 'label': 'pulse poll', 'ms': spec.poll_ms}] + poll(index)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour pulse targets',
        'contract': (f'A real {spec.setup_spell} cast raises creature {spec.caster_entry}, then {spec.trigger_spell} '
                     f'at the primary dummy; {spec.dummies} dummies stand inside {spec.radius:g} yd of the caster and '
                     f'one {PULSE_TARGETS_FAR_MARGIN_YD:g} yd beyond. Every {spec.poll_ms} ms over {spec.window_ms} ms '
                     f'the game time and each dummy\'s {spec.hit_spell} hits from the creature are read; the dummies '
                     f'hit between two reads are one pulse\'s targets, and no pulse may strike more than '
                     f'{spec.expected}, at least one pulse strikes {spec.expected}, the far dummy never.'),
        'players': [player_fixture(class_file)],
        'creatures': creatures,
        'steps': steps}
    reads = [[label(index, 'time')] + [label(index, pulse_dummy(dummy)) for dummy in range(spec.dummies + 1)]
             for index in range(polls + 1)]
    model = {'kind': 'pulse_targets', 'metric': PULSE_TARGETS_METRIC, 'quote': entry.quote,
             'expected': spec.expected, 'reads': reads, 'far_index': far}
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}', BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.hit_spell, None, str(spec.expected),
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def pulse_targets_verdict(base, run, model: dict):
    from compare import missing_measurement
    missing = next((label for row in model['reads'] for label in row if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    rows = [[run.values[label] for label in row] for row in model['reads']]
    far, expected = int(model['far_index']), int(model['expected'])
    if rows[-1][1 + far] != rows[0][1 + far]:
        return replace(base, status='alert', explanation=f'the dummy beyond the radius was struck '
                                                         f'{rows[-1][1 + far] - rows[0][1 + far]:g} times')
    pulses = []
    for earlier, later in zip(rows, rows[1:]):
        increments = [later[1 + dummy] - earlier[1 + dummy] for dummy in range(far)]
        if any(value > 1 or value < 0 for value in increments):
            return replace(base, status='alert', explanation='a dummy took two strikes between two reads: the polls do '
                                                             'not separate the pulses')
        struck = sum(1 for value in increments if value > 0)
        if struck:
            pulses.append((later[0] - rows[0][0], struck))
    if len(pulses) < PULSE_TARGETS_MINIMUM_PULSES:
        return replace(base, status='unmeasured', measured=float(len(pulses)),
                       explanation=f'{len(pulses)} pulses read, fewer than {PULSE_TARGETS_MINIMUM_PULSES}')
    widest = max(struck for _, struck in pulses)
    status = 'ok' if widest == expected else 'alert'
    return replace(base, status=status, measured=float(widest), expected=float(expected), low=float(expected),
                   high=float(expected),
                   explanation=f'{len(pulses)} pulses; dummies struck per pulse {[struck for _, struck in pulses]} '
                               f'(of {far} inside the radius), at most {widest} against the stated {expected}; the far '
                               f'dummy never struck')
