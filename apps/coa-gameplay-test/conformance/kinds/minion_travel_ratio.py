from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, hit_ratio_cast, prose_rule, waited_ms
from bonus import bonus_band
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import DUMMY_DISTANCE, Expectation, TARGET, dataset

KIND = 'minion_travel_ratio'
ORDER = 25

FAR = 'far'
TRAVEL_STOP_YD = 3.0
TRAVEL_MINIMUM_MS = 1000
TRAVEL_MINIMUM_POLLS = 5
TRAVEL_STALL_SHARE = 0.5
TRAVEL_STEP_OVERHEAD_MS = 9
MINIONS = ('slowed', 'control')


@dataclass(frozen=True)
class MinionTravelSpec:
    spell: int
    name: str
    quote: str
    raises: tuple[tuple[int, str, int | None], ...]
    command_spell: int
    slowed_entry: int
    control_entry: int
    expected_ratio: float
    far_yd: float
    window_ms: int
    settle_ms: int = 1000
    poll_ms: int = 100
    label_suffix: str = 'travel_ratio'


def minion_travel_spec(entry: dict) -> MinionTravelSpec:
    spec = MinionTravelSpec(int(entry['spell']), entry['name'], entry['quote'],
                            tuple((int(raw[0]), raw[1], int(raw[2]) if len(raw) > 2 else None)
                                  for raw in entry['raises']),
                            int(entry['command_spell']), int(entry['slowed_entry']), int(entry['control_entry']),
                            float(entry['expected_ratio']), float(entry['far_yd']), int(entry['window_ms']),
                            int(entry.get('settle_ms', 1000)), int(entry.get('poll_ms', 100)),
                            entry.get('label_suffix', 'travel_ratio'))
    if not 0 < spec.expected_ratio < 1 or spec.far_yd <= DUMMY_DISTANCE + 2 * TRAVEL_STOP_YD or spec.poll_ms < 25:
        raise ValueError(f'{spec.spell} minion_travel_ratio states a ratio below 1, a far dummy beyond the primary '
                         f'and polls of at least 25 ms')
    if any(target not in (CASTER, TARGET) for _, target, _ in spec.raises) or spec.slowed_entry == spec.control_entry:
        raise ValueError(f'{spec.spell} minion_travel_ratio raises at the caster or the primary, two distinct entries')
    return spec


def travel_label(spec: MinionTravelSpec, read: str) -> str:
    return f'{spec.spell} {spec.label_suffix} {read}'


def minion_travel_scenario(class_file: dict, spec: MinionTravelSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, spec.expected_ratio)
    entries = {'slowed': spec.slowed_entry, 'control': spec.control_entry}
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                for spell in dict.fromkeys((*(spell for spell, _, _ in spec.raises), spec.command_spell))])
    for spell, target, power in spec.raises:
        steps += hit_ratio_cast(records, spell, CASTER, target, power)
        steps.append({'action': 'wait', 'label': 'raise settle', 'ms': spec.settle_ms})
    steps += [measurement(travel_label(spec, f'{minion} run_speed_rate'), CASTER, 'owned_creature_run_speed_rate',
                          entry=entries[minion]) for minion in MINIONS]
    steps += hit_ratio_cast(records, spec.command_spell, CASTER, FAR)[:-1]
    rows, elapsed = [], 0
    while elapsed <= spec.window_ms:
        index = len(rows)
        row = [travel_label(spec, f'{index} time')] + [travel_label(spec, f'{index} {minion}') for minion in MINIONS]
        steps += [measurement(row[0], CASTER, 'game_time_ms')]
        steps += [measurement(label, CASTER, 'owned_creature_distance_2d', entry=entries[minion], target=FAR)
                  for label, minion in zip(row[1:], MINIONS)]
        steps.append({'action': 'wait', 'label': 'travel poll', 'ms': spec.poll_ms})
        rows.append(row)
        elapsed += spec.poll_ms + TRAVEL_STEP_OVERHEAD_MS
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour minion travel ratio',
        'contract': (f'Creatures {spec.slowed_entry} and {spec.control_entry} (the control, without the slow) are '
                     f'raised, then {spec.command_spell} sends both at a dummy {spec.far_yd:g} yd out. Every '
                     f'{spec.poll_ms} ms the game time and each creature\'s distance to that dummy are read; the yards '
                     f'per second each covers while more than {TRAVEL_STOP_YD:g} yd away and still closing at '
                     f'least half its median step (least squares over the stamped reads) must stand in the stated '
                     f'ratio {spec.expected_ratio:g}, inside the G-19 band.'),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file),
                      {**creature_fixture(class_file), 'id': FAR, 'distance': spec.far_yd}],
        'steps': steps}
    model = {'kind': KIND, 'metric': 'owned_creature_distance_2d', 'quote': entry.quote, 'rows': rows,
             'rates': [travel_label(spec, f'{minion} run_speed_rate') for minion in MINIONS],
             'expected': spec.expected_ratio}
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}', BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.slowed_entry, None, f'{spec.expected_ratio:g}',
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def travel_speed(points: list[tuple[float, float]]) -> float | str:
    moving = [(time, distance) for time, distance in points if distance > TRAVEL_STOP_YD]
    start = next((index for index in range(1, len(moving)) if moving[index][1] < moving[index - 1][1]), None)
    if start is None:
        return 'never closes on the dummy'
    moving = moving[start - 1:]
    steps = sorted(earlier[1] - later[1] for earlier, later in zip(moving, moving[1:]))
    typical = steps[len(steps) // 2]
    stop = next((index for index in range(1, len(moving))
                 if moving[index - 1][1] - moving[index][1] < typical * TRAVEL_STALL_SHARE), len(moving))
    moving = moving[:stop]
    if len(moving) < TRAVEL_MINIMUM_POLLS or moving[-1][0] - moving[0][0] < TRAVEL_MINIMUM_MS:
        return f'moves for {moving[-1][0] - moving[0][0]:g} ms only'
    mean_time = sum(time for time, _ in moving) / len(moving)
    mean_distance = sum(distance for _, distance in moving) / len(moving)
    spread = sum((time - mean_time) ** 2 for time, _ in moving)
    slope = sum((time - mean_time) * (distance - mean_distance) for time, distance in moving) / spread
    return -slope * 1000.0


def minion_travel_verdict(base, run, model: dict):
    from compare import missing_measurement
    labels = [label for row in model['rows'] for label in row] + model['rates']
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    speeds = {}
    for column, minion in enumerate(MINIONS, start=1):
        speed = travel_speed([(run.values[row[0]], run.values[row[column]]) for row in model['rows']])
        if isinstance(speed, str):
            return replace(base, status='unmeasured', explanation=f'the {minion} creature {speed}')
        speeds[minion] = speed
    if speeds['control'] <= 0:
        return replace(base, status='unmeasured', explanation='the control creature does not move towards the dummy')
    expected = float(model['expected'])
    band = bonus_band(expected * 100) / 100
    ratio = speeds['slowed'] / speeds['control']
    rates = [run.values[label] for label in model['rates']]
    status = 'ok' if abs(ratio - expected) <= band else 'alert'
    return replace(base, status=status, measured=ratio, expected=expected, low=expected - band, high=expected + band,
                   explanation=f'slowed {speeds["slowed"]:.3f} yd/s against the control {speeds["control"]:.3f} yd/s: '
                               f'ratio {ratio:.4f} against {expected:g} +- {band:g} (run speed rates read '
                               f'{rates[0]:g} and {rates[1]:g})')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return minion_travel_scenario(class_file, minion_travel_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'travel_ratio')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: minion_travel_verdict}
METRIC_EVIDENCE = {'owned_creature_distance_2d': 'event'}
