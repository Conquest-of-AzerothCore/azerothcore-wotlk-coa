NAME = 'before_auras'
ORDER = 3


def parse(raw) -> tuple[tuple[int, int, str, str], ...]:
    from behaviours import phase_aura
    if not isinstance(raw, list) or not raw:
        raise ValueError(f'before_auras is a non-empty list of [spell, stacks, on, by], not {raw!r}')
    return tuple(phase_aura(aura) for aura in raw)


def check(spec, auras):
    if auras is None:
        return
    if spec.gate_timing != 'between' or spec.setup_only_after or spec.attack_swings:
        raise ValueError(f'{spec.spell} sets before_auras in the control phase before the gate learn, which needs '
                         f'the default gate timing, no setup_only_after and no attack swings')
    phased = {aura[0] for aura in (*spec.phase_auras, *spec.after_auras)}
    if any(aura[0] in phased for aura in auras):
        raise ValueError(f'{spec.spell} before_auras {[aura[0] for aura in auras]} are also phase or after auras, '
                         f'which would set them again after the gate learn')


def phase_steps(spec, auras, after: bool) -> list[dict]:
    from behaviours import phase_aura_step
    return [] if after else [phase_aura_step(aura) for aura in auras]
