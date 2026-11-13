NAME = 'forced_roll'
ORDER = 4


def parse(raw) -> int:
    return int(raw)


def released_label(spec) -> str:
    return f'{spec.spell} forced_roll released'


def check(spec, talent):
    if talent is not None and spec.forced_chance is not None:
        raise ValueError(f'{spec.spell} sets forced_roll and forced_chance; forced_chance already forces the roll')


def fixtures(class_file: dict, spec, talent: int, scenario: dict):
    from behaviours import FORCED_CHANCE_OP, FORCED_CHANCE_OWNER_AURA, FORCED_CHANCE_PERCENT
    from profile import CASTER, base_steps, measurement
    settled = len(base_steps(class_file))
    steps = scenario['steps']
    scenario['steps'] = (steps[:settled]
                         + [{'action': 'spell_mod_mutant', 'actor': CASTER, 'spell': talent, 'op': FORCED_CHANCE_OP,
                             'percent': FORCED_CHANCE_PERCENT}]
                         + steps[settled:]
                         + [{'action': 'set_aura', 'actor': CASTER, 'spell': FORCED_CHANCE_OWNER_AURA, 'stacks': 0},
                            measurement(released_label(spec), CASTER, 'spell_mod_mutants')])
    scenario['contract'] += (f' A forcing fixture raises the roll of {talent} by {FORCED_CHANCE_PERCENT}% (a '
                             f'SPELLMOD_CHANCE_OF_SUCCESS spell modifier mutant) for the whole scenario; it is removed '
                             f'at the end and read gone.')


def model(spec, talent: int) -> dict:
    return {'forced_roll': {'talent': talent, 'released_label': released_label(spec)}}
