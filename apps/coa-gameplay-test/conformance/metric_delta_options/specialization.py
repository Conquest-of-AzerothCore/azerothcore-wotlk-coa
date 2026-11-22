NAME = 'specialization'
ORDER = 26
MAX_SPECIALIZATION = 0xFFFF
SWITCH_COPPER = 1000000


def parse(raw) -> int:
    if type(raw) is not int or not 1 <= raw <= MAX_SPECIALIZATION:
        raise ValueError(f'specialization is a specialization id from 1 to {MAX_SPECIALIZATION}, not {raw!r}')
    return raw


def phase_steps(spec, specialization: int, after: bool) -> list[dict]:
    from profile import CASTER
    if after:
        return []
    return [{'action': 'money', 'actor': CASTER, 'copper': SWITCH_COPPER},
            {'action': 'specialization', 'actor': CASTER, 'id': specialization}]


def fixtures(class_file: dict, spec, specialization: int, scenario: dict):
    scenario['contract'] += (f' The caster is given {SWITCH_COPPER} copper for the switch cost and switches to '
                             f'specialization {specialization} at the start of the before phase, a precondition '
                             f'fixture: an ability a talent teaches only in that specialization is then taught by the '
                             f'learn between the phases.')
