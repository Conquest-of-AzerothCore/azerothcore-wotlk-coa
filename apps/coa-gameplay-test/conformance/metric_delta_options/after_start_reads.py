from dataclasses import replace

NAME = 'after_start_reads'
ORDER = 10
READ_KEYS = {'spell', 'expected'}
OPTIONAL_READ_KEYS = {'actor'}


def well_formed(read) -> bool:
    return (isinstance(read, dict) and READ_KEYS <= set(read) <= READ_KEYS | OPTIONAL_READ_KEYS
            and isinstance(read['spell'], int) and not isinstance(read['expected'], bool)
            and read['expected'] in (0, 1)
            and ('actor' not in read or (isinstance(read['actor'], str) and bool(read['actor']))))


def parse(raw) -> tuple[tuple[int, int, str | None], ...]:
    if not isinstance(raw, list) or not raw or not all(well_formed(read) for read in raw):
        raise ValueError(f'after_start_reads is a non-empty list of {{"spell": id, "expected": 0 or 1, "actor"?: '
                         f'unit}}, not {raw!r}')
    if len({(read['spell'], read.get('actor')) for read in raw}) != len(raw):
        raise ValueError(f'after_start_reads names a spell twice on one unit: {raw!r}')
    return tuple((read['spell'], read['expected'], read.get('actor')) for read in raw)


def check(spec, reads):
    if reads is None:
        return
    from profile import CASTER
    ally = dict(spec.options).get('ally_arm')
    units = {CASTER, *(ally.ally_ids if ally is not None else ())}
    unknown = sorted({actor for _, _, actor in reads if actor is not None} - units)
    if unknown:
        raise ValueError(f'{spec.spell} after_start_reads reads {unknown}, not a unit of its scenario {sorted(units)}')


def read_label(spec, spell: int, actor: str | None = None) -> str:
    return f'{spec.spell} after_start_reads {spell}' + (f' {actor}' if actor is not None else '')


def phase_steps(spec, reads, after: bool) -> list[dict]:
    from profile import CASTER, measurement
    return [measurement(read_label(spec, spell, actor), CASTER if actor is None else actor, 'aura_stacks',
                        spell=spell) for spell, _, actor in reads] if after else []


def model(spec, reads) -> dict:
    return {NAME: [{'spell': spell, 'expected': expected, 'read_label': read_label(spec, spell, actor),
                    **({'actor': actor} if actor is not None else {})}
                   for spell, expected, actor in reads]}


def verdict(verdict, run, reads):
    off = [(read['spell'], read['expected'], read.get('actor'), run.values.get(read['read_label'])) for read in reads
           if run.values.get(read['read_label']) is None
           or (run.values[read['read_label']] > 0) != bool(read['expected'])]
    if not off:
        return verdict
    detail = ', '.join(f'{"the caster" if actor is None else actor} aura {spell} read {value} (expected '
                       f'{"present" if expected else "absent"})' for spell, expected, actor, value in off)
    return replace(verdict, status='unmeasured',
                   explanation=f'{verdict.explanation}; at the start of the after phase {detail}, so the '
                               f'precondition did not hold')
