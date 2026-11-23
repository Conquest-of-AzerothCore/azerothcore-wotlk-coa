from dataclasses import replace

NAME = 'before_reference'
ORDER = 34
OWNED_PREFIX = 'owned_creature_'


def parse(raw) -> dict:
    if not isinstance(raw, dict) or set(raw) - {'metric', 'fields'} or not isinstance(raw.get('metric'), str) \
            or not isinstance(raw.get('fields', {}), dict):
        raise ValueError(f'before_reference is {{"metric": name, "fields": {{...}}}}, the read that stands in for the '
                         f'before reading, not {raw!r}')
    return {'metric': raw['metric'], 'fields': dict(raw.get('fields', {}))}


def check(spec, reference):
    if reference is None:
        return
    if not spec.metric.startswith(OWNED_PREFIX) or not isinstance(spec.fields.get('entry'), int):
        raise ValueError(f'{spec.spell} sets before_reference only on an {OWNED_PREFIX}* read of a named entry')
    if reference['metric'] == spec.metric:
        raise ValueError(f'{spec.spell} before_reference reads {spec.metric} again')
    if spec.expiry_wait_ms is not None:
        raise ValueError(f'{spec.spell} before_reference judges a before and an after reading only')


def count_label(spec) -> str:
    return f'{spec.spell} before_reference count'


def present_label(spec) -> str:
    return f'{spec.spell} before_reference present'


def fixtures(class_file: dict, spec, reference: dict, scenario: dict):
    from behaviours import metric_delta_label
    from profile import CASTER, measurement
    entry = spec.fields['entry']
    steps = scenario['steps']
    labels = [step.get('label') for step in steps]
    before = labels.index(metric_delta_label(spec, 'before'))
    after = labels.index(metric_delta_label(spec, 'after'))
    count = measurement(count_label(spec), CASTER, 'owned_creature_count', entry=entry)
    replaced = measurement(metric_delta_label(spec, 'before'), steps[before]['actor'], reference['metric'],
                           **reference['fields'])
    present = {'action': 'assert', 'label': present_label(spec), 'actor': CASTER, 'metric': 'owned_creature_count',
               'entry': entry, 'equals': 1}
    scenario['steps'] = steps[:before] + [count, replaced] + steps[before + 1:after] + [present] + steps[after:]
    scenario['contract'] += (f' The before phase owns no {entry}: a count of it must read 0, and its {spec.metric} '
                             f'read is replaced by {reference["metric"]} {reference["fields"]}, the reading a '
                             f'creature at that reference would give; the after read requires exactly one owned '
                             f'{entry}.')


def model(spec, reference: dict) -> dict:
    return {NAME: {'count_label': count_label(spec), 'metric': reference['metric'], 'fields': reference['fields']}}


def verdict(verdict, run, reference: dict):
    count = run.values.get(reference['count_label'])
    if count is None:
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; the before count of the owned creature was not read')
    if count != 0:
        return replace(verdict, status='alert',
                       explanation=f'{verdict.explanation}; the before phase owned {count:g} of the creature, not 0')
    return replace(verdict, explanation=f'{verdict.explanation}; the before reading is {reference["metric"]} '
                                        f'{reference["fields"]}, with no owned creature in the before phase')
