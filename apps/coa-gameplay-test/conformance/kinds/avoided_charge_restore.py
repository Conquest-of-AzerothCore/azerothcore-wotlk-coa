from dataclasses import dataclass, replace
from functools import cache
import math
from pathlib import Path
from statistics import NormalDist

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, waited_ms
from compare import Run, Verdict, banded_rate, describe_failures, failure_reasons, missing_measurement, rate_judgement
from hits import MAX_ACCELERATED_SCENARIO_MS, base_mana_steps, creature_fixture, timed
import proc_avoided
from procs import Z_99, rate_band, wilson_interval
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import (MAX_SCENARIO_STEPS, TARGET, Expectation, dataset, facts_of, fixture_health_step)

KIND = 'avoided_charge_restore'
ORDER = 57
METRIC = 'avoided_charge_restore_rate'
CONTROL, TREATMENT = 'control', 'treatment'
CONTROL_MIN_TRIALS = 50
DEFAULT_RESIDUAL = 1e-3
PAIR_RUNS = 2
TAIL_SDS = 14
DEFAULT_DUMMY_DISTANCE = 5.0
PAUSE_AURA = 56
FIELDS = {'spell', 'name', 'kind', 'variant', 'label_suffix', 'quote', 'charge_spell', 'max_charges',
          'spend_charges', 'expected_pct', 'striker_entry', 'strikers', 'striker_auras', 'window_ms',
          'dodge', 'parry', 'count_misses', 'miss_exclusion', 'dummy_distance', 'control_cycles',
          'treatment_cycles', 'parts', 'residual', 'learn', 'observe_source'}


@dataclass(frozen=True)
class AvoidedChargeRestoreSpec:
    spell: int
    name: str
    quote: str
    label_suffix: str
    charge_spell: int
    max_charges: int
    spend_charges: int
    expected_pct: float
    striker_entry: int
    strikers: int
    striker_auras: tuple[int, ...]
    window_ms: int
    dodge: float
    parry: float
    count_misses: bool
    miss_exclusion: float | None
    dummy_distance: float
    control_cycles: int
    treatment_cycles: int
    parts: int
    residual: float
    learn: tuple[int, ...]


def residual_z(residual: float) -> float:
    return NormalDist().inv_cdf(1 - residual / 2)


def band_trials(rate: float, residual: float) -> int:
    return math.ceil(rate * (1 - rate) * ((Z_99 + residual_z(residual)) / rate_band(rate)) ** 2)


def binomial_pmf(events: int, trials: int, rate: float) -> float:
    return math.exp(math.lgamma(trials + 1) - math.lgamma(events + 1) - math.lgamma(trials - events + 1)
                    + events * math.log(rate) + (trials - events) * math.log(1 - rate))


def judged_rate(restores: int, trials: int, minimum: int, expected: float) -> tuple[str, float | None,
                                                                                    float | None, str]:
    if trials <= 0:
        return 'unmeasured', None, None, 'no avoided swing trial'
    if trials < minimum:
        low, high = wilson_interval(restores, trials)
        return 'insufficient_trials', low, high, (f'rate {restores / trials:.4f} [{low:.4f}, {high:.4f}]: '
                                                  f'fewer than the {minimum} trials the rate needs')
    status, low, high, why = rate_judgement(restores, trials, minimum, expected)
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


def avoided_entry(spec: AvoidedChargeRestoreSpec) -> dict:
    trigger = {'action': proc_avoided.AVOIDED, 'striker_entry': spec.striker_entry, 'swing_ms': spec.window_ms,
               'dodge': spec.dodge, 'parry': spec.parry, 'strikers': spec.strikers,
               'striker_auras': list(spec.striker_auras), 'count_misses': spec.count_misses,
               'learn': list(spec.learn)}
    if spec.miss_exclusion is not None:
        trigger['miss_exclusion'] = {'min_share': spec.miss_exclusion}
    return {'aura': spec.spell, 'trigger': trigger}


def avoided_charge_restore_spec(entry: dict) -> AvoidedChargeRestoreSpec:
    if set(entry) - FIELDS:
        raise ValueError(f'{entry["spell"]} {KIND} has unknown fields {sorted(set(entry) - FIELDS)}')
    spell = int(entry['spell'])
    max_charges = entry['max_charges']
    spend_charges = entry.get('spend_charges', max_charges)
    if isinstance(max_charges, bool) or not isinstance(max_charges, int) or max_charges < 1:
        raise ValueError(f'{spell} {KIND} max_charges must be a positive integer')
    if isinstance(spend_charges, bool) or not isinstance(spend_charges, int) or not 1 <= spend_charges <= max_charges:
        raise ValueError(f'{spell} {KIND} spend_charges must be between 1 and max_charges ({max_charges})')
    expected_pct = entry['expected_pct']
    if isinstance(expected_pct, bool) or not isinstance(expected_pct, (int, float)) or not 0 < expected_pct < 100:
        raise ValueError(f'{spell} {KIND} expected_pct must lie strictly between 0 and 100')
    for field_name in ('charge_spell', 'striker_entry', 'strikers', 'window_ms', 'control_cycles', 'treatment_cycles',
                       'parts'):
        value = entry[field_name]
        if isinstance(value, bool) or not isinstance(value, int) or value < 1:
            raise ValueError(f'{spell} {KIND} {field_name} must be a positive integer')
    residual = float(entry.get('residual', DEFAULT_RESIDUAL))
    if not 0 < residual < 1:
        raise ValueError(f'{spell} {KIND} residual must lie strictly between 0 and 1')
    dummy_distance = float(entry.get('dummy_distance', DEFAULT_DUMMY_DISTANCE))
    if not math.isfinite(dummy_distance) or dummy_distance <= 0:
        raise ValueError(f'{spell} {KIND} dummy_distance must be positive')
    miss_excl_raw = entry.get('miss_exclusion')
    miss_exclusion = None
    if miss_excl_raw is not None:
        if not isinstance(miss_excl_raw, dict) or set(miss_excl_raw) != {'min_share'}:
            raise ValueError(f'{spell} {KIND} miss_exclusion is {{"min_share": 0 to 0.5 exclusive}}')
        miss_exclusion = float(miss_excl_raw['min_share'])
    spec = AvoidedChargeRestoreSpec(
        spell, entry['name'], entry['quote'], entry.get('label_suffix', KIND),
        int(entry['charge_spell']), max_charges, spend_charges, float(expected_pct),
        int(entry['striker_entry']), int(entry['strikers']),
        tuple(int(item) for item in entry.get('striker_auras', ())), int(entry['window_ms']),
        float(entry['dodge']), float(entry['parry']), bool(entry.get('count_misses', False)),
        miss_exclusion, dummy_distance, int(entry['control_cycles']), int(entry['treatment_cycles']),
        int(entry['parts']), residual, tuple(int(item) for item in entry.get('learn', ())))
    proc_avoided.checked_trigger(avoided_entry(spec))
    return spec


def check_label(spec: AvoidedChargeRestoreSpec) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}'


def cycle_labels(prefix: str, arm: str, cycle: int, misses: bool) -> dict:
    trials_base = f'{prefix} {arm} {cycle} avoided'
    return {
        'charges_before': f'{prefix} {arm} {cycle} charges before',
        'charges_after': f'{prefix} {arm} {cycle} charges after',
        'trials': proc_avoided.trial_labels(trials_base, misses),
        'total': f'{prefix} {arm} {cycle} total',
    }


def start_labels(prefix: str, misses: bool) -> dict:
    return {
        'trials': proc_avoided.trial_labels(f'{prefix} start avoided', misses),
        'total': f'{prefix} start total',
    }


def pause_steps(avoided: dict, on: bool) -> list[dict]:
    stacks = 1 if on else 0
    return [{'action': 'set_aura', 'actor': CASTER, 'target': striker, 'caster': striker, 'spell': PAUSE_AURA,
             'stacks': stacks} for striker in proc_avoided.striker_ids(avoided)]


def cycle_steps(spec: AvoidedChargeRestoreSpec, avoided: dict, mana: list[dict], labels: dict) -> list[dict]:
    steps = [{'action': 'restore_charges', 'actor': CASTER, 'spell': spec.charge_spell}, *mana]
    for _ in range(spec.spend_charges):
        steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.charge_spell, 'target': TARGET,
                      'ignore_gcd': True})
    steps += [{'action': 'stop_attack', 'actor': CASTER},
              fixture_health_step(CASTER, 100),
              {'action': 'set_combat_avoidance', 'actor': CASTER, 'dodge': spec.dodge, 'parry': spec.parry},
              measurement(labels['charges_before'], CASTER, 'spell_charges', spell=spec.charge_spell),
              *pause_steps(avoided, False),
              {'action': 'wait', 'ms': spec.window_ms},
              *pause_steps(avoided, True),
              measurement(labels['charges_after'], CASTER, 'spell_charges', spell=spec.charge_spell),
              *proc_avoided.trial_steps(labels['trials']['dodged'], labels['total'], misses=spec.count_misses)]
    return steps


def avoided_charge_restore_scenario(class_file: dict,
                                    spec: AvoidedChargeRestoreSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, spec.expected_pct)
    charge_facts = facts_of(records, spec.charge_spell)
    mana = base_mana_steps(class_file, charge_facts)
    if not mana and (charge_facts.mana_cost or charge_facts.mana_cost_percentage):
        raise ValueError(f'{spec.spell} {KIND} charge_spell {spec.charge_spell} needs base_mana or zero cost')
    avoided = avoided_entry(spec)
    prefix = check_label(spec)
    start = start_labels(prefix, spec.count_misses)
    control_reads = [cycle_labels(prefix, CONTROL, idx, spec.count_misses) for idx in range(1, spec.control_cycles + 1)]
    treatment_reads = [cycle_labels(prefix, TREATMENT, idx, spec.count_misses)
                       for idx in range(1, spec.treatment_cycles + 1)]
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.charge_spell}]
             + proc_avoided.engage_steps(avoided)
             + pause_steps(avoided, True)
             + proc_avoided.trial_steps(start['trials']['dodged'], start['total'], misses=spec.count_misses))
    for reads in control_reads:
        steps += cycle_steps(spec, avoided, mana, reads)
    steps.append({'action': 'learn', 'actor': CASTER, 'spell': spec.spell})
    for reads in treatment_reads:
        steps += cycle_steps(spec, avoided, mana, reads)
    steps += proc_avoided.guard_steps(avoided)
    if len(steps) > MAX_SCENARIO_STEPS:
        raise ValueError(f'{spec.spell} {KIND} takes {len(steps)} steps, above {MAX_SCENARIO_STEPS}: '
                         f'reduce cycles per part and add parts')
    rate = spec.expected_pct / 100.0
    min_treat = minimum_treatment_trials(rate, spec.residual)
    min_ctrl = minimum_control_trials(rate, spec.residual)
    ff_pair = PAIR_RUNS * exact_false_fail(min_treat, rate)
    fp_ctrl_pair = ((1.0 - rate) ** min_ctrl) ** PAIR_RUNS
    fp_treat_pair = exact_false_pass(min_treat, 0.0, rate) ** PAIR_RUNS
    guards = {name: proc_avoided.guard_label(spec.spell, name) for name in proc_avoided.guard_reads(avoided)}
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour avoided charge restore',
        'contract': (f'Avoided-swing spell-charge restore rate for {spec.spell} on {spec.charge_spell} '
                     f'(max_charges={spec.max_charges}, spend_charges={spec.spend_charges}, '
                     f'window_ms={spec.window_ms}, expected={spec.expected_pct:g}%, '
                     f'G-20 band +-{rate_band(rate) * 100:g} pts). '
                     f'{proc_avoided.trial_rule(avoided)}. Each cycle resets {spec.charge_spell} charges, spends '
                     f'{spec.spend_charges} charge(s) at dummy ({spec.dummy_distance:g} yd) with ignore_gcd, reads '
                     f'spell_charges before and after one {spec.window_ms} ms avoided-swing window, and reads '
                     f'cumulative avoided swings. Control runs {spec.control_cycles} cycles/part before {spec.spell} '
                     f'is learned (must restore 0 charges over >= {min_ctrl} pooled avoided swings); treatment runs '
                     f'{spec.treatment_cycles} cycles/part after a real learn (>= {min_treat} pooled avoided swings '
                     f'across {spec.parts} part(s)). Any window with avoided swings > open charge slots voids the run '
                     f'as unmeasured so charge capping cannot bias the rate. Residual per counted pair of {PAIR_RUNS} '
                     f'runs (exact binomial at minimum sample): conformant false-fail {ff_pair:.1e}, control '
                     f'false-pass {fp_ctrl_pair:.1e}, treatment false-pass at 0% {fp_treat_pair:.1e} (target <= '
                     f'{spec.residual:.1e}).'),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file, spec.dummy_distance),
                      *proc_avoided.striker_fixtures(class_file, avoided)],
        'steps': steps}
    model = {
        'kind': KIND, 'metric': METRIC, 'quote': entry.quote, 'prefix': prefix,
        'expected_rate': rate, 'max_charges': spec.max_charges,
        'min_control_trials': min_ctrl, 'min_treatment_trials': min_treat,
        'count_misses': spec.count_misses, 'miss_exclusion': spec.miss_exclusion,
        'start': start, 'arms': {CONTROL: control_reads, TREATMENT: treatment_reads},
        'guards': guards,
    }
    expectation = Expectation(prefix, BEHAVIOUR_METRIC_DELTA, spec.spell, spec.charge_spell, None,
                              f'{rate:.4f}', prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps), MAX_ACCELERATED_SCENARIO_MS), [expectation]


def sum_avoided(run: Run, trial_map: dict) -> tuple[int, int, str | None]:
    total = 0
    missed = 0
    for outcome, label in trial_map.items():
        val = run.values.get(label)
        if val is None:
            return 0, 0, missing_measurement(run, label)
        count = int(round(float(val)))
        total += count
        if outcome == proc_avoided.MISSED:
            missed = count
    return total, missed, None


def extract_run_counts(run: Run, model: dict) -> tuple[dict | None, str | None, str | None]:
    refused = '; '.join(f'{spell}: {describe_failures(reasons)}' for spell, reasons
                        in ((spell, failure_reasons(run, spell)) for spell in run.cast_failures) if reasons)
    if refused:
        return None, 'unmeasured', f'refused casts {refused}'
    for name, label in model['guards'].items():
        val = run.values.get(label)
        if val is None:
            return None, 'unmeasured', missing_measurement(run, label)
        if val != 0:
            return None, 'unmeasured', f'avoided guard {name} read {val:g}, expected 0'
    prev_avoided, prev_missed, missing = sum_avoided(run, model['start']['trials'])
    if missing:
        return None, 'unmeasured', missing
    prev_total_raw = run.values.get(model['start']['total'])
    if prev_total_raw is None:
        return None, 'unmeasured', missing_measurement(run, model['start']['total'])
    prev_total = int(round(float(prev_total_raw)))
    max_charges = int(model['max_charges'])
    counts = {CONTROL: {'trials': 0, 'restores': 0, 'missed': 0},
              TREATMENT: {'trials': 0, 'restores': 0, 'missed': 0}}
    for arm in (CONTROL, TREATMENT):
        for idx, cycle in enumerate(model['arms'][arm], 1):
            cb_raw = run.values.get(cycle['charges_before'])
            if cb_raw is None:
                return None, 'unmeasured', missing_measurement(run, cycle['charges_before'])
            ca_raw = run.values.get(cycle['charges_after'])
            if ca_raw is None:
                return None, 'unmeasured', missing_measurement(run, cycle['charges_after'])
            cur_avoided, cur_missed, missing = sum_avoided(run, cycle['trials'])
            if missing:
                return None, 'unmeasured', missing
            cur_total_raw = run.values.get(cycle['total'])
            if cur_total_raw is None:
                return None, 'unmeasured', missing_measurement(run, cycle['total'])
            cur_total = int(round(float(cur_total_raw)))
            c_before, c_after = int(round(float(cb_raw))), int(round(float(ca_raw)))
            open_slots = max_charges - c_before
            w_trials = cur_avoided - prev_avoided
            w_missed = cur_missed - prev_missed
            w_total = cur_total - prev_total
            w_restores = c_after - c_before
            prev_avoided, prev_missed, prev_total = cur_avoided, cur_missed, cur_total
            if model['count_misses'] and w_total != w_trials:
                return None, 'unmeasured', (f'{arm} cycle {idx}: attacks taken {w_total} != avoided+missed {w_trials}')
            if open_slots < 1 or w_trials < 0:
                return None, 'unmeasured', (f'{arm} cycle {idx}: invalid window (open_slots={open_slots}, '
                                            f'trials={w_trials})')
            if w_trials > open_slots:
                return None, 'unmeasured', (f'{arm} cycle {idx}: {w_trials} avoided swings exceeded {open_slots} open '
                                            f'charge slots (capping risk)')
            if w_restores < 0:
                return None, 'unmeasured', f'{arm} cycle {idx}: charges fell ({c_before} -> {c_after})'
            if w_restores > w_trials:
                return None, 'alert', (f'{arm} cycle {idx}: {w_restores} charges restored over only {w_trials} avoided '
                                       f'swings (extra or natural recharge leaked into window)')
            counts[arm]['trials'] += w_trials
            counts[arm]['restores'] += w_restores
            counts[arm]['missed'] += w_missed
    return counts, None, None


def avoided_charge_restore_verdict(base: Verdict, runs: list[Run], model: dict) -> Verdict:
    totals = {CONTROL: {'trials': 0, 'restores': 0, 'missed': 0},
              TREATMENT: {'trials': 0, 'restores': 0, 'missed': 0}}
    for run in runs:
        found, status, why = extract_run_counts(run, model)
        if status is not None:
            return replace(base, status=status, explanation=why)
        for arm in (CONTROL, TREATMENT):
            for key in ('trials', 'restores', 'missed'):
                totals[arm][key] += found[arm][key]
    expected = float(model['expected_rate'])
    ctrl = totals[CONTROL]
    treat = totals[TREATMENT]
    min_ctrl, min_treat = int(model['min_control_trials']), int(model['min_treatment_trials'])
    detail = {**(base.detail or {}), 'metric': METRIC, 'control': ctrl, 'treatment': treat, 'parts': len(runs)}
    if ctrl['trials'] < min_ctrl:
        return replace(base, status='insufficient_trials', detail=detail,
                       explanation=f'control saw {ctrl["trials"]} avoided swings, below minimum {min_ctrl}')
    if ctrl['restores'] > 0:
        return replace(base, status='alert', measured=ctrl['restores'] / ctrl['trials'], expected=0.0,
                       detail=detail, explanation=f'control restored {ctrl["restores"]} of {ctrl["trials"]} before '
                                                  f'passive learned (expected 0)')
    status, low, high, why = judged_rate(treat['restores'], treat['trials'], min_treat, expected)
    measured = treat['restores'] / treat['trials'] if treat['trials'] else None
    miss_note = ''
    if status == 'ok' and model.get('miss_exclusion') is not None and low is not None:
        min_share = float(model['miss_exclusion'])
        miss_share = treat['missed'] / treat['trials']
        detail['miss_share'] = miss_share
        if miss_share < min_share:
            return replace(base, status='unmeasured', measured=measured, expected=expected, low=low, high=high,
                           detail=detail, explanation=f'miss share {miss_share:.4f} below min_share {min_share:.4f}')
        no_miss_rate = expected * (1.0 - miss_share)
        miss_note = f'; miss share {miss_share:.4f} (no-miss rate {no_miss_rate:.4f} vs low {low:.4f})'
        if no_miss_rate >= low:
            return replace(base, status='alert', measured=measured, expected=expected, low=low, high=high,
                           detail=detail, explanation=(f'control 0/{ctrl["trials"]}; treatment {treat["restores"]}/'
                                                       f'{treat["trials"]}: {why}{miss_note} '
                                                       f'(misses not proven counted)'))
    return replace(base, status=status, measured=measured, expected=expected, low=low, high=high, detail=detail,
                   explanation=f'control 0/{ctrl["trials"]}; treatment {treat["restores"]}/{treat["trials"]} '
                               f'({measured:.4f} against {expected:.4f}): {why}{miss_note}'
                               if measured is not None else why)


def avoided_charge_restore_single_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    return avoided_charge_restore_verdict(base, [run], model)


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return avoided_charge_restore_scenario(class_file, avoided_charge_restore_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} {BEHAVIOUR_METRIC_DELTA} {entry.get('label_suffix', KIND)}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: avoided_charge_restore_single_verdict}
POOLED_JUDGE = avoided_charge_restore_verdict
METRIC_EVIDENCE = {METRIC: 'event'}
