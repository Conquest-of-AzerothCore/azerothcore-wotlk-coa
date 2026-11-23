from dataclasses import dataclass

NAME = 'relocate_during_wait'
ORDER = 13
MAX_STEP_YD = 20
MIN_INTERVAL_MS = 100
METRIC_EVIDENCE = {'cast_remaining_ms': 'state'}
STATE_PROMISES = {'cast_remaining_ms': r'move while active'}


@dataclass(frozen=True)
class RelocateDuringWait:
    every_ms: int
    count: int
    dy: float


def parse(raw) -> RelocateDuringWait:
    if not isinstance(raw, dict) or set(raw) != {'every_ms', 'count', 'dy'} \
            or any(isinstance(raw[key], bool) or not isinstance(raw[key], (int, float)) for key in raw):
        raise ValueError(f'relocate_during_wait is {{"every_ms", "count", "dy"}}, not {raw!r}')
    value = RelocateDuringWait(int(raw['every_ms']), int(raw['count']), float(raw['dy']))
    if value.every_ms < MIN_INTERVAL_MS or value.count < 2 or value.count % 2 or not 0 < abs(value.dy) <= MAX_STEP_YD:
        raise ValueError(f'relocate_during_wait needs every_ms of at least {MIN_INTERVAL_MS}, an even count of at '
                         f'least 2 and a nonzero dy of at most {MAX_STEP_YD} yd, not {raw!r}')
    return value


def after_trigger_steps(spec, value: RelocateDuringWait, after: bool) -> list[dict]:
    from profile import CASTER
    steps = []
    for index in range(value.count):
        steps += [{'action': 'wait', 'label': f'move {index + 1} of {value.count}', 'ms': value.every_ms},
                  {'action': 'relocate', 'actor': CASTER, 'dy': value.dy if index % 2 == 0 else -value.dy}]
    return steps


def fixtures(class_file: dict, spec, value: RelocateDuringWait, scenario: dict):
    scenario['contract'] += (f' After each cast of {spec.trigger_spell} the caster is moved {value.dy:g} yd along y '
                             f'and back, {value.count} moves {value.every_ms} ms apart, through the native position '
                             f'update a movement packet applies (movement interrupts run); the reading follows the '
                             f'last move by wait_ms.')


def model(spec, value: RelocateDuringWait) -> dict:
    return {NAME: {'every_ms': value.every_ms, 'count': value.count, 'dy': value.dy}}
