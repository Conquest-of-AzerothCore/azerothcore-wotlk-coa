import math
from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, hit_ratio_cast, prose_rule, waited_ms
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, dataset

KIND = 'follow_bearing'
ORDER = 30

FRONT = 'front'
MINIONS = ('control', 'follower')
BEHIND_DEGREES = 135.0
FRIENDLY_FACTION = 35
MINIMUM_FOLLOW_YD = 0.5


@dataclass(frozen=True)
class FollowBearingSpec:
    spell: int
    name: str
    quote: str
    control_raise: tuple[int, int | None]
    control_entry: int
    follower_raise: tuple[int, int | None]
    follower_entry: int
    front_yd: float
    settle_ms: int
    label_suffix: str = 'behind'


def raise_of(raw: list) -> tuple[int, int | None]:
    return int(raw[0]), int(raw[1]) if len(raw) > 1 and raw[1] is not None else None


def follow_bearing_spec(entry: dict) -> FollowBearingSpec:
    spec = FollowBearingSpec(int(entry['spell']), entry['name'], entry['quote'], raise_of(entry['control_raise']),
                             int(entry['control_entry']), raise_of(entry['follower_raise']),
                             int(entry['follower_entry']), float(entry['front_yd']), int(entry['settle_ms']),
                             entry.get('label_suffix', 'behind'))
    if spec.control_entry == spec.follower_entry or spec.front_yd < 5 or spec.settle_ms < 1000:
        raise ValueError(f'{spec.spell} follow_bearing needs two distinct entries, a front dummy at least 5 yd out '
                         f'and a settle of at least 1000 ms')
    return spec


def bearing_label(spec: FollowBearingSpec, read: str) -> str:
    return f'{spec.spell} {spec.label_suffix} {read}'


def follow_bearing_scenario(class_file: dict, spec: FollowBearingSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, BEHIND_DEGREES)
    entries = {'control': spec.control_entry, 'follower': spec.follower_entry}
    raises = {'control': spec.control_raise, 'follower': spec.follower_raise}
    front = {**creature_fixture(class_file), 'id': FRONT, 'distance': spec.front_yd, 'faction': FRIENDLY_FACTION}
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                for spell in dict.fromkeys((spec.control_raise[0], spec.follower_raise[0]))]
             + [measurement(bearing_label(spec, 'caster front'), CASTER, 'distance_2d', target=FRONT)])
    reads = {}
    for minion in MINIONS:
        spell, power = raises[minion]
        steps += hit_ratio_cast(records, spell, CASTER, CASTER, power)
        steps.append({'action': 'wait', 'label': f'{minion} follow settle', 'ms': spec.settle_ms})
        reads[minion] = [bearing_label(spec, f'{minion} {target}') for target in ('caster', FRONT)]
        steps += [measurement(label, CASTER, 'owned_creature_distance_2d', entry=entries[minion], target=target)
                  for label, target in zip(reads[minion], (CASTER, FRONT))]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour follow bearing',
        'contract': (f'The caster faces a friendly stationary dummy {spec.front_yd:g} yd out. Creature '
                     f'{spec.control_entry} (the control, a stock follow angle) is raised and, {spec.settle_ms} ms '
                     f'later, its distances to the caster and to the dummy are read; then creature '
                     f'{spec.follower_entry} is raised and read the same way. The bearing of each creature from the '
                     f'caster\'s facing (law of cosines over the three distances) must be at least '
                     f'{BEHIND_DEGREES:g} degrees for the follower (behind) and under it for the control.'),
        'players': [player_fixture(class_file)],
        'creatures': [front],
        'steps': steps}
    model = {'kind': KIND, 'metric': 'owned_creature_distance_2d', 'quote': entry.quote,
             'caster_front': bearing_label(spec, 'caster front'), 'reads': reads, 'expected': BEHIND_DEGREES}
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}', BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.follower_entry, None, f'>= {BEHIND_DEGREES:g} degrees',
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def bearing_degrees(to_caster: float, to_front: float, caster_front: float) -> float | None:
    if to_caster < MINIMUM_FOLLOW_YD or caster_front <= 0:
        return None
    cosine = (to_caster ** 2 + caster_front ** 2 - to_front ** 2) / (2 * to_caster * caster_front)
    return math.degrees(math.acos(max(-1.0, min(1.0, cosine))))


def follow_bearing_verdict(base, run, model: dict):
    from compare import missing_measurement
    labels = [model['caster_front']] + [label for row in model['reads'].values() for label in row]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    caster_front = run.values[model['caster_front']]
    bearings = {}
    for minion in MINIONS:
        to_caster, to_front = (run.values[label] for label in model['reads'][minion])
        bearing = bearing_degrees(to_caster, to_front, caster_front)
        if bearing is None:
            return replace(base, status='unmeasured',
                           explanation=f'the {minion} stands {to_caster:.2f} yd from the caster: no bearing')
        bearings[minion] = bearing
    expected = float(model['expected'])
    if bearings['control'] >= expected:
        return replace(base, status='unmeasured',
                       explanation=f'the control also stands behind ({bearings["control"]:.1f} degrees): the read '
                                   f'does not tell a behind follower from a stock one')
    status = 'ok' if bearings['follower'] >= expected else 'alert'
    return replace(base, status=status, measured=bearings['follower'], expected=180.0, low=expected, high=180.0,
                   explanation=f'follower bearing {bearings["follower"]:.1f} degrees, control '
                               f'{bearings["control"]:.1f} degrees, against at least {expected:g}')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return follow_bearing_scenario(class_file, follow_bearing_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'behind')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: follow_bearing_verdict}
METRIC_EVIDENCE = {'owned_creature_distance_2d': 'event'}
