NAME = 'ratio_to_metric'
ORDER = 25
JUDGED_MOMENTS = ('before', 'after', 'expired')
SUMMED = ('fields_sum', 'area_sum', 'ring_sum')


def parse(raw) -> dict:
    if not isinstance(raw, dict) or set(raw) - {'metric', 'fields'} or not isinstance(raw.get('metric'), str) \
            or not isinstance(raw.get('fields', {}), dict):
        raise ValueError(f'ratio_to_metric is {{"metric": name, "fields": {{...}}}}, the read each judged reading is '
                         f'divided by, not {raw!r}')
    return {'metric': raw['metric'], 'fields': dict(raw.get('fields', {}))}


def check(spec, base):
    if base is None:
        return
    if base['metric'] == spec.metric and base['fields'] == spec.fields:
        raise ValueError(f'{spec.spell} ratio_to_metric divides {spec.metric} by itself')
    combined = [name for name, _ in spec.options if name in SUMMED]
    if combined:
        raise ValueError(f'{spec.spell} ratio_to_metric cannot divide a summed reading ({combined})')


def base_label(label: str) -> str:
    return f'{label} ratio base'


def fixtures(class_file: dict, spec, base: dict, scenario: dict):
    from behaviours import metric_delta_label
    from profile import measurement
    judged = {metric_delta_label(spec, moment) for moment in JUDGED_MOMENTS}
    steps = []
    for step in scenario['steps']:
        steps.append(step)
        if step.get('action') == 'assert' and step.get('label') in judged:
            steps.append(measurement(base_label(step['label']), step['actor'], base['metric'], **base['fields']))
    scenario['steps'] = steps
    scenario['contract'] += (f' Each judged reading is {spec.metric} {spec.fields} divided by {base["metric"]} '
                             f'{base["fields"]} of the same unit, read right after it.')


def model(spec, base: dict) -> dict:
    from behaviours import metric_delta_label
    return {NAME: {'metric': base['metric'], 'fields': base['fields'],
                   'bases': {metric_delta_label(spec, moment): base_label(metric_delta_label(spec, moment))
                             for moment in JUDGED_MOMENTS}}}


def run_values(values: dict, ratio: dict) -> dict:
    out = dict(values)
    for label, base in ratio['bases'].items():
        if label in out:
            divisor = values.get(base)
            out[label] = out[label] / divisor if divisor else None
    return {label: value for label, value in out.items() if value is not None}
