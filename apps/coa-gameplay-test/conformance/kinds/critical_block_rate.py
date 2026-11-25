from dataclasses import dataclass, replace
from functools import cache
import math
from pathlib import Path
from statistics import NormalDist

from behaviours import (AVOIDING_ENGAGE_MS, BEHAVIOUR_METRIC_DELTA, STRIKER_DISTANCE, STRIKER_HEALTH,
                        behaviour_entry, prose_rule, waited_ms)
from compare import Run, Verdict, banded_rate, describe_failures, failure_reasons, missing_measurement, rate_judgement
from hits import MAX_ACCELERATED_SCENARIO_MS, timed
from procs import Z_99, rate_band, wilson_interval
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, MAX_SCENARIO_STEPS, armed_for, dataset

KIND = 'critical_block_rate'
ORDER = 59
COUNT_METRIC = 'melee_blocks_taken_count'
TOTAL_METRIC = 'melee_blocks_taken_total'
METRIC_EVIDENCE = {COUNT_METRIC: 'event', TOTAL_METRIC: 'event'}
CONTROL, TREATMENT = 'control', 'treatment'
BLOCK_SPELL = 107
PAUSE_AURA = 56
MAX_STRIKERS = 10
DEFAULT_SHIELD_SLOT = 16
STRIKE_HEALTH = 100000
CONTROL_MIN_TRIALS = 50
DEFAULT_RESIDUAL = 1e-3
PAIR_RUNS = 2
TAIL_SDS = 14
BLOCK_KINDS = ('all', 'normal', 'critical', 'other', 'full')
TOTAL_KINDS = ('all', 'normal', 'critical')
FIELDS = frozenset({
    'spell', 'name', 'kind', 'variant', 'label_suffix', 'quote', 'gate_spell', 'expected_pct',
    'shield_item', 'shield_slot', 'striker_entry', 'strikers', 'striker_auras', 'window_ms',
    'control_windows', 'treatment_windows', 'parts', 'residual', 'phase_auras', 'setup_wait_ms',
    'after_setup_stacks', 'learn', 'observe_source'})


@dataclass(frozen=True)
class CriticalBlockSpec:
    spell: int
    name: str
    quote: str
    gate_spell: int
    label_suffix: str
    expected_pct: float
    shield_item: int
    shield_slot: int
    striker_entry: int
    strikers: int
    striker_auras: tuple[int, ...]
    window_ms: int
    control_windows: int
    treatment_windows: int
    parts: int
    residual: float
    phase_auras: tuple[tuple[int, int, str, str], ...]
    setup_wait_ms: int
    after_setup_stacks: tuple[tuple[int, int], ...]
    learn: tuple[int, ...]


def residual_z(residual: float) -> float:
    return NormalDist().inv_cdf(1 - residual / 2)


def band_trials(rate: float, residual: float) -> int:
    return math.ceil(rate * (1 - rate) * ((Z_99 + residual_z(residual)) / rate_band(rate)) ** 2)


def binomial_pmf(events: int, trials: int, rate: float) -> float:
    return math.exp(math.lgamma(trials + 1) - math.lgamma(events + 1) - math.lgamma(trials - events + 1)
                    + events * math.log(rate) + (trials - events) * math.log(1 - rate))


def judged_rate(crits: int, trials: int, minimum: int, expected: float) -> tuple[str, float | None,
                                                                                 float | None, str]:
    if trials <= 0:
        return 'unmeasured', None, None, 'no blocked melee trial'
    if trials < minimum:
        low, high = wilson_interval(crits, trials)
        return 'insufficient_trials', low, high, (f'rate {crits / trials:.4f} [{low:.4f}, {high:.4f}]: '
                                                  f'fewer than the {minimum} trials the rate needs')
    status, low, high, why = rate_judgement(crits, trials, minimum, expected)
    if low is not None:
        return banded_rate(status, low, high, expected, why)
    return status, low, high, why


@cache
def exact_false_fail(trials: int, rate: float) -> float:
    spread = TAIL_SDS * math.sqrt(trials * rate * (1 - rate))
    low, high = max(0, int(trials * rate - spread)), min(trials, int(trials * rate + spread))
    return sum(binomial_pmf(events, trials, rate) for events in range(low, high + 1)
               if judged_rate(events, trials, trials, rate)[0] != 'ok')


@cache
def exact_false_pass(trials: int, true_rate: float, expected_rate: float) -> float:
    if true_rate <= 0.0:
        return 1.0 if judged_rate(0, trials, trials, expected_rate)[0] == 'ok' else 0.0
    if true_rate >= 1.0:
        return 1.0 if judged_rate(trials, trials, trials, expected_rate)[0] == 'ok' else 0.0
    band = rate_band(expected_rate)
    low = max(0, int(math.floor(trials * (expected_rate - band))) - 2)
    high = min(trials, int(math.ceil(trials * (expected_rate + band))) + 2)
    return sum(binomial_pmf(events, trials, true_rate) for events in range(low, high + 1)
               if judged_rate(events, trials, trials, expected_rate)[0] == 'ok')


@cache
def minimum_treatment_trials(rate: float, residual: float) -> int:
    ff_budget = residual / PAIR_RUNS
    trials = max(CONTROL_MIN_TRIALS, band_trials(rate, ff_budget))
    while exact_false_fail(trials, rate) > ff_budget or exact_false_pass(trials, 0.0, rate) ** PAIR_RUNS > residual:
        trials += 1
    return trials


def minimum_control_trials(rate: float, residual: float) -> int:
    return max(CONTROL_MIN_TRIALS, math.ceil(math.log(math.sqrt(residual)) / math.log(1.0 - rate)))


def parse_phase_auras(raw, spell: int) -> tuple[tuple[int, int, str, str], ...]:
    if not raw:
        return ()
    parsed = []
    for item in raw:
        if not isinstance(item, (list, tuple)) or len(item) != 4:
            raise ValueError(f'{spell} {KIND} phase_auras entries are [spell, stacks, on, by], not {item!r}')
        aura_id, stacks, target, caster = item
        if isinstance(aura_id, bool) or not isinstance(aura_id, int) or aura_id < 1:
            raise ValueError(f'{spell} {KIND} phase_auras spell must be positive int')
        if isinstance(stacks, bool) or not isinstance(stacks, int) or stacks < 0:
            raise ValueError(f'{spell} {KIND} phase_auras stacks must be non-negative int')
        if target != CASTER or caster != CASTER:
            raise ValueError(f'{spell} {KIND} phase_auras apply on caster by caster')
        parsed.append((aura_id, stacks, target, caster))
    return tuple(parsed)


def parse_after_setup_stacks(raw, spell: int) -> tuple[tuple[int, int], ...]:
    if not raw:
        return ()
    parsed = []
    for item in raw:
        if not isinstance(item, dict) or not {'spell', 'stacks'} <= set(item) <= {'spell', 'actor', 'stacks'}:
            raise ValueError(f'{spell} {KIND} after_setup_stacks entry invalid: {item!r}')
        if item.get('actor', CASTER) != CASTER:
            raise ValueError(f'{spell} {KIND} after_setup_stacks checks caster only')
        aura_id, stacks = item['spell'], item['stacks']
        if isinstance(aura_id, bool) or not isinstance(aura_id, int) or aura_id < 1:
            raise ValueError(f'{spell} {KIND} after_setup_stacks spell must be positive int')
        if isinstance(stacks, bool) or not isinstance(stacks, int) or stacks < 0:
            raise ValueError(f'{spell} {KIND} after_setup_stacks stacks must be non-negative int')
        parsed.append((aura_id, stacks))
    return tuple(parsed)


def critical_block_spec(entry: dict) -> CriticalBlockSpec:
    unknown = set(entry) - FIELDS
    if unknown:
        raise ValueError(f'{entry["spell"]} {KIND} has unknown fields {sorted(unknown)}')
    spell = int(entry['spell'])
    gate_spell = int(entry.get('gate_spell', spell))
    expected_pct = entry['expected_pct']
    if isinstance(expected_pct, bool) or not isinstance(expected_pct, (int, float)) or not 0 < expected_pct < 100:
        raise ValueError(f'{spell} {KIND} expected_pct must lie strictly between 0 and 100')
    for field_name in ('shield_item', 'striker_entry', 'strikers', 'window_ms', 'control_windows',
                       'treatment_windows', 'parts'):
        value = entry[field_name]
        if isinstance(value, bool) or not isinstance(value, int) or value < 1:
            raise ValueError(f'{spell} {KIND} {field_name} must be a positive integer')
    if not 1 <= entry['strikers'] <= MAX_STRIKERS:
        raise ValueError(f'{spell} {KIND} strikers must be between 1 and {MAX_STRIKERS}')
    shield_slot = entry.get('shield_slot', DEFAULT_SHIELD_SLOT)
    if isinstance(shield_slot, bool) or not isinstance(shield_slot, int) or shield_slot != DEFAULT_SHIELD_SLOT:
        raise ValueError(f'{spell} {KIND} shield_slot must be {DEFAULT_SHIELD_SLOT}')
    auras_raw = entry.get('striker_auras', ())
    if not isinstance(auras_raw, list) or any(isinstance(a, bool) or not isinstance(a, int) or a < 1
                                              for a in auras_raw):
        raise ValueError(f'{spell} {KIND} striker_auras must be a list of positive spell ids')
    residual = float(entry.get('residual', DEFAULT_RESIDUAL))
    if not 0 < residual < 1:
        raise ValueError(f'{spell} {KIND} residual must lie strictly between 0 and 1')
    setup_wait_ms = entry.get('setup_wait_ms', 0)
    if isinstance(setup_wait_ms, bool) or not isinstance(setup_wait_ms, int) or setup_wait_ms < 0:
        raise ValueError(f'{spell} {KIND} setup_wait_ms must be non-negative int')
    learn_raw = entry.get('learn', ())
    if not isinstance(learn_raw, (list, tuple)) or any(isinstance(s, bool) or not isinstance(s, int) or s < 1
                                                       for s in learn_raw):
        raise ValueError(f'{spell} {KIND} learn must be a list of positive spell ids')
    learn = tuple(learn_raw)
    if gate_spell in learn:
        raise ValueError(f'{spell} {KIND} learns gate_spell {gate_spell} only between control and treatment')
    return CriticalBlockSpec(
        spell, entry['name'], entry['quote'], gate_spell, entry.get('label_suffix', KIND),
        float(expected_pct), int(entry['shield_item']), shield_slot, int(entry['striker_entry']),
        int(entry['strikers']), tuple(auras_raw), int(entry['window_ms']), int(entry['control_windows']),
        int(entry['treatment_windows']), int(entry['parts']), residual,
        parse_phase_auras(entry.get('phase_auras'), spell), setup_wait_ms,
        parse_after_setup_stacks(entry.get('after_setup_stacks'), spell), learn)


def check_label(spec: CriticalBlockSpec) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}'


def striker_ids(count: int) -> list[str]:
    return ['striker' if index == 1 else f'striker_{index}' for index in range(1, count + 1)]


def pause_steps(strikers: list[str], on: bool) -> list[dict]:
    stacks = 1 if on else 0
    return [{'action': 'set_aura', 'actor': CASTER, 'target': sid, 'caster': sid, 'spell': PAUSE_AURA,
             'stacks': stacks} for sid in strikers]


def block_reads(prefix: str, arm: str, moment: str) -> tuple[list[dict], dict[str, str]]:
    names = {'block_value': f'{prefix} {arm} {moment} block_value'}
    steps = [measurement(names['block_value'], CASTER, 'block_value')]
    for kind in BLOCK_KINDS:
        key = f'count_{kind}'
        names[key] = f'{prefix} {arm} {moment} {key}'
        steps.append(measurement(names[key], CASTER, COUNT_METRIC, block_kind=kind))
    for kind in TOTAL_KINDS:
        key = f'total_{kind}'
        names[key] = f'{prefix} {arm} {moment} {key}'
        steps.append(measurement(names[key], CASTER, TOTAL_METRIC, block_kind=kind))
    return steps, names


def critical_block_scenario(class_file: dict, spec: CriticalBlockSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, spec.expected_pct)
    class_file = armed_for(class_file, records, spec.spell)
    strikers = striker_ids(spec.strikers)
    prefix = check_label(spec)

    def arm_steps(arm: str, windows: int) -> tuple[list[dict], dict]:
        steps = [{'action': 'set_aura', 'actor': CASTER, 'spell': aura_id, 'stacks': stacks}
                 for aura_id, stacks, _, _ in spec.phase_auras]
        if spec.setup_wait_ms:
            steps.append({'action': 'wait', 'label': f'{arm} setup settle', 'ms': spec.setup_wait_ms})
        shield_label = f'{prefix} {arm} shield'
        steps.append(measurement(shield_label, CASTER, 'equipped_item', slot=spec.shield_slot))
        stack_reads = []
        for aura_id, expected_stacks in spec.after_setup_stacks:
            label_name = f'{prefix} {arm} stack {aura_id}'
            steps.append(measurement(label_name, CASTER, 'aura_stacks', spell=aura_id))
            stack_reads.append({'spell': aura_id, 'expected': expected_stacks, 'label': label_name})
        start_steps, start_names = block_reads(prefix, arm, 'start')
        steps += start_steps
        for window in range(1, windows + 1):
            steps += [{'action': 'set_health', 'actor': CASTER, 'value': STRIKE_HEALTH, 'maximum': STRIKE_HEALTH},
                      {'action': 'set_combat_avoidance', 'actor': CASTER, 'dodge': 0, 'parry': 0, 'block': 100},
                      *pause_steps(strikers, False),
                      {'action': 'wait', 'label': f'{arm} window {window}', 'ms': spec.window_ms},
                      *pause_steps(strikers, True)]
        end_steps, end_names = block_reads(prefix, arm, 'end')
        steps += end_steps
        return steps, {'shield': shield_label, 'stacks': stack_reads, 'start': start_names, 'end': end_names}

    learn_spells = tuple(dict.fromkeys((BLOCK_SPELL, *spec.learn)))
    engage = [{'action': 'set_aura', 'actor': CASTER, 'target': sid, 'caster': sid, 'spell': aura_id, 'stacks': 1}
              for sid in strikers for aura_id in spec.striker_auras]
    for sid in strikers:
        engage += [{'action': 'set_health', 'actor': CASTER, 'value': STRIKE_HEALTH, 'maximum': STRIKE_HEALTH},
                   {'action': 'set_combat_avoidance', 'actor': CASTER, 'dodge': 0, 'parry': 0, 'block': 100},
                   {'action': 'attack', 'actor': CASTER, 'target': sid},
                   {'action': 'wait', 'label': f'engage {sid}', 'ms': AVOIDING_ENGAGE_MS},
                   {'action': 'stop_attack', 'actor': CASTER}]
    engage += pause_steps(strikers, True)

    ctrl_steps, ctrl_model = arm_steps(CONTROL, spec.control_windows)
    treat_steps, treat_model = arm_steps(TREATMENT, spec.treatment_windows)
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell_id} for spell_id in learn_spells]
             + engage
             + ctrl_steps
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.gate_spell}]
             + treat_steps)
    if len(steps) > MAX_SCENARIO_STEPS:
        raise ValueError(f'{spec.spell} {KIND} takes {len(steps)} steps, above {MAX_SCENARIO_STEPS}: '
                         f'reduce windows per part and add parts')

    rate = spec.expected_pct / 100.0
    min_treat = minimum_treatment_trials(rate, spec.residual)
    min_ctrl = minimum_control_trials(rate, spec.residual)
    ff_pair = PAIR_RUNS * exact_false_fail(min_treat, rate)
    fp_ctrl_pair = ((1.0 - rate) ** min_ctrl) ** PAIR_RUNS
    fp_treat_pair = exact_false_pass(min_treat, 0.0, rate) ** PAIR_RUNS
    creatures = [{'id': sid, 'owner': CASTER, 'entry': spec.striker_entry, 'level': class_file['level'],
                  'health': STRIKER_HEALTH, 'distance': STRIKER_DISTANCE, 'reaction': 2, 'stationary': True}
                 for sid in strikers]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour critical block rate',
        'contract': (f'Incoming melee critical-block rate and exact 2x blocked-amount proof for {spec.gate_spell} '
                     f'(expected {spec.expected_pct:g}%, G-20 band +-{rate_band(rate) * 100:g} pts). Shield '
                     f'{spec.shield_item} verified in slot {spec.shield_slot}; {spec.strikers} stationary striker(s) '
                     f'of entry {spec.striker_entry} (auras {list(spec.striker_auras)}) hit caster with dodge=0, '
                     f'parry=0, block=100, paused by Stun {PAUSE_AURA} during setup and reads. Control runs '
                     f'{spec.control_windows} window(s) of {spec.window_ms} ms before learning {spec.gate_spell} '
                     f'(must record 0 critical blocks over >= {min_ctrl} pooled blocks); treatment runs '
                     f'{spec.treatment_windows} window(s)/part across {spec.parts} part(s) after a real learn '
                     f'(>= {min_treat} pooled blocks). Every incoming block must be a partial block with amount '
                     f'strictly equal to block_value B (normal) or 2*B (critical); any clamped full block voids the '
                     f'run as unmeasured and any non-1x/2x block amount alerts. Residual per counted pair of '
                     f'{PAIR_RUNS} runs (exact binomial at minimum sample): conformant false-fail {ff_pair:.1e}, '
                     f'control false-pass {fp_ctrl_pair:.1e}, treatment false-pass at 0% {fp_treat_pair:.1e} '
                     f'(target <= {spec.residual:.1e}).'),
        'players': [player_fixture(class_file)],
        'creatures': creatures,
        'steps': steps}
    model = {
        'kind': KIND, 'metric': COUNT_METRIC, 'quote': entry.quote, 'prefix': prefix,
        'expected_rate': rate, 'shield_item': spec.shield_item,
        'min_control_trials': min_ctrl, 'min_treatment_trials': min_treat,
        'parts': spec.parts, 'arms': {CONTROL: ctrl_model, TREATMENT: treat_model}}
    expectation = Expectation(prefix, BEHAVIOUR_METRIC_DELTA, spec.spell, spec.gate_spell, None,
                              f'{rate:.4f}', prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps), MAX_ACCELERATED_SCENARIO_MS), [expectation]


def extract_arm(run: Run, arm_model: dict, shield_item: int, arm_name: str) -> tuple[dict | None, str | None,
                                                                                      str | None]:
    shield_raw = run.values.get(arm_model['shield'])
    if shield_raw is None:
        return None, 'unmeasured', missing_measurement(run, arm_model['shield'])
    if int(round(float(shield_raw))) != shield_item:
        return None, 'unmeasured', f'{arm_name} shield slot read {shield_raw:g}, expected {shield_item}'
    for stack in arm_model['stacks']:
        val = run.values.get(stack['label'])
        if val is None:
            return None, 'unmeasured', missing_measurement(run, stack['label'])
        if int(round(float(val))) != int(stack['expected']):
            return None, 'unmeasured', (f'{arm_name} aura {stack["spell"]} stacks read {val:g}, expected '
                                        f'{stack["expected"]}')
    start_vals, end_vals = {}, {}
    for moment, bucket in (('start', start_vals), ('end', end_vals)):
        for key, label_name in arm_model[moment].items():
            raw = run.values.get(label_name)
            if raw is None:
                return None, 'unmeasured', missing_measurement(run, label_name)
            bucket[key] = int(round(float(raw)))
    b_start, b_end = start_vals['block_value'], end_vals['block_value']
    if b_start <= 0 or b_start != b_end:
        return None, 'unmeasured', f'{arm_name} block_value invalid or drifted ({b_start} -> {b_end})'
    deltas = {key: end_vals[key] - start_vals[key] for key in start_vals if key != 'block_value'}
    if any(value < 0 for value in deltas.values()):
        return None, 'unmeasured', f'{arm_name} negative block counter delta: {deltas}'
    if deltas['count_full'] > 0:
        return None, 'unmeasured', (f'{arm_name} saw {deltas["count_full"]} clamped full block(s): '
                                    f'striker hit too small to separate 2x from 1x block value {b_start}')
    if (deltas['count_normal'] + deltas['count_critical'] + deltas['count_other'] + deltas['count_full']
            != deltas['count_all']):
        return None, 'unmeasured', f'{arm_name} block count partition mismatch: {deltas}'
    if deltas['count_other'] > 0:
        return None, 'alert', (f'{arm_name} saw {deltas["count_other"]} block(s) whose amount was neither '
                               f'{b_start} (1x) nor {2 * b_start} (2x)')
    if deltas['total_normal'] != b_start * deltas['count_normal']:
        return None, 'alert', (f'{arm_name} normal blocked total {deltas["total_normal"]} != '
                               f'{b_start} * {deltas["count_normal"]}')
    if deltas['total_critical'] != 2 * b_start * deltas['count_critical']:
        return None, 'alert', (f'{arm_name} critical blocked total {deltas["total_critical"]} != '
                               f'{2 * b_start} * {deltas["count_critical"]}')
    if deltas['total_all'] != deltas['total_normal'] + deltas['total_critical']:
        return None, 'alert', (f'{arm_name} total blocked {deltas["total_all"]} != '
                               f'normal {deltas["total_normal"]} + critical {deltas["total_critical"]}')
    return {**deltas, 'block_value': b_start}, None, None


def critical_block_rate_verdict(base: Verdict, runs: list[Run], model: dict) -> Verdict:
    expected_parts = int(model.get('parts', 1))
    if len(runs) != expected_parts:
        return replace(base, status='unmeasured',
                       explanation=f'received {len(runs)} part(s), expected {expected_parts}')
    totals = {arm: {'count_all': 0, 'count_normal': 0, 'count_critical': 0,
                    'total_all': 0, 'total_normal': 0, 'total_critical': 0} for arm in (CONTROL, TREATMENT)}
    block_values = set()
    for part_index, run in enumerate(runs, 1):
        refused = '; '.join(f'{spell}: {describe_failures(reasons)}' for spell, reasons
                            in ((spell, failure_reasons(run, spell)) for spell in run.cast_failures) if reasons)
        if refused:
            return replace(base, status='unmeasured', explanation=f'part {part_index}: refused casts {refused}')
        for arm in (CONTROL, TREATMENT):
            found, status, why = extract_arm(run, model['arms'][arm], int(model['shield_item']), arm)
            if status is not None:
                return replace(base, status=status, explanation=f'part {part_index}: {why}')
            block_values.add(found['block_value'])
            for key in totals[arm]:
                totals[arm][key] += found[key]
    expected = float(model['expected_rate'])
    ctrl, treat = totals[CONTROL], totals[TREATMENT]
    min_ctrl, min_treat = int(model['min_control_trials']), int(model['min_treatment_trials'])
    crit_ratio = ((treat['total_critical'] / treat['count_critical']) /
                  (treat['total_normal'] / treat['count_normal'])
                  if treat['count_critical'] > 0 and treat['count_normal'] > 0 else None)
    detail = {**(base.detail or {}), 'metric': COUNT_METRIC, 'control': ctrl, 'treatment': treat,
              'block_values': sorted(block_values), 'crit_amount_ratio': crit_ratio, 'parts': len(runs)}
    if ctrl['count_all'] < min_ctrl:
        return replace(base, status='insufficient_trials', detail=detail,
                       explanation=f'control saw {ctrl["count_all"]} blocks, below minimum {min_ctrl}')
    if ctrl['count_critical'] > 0:
        return replace(base, status='alert', measured=ctrl['count_critical'] / ctrl['count_all'], expected=0.0,
                       detail=detail, explanation=f'control saw {ctrl["count_critical"]}/{ctrl["count_all"]} '
                                                  f'critical blocks before passive learned (expected 0)')
    status, low, high, why = judged_rate(treat['count_critical'], treat['count_all'], min_treat, expected)
    measured = treat['count_critical'] / treat['count_all'] if treat['count_all'] else None
    if status == 'ok' and (crit_ratio is None or abs(crit_ratio - 2.0) > 1e-6):
        return replace(base, status='alert', measured=measured, expected=expected, low=low, high=high, detail=detail,
                       explanation=f'critical block amount ratio {crit_ratio} != 2.0')
    ratio_note = f', amount ratio {crit_ratio:.4f}x (block_value {sorted(block_values)})' if crit_ratio else ''
    return replace(base, status=status, measured=measured, expected=expected, low=low, high=high, detail=detail,
                   explanation=(f'control 0/{ctrl["count_all"]}; treatment '
                                f'{treat["count_critical"]}/{treat["count_all"]} '
                                f'({measured:.4f} against {expected:.4f}): {why}{ratio_note}')
                   if measured is not None else why)


def critical_block_rate_single_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    return critical_block_rate_verdict(base, [run], model)


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return critical_block_scenario(class_file, critical_block_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} {BEHAVIOUR_METRIC_DELTA} {entry.get('label_suffix', KIND)}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: critical_block_rate_single_verdict}
POOLED_JUDGE = critical_block_rate_verdict
