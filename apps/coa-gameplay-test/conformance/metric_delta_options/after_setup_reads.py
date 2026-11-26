from dataclasses import replace

NAME = 'after_setup_reads'
ORDER = 29
PHASES = ('before', 'after')


def parse(raw) -> tuple[tuple[int, int], ...]:
    if not isinstance(raw, list) or not raw or any(
            not isinstance(read, dict) or set(read) != {'spell', 'expected'} or type(read['spell']) is not int
            or type(read['expected']) is not int or read['expected'] not in (0, 1) for read in raw):
        raise ValueError(f'after_setup_reads is a non-empty list of {{"spell": id, "expected": 0 or 1}}, not {raw!r}')
    if len({read['spell'] for read in raw}) != len(raw):
        raise ValueError(f'after_setup_reads names a spell twice: {raw!r}')
    return tuple((read['spell'], read['expected']) for read in raw)


def check(spec, value):
    if value is not None and (not spec.setup_casts or spec.attack_swings):
        raise ValueError(f'{spec.spell} after_setup_reads reads after the last setup cast of a cast phase, which '
                         f'needs setup_casts and no attack_swings')


def read_label(spec, spell: int, phase: str) -> str:
    return f'{spec.spell} after_setup_reads {spell} {phase}'


def setup_cast_steps(spec, reads, index: int, after: bool) -> list[dict]:
    from profile import CASTER, measurement
    if index != len(spec.setup_casts) - 1:
        return []
    phase = PHASES[after]
    return [measurement(read_label(spec, spell, phase), CASTER, 'aura_stacks', spell=spell) for spell, _ in reads]


def fixtures(class_file: dict, spec, reads, scenario: dict):
    scenario['contract'] += (f' After the last setup cast of each phase that makes the setup casts, the caster auras '
                             f'{[spell for spell, _ in reads]} are read and judged against '
                             f'{["present" if expected else "absent" for _, expected in reads]}: a precondition '
                             f'check, so a mismatch voids the trial.')


def model(spec, reads) -> dict:
    return {NAME: [{'spell': spell, 'expected': expected,
                    'read_labels': {phase: read_label(spec, spell, phase) for phase in PHASES}}
                   for spell, expected in reads]}


def verdict(verdict, run, reads):
    off = []
    for read in reads:
        for phase in PHASES:
            value = run.values.get(read['read_labels'][phase])
            if (value is None and phase == 'after') or (value is not None and (value > 0) != bool(read['expected'])):
                off.append((read['spell'], read['expected'], phase, value))
    if not off:
        return verdict
    detail = ', '.join(f'{spell} read {value} in the {phase} phase (expected {"present" if expected else "absent"})'
                       for spell, expected, phase, value in off)
    return replace(verdict, status='unmeasured',
                   explanation=f'{verdict.explanation}; after the setup casts the caster aura {detail}, '
                               f'so the precondition did not hold')
