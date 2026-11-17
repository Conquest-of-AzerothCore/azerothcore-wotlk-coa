NAME = 'caster_avoidance'
ORDER = 16
FIELDS = ('dodge', 'parry')


def parse(raw) -> dict:
    if not isinstance(raw, dict) or not raw or not set(raw) <= set(FIELDS) or not all(
            not isinstance(raw[key], bool) and isinstance(raw[key], (int, float)) and 0 <= raw[key] <= 100
            for key in raw):
        raise ValueError(f'caster_avoidance is {{"dodge": percent, "parry": percent}}, at least one of them, each '
                         f'between 0 and 100, not {raw!r}')
    return {key: float(raw.get(key, 0)) for key in FIELDS}


def check(spec, avoidance):
    if avoidance is not None and spec.strike is None:
        raise ValueError(f'{spec.spell} caster_avoidance sets the caster\'s dodge and parry for a strike, and the '
                         f'entry has none')


def fixtures(class_file: dict, spec, avoidance: dict, scenario: dict):
    from behaviours import STRIKER
    from profile import CASTER
    steps = []
    for step in scenario['steps']:
        if step.get('action') == 'cast' and step.get('actor') == STRIKER:
            steps.append({'action': 'set_combat_avoidance', 'actor': CASTER, **avoidance})
        steps.append(step)
    scenario['steps'] = steps
    scenario['contract'] += (f' Right before each strike the caster\'s dodge and parry chances are set to '
                             f'{avoidance["dodge"]:g}% and {avoidance["parry"]:g}% (set_combat_avoidance, '
                             f'Player::m_realDodge and m_realParry), so a melee-class strike is avoided as set.')


def model(spec, avoidance: dict) -> dict:
    return {NAME: avoidance}
