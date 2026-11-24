from dataclasses import replace

NAME = 'attack_power_arms'
ORDER = 43
KEYS = {'aura', 'wait_ms', 'source'}
ATTACK_POWER = 'attack_power'
ATTACK_POWER_TOLERANCE = 0.5
READS = ('control high', 'learned high')
POWER_READS = ('control low', 'control high', 'learned low', 'learned high')


def parse(raw) -> dict:
    if not isinstance(raw, dict) or set(raw) != KEYS:
        raise ValueError(f'attack_power_arms is {{"aura", "wait_ms", "source"}}, not {raw!r}')
    for key in ('aura', 'wait_ms'):
        if isinstance(raw[key], bool) or not isinstance(raw[key], int) or raw[key] <= 0:
            raise ValueError(f'attack_power_arms {key} is a positive integer, not {raw[key]!r}')
    if not isinstance(raw['source'], str) or not raw['source'].strip():
        raise ValueError('attack_power_arms source cites the attack power fixture aura')
    return {'aura': raw['aura'], 'wait_ms': raw['wait_ms'], 'source': raw['source']}


def check(spec, value):
    if value is None:
        return
    if spec.gate_timing != 'between' or spec.setup_only_after or spec.attack_swings or \
            spec.expiry_wait_ms is not None:
        raise ValueError(f'{spec.spell} attack_power_arms repeats the plain learned contrast only')
    if any(found is not None for found in (spec.expected_gain, spec.expected_ratio, spec.after_at_least,
                                           spec.after_at_most, spec.phase_power)):
        raise ValueError(f'{spec.spell} attack_power_arms judges a direction only, so it states no gain, ratio, '
                         f'bound or phase power')
    if spec.metric == ATTACK_POWER:
        raise ValueError(f'{spec.spell} attack_power_arms reads attack power as its fixture, not as the metric')


def labels(spec) -> dict:
    from behaviours import metric_delta_label
    return {'reads': {arm: metric_delta_label(spec, arm) for arm in READS},
            'power': {arm: f'{spec.spell} {NAME} {ATTACK_POWER} {arm}' for arm in POWER_READS}}


def fixtures(class_file: dict, spec, value: dict, scenario: dict):
    from behaviours import AFTER, BEFORE, CASTER, metric_delta_label
    from profile import measurement
    names = labels(spec)
    steps = scenario['steps']
    before_label, after_label = metric_delta_label(spec, BEFORE), metric_delta_label(spec, AFTER)
    reading = next(step for step in steps if step.get('label') == before_label)

    def power(arm: str) -> dict:
        return measurement(names['power'][arm], CASTER, ATTACK_POWER)

    def aura(stacks: int) -> dict:
        return {'action': 'set_aura', 'actor': CASTER, 'spell': value['aura'], 'stacks': stacks}

    def raised(arm: str) -> list[dict]:
        return [power(f'{arm} low'), aura(1), {'action': 'wait', 'ms': value['wait_ms']}, power(f'{arm} high'),
                {**reading, 'label': names['reads'][f'{arm} high']}]

    added = {before_label: [*raised('control'), aura(0)], after_label: raised('learned')}
    scenario['steps'] = [step for original in steps for step in (original, *added.get(original.get('label'), ()))]
    scenario['contract'] += (f' Attack power arms: right after the before reading the caster reads its attack power, '
                             f'takes the fixture aura {value["aura"]} ({value["source"]}), waits {value["wait_ms"]} '
                             f'ms, reads its attack power and the metric again (control high), and loses the aura; '
                             f'right after the after reading the learned arm repeats it (learned high). The attack '
                             f'power gain is read, not assumed: it must be positive and the same in both arms, and '
                             f'the low and high attack power of the learned arm must match the control arm, else '
                             f'the trial is void. Judged on the direction only (no amount, no before value, the '
                             f'plain before/after bands are not applied): the learned gain at the low attack power '
                             f'(after minus before) is positive, and the learned gain at the high attack power '
                             f'(learned high minus control high) is strictly larger.')


def model(spec, value: dict) -> dict:
    from behaviours import AFTER, BEFORE, metric_delta_label
    from compare import METRIC_DELTA_FLOAT_TOLERANCE
    tolerance = METRIC_DELTA_FLOAT_TOLERANCE if spec.tolerance is None else spec.tolerance
    return {NAME: {**value, **labels(spec), 'metric': spec.metric, 'tolerance': tolerance,
                   'before_label': metric_delta_label(spec, BEFORE), 'after_label': metric_delta_label(spec, AFTER)}}


def verdict(verdict, run, recorded: dict):
    from compare import missing_measurement
    if verdict.status == 'unmeasured':
        return verdict
    tolerance = float(recorded['tolerance'])
    wanted = {'before': recorded['before_label'], 'after': recorded['after_label'],
              **recorded['reads'],
              **{f'{ATTACK_POWER} {arm}': label for arm, label in recorded['power'].items()}}
    read = {name: run.values.get(label) for name, label in wanted.items()}
    missing = next((wanted[name] for name, found in read.items() if found is None), None)
    if missing is not None:
        return replace(verdict, status='unmeasured', explanation=missing_measurement(run, missing))
    power = {arm: float(read[f'{ATTACK_POWER} {arm}']) for arm in POWER_READS}
    control_gain = power['control high'] - power['control low']
    learned_gain = power['learned high'] - power['learned low']
    powers = ', '.join(f'{power[arm]:g} {arm}' for arm in POWER_READS)
    if control_gain <= ATTACK_POWER_TOLERANCE or \
            abs(power['learned low'] - power['control low']) > ATTACK_POWER_TOLERANCE or \
            abs(power['learned high'] - power['control high']) > ATTACK_POWER_TOLERANCE:
        return replace(verdict, status='unmeasured',
                       explanation=f'attack power arms: attack power read {powers}; the fixture gain is '
                                   f'{control_gain:g} in the control arm and {learned_gain:g} in the learned arm, '
                                   f'so the two arms do not compare the same two attack powers and the trial is void')
    low_gain = float(read['after']) - float(read['before'])
    high_gain = float(read['learned high']) - float(read['control high'])
    rising = low_gain > tolerance and high_gain > low_gain + tolerance
    detail = {**(verdict.detail or {}), 'arm_gains': [low_gain, high_gain],
              'attack_power': [power[arm] for arm in POWER_READS]}
    return replace(verdict, status='ok' if rising else 'alert', measured=high_gain, expected=None, low=low_gain,
                   high=None, detail=detail,
                   explanation=f'attack power arms ({recorded["metric"]}): '
                               f'{read["before"]:g} before and {read["after"]:g} after the learn at attack power '
                               f'{power["control low"]:g} (gain {low_gain:g}); {read["control high"]:g} without and '
                               f'{read["learned high"]:g} with the spell at attack power {power["control high"]:g} '
                               f'(gain {high_gain:g}, the fixture adding {control_gain:g} attack power as read); '
                               f'judged on the direction only, the low gain above {tolerance:g} and the high gain '
                               f'strictly above the low gain: {"rising" if rising else "not rising"}')
