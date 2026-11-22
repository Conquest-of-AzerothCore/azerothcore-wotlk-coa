from dataclasses import dataclass, replace
from math import hypot
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, facts_of, hit_ratio_cast, prose_rule
from hits import creature_fixture
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, dataset, required_target_health_steps

KIND = 'radius_edge'
ORDER = 21

RADIUS_EDGE_METRIC = 'spell_damage_count'
RADIUS_EDGE_PRIMARY_YD = 3.0
RADIUS_EDGE_REACH_TOLERANCE_YD = 0.01
PRIMARY, INSIDE, OUTSIDE = 'primary', 'inside', 'outside'
DUMMIES = (PRIMARY, INSIDE, OUTSIDE)
ARMS = ('control', 'treatment')
LEEWAY_TARGETS = frozenset({15, 20, 56})
LEEWAY_BONUS_RANGE_YD = 2.66
LEEWAY_MIN_MOVE_SPEED = 4.97
PLAYER_BASE_RUN_SPEED = 7.0
LEEWAY_RULE = ('Spell.cpp:1388-1394 adds GetLeewayBonusRadius to TARGET_UNIT_SRC_AREA_ENEMY, CASTER_AREA_PARTY and '
               'CASTER_AREA_RAID; Object.cpp:1787-1808 returns LEEWAY_BONUS_RANGE 2.66 yd for a player whose speed '
               'exceeds LEEWAY_MIN_MOVE_SPEED 4.97 (ObjectDefines.h:50-51), the run speed rate times 7.0 '
               '(playerBaseMoveSpeed, Unit.cpp:107-110) in run mode; run mode is required by construction: the '
               'scenario has no movement step and the harness never sets a walking flag')


@dataclass(frozen=True)
class RadiusEdgeSpec:
    spell: int
    name: str
    quote: str
    gate_spell: int
    cast_spell: int
    hit_spell: int
    radius: float
    dummy_reach: float
    reach_source: str
    margin_yd: float = 0.5
    caster_entry: int | None = None
    learn: tuple[int, ...] = ()
    setup_casts: tuple[int, ...] = ()
    power: int | None = None
    repeats: int = 3
    settle_ms: int = 1500
    label_suffix: str = 'radius_edge'
    cast_at: str = PRIMARY
    corpse: tuple[int, int, int, float] | None = None
    primary_yd: float = RADIUS_EDGE_PRIMARY_YD
    center_reach: float = 0.0
    hit_metric: str = RADIUS_EDGE_METRIC
    leeway: bool = False


def radius_edge_spec(entry: dict) -> RadiusEdgeSpec:
    spec = RadiusEdgeSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['gate_spell']),
                          int(entry['cast_spell']), int(entry['hit_spell']), float(entry['radius']),
                          float(entry['dummy_reach']), entry['reach_source'], float(entry.get('margin_yd', 0.5)),
                          int(entry['caster_entry']) if entry.get('caster_entry') is not None else None,
                          tuple(int(spell) for spell in entry.get('learn', [])),
                          tuple(int(spell) for spell in entry.get('setup_casts', [])),
                          int(entry['power']) if entry.get('power') is not None else None,
                          int(entry.get('repeats', 3)), int(entry.get('settle_ms', 1500)),
                          entry.get('label_suffix', 'radius_edge'), entry.get('cast_at', PRIMARY),
                          radius_edge_corpse(entry.get('corpse')),
                          float(entry.get('primary_yd', RADIUS_EDGE_PRIMARY_YD)),
                          float(entry.get('center_reach', 0.0)), entry.get('hit_metric', RADIUS_EDGE_METRIC),
                          entry.get('leeway', False))
    if not isinstance(spec.leeway, bool) or (spec.leeway and spec.caster_entry is not None):
        raise ValueError(f'{spec.spell} radius_edge leeway is true or false and needs the player as the caster')
    if spec.cast_at not in (PRIMARY, CASTER):
        raise ValueError(f'{spec.spell} radius_edge casts at the primary or the caster, not {spec.cast_at!r}')
    if spec.hit_metric not in (RADIUS_EDGE_METRIC, 'aura'):
        raise ValueError(f'{spec.spell} radius_edge reads damage hits or an aura, not {spec.hit_metric!r}')
    if spec.primary_yd <= 0 or spec.center_reach < 0 or (spec.center_reach and spec.corpse):
        raise ValueError(f'{spec.spell} radius_edge needs a positive primary distance and one center size')
    if spec.radius <= 0 or not 0 < spec.margin_yd < spec.radius or spec.dummy_reach < 0 or spec.repeats < 1:
        raise ValueError(f'{spec.spell} radius_edge needs a radius, a margin inside it, a dummy reach and a cast')
    if spec.gate_spell in spec.learn:
        raise ValueError(f'{spec.spell} radius_edge learns its gate {spec.gate_spell} only between the arms')
    return spec


def radius_edge_corpse(raw: dict | None) -> tuple[int, int, int, float] | None:
    if raw is None:
        return None
    if set(raw) != {'entry', 'health', 'kill_spell', 'reach'} or int(raw['health']) < 1 or float(raw['reach']) < 0:
        raise ValueError(f'radius_edge corpse {raw!r} needs an entry, a positive health, a kill spell and its reach')
    return int(raw['entry']), int(raw['health']), int(raw['kill_spell']), float(raw['reach'])


def radius_edge_leeway(run_speed_rate: float) -> float:
    return LEEWAY_BONUS_RANGE_YD if run_speed_rate * PLAYER_BASE_RUN_SPEED > LEEWAY_MIN_MOVE_SPEED else 0.0


def radius_edge_offsets(spec: RadiusEdgeSpec) -> dict[str, float]:
    edge = spec.radius + spec.dummy_reach + (spec.corpse[3] if spec.corpse else 0.0) + spec.center_reach
    edge += radius_edge_leeway(1.0) if spec.leeway else 0.0
    return {PRIMARY: 0.0, INSIDE: edge - spec.margin_yd, OUTSIDE: edge + spec.margin_yd}


def radius_edge_label(spec: RadiusEdgeSpec, read: str) -> str:
    return f'{spec.spell} {spec.label_suffix} {read}'


def radius_edge_scenario(class_file: dict, spec: RadiusEdgeSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, spec.radius)
    facts = facts_of(records, spec.cast_spell)
    if spec.leeway and not LEEWAY_TARGETS & {*facts.target_a, *facts.target_b}:
        raise ValueError(f'{spec.cast_spell} has no area target that takes the leeway (TargetA/B 15, 20 or 56)')
    offsets = radius_edge_offsets(spec)
    creatures = [{**creature_fixture(class_file), 'id': dummy, 'distance': spec.primary_yd + offsets[dummy]}
                 for dummy in DUMMIES]
    kill = []
    if spec.corpse:
        corpse_entry, health, kill_spell, _ = spec.corpse
        creatures[0].update({'entry': corpse_entry, 'health': health})
        kill = (hit_ratio_cast(records, kill_spell, CASTER, PRIMARY)
                + [{'action': 'wait', 'label': 'corpse settle', 'ms': spec.settle_ms}])
    origin = {'caster_entry': spec.caster_entry} if spec.caster_entry is not None else {}

    reading = 'aura presence' if spec.hit_metric == 'aura' else 'hits'

    def label(read: str) -> str:
        return radius_edge_label(spec, read)

    geometry = []
    for dummy in DUMMIES:
        geometry += [measurement(label(f'{dummy} combat_reach'), dummy, 'combat_reach'),
                     measurement(label(f'{dummy} position_z'), dummy, 'position_z')]
    geometry += [measurement(label(f'{dummy} distance_2d primary'), dummy, 'distance_2d', target=PRIMARY)
                 for dummy in (INSIDE, OUTSIDE)]
    if spec.leeway:
        geometry.append(measurement(label(f'{CASTER} run_speed_rate'), CASTER, 'run_speed_rate'))

    def arm(name: str) -> list[dict]:
        steps = [step for spell in spec.setup_casts for step in hit_ratio_cast(records, spell, CASTER, CASTER)]
        for _ in range(spec.repeats):
            steps += required_target_health_steps(facts, PRIMARY) if spec.cast_at == PRIMARY else []
            steps += hit_ratio_cast(records, spec.cast_spell, CASTER, spec.cast_at, spec.power)
            steps.append({'action': 'wait', 'label': f'{name} settle', 'ms': spec.settle_ms})
        if spec.hit_metric == 'aura':
            return steps + [measurement(label(f'{name} {dummy}'), dummy, 'aura', spell=spec.hit_spell, caster=CASTER)
                            for dummy in DUMMIES]
        return steps + [measurement(label(f'{name} {dummy}'), CASTER, RADIUS_EDGE_METRIC, spell=spec.hit_spell,
                                    target=dummy, **origin) for dummy in DUMMIES]

    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                for spell in dict.fromkeys((*spec.learn, *(spec.corpse or ())[2:3], spec.cast_spell))
                if spell != spec.gate_spell]
             + kill + geometry + arm(ARMS[0])
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.gate_spell}] + arm(ARMS[1]))
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour radius edge',
        'contract': (f'Three dummies on one line from the caster: the primary {spec.primary_yd:g} yd out, one '
                     f'{offsets[INSIDE]:g} yd and one {offsets[OUTSIDE]:g} yd beyond it, {spec.margin_yd:g} yd on '
                     f'each side of the stated {spec.radius:g} yd radius plus the dummy\'s combat reach '
                     f'{spec.dummy_reach:g} yd ({spec.reach_source}), the engine\'s area test '
                     f'(WorldObject::IsWithinDist3d adds the target\'s object size). Each dummy\'s combat reach, '
                     f'height and distance to the primary are read first. Control arm: {spec.repeats} casts of '
                     f'{spec.cast_spell} at the {spec.cast_at} before {spec.gate_spell} is learned; treatment arm: the '
                     f'same casts after it. {spec.hit_spell} {reading} per '
                     f'dummy are read after each arm: in the treatment '
                     f'the inside dummy is struck and the outside one never; the control strikes neither.'
                     + (f' The primary is a creature {spec.corpse[0]} killed by {spec.corpse[2]} first, a corpse whose '
                        f'object size {spec.corpse[3]:g} yd the edge adds too (WorldObject::IsWithinDistInMap, both '
                        f'radii).' if spec.corpse else '')
                     + (f' The primary is a living creature whose object size {spec.center_reach:g} yd the edge adds '
                        f'too (WorldObject::IsWithinDistInMap, both radii); it stands {spec.primary_yd:g} yd from the '
                        f'caster.' if spec.center_reach else '')
                     + (f' The edge adds the player caster\'s area leeway {radius_edge_leeway(1.0):g} yd at the base '
                        f'run speed rate 1: '
                        f'{LEEWAY_RULE}; the caster\'s run speed rate is read with the geometry and the judge '
                        f'recomputes the leeway from it.' if spec.leeway else '')),
        'players': [player_fixture(class_file)],
        'creatures': creatures,
        'steps': steps}
    model = {'kind': KIND, 'metric': spec.hit_metric, 'quote': entry.quote, 'radius': spec.radius,
             'center_size': spec.corpse is not None or spec.center_reach > 0,
             'reach': {dummy: label(f'{dummy} combat_reach') for dummy in DUMMIES},
             'height': {dummy: label(f'{dummy} position_z') for dummy in DUMMIES},
             'distance': {dummy: label(f'{dummy} distance_2d primary') for dummy in (INSIDE, OUTSIDE)},
             'arms': {arm_name: {dummy: label(f'{arm_name} {dummy}') for dummy in DUMMIES} for arm_name in ARMS}}
    if spec.center_reach > 0:
        model['center_struck'] = True
    if spec.leeway:
        model['leeway'] = label(f'{CASTER} run_speed_rate')
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}', BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.hit_spell, None, f'{spec.radius:g}',
                              prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def radius_edge_verdict(base, run, model: dict):
    from compare import missing_measurement
    labels = [*model['reach'].values(), *model['height'].values(), *model['distance'].values(),
              *(label for arm in model['arms'].values() for label in arm.values()),
              *([model['leeway']] if 'leeway' in model else [])]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    value = run.values
    radius = float(model['radius'])
    primary_z = value[model['height'][PRIMARY]]
    span = {dummy: hypot(value[model['distance'][dummy]], value[model['height'][dummy]] - primary_z)
            for dummy in (INSIDE, OUTSIDE)}
    center = value[model['reach'][PRIMARY]] if model.get('center_size') else 0.0
    rate = value[model['leeway']] if 'leeway' in model else None
    leeway = radius_edge_leeway(rate) if rate is not None else 0.0
    edge = {dummy: radius + center + leeway + value[model['reach'][dummy]] for dummy in (INSIDE, OUTSIDE)}
    if not (span[INSIDE] < edge[INSIDE] and span[OUTSIDE] >= edge[OUTSIDE]):
        return replace(base, status='unmeasured',
                       explanation=f'the layout does not bracket the edge: inside {span[INSIDE]:.2f} yd against '
                                   f'{edge[INSIDE]:.2f}, outside {span[OUTSIDE]:.2f} yd against {edge[OUTSIDE]:.2f}')
    control = {dummy: value[label] for dummy, label in model['arms']['control'].items()}
    treatment = {dummy: value[label] for dummy, label in model['arms']['treatment'].items()}
    layout = (f'inside {span[INSIDE]:.2f} yd and outside {span[OUTSIDE]:.2f} yd from the primary, edge '
              f'{radius:g} + reach {value[model["reach"][INSIDE]]:g}'
              + (f' + center {center:g}' if model.get('center_size') else '')
              + (f' + leeway {leeway:g} (caster run speed rate {rate:g} x {PLAYER_BASE_RUN_SPEED:g} = '
                 f'{rate * PLAYER_BASE_RUN_SPEED:g} yd/s against {LEEWAY_MIN_MOVE_SPEED:g}, run mode required by '
                 f'construction: no movement step, no walking flag)' if rate is not None else '') + ' yd')
    if treatment[PRIMARY] < 1 and (not model.get('center_size') or model.get('center_struck')):
        return replace(base, status='unmeasured', explanation=f'the treatment never struck the primary; {layout}')
    if any(control.values()):
        return replace(base, status='alert', measured=control[INSIDE],
                       explanation=f'the control arm struck dummies {control} without the gate; {layout}')
    status = 'ok' if treatment[INSIDE] >= 1 and treatment[OUTSIDE] == 0 else 'alert'
    return replace(base, status=status, measured=radius, expected=radius, low=span[INSIDE] - edge[INSIDE] + radius,
                   high=span[OUTSIDE] - edge[OUTSIDE] + radius,
                   explanation=f'treatment hits {treatment}, control none; {layout}; the inside dummy must be struck '
                               f'and the outside one never')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return radius_edge_scenario(class_file, radius_edge_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'radius_edge')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: radius_edge_verdict}
