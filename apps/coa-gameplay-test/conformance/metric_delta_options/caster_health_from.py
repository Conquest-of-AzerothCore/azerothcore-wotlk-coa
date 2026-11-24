NAME = 'caster_health_from'
ORDER = 26
SETTLE_MS = 1000


def parse(raw) -> int:
    if not isinstance(raw, int) or isinstance(raw, bool) or not 0 < raw <= 100:
        raise ValueError(f'caster_health_from is the percent the caster enters its health from, 1-100, not {raw!r}')
    return raw


def check(spec, pct):
    if pct is not None and (spec.caster_health_pct is None or pct == spec.caster_health_pct
                            or not spec.disable_regeneration):
        raise ValueError(f'{spec.spell} caster_health_from enters caster_health_pct from another percent, so it needs '
                         f'caster_health_pct, a different percent and disable_regeneration')


def phase_steps(spec, pct: int, after: bool) -> list[dict]:
    from profile import CASTER
    from values import fixture_health_step
    return [fixture_health_step(CASTER, pct),
            {'action': 'wait', 'label': f'health from {pct}% settle', 'ms': SETTLE_MS}]


def fixtures(class_file: dict, spec, pct: int, scenario: dict):
    scenario['contract'] += (f' In each phase the caster is first set to {pct}% health and held there {SETTLE_MS} ms, '
                             f'then set to {spec.caster_health_pct}% before the trigger, so a health state with '
                             f'hysteresis is entered from {"above" if pct > spec.caster_health_pct else "below"}.')


def model(spec, pct: int) -> dict:
    return {NAME: pct}
