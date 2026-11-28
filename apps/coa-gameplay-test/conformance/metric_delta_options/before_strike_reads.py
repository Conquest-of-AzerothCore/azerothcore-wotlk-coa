from dataclasses import dataclass, replace
import math

NAME = 'before_strike_reads'
ORDER = 25
READ_KEYS = {'actor', 'metric', 'fields', 'expected', 'tolerance', 'source', 'after_expected', 'before_phase_expected'}
OPTIONAL_KEYS = {'fields', 'after_expected', 'before_phase_expected'}


@dataclass(frozen=True)
class BeforeStrikeRead:
    actor: str
    metric: str
    fields: dict
    expected: float
    tolerance: float
    source: str
    after_expected: float | None = None
    before_phase_expected: float | None = None


def finite_number(value) -> bool:
    return type(value) in (int, float) and math.isfinite(value)


def parse_read(raw) -> BeforeStrikeRead:
    after_expected = raw.get('after_expected') if isinstance(raw, dict) else None
    before_phase_expected = raw.get('before_phase_expected') if isinstance(raw, dict) else None
    if (not isinstance(raw, dict) or not READ_KEYS - OPTIONAL_KEYS <= set(raw) <= READ_KEYS
            or not isinstance(raw['actor'], str) or not raw['actor']
            or not isinstance(raw['metric'], str) or not raw['metric']
            or not isinstance(raw.get('fields', {}), dict)
            or not finite_number(raw['expected'])
            or (after_expected is not None and not finite_number(after_expected))
            or (before_phase_expected is not None and not finite_number(before_phase_expected))
            or not finite_number(raw['tolerance']) or raw['tolerance'] < 0
            or not isinstance(raw['source'], str) or not raw['source'].strip()):
        raise ValueError(f'before_strike_reads entry is {{actor, metric, fields?, expected, after_expected?, '
                         f'before_phase_expected?, tolerance >= 0, source}}, not {raw!r}')
    return BeforeStrikeRead(
        raw['actor'], raw['metric'], dict(raw.get('fields', {})), float(raw['expected']),
        float(raw['tolerance']), raw['source'],
        None if after_expected is None else float(after_expected),
        None if before_phase_expected is None else float(before_phase_expected),
    )


def parse(raw) -> tuple[BeforeStrikeRead, ...]:
    if not isinstance(raw, list) or not raw:
        raise ValueError(f'before_strike_reads is a non-empty list, not {raw!r}')
    return tuple(parse_read(item) for item in raw)


def check(spec, reads: tuple[BeforeStrikeRead, ...] | None):
    if reads is None:
        return
    from coverage import metric_evidence
    from profile import CASTER
    from values import TARGET
    if spec.strike is None:
        raise ValueError(f'{spec.spell} before_strike_reads needs a strike to read before')
    ally = dict(spec.options).get('ally_arm')
    dummy = spec.select_dummy or TARGET in (spec.target, spec.measure_actor, spec.fields.get('target'))
    units = {CASTER, *(ally.ally_ids if ally is not None else ()), *((TARGET,) if dummy else ())}
    for index, read in enumerate(reads):
        if read.actor not in units:
            raise ValueError(f'{spec.spell} before_strike_reads {index} reads {read.actor!r}, outside {sorted(units)}')
        if read.metric not in metric_evidence():
            raise ValueError(f'{spec.spell} before_strike_reads {index} metric {read.metric!r} needs a '
                             f'METRIC_EVIDENCE row')


def read_label(spec, index: int, read: BeforeStrikeRead, stage: str = 'before_strike') -> str:
    return f'{spec.spell} {NAME} {index} {stage} {read.actor} {read.metric}'


def fixtures(class_file: dict, spec, reads: tuple[BeforeStrikeRead, ...], scenario: dict):
    from behaviours import STRIKER, metric_delta_label
    from profile import measurement
    steps = list(scenario['steps'])
    before_index = next(index for index, step in enumerate(steps)
                        if step.get('label') == metric_delta_label(spec, 'before'))
    before_phase_added = [measurement(read_label(spec, index, read, 'before_phase'), read.actor, read.metric,
                                      **read.fields)
                          for index, read in enumerate(reads) if read.before_phase_expected is not None]
    if before_phase_added:
        steps = steps[:before_index + 1] + before_phase_added + steps[before_index + 1:]
    before_index = next(index for index, step in enumerate(steps)
                        if step.get('label') == metric_delta_label(spec, 'before'))
    strike_index = next((index for index in range(before_index + 1, len(steps))
                         if steps[index].get('action') == 'cast' and steps[index].get('actor') == STRIKER
                         and steps[index].get('spell') == spec.strike.spell), None)
    if strike_index is None:
        raise ValueError(f'{spec.spell} before_strike_reads found no treatment strike cast of {spec.strike.spell}')
    added = [measurement(read_label(spec, index, read), read.actor, read.metric, **read.fields)
             for index, read in enumerate(reads)]
    steps = steps[:strike_index] + added + steps[strike_index:]
    after_added = [measurement(read_label(spec, index, read, 'after_strike'), read.actor, read.metric, **read.fields)
                   for index, read in enumerate(reads) if read.after_expected is not None]
    if after_added:
        after_index = next(index for index, step in enumerate(steps)
                           if step.get('label') == metric_delta_label(spec, 'after'))
        steps = steps[:after_index + 1] + after_added + steps[after_index + 1:]
    scenario['steps'] = steps
    described = '; '.join(
        f'{read.metric} {read.fields} on {read.actor} expected {read.expected:g}'
        + (f' (before phase {read.before_phase_expected:g})' if read.before_phase_expected is not None else '')
        + (f' (after strike {read.after_expected:g})' if read.after_expected is not None else '')
        + f' within {read.tolerance:g} ({read.source})'
        for read in reads
    )
    scenario['contract'] += f' Immediately before the treatment strike, read {described}.'


def model(spec, reads: tuple[BeforeStrikeRead, ...]) -> dict:
    entries = []
    for index, read in enumerate(reads):
        entry = {'actor': read.actor, 'metric': read.metric, 'expected': read.expected,
                 'tolerance': read.tolerance, 'source': read.source, 'label': read_label(spec, index, read)}
        if read.after_expected is not None:
            entry['after_label'] = read_label(spec, index, read, 'after_strike')
            entry['after_expected'] = read.after_expected
        if read.before_phase_expected is not None:
            entry['before_phase_label'] = read_label(spec, index, read, 'before_phase')
            entry['before_phase_expected'] = read.before_phase_expected
        entries.append(entry)
    return {NAME: entries}


def verdict(verdict, run, reads: list[dict]):
    from compare import missing_measurement
    if verdict.status == 'unmeasured':
        return verdict
    texts = []
    off = False
    for read in reads:
        checks = []
        if 'before_phase_label' in read:
            checks.append(('before phase', read['before_phase_label'], read['before_phase_expected']))
        checks.append(('before strike', read['label'], read['expected']))
        if 'after_label' in read:
            checks.append(('after strike', read['after_label'], read['after_expected']))
        for stage, label, expected in checks:
            value = run.values.get(label)
            if value is None:
                return replace(verdict, status='alert' if verdict.status == 'alert' else 'unmeasured',
                               explanation=f'{verdict.explanation}; before_strike_reads: '
                                           f'{missing_measurement(run, label)}')
            held = abs(value - expected) <= read['tolerance']
            off = off or not held
            texts.append(f'{read["metric"]} on {read["actor"]} {stage}: {value:g} '
                         f'(expected {expected:g} +- {read["tolerance"]:g}): {"ok" if held else "off"} '
                         f'({read["source"]})')
    return replace(verdict, status='alert' if off else verdict.status,
                   explanation=f'{verdict.explanation}; before_strike_reads: {"; ".join(texts)}')
