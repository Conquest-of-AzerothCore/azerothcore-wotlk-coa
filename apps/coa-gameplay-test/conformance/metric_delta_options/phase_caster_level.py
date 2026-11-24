NAME = 'phase_caster_level'
ORDER = 12
MAX_LEVEL = 80


def parse(raw) -> tuple[int, int]:
    if not isinstance(raw, list) or len(raw) != 2 or not all(
            type(level) is int and 1 <= level <= MAX_LEVEL for level in raw) or raw[0] == raw[1]:
        raise ValueError(f'phase_caster_level is [before level, after level], two different levels 1-{MAX_LEVEL}, '
                         f'not {raw!r}')
    return raw[0], raw[1]


def check(spec, levels):
    if levels is None:
        return
    if spec.trigger_only_after or not spec.cast_in_before or spec.attack_swings:
        raise ValueError(f'{spec.spell} phase_caster_level casts the trigger in both phases, one at each level')


def phase_steps(spec, levels: tuple[int, int], after: bool) -> list[dict]:
    from profile import CASTER
    level = levels[1] if after else levels[0]
    return [{'action': 'set_level', 'label': f'the {"treatment" if after else "control"} caster level',
             'actor': CASTER, 'value': level}]


def fixtures(class_file: dict, spec, levels: tuple[int, int], scenario: dict):
    scenario['contract'] += (f' The caster\'s level is set at the start of each phase (set_level, Player::GiveLevel): '
                             f'{levels[0]} for the control cast and {levels[1]} for the treatment cast, so the two '
                             f'casts differ only by the caster level.')


def model(spec, levels: tuple[int, int]) -> dict:
    return {NAME: list(levels)}
