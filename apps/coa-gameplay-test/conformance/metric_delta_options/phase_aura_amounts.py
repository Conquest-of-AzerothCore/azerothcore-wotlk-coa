NAME = 'phase_aura_amounts'
ORDER = 3


def parse(raw) -> tuple[tuple[int, int, int], ...]:
    return tuple((int(spell), int(effect), int(amount)) for spell, effect, amount in raw)


def phase_aura_of(spec, spell: int, after: bool):
    auras = (*(spec.after_auras if after else ()), *spec.phase_auras)
    return next((aura for aura in auras if aura[0] == spell), None)


def check(spec, amounts):
    for spell, effect, amount in amounts or ():
        if effect not in (0, 1, 2):
            raise ValueError(f'{spec.spell} phase_aura_amounts sets effect {effect} of {spell}, not an effect 0-2')
        if phase_aura_of(spec, spell, True) is None:
            raise ValueError(f'{spec.spell} phase_aura_amounts sets an amount of {spell}, which is neither a phase '
                             f'aura nor an after aura of the entry')


def phase_steps(spec, amounts, after: bool) -> list[dict]:
    from behaviours import phase_aura_step
    return [{**phase_aura_step(aura), 'effect': effect, 'amount': amount} for spell, effect, amount in amounts
            for aura in (phase_aura_of(spec, spell, after),) if aura is not None]
