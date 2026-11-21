from dataclasses import dataclass

NAME = 'target_attack_window'
ORDER = 26
WINDOW_METRIC = 'melee_attacks_taken'
BEFORE_START = 'attack_window_before'
AFTER_START = 'attack_window_after'


@dataclass(frozen=True)
class AttackWindow:
    engage_ms: int
    land_ms: int


def parse(raw) -> AttackWindow:
    if not isinstance(raw, dict) or set(raw) != {'engage_ms', 'land_ms'} \
            or not all(type(raw[key]) is int and raw[key] >= 0 for key in raw):
        raise ValueError(f'target_attack_window is {{"engage_ms": n, "land_ms": n}} (ms, at least 0), not {raw!r}')
    return AttackWindow(raw['engage_ms'], raw['land_ms'])


def check(spec, window):
    if window is None:
        return
    from behaviours import TARGET
    from profile import CASTER
    if spec.gate_timing != 'start' or not spec.trigger_only_after or spec.expiry_wait_ms is not None:
        raise ValueError(f'{spec.spell} target_attack_window needs gate_timing start and trigger_only_after, without '
                         f'an expiry read: the control phase casts nothing')
    if spec.metric != WINDOW_METRIC or spec.measure_actor != CASTER or spec.fields != {'target': TARGET}:
        raise ValueError(f'{spec.spell} target_attack_window reads {WINDOW_METRIC} of the caster from the dummy '
                         f'(fields {{"target": "dummy"}})')
    if spec.target not in (TARGET, CASTER):
        raise ValueError(f'{spec.spell} target_attack_window casts its trigger at the dummy or at the caster')


def phase_steps(spec, window: AttackWindow, after: bool) -> list[dict]:
    from behaviours import TARGET
    from profile import CASTER
    if after:
        return []
    return [{'action': 'creature_attack', 'label': 'the dummy attacks the caster', 'actor': TARGET,
             'target': CASTER},
            {'action': 'wait', 'label': 'let the dummy engage', 'ms': window.engage_ms},
            start_step(BEFORE_START),
            {'action': 'wait', 'label': 'control attack window', 'ms': spec.wait_ms}]


def after_trigger_steps(spec, window: AttackWindow, after: bool) -> list[dict]:
    if not after:
        return []
    return [{'action': 'wait', 'label': 'let the trigger land', 'ms': window.land_ms}, start_step(AFTER_START)]


def start_step(name: str) -> dict:
    from behaviours import TARGET
    from profile import CASTER
    return {'action': 'snapshot', 'label': f'{name} start', 'actor': CASTER, 'metric': WINDOW_METRIC,
            'target': TARGET, 'save_as': name}


def fixtures(class_file: dict, spec, window: AttackWindow, scenario: dict):
    from behaviours import metric_delta_label
    starts = {metric_delta_label(spec, 'before'): BEFORE_START, metric_delta_label(spec, 'after'): AFTER_START}
    scenario['steps'] = [{**step, 'relative_to': starts[step['label']]}
                         if step.get('action') == 'assert' and step.get('label') in starts else step
                         for step in scenario['steps']]
    scenario['contract'] += (f' The dummy melees the caster from the start of the control phase (creature_attack, '
                             f'{window.engage_ms} ms to engage); each judged reading counts its swings at the caster '
                             f'over {spec.wait_ms} ms, from a snapshot taken at the start of the control window and '
                             f'{window.land_ms} ms after the treatment cast.')
