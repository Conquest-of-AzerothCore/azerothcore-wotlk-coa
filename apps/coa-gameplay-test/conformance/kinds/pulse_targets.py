from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, waited_ms
from hits import creature_fixture, timed
from kinds.cast_period import cast_period_label
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, dataset

KIND = 'pulse_targets'
ORDER = 9


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


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return pulse_targets_scenario(class_file, pulse_targets_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta "
            f"{entry.get('label_suffix', 'pulse_targets')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: pulse_targets_verdict}
