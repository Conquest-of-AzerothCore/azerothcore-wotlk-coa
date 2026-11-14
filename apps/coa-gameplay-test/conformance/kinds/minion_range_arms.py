from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, hit_ratio_cast, prose_rule, relocate_steps, waited_ms
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import DUMMY_DISTANCE, Expectation, TARGET, dataset

KIND = 'minion_range_arms'
ORDER = 23

MINION_RANGE_METRIC = 'spell_heal_count'
MINION_RANGE_REACH_MARGIN_YD = 3.0
ARMS = ('near', 'far')


@dataclass(frozen=True)
class MinionRangeSpec:
    spell: int
    name: str
    quote: str
    raise_spell: int
    command_spell: int
    observe_spell: int
    minion_entry: int
    radius: float
    near_yd: float
    far_yd: float
    wait_ms: int
    settle_ms: int = 2500
    label_suffix: str = 'minion_range'


def minion_range_spec(entry: dict) -> MinionRangeSpec:
    spec = MinionRangeSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['raise_spell']),
                           int(entry['command_spell']), int(entry['observe_spell']), int(entry['minion_entry']),
                           float(entry['radius']), float(entry['near_yd']), float(entry['far_yd']),
                           int(entry['wait_ms']), int(entry.get('settle_ms', 2500)),
                           entry.get('label_suffix', 'minion_range'))
    if not DUMMY_DISTANCE < spec.near_yd < spec.radius < spec.radius + MINION_RANGE_REACH_MARGIN_YD < spec.far_yd:
        raise ValueError(f'{spec.spell} minion_range_arms places the near arm inside the radius and the far arm '
                         f'more than {MINION_RANGE_REACH_MARGIN_YD:g} yd beyond it')
    return spec


def minion_range_label(spec: MinionRangeSpec, read: str) -> str:
    return f'{spec.spell} {spec.label_suffix} {read}'


def minion_range_scenario(class_file: dict, spec: MinionRangeSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, spec.radius)

    def label(read: str) -> str:
        return minion_range_label(spec, read)

    def reads(moment: str) -> list[dict]:
        return [measurement(label(f'{moment} heals'), CASTER, MINION_RANGE_METRIC, spell=spec.observe_spell),
                measurement(label(f'{moment} caster distance'), CASTER, 'distance_2d', target=TARGET),
                measurement(label(f'{moment} minion distance'), CASTER, 'owned_creature_distance_2d',
                            entry=spec.minion_entry, target=CASTER)]

    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                for spell in (spec.raise_spell, spec.command_spell, spec.spell)]
             + hit_ratio_cast(records, spec.raise_spell, CASTER, CASTER)
             + [{'action': 'wait', 'label': 'raise settle', 'ms': spec.settle_ms}]
             + hit_ratio_cast(records, spec.command_spell, CASTER, TARGET)
             + [{'action': 'wait', 'label': 'command settle', 'ms': spec.settle_ms}])
    moved = 0.0
    for name, away in zip(ARMS, (spec.near_yd, spec.far_yd)):
        shift = DUMMY_DISTANCE + away - moved
        steps += relocate_steps(CASTER, shift) + reads(f'{name} before')
        moved += shift
        steps += hit_ratio_cast(records, spec.spell, CASTER, CASTER)
        steps += [{'action': 'wait', 'label': f'{name} channel', 'ms': spec.wait_ms}] + reads(f'{name} after')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour minion range',
        'contract': (f'{spec.raise_spell} raises creature {spec.minion_entry}, {spec.command_spell} sends it onto the '
                     f'dummy; the caster then steps along the line past the dummy to {spec.near_yd:g} yd from it '
                     f'(near arm) and casts {spec.spell}, then to {spec.far_yd:g} yd (far arm, the control) and casts '
                     f'again. Each arm reads the caster\'s and the minion\'s distances and the {spec.observe_spell} '
                     f'heals over {spec.wait_ms} ms: the minion inside {spec.radius:g} yd is healed, the one beyond '
                     f'{spec.radius:g} + {MINION_RANGE_REACH_MARGIN_YD:g} yd (its object size margin) never.'),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {'kind': KIND, 'metric': MINION_RANGE_METRIC, 'quote': entry.quote, 'radius': spec.radius,
             'arms': {name: {read: [label(f'{name} {moment} {read}') for moment in ('before', 'after')]
                             for read in ('heals', 'caster distance', 'minion distance')} for name in ARMS}}
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}', BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.observe_spell, None, f'{spec.radius:g}',
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def minion_range_verdict(base, run, model: dict):
    from compare import missing_measurement
    labels = [label for arm in model['arms'].values() for pair in arm.values() for label in pair]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    radius = float(model['radius'])
    arm = {name: {read: [run.values[label] for label in pair] for read, pair in reads.items()}
           for name, reads in model['arms'].items()}
    near_distance = max(arm['near']['minion distance'])
    far_distance = min(arm['far']['minion distance'])
    if not (near_distance < radius and far_distance > radius + MINION_RANGE_REACH_MARGIN_YD):
        return replace(base, status='unmeasured',
                       explanation=f'the minion did not hold its place: {near_distance:.2f} yd from the caster in the '
                                   f'near arm, {far_distance:.2f} yd in the far arm, against {radius:g} yd')
    heals = {name: arm[name]['heals'][1] - arm[name]['heals'][0] for name in ARMS}
    status = 'ok' if heals['near'] > 0 and heals['far'] == 0 else 'alert'
    return replace(base, status=status, measured=radius, expected=radius, low=near_distance, high=far_distance,
                   explanation=f'near arm: minion {near_distance:.2f} yd from the caster, {heals["near"]:g} heals; far '
                               f'arm (control): {far_distance:.2f} yd, {heals["far"]:g} heals; the near minion must be '
                               f'healed and the far one never')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return minion_range_scenario(class_file, minion_range_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'minion_range')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: minion_range_verdict}
