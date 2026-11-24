from dataclasses import dataclass, replace

NAME = 'uncritical_casts'
ORDER = 0
MAX_CASTS = 10
SETTLE_LABEL = 'let the first effect fully expire'
READS = ('critical', 'landed')


@dataclass(frozen=True)
class UncriticalCasts:
    casts: int
    min_uncritical: int


def parse(raw) -> UncriticalCasts:
    if not isinstance(raw, dict) or set(raw) != {'casts', 'min_uncritical'} \
            or any(isinstance(raw[key], bool) or not isinstance(raw[key], int) for key in raw):
        raise ValueError(f'uncritical_casts is {{"casts": count, "min_uncritical": count}}, not {raw!r}')
    value = UncriticalCasts(raw['casts'], raw['min_uncritical'])
    if not 2 <= value.casts <= MAX_CASTS or not 1 <= value.min_uncritical <= value.casts:
        raise ValueError(f'uncritical_casts needs 2 to {MAX_CASTS} treatment casts and a minimum of 1 to that many '
                         f'non-critical ones, not {raw!r}')
    return value


def check(spec, value):
    if value is None:
        return
    from values import TARGET
    if (spec.target != TARGET or spec.gate_timing != 'between' or spec.setup_only_after or spec.attack_swings
            or not spec.cast_in_before or spec.trigger_only_after or spec.trigger_item is not None
            or spec.strike is not None or spec.force_crit is not None or spec.forced_chance is not None
            or spec.game_time is not None or spec.expiry_wait_ms is not None):
        raise ValueError(f'{spec.spell} uncritical_casts repeats a plain treatment cast at the dummy, learned between '
                         f'the phases and cast in both, without a forced critical strike, strike, item, forced '
                         f'chance, game time or expiry read')


def after_labels(spec, value: UncriticalCasts) -> list[str]:
    from behaviours import metric_delta_label
    after = metric_delta_label(spec, 'after')
    return [after, *(f'{after} {index}' for index in range(2, value.casts + 1))]


def hit_labels(spec, value: UncriticalCasts) -> dict[str, list[str]]:
    from behaviours import metric_delta_label
    base = f'{metric_delta_label(spec, "after")} {NAME}'
    return {read: [f'{base} {index} {read}' for index in range(value.casts + 1)] for read in READS}


def hit_reads(spec, labels: dict[str, list[str]], index: int) -> list[dict]:
    from profile import CASTER, measurement
    fields = {'spell': spec.trigger_spell, 'target': spec.target}
    return [measurement(labels['critical'][index], CASTER, 'spell_damage_count', **fields, critical=True),
            measurement(labels['landed'][index], CASTER, 'spell_damage_count', **fields, critical=False)]


def relabeled(step: dict, index: int) -> dict:
    return {**step, 'label': f'{step["label"]} {index}'} if 'label' in step else dict(step)


def fixtures(class_file: dict, spec, value: UncriticalCasts, scenario: dict):
    from behaviours import METRIC_DELTA_UNTIMED_WAIT_MS, metric_delta_label
    steps = scenario['steps']
    labels = [step.get('label') for step in steps]
    before, after = (labels.index(metric_delta_label(spec, moment)) for moment in ('before', 'after'))
    settle = max(index for index, label in enumerate(labels[:after]) if label == SETTLE_LABEL)
    block, reads, names = steps[settle + 1:after], hit_labels(spec, value), after_labels(spec, value)
    repeated = [step for index in range(2, value.casts + 1) for step in (
        *(relabeled(step, index) for step in block), {**steps[after], 'label': names[index - 1]},
        *hit_reads(spec, reads, index))]
    scenario['steps'] = (steps[:before + 1] + hit_reads(spec, reads, 0) + steps[before + 1:after + 1]
                         + hit_reads(spec, reads, 1) + repeated + steps[after + 1:])
    waited = sum(step['ms'] for step in scenario['steps'] if step['action'] == 'wait')
    if waited > METRIC_DELTA_UNTIMED_WAIT_MS or 'timeout_ms' in scenario:
        raise ValueError(f'{spec.spell} uncritical_casts waits {waited} ms, beyond an untimed metric delta')
    scenario['contract'] += (
        f' Uncritical casts: the treatment cast of {spec.trigger_spell} is made {value.casts} times, each with the '
        f'phase fixtures set again and followed by its own reading; right after the before reading and after each '
        f'treatment reading the caster\'s critical and non-critical damage events of {spec.trigger_spell} at the '
        f'{spec.target} are counted. A treatment cast whose recorded damage event is critical, or that lands no '
        f'non-critical hit, is dropped; every remaining cast is judged on its own reading against the before '
        f'reading, and fewer than {value.min_uncritical} remaining casts leave the entry unmeasured.')


def judged_model(spec) -> dict:
    from behaviours import metric_delta_label
    stated = {'tolerance': spec.tolerance, 'after_at_least': spec.after_at_least, 'after_at_most': spec.after_at_most,
              'expected_gain': spec.expected_gain, 'expected_ratio': spec.expected_ratio}
    return {'before_label': metric_delta_label(spec, 'before'), 'after_label': metric_delta_label(spec, 'after'),
            'expected': spec.expected, 'before_expected': spec.before_expected, 'metric': spec.metric,
            **{key: value for key, value in stated.items() if value is not None}}


def model(spec, value: UncriticalCasts) -> dict:
    return {NAME: {'casts': value.casts, 'min_uncritical': value.min_uncritical,
                   'after_labels': after_labels(spec, value), **hit_labels(spec, value),
                   'judged': judged_model(spec)}}


def verdict(verdict, run, recorded: dict):
    from compare import judged_metric_delta, missing_measurement
    from metric_delta_options import OptionRun
    labels = [*recorded['after_labels'], *recorded['critical'], *recorded['landed']]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(verdict, status='unmeasured', explanation=missing_measurement(run, missing))
    counts = {read: [float(run.values[label]) for label in recorded[read]] for read in READS}
    after_label = recorded['after_labels'][0]
    kept, notes = [], []
    for index, label in enumerate(recorded['after_labels'], 1):
        critical = counts['critical'][index] - counts['critical'][index - 1]
        landed = counts['landed'][index] - counts['landed'][index - 1]
        if critical:
            notes.append(f'cast {index} dropped ({critical:g} critical damage event)')
        elif landed < 1:
            notes.append(f'cast {index} dropped (no landed non-critical hit)')
        else:
            judged = judged_metric_delta(verdict, OptionRun(run, {**run.values, after_label: run.values[label]}),
                                         recorded['judged'])
            kept.append((index, judged))
            notes.append(f'cast {index} {judged.status}: {judged.explanation}')
    text = f'uncritical casts: {"; ".join(notes)}'
    if len(kept) < recorded['min_uncritical']:
        return replace(verdict, status='unmeasured',
                       explanation=f'{text}; {len(kept)} non-critical casts, below the stated minimum of '
                                   f'{recorded["min_uncritical"]}')
    failed = next((judged for _, judged in kept if judged.status != 'ok'), None)
    return replace(failed or kept[-1][1], explanation=f'{text}; {len(kept)} non-critical casts judged '
                                                      f'(minimum {recorded["min_uncritical"]})')
