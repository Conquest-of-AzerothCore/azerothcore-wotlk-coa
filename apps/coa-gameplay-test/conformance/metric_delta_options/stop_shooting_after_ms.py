from dataclasses import replace

NAME = 'stop_shooting_after_ms'
ORDER = 23
STEP_MS = 25
RELOCATE_LIMIT_YD = 20.0
MOVE_LIMIT_YD = 60.0
COUNTED = ('relocate', 'after', 'expired')
METRIC = 'stop_shooting_attack_time_ms'
METRIC_EVIDENCE = {METRIC: 'state'}
STATE_PROMISES = {METRIC: r'for \$\d*d'}


def parse(raw) -> dict:
    if not isinstance(raw, dict) or set(raw) != {'ms', 'dx', 'spell', 'target'}:
        raise ValueError(f'stop_shooting_after_ms is {{"ms", "dx", "spell", "target"}}, not {raw!r}')
    ms, dx, spell, target = raw['ms'], raw['dx'], raw['spell'], raw['target']
    if isinstance(ms, bool) or not isinstance(ms, int) or not 0 < ms <= 2000:
        raise ValueError(f'stop_shooting_after_ms ms lies in (0, 2000], not {ms!r}')
    if isinstance(dx, bool) or not isinstance(dx, (int, float)) or not 0 < abs(dx) <= MOVE_LIMIT_YD:
        raise ValueError(f'stop_shooting_after_ms dx is a nonzero number of yards up to {MOVE_LIMIT_YD:g}, not {dx!r}')
    if isinstance(spell, bool) or not isinstance(spell, int) or spell <= 0 or not isinstance(target, str):
        raise ValueError(f'stop_shooting_after_ms counts a spell id at a unit name, not {spell!r} at {target!r}')
    return {'ms': ms, 'dx': float(dx), 'spell': spell, 'target': target}


def check(spec, value):
    if value is None:
        return
    if (spec.gate_timing != 'start' or not spec.trigger_only_after or spec.expiry_wait_ms is None
            or spec.game_time is None or spec.game_time[1] is None or spec.trigger_spell != value['spell']):
        raise ValueError(f'{spec.spell} stop_shooting_after_ms stops the shooting of the trigger {value["spell"]} cast '
                         f'in the treatment only (gate_timing start, trigger_only_after), before an expiry read '
                         f'bracketed by game_time windows')


def labels(spec) -> dict[str, str]:
    from behaviours import metric_delta_label
    names = {moment: f'{metric_delta_label(spec, moment)} {NAME} shots' for moment in COUNTED}
    names['relocate at'] = f'{metric_delta_label(spec, "relocate")} {NAME} game_time'
    return names


def shot_count(spec, value: dict, label: str) -> dict:
    from profile import CASTER, measurement
    return measurement(label, CASTER, 'spell_damage_count', spell=value['spell'], target=value['target'])


def phase_steps(spec, value: dict, after: bool) -> list[dict]:
    if after:
        return []
    from profile import CASTER
    steps = []
    for spell in spec.setup_casts:
        steps += [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spell},
                  {'action': 'cast', 'actor': CASTER, 'spell': spell, 'target': spec.setup_target or spec.target}]
        if spec.setup_wait_ms:
            steps.append({'action': 'wait', 'ms': spec.setup_wait_ms})
    return steps


def after_trigger_steps(spec, value: dict, after: bool) -> list[dict]:
    if not after:
        return []
    from profile import CASTER, measurement
    names = labels(spec)
    return [{'action': 'wait', 'label': 'until the shooter leaves the range', 'ms': value['ms']},
            measurement(names['relocate at'], CASTER, 'game_time_ms'),
            shot_count(spec, value, names['relocate']),
            *relocate_steps(value['dx'])]


def relocate_steps(dx: float) -> list[dict]:
    from profile import CASTER
    steps, left = [], dx
    while left:
        move = max(-RELOCATE_LIMIT_YD, min(RELOCATE_LIMIT_YD, left))
        steps.append({'action': 'relocate', 'actor': CASTER, 'dx': move})
        left -= move
    return steps


def fixtures(class_file: dict, spec, value: dict, scenario: dict):
    from behaviours import metric_delta_label
    names = labels(spec)
    marks = {metric_delta_label(spec, moment): shot_count(spec, value, names[moment]) for moment in ('after', 'expired')}
    scenario['steps'] = [step for original in scenario['steps']
                         for step in ((marks[original['label']],) if original.get('label') in marks else ())
                         + (original,)]
    scenario['contract'] += (f' The shooting is stopped without a harness action: {value["ms"]} ms after the treatment '
                             f'cast of {value["spell"]} the caster is moved {value["dx"]:g} yd along x (relocate '
                             f'steps of at most {RELOCATE_LIMIT_YD:g} yd), out of its range, after the logged hits of {value["spell"]} at the {value["target"]} and the game '
                             f'time are read; the hit count is read again before the after and the expired readings. '
                             f'At least one hit must land before the move, no hit after it, and the move must come at '
                             f'most {value["ms"] + STEP_MS} ms of game time after the cast, so the aura began inside '
                             f'that time. The setup casts are repeated in the before phase, which casts no trigger.')


def model(spec, value: dict) -> dict:
    from behaviours import game_time_labels
    return {NAME: {**value, **labels(spec), 'cast': game_time_labels(spec)[0]}, 'evidence_metric': METRIC}


def verdict(verdict, run, recorded: dict):
    if verdict.status == 'unmeasured':
        return verdict
    reads = {name: run.values.get(recorded[name]) for name in (*COUNTED, 'relocate at')}
    cast = run.values.get(recorded['cast'])
    missing = [name for name, found in reads.items() if found is None] + ([] if cast is not None else ['cast'])
    if missing:
        return replace(verdict, status='unmeasured', explanation=f'{verdict.explanation}; stop shooting: '
                                                                 f'{", ".join(missing)} not read')
    moved = reads['relocate at'] - cast
    text = (f'{reads["relocate"]:g} hits of {recorded["spell"]} before the move at {moved:g} ms after the cast, '
            f'{reads["after"]:g} at the after reading and {reads["expired"]:g} at the expired reading')
    failures = [*(['no hit landed before the move'] if reads['relocate'] < 1 else []),
                *(['a hit landed after the move'] if reads['after'] != reads['relocate']
                  or reads['expired'] != reads['relocate'] else []),
                *([f'the move came later than {recorded["ms"] + STEP_MS} ms'] if moved > recorded['ms'] + STEP_MS
                  else [])]
    if failures:
        return replace(verdict, status='unmeasured', explanation=f'{verdict.explanation}; stop shooting: {text}: '
                                                                 f'{"; ".join(failures)}')
    return replace(verdict, explanation=f'{verdict.explanation}; stop shooting: {text}')
