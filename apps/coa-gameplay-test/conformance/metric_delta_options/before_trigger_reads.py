from dataclasses import replace

NAME = 'before_trigger_reads'
ORDER = 30
READ_KEYS = {'spell', 'expected', 'actor'}
UNITS = ('caster', 'dummy')


def parse(raw) -> tuple[tuple[int, int, str], ...]:
    if not isinstance(raw, list) or not raw or any(
            not isinstance(read, dict) or set(read) != READ_KEYS or not isinstance(read['spell'], int)
            or isinstance(read['spell'], bool) or isinstance(read['expected'], bool)
            or read['expected'] not in (0, 1) or read['actor'] not in UNITS for read in raw):
        raise ValueError(f'before_trigger_reads is a non-empty list of {{"spell": id, "expected": 0 or 1, "actor": '
                         f'{" or ".join(UNITS)}}}, not {raw!r}')
    if len({(read['spell'], read['actor']) for read in raw}) != len(raw):
        raise ValueError(f'before_trigger_reads names a spell twice on one unit: {raw!r}')
    return tuple((read['spell'], read['expected'], read['actor']) for read in raw)


def phases(spec) -> tuple[str, ...]:
    casts_before = spec.cast_in_before and not spec.trigger_only_after and not spec.setup_only_after
    return ('before', 'after') if casts_before else ('after',)


def read_label(spec, spell: int, actor: str, phase: str) -> str:
    return f'{spec.spell} before_trigger_reads {actor} {spell} {phase}'


def phase_steps(spec, reads, after: bool) -> list[dict]:
    from profile import measurement
    phase = 'after' if after else 'before'
    if phase not in phases(spec):
        return []
    return [measurement(read_label(spec, spell, actor, phase), actor, 'aura_stacks', spell=spell)
            for spell, _, actor in reads]


def fixtures(class_file: dict, spec, reads, scenario: dict):
    scenario['contract'] += (' Before the trigger cast of each phase that makes it, right after the fixture auras are '
                             'set and with no wait in between, '
                             + ', '.join(f'aura {spell} on the {actor}' for spell, _, actor in reads)
                             + ' is read and judged against '
                             + ', '.join('present' if expected else 'absent' for _, expected, _ in reads)
                             + ': a precondition check, so a mismatch voids the trial.')


def model(spec, reads) -> dict:
    return {NAME: [{'spell': spell, 'expected': expected, 'actor': actor,
                    'read_labels': {phase: read_label(spec, spell, actor, phase) for phase in phases(spec)}}
                   for spell, expected, actor in reads]}


def verdict(verdict, run, reads):
    off = []
    for read in reads:
        for phase, label in read['read_labels'].items():
            value = run.values.get(label)
            if value is None or (value > 0) != bool(read['expected']):
                off.append((read['actor'], read['spell'], read['expected'], phase, value))
    if not off:
        return verdict
    detail = ', '.join(f'the {actor} aura {spell} read {value} in the {phase} phase (expected '
                       f'{"present" if expected else "absent"})' for actor, spell, expected, phase, value in off)
    return replace(verdict, status='unmeasured',
                   explanation=f'{verdict.explanation}; before the trigger cast {detail}, so the precondition did '
                               f'not hold')
