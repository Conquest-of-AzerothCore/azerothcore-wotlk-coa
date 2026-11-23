NAME = 'after_target_health'
ORDER = 14


def parse(raw) -> int:
    if isinstance(raw, bool) or not isinstance(raw, int) or raw < 1:
        raise ValueError(f'after_target_health is a positive health of the dummy, not {raw!r}')
    return raw


def check(spec, health):
    from values import DUMMY_HEALTH, TARGET
    if health is None:
        return
    if spec.target != TARGET or spec.target_health_pct is not None or spec.trigger_only_after:
        raise ValueError(f'{spec.spell} after_target_health sets the dummy\'s health in the treatment phase only, so '
                         f'it needs the dummy as the target, both phases cast and no target_health_pct')
    if health >= DUMMY_HEALTH:
        raise ValueError(f'{spec.spell} after_target_health is below the dummy\'s {DUMMY_HEALTH} health')
    if any(name == 'phase_target_health_pct' for name, _ in spec.options):
        raise ValueError(f'{spec.spell} after_target_health and phase_target_health_pct both set the dummy\'s health')


def phase_steps(spec, health: int, after: bool) -> list[dict]:
    from values import TARGET
    if not after:
        return []
    return [{'action': 'set_health', 'label': 'the treatment dummy\'s health', 'actor': TARGET, 'value': health}]


def fixtures(class_file: dict, spec, health: int, scenario: dict):
    from values import DUMMY_HEALTH
    scenario['contract'] += (f' The control phase casts at the dummy at its full {DUMMY_HEALTH} health; at the start '
                             f'of the treatment phase the dummy\'s health is set to {health} (set_health), so the '
                             f'treatment cast can kill it while the control cast cannot.')
