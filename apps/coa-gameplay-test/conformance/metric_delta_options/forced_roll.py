from dataclasses import dataclass

NAME = 'forced_roll'
ORDER = 4
FORCED_PERCENT = 'forced_percent'
MAX_FORCED_PERCENT = 10000


@dataclass(frozen=True)
class ForcedRoll:
    talent: int
    release_after_setup: int | None = None
    forced_percent: int | None = None


def percent_of(roll: 'ForcedRoll') -> int:
    from behaviours import FORCED_CHANCE_PERCENT
    return FORCED_CHANCE_PERCENT if roll.forced_percent is None else roll.forced_percent


def parse(raw) -> ForcedRoll:
    if isinstance(raw, dict):
        unknown = set(raw) - {'talent', 'release_after_setup', FORCED_PERCENT}
        if unknown or 'talent' not in raw:
            raise ValueError(f'forced_roll takes a talent and an optional release_after_setup and {FORCED_PERCENT}, '
                             f'not {sorted(raw)}')
        release = raw.get('release_after_setup')
        percent = raw.get(FORCED_PERCENT)
        if percent is not None and (isinstance(percent, bool) or not isinstance(percent, int)
                                    or not 0 < percent <= MAX_FORCED_PERCENT):
            raise ValueError(f'forced_roll {FORCED_PERCENT} is a whole percent in (0, {MAX_FORCED_PERCENT}], not '
                             f'{percent!r}')
        return ForcedRoll(int(raw['talent']), None if release is None else int(release), percent)
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
    from behaviours import FORCED_CHANCE_OP, FORCED_CHANCE_OWNER_AURA
    from profile import CASTER, base_steps, measurement
    settled = len(base_steps(class_file))
    steps = scenario['steps']
    scenario['steps'] = (steps[:settled]
                         + [{'action': 'spell_mod_mutant', 'actor': CASTER, 'spell': roll.talent,
                             'op': FORCED_CHANCE_OP, 'percent': percent_of(roll)}]
                         + steps[settled:]
                         + [{'action': 'set_aura', 'actor': CASTER, 'spell': FORCED_CHANCE_OWNER_AURA, 'stacks': 0},
                            measurement(released_label(spec), CASTER, 'spell_mod_mutants')])
    scenario['contract'] += (f' A forcing fixture raises the roll of {roll.talent} by {percent_of(roll)}% (a '
                             f'SPELLMOD_CHANCE_OF_SUCCESS spell modifier mutant) for the whole scenario; it is removed '
                             f'at the end and read gone.')
    if roll.release_after_setup is not None:
        scenario['contract'] += (f' In the treatment phase the mutant is removed and {roll.talent} unlearned right '
                                 f'after setup cast {roll.release_after_setup + 1}, so later casts cannot roll it again.')


def model(spec, roll: ForcedRoll) -> dict:
    percent = {} if roll.forced_percent is None else {FORCED_PERCENT: roll.forced_percent}
    return {'forced_roll': {'talent': roll.talent, 'released_label': released_label(spec), **percent}}
