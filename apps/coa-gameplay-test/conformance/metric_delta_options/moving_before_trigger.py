NAME = 'moving_before_trigger'
ORDER = 15
FLAGS = ('forward', 'backward', 'strafe_left', 'strafe_right')


def parse(raw) -> str:
    if not isinstance(raw, dict) or set(raw) != {'flag'} or raw['flag'] not in FLAGS:
        raise ValueError(f'moving_before_trigger is {{"flag": one of {list(FLAGS)}}}, not {raw!r}')
    return raw['flag']


def judged_labels(spec) -> set[str]:
    from behaviours import metric_delta_label
    return {metric_delta_label(spec, moment) for moment in ('before', 'after', 'expired')}


def fixtures(class_file: dict, spec, flag: str, scenario: dict):
    from profile import CASTER
    from metric_delta_options.relocate_before_trigger import is_trigger_cast
    reads = judged_labels(spec)
    steps, moving, casts = [], False, 0
    for step in scenario['steps']:
        if is_trigger_cast(spec, step):
            if not moving:
                steps.append({'action': 'set_moving', 'actor': CASTER, 'enabled': True, 'flag': flag})
                moving = True
            casts += 1
        steps.append(step)
        if moving and step.get('label') in reads:
            steps.append({'action': 'set_moving', 'actor': CASTER, 'enabled': False, 'flag': flag})
            moving = False
    if not casts:
        raise ValueError(f'{spec.spell} moving_before_trigger finds no cast of {spec.trigger_spell}')
    if moving:
        steps.append({'action': 'set_moving', 'actor': CASTER, 'enabled': False, 'flag': flag})
    scenario['steps'] = steps
    scenario['contract'] += (f' The caster holds the {flag} movement flag from right before each cast of '
                             f'{spec.trigger_spell} until the judged reading that follows it, so the cast starts and '
                             f'runs while moving.')


def model(spec, flag: str) -> dict:
    return {NAME: flag}
