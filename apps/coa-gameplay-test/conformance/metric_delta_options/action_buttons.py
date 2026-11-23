NAME = 'action_buttons'
ORDER = 31
MAXIMUM_BUTTON = 143


def parse(raw) -> list[tuple[int, int]]:
    if not isinstance(raw, list) or not raw or not all(
            isinstance(item, list) and len(item) == 2 and all(type(part) is int for part in item)
            and 0 <= item[0] <= MAXIMUM_BUTTON and item[1] > 0 for item in raw) \
            or len({item[0] for item in raw}) != len(raw):
        raise ValueError(f'action_buttons is a non-empty list of [button 0 to {MAXIMUM_BUTTON}, spell] with distinct '
                         f'buttons, not {raw!r}')
    return [(button, spell) for button, spell in raw]


def check(spec, buttons):
    if buttons is not None and not {spell for _, spell in buttons} <= set(spec.learn):
        raise ValueError(f'{spec.spell} action_buttons places spells the entry does not learn')


def phase_steps(spec, buttons: list[tuple[int, int]], after: bool) -> list[dict]:
    from profile import CASTER
    if not after:
        return []
    return [step for button, spell in buttons
            for step in ({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spell},
                         {'action': 'set_action_button', 'actor': CASTER, 'button': button, 'spell': spell})]


def fixtures(class_file: dict, spec, buttons: list[tuple[int, int]], scenario: dict):
    placed = ', '.join(f'{spell} on button {button}' for button, spell in buttons)
    scenario['contract'] += (f' In the treatment phase only, before the trigger cast, the action buttons '
                             f'of the caster hold {placed} (each spell learned in both phases, its cooldown reset); the'
                             f' control phase leaves them empty.')
