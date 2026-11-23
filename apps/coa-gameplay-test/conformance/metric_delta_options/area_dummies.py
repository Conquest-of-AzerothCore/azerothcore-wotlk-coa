from dataclasses import replace
from math import atan2, degrees, dist, hypot, radians, sin, tan

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
            and 100 <= cone['behind'] <= 170 and 2 <= cone['offset'] <= 12 and cone['radius'] > 0):
        raise ValueError(f'area_dummies cone {cone!r} needs an angle of 20 to 160 degrees with its outside bearing '
                         f'under 85, a margin_pct of at most 50, a behind bearing of 100 to 170, an offset of 2 to 12 '
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


def area_dummy_id(index: int) -> str:
    return f'area{index + 1}'


def parse(raw) -> tuple[float, ...]:
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
    if spec.setup_casts and (spec.setup_target or spec.target) != TARGET:
        raise ValueError(f'{spec.spell} sets area_dummies with a setup target other than the dummy')
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
        if spec.metric != 'spell_damage_count' or spec.target != TARGET or spec.fields.get('target') != TARGET \
                or not isinstance(spec.fields.get('spell'), int) or spec.setup_casts or 'area_sum' in options \
                or 'relocate_before_trigger' in options or spec.cast_in_before:
            raise ValueError(f'{spec.spell} area_dummies cone judges the dummy\'s spell_damage_count of the hit '
                             f'spell, with no setup cast, no area_sum, no relocate_before_trigger, and the trigger '
                             f'cast only after the learn (cast_in_before false)')


def fixtures(class_file: dict, spec, distances: tuple[float, ...], scenario: dict):
    from behaviours import TARGET
    primary = next((creature for creature in scenario.get('creatures', ()) if creature['id'] == TARGET), None)
    if primary is None:
        raise ValueError(f'{spec.spell} sets area_dummies without the dummy in its scenario')
    names = [area_dummy_id(index) for index in range(len(distances))]
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
        f'voids the trial.')


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


def model(spec, distances):
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
