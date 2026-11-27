from dataclasses import replace

NAME = 'area_sum'
ORDER = 7
JUDGED_MOMENTS = ('before', 'after', 'expired')


def parse(raw) -> bool | dict:
    if isinstance(raw, dict) and set(raw) == {'additional_single_hits'} and \
            type(raw['additional_single_hits']) is int and raw['additional_single_hits'] > 0:
        return raw
    if raw is not True:
        raise ValueError(f'area_sum is true to sum all reads, or sets additional_single_hits to a positive integer, '
                         f'not {raw!r}')
    return True


def check(spec, enabled):
    if enabled is None:
        return
    options = dict(spec.options)
    if not options.get('area_dummies'):
        raise ValueError(f'{spec.spell} sets area_sum without area_dummies, so there is nothing to sum')
    if options.get('fields_sum') is not None:
        raise ValueError(f'{spec.spell} sets area_sum and fields_sum, two sums of the same reading')
    summed_key(spec)
    if isinstance(enabled, dict) and (enabled['additional_single_hits'] > len(options['area_dummies'])
                                      or spec.metric != 'spell_damage_count' or spec.before_expected != 0
                                      or spec.expected != 1 or spec.tolerance != 0 or spec.expiry_wait_ms is not None):
        raise ValueError(f'{spec.spell} area_sum additional_single_hits needs damage counts, a primary 0 -> 1 '
                         f'expectation without tolerance or expiry, and enough additional dummies')


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


def fixtures(class_file: dict, spec, enabled: bool | dict, scenario: dict):
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
    if isinstance(enabled, dict):
        scenario['contract'] += (
            f" The primary dummy takes one hit and exactly {enabled['additional_single_hits']} of "
            f"{', '.join(areas)} take one hit each; all other readings must be zero.")
        return
    scenario['contract'] += (f' Each judged reading is the sum of {spec.metric} {spec.fields} read with the dummy '
                             f'as its {key} and with {", ".join(areas)}.')


def model(spec, enabled: bool | dict) -> dict:
    from behaviours import metric_delta_label
    areas = area_names(spec)
    if isinstance(enabled, dict):
        return {NAME: {**enabled, 'areas': areas,
                       **{moment: metric_delta_label(spec, moment) for moment in ('before', 'after')}}}
    return {NAME: {'parts': {metric_delta_label(spec, moment): [part_label(metric_delta_label(spec, moment), area)
                                                                for area in areas]
                             for moment in JUDGED_MOMENTS}}}


def run_values(values: dict, summed: dict) -> dict:
    if 'parts' not in summed:
        return values
    out = dict(values)
    for label, parts in summed['parts'].items():
        if label in out:
            out[label] = (out[label] + sum(values[part] for part in parts)
                          if all(part in values for part in parts) else None)
    return {label: value for label, value in out.items() if value is not None}


def verdict(verdict, run, model):
    if 'additional_single_hits' not in model or verdict.status == 'unmeasured':
        return verdict
    parts = {moment: {area: run.values.get(part_label(model[moment], area)) for area in model['areas']}
             for moment in ('before', 'after')}
    detail = f'{verdict.explanation}; additional enemies: {parts}'
    if any(value is None for readings in parts.values() for value in readings.values()):
        return replace(verdict, status='alert' if verdict.status == 'alert' else 'unmeasured', explanation=detail)
    hits = model['additional_single_hits']
    matched = all(value == 0 for value in parts['before'].values()) and (
        sorted(parts['after'].values()) == [0] * (len(model['areas']) - hits) + [1] * hits)
    return replace(verdict, status=verdict.status if matched else 'alert', explanation=detail)
