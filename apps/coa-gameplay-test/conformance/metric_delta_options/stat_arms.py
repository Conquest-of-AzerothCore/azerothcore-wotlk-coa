from dataclasses import replace

NAME = 'stat_arms'
ORDER = 44
FORBIDS_EXPECTED = True
PASSIVE, ACTIVE_RECAST = 'passive', 'active_recast'
MODES = (PASSIVE, ACTIVE_RECAST)
KEYS = {'mode', 'input', 'arms', 'unrelated', 'wait_ms'}
STAT_KEYS = {'metric', 'fields'}
ARM_KEYS = {'aura', 'stacks', 'source'}
UNRELATED_KEYS = {'metric', 'fields', 'aura', 'stacks', 'source'}
ALLOWED_INPUT_METRICS = frozenset({
    'stat', 'stat_exact', 'combat_rating', 'attack_power', 'ranged_attack_power',
    'spell_power', 'max_health', 'armor', 'healing_power',
})
INPUT_TOLERANCE = 0.5
MIN_ADDED_ARMS = 2
EXPIRE_WAIT_LABEL = 'let the first effect fully expire'


def positive_int(value, label: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
        raise ValueError(f'{NAME} {label} is a positive integer, not {value!r}')
    return value


def non_negative_int(value, label: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise ValueError(f'{NAME} {label} is a non-negative integer, not {value!r}')
    return value


def non_empty_str(value, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f'{NAME} {label} must be a non-empty string')
    return value


def parsed_stat(raw, role: str) -> dict:
    if not isinstance(raw, dict) or set(raw) != STAT_KEYS:
        raise ValueError(f'{NAME} {role} is {{"metric", "fields"}}, not {raw!r}')
    metric = raw['metric']
    if metric not in ALLOWED_INPUT_METRICS or not isinstance(raw['fields'], dict):
        raise ValueError(f'{NAME} {role} metric must be in {sorted(ALLOWED_INPUT_METRICS)} with a fields dict')
    return {'metric': metric, 'fields': dict(raw['fields'])}


def parsed_arm(raw, index: int) -> dict:
    if not isinstance(raw, dict) or set(raw) != ARM_KEYS:
        raise ValueError(f'{NAME} arms[{index}] is {{"aura", "stacks", "source"}}, not {raw!r}')
    return {'aura': positive_int(raw['aura'], f'arms[{index}].aura'),
            'stacks': positive_int(raw['stacks'], f'arms[{index}].stacks'),
            'source': non_empty_str(raw['source'], f'arms[{index}].source')}


def parsed_unrelated(raw) -> dict:
    if not isinstance(raw, dict) or set(raw) != UNRELATED_KEYS:
        raise ValueError(f'{NAME} unrelated is {{"metric", "fields", "aura", "stacks", "source"}}, not {raw!r}')
    stat = parsed_stat({'metric': raw['metric'], 'fields': raw['fields']}, 'unrelated')
    return {**stat, 'aura': positive_int(raw['aura'], 'unrelated.aura'),
            'stacks': positive_int(raw['stacks'], 'unrelated.stacks'),
            'source': non_empty_str(raw['source'], 'unrelated.source')}


def parse(raw) -> dict:
    if not isinstance(raw, dict) or set(raw) != KEYS:
        raise ValueError(f'{NAME} is {{"mode", "input", "arms", "unrelated", "wait_ms"}}, not {raw!r}')
    mode = raw['mode']
    if mode not in MODES:
        raise ValueError(f'{NAME} mode must be one of {MODES}, not {mode!r}')
    input_stat = parsed_stat(raw['input'], 'input')
    if not isinstance(raw['arms'], list) or len(raw['arms']) < MIN_ADDED_ARMS:
        raise ValueError(f'{NAME} needs at least {MIN_ADDED_ARMS} added arms (3+ stat values total)')
    arms = [parsed_arm(item, index) for index, item in enumerate(raw['arms'])]
    seen = [(arm['aura'], arm['stacks']) for arm in arms]
    if len(set(seen)) != len(seen):
        raise ValueError(f'{NAME} arms must have distinct (aura, stacks) pairs')
    unrelated = parsed_unrelated(raw['unrelated'])
    if (unrelated['metric'], unrelated['fields']) == (input_stat['metric'], input_stat['fields']):
        raise ValueError(f'{NAME} unrelated stat must differ from input stat')
    if unrelated['aura'] in {arm['aura'] for arm in arms}:
        raise ValueError(f'{NAME} unrelated aura {unrelated["aura"]} cannot also be used by an input arm')
    wait_ms = non_negative_int(raw['wait_ms'], 'wait_ms')
    return {'mode': mode, 'input': input_stat, 'arms': arms, 'unrelated': unrelated, 'wait_ms': wait_ms}


def check(spec, value):
    if value is None:
        return
    if any(found is not None for found in (spec.expected, spec.before_expected, spec.expected_gain,
                                           spec.expected_ratio, spec.after_at_least, spec.after_at_most,
                                           spec.after_expiry_expected, spec.phase_power)):
        raise ValueError(f'{spec.spell} {NAME} judges a strict direction only and forbids any expected figure, '
                         f'gain, ratio, bound or phase power')
    if spec.gate_timing != 'between' or spec.setup_only_after or spec.attack_swings or \
            spec.expiry_wait_ms is not None:
        raise ValueError(f'{spec.spell} {NAME} requires plain gate_timing="between" without setup_only_after, '
                         f'attack_swings or expiry_wait_ms')
    if value['mode'] == PASSIVE and not spec.cast_in_before:
        raise ValueError(f'{spec.spell} {NAME} passive mode requires cast_in_before=True')
    if value['mode'] == ACTIVE_RECAST and spec.cast_in_before:
        raise ValueError(f'{spec.spell} {NAME} active_recast mode requires cast_in_before=False')
    output = (spec.metric, dict(spec.fields))
    if output == (value['input']['metric'], value['input']['fields']):
        raise ValueError(f'{spec.spell} {NAME} cannot judge the input stat against itself')
    if output == (value['unrelated']['metric'], value['unrelated']['fields']):
        raise ValueError(f'{spec.spell} {NAME} cannot judge the unrelated stat against itself')


def stat_label(spec, kind: str, tag: str) -> str:
    return f'{spec.spell} {NAME} {kind} {tag}'


def read_label(spec, tag: str) -> str:
    from behaviours import metric_delta_label
    return metric_delta_label(spec, f'{NAME} {tag}')


def labels(spec, value: dict) -> dict:
    count = len(value['arms'])
    if value['mode'] == PASSIVE:
        return {
            'reads': {
                'control': [read_label(spec, f'control {i}') for i in range(1, count + 1)],
                'learned': [read_label(spec, f'learned {i}') for i in range(1, count + 1)],
                'control_unrelated': read_label(spec, 'control unrelated'),
                'learned_unrelated': read_label(spec, 'learned unrelated'),
            },
            'input': {
                'control': [stat_label(spec, 'input', f'control {i}') for i in range(count + 1)],
                'learned': [stat_label(spec, 'input', f'learned {i}') for i in range(count + 1)],
                'control_unrelated': stat_label(spec, 'input', 'control unrelated'),
                'learned_unrelated': stat_label(spec, 'input', 'learned unrelated'),
            },
            'unrelated': {
                'control_base': stat_label(spec, 'unrelated', 'control base'),
                'control_active': stat_label(spec, 'unrelated', 'control active'),
                'learned_base': stat_label(spec, 'unrelated', 'learned base'),
                'learned_active': stat_label(spec, 'unrelated', 'learned active'),
            },
        }
    return {
        'reads': {
            'levels': [read_label(spec, f'level {i}') for i in range(1, count + 1)],
            'unrelated': read_label(spec, 'unrelated'),
        },
        'input': {
            'levels': [stat_label(spec, 'input', f'level {i}') for i in range(count + 1)],
            'unrelated': stat_label(spec, 'input', 'unrelated'),
        },
        'unrelated': {
            'base': stat_label(spec, 'unrelated', 'base'),
            'active': stat_label(spec, 'unrelated', 'active'),
        },
    }


def fixtures(class_file: dict, spec, value: dict, scenario: dict):
    from behaviours import AFTER, BEFORE, CASTER, METRIC_DELTA_UNTIMED_WAIT_MS, metric_delta_label
    from hits import MAX_ACCELERATED_SCENARIO_MS, timed
    from profile import measurement
    names = labels(spec, value)
    steps = scenario['steps']
    before_label, after_label = metric_delta_label(spec, BEFORE), metric_delta_label(spec, AFTER)
    reading = next(step for step in steps if step.get('label') == after_label)
    wait_ms = value['wait_ms']

    def wait_step(label_text: str, ms: int) -> list[dict]:
        return [{'action': 'wait', 'label': label_text, 'ms': ms}] if ms > 0 else []

    def measure_stat(label_text: str, stat: dict) -> dict:
        return measurement(label_text, CASTER, stat['metric'], **stat['fields'])

    def set_aura(spell: int, stacks: int) -> dict:
        return {'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': stacks}

    if value['mode'] == PASSIVE:
        def phase_block(phase: str) -> list[dict]:
            out = [measure_stat(names['input'][phase][0], value['input']),
                   measure_stat(names['unrelated'][f'{phase}_base'], value['unrelated'])]
            for idx, arm in enumerate(value['arms'], 1):
                out += [set_aura(arm['aura'], arm['stacks']), *wait_step(f'{NAME} settle', wait_ms),
                        measure_stat(names['input'][phase][idx], value['input']),
                        {**reading, 'label': names['reads'][phase][idx - 1]},
                        set_aura(arm['aura'], 0), *wait_step(f'{NAME} clear', wait_ms)]
            unrelated = value['unrelated']
            out += [set_aura(unrelated['aura'], unrelated['stacks']), *wait_step(f'{NAME} unrelated settle', wait_ms),
                    measure_stat(names['unrelated'][f'{phase}_active'], unrelated),
                    measure_stat(names['input'][f'{phase}_unrelated'], value['input']),
                    {**reading, 'label': names['reads'][f'{phase}_unrelated']},
                    set_aura(unrelated['aura'], 0), *wait_step(f'{NAME} unrelated clear', wait_ms)]
            return out

        added = {before_label: phase_block('control'), after_label: phase_block('learned')}
        scenario['steps'] = [step for original in steps for step in (original, *added.get(original.get('label'), ()))]
    else:
        after_idx = next(idx for idx, step in enumerate(steps) if step.get('label') == after_label)
        start_idx = max(idx for idx, step in enumerate(steps[:after_idx])
                        if step.get('label') == EXPIRE_WAIT_LABEL) + 1
        cast_block = steps[start_idx:after_idx]
        prefix_reads = [measure_stat(names['input']['levels'][0], value['input']),
                        measure_stat(names['unrelated']['base'], value['unrelated'])]
        extra = []
        for idx, arm in enumerate(value['arms'], 1):
            extra += [*wait_step(f'{NAME} expire', spec.expire_ms),
                      set_aura(arm['aura'], arm['stacks']), *wait_step(f'{NAME} settle', wait_ms),
                      measure_stat(names['input']['levels'][idx], value['input']),
                      *cast_block, {**reading, 'label': names['reads']['levels'][idx - 1]},
                      set_aura(arm['aura'], 0)]
        unrelated = value['unrelated']
        extra += [*wait_step(f'{NAME} expire', spec.expire_ms),
                  set_aura(unrelated['aura'], unrelated['stacks']), *wait_step(f'{NAME} unrelated settle', wait_ms),
                  measure_stat(names['unrelated']['active'], unrelated),
                  measure_stat(names['input']['unrelated'], value['input']),
                  *cast_block, {**reading, 'label': names['reads']['unrelated']},
                  set_aura(unrelated['aura'], 0)]
        scenario['steps'] = (steps[:start_idx] + prefix_reads + steps[start_idx:after_idx + 1]
                             + extra + steps[after_idx + 1:])

    waited = sum(step['ms'] for step in scenario['steps'] if step['action'] == 'wait')
    if waited > METRIC_DELTA_UNTIMED_WAIT_MS:
        scenario.pop('timeout_ms', None)
        timed(scenario, waited, MAX_ACCELERATED_SCENARIO_MS)

    arm_desc = ', '.join(f'{arm["aura"]} x{arm["stacks"]} ({arm["source"]})' for arm in value['arms'])
    unrel = value['unrelated']
    scenario['contract'] += (
        f' Stat arms ({value["mode"]}, D-38): varies {value["input"]["metric"]} {value["input"]["fields"]} over '
        f'{1 + len(value["arms"])} values (baseline plus [{arm_desc}]), with an unrelated-stat control on '
        f'{unrel["metric"]} {unrel["fields"]} via {unrel["aura"]} x{unrel["stacks"]} ({unrel["source"]}). Every '
        f'input and unrelated stat value is read back (fixture failures void as unmeasured). Judged strictly '
        f'monotonic across all {1 + len(value["arms"])} stat values and unchanged under the unrelated stat, with no '
        f'slope, ratio or expected figure.')


def model(spec, value: dict) -> dict:
    from behaviours import AFTER, BEFORE, metric_delta_label
    from compare import METRIC_DELTA_FLOAT_TOLERANCE
    tolerance = METRIC_DELTA_FLOAT_TOLERANCE if spec.tolerance is None else spec.tolerance
    return {NAME: {**value, **labels(spec, value), 'metric': spec.metric, 'tolerance': tolerance,
                   'before_label': metric_delta_label(spec, BEFORE), 'after_label': metric_delta_label(spec, AFTER)}}


def read_values(run, label_list: list[str]) -> tuple[list[float], str | None]:
    from compare import missing_measurement
    out = []
    for label in label_list:
        val = run.values.get(label)
        if val is None:
            return [], missing_measurement(run, label)
        out.append(float(val))
    return out, None


def strictly_rising(values: list[float], tol: float) -> bool:
    return all(high > low + tol for low, high in zip(values, values[1:]))


def verdict(verdict, run, recorded: dict):
    if verdict.status == 'unmeasured':
        return verdict
    tolerance = float(recorded['tolerance'])
    mode = recorded['mode']
    if mode == PASSIVE:
        ctrl_out, missing = read_values(run, [recorded['before_label'], *recorded['reads']['control'],
                                              recorded['reads']['control_unrelated']])
        if missing:
            return replace(verdict, status='unmeasured', explanation=missing)
        lrn_out, missing = read_values(run, [recorded['after_label'], *recorded['reads']['learned'],
                                             recorded['reads']['learned_unrelated']])
        if missing:
            return replace(verdict, status='unmeasured', explanation=missing)
        ctrl_in, missing = read_values(run, [*recorded['input']['control'], recorded['input']['control_unrelated']])
        if missing:
            return replace(verdict, status='unmeasured', explanation=missing)
        lrn_in, missing = read_values(run, [*recorded['input']['learned'], recorded['input']['learned_unrelated']])
        if missing:
            return replace(verdict, status='unmeasured', explanation=missing)
        unrel_vals, missing = read_values(run, [recorded['unrelated']['control_base'],
                                                recorded['unrelated']['control_active'],
                                                recorded['unrelated']['learned_base'],
                                                recorded['unrelated']['learned_active']])
        if missing:
            return replace(verdict, status='unmeasured', explanation=missing)
        ctrl_levels, ctrl_in_unrel = ctrl_in[:-1], ctrl_in[-1]
        lrn_levels, lrn_in_unrel = lrn_in[:-1], lrn_in[-1]
        c_ub, c_ua, l_ub, l_ua = unrel_vals
        if not strictly_rising(ctrl_levels, INPUT_TOLERANCE) or \
                any(abs(a - b) > INPUT_TOLERANCE for a, b in zip(ctrl_levels, lrn_levels)):
            return replace(verdict, status='unmeasured',
                           explanation=f'{NAME}: input stat levels did not rise strictly and match across arms '
                                       f'(control={ctrl_levels}, learned={lrn_levels})')
        if c_ua - c_ub <= INPUT_TOLERANCE or l_ua - l_ub <= INPUT_TOLERANCE or \
                abs((l_ua - l_ub) - (c_ua - c_ub)) > INPUT_TOLERANCE or \
                abs(ctrl_in_unrel - ctrl_levels[0]) > INPUT_TOLERANCE or \
                abs(lrn_in_unrel - lrn_levels[0]) > INPUT_TOLERANCE:
            return replace(verdict, status='unmeasured',
                           explanation=f'{NAME}: unrelated stat control fixture invalid (unrelated '
                                       f'control {c_ub:g}->{c_ua:g}, learned {l_ub:g}->{l_ua:g}; input during '
                                       f'unrelated control={ctrl_in_unrel:g} vs {ctrl_levels[0]:g}, '
                                       f'learned={lrn_in_unrel:g} vs {lrn_levels[0]:g})')
        gains = [lrn - ctrl for lrn, ctrl in zip(lrn_out[:-1], ctrl_out[:-1])]
        unrel_gain = lrn_out[-1] - ctrl_out[-1]
        rising = gains[0] >= -tolerance and strictly_rising(gains, tolerance)
        stable = abs(unrel_gain - gains[0]) <= tolerance
        ok = rising and stable
        detail = {**(verdict.detail or {}), 'mode': mode, 'input_levels': ctrl_levels, 'arm_gains': gains,
                  'unrelated_gain': unrel_gain, 'unrelated_stat': [c_ub, c_ua, l_ub, l_ua]}
        return replace(verdict, status='ok' if ok else 'alert', measured=gains[-1], expected=None, low=None, high=None,
                       detail=detail,
                       explanation=f'{NAME} ({mode}, {recorded["metric"]}): input {ctrl_levels} -> learned gains '
                                   f'{gains} (strictly rising: {rising}); unrelated stat {c_ub:g}->{c_ua:g} -> '
                                   f'learned gain {unrel_gain:g} vs baseline {gains[0]:g} (unchanged within '
                                   f'{tolerance:g}: {stable}); direction only, no figure asserted')

    out_vals, missing = read_values(run, [recorded['after_label'], *recorded['reads']['levels'],
                                          recorded['reads']['unrelated']])
    if missing:
        return replace(verdict, status='unmeasured', explanation=missing)
    in_vals, missing = read_values(run, [*recorded['input']['levels'], recorded['input']['unrelated']])
    if missing:
        return replace(verdict, status='unmeasured', explanation=missing)
    unrel_vals, missing = read_values(run, [recorded['unrelated']['base'], recorded['unrelated']['active']])
    if missing:
        return replace(verdict, status='unmeasured', explanation=missing)
    levels, in_unrel = in_vals[:-1], in_vals[-1]
    u_base, u_active = unrel_vals
    if not strictly_rising(levels, INPUT_TOLERANCE):
        return replace(verdict, status='unmeasured',
                       explanation=f'{NAME}: input stat levels {levels} did not rise strictly')
    if u_active - u_base <= INPUT_TOLERANCE or abs(in_unrel - levels[0]) > INPUT_TOLERANCE:
        return replace(verdict, status='unmeasured',
                       explanation=f'{NAME}: unrelated stat control fixture invalid (unrelated {u_base:g}->'
                                   f'{u_active:g}, input during unrelated {in_unrel:g} vs {levels[0]:g})')
    series, unrel_out = out_vals[:-1], out_vals[-1]
    rising = series[0] >= -tolerance and strictly_rising(series, tolerance)
    stable = abs(unrel_out - series[0]) <= tolerance
    ok = rising and stable
    detail = {**(verdict.detail or {}), 'mode': mode, 'input_levels': levels, 'arm_values': series,
              'unrelated_value': unrel_out, 'unrelated_stat': [u_base, u_active]}
    return replace(verdict, status='ok' if ok else 'alert', measured=series[-1], expected=None, low=None, high=None,
                   detail=detail,
                   explanation=f'{NAME} ({mode}, {recorded["metric"]}): input {levels} -> output {series} '
                               f'(strictly rising: {rising}); unrelated stat {u_base:g}->{u_active:g} -> '
                               f'output {unrel_out:g} vs baseline {series[0]:g} (unchanged within {tolerance:g}: '
                               f'{stable}); direction only, no figure asserted')
