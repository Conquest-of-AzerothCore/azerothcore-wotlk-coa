from dataclasses import replace

NAME = 'rage_per_damage'
ORDER = 22
MOMENTS = ('before', 'after')
READS = ('damage', 'hits', 'crits')
METRIC = 'rage_per_damage'
METRIC_EVIDENCE = {METRIC: 'state'}
STATE_PROMISES = {METRIC: r'based on the damage dealt'}


def parse(raw) -> dict:
    if not isinstance(raw, dict) or set(raw) != {'spell', 'target', 'min_damage_ratio'}:
        raise ValueError(f'rage_per_damage is {{"spell", "target", "min_damage_ratio"}}, not {raw!r}')
    spell, target, least = raw['spell'], raw['target'], raw['min_damage_ratio']
    if isinstance(spell, bool) or not isinstance(spell, int) or spell <= 0 or not isinstance(target, str):
        raise ValueError(f'rage_per_damage reads the damage of a spell id at a unit name, not {spell!r} at {target!r}')
    if isinstance(least, bool) or not isinstance(least, (int, float)) or least <= 1:
        raise ValueError(f'rage_per_damage min_damage_ratio is a number above 1, not {least!r}')
    return {'spell': spell, 'target': target, 'min_damage_ratio': float(least)}


def check(spec, value):
    if value is None:
        return
    from profile import CASTER
    if (spec.metric != 'power' or spec.fields != {'power': 1} or spec.measure_actor != CASTER
            or spec.phase_power is None or spec.phase_power[0] != 1 or not spec.disable_regeneration
            or not spec.cast_in_before or spec.gate_timing != 'between' or not spec.after_auras
            or spec.tolerance is None or spec.trigger_spell != value['spell']):
        raise ValueError(f'{spec.spell} rage_per_damage reads the caster\'s Rage (power 1) reset by phase_power with '
                         f'regeneration off, the trigger {value["spell"]} cast in both phases, a damage contrast in '
                         f'after_auras and a stated tolerance')


def labels(spec, moment: str) -> dict[str, str]:
    from behaviours import metric_delta_label
    base = metric_delta_label(spec, moment)
    names = {read: f'{base} {read}' for read in READS}
    if moment == 'after':
        names['cap'] = f'{base} max power'
    return names


def fixtures(class_file: dict, spec, value: dict, scenario: dict):
    from behaviours import metric_delta_label
    from profile import CASTER, measurement
    fields = {'spell': value['spell'], 'target': value['target']}
    marks = {}
    for moment in MOMENTS:
        names = labels(spec, moment)
        read = metric_delta_label(spec, moment)
        marks[read] = [measurement(names['damage'], CASTER, 'spell_damage_total', **fields),
                       measurement(names['hits'], CASTER, 'spell_damage_count', **fields),
                       measurement(names['crits'], CASTER, 'spell_damage_count', **fields, critical=True)]
        if 'cap' in names:
            marks[read].append(measurement(names['cap'], CASTER, 'max_power', power=1))
    scenario['steps'] = [step for original in scenario['steps']
                         for step in (*marks.get(original.get('label'), ()), original)]
    scenario['contract'] += (f' Rage per damage: right before each Rage reading, the logged damage of '
                             f'{value["spell"]} at the {value["target"]} (cumulative total, hit count and critical '
                             f'hit count) is read, and the caster\'s maximum Rage before the after reading. Each phase '
                             f'must land exactly one non-critical hit, the after phase must deal at least '
                             f'{value["min_damage_ratio"]:g} times the damage of the before phase and stay under the '
                             f'Rage cap; the judged value is the Rage per point of damage of the after phase divided by '
                             f'that of the before phase, 1 within {spec.tolerance:g} when the Rage follows the damage '
                             f'dealt.')


def model(spec, value: dict) -> dict:
    return {NAME: {**value, 'tolerance': spec.tolerance, 'rage': {moment: f'{spec.spell} {spec.metric} {moment}'
                                                                  for moment in MOMENTS},
                   **{moment: labels(spec, moment) for moment in MOMENTS}},
            'evidence_metric': METRIC}


def phases(values: dict, recorded: dict) -> dict | str:
    found = {}
    for moment in MOMENTS:
        for read, label in (('rage', recorded['rage'][moment]), *recorded[moment].items()):
            if values.get(label) is None:
                return f'{label} is missing'
            found[f'{moment} {read}'] = values[label]
    return {'before': {read: found[f'before {read}'] for read in ('rage', *READS)},
            'after': {'rage': found['after rage'], 'cap': found['after cap'],
                      **{read: found[f'after {read}'] - found[f'before {read}'] for read in READS}}}


def verdict(verdict, run, recorded: dict):
    phase = phases(run.values, recorded)
    if isinstance(phase, str):
        return replace(verdict, status='unmeasured', explanation=f'rage per damage: {phase}')
    before, after = phase['before'], phase['after']
    tolerance = float(recorded['tolerance'])
    text = (f'rage per damage of {recorded["spell"]}: before phase {before["rage"]:g} Rage for {before["damage"]:g} '
            f'damage in {before["hits"]:g} hits ({before["crits"]:g} critical), after phase {after["rage"]:g} Rage '
            f'for {after["damage"]:g} damage in {after["hits"]:g} hits ({after["crits"]:g} critical), Rage cap '
            f'{after["cap"]:g}')
    refused = [*(f'the {moment} phase landed {phase[moment]["hits"]:g} hits, not 1' for moment in MOMENTS
                 if phase[moment]['hits'] != 1),
               *(f'the {moment} phase landed {phase[moment]["crits"]:g} critical hits' for moment in MOMENTS
                 if phase[moment]['crits'] != 0),
               *(['a phase dealt no damage'] if before['damage'] <= 0 or after['damage'] <= 0 else []),
               *(['the after phase reached the Rage cap'] if after['rage'] >= after['cap'] else [])]
    if refused:
        return replace(verdict, status='unmeasured', explanation=f'{text}: {"; ".join(refused)}')
    contrast = after['damage'] / before['damage']
    if contrast < recorded['min_damage_ratio']:
        return replace(verdict, status='unmeasured',
                       explanation=f'{text}: a damage contrast of {contrast:.4g}, below the stated '
                                   f'{recorded["min_damage_ratio"]:g}, cannot tell Rage from damage apart')
    if before['rage'] <= 0:
        return replace(verdict, status='alert', measured=0.0, expected=1.0, low=1.0 - tolerance, high=1.0 + tolerance,
                       explanation=f'{text}: no Rage from the before phase\'s damage')
    ratio = (after['rage'] / after['damage']) / (before['rage'] / before['damage'])
    status = 'ok' if abs(ratio - 1.0) <= tolerance else 'alert'
    return replace(verdict, status=status, measured=ratio, expected=1.0, low=1.0 - tolerance, high=1.0 + tolerance,
                   detail={'damage_ratio': contrast, 'rage': [before['rage'], after['rage']],
                           'damage': [before['damage'], after['damage']]},
                   explanation=f'{text}: damage contrast {contrast:.4g}, Rage per damage after / before '
                               f'{ratio:.4g} against 1 within {tolerance:g} (a Rage independent of the damage would '
                               f'read {1 / contrast:.4g})')
