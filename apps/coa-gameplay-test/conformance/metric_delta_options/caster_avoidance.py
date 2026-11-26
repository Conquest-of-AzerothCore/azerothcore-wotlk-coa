from dataclasses import replace

NAME = 'caster_avoidance'
ORDER = 16
FIELDS = ('dodge', 'parry')
BLOCK = 'block'
PHASES = ('before', 'after')


def parse(raw) -> dict:
    if not isinstance(raw, dict) or not raw or not set(raw) <= {*FIELDS, BLOCK} or not all(
            not isinstance(raw[key], bool) and isinstance(raw[key], (int, float)) and 0 <= raw[key] <= 100
            for key in raw):
        raise ValueError(f'caster_avoidance is {{"dodge": percent, "parry": percent, "block": percent}}, at least '
                         f'one of them, each between 0 and 100, not {raw!r}')
    parsed = {key: float(raw.get(key, 0)) for key in FIELDS}
    if BLOCK in raw:
        parsed[BLOCK] = float(raw[BLOCK])
    return parsed


def check(spec, avoidance):
    if avoidance is not None and spec.strike is None:
        raise ValueError(f'{spec.spell} caster_avoidance sets the caster\'s dodge and parry for a strike, and the '
                         f'entry has none')
    if avoidance is not None and BLOCK in avoidance and (
            avoidance[BLOCK] not in (0.0, 100.0) or spec.strike.owned_entry is not None):
        raise ValueError(f'{spec.spell} caster_avoidance block is 0 or 100, for a strike at the caster, not '
                         f'{avoidance[BLOCK]:g} at an owned creature')


def guard_label(spec, phase: str, blocked: bool) -> str:
    from behaviours import metric_delta_label
    return f'{metric_delta_label(spec, phase)} caster_avoidance {"blocked" if blocked else "unblocked"} strikes'


STRIKES_BY_GUARD = {}


def fixtures(class_file: dict, spec, avoidance: dict, scenario: dict):
    from behaviours import STRIKER, metric_delta_label
    from profile import CASTER, measurement
    readings = {metric_delta_label(spec, phase): phase for phase in PHASES}
    steps, strikes = [], 0
    for step in scenario['steps']:
        if step.get('action') == 'cast' and step.get('actor') == STRIKER:
            steps.append({'action': 'set_combat_avoidance', 'actor': CASTER, **avoidance})
            strikes += 1
        steps.append(step)
        if BLOCK in avoidance and step.get('label') in readings:
            phase = readings[step['label']]
            STRIKES_BY_GUARD[guard_label(spec, phase, True)] = strikes
            steps += [measurement(guard_label(spec, phase, blocked), CASTER, 'spell_damage_count',
                                  spell=spec.strike.spell, caster=STRIKER, target=CASTER, blocked=blocked)
                      for blocked in (True, False)]
    scenario['steps'] = steps
    scenario['contract'] += (f' Right before each strike the caster\'s dodge and parry chances are set to '
                             f'{avoidance["dodge"]:g}% and {avoidance["parry"]:g}% (set_combat_avoidance, '
                             f'Player::m_realDodge and m_realParry), so a melee-class strike is avoided as set.')
    if BLOCK in avoidance:
        scenario['contract'] += (f' Its block chance is set to {avoidance[BLOCK]:g}% (set_combat_avoidance block, '
                                 f'owner ruling O-20), and the striker\'s blocked and unblocked damage logs are '
                                 f'counted after each reading: every strike so far must be '
                                 f'{"blocked" if avoidance[BLOCK] else "an unblocked hit"} or the run is '
                                 f'unmeasured.')


def model(spec, avoidance: dict) -> dict:
    if BLOCK not in avoidance:
        return {NAME: avoidance}
    guards = {phase: {'blocked': guard_label(spec, phase, True), 'unblocked': guard_label(spec, phase, False),
                      'strikes': STRIKES_BY_GUARD.get(guard_label(spec, phase, True))} for phase in PHASES}
    return {NAME: {**avoidance, 'guards': guards}}


def verdict(verdict, run, avoidance: dict):
    if BLOCK not in avoidance:
        return verdict
    wanted = 'blocked' if avoidance[BLOCK] else 'unblocked'
    notes = []
    for phase, guard in avoidance['guards'].items():
        counts = {kind: run.values.get(guard[kind]) for kind in ('blocked', 'unblocked')}
        strikes = guard['strikes']
        if strikes is None or None in counts.values() or counts[wanted] != strikes or \
                counts['blocked'] + counts['unblocked'] != strikes:
            return replace(verdict, status='unmeasured',
                           explanation=f'{verdict.explanation}; {phase}: {counts["blocked"]} blocked and '
                                       f'{counts["unblocked"]} unblocked strikes against {strikes} strikes, all '
                                       f'{wanted} as set, so the reading is not the effect of the set outcome')
        notes.append(f'{phase} {strikes:g} {wanted}')
    return replace(verdict, explanation=f'{verdict.explanation}; strikes {", ".join(notes)}')
