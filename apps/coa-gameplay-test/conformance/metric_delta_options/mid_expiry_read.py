from dataclasses import dataclass, replace
import math

NAME = 'mid_expiry_read'
ORDER = 49
KEYS = frozenset({'wait_ms', 'expected', 'tolerance', 'source'})


@dataclass(frozen=True)
class MidExpiryRead:
    wait_ms: int
    expected: float
    tolerance: float
    source: str


def number(value) -> bool:
    return type(value) in (int, float) and math.isfinite(value)


def parse(raw) -> MidExpiryRead:
    if (not isinstance(raw, dict) or set(raw) != KEYS
            or type(raw['wait_ms']) is not int or raw['wait_ms'] <= 0
            or not number(raw['expected']) or not number(raw['tolerance']) or raw['tolerance'] < 0
            or not isinstance(raw['source'], str) or not raw['source'].strip()):
        raise ValueError(f'mid_expiry_read is {{"wait_ms": ms > 0, "expected": finite, "tolerance": >= 0, '
                         f'"source": text}}, not {raw!r}')
    return MidExpiryRead(raw['wait_ms'], float(raw['expected']), float(raw['tolerance']), raw['source'])


def check(spec, mid: MidExpiryRead | None):
    if mid is None:
        return
    if spec.expiry_wait_ms is None or not 0 < mid.wait_ms < spec.expiry_wait_ms:
        raise ValueError(f'{spec.spell} mid_expiry_read needs expiry_wait_ms with 0 < wait_ms < expiry_wait_ms, '
                         f'not {mid.wait_ms} against {spec.expiry_wait_ms}')


def mid_label(spec) -> str:
    from behaviours import metric_delta_label
    return metric_delta_label(spec, 'mid_expiry')


def fixtures(class_file: dict, spec, mid: MidExpiryRead, scenario: dict):
    from behaviours import metric_delta_label
    from profile import measurement
    steps = scenario['steps']
    expired = next(index for index, step in enumerate(steps)
                   if step.get('label') == metric_delta_label(spec, 'expired'))
    wait_index = next(index for index in range(expired - 1, -1, -1)
                      if steps[index].get('action') == 'wait'
                      and steps[index].get('label') == 'let the triggering aura actually expire')
    remaining_ms = spec.expiry_wait_ms - mid.wait_ms
    split = [
        {'action': 'wait', 'label': 'mid-expiry wait', 'ms': mid.wait_ms},
        measurement(mid_label(spec), spec.measure_actor, spec.metric, **spec.fields),
        {'action': 'wait', 'label': 'let the triggering aura actually expire', 'ms': remaining_ms},
    ]
    scenario['steps'] = steps[:wait_index] + split + steps[wait_index + 1:]
    scenario['contract'] += (f' A mid-expiry reading follows {mid.wait_ms} ms into the expiry wait (before the '
                             f'remaining {remaining_ms} ms wait), expected {mid.expected:g} within '
                             f'{mid.tolerance:g} ({mid.source}).')


def model(spec, mid: MidExpiryRead) -> dict:
    return {NAME: {'mid_label': mid_label(spec), 'wait_ms': mid.wait_ms, 'expected': mid.expected,
                   'tolerance': mid.tolerance, 'source': mid.source}}


def verdict(verdict, run, mid: dict):
    from compare import missing_measurement
    measured = run.values.get(mid['mid_label'])
    if measured is None:
        return replace(verdict, status='unmeasured', explanation=missing_measurement(run, mid['mid_label']))
    held = abs(measured - mid['expected']) <= mid['tolerance']
    explanation = (f'{verdict.explanation}; {measured:g} at {mid["wait_ms"]} ms into the expiry wait '
                   f'(expected {mid["expected"]:g} within {mid["tolerance"]:g})')
    return replace(verdict, status=verdict.status if held else 'alert', explanation=explanation)
