NAME = 'specialization'
ORDER = 26
MAX_SPECIALIZATION = 0xFFFF


def parse(raw) -> int:
    if type(raw) is not int or not 1 <= raw <= MAX_SPECIALIZATION:
        raise ValueError(f'specialization is a specialization id from 1 to {MAX_SPECIALIZATION}, not {raw!r}')
    return raw


def phase_steps(spec, specialization: int, after: bool) -> list[dict]:
    from profile import CASTER
    if after:
        return []
    return [{'action': 'specialization', 'actor': CASTER, 'id': specialization}]


def fixtures(class_file: dict, spec, specialization: int, scenario: dict):
    scenario['contract'] += (f' The caster switches to specialization {specialization} at the start of the before '
                             f'phase, a precondition fixture: an ability a talent teaches only in that '
                             f'specialization is then taught by the learn between the phases.')
