import math
from dataclasses import dataclass, replace

NAME = 'step_out'
ORDER = 32
SIDES = ('inside', 'beyond')
MOVE_LIMIT_YD = 20.0
MINIMUM_MARGIN_YD = 0.25
MOMENTS = ('out', 'held')
READS = ('distance', 'caster z', 'target z', 'caster reach', 'target reach')


@dataclass(frozen=True)
class StepOut:
    dx: float
    after_ms: int
    hold_ms: int
    radius: float
    side: str


def parse(raw) -> StepOut:
    if not isinstance(raw, dict) or set(raw) != {'dx', 'after_ms', 'hold_ms', 'radius', 'side'}:
        raise ValueError(f'step_out is {{"dx", "after_ms", "hold_ms", "radius", "side"}}, not {raw!r}')
    numbers = [raw[key] for key in ('dx', 'after_ms', 'hold_ms', 'radius')]
    if any(isinstance(value, bool) or not isinstance(value, (int, float)) for value in numbers) \
            or type(raw['after_ms']) is not int or type(raw['hold_ms']) is not int:
        raise ValueError(f'step_out takes a yard offset, two whole millisecond waits and a radius, not {raw!r}')
    value = StepOut(float(raw['dx']), raw['after_ms'], raw['hold_ms'], float(raw['radius']), raw['side'])
    if not 0 < abs(value.dx) <= MOVE_LIMIT_YD or value.after_ms < 0 or value.hold_ms <= 0 \
            or not 0 < value.radius <= 100 or value.side not in SIDES:
        raise ValueError(f'step_out moves the caster at most {MOVE_LIMIT_YD:g} yd for a positive hold, to a side of '
                         f'{SIDES} of a radius in (0, 100], not {raw!r}')
    return value


def check(spec, value):
    if value is None:
        return
    from behaviours import TARGET
    if spec.target != TARGET or spec.attack_swings:
        raise ValueError(f'{spec.spell} step_out moves the caster relative to the dummy it casts the trigger at')


def labels(spec) -> dict[str, dict[str, str]]:
    from behaviours import metric_delta_label
    after = metric_delta_label(spec, 'after')
    return {moment: {read: f'{after} {NAME} {moment} {read}' for read in READS} for moment in MOMENTS}


def geometry_steps(names: dict[str, str]) -> list[dict]:
    from behaviours import TARGET
    from profile import CASTER, measurement
    return [measurement(names['distance'], CASTER, 'distance_2d', target=TARGET),
            measurement(names['caster z'], CASTER, 'position_z'),
            measurement(names['target z'], TARGET, 'position_z'),
            measurement(names['caster reach'], CASTER, 'combat_reach'),
            measurement(names['target reach'], TARGET, 'combat_reach')]


def after_trigger_steps(spec, value: StepOut, after: bool) -> list[dict]:
    from profile import CASTER
    if not after:
        return []
    names = labels(spec)
    return ([{'action': 'wait', 'label': f'{NAME} lead', 'ms': value.after_ms},
             {'action': 'relocate', 'actor': CASTER, 'dx': value.dx}] + geometry_steps(names['out'])
            + [{'action': 'wait', 'label': f'{NAME} hold', 'ms': value.hold_ms}] + geometry_steps(names['held'])
            + [{'action': 'relocate', 'actor': CASTER, 'dx': -value.dx}])


def fixtures(class_file: dict, spec, value: StepOut, scenario: dict):
    scenario['contract'] += (f' In the treatment phase, {value.after_ms} ms after the trigger cast the caster is moved '
                             f'{value.dx:g} yd along x, to {value.side} the {value.radius:g} yd range of the dummy '
                             f'(the 3D distance less both combat reaches), held there {value.hold_ms} ms and moved '
                             f'back; the distance, both heights and both reaches are read right after the move and '
                             f'at the end of the hold.')


def model(spec, value: StepOut) -> dict:
    return {NAME: {'radius': value.radius, 'side': value.side, 'labels': labels(spec)}}


def margin(reads: dict[str, float], radius: float) -> float:
    return (math.hypot(reads['distance'], reads['caster z'] - reads['target z']) - reads['caster reach']
            - reads['target reach'] - radius)


def verdict(verdict, run, value: dict):
    reads = {moment: {read: run.values.get(label) for read, label in names.items()}
             for moment, names in value['labels'].items()}
    if any(number is None for moment in reads.values() for number in moment.values()):
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; the {NAME} layout reads are missing')
    margins = [margin(moment, float(value['radius'])) for moment in reads.values()]
    held = all(m <= -MINIMUM_MARGIN_YD for m in margins) if value['side'] == 'inside' else all(
        m >= MINIMUM_MARGIN_YD for m in margins)
    text = ', '.join(f'{m:+.2f}' for m in margins)
    if not held:
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; the caster stood {text} yd from the {value["radius"]:g} yd '
                                   f'edge, not at least {MINIMUM_MARGIN_YD:g} yd {value["side"]} it')
    return replace(verdict, explanation=f'{verdict.explanation}; the caster stood {text} yd from the '
                                        f'{value["radius"]:g} yd edge ({value["side"]})')
