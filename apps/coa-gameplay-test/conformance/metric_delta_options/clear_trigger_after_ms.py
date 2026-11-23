from dataclasses import replace

NAME = 'clear_trigger_after_ms'
ORDER = 24
STEP_MS = 25
MAX_MS = 10000
FIELDS = {'ms', 'quiet_ms', 'spell', 'target'}
COUNTED = ('after', 'expired')
METRIC = 'cleared_trigger_state'
METRIC_EVIDENCE = {METRIC: 'state'}
STATE_PROMISES = {METRIC: r'for \$\d*d'}


def whole_ms(value) -> bool:
    return not isinstance(value, bool) and isinstance(value, int)


def parse(raw) -> dict:
    if not isinstance(raw, dict) or set(raw) != FIELDS:
        raise ValueError(f'{NAME} is {{"ms", "quiet_ms", "spell", "target"}}, not {raw!r}')
    ms, quiet, spell, target = raw['ms'], raw['quiet_ms'], raw['spell'], raw['target']
    if not whole_ms(ms) or not whole_ms(quiet) or not 0 < quiet < ms <= MAX_MS:
        raise ValueError(f'{NAME} reads the quiet count at quiet_ms and clears at ms, 0 < quiet_ms < ms <= {MAX_MS}, '
                         f'not {quiet!r} and {ms!r}')
    if not whole_ms(spell) or spell <= 0 or not isinstance(target, str):
        raise ValueError(f'{NAME} clears a spell id from a unit name, not {spell!r} from {target!r}')
    return {'ms': ms, 'quiet_ms': quiet, 'spell': spell, 'target': target}


def check(spec, value):
    if value is None:
        return
    if (spec.gate_timing != 'start' or not spec.trigger_only_after or spec.expiry_wait_ms is None
            or spec.game_time is None or spec.game_time[1] is None or spec.trigger_spell != value['spell']
            or spec.target != value['target']):
        raise ValueError(f'{spec.spell} {NAME} clears the trigger {value["spell"]} from its own target after the '
                         f'treatment cast only (gate_timing start, trigger_only_after), before an expiry read '
                         f'bracketed by game_time windows')
    if spec.game_time[0][0] <= value['ms']:
        raise ValueError(f'{spec.spell} {NAME} clears at {value["ms"]} ms, not before the after window '
                         f'{list(spec.game_time[0])}')


def labels(spec) -> dict[str, str]:
    from behaviours import metric_delta_label
    names = {moment: f'{metric_delta_label(spec, moment)} {NAME} ticks'
             for moment in ('cast', 'quiet', 'cleared', *COUNTED)}
    names['cleared at'] = f'{metric_delta_label(spec, "cleared")} {NAME} game_time'
    return names


def tick_count(value: dict, label: str) -> dict:
    from profile import CASTER, measurement
    return measurement(label, CASTER, 'spell_damage_count', spell=value['spell'], target=value['target'],
                       periodic=True)


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
    return [tick_count(value, names['cast']),
            {'action': 'wait', 'label': 'until the quiet tick count', 'ms': value['quiet_ms']},
            tick_count(value, names['quiet']),
            {'action': 'wait', 'label': 'until the trigger aura is cleared', 'ms': value['ms'] - value['quiet_ms']},
            measurement(names['cleared at'], CASTER, 'game_time_ms'),
            tick_count(value, names['cleared']),
            {'action': 'set_aura', 'actor': CASTER, 'spell': value['spell'], 'stacks': 0,
             'target': value['target']}]


def fixtures(class_file: dict, spec, value: dict, scenario: dict):
    from behaviours import metric_delta_label
    names = labels(spec)
    marks = {metric_delta_label(spec, moment): tick_count(value, names[moment]) for moment in COUNTED}
    scenario['steps'] = [step for original in scenario['steps']
                         for step in ((marks[original['label']],) if original.get('label') in marks else ())
                         + (original,)]
    scenario['contract'] += (f' The trigger aura is cleared after one periodic tick: the periodic hits of '
                             f'{value["spell"]} at the {value["target"]} are read right after the treatment cast, '
                             f'{value["quiet_ms"]} ms after it (no tick yet) and {value["ms"]} ms after it (exactly '
                             f'one tick), with the game time, and {value["spell"]} is then removed from the '
                             f'{value["target"]} (harness set_aura 0, a precondition fixture on the trigger, not the '
                             f'claim); the count is read again before the after and the expired readings and must '
                             f'not grow, so the measured aura began with that one tick, between {value["quiet_ms"]} '
                             f'and {value["ms"] + STEP_MS} ms of game time after the cast. The setup casts are '
                             f'repeated in the before phase, which casts no trigger.')


def model(spec, value: dict) -> dict:
    from behaviours import game_time_labels
    return {NAME: {**value, **labels(spec), 'cast stamp': game_time_labels(spec)[0]}, 'evidence_metric': METRIC}


def verdict(verdict, run, recorded: dict):
    if verdict.status == 'unmeasured':
        return verdict
    names = ('cast', 'quiet', 'cleared', *COUNTED, 'cleared at', 'cast stamp')
    reads = {name: run.values.get(recorded[name]) for name in names}
    missing = [name for name, found in reads.items() if found is None]
    if missing:
        return replace(verdict, status='unmeasured', explanation=f'{verdict.explanation}; {NAME}: '
                                                                 f'{", ".join(missing)} not read')
    cleared_at = reads['cleared at'] - reads['cast stamp']
    text = (f'periodic hits of {recorded["spell"]}: {reads["cast"]:g} at the cast, {reads["quiet"]:g} at '
            f'{recorded["quiet_ms"]} ms, {reads["cleared"]:g} when cleared at {cleared_at:g} ms, {reads["after"]:g} '
            f'at the after reading and {reads["expired"]:g} at the expired reading')
    failures = [*(['a tick landed before the quiet read'] if reads['quiet'] != reads['cast'] else []),
                *(['not exactly one tick before the clear'] if reads['cleared'] - reads['quiet'] != 1 else []),
                *(['a tick landed after the clear'] if reads['after'] != reads['cleared']
                  or reads['expired'] != reads['cleared'] else []),
                *([f'the clear came later than {recorded["ms"] + STEP_MS} ms'] if cleared_at > recorded['ms'] + STEP_MS
                  else [])]
    if failures:
        return replace(verdict, status='unmeasured', explanation=f'{verdict.explanation}; {NAME}: {text}: '
                                                                 f'{"; ".join(failures)}')
    return replace(verdict, explanation=f'{verdict.explanation}; {NAME}: {text}')
