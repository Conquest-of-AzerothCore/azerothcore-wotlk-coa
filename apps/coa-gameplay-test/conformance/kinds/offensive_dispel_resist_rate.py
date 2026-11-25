from dataclasses import dataclass, replace
from functools import cache
import math
from pathlib import Path
from statistics import NormalDist

from behaviours import (BEHAVIOUR_METRIC_DELTA, STRIKER, STRIKER_DISTANCE, STRIKER_HEALTH, behaviour_entry,
                        prose_rule, waited_ms)
from compare import Run, Verdict, banded_rate, missing_measurement, rate_judgement
from hits import MAX_SCENARIO_MS, timed
from procs import Z_99, rate_band, wilson_interval
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import ALLY, MAX_SCENARIO_STEPS, Expectation, dataset

KIND = 'offensive_dispel_resist_rate'
ORDER = 56
CONTROL, TREATMENT, GATE_OFF = 'control', 'treatment', 'gate_off'
STRIKER_ENTRY = 36
DEFAULT_DISPEL_SPELL = 527
SPELL_EFFECT_DISPEL = 38
DISPEL_MAGIC = 1
GATE_SETTLE_MS = 500
CONTROL_MIN_TRIALS = 50
DEFAULT_RESIDUAL = 1e-3
PAIR_RUNS = 2
TAIL_SDS = 14
TARGETS = (CASTER, ALLY)
ALLY_DY_YD = 2.0


@dataclass(frozen=True)
class OffensiveDispelResistSpec:
    spell: int
    name: str
    quote: str
    label_suffix: str
    buff_spell: int
    treatment_resist_pct: float
    control_resist_pct: float = 0.0
    dispel_spell: int = DEFAULT_DISPEL_SPELL
    target: str = CASTER
    learn: tuple[int, ...] = ()
    gate_cast: int | None = None
    gate_settle_ms: int = GATE_SETTLE_MS
    clear_auras: tuple[int, ...] = ()
    parts: int = 1
    residual: float = DEFAULT_RESIDUAL
    trials: int | None = None
    control_trials: int | None = None
    buff_source: str = ''


def clamped_survive_rate(resist_pct: float) -> float:
    return min(100.0, max(0.0, float(resist_pct))) / 100.0


def arm_band(rate: float) -> float:
    return rate_band(rate) if 0.0 < rate < 1.0 else 0.0


def residual_z(residual: float) -> float:
    return NormalDist().inv_cdf(1 - residual / 2)


def band_trials(rate: float, residual: float) -> int:
    return math.ceil(rate * (1 - rate) * ((Z_99 + residual_z(residual)) / rate_band(rate)) ** 2)


def binomial_pmf(events: int, trials: int, rate: float) -> float:
    return math.exp(math.lgamma(trials + 1) - math.lgamma(events + 1) - math.lgamma(trials - events + 1)
                    + events * math.log(rate) + (trials - events) * math.log(1 - rate))


def judged_arm(survived: int, trials: int, minimum: int, expected: float) -> tuple[str, float | None,
                                                                                   float | None, str]:
    if trials <= 0:
        return 'unmeasured', None, None, 'no trial'
    if trials < minimum:
        if 0.0 < expected < 1.0:
            low, high = wilson_interval(survived, trials)
            return 'insufficient_trials', low, high, (f'rate {survived / trials:.4f} [{low:.4f}, {high:.4f}]: '
                                                      f'fewer than the {minimum} trials the rate needs')
        return 'insufficient_trials', None, None, (f'rate {survived / trials:.4f}, {survived} of {trials} survived: '
                                                   f'fewer than the {minimum} trials needed')
    if expected <= 0.0:
        status = 'ok' if survived == 0 else 'alert'
        return status, 0.0, 0.0, f'rate {survived / trials:.4f}, {survived} of {trials} survived against clamped 0.0000'
    if expected >= 1.0:
        status = 'ok' if survived == trials else 'alert'
        return status, 1.0, 1.0, f'rate {survived / trials:.4f}, {survived} of {trials} survived against clamped 1.0000'
    status, low, high, why = rate_judgement(survived, trials, minimum, expected)
    if low is not None:
        return banded_rate(status, low, high, expected, why)
    return status, low, high, why


@cache
def exact_false_fail(trials: int, rate: float) -> float:
    if rate <= 0.0 or rate >= 1.0:
        return 0.0
    spread = TAIL_SDS * math.sqrt(trials * rate * (1 - rate))
    low, high = max(0, int(trials * rate - spread)), min(trials, int(trials * rate + spread))
    return sum(binomial_pmf(survived, trials, rate) for survived in range(low, high + 1)
               if judged_arm(survived, trials, trials, rate)[0] != 'ok')


@cache
def exact_false_pass(trials: int, true_rate: float, expected_rate: float) -> float:
    if expected_rate <= 0.0:
        return (1.0 - true_rate) ** trials
    if expected_rate >= 1.0:
        return true_rate ** trials
    if true_rate <= 0.0:
        return 1.0 if judged_arm(0, trials, trials, expected_rate)[0] == 'ok' else 0.0
    if true_rate >= 1.0:
        return 1.0 if judged_arm(trials, trials, trials, expected_rate)[0] == 'ok' else 0.0
    band = arm_band(expected_rate)
    low = max(0, int(math.floor(trials * (expected_rate - band))) - 2)
    high = min(trials, int(math.ceil(trials * (expected_rate + band))) + 2)
    return sum(binomial_pmf(survived, trials, true_rate) for survived in range(low, high + 1)
               if judged_arm(survived, trials, trials, expected_rate)[0] == 'ok')


def pair_false_pass(trials: int, true_rate: float, expected_rate: float) -> float:
    return exact_false_pass(trials, true_rate, expected_rate) ** PAIR_RUNS


def boundary_trials_needed(other_rate: float, expected_rate: float, residual: float) -> int:
    mismatch = 1.0 - other_rate if expected_rate <= 0.0 else other_rate
    if mismatch <= 0.0:
        return CONTROL_MIN_TRIALS
    if mismatch >= 1.0:
        return CONTROL_MIN_TRIALS
    single_target = math.sqrt(residual)
    return max(CONTROL_MIN_TRIALS, math.ceil(math.log(single_target) / math.log(mismatch)))


@cache
def split_interior_trials(rate: float, residual: float, parts: int) -> int:
    per_part = max(1, math.ceil(band_trials(rate, residual) / parts))
    while exact_false_fail(per_part * parts, rate) > residual:
        per_part += 1
    return per_part


def split_arm_trials(rate: float, other_rate: float, ff_budget: float, fp_budget: float, parts: int) -> int:
    if 0.0 < rate < 1.0:
        per_part = split_interior_trials(rate, ff_budget, parts)
        while pair_false_pass(per_part * parts, other_rate, rate) > fp_budget:
            per_part += 1
            if per_part * parts > MAX_SCENARIO_STEPS * parts:
                break
        return per_part
    return math.ceil(boundary_trials_needed(other_rate, rate, fp_budget) / parts)


def spec_arms(spec: OffensiveDispelResistSpec) -> tuple[str, ...]:
    return (CONTROL, TREATMENT, GATE_OFF) if spec.gate_cast is not None else (CONTROL, TREATMENT)


def arm_rates(spec: OffensiveDispelResistSpec) -> dict[str, float]:
    control = clamped_survive_rate(spec.control_resist_pct)
    treatment = clamped_survive_rate(spec.treatment_resist_pct)
    rates = {CONTROL: control, TREATMENT: treatment}
    if spec.gate_cast is not None:
        rates[GATE_OFF] = control
    return rates


def arm_trials(spec: OffensiveDispelResistSpec) -> dict[str, int]:
    rates = arm_rates(spec)
    control_rate, treatment_rate = rates[CONTROL], rates[TREATMENT]
    interior = sum(1 for rate in rates.values() if 0.0 < rate < 1.0)
    ff_budget = spec.residual / (PAIR_RUNS * max(1, interior))
    fp_budget = spec.residual
    auto_control = split_arm_trials(control_rate, treatment_rate, ff_budget, fp_budget, spec.parts)
    auto_treatment = split_arm_trials(treatment_rate, control_rate, ff_budget, fp_budget, spec.parts)
    control = auto_control if spec.control_trials is None else spec.control_trials
    treatment = auto_treatment if spec.trials is None else spec.trials
    trials = {CONTROL: control, TREATMENT: treatment}
    if spec.gate_cast is not None:
        trials[GATE_OFF] = control
    return trials


def arm_risk(spec: OffensiveDispelResistSpec) -> dict:
    rates = arm_rates(spec)
    trials = arm_trials(spec)
    ff = {arm: exact_false_fail(trials[arm] * spec.parts, rates[arm]) for arm in spec_arms(spec)}
    fp = {
        CONTROL: pair_false_pass(trials[CONTROL] * spec.parts, rates[TREATMENT], rates[CONTROL]),
        TREATMENT: pair_false_pass(trials[TREATMENT] * spec.parts, rates[CONTROL], rates[TREATMENT]),
    }
    if GATE_OFF in rates:
        fp[GATE_OFF] = pair_false_pass(trials[GATE_OFF] * spec.parts, rates[TREATMENT], rates[GATE_OFF])
    return {'false_fail': ff, 'false_fail_pair': PAIR_RUNS * sum(ff.values()),
            'false_pass_pair': fp, 'max_false_pass_pair': max(fp.values())}


def offensive_dispel_resist_spec(entry: dict) -> OffensiveDispelResistSpec:
    spell = int(entry['spell'])
    spec = OffensiveDispelResistSpec(
        spell, entry['name'], entry['quote'], entry['label_suffix'], int(entry['buff_spell']),
        float(entry['treatment_resist_pct']), float(entry.get('control_resist_pct', 0.0)),
        int(entry.get('dispel_spell', DEFAULT_DISPEL_SPELL)), entry.get('target', CASTER),
        tuple(int(item) for item in entry.get('learn', ())),
        None if entry.get('gate_cast') is None else int(entry['gate_cast']),
        int(entry.get('gate_settle_ms', GATE_SETTLE_MS)),
        tuple(int(aura) for aura in entry.get('clear_auras', ())),
        int(entry.get('parts', 1)), float(entry.get('residual', DEFAULT_RESIDUAL)),
        None if entry.get('trials') is None else int(entry['trials']),
        None if entry.get('control_trials') is None else int(entry['control_trials']),
        str(entry.get('buff_source', '')))
    if spec.target not in TARGETS:
        raise ValueError(f'{spell} {KIND} target must be one of {TARGETS}, not {spec.target!r}')
    if spec.parts < 1 or not 0 < spec.residual < 1 or spec.gate_settle_ms < 0:
        raise ValueError(f'{spell} {KIND} needs parts >= 1, residual in (0, 1) and non-negative gate_settle_ms')
    if spec.spell in spec.learn:
        raise ValueError(f'{spell} {KIND} learns {spec.spell} only between the control and treatment arms')
    if spec.trials is not None and spec.trials < 1:
        raise ValueError(f'{spell} {KIND} trials must be positive, not {spec.trials}')
    if spec.control_trials is not None and spec.control_trials < 1:
        raise ValueError(f'{spell} {KIND} control_trials must be positive, not {spec.control_trials}')
    control_rate = clamped_survive_rate(spec.control_resist_pct)
    treatment_rate = clamped_survive_rate(spec.treatment_resist_pct)
    if control_rate == treatment_rate:
        raise ValueError(f'{spell} {KIND} clamped survive rates are identical ({control_rate:.4f} vs '
                         f'{treatment_rate:.4f}): nothing to tell apart')
    band_gap = arm_band(control_rate) + arm_band(treatment_rate)
    if abs(treatment_rate - control_rate) <= band_gap + 1e-12:
        raise ValueError(f'{spell} {KIND} clamped survive rates {control_rate:.4f} and {treatment_rate:.4f} '
                         f'are within their combined G-20 bands ({band_gap:.4f}) and cannot be told apart')
    risk = arm_risk(spec)
    if risk['false_fail_pair'] > spec.residual:
        raise ValueError(f'{spell} {KIND} conformant pair false-fail probability {risk["false_fail_pair"]:.2e} '
                         f'exceeds residual {spec.residual:.1e}: increase trials or parts')
    if risk['max_false_pass_pair'] > spec.residual:
        raise ValueError(f'{spell} {KIND} pair false-pass probability {risk["max_false_pass_pair"]:.2e} '
                         f'exceeds residual {spec.residual:.1e}: rates {control_rate:.4f} and {treatment_rate:.4f} '
                         f'cannot be told apart at the given sample')
    for arm, count in arm_trials(spec).items():
        if count * spec.parts < CONTROL_MIN_TRIALS:
            raise ValueError(f'{spell} {KIND} {arm} plans {count * spec.parts} trials across {spec.parts} part(s), '
                             f'below the minimum {CONTROL_MIN_TRIALS}')
    return spec


def check_label(spec: OffensiveDispelResistSpec, suffix: str = '') -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}{suffix}'


def read_label(prefix: str, arm: str, trial: int) -> str:
    return f'{prefix} {arm} {trial} survived'


def gate_label(prefix: str, arm: str, edge: str) -> str:
    return f'{prefix} {arm} gate {edge}'


def clear_steps(spec: OffensiveDispelResistSpec) -> list[dict]:
    steps = [{'action': 'set_aura', 'actor': CASTER, 'spell': aura, 'stacks': 0, 'target': spec.target}
             for aura in spec.clear_auras]
    steps.append({'action': 'set_aura', 'actor': CASTER, 'spell': spec.buff_spell, 'stacks': 0,
                  'target': spec.target, 'caster': CASTER})
    return steps


def arm_steps(spec: OffensiveDispelResistSpec, arm: str, count: int) -> list[dict]:
    prefix = check_label(spec)
    steps = clear_steps(spec)
    if spec.gate_cast is not None:
        if arm == GATE_OFF:
            steps.append({'action': 'set_aura', 'actor': CASTER, 'spell': spec.gate_cast, 'stacks': 0})
            if spec.gate_settle_ms:
                steps.append({'action': 'wait', 'label': f'{KIND} gate off settle', 'ms': spec.gate_settle_ms})
        else:
            steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.gate_cast})
            steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.gate_cast, 'target': CASTER})
            if spec.gate_settle_ms:
                steps.append({'action': 'wait', 'label': f'{KIND} gate settle', 'ms': spec.gate_settle_ms})
        steps.append(measurement(gate_label(prefix, arm, 'before'), CASTER, 'aura', spell=spec.gate_cast))
    for trial in range(1, count + 1):
        steps.append({'action': 'set_aura', 'actor': CASTER, 'spell': spec.buff_spell, 'stacks': 1,
                      'target': spec.target, 'caster': CASTER})
        steps.append({'action': 'cast', 'actor': STRIKER, 'spell': spec.dispel_spell, 'target': spec.target})
        steps.append(measurement(read_label(prefix, arm, trial), spec.target, 'aura', spell=spec.buff_spell))
    if spec.gate_cast is not None:
        steps.append(measurement(gate_label(prefix, arm, 'after'), CASTER, 'aura', spell=spec.gate_cast))
        if arm != GATE_OFF:
            steps.append({'action': 'set_aura', 'actor': CASTER, 'spell': spec.gate_cast, 'stacks': 0})
    return steps + clear_steps(spec)


def scenario_steps(class_file: dict, spec: OffensiveDispelResistSpec) -> list[dict]:
    steps = base_steps(class_file)
    if spec.target == ALLY:
        steps += [{'action': 'relocate', 'actor': ALLY, 'dy': ALLY_DY_YD},
                  {'action': 'group', 'actor': CASTER, 'target': ALLY}]
    steps += [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in spec.learn]
    trials = arm_trials(spec)
    steps += arm_steps(spec, CONTROL, trials[CONTROL])
    steps.append({'action': 'learn', 'actor': CASTER, 'spell': spec.spell})
    steps += arm_steps(spec, TREATMENT, trials[TREATMENT])
    if spec.gate_cast is not None:
        steps += arm_steps(spec, GATE_OFF, trials[GATE_OFF])
    return steps


def residual_text(value: float) -> str:
    return f'{value:.1e}'


def scenario_contract(spec: OffensiveDispelResistSpec) -> str:
    rates = arm_rates(spec)
    trials = arm_trials(spec)
    risk = arm_risk(spec)
    holder = 'a grouped ally player' if spec.target == ALLY else 'the caster'
    buff_note = f' ({spec.buff_source})' if spec.buff_source else ''
    gate_note = (f' Gate {spec.gate_cast} is cast before control and treatment (read present before and after each '
                 f'arm) and removed before gate_off (read absent before and after: {trials[GATE_OFF]} trials/part, '
                 f'expected survive rate {rates[GATE_OFF]:.4f}).' if spec.gate_cast is not None else '')
    return (f'Offensive dispel survival through Aura::CalcDispelChance (SpellAuras.cpp:1153-1178, resistChance clamped '
            f'to [0, 100], survive rate = clamp(resist, 0, 100) / 100): positive Magic buff {spec.buff_spell}'
            f'{buff_note} is applied to {holder} (caster = caster) before each trial, and a stationary passive '
            f'hostile striker (creature {STRIKER_ENTRY}, spell_hit_bonus 100) casts {spec.dispel_spell} at '
            f'{spec.target}; each trial reads aura {spec.buff_spell} on {spec.target} immediately after. Control: '
            f'{trials[CONTROL]} trials/part before {spec.spell} is learned (raw {spec.control_resist_pct:g}%, clamped '
            f'survive rate {rates[CONTROL]:.4f}). Then {spec.spell} is learned (a real learn). Treatment: '
            f'{trials[TREATMENT]} trials/part (raw {spec.treatment_resist_pct:g}%, clamped survive rate '
            f'{rates[TREATMENT]:.4f}).{gate_note} Pooled over {spec.parts} part(s); interior rates judged by Wilson '
            f'99% interval inside the G-20 band, clamped 0/1 rates by exact survival. Residual per counted pair of '
            f'{PAIR_RUNS} runs (exact binomial): conformant false-fail {residual_text(risk["false_fail_pair"])}, '
            f'cross-arm false-pass at most {residual_text(risk["max_false_pass_pair"])} (target <= '
            f'{residual_text(spec.residual)}).')


def validate_spells(records: Records, spec: OffensiveDispelResistSpec):
    if int(records.field('Spell', spec.buff_spell, 'Dispel') or 0) != DISPEL_MAGIC:
        raise ValueError(f'{spec.spell} {KIND} buff_spell {spec.buff_spell} is not Magic-dispellable (Dispel != 1)')
    if int(records.field('Spell', spec.dispel_spell, 'Effect[0]') or 0) != SPELL_EFFECT_DISPEL or \
            int(records.field('Spell', spec.dispel_spell, 'EffectMiscValue[0]') or 0) != DISPEL_MAGIC or \
            float(records.field('Spell', spec.dispel_spell, 'Speed') or 0) != 0.0:
        raise ValueError(f'{spec.spell} {KIND} dispel_spell {spec.dispel_spell} must be an instant Magic dispel')


def offensive_dispel_resist_scenario(class_file: dict,
                                     spec: OffensiveDispelResistSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    validate_spells(records, spec)
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, spec.treatment_resist_pct)
    steps = scenario_steps(class_file, spec)
    if len(steps) > MAX_SCENARIO_STEPS:
        raise ValueError(f'{spec.spell} {KIND} takes {len(steps)} steps, above {MAX_SCENARIO_STEPS}: add parts')
    players = [player_fixture(class_file)]
    if spec.target == ALLY:
        players.append({**player_fixture(class_file), 'id': ALLY})
    striker = {'id': STRIKER, 'owner': CASTER, 'entry': STRIKER_ENTRY, 'level': class_file['level'],
               'health': STRIKER_HEALTH, 'distance': STRIKER_DISTANCE, 'stationary': True, 'reaction': 0,
               'spell_hit_bonus': 100}
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour offensive dispel resist rate',
        'contract': scenario_contract(spec),
        'players': players,
        'creatures': [striker],
        'steps': steps}
    rates = arm_rates(spec)
    trials = arm_trials(spec)
    minimum = {arm: count * spec.parts for arm, count in trials.items()}
    common = {'kind': KIND, 'metric': 'aura', 'quote': entry.quote, 'prefix': check_label(spec),
              'rates': rates, 'trials': trials, 'minimum': minimum, 'gate_cast': spec.gate_cast}
    rule = prose_rule(entry.quote, spec.spell)
    expectations = [
        Expectation(check_label(spec), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.buff_spell, None,
                    f'{rates[TREATMENT]:.4f}', rule, {**common, 'arms': [CONTROL, TREATMENT]})]
    if spec.gate_cast is not None:
        expectations.append(
            Expectation(check_label(spec, '_gate_off'), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.buff_spell, None,
                        f'{rates[GATE_OFF]:.4f}', rule, {**common, 'arms': [CONTROL, GATE_OFF]}))
    return timed(scenario, waited_ms(steps), MAX_SCENARIO_MS), expectations


def arm_reads(run: Run, model: dict, arm: str) -> tuple[list[bool], str | None]:
    prefix = model['prefix']
    if model.get('gate_cast') is not None:
        want = 0 if arm == GATE_OFF else 1
        for edge in ('before', 'after'):
            label = gate_label(prefix, arm, edge)
            value = run.values.get(label)
            if value is None:
                return [], missing_measurement(run, label)
            if (value == 0) != (want == 0):
                state = 'absent' if want == 0 else 'present'
                return [], f'{arm} gate aura {model["gate_cast"]} read {value:g} ({edge}), expected {state}'
    found = []
    for trial in range(1, int(model['trials'][arm]) + 1):
        label = read_label(prefix, arm, trial)
        value = run.values.get(label)
        if value is None:
            return [], missing_measurement(run, label)
        found.append(value > 0)
    return found, None


def worst(statuses: list[str]) -> str:
    for status in ('unmeasured', 'alert', 'insufficient_trials', 'measured'):
        if status in statuses:
            return status
    return 'ok'


def offensive_dispel_resist_verdict(base: Verdict, runs: list[Run], model: dict) -> Verdict:
    counts = {arm: [0, 0] for arm in model['arms']}
    for run in runs:
        for arm in model['arms']:
            found, problem = arm_reads(run, model, arm)
            if problem is not None:
                return replace(base, status='unmeasured', explanation=problem)
            counts[arm][0] += len(found)
            counts[arm][1] += sum(found)
    rates = model['rates']
    statuses, parts, detail = [], [], {}
    for arm in model['arms']:
        trials, survived = counts[arm]
        expected = float(rates[arm])
        status, low, high, why = judged_arm(survived, trials, int(model['minimum'][arm]), expected)
        statuses.append(status)
        detail[arm] = {'trials': trials, 'survived': survived, 'low': low, 'high': high}
        parts.append(f'{arm} survived {survived} of {trials} against {expected:.4f}: {status}, {why}')
    judged = model['arms'][-1]
    trials, survived = counts[judged]
    return replace(base, status=worst(statuses), measured=survived / trials if trials else None,
                   expected=float(rates[judged]), low=detail[judged]['low'], high=detail[judged]['high'],
                   detail={**detail, 'parts': len(runs)}, explanation='; '.join(parts))


def offensive_dispel_resist_single_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    return offensive_dispel_resist_verdict(base, [run], model)


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return offensive_dispel_resist_scenario(class_file, offensive_dispel_resist_spec(entry))


def label(entry: dict) -> list[str]:
    base = f"{entry['spell']} {BEHAVIOUR_METRIC_DELTA} {entry['label_suffix']}"
    return [base, f'{base}_gate_off'] if entry.get('gate_cast') is not None else [base]


JUDGES = {BEHAVIOUR_METRIC_DELTA: offensive_dispel_resist_single_verdict}
POOLED_JUDGE = offensive_dispel_resist_verdict
