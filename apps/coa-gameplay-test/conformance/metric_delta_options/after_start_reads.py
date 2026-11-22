from dataclasses import replace

NAME = 'after_start_reads'
ORDER = 10


def parse(raw) -> tuple[tuple[int, int], ...]:
    if not isinstance(raw, list) or not raw or any(
            not isinstance(read, dict) or set(read) != {'spell', 'expected'} or not isinstance(read['spell'], int)
            or isinstance(read['expected'], bool) or read['expected'] not in (0, 1) for read in raw):
        raise ValueError(f'after_start_reads is a non-empty list of {{"spell": id, "expected": 0 or 1}}, not {raw!r}')
    if len({read['spell'] for read in raw}) != len(raw):
        raise ValueError(f'after_start_reads names a spell twice: {raw!r}')
    return tuple((read['spell'], read['expected']) for read in raw)


def read_label(spec, spell: int) -> str:
    return f'{spec.spell} after_start_reads {spell}'


def phase_steps(spec, reads, after: bool) -> list[dict]:
    from profile import CASTER, measurement
    return [measurement(read_label(spec, spell), CASTER, 'aura_stacks', spell=spell)
            for spell, _ in reads] if after else []


def model(spec, reads) -> dict:
    return {NAME: [{'spell': spell, 'expected': expected, 'read_label': read_label(spec, spell)}
                   for spell, expected in reads]}


def verdict(verdict, run, reads):
    off = [(read['spell'], read['expected'], run.values.get(read['read_label'])) for read in reads
           if run.values.get(read['read_label']) is None
           or (run.values[read['read_label']] > 0) != bool(read['expected'])]
    if not off:
        return verdict
    detail = ', '.join(f'{spell} read {value} (expected {"present" if expected else "absent"})'
                       for spell, expected, value in off)
    return replace(verdict, status='unmeasured',
                   explanation=f'{verdict.explanation}; at the start of the after phase the caster aura {detail}, '
                               f'so the precondition did not hold')
