NAME = 'phase_target_health_pct'
ORDER = 13


def parse(raw) -> tuple[int, int]:
    if not isinstance(raw, list) or len(raw) != 2 or not all(
            isinstance(pct, int) and not isinstance(pct, bool) and 0 < pct <= 100 for pct in raw) or raw[1] >= raw[0]:
        raise ValueError(f'phase_target_health_pct is [before pct, lower after pct], each 1-100, not {raw!r}')
    return raw[0], raw[1]


def check(spec, pcts):
    from values import TARGET
    if pcts is not None and (spec.target != TARGET or spec.target_health_pct is not None):
        raise ValueError(f'{spec.spell} phase_target_health_pct holds the dummy\'s health once per phase, so it needs '
                         f'the dummy as the target and no target_health_pct before every trigger')


def phase_steps(spec, pcts: tuple[int, int], after: bool) -> list[dict]:
    from profile import CASTER
    from values import TARGET
    return [{'action': 'set_health_pct', 'actor': CASTER, 'target': TARGET, 'pct': pcts[1] if after else pcts[0]}]


def fixtures(class_file: dict, spec, pcts: tuple[int, int], scenario: dict):
    scenario['contract'] += (f' The dummy\'s health is set once at the start of each phase, before its setup casts: '
                             f'{pcts[0]}% in the before phase and {pcts[1]}% in the after phase (lower, since the '
                             f'before phase\'s hits already took it below {pcts[0]}% and a health fixture cannot raise '
                             f'it), so a health-gated setup cast and the trigger cast both see it below the gate.')


def model(spec, pcts: tuple[int, int]) -> dict:
    return {NAME: list(pcts)}
