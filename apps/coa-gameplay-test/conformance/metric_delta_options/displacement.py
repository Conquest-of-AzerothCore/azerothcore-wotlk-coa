import math
from dataclasses import replace

NAME = 'displacement'
ORDER = 18
METRIC = 'displacement_2d'
METRIC_EVIDENCE = {METRIC: 'state', 'position_x': 'state'}
STATE_PROMISES = {METRIC: r'charge\w*|dash\w*|direction|distance|leap\w*|range|teleport\w*|yds?'}
MOMENTS = ('before', 'after')
MINIMUM_YD = 1.0
DEFAULT_BEARING_TOLERANCE = 15.0


def degrees(raw, key: str) -> float:
    if isinstance(raw, bool) or not isinstance(raw, (int, float)):
        raise ValueError(f'displacement {key} is a number of degrees, not {raw!r}')
    return float(raw)


def parse(raw) -> dict:
    if not isinstance(raw, dict) or not set(raw) <= {'bearing', 'bearing_tolerance'} or (
            'bearing_tolerance' in raw and 'bearing' not in raw):
        raise ValueError(f'displacement is {{}} or {{"bearing": degrees, "bearing_tolerance": degrees}}, not {raw!r}')
    if 'bearing' not in raw:
        return {}
    bearing = degrees(raw['bearing'], 'bearing')
    tolerance = degrees(raw.get('bearing_tolerance', DEFAULT_BEARING_TOLERANCE), 'bearing_tolerance')
    if not -180 < bearing <= 180 or not 0 < tolerance < 90:
        raise ValueError(f'displacement bearing {bearing:g} lies in (-180, 180] and its tolerance {tolerance:g} in '
                         f'(0, 90) degrees')
    return {'bearing': bearing, 'bearing_tolerance': tolerance}


def check(spec, value):
    from profile import CASTER
    if value is not None and (spec.measure_actor != CASTER or spec.attack_swings or spec.fields
                              or spec.metric != 'position_x'):
        raise ValueError(f'{spec.spell} displacement replaces the judged readings with the caster\'s displacement: '
                         f'the entry reads the caster\'s position_x without fields and no swings')


def labels(spec, moment: str) -> dict[str, str]:
    from behaviours import metric_delta_label
    base = metric_delta_label(spec, moment)
    return {read: f'{base} {read}' for read in ('start x', 'start y', 'start o', 'end x', 'end y')}


def fixtures(class_file: dict, spec, value: dict, scenario: dict):
    from behaviours import metric_delta_label
    from metric_delta_options.relocate_before_trigger import is_trigger_cast
    from profile import CASTER, measurement
    steps = scenario['steps']
    marks = {}
    start = 0
    for moment in MOMENTS:
        read = next(index for index, step in enumerate(steps) if step.get('label') == metric_delta_label(spec, moment))
        casts = [index for index in range(start, read) if is_trigger_cast(spec, steps[index])]
        names = labels(spec, moment)
        begin = casts[-1] if casts else read
        marks.setdefault(begin, []).extend(
            measurement(names[f'start {axis}'], CASTER, f'position_{axis}') for axis in ('x', 'y', 'o'))
        marks.setdefault(read, []).extend(
            measurement(names[f'end {axis}'], CASTER, f'position_{axis}') for axis in ('x', 'y'))
        start = read + 1
    scenario['steps'] = [step for index, step in enumerate(steps)
                         for step in (*marks.get(index, ()), step)]
    scenario['contract'] += (' The judged readings are the caster\'s 2D displacement: its position is read right '
                             'before the last trigger cast of each phase (right before the reading when the phase '
                             'casts none) and right before the reading, and the judge takes the distance between '
                             'the two.' + (f' The treatment displacement must also point {value["bearing"]:g} '
                                           f'degrees from the caster\'s facing at its start, within '
                                           f'{value["bearing_tolerance"]:g} degrees, and be at least {MINIMUM_YD:g} '
                                           f'yd long.' if value else ''))


def model(spec, value: dict) -> dict:
    return {NAME: {**value, **{moment: labels(spec, moment) for moment in MOMENTS},
                   'judged': {moment: f'{spec.spell} {spec.metric} {moment}' for moment in MOMENTS}},
            'evidence_metric': METRIC}


def moved(values: dict, names: dict) -> tuple[float, float, float] | None:
    found = [values.get(names[read]) for read in ('start x', 'start y', 'start o', 'end x', 'end y')]
    if any(reading is None for reading in found):
        return None
    x, y, facing, end_x, end_y = found
    return end_x - x, end_y - y, facing


def run_values(values: dict, shift: dict) -> dict:
    out = dict(values)
    for moment in MOMENTS:
        found = moved(values, shift[moment])
        out.pop(shift['judged'][moment], None)
        if found is not None:
            out[shift['judged'][moment]] = math.hypot(found[0], found[1])
    return out


def bearing_of(dx: float, dy: float, facing: float) -> float:
    angle = (math.degrees(math.atan2(dy, dx) - facing) + 180.0) % 360.0 - 180.0
    return 180.0 if angle == -180.0 else angle


def verdict(verdict, run, shift: dict):
    if 'bearing' not in shift or verdict.status == 'unmeasured':
        return verdict
    found = moved(run.values, shift['after'])
    if found is None:
        return verdict
    dx, dy, facing = found
    length = math.hypot(dx, dy)
    if length < MINIMUM_YD:
        return replace(verdict, status='alert', explanation=f'{verdict.explanation}; the treatment displacement of '
                                                            f'{length:.3g} yd is too short to show a direction')
    angle = bearing_of(dx, dy, facing)
    off = abs((angle - shift['bearing'] + 180.0) % 360.0 - 180.0)
    text = (f'{verdict.explanation}; treatment displacement {length:.3g} yd at {angle:.1f} degrees from the start '
            f'facing (stated {shift["bearing"]:g}, within {shift["bearing_tolerance"]:g})')
    return replace(verdict, status=verdict.status if off <= shift['bearing_tolerance'] else 'alert', explanation=text)
