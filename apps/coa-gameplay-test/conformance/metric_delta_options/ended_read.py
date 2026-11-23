from dataclasses import replace

NAME = 'ended_read'
ORDER = 40
KEYS = frozenset({'unlearn', 'wait_ms', 'duration_ms'})


def parse(raw) -> dict:
    if not isinstance(raw, dict) or set(raw) != KEYS or not isinstance(raw['unlearn'], list) or not raw['unlearn'] \
            or not all(isinstance(spell, int) and not isinstance(spell, bool) and spell > 0
                       for spell in raw['unlearn']) \
            or any(not isinstance(raw[key], int) or isinstance(raw[key], bool) or raw[key] <= 0
                   for key in ('wait_ms', 'duration_ms')) or raw['wait_ms'] <= raw['duration_ms']:
        raise ValueError(f'ended_read is {{"unlearn": [spell, ...], "wait_ms": ms, "duration_ms": ms}} with a wait '
                         f'longer than the stated aura duration, not {raw!r}')
    return {'unlearn': tuple(raw['unlearn']), 'wait_ms': raw['wait_ms'], 'duration_ms': raw['duration_ms']}


def check(spec, ended):
    if ended is None:
        return
    if spec.gate_timing != 'between' or spec.expiry_wait_ms is not None or spec.attack_swings \
            or spec.setup_only_after:
        raise ValueError(f'{spec.spell} ended_read follows the after reading of the default gate timing, without '
                         f'an expiry read, attack swings or setup_only_after')


def ended_label(spec) -> str:
    from behaviours import metric_delta_label
    return metric_delta_label(spec, 'ended')


def fixtures(class_file: dict, spec, ended: dict, scenario: dict):
    from behaviours import METRIC_DELTA_UNTIMED_WAIT_MS, metric_delta_label
    from hits import MAX_ACCELERATED_SCENARIO_MS, timed
    from profile import CASTER, measurement
    steps = scenario['steps']
    after = next(index for index, step in enumerate(steps) if step.get('label') == metric_delta_label(spec, 'after'))
    added = ([{'action': 'unlearn', 'actor': CASTER, 'spell': spell} for spell in ended['unlearn']]
             + [{'action': 'wait', 'label': 'let the triggered aura end', 'ms': ended['wait_ms']},
                measurement(ended_label(spec), spec.measure_actor, spec.metric, **spec.fields)])
    scenario['steps'] = steps[:after + 1] + added + steps[after + 1:]
    waited = sum(step['ms'] for step in scenario['steps'] if step['action'] == 'wait')
    if 'timeout_ms' in scenario or waited > METRIC_DELTA_UNTIMED_WAIT_MS:
        timed(scenario, waited, MAX_ACCELERATED_SCENARIO_MS)
    scenario['contract'] += (f' After the after reading, {list(ended["unlearn"])} is unlearned and a third reading '
                             f'follows {ended["wait_ms"]} ms later, past the triggered aura\'s '
                             f'{ended["duration_ms"]} ms duration; it must equal the before reading of the same '
                             f'scenario.')


def model(spec, ended: dict) -> dict:
    from compare import METRIC_DELTA_FLOAT_TOLERANCE
    from behaviours import metric_delta_label
    tolerance = spec.tolerance if spec.tolerance is not None else METRIC_DELTA_FLOAT_TOLERANCE
    return {NAME: {'before_label': metric_delta_label(spec, 'before'), 'ended_label': ended_label(spec),
                   'tolerance': tolerance, 'unlearn': list(ended['unlearn']), 'wait_ms': ended['wait_ms']}}


def verdict(verdict, run, ended: dict):
    from compare import missing_measurement
    before, after_end = run.values.get(ended['before_label']), run.values.get(ended['ended_label'])
    if before is None or after_end is None:
        return replace(verdict, status='unmeasured', explanation=missing_measurement(
            run, ended['before_label'] if before is None else ended['ended_label']))
    back = abs(after_end - before) <= ended['tolerance']
    explanation = (f'{verdict.explanation}; {after_end:g} {ended["wait_ms"]} ms after unlearning '
                   f'{ended["unlearn"]} (expected the before reading {before:g} within {ended["tolerance"]:g})')
    return replace(verdict, status=verdict.status if back else 'alert', explanation=explanation)
