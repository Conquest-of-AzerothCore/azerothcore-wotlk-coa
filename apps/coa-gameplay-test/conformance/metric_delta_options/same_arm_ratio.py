from dataclasses import replace

NAME = 'same_arm_ratio'
ORDER = 26
MOMENTS = ('before', 'after')
KEYS = {'metric', 'fields', 'ratio', 'tolerance', 'least', 'source'}
OPTIONAL = {'main_below'}


def number(raw, name: str, positive: bool = True) -> float:
    if isinstance(raw, bool) or not isinstance(raw, (int, float)) or (raw <= 0 if positive else raw < 0):
        raise ValueError(f'same_arm_ratio {name} is a {"positive" if positive else "non-negative"} number, '
                         f'not {raw!r}')
    return float(raw)


def parse(raw) -> dict:
    if not isinstance(raw, dict) or not KEYS <= set(raw) or set(raw) - KEYS - OPTIONAL:
        raise ValueError(f'same_arm_ratio is {{"metric", "fields", "ratio", "tolerance", "least", "source"}} '
                         f'with an optional "main_below", not {raw!r}')
    if not isinstance(raw['metric'], str) or not raw['metric'] or not isinstance(raw['fields'], dict):
        raise ValueError(f'same_arm_ratio reads a metric name with its fields, not {raw["metric"]!r} '
                         f'{raw["fields"]!r}')
    if not isinstance(raw['source'], str) or not raw['source'].strip():
        raise ValueError('same_arm_ratio source cites the tooltip or data line that states the ratio')
    parsed = {'metric': raw['metric'], 'fields': dict(raw['fields']), 'ratio': number(raw['ratio'], 'ratio'),
              'tolerance': number(raw['tolerance'], 'tolerance', positive=False),
              'least': number(raw['least'], 'least'), 'source': raw['source']}
    if 'main_below' in raw:
        parsed['main_below'] = number(raw['main_below'], 'main_below')
    return parsed


def check(spec, value):
    if value is None:
        return
    if value['metric'] == spec.metric and value['fields'] == spec.fields:
        raise ValueError(f'{spec.spell} same_arm_ratio reads a second metric, not the entry\'s own '
                         f'{spec.metric} {spec.fields}')
    if spec.expected_ratio is not None:
        raise ValueError(f'{spec.spell} same_arm_ratio judges the after arm\'s own gains and replaces '
                         f'expected_ratio, which relates the arms')


def labels(spec) -> dict[str, str]:
    from behaviours import metric_delta_label
    return {moment: f'{metric_delta_label(spec, moment)} same_arm_ratio part' for moment in MOMENTS}


def fixtures(class_file: dict, spec, value: dict, scenario: dict):
    from behaviours import metric_delta_label
    from profile import measurement
    names = labels(spec)
    reads = {metric_delta_label(spec, moment): measurement(names[moment], spec.measure_actor, value['metric'],
                                                           **value['fields'])
             for moment in MOMENTS}
    scenario['steps'] = [step for original in scenario['steps']
                         for step in (original, *((reads[original['label']],)
                                                  if original.get('label') in reads else ()))]
    fields = f' {value["fields"]}' if value['fields'] else ''
    scenario['contract'] += (f' Same-arm ratio: right after each reading, {value["metric"]}{fields} '
                             f'is read at the same moment; between the before and the after reading '
                             f'(the after arm), the gain of the reading divided by the gain of that metric is judged '
                             f'against {value["ratio"]:g} within {value["tolerance"]:g} ({value["source"]}), with a '
                             f'gain of at least {value["least"]:g} of that metric'
                             + (f' and an after reading below {value["main_below"]:g}'
                                if 'main_below' in value else '') + '.')


def model(spec, value: dict) -> dict:
    from behaviours import metric_delta_label
    return {NAME: {**value, 'parts': labels(spec),
                   'reads': {moment: metric_delta_label(spec, moment) for moment in MOMENTS}}}


def verdict(verdict, run, recorded: dict):
    values = run.values
    labels_needed = [*recorded['reads'].values(), *recorded['parts'].values()]
    missing = [label for label in labels_needed if values.get(label) is None]
    if missing:
        return replace(verdict, status='unmeasured', explanation=f'same-arm ratio: {", ".join(missing)} missing')
    main = [float(values[recorded['reads'][moment]]) for moment in MOMENTS]
    part = [float(values[recorded['parts'][moment]]) for moment in MOMENTS]
    gain, base = main[1] - main[0], part[1] - part[0]
    ratio, tolerance = recorded['ratio'], recorded['tolerance']
    text = (f'same-arm ratio: reading {main[0]:g} then {main[1]:g} (gain {gain:g}), {recorded["metric"]} '
            f'{part[0]:g} then {part[1]:g} (gain {base:g})')
    if base < recorded['least']:
        return replace(verdict, status='unmeasured',
                       explanation=f'{text}: a {recorded["metric"]} gain below the stated {recorded["least"]:g}')
    if 'main_below' in recorded and main[1] >= recorded['main_below']:
        return replace(verdict, status='unmeasured',
                       explanation=f'{text}: the after reading reached the stated bound {recorded["main_below"]:g}')
    measured = gain / base
    status = 'ok' if abs(measured - ratio) <= tolerance else 'alert'
    return replace(verdict, status=status, measured=measured, expected=ratio, low=ratio - tolerance,
                   high=ratio + tolerance, detail={**(verdict.detail or {}), 'same_arm_gains': [gain, base]},
                   explanation=f'{text}: {measured:.4g} against {ratio:g} within {tolerance:g} '
                               f'({recorded["source"]})')
