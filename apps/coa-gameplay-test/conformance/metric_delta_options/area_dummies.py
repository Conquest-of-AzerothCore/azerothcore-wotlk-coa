from dataclasses import replace
from math import atan2, degrees, hypot, radians, sin, tan

NAME = 'area_dummies'
ORDER = 6
MAX_AREA_DUMMIES = 9
CONE_KEYS = {'angle', 'source', 'radius'}
CONE_OPTIONAL = {'offset', 'margin_pct', 'behind'}
CONE_BEARING_TOLERANCE_DEG = 1.0
CONE_HEIGHT_TOLERANCE_YD = 1.0
CONE_MIN_DISTANCE_YD = 4.0
CONE_ARMS = ('dummy', 'area1', 'area2')


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


def area_dummy_id(index: int) -> str:
    return f'area{index + 1}'


def parse(raw) -> tuple[float, ...]:
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


def model(spec, distances):
    if not hasattr(distances, 'cone'):
        return {}
    cone = distances.cone
    return {NAME: {'cone': cone, 'labels': {
        'positions': {unit: [cone_label(spec, f'{unit} {axis}') for axis in 'xyz'] for unit in CONE_ARMS},
        'caster_z': cone_label(spec, 'caster z'),
        'caster': [cone_label(spec, f'caster {axis}') for axis in 'xyo'],
        'hits': {'outside': cone_label(spec, 'outside hits'), 'behind': cone_label(spec, 'behind hits')}}}}


def verdict(verdict, run, model: dict):
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
