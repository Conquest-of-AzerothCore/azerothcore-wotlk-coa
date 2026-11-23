NAME = 'skill_line'
ORDER = 25
MAX_SKILL_VALUE = 450


def parse(raw) -> dict:
    if not isinstance(raw, dict) or set(raw) != {'skill', 'value', 'maximum'} \
            or not all(type(raw[key]) is int for key in raw):
        raise ValueError(f'skill_line is {{"skill": id, "value": n, "maximum": n}}, not {raw!r}')
    if raw['skill'] < 1 or not 1 <= raw['value'] <= raw['maximum'] <= MAX_SKILL_VALUE:
        raise ValueError(f'skill_line needs a positive skill id and 1 <= value <= maximum <= {MAX_SKILL_VALUE}, '
                         f'not {raw!r}')
    return dict(raw)


def phase_steps(spec, line: dict, after: bool) -> list[dict]:
    from profile import CASTER
    if after:
        return []
    return [{'action': 'set_skill', 'actor': CASTER, 'skill': line['skill'], 'value': line['value'],
             'maximum': line['maximum']}]


def fixtures(class_file: dict, spec, line: dict, scenario: dict):
    scenario['contract'] += (f' The caster is given skill line {line["skill"]} at {line["value"]} of '
                             f'{line["maximum"]} at the start of the before phase, a precondition fixture.')
