NAME = 'after_gate_cast'
ORDER = 6


def parse(raw) -> bool:
    if raw is not True:
        raise ValueError(f'after_gate_cast is true, not {raw!r}')
    return raw


def gate(spec) -> int:
    return spec.gate_spell if spec.gate_spell is not None else spec.spell


def check(spec, value):
    if value is None:
        return
    spell = gate(spec)
    present = dict(spec.options)
    if spec.gate_timing != 'between' or spec.attack_swings:
        raise ValueError(f'{spec.spell} after_gate_cast casts {spell} at the start of the after phase, which needs '
                         f'the default gate timing and no attack swings (gate_cast casts between attack phases)')
    if any(aura[0] == spell for aura in (*spec.after_auras, *spec.phase_auras)):
        raise ValueError(f'{spec.spell} after_gate_cast casts {spell}, so it is not also an after or phase aura')
    if (spell, 1, None) not in (present.get('after_start_reads') or ()):
        raise ValueError(f'{spec.spell} after_gate_cast needs after_start_reads [{{"spell": {spell}, "expected": 1}}] '
                         f'so a cast that did not land is unmeasured')
    if present.get('void_on_cast_failure') is not True:
        raise ValueError(f'{spec.spell} after_gate_cast needs void_on_cast_failure so a refused cast is unmeasured')


def phase_steps(spec, value: bool, after: bool) -> list[dict]:
    from profile import CASTER
    spell = gate(spec)
    return [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spell},
            {'action': 'cast', 'actor': CASTER, 'spell': spell, 'target': CASTER}] if after else []


def fixtures(class_file: dict, spec, value: bool, scenario: dict):
    spell = gate(spec)
    scenario['contract'] += (f' The after phase starts with a real cast of {spell} at the caster, not an aura '
                             f'fixture: learning {spell} applies nothing by itself, and the after-start read of its '
                             f'aura confirms the cast landed.')
