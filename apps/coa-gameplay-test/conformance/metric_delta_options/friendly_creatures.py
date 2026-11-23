NAME = 'friendly_creatures'
ORDER = 8
JUDGED_MOMENTS = ('before', 'after', 'expired')
KEYS = {'entry', 'faction', 'distances'}
MAX_FRIENDLY_CREATURES = 12
DEFAULT_FRIENDLY_FACTION = 35


def parse(raw) -> dict:
    if not isinstance(raw, dict) or not {'entry', 'distances'} <= raw.keys() or not raw.keys() <= KEYS:
        raise ValueError(f'friendly_creatures is {{"entry": id, "distances": [yd, ...], "faction": id}}, not {raw!r}')
    distances = raw['distances']
    if not isinstance(distances, list) or not 1 <= len(distances) <= MAX_FRIENDLY_CREATURES \
            or any(not isinstance(distance, (int, float)) or distance <= 0 for distance in distances):
        raise ValueError(f'friendly_creatures distances are 1 to {MAX_FRIENDLY_CREATURES} positive yd, '
                         f'not {distances!r}')
    entry, faction = raw['entry'], raw.get('faction', DEFAULT_FRIENDLY_FACTION)
    if not isinstance(entry, int) or entry < 1 or not isinstance(faction, int) or faction < 1:
        raise ValueError(f'friendly_creatures entry and faction are positive ids, not {entry!r} / {faction!r}')
    return {'entry': entry, 'faction': faction, 'distances': [float(distance) for distance in distances]}


def check(spec, option):
    if option is None:
        return
    options = dict(spec.options)
    for other in ('area_dummies', 'area_sum', 'fields_sum'):
        if options.get(other) is not None:
            raise ValueError(f'{spec.spell} sets friendly_creatures and {other}, two sets of extra readings')
    if spec.metric != 'aura':
        raise ValueError(f'{spec.spell} friendly_creatures sums the aura reading of each creature, not {spec.metric}')


def friend_id(index: int) -> str:
    return f'friend{index + 1}'


def friend_names(option: dict) -> list[str]:
    return [friend_id(index) for index in range(len(option['distances']))]


def part_label(label: str, friend: str) -> str:
    return f'{label} {friend}'


def fixtures(class_file: dict, spec, option: dict, scenario: dict):
    from behaviours import CASTER, metric_delta_label
    names = friend_names(option)
    scenario.setdefault('creatures', [])
    scenario['creatures'] += [{'id': name, 'owner': CASTER, 'entry': option['entry'], 'distance': distance,
                               'faction': option['faction'], 'level': class_file['level'], 'stationary': True}
                              for name, distance in zip(names, option['distances'])]
    judged = {metric_delta_label(spec, moment) for moment in JUDGED_MOMENTS}
    steps = []
    for step in scenario['steps']:
        steps.append(step)
        if step.get('action') == 'assert' and step.get('label') in judged:
            steps += [{**step, 'actor': name, 'label': part_label(step['label'], name)} for name in names]
    scenario['steps'] = steps
    scenario['contract'] += (f' {len(names)} friendly creatures ({", ".join(names)}: entry {option["entry"]}, '
                             f'faction {option["faction"]}) stand at {option["distances"]} yd from the caster, '
                             f'fixtures outside the caster\'s party; each judged reading is the sum of {spec.metric} '
                             f'{spec.fields} on {spec.measure_actor} and on every friendly creature.')


def model(spec, option: dict) -> dict:
    from behaviours import metric_delta_label
    names = friend_names(option)
    return {NAME: {'parts': {metric_delta_label(spec, moment): [part_label(metric_delta_label(spec, moment), name)
                                                                for name in names]
                             for moment in JUDGED_MOMENTS}}}


def run_values(values: dict, summed: dict) -> dict:
    out = dict(values)
    for label, parts in summed['parts'].items():
        if label in out:
            out[label] = (out[label] + sum(values[part] for part in parts)
                          if all(part in values for part in parts) else None)
    return {label: value for label, value in out.items() if value is not None}
