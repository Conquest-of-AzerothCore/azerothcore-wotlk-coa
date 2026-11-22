from dataclasses import dataclass, replace

NAME = 'second_strike'
ORDER = 17


@dataclass(frozen=True)
class SecondStrike:
    spell: int
    present: float
    wait_ms: int = 300


def parse(raw) -> SecondStrike:
    if not isinstance(raw, dict) or set(raw) - {'spell', 'present', 'wait_ms'} or not {'spell', 'present'} <= set(raw):
        raise ValueError(f'second_strike takes a spell, a present reading and an optional wait_ms, not {raw!r}')
    if any(isinstance(raw[key], bool) for key in raw):
        raise ValueError(f'second_strike takes numbers, not {raw!r}')
    strike = SecondStrike(int(raw['spell']), float(raw['present']), int(raw.get('wait_ms', 300)))
    if strike.wait_ms < 0:
        raise ValueError('second_strike needs a wait of at least 0 ms')
    return strike


def present_label(spec) -> str:
    return f'{spec.spell} second_strike present'


def log_label(spec, strike: SecondStrike) -> str:
    return f'{spec.spell} second_strike {strike.spell} damage logs'


def log_before_label(spec, strike: SecondStrike) -> str:
    return f'{log_label(spec, strike)} before'


def check(spec, strike):
    if strike is None:
        return
    if spec.strike is None:
        raise ValueError(f'{spec.spell} second_strike strikes again after the entry\'s strike, and the entry has none')
    if strike.spell == spec.strike.spell:
        raise ValueError(f'{spec.spell} second_strike needs a spell other than the strike\'s {strike.spell}')


def after_trigger_steps(spec, strike: SecondStrike, after: bool) -> list[dict]:
    from behaviours import STRIKER
    from profile import CASTER, measurement
    read = [measurement(present_label(spec), spec.measure_actor, spec.metric, **spec.fields)] if after else []
    return read + [{'action': 'cast', 'actor': STRIKER, 'spell': strike.spell, 'target': CASTER},
                   {'action': 'wait', 'label': 'second strike', 'ms': strike.wait_ms}]


def fixtures(class_file: dict, spec, strike: SecondStrike, scenario: dict):
    from behaviours import STRIKER, metric_delta_label
    from profile import CASTER, measurement
    steps = []
    for step in scenario['steps']:
        if step.get('action') == 'cast' and step.get('actor') == STRIKER and step.get('spell') == strike.spell:
            if steps and steps[-1].get('action') == 'set_combat_avoidance':
                steps.pop()
            steps.append({'action': 'set_combat_avoidance', 'actor': CASTER, 'dodge': 0.0, 'parry': 0.0})
        steps.append(step)
    before = next(index for index, step in enumerate(steps) if step.get('label') == metric_delta_label(spec, 'before'))
    steps.insert(before + 1, measurement(log_before_label(spec, strike), CASTER, 'spell_log_count',
                                         spell=strike.spell, caster=STRIKER))
    after = next(index for index, step in enumerate(steps) if step.get('label') == metric_delta_label(spec, 'after'))
    read = measurement(log_label(spec, strike), CASTER, 'spell_log_count', spell=strike.spell, caster=STRIKER)
    scenario['steps'] = steps[:after + 1] + [read] + steps[after + 1:]
    scenario['contract'] += (f' After each trigger cast the striker casts {strike.spell} at the caster with the '
                             f'caster\'s dodge and parry set to 0%, {strike.wait_ms} ms before the wait to the '
                             f'reading; in the treatment phase the reading is taken once right before that second '
                             f'strike and must be {strike.present:g}, and the second strike\'s damage logs are '
                             f'counted after each reading: a missing state, or a phase without exactly one landed second '
                             f'strike, makes the trial unmeasured.')


def model(spec, strike: SecondStrike) -> dict:
    return {NAME: {'spell': strike.spell, 'present': strike.present, 'present_label': present_label(spec),
                   'log_label': log_label(spec, strike),
                   'log_before_label': log_before_label(spec, strike)}}


def verdict(verdict, run, strike: dict):
    present = run.values.get(strike['present_label'])
    if present is None or abs(present - strike['present']) > 1e-6:
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; the reading before the second strike is {present}, not '
                                   f'{strike["present"]:g}, so the second strike did not meet the state it tests')
    before = run.values.get(strike['log_before_label'])
    total = run.values.get(strike['log_label'])
    if before is None or total is None or before != 1 or total - before != 1:
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; {strike["spell"]} second strikes landed {before} times '
                                   f'in the control phase and {None if before is None or total is None else total - before} '
                                   f'in the treatment phase, not once in each, so the reading is not its effect')
    return replace(verdict, explanation=f'{verdict.explanation}; read {present:g} before the second strike, one '
                                        f'{strike["spell"]} second strike landed in each phase')
