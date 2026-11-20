NAME = 'fields_sum'
ORDER = 0
JUDGED_MOMENTS = ('before', 'after', 'expired')


def parse(raw) -> dict:
    if not isinstance(raw, dict) or not raw or not all(isinstance(key, str) for key in raw):
        raise ValueError(f'fields_sum is the fields of a second read of the same metric, not {raw!r}')
    return dict(raw)


def check(spec, fields):
    if fields is not None and fields == spec.fields:
        raise ValueError(f'{spec.spell} fields_sum repeats its own fields, so the sum would count one read twice')


def part_label(label: str) -> str:
    return f'{label} sum part'


def fixtures(class_file: dict, spec, fields: dict, scenario: dict):
    from behaviours import metric_delta_label
    judged = {metric_delta_label(spec, moment) for moment in JUDGED_MOMENTS}
    steps = []
    for step in scenario['steps']:
        steps.append(step)
        if step.get('action') == 'assert' and step.get('label') in judged:
            part = {key: value for key, value in step.items() if key not in spec.fields}
            steps.append({**part, **fields, 'label': part_label(step['label'])})
    scenario['steps'] = steps
    scenario['contract'] += (f' Each judged reading is the sum of two reads of {spec.metric}: {spec.fields} and, '
                             f'right after it, {fields}.')


def model(spec, fields: dict) -> dict:
    from behaviours import metric_delta_label
    return {NAME: {'fields': fields, 'parts': {metric_delta_label(spec, moment): part_label(
        metric_delta_label(spec, moment)) for moment in JUDGED_MOMENTS}}}


def run_values(values: dict, summed: dict) -> dict:
    out = dict(values)
    for label, part in summed['parts'].items():
        if label in out:
            out[label] = out[label] + values[part] if part in values else None
    return {label: value for label, value in out.items() if value is not None}
