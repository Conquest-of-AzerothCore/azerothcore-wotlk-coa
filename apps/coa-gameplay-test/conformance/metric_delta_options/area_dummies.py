from dataclasses import replace
from math import atan2, degrees, dist, hypot, isfinite, radians, sin, tan

NAME = 'area_dummies'
ORDER = 6
MAX_AREA_DUMMIES = 11
CONE_KEYS = {'angle', 'source', 'radius'}
CONE_OPTIONAL = {'offset', 'margin_pct', 'behind'}
CONE_BEARING_TOLERANCE_DEG = 1.0
CONE_HEIGHT_TOLERANCE_YD = 1.0
CONE_MIN_DISTANCE_YD = 4.0
CONE_ARMS = ('dummy', 'area1', 'area2')
EDGE_KEYS = {'radius', 'reach', 'reach_source', 'leeway', 'source'}
EDGE_OPTIONAL = {'margin_pct'}
EDGE_ARMS = ('area1', 'area2')
EDGE_PLAN_TOLERANCE_YD = 0.25
EDGE_REACH_TOLERANCE_YD = 0.01
EDGE_TARGET_REACH_RULE = ('Spell.cpp:9437-9442: a unit target of a SRC, DEST or TARGET reference area search, by a '
                          'player-controlled caster and not itself player-controlled, adds its combat reach to the '
                          'radius (GetExactDist to the search center, 3D)')
EDGE_RELOCATIONS = ('relocate_before_trigger', 'relocate_during_wait', 'moving_before_trigger')
PLACED_TOP_KEYS = {'placed', 'casts_before'}
PLACED_ITEM_KEYS = {'dx', 'dy', 'before_expected', 'expected'}
PLACED_ITEM_OPTIONAL = {'tolerance'}
PLACED_MAX_DISTANCE_YD = 100.0
PLACED_POSITION_TOLERANCE_YD = 0.25
PLACED_HEIGHT_TOLERANCE_YD = 1.0
PLACED_CASTING_METRIC = 'area_casting'
METRIC_EVIDENCE = {PLACED_CASTING_METRIC: 'state'}
STATE_PROMISES = {PLACED_CASTING_METRIC: r'all enemies|around you|nearby enemies|interrupt\w*|\bcast\w*'}


class ConeDummies(tuple):
    cone: dict


def cone_plan(cone: dict) -> dict:
    half = cone['angle'] / 2
    margin = half * cone['margin_pct'] / 100
    offset = cone['offset']
    bearings = {'inside': half - margin, 'outside': half + margin, 'behind': cone['behind']}
    reach = {arm: offset / sin(radians(bearing)) for arm, bearing in bearings.items()}
    start = offset / abs(tan(radians(cone['behind']))) + CONE_MIN_DISTANCE_YD
    along = {arm: start + offset / tan(radians(bearing)) for arm, bearing in bearings.items()}
    return {'bearing': bearings, 'distance': reach, 'x': along, 'start': start, 'offset': offset}


def parse_cone(raw: dict) -> ConeDummies:
    cone = raw.get('cone')
    if set(raw) != {'cone'} or not isinstance(cone, dict) or CONE_KEYS - set(cone) or set(cone) - CONE_KEYS - CONE_OPTIONAL:
        raise ValueError(f'area_dummies cone is {{"cone": {{"angle": degrees, "radius": yd, "source": text, optional '
                         f'"offset", "margin_pct", "behind"}}}}, not {raw!r}')
    numbers = {'angle': cone['angle'], 'radius': cone['radius'], 'offset': cone.get('offset', 6.0),
               'margin_pct': cone.get('margin_pct', 10.0), 'behind': cone.get('behind', 135.0)}
    if any(isinstance(value, bool) or not isinstance(value, (int, float)) for value in numbers.values()) \
            or not isinstance(cone['source'], str) or len(cone['source'].strip()) < 20:
        raise ValueError('area_dummies cone takes numbers and a source text of at least 20 characters citing the '
                         'DBC cone field or the code line that sets the angle, never a reading')
    cone = {**{key: float(value) for key, value in numbers.items()}, 'source': cone['source']}
    half = cone['angle'] / 2
    outside = half * (1 + cone['margin_pct'] / 100)
    if not (20 <= cone['angle'] <= 160 and 0 < cone['margin_pct'] <= 50 and outside < 85
            and 100 <= cone['behind'] <= 170 and 0.5 <= cone['offset'] <= 12 and cone['radius'] > 0):
        raise ValueError(f'area_dummies cone {cone!r} needs an angle of 20 to 160 degrees with its outside bearing '
                         f'under 85, a margin_pct of at most 50, a behind bearing of 100 to 170, an offset of 0.5 to 12 '
                         f'yd and a positive radius')
    plan = cone_plan(cone)
    if any(not CONE_MIN_DISTANCE_YD <= distance <= cone['radius'] - 1 for distance in plan['distance'].values()) \
            or plan['start'] + cone['offset'] > 20 or max(plan['x'].values()) > 100:
        raise ValueError(f'area_dummies cone distances {plan["distance"]} must lie between {CONE_MIN_DISTANCE_YD:g} '
                         f'yd and the radius less 1 yd, and the caster start within the 20 yd relocate bound')
    result = ConeDummies((plan['x']['outside'], plan['x']['behind']))
    result.cone = {**cone, 'plan': plan}
    return result


class EdgeDummies(tuple):
    edge: dict


def parse_edge(raw: dict) -> EdgeDummies:
    from kinds.radius_edge import radius_edge_leeway
    edge = raw.get('edge')
    if set(raw) != {'edge'} or not isinstance(edge, dict) or EDGE_KEYS - set(edge) \
            or set(edge) - EDGE_KEYS - EDGE_OPTIONAL:
        raise ValueError(f'area_dummies edge is {{"edge": {{"radius": yd, "reach": yd, "reach_source": text, '
                         f'"leeway": bool, "source": text, optional "margin_pct"}}}}, not {raw!r}')
    numbers = {'radius': edge['radius'], 'reach': edge['reach'], 'margin_pct': edge.get('margin_pct', 10.0)}
    if any(isinstance(value, bool) or not isinstance(value, (int, float)) for value in numbers.values()) \
            or not isinstance(edge['leeway'], bool) \
            or any(not isinstance(edge[key], str) or len(edge[key].strip()) < 20 for key in ('source', 'reach_source')):
        raise ValueError('area_dummies edge takes numbers, a leeway true or false, and source and reach_source texts '
                         'of at least 20 characters citing the DBC radius and the data row of the dummy\'s combat '
                         'reach, never a reading')
    numbers = {key: float(value) for key, value in numbers.items()}
    if not (numbers['radius'] > 0 and numbers['reach'] >= 0 and 0 < numbers['margin_pct'] <= 50):
        raise ValueError(f'area_dummies edge {edge!r} needs a positive radius, a reach of at least 0 and a '
                         f'margin_pct above 0 and at most 50')
    leeway = radius_edge_leeway(1.0) if edge['leeway'] else 0.0
    line = numbers['radius'] + numbers['reach'] + leeway
    margin = numbers['margin_pct'] / 100
    plan = {'edge': line, 'leeway': leeway, 'area1': line * (1 - margin), 'area2': line * (1 + margin)}
    result = EdgeDummies((plan['area1'], plan['area2']))
    result.edge = {**numbers, 'leeway': edge['leeway'], 'source': edge['source'], 'reach_source': edge['reach_source'],
                   'plan': plan}
    return result


class PlacedDummies(tuple):
    placed: dict


def finite_number(value, where: str) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not isfinite(value):
        raise ValueError(f'{where} must be a finite number, not {value!r}')
    return float(value)


def parse_placed(raw: dict) -> PlacedDummies:
    if not {'placed'} <= set(raw) <= PLACED_TOP_KEYS:
        raise ValueError(f'area_dummies placed is {{"placed": [...], optional "casts_before": [spell, ...]}}, '
                         f'not {raw!r}')
    items = raw['placed']
    if not isinstance(items, list) or not 1 <= len(items) <= MAX_AREA_DUMMIES:
        raise ValueError(f'area_dummies placed needs 1 to {MAX_AREA_DUMMIES} placements, not {items!r}')
    casts_before = raw.get('casts_before', [])
    if not isinstance(casts_before, list) or ('casts_before' in raw and not casts_before) or any(
            isinstance(spell, bool) or not isinstance(spell, int) or spell <= 0 for spell in casts_before):
        raise ValueError(f'area_dummies placed casts_before must be a non-empty list of spell ids, '
                         f'not {casts_before!r}')
    dummies, seen = [], set()
    for item in items:
        if not isinstance(item, dict) or PLACED_ITEM_KEYS - set(item) \
                or set(item) - PLACED_ITEM_KEYS - PLACED_ITEM_OPTIONAL:
            raise ValueError(f'area_dummies placed entry needs {sorted(PLACED_ITEM_KEYS)} (optional "tolerance"), '
                             f'not {item!r}')
        dx = finite_number(item['dx'], 'area_dummies placed dx')
        dy = finite_number(item['dy'], 'area_dummies placed dy')
        distance = hypot(dx, dy)
        if not (0 < distance <= PLACED_MAX_DISTANCE_YD and -PLACED_MAX_DISTANCE_YD <= dx <= PLACED_MAX_DISTANCE_YD
                and -PLACED_MAX_DISTANCE_YD <= dy <= PLACED_MAX_DISTANCE_YD):
            raise ValueError(f'area_dummies placed offset ({dx:g}, {dy:g}) must be nonzero and within '
                             f'{PLACED_MAX_DISTANCE_YD:g} yd')
        coord = (round(dx, 4), round(dy, 4))
        if coord in seen:
            raise ValueError(f'area_dummies placed repeats offset ({dx:g}, {dy:g})')
        seen.add(coord)
        before_expected = finite_number(item['before_expected'], 'area_dummies placed before_expected')
        expected = finite_number(item['expected'], 'area_dummies placed expected')
        tolerance = finite_number(item.get('tolerance', 0.0), 'area_dummies placed tolerance')
        if tolerance < 0:
            raise ValueError(f'area_dummies placed tolerance {tolerance:g} must be at least 0')
        dummies.append({'dx': dx, 'dy': dy, 'before_expected': before_expected, 'expected': expected,
                        'tolerance': tolerance})
    if not any(item['expected'] != item['before_expected'] for item in dummies):
        raise ValueError('area_dummies placed needs at least one dummy with expected != before_expected')
    result = PlacedDummies(tuple(hypot(item['dx'], item['dy']) for item in dummies))
    result.placed = {'dummies': dummies, 'casts_before': list(casts_before)}
    return result


def area_dummy_id(index: int) -> str:
    return f'area{index + 1}'


def parse(raw) -> tuple[float, ...]:
    if isinstance(raw, dict) and 'placed' in raw:
        return parse_placed(raw)
    if isinstance(raw, dict) and 'edge' in raw:
        return parse_edge(raw)
    if isinstance(raw, dict):
        return parse_cone(raw)
    if not isinstance(raw, list) or not 1 <= len(raw) <= MAX_AREA_DUMMIES:
        raise ValueError(f'area_dummies takes a list of 1 to {MAX_AREA_DUMMIES} distances in yd, not {raw!r}')
    distances = tuple(float(distance) for distance in raw)
    if any(distance <= 0 for distance in distances):
        raise ValueError(f'area_dummies distances {list(distances)} must be positive')
    return distances


def check(spec, distances):
    if distances is None:
        return
    from behaviours import TARGET
    from values import DUMMY_DISTANCE
    if spec.setup_casts and (spec.setup_target or spec.target) != TARGET:
        raise ValueError(f'{spec.spell} sets area_dummies with a setup target other than the dummy')
    if hasattr(distances, 'placed'):
        options = dict(spec.options)
        if spec.attack_swings or 'area_sum' in options or any(name in options for name in EDGE_RELOCATIONS):
            raise ValueError(f'{spec.spell} area_dummies placed refuses attack_swings, area_sum and '
                             f'{list(EDGE_RELOCATIONS)}')
        if spec.measure_actor != TARGET and spec.fields.get('target') != TARGET:
            raise ValueError(f'{spec.spell} area_dummies placed needs measure_actor or fields.target to be {TARGET!r}')
        if distances.placed['casts_before'] and spec.target != TARGET:
            raise ValueError(f'{spec.spell} area_dummies placed casts_before needs {TARGET!r} as the trigger target')
        primary_dx = float(spec.dummy_distance) if spec.dummy_distance is not None else float(DUMMY_DISTANCE)
        if any(round(item['dx'], 4) == round(primary_dx, 4) and round(item['dy'], 4) == 0.0
               for item in distances.placed['dummies']):
            raise ValueError(f'{spec.spell} area_dummies placed duplicates the primary dummy at ({primary_dx:g}, 0)')
        if spec.metric == 'casting' and spec.evidence_metric is not None:
            raise ValueError(f'{spec.spell} area_dummies placed stamps {PLACED_CASTING_METRIC} itself, not '
                             f'evidence_metric {spec.evidence_metric!r}')
    if hasattr(distances, 'edge'):
        options = dict(spec.options)
        if spec.metric not in ('spell_damage_count', 'spell_damage_total') \
                or not isinstance(spec.fields.get('spell'), int) \
                or any(name in options for name in EDGE_RELOCATIONS):
            raise ValueError(f'{spec.spell} area_dummies edge reads the hit spell\'s spell_damage_count or '
                             f'spell_damage_total (fields.spell), and refuses {list(EDGE_RELOCATIONS)}: the caster '
                             f'must stand where the geometry is read')
    if hasattr(distances, 'cone'):
        options = dict(spec.options)
        bad_setup = bool(spec.setup_casts) and (
            spec.setup_only_after or spec.setup_in_before or spec.trigger_spell in spec.setup_casts
            or spec.fields.get('spell') in spec.setup_casts)
        if spec.metric != 'spell_damage_count' or spec.target != TARGET or spec.fields.get('target') != TARGET \
                or not isinstance(spec.fields.get('spell'), int) or bad_setup or 'area_sum' in options \
                or 'relocate_before_trigger' in options or spec.cast_in_before:
            raise ValueError(f'{spec.spell} area_dummies cone judges the dummy\'s spell_damage_count of the hit '
                             f'spell, with no area_sum, no relocate_before_trigger, the trigger cast only after the '
                             f'learn (cast_in_before false), and any setup_casts distinct from the trigger and hit '
                             f'spells running only in the treatment phase')


def fixtures(class_file: dict, spec, distances: tuple[float, ...], scenario: dict):
    from behaviours import TARGET
    primary = next((creature for creature in scenario.get('creatures', ()) if creature['id'] == TARGET), None)
    if primary is None:
        raise ValueError(f'{spec.spell} sets area_dummies without the dummy in its scenario')
    names = [area_dummy_id(index) for index in range(len(distances))]
    if hasattr(distances, 'placed'):
        return placed_fixtures(spec, distances.placed, primary, names, scenario)
    if hasattr(distances, 'cone'):
        return cone_fixtures(spec, distances.cone, primary, names, scenario)
    if hasattr(distances, 'edge'):
        return edge_fixtures(class_file, spec, distances.edge, primary, names, scenario)
    scenario['creatures'] += [{**primary, 'id': name, 'distance': distance}
                              for name, distance in zip(names, distances)]
    scenario['contract'] += (f' {len(distances)} more dummies ({", ".join(names)}) stand at {list(distances)} yd '
                             f'from the caster, copies of the dummy; setup casts never target them.')


def cone_label(spec, read: str) -> str:
    return f'{spec.spell} cone {read}'


def cone_fixtures(spec, cone: dict, primary: dict, names: list[str], scenario: dict):
    from behaviours import metric_delta_label
    from profile import CASTER, measurement
    plan = cone['plan']
    primary['distance'] = plan['x']['inside']
    scenario['creatures'] += [{**primary, 'id': name, 'distance': plan['x'][arm]}
                              for name, arm in zip(names, ('outside', 'behind'))]
    arms = dict(zip(CONE_ARMS, ('inside', 'outside', 'behind')))
    casts = [index for index, step in enumerate(scenario['steps']) if step.get('action') == 'cast'
             and step.get('actor') == CASTER and step.get('spell') == spec.trigger_spell]
    if len(casts) != 1:
        raise ValueError(f'{spec.spell} area_dummies cone needs exactly one cast of {spec.trigger_spell}, finds '
                         f'{len(casts)}')
    geometry = [measurement(cone_label(spec, f'{unit} {axis}'), unit, f'position_{axis}')
                for unit in CONE_ARMS for axis in 'xyz']
    geometry.append(measurement(cone_label(spec, f'{CASTER} z'), CASTER, 'position_z'))
    casters = [measurement(cone_label(spec, f'{CASTER} {axis}'), CASTER, f'position_{axis}') for axis in 'xyo']
    steps = []
    for index, step in enumerate(scenario['steps']):
        if index == casts[0]:
            steps += [{'action': 'relocate', 'actor': CASTER, 'dx': plan['start'], 'dy': -plan['offset']}] + geometry
        if index in casts:
            steps += casters
        if step.get('label') == metric_delta_label(spec, 'after'):
            steps += [measurement(cone_label(spec, f'{arm} hits'), CASTER, 'spell_damage_count',
                                  spell=spec.fields['spell'], target=unit) for unit, arm in arms.items()
                      if unit != 'dummy']
        steps.append(step)
    scenario['steps'] = steps
    scenario['contract'] += (
        f' Cone arms ({cone["source"]}): a {cone["angle"]:g} degree cone, so the edge lies {cone["angle"] / 2:g} '
        f'degrees either side of the caster\'s facing. The caster is moved {plan["start"]:g} yd along x and '
        f'{plan["offset"]:g} yd along -y from its spawn (a relocate step; its orientation is unchanged and is read), '
        f'so the three dummies on the +x line stand at the bearings {plan["bearing"]} from its facing: the dummy '
        f'(the primary, struck: {plan["bearing"]["inside"]:g} degrees), area1 (just outside: '
        f'{plan["bearing"]["outside"]:g}) and area2 (behind the caster: {plan["bearing"]["behind"]:g}). Each bearing '
        f'is recomputed from the read positions and orientation; a dummy more than {CONE_BEARING_TOLERANCE_DEG:g} '
        f'degree off its planned bearing, or a height more than {CONE_HEIGHT_TOLERANCE_YD:g} yd off the caster\'s, '
        f'voids the trial.'
        + (' Setup casts run at the dummy before the cone relocation.' if spec.setup_casts else ''))


def edge_label(spec, read: str) -> str:
    return f'{spec.spell} edge {read}'


def edge_labels(spec, edge: dict) -> dict:
    from profile import CASTER
    units = (CASTER, *EDGE_ARMS)
    labels = {'positions': {unit: [edge_label(spec, f'{unit} {axis}') for axis in 'xyz'] for unit in units},
              'reach': {unit: edge_label(spec, f'{unit} combat_reach') for unit in units},
              'hits': {unit: edge_label(spec, f'{unit} hits') for unit in EDGE_ARMS}}
    if edge['leeway']:
        labels['run_speed_rate'] = edge_label(spec, f'{CASTER} run_speed_rate')
    return labels


def edge_fixtures(class_file: dict, spec, edge: dict, primary: dict, names: list[str], scenario: dict):
    from pathlib import Path
    from behaviours import facts_of, metric_delta_label
    from kinds.radius_edge import LEEWAY_RULE, LEEWAY_TARGETS
    from profile import CASTER, DBC_DIR, measurement
    from tooltip import Records
    from values import dataset
    if edge['leeway']:
        facts = facts_of(Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR)))), spec.fields['spell'])
        if not LEEWAY_TARGETS & {*facts.target_a, *facts.target_b}:
            raise ValueError(f'{spec.fields["spell"]} has no area target that takes the leeway (TargetA/B 15, 20 or '
                             f'56)')
    plan = edge['plan']
    scenario['creatures'] += [{**primary, 'id': name, 'distance': plan[name]} for name in names]
    labels = edge_labels(spec, edge)
    casts = [index for index, step in enumerate(scenario['steps']) if step.get('action') == 'cast'
             and step.get('actor') == CASTER and step.get('spell') == spec.trigger_spell]
    if not casts:
        raise ValueError(f'{spec.spell} area_dummies edge needs a cast of {spec.trigger_spell}')
    geometry = [measurement(label, unit, f'position_{axis}')
                for unit, triple in labels['positions'].items() for axis, label in zip('xyz', triple)]
    geometry += [measurement(label, unit, 'combat_reach') for unit, label in labels['reach'].items()]
    if edge['leeway']:
        geometry.append(measurement(labels['run_speed_rate'], CASTER, 'run_speed_rate'))
    steps = []
    for index, step in enumerate(scenario['steps']):
        if index == casts[-1]:
            steps += geometry
        steps.append(step)
        if step.get('label') == metric_delta_label(spec, 'after'):
            steps += [measurement(label, CASTER, 'spell_damage_count', spell=spec.fields['spell'], target=unit)
                      for unit, label in labels['hits'].items()]
    scenario['steps'] = steps
    scenario['contract'] += (
        f' Radius edge arms: the edge is the radius {edge["radius"]:g} yd ({edge["source"]}) plus the dummy\'s combat '
        f'reach {edge["reach"]:g} yd ({edge["reach_source"]}; {EDGE_TARGET_REACH_RULE})'
        + (f' plus the player caster\'s area leeway {plan["leeway"]:g} yd ({LEEWAY_RULE})' if edge['leeway'] else '')
        + f' = {plan["edge"]:g} yd from the caster. area1 stands {edge["margin_pct"]:g}% inside it '
        f'({plan["area1"]:g} yd) and area2 {edge["margin_pct"]:g}% beyond it ({plan["area2"]:g} yd). Before the '
        f'treatment trigger the positions of the caster, area1 and area2, their combat reaches'
        + (' and the caster\'s run speed rate' if edge['leeway'] else '')
        + f' are read; the judge recomputes the edge from the read reach'
        + (' and leeway' if edge['leeway'] else '')
        + f' and the 3D distances from the positions, and voids the trial (unmeasured) when a read reach is more than '
        f'{EDGE_REACH_TOLERANCE_YD:g} yd off the stated one, the leeway read differs from the stated one, a distance '
        f'is more than {EDGE_PLAN_TOLERANCE_YD:g} yd off its plan, or the read layout does not bracket the edge. The '
        f'caster\'s own combat reach is recorded and never judged. After the treatment reading the hits of '
        f'{spec.fields["spell"]} on area1 and area2 are read: area1 unstruck or area2 struck alerts.')


def edge_model(spec, edge: dict) -> dict:
    return {NAME: {'edge': edge, 'labels': edge_labels(spec, edge)}}


def edge_verdict(verdict, run, model: dict):
    from compare import missing_measurement
    from kinds.radius_edge import radius_edge_leeway
    from profile import CASTER
    edge, labels = model['edge'], model['labels']
    needed = [label for triple in labels['positions'].values() for label in triple] + [
        *labels['reach'].values(), *labels['hits'].values(), *([labels['run_speed_rate']] if edge['leeway'] else [])]
    values = run.values
    missing = next((label for label in needed if values.get(label) is None), None)
    if missing is not None:
        return replace(verdict, status='alert', explanation=missing_measurement(run, missing))
    plan = edge['plan']
    caster = [values[label] for label in labels['positions'][CASTER]]
    distances = {unit: round(dist(caster, [values[label] for label in labels['positions'][unit]]), 3)
                 for unit in EDGE_ARMS}
    reaches = {unit: values[labels['reach'][unit]] for unit in EDGE_ARMS}
    leeway = radius_edge_leeway(values[labels['run_speed_rate']]) if edge['leeway'] else 0.0
    hits = {unit: values[labels['hits'][unit]] for unit in EDGE_ARMS}
    read_edge = {unit: edge['radius'] + reaches[unit] + leeway for unit in EDGE_ARMS}
    lead = (f'3D distances from the read positions {distances} (planned area1 {plan["area1"]:g}, area2 '
            f'{plan["area2"]:g}), read reaches {reaches} (stated {edge["reach"]:g}), leeway {leeway:g} (stated '
            f'{plan["leeway"]:g}), caster reach {values[labels["reach"][CASTER]]:g} (recorded), edge '
            f'{plan["edge"]:g} yd, hits {hits}')
    off = [unit for unit in EDGE_ARMS if abs(reaches[unit] - edge['reach']) > EDGE_REACH_TOLERANCE_YD
           or abs(distances[unit] - plan[unit]) > EDGE_PLAN_TOLERANCE_YD]
    if off or abs(leeway - plan['leeway']) > EDGE_REACH_TOLERANCE_YD \
            or not distances['area1'] < read_edge['area1'] < distances['area2'] \
            or not distances['area1'] < read_edge['area2'] < distances['area2']:
        return replace(verdict, status='unmeasured',
                       explanation=f'the read layout does not bracket the stated edge (off {off}): {lead}')
    if verdict.status == 'unmeasured':
        return replace(verdict, explanation=f'{verdict.explanation}; {lead}')
    if hits['area1'] <= 0 or hits['area2'] != 0:
        return replace(verdict, status='alert', explanation=f'{verdict.explanation}; area1 inside the edge must be '
                                                            f'struck and area2 beyond it never: {lead}')
    return replace(verdict, explanation=f'{verdict.explanation}; area1 inside the edge struck, area2 beyond it not: '
                                        f'{lead}')


def placed_label(spec, read: str) -> str:
    return f'{spec.spell} placed {read}'


def placed_labels(spec, names: list[str]) -> dict:
    from behaviours import TARGET
    from profile import CASTER
    units = (CASTER, TARGET, *names)
    return {'positions': {unit: [placed_label(spec, f'{unit} {axis}') for axis in 'xyz'] for unit in units},
            'before': {name: placed_label(spec, f'{name} before') for name in names},
            'after': {name: placed_label(spec, f'{name} after') for name in names}}


def placed_area_casts(names: list[str], casts_before: list[int]) -> list[dict]:
    from behaviours import TARGET_CAST_SETTLE_MS
    return [step for spell in casts_before for step in (
        *[{'action': 'cast', 'actor': name, 'spell': spell} for name in names],
        {'action': 'wait', 'label': f'{spell} area cast settle', 'ms': TARGET_CAST_SETTLE_MS})]


def placed_area_reads(spec, names: list[str], labels_by_name: dict[str, str]) -> list[dict]:
    from behaviours import TARGET
    from profile import measurement
    if spec.measure_actor == TARGET:
        return [measurement(labels_by_name[name], name, spec.metric, **spec.fields) for name in names]
    return [measurement(labels_by_name[name], spec.measure_actor, spec.metric, **{**spec.fields, 'target': name})
            for name in names]


def placed_fixtures(spec, placed: dict, primary: dict, names: list[str], scenario: dict):
    from behaviours import AFTER, BEFORE, metric_delta_label
    from profile import CASTER, measurement
    extra_base = {key: value for key, value in primary.items() if key != 'distance'}
    scenario['creatures'] += [{**extra_base, 'id': name, 'dx': item['dx'], 'dy': item['dy']}
                              for name, item in zip(names, placed['dummies'])]
    labels = placed_labels(spec, names)
    before_label = metric_delta_label(spec, BEFORE)
    after_label = metric_delta_label(spec, AFTER)
    raw_steps = scenario['steps']
    before_index = next(index for index, step in enumerate(raw_steps) if step.get('label') == before_label)
    after_index = next(index for index, step in enumerate(raw_steps) if step.get('label') == after_label)
    casts = [index for index, step in enumerate(raw_steps) if step.get('action') == 'cast'
             and step.get('actor') == CASTER and step.get('spell') == spec.trigger_spell]
    before_casts = [index for index in casts if index < before_index]
    after_casts = [index for index in casts if before_index < index < after_index]
    if not after_casts:
        raise ValueError(f'{spec.spell} area_dummies placed needs a treatment cast of {spec.trigger_spell}')
    before_cast_insert = before_casts[-1] if before_casts else before_index
    after_cast_insert = after_casts[-1]
    geometry = [measurement(label, unit, f'position_{axis}')
                for unit, triple in labels['positions'].items() for axis, label in zip('xyz', triple)]
    casts_before = placed['casts_before']
    steps = []
    for index, step in enumerate(raw_steps):
        if casts_before and index == before_cast_insert:
            steps += placed_area_casts(names, casts_before)
        if index == after_cast_insert:
            steps += geometry
            if casts_before:
                steps += placed_area_casts(names, casts_before)
        steps.append(step)
        if index == before_index:
            steps += placed_area_reads(spec, names, labels['before'])
        if index == after_index:
            steps += placed_area_reads(spec, names, labels['after'])
    scenario['steps'] = steps
    layout = ', '.join(f'{name} at ({item["dx"]:g}, {item["dy"]:g}) yd expecting '
                       f'{item["before_expected"]:g} -> {item["expected"]:g}'
                       + (f' +- {item["tolerance"]:g}' if item['tolerance'] else '')
                       for name, item in zip(names, placed['dummies']))
    scenario['contract'] += (
        f' Placed area dummies: {layout}. Before the treatment trigger cast, the 3D positions of the caster, '
        f'dummy and every placed dummy are read; any dummy more than {PLACED_POSITION_TOLERANCE_YD:g} yd off its '
        f'planned (dx, dy) offset or more than {PLACED_HEIGHT_TOLERANCE_YD:g} yd off the caster\'s height voids the '
        f'trial (unmeasured). After each phase\'s primary reading, {spec.metric} is read on every placed dummy and '
        f'any mismatch alerts.'
        + (f' Each placed dummy casts {casts_before} before each phase.' if casts_before else ''))


def placed_model(spec, placed: dict) -> dict:
    from values import DUMMY_DISTANCE
    names = [area_dummy_id(index) for index in range(len(placed['dummies']))]
    primary_dx = float(spec.dummy_distance) if spec.dummy_distance is not None else float(DUMMY_DISTANCE)
    entry = {NAME: {'placed': {**placed, 'names': names, 'primary_dx': primary_dx},
                    'labels': placed_labels(spec, names)}}
    if spec.metric == 'casting':
        entry['evidence_metric'] = PLACED_CASTING_METRIC
    return entry


def placed_verdict(verdict, run, model: dict):
    from behaviours import TARGET
    from compare import missing_measurement
    from profile import CASTER
    placed, labels = model['placed'], model['labels']
    names = placed['names']
    needed = [label for triple in labels['positions'].values() for label in triple] + [
        *labels['before'].values(), *labels['after'].values()]
    values = run.values
    missing = next((label for label in needed if values.get(label) is None), None)
    if missing is not None:
        return replace(verdict, status='alert', explanation=missing_measurement(run, missing))
    cx, cy, cz = (values[label] for label in labels['positions'][CASTER])
    planned = {TARGET: (placed['primary_dx'], 0.0),
               **{name: (item['dx'], item['dy']) for name, item in zip(names, placed['dummies'])}}
    measured_pos, off = {}, []
    for unit, (px, py) in planned.items():
        ux, uy, uz = (values[label] for label in labels['positions'][unit])
        adx, ady, adz = ux - cx, uy - cy, uz - cz
        measured_pos[unit] = (round(adx, 2), round(ady, 2))
        if hypot(adx - px, ady - py) > PLACED_POSITION_TOLERANCE_YD or abs(adz) > PLACED_HEIGHT_TOLERANCE_YD:
            off.append(unit)
    readings = {name: (values[labels['before'][name]], values[labels['after'][name]]) for name in names}
    lead = f'placed offsets {measured_pos}, readings {readings}'
    if off:
        return replace(verdict, status='unmeasured', explanation=f'misplaced dummies {off}: {lead}')
    if verdict.status == 'unmeasured':
        return replace(verdict, explanation=f'{verdict.explanation}; {lead}')
    failures = []
    for name, item in zip(names, placed['dummies']):
        before_val, after_val = readings[name]
        tol = item['tolerance']
        if abs(before_val - item['before_expected']) > tol:
            failures.append(f'{name} before {before_val:g} vs {item["before_expected"]:g} +- {tol:g}')
        if abs(after_val - item['expected']) > tol:
            failures.append(f'{name} after {after_val:g} vs {item["expected"]:g} +- {tol:g}')
    if failures:
        return replace(verdict, status='alert',
                       explanation=f'{verdict.explanation}; placed dummy mismatch ({"; ".join(failures)}): {lead}')
    if verdict.status != 'ok':
        return replace(verdict, explanation=f'{verdict.explanation}; {lead}')
    return replace(verdict, explanation=f'{verdict.explanation}; placed dummies matched: {lead}')


def model(spec, distances):
    if hasattr(distances, 'placed'):
        return placed_model(spec, distances.placed)
    if hasattr(distances, 'edge'):
        return edge_model(spec, distances.edge)
    if not hasattr(distances, 'cone'):
        return {}
    cone = distances.cone
    return {NAME: {'cone': cone, 'labels': {
        'positions': {unit: [cone_label(spec, f'{unit} {axis}') for axis in 'xyz'] for unit in CONE_ARMS},
        'caster_z': cone_label(spec, 'caster z'),
        'caster': [cone_label(spec, f'caster {axis}') for axis in 'xyo'],
        'hits': {'outside': cone_label(spec, 'outside hits'), 'behind': cone_label(spec, 'behind hits')}}}}


def verdict(verdict, run, model: dict):
    if 'placed' in model:
        return placed_verdict(verdict, run, model)
    if 'edge' in model:
        return edge_verdict(verdict, run, model)
    from compare import missing_measurement
    labels = model['labels']
    needed = [label for triple in labels['positions'].values() for label in triple] + [labels['caster_z'],
              *labels['caster'], *labels['hits'].values()]
    values = run.values
    missing = next((label for label in needed if values.get(label) is None), None)
    if missing is not None:
        return replace(verdict, status='alert', explanation=missing_measurement(run, missing))
    cone = model['cone']
    plan = cone['plan']
    x, y, o = (values[label] for label in labels['caster'])
    z = values[labels['caster_z']]
    measured, off = {}, []
    for arm, unit in zip(('inside', 'outside', 'behind'), CONE_ARMS):
        ux, uy, uz = (values[label] for label in labels['positions'][unit])
        bearing = (degrees(atan2(uy - y, ux - x) - o) + 180) % 360 - 180
        measured[arm] = round(abs(bearing), 2)
        if abs(abs(bearing) - plan['bearing'][arm]) > CONE_BEARING_TOLERANCE_DEG \
                or abs(uz - z) > CONE_HEIGHT_TOLERANCE_YD or not CONE_MIN_DISTANCE_YD <= hypot(ux - x, uy - y) <= cone['radius']:
            off.append(arm)
    lead = (f'bearings from the read positions {measured} (planned {({a: round(b, 2) for a, b in plan["bearing"].items()})}), '
            f'hits outside {values[labels["hits"]["outside"]]:g} and behind {values[labels["hits"]["behind"]]:g}; '
            f'cone {cone["angle"]:g} degrees ({cone["source"]})')
    if off:
        return replace(verdict, status='unmeasured', explanation=f'misplaced dummies {off}: {lead}')
    if verdict.status != 'ok':
        return replace(verdict, explanation=f'{verdict.explanation}; {lead}')
    if values[labels['hits']['outside']] != 0 or values[labels['hits']['behind']] != 0:
        return replace(verdict, status='alert', explanation=f'a dummy outside the cone was struck: {lead}')
    return replace(verdict, explanation=f'{verdict.explanation}; the primary inside the cone is struck, the dummies '
                                        f'outside it and behind the caster are not: {lead}')
