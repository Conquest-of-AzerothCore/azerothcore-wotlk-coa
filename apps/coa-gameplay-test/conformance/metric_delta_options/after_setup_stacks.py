from dataclasses import replace

NAME = 'after_setup_stacks'
ORDER = 29
PHASES = ('before', 'after')
UNITS = ('caster', 'dummy')
READ_KEYS = {'spell', 'actor', 'stacks'}


def parse(raw) -> tuple[tuple[int, str, int], ...]:
    if not isinstance(raw, list) or not raw or any(
            not isinstance(read, dict) or set(read) != READ_KEYS or type(read['spell']) is not int
            or read['actor'] not in UNITS or type(read['stacks']) is not int or read['stacks'] < 0 for read in raw):
        raise ValueError(f'after_setup_stacks is a non-empty list of {{"spell": id, "actor": {" or ".join(UNITS)}, '
                         f'"stacks": a whole number from 0}}, not {raw!r}')
    if len({(read['spell'], read['actor']) for read in raw}) != len(raw):
        raise ValueError(f'after_setup_stacks names a spell twice on one unit: {raw!r}')
    return tuple((read['spell'], read['actor'], read['stacks']) for read in raw)


def check(spec, value):
    if value is not None and (not spec.setup_casts or spec.attack_swings):
        raise ValueError(f'{spec.spell} after_setup_stacks reads after the last setup cast of a cast phase, which '
                         f'needs setup_casts and no attack_swings')


def read_label(spec, spell: int, actor: str, phase: str) -> str:
    return f'{spec.spell} after_setup_stacks {actor} {spell} {phase}'


def setup_cast_steps(spec, reads, index: int, after: bool) -> list[dict]:
    from profile import measurement
    if index != len(spec.setup_casts) - 1:
        return []
    phase = PHASES[after]
    return [measurement(read_label(spec, spell, actor, phase), actor, 'aura_stacks', spell=spell)
            for spell, actor, _ in reads]


def fixtures(class_file: dict, spec, reads, scenario: dict):
    scenario['contract'] += (' After the last setup cast of each phase that makes the setup casts, '
                             + ', '.join(f'aura {spell} on the {actor} is read at exactly {stacks} stacks'
                                         for spell, actor, stacks in reads)
                             + ': a precondition check, so a mismatch voids the trial.')


def model(spec, reads) -> dict:
    return {NAME: [{'spell': spell, 'actor': actor, 'stacks': stacks,
                    'read_labels': {phase: read_label(spec, spell, actor, phase) for phase in PHASES}}
                   for spell, actor, stacks in reads]}


def verdict(verdict, run, reads):
    off = []
    for read in reads:
        for phase in PHASES:
            value = run.values.get(read['read_labels'][phase])
            if (value is None and phase == 'after') or (value is not None and value != read['stacks']):
                off.append((read['actor'], read['spell'], read['stacks'], phase, value))
    if not off:
        return verdict
    detail = ', '.join(f'the {actor} aura {spell} read {value} stacks in the {phase} phase (expected {stacks})'
                       for actor, spell, stacks, phase, value in off)
    return replace(verdict, status='unmeasured',
                   explanation=f'{verdict.explanation}; after the setup casts {detail}, so the precondition did '
                               f'not hold')
