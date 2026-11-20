NAME = 'relocate_before_trigger'
ORDER = 12
MAX_SHIFT_YD = 40


def parse(raw) -> float:
    if not isinstance(raw, dict) or set(raw) != {'dx'} or isinstance(raw['dx'], bool) \
            or not isinstance(raw['dx'], (int, float)) or not 0 < abs(raw['dx']) <= MAX_SHIFT_YD:
        raise ValueError(f'relocate_before_trigger is {{"dx": yards}}, nonzero and at most {MAX_SHIFT_YD} yd, '
                         f'not {raw!r}')
    return float(raw['dx'])


def is_trigger_cast(spec, step: dict) -> bool:
    from profile import CASTER
    return step.get('action') == 'cast' and step.get('actor') == CASTER and step.get('spell') == spec.trigger_spell


def fixtures(class_file: dict, spec, dx: float, scenario: dict):
    from profile import CASTER
    steps = []
    for step in scenario['steps']:
        if is_trigger_cast(spec, step):
            steps.append({'action': 'relocate', 'actor': CASTER, 'dx': dx})
        steps.append(step)
    if len(steps) == len(scenario['steps']):
        raise ValueError(f'{spec.spell} relocate_before_trigger finds no cast of {spec.trigger_spell}')
    scenario['steps'] = steps
    scenario['contract'] += (f' Right before each cast of {spec.trigger_spell} the caster is moved {dx:g} yd along x '
                             f'from where it stands (the dummy stands on +x), so a charge or leap that carried it to '
                             f'the dummy in an earlier phase starts the next one from a distance again.')


def model(spec, dx: float) -> dict:
    return {NAME: dx}
