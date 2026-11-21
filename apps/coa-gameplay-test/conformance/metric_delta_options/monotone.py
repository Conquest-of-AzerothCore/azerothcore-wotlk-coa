from dataclasses import replace

NAME = 'monotone'
ORDER = 11
EXPIRE_WAIT_LABEL = 'let the first effect fully expire'


def parse(raw) -> dict:
    if not isinstance(raw, dict) or set(raw) != {'levels', 'cumulative'} or not isinstance(raw['cumulative'], bool) \
            or not isinstance(raw['levels'], list) or not raw['levels'] \
            or not all(isinstance(level, int) and not isinstance(level, bool) for level in raw['levels']):
        raise ValueError(f'monotone is {{"levels": [power, ...], "cumulative": true|false}}, not {raw!r}')
    return {'levels': tuple(raw['levels']), 'cumulative': raw['cumulative']}


def check(spec, monotone):
    if monotone is None:
        return
    if spec.phase_power is None:
        raise ValueError(f'{spec.spell} monotone raises the phase power, so it needs phase_power')
    _, control, first = spec.phase_power
    powers = (control, first, *monotone['levels'])
    if any(low >= high for low, high in zip(powers, powers[1:])):
        raise ValueError(f'{spec.spell} monotone levels {list(powers)} must rise strictly from the control')
    if spec.expiry_wait_ms is not None or spec.attack_swings or spec.gate_timing != 'between':
        raise ValueError(f'{spec.spell} monotone repeats the plain treatment phase only')


def level_label(spec, level: int) -> str:
    from behaviours import metric_delta_label
    return f'{metric_delta_label(spec, "level")} {level}'


def fixtures(class_file: dict, spec, monotone: dict, scenario: dict):
    from behaviours import metric_delta_label
    steps = scenario['steps']
    after_label = metric_delta_label(spec, 'after')
    after = next(index for index, step in enumerate(steps) if step.get('label') == after_label)
    start = max(index for index, step in enumerate(steps[:after]) if step.get('label') == EXPIRE_WAIT_LABEL)
    power, _, first = spec.phase_power
    block = steps[start:after + 1]
    added = []
    for level in monotone['levels']:
        for step in block:
            if step.get('action') == 'set_power' and step.get('power') == power and step.get('value') == first:
                step = {**step, 'value': level}
            elif step.get('label') == after_label:
                step = {**step, 'label': level_label(spec, level)}
            added.append(step)
    scenario['steps'] = steps[:after + 1] + added + steps[after + 1:]
    scenario['contract'] += (f' The treatment phase is repeated at power {list(monotone["levels"])} (power type '
                             f'{power}) after the after reading; the readings at the control, at {first} and at '
                             f'each level must rise strictly' + (', each phase judged by its own increase of the '
                                                                 'cumulative metric' if monotone['cumulative']
                                                                 else '') + '.')


def model(spec, monotone: dict) -> dict:
    from behaviours import metric_delta_label
    _, control, first = spec.phase_power
    return {NAME: {'powers': [control, first, *monotone['levels']], 'cumulative': monotone['cumulative'],
                   'labels': [metric_delta_label(spec, 'before'), metric_delta_label(spec, 'after'),
                              *(level_label(spec, level) for level in monotone['levels'])]}}


def verdict(verdict, run, monotone: dict):
    from compare import missing_measurement
    reads = [run.values.get(label) for label in monotone['labels']]
    missing = next((label for label, value in zip(monotone['labels'], reads) if value is None), None)
    if missing is not None:
        return replace(verdict, status='alert', explanation=missing_measurement(run, missing))
    phases = ([reads[0], *(high - low for low, high in zip(reads, reads[1:]))] if monotone['cumulative']
              else reads)
    rising = all(low < high for low, high in zip(phases, phases[1:]))
    pairs = ', '.join(f'{value:g} at power {power}' for power, value in zip(monotone['powers'], phases))
    return replace(verdict, status='ok' if rising else 'alert', measured=phases[-1], expected=None, low=None,
                   high=None, explanation=f'per phase {pairs}; judged strictly rising from the control (no amount '
                                          f'stated, the plain before/after bands are not applied): '
                                          f'{"rising" if rising else "not rising"}')
