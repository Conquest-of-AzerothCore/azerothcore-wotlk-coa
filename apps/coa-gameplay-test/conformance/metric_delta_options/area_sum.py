NAME = 'area_sum'
ORDER = 7
JUDGED_MOMENTS = ('before', 'after', 'expired')


def parse(raw) -> bool:
    if raw is not True:
        raise ValueError(f'area_sum is true (the dummy and every area dummy read and summed), not {raw!r}')
    return True


def check(spec, enabled):
    if enabled is None:
        return
    from behaviours import TARGET
    options = dict(spec.options)
    if not options.get('area_dummies'):
        raise ValueError(f'{spec.spell} sets area_sum without area_dummies, so there is nothing to sum')
    if options.get('fields_sum') is not None:
        raise ValueError(f'{spec.spell} sets area_sum and fields_sum, two sums of the same reading')
    summed_key(spec)


def summed_key(spec) -> str:
    from behaviours import TARGET
    keys = [key for key, unit in (('actor', spec.measure_actor), ('target', spec.fields.get('target')))
            if unit == TARGET]
    if len(keys) != 1:
        raise ValueError(f'{spec.spell} sets area_sum on a reading that does not name the dummy once (measure_actor '
                         f'{spec.measure_actor!r}, fields.target {spec.fields.get("target")!r})')
    return keys[0]


def area_names(spec) -> list[str]:
    from metric_delta_options.area_dummies import area_dummy_id
    return [area_dummy_id(index) for index in range(len(dict(spec.options)['area_dummies']))]


def part_label(label: str, area: str) -> str:
    return f'{label} {area}'


def fixtures(class_file: dict, spec, enabled: bool, scenario: dict):
    from behaviours import metric_delta_label
    judged = {metric_delta_label(spec, moment) for moment in JUDGED_MOMENTS}
    areas = area_names(spec)
    key = summed_key(spec)
    steps = []
    for step in scenario['steps']:
        steps.append(step)
        if step.get('action') == 'assert' and step.get('label') in judged:
            steps += [{**step, key: area, 'label': part_label(step['label'], area)} for area in areas]
    scenario['steps'] = steps
    scenario['contract'] += (f' Each judged reading is the sum of {spec.metric} {spec.fields} read with the dummy '
                             f'as its {key} and with {", ".join(areas)}.')


def model(spec, enabled: bool) -> dict:
    from behaviours import metric_delta_label
    areas = area_names(spec)
    return {NAME: {'parts': {metric_delta_label(spec, moment): [part_label(metric_delta_label(spec, moment), area)
                                                                for area in areas]
                             for moment in JUDGED_MOMENTS}}}


def run_values(values: dict, summed: dict) -> dict:
    out = dict(values)
    for label, parts in summed['parts'].items():
        if label in out:
            out[label] = (out[label] + sum(values[part] for part in parts)
                          if all(part in values for part in parts) else None)
    return {label: value for label, value in out.items() if value is not None}
