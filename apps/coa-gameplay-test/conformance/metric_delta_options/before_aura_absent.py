from dataclasses import replace

NAME = 'before_aura_absent'
ORDER = 7


def parse(raw) -> dict:
    if not isinstance(raw, dict) or set(raw) != {'aura', 'entry', 'source'} or not isinstance(raw['aura'], int) \
            or not isinstance(raw['entry'], int) or not isinstance(raw['source'], str) or not raw['source']:
        raise ValueError(f'before_aura_absent is {{"aura": id, "entry": id, "source": text}}, not {raw!r}')
    return raw


def read_label(spec, absent: dict) -> str:
    return f'{spec.spell} before_aura_absent {absent["aura"]} on {absent["entry"]}'


def fixtures(class_file: dict, spec, absent: dict, scenario: dict):
    from behaviours import metric_delta_label
    from profile import CASTER, measurement
    steps = scenario['steps']
    before = next(index for index, step in enumerate(steps) if step.get('label') == metric_delta_label(spec, 'before'))
    read = measurement(read_label(spec, absent), CASTER, 'owned_creature_aura_max_duration_ms', spell=absent['aura'],
                       entry=absent['entry'])
    scenario['steps'] = steps[:before] + [read] + steps[before:]
    scenario['contract'] += (f' Right before the before reading, the owned creature {absent["entry"]} must hold no '
                             f'{absent["aura"]} ({absent["source"]}): a control that holds it is not the plain one.')


def model(spec, absent: dict) -> dict:
    return {NAME: {'aura': absent['aura'], 'entry': absent['entry'], 'read_label': read_label(spec, absent)}}


def verdict(verdict, run, absent: dict):
    held = run.values.get(absent['read_label'])
    if held is None or held > 0:
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; the owned {absent["entry"]} held {absent["aura"]} at the '
                                   f'before reading (max duration {held}), so the control is not the plain one')
    return verdict
