from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, hit_ratio_cast, prose_rule, waited_ms
from bonus import bonus_band
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import DUMMY_DISTANCE, Expectation, dataset

KIND = 'chase_halt'
ORDER = 26

HOOKED, CHASER, FAR = 'hooked', 'chaser', 'far'
MOVERS = (HOOKED, CHASER)
CHASE_MINIMUM_YD = 3.0
ATTACK, MOVE_POINT = 'attack', 'move_point'


@dataclass(frozen=True)
class ChaseHaltSpec:
    spell: int
    name: str
    quote: str
    learn: tuple[int, ...]
    raises: tuple[tuple[int, str, int | None, int], ...]
    chased_entry: int | None
    expected_ratio: float
    far_yd: float
    chaser_yd: float
    start_ms: int
    window_ms: int
    label_suffix: str = 'chase_halt'
    order: str = ATTACK
    move_yd: float = 0.0


def chase_halt_spec(entry: dict) -> ChaseHaltSpec:
    spec = ChaseHaltSpec(int(entry['spell']), entry['name'], entry['quote'],
                         tuple(int(spell) for spell in entry.get('learn', [])),
                         tuple((int(raw[0]), raw[1], int(raw[2]) if raw[2] is not None else None, int(raw[3]))
                               for raw in entry['raises']),
                         int(entry['chased_entry']) if entry.get('chased_entry') is not None else None,
                         float(entry['expected_ratio']), float(entry['far_yd']),
                         float(entry['chaser_yd']), int(entry['start_ms']), int(entry['window_ms']),
                         entry.get('label_suffix', 'chase_halt'), entry.get('order', ATTACK),
                         float(entry.get('move_yd', 0.0)))
    if spec.order not in (ATTACK, MOVE_POINT):
        raise ValueError(f'{spec.spell} chase_halt orders the movers to attack or to move to a point')
    if spec.order == ATTACK and spec.chased_entry is None:
        raise ValueError(f'{spec.spell} chase_halt attack order names the chased creature entry')
    if spec.order == MOVE_POINT and not CHASE_MINIMUM_YD < spec.move_yd < spec.far_yd - spec.chaser_yd:
        raise ValueError(f'{spec.spell} chase_halt point move stays short of the far dummy')
    if not 0 < spec.expected_ratio < 1 or spec.window_ms < 500 or spec.start_ms < 0:
        raise ValueError(f'{spec.spell} chase_halt states a ratio below 1 and a window of at least 500 ms')
    if not DUMMY_DISTANCE < spec.chaser_yd < spec.far_yd - CHASE_MINIMUM_YD:
        raise ValueError(f'{spec.spell} chase_halt places the chaser between the hooked dummy and the far one')
    if any(target not in (CASTER, FAR) for _, target, _, _ in spec.raises):
        raise ValueError(f'{spec.spell} chase_halt raises at the caster or the far dummy')
    return spec


def chase_label(spec: ChaseHaltSpec, read: str) -> str:
    return f'{spec.spell} {spec.label_suffix} {read}'


def chase_halt_scenario(class_file: dict, spec: ChaseHaltSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, spec.expected_ratio)
    moving = {**creature_fixture(class_file), 'stationary': False}
    creatures = [{**moving, 'id': HOOKED, 'distance': DUMMY_DISTANCE},
                 {**moving, 'id': CHASER, 'distance': spec.chaser_yd},
                 {**creature_fixture(class_file), 'id': FAR, 'distance': spec.far_yd}]

    def reads(moment: str) -> list[dict]:
        return ([measurement(chase_label(spec, f'{moment} time'), CASTER, 'game_time_ms')]
                + [measurement(chase_label(spec, f'{moment} {mover}'), mover, 'distance_2d', target=FAR)
                   for mover in MOVERS])

    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                for spell in dict.fromkeys((*spec.learn, *(spell for spell, _, _, _ in spec.raises), spec.spell))])
    for spell, target, power, settle in spec.raises:
        steps += hit_ratio_cast(records, spell, CASTER, target, power)
        steps.append({'action': 'wait', 'label': 'raise settle', 'ms': settle})
    if spec.order == ATTACK:
        steps += [{'action': 'attack_owned_creature', 'actor': mover, 'target': CASTER, 'entry': spec.chased_entry}
                  for mover in MOVERS]
    steps += hit_ratio_cast(records, spec.spell, CASTER, HOOKED)[:-1]
    steps.append({'action': 'wait', 'label': 'chase start', 'ms': spec.start_ms})
    if spec.order == MOVE_POINT:
        steps += [{'action': 'move_point', 'actor': mover, 'dx': spec.move_yd} for mover in MOVERS]
    steps += (reads('start') + [{'action': 'wait', 'label': 'chase window', 'ms': spec.window_ms}] + reads('end'))
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour chase halt',
        'contract': move_contract(spec) if spec.order == MOVE_POINT else attack_contract(spec),
        'players': [player_fixture(class_file)],
        'creatures': creatures,
        'steps': steps}
    model = {'kind': KIND, 'metric': 'distance_2d', 'quote': entry.quote, 'expected': spec.expected_ratio,
             'reads': {moment: [chase_label(spec, f'{moment} {read}') for read in ('time', *MOVERS)]
                       for moment in ('start', 'end')}}
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}', BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.spell, None, f'{spec.expected_ratio:g}',
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def attack_contract(spec: ChaseHaltSpec) -> str:
    return (f'Two movable dummies (the hooked one at {DUMMY_DISTANCE:g} yd, the chaser, the control, at '
            f'{spec.chaser_yd:g} yd) are ordered to attack the caster\'s creature {spec.chased_entry} beside '
            f'a stationary dummy {spec.far_yd:g} yd out, then {spec.spell} is cast at the hooked one. From '
            f'{spec.start_ms} ms after the cast, over {spec.window_ms} ms of stamped game time, each mover\'s '
            f'distance to the far dummy is read: the hooked dummy must cover {spec.expected_ratio:g} of the '
            f'chaser\'s yards (G-19 band), the chaser at least {CHASE_MINIMUM_YD:g} yd.')


def move_contract(spec: ChaseHaltSpec) -> str:
    return (f'Two movable dummies (the hooked one at {DUMMY_DISTANCE:g} yd, the chaser, the control, at '
            f'{spec.chaser_yd:g} yd) stand between the caster and a stationary dummy {spec.far_yd:g} yd out; '
            f'{spec.spell} is cast at the hooked one, which jumps to the caster\'s minion. {spec.start_ms} ms after '
            f'the cast, once the jump has landed, both movers get the same running point move {spec.move_yd:g} yd '
            f'towards the far dummy; over {spec.window_ms} ms of stamped game time each mover\'s distance to the far '
            f'dummy is read: the hooked dummy must cover {spec.expected_ratio:g} of the chaser\'s yards (G-19 band), '
            f'the chaser at least {CHASE_MINIMUM_YD:g} yd.')


def chase_halt_verdict(base, run, model: dict):
    from compare import missing_measurement
    labels = [label for row in model['reads'].values() for label in row]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    start, end = ([run.values[label] for label in model['reads'][moment]] for moment in ('start', 'end'))
    travelled = {mover: start[index] - end[index] for index, mover in enumerate(MOVERS, start=1)}
    elapsed = end[0] - start[0]
    if travelled[CHASER] < CHASE_MINIMUM_YD:
        return replace(base, status='unmeasured',
                       explanation=f'the control dummy covered {travelled[CHASER]:.2f} yd in {elapsed:g} ms, under '
                                   f'{CHASE_MINIMUM_YD:g} yd: it does not chase (gap T6)')
    expected = float(model['expected'])
    band = bonus_band(expected * 100) / 100
    ratio = travelled[HOOKED] / travelled[CHASER]
    status = 'ok' if abs(ratio - expected) <= band else 'alert'
    return replace(base, status=status, measured=ratio, expected=expected, low=max(0.0, expected - band),
                   high=expected + band,
                   explanation=f'over {elapsed:g} ms the hooked dummy covered {travelled[HOOKED]:.3f} yd and the '
                               f'control {travelled[CHASER]:.3f} yd: ratio {ratio:.4f} against {expected:g} +- {band:g}')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return chase_halt_scenario(class_file, chase_halt_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'chase_halt')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: chase_halt_verdict}
