from dataclasses import dataclass

NAME = 'forced_roll'
ORDER = 4


@dataclass(frozen=True)
class ForcedRoll:
    talent: int
    release_after_setup: int | None = None


def parse(raw) -> ForcedRoll:
    if isinstance(raw, dict):
        unknown = set(raw) - {'talent', 'release_after_setup'}
        if unknown or 'talent' not in raw:
            raise ValueError(f'forced_roll takes a talent and an optional release_after_setup, not {sorted(raw)}')
        release = raw.get('release_after_setup')
        return ForcedRoll(int(raw['talent']), None if release is None else int(release))
    return ForcedRoll(int(raw))


def released_label(spec) -> str:
    return f'{spec.spell} forced_roll released'


def check(spec, roll):
    if roll is None:
        return
    if spec.forced_chance is not None:
        raise ValueError(f'{spec.spell} sets forced_roll and forced_chance; forced_chance already forces the roll')
    if roll.release_after_setup is not None and not 0 <= roll.release_after_setup < len(spec.setup_casts):
        raise ValueError(f'{spec.spell} forced_roll releases after setup cast {roll.release_after_setup}, which the '
                         f'entry does not have')


def release_steps(talent: int) -> list[dict]:
    from behaviours import FORCED_CHANCE_OWNER_AURA
    from profile import CASTER
    return [{'action': 'set_aura', 'actor': CASTER, 'spell': FORCED_CHANCE_OWNER_AURA, 'stacks': 0},
            {'action': 'unlearn', 'actor': CASTER, 'spell': talent}]


def setup_cast_steps(spec, roll: ForcedRoll, index: int, after: bool) -> list[dict]:
    return release_steps(roll.talent) if after and index == roll.release_after_setup else []


def fixtures(class_file: dict, spec, roll: ForcedRoll, scenario: dict):
    from behaviours import FORCED_CHANCE_OP, FORCED_CHANCE_OWNER_AURA, FORCED_CHANCE_PERCENT
    from profile import CASTER, base_steps, measurement
    settled = len(base_steps(class_file))
    steps = scenario['steps']
    scenario['steps'] = (steps[:settled]
                         + [{'action': 'spell_mod_mutant', 'actor': CASTER, 'spell': roll.talent,
                             'op': FORCED_CHANCE_OP, 'percent': FORCED_CHANCE_PERCENT}]
                         + steps[settled:]
                         + [{'action': 'set_aura', 'actor': CASTER, 'spell': FORCED_CHANCE_OWNER_AURA, 'stacks': 0},
                            measurement(released_label(spec), CASTER, 'spell_mod_mutants')])
    scenario['contract'] += (f' A forcing fixture raises the roll of {roll.talent} by {FORCED_CHANCE_PERCENT}% (a '
                             f'SPELLMOD_CHANCE_OF_SUCCESS spell modifier mutant) for the whole scenario; it is removed '
                             f'at the end and read gone.')
    if roll.release_after_setup is not None:
        scenario['contract'] += (f' In the treatment phase the mutant is removed and {roll.talent} unlearned right '
                                 f'after setup cast {roll.release_after_setup + 1}, so later casts cannot roll it again.')


def model(spec, roll: ForcedRoll) -> dict:
    return {'forced_roll': {'talent': roll.talent, 'released_label': released_label(spec)}}
