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
from values import MAX_SCENARIO_STEPS, Expectation, dataset

KIND = 'debuff_resist_rate'
ORDER = 55
RATE, LOCKOUT = 'rate', 'lockout'
CONTROL, TREATMENT, LOW_HEALTH = 'control', 'treatment', 'low_health'
LOCKED, EXPIRY = 'locked', 'expiry'
STRIKER_ENTRY = 36
CASTER_HEALTH = 1_000_000
STRIKE_WAIT_MS = 300
DEFAULT_RESIDUAL = 1e-3
TAIL_SDS = 14
PAIR_RUNS = 2
RATE_ARMS = (CONTROL, TREATMENT, LOW_HEALTH)
HOLD_GROUPS = ('primed', 'unprimed', 'share')


@dataclass(frozen=True)
class DebuffResistRateSpec:
    spell: int
    name: str
    quote: str
    label_suffix: str
    mode: str
    strike_spell: int
    base_chance_pct: float
    clear_auras: tuple[int, ...]
    striker_level: int | None
    parts: int
    residual: float
    low_health_pct: int = 0
    lockout_aura: int = 0
    lockout_ms: int = 0
    locked_gap_ms: int = 0
    locked_trials: int = 0
    expiry_trials: int = 0
    expiry_margin_ms: int = 0


def boosted(chance: float) -> float:
    return 1 - (1 - chance) ** 2


def residual_z(residual: float) -> float:
    return NormalDist().inv_cdf(1 - residual / 2)


def band_trials(chance: float, residual: float) -> int:
    return math.ceil(chance * (1 - chance) * ((Z_99 + residual_z(residual)) / rate_band(chance)) ** 2)


def binomial_pmf(events: int, trials: int, chance: float) -> float:
    return math.exp(math.lgamma(trials + 1) - math.lgamma(events + 1) - math.lgamma(trials - events + 1)
                    + events * math.log(chance) + (trials - events) * math.log(1 - chance))


@cache
def exact_false_fail(trials: int, chance: float) -> float:
    spread = TAIL_SDS * math.sqrt(trials * chance * (1 - chance))
    low, high = max(0, int(trials * chance - spread)), min(trials, int(trials * chance + spread))
    return sum(binomial_pmf(resisted, trials, chance) for resisted in range(low, high + 1)
               if judged_rate(resisted, trials, trials, chance)[0] != 'ok')


@cache
def split_trials(chance: float, residual: float, parts: int) -> int:
    per_part = math.ceil(band_trials(chance, residual) / parts)
    while exact_false_fail(per_part * parts, chance) > residual:
        per_part += 1
    return per_part


def exclusion_trials(expected: float, other: float, residual: float) -> int:
    spread = max(expected * (1 - expected), other * (1 - other))
    return math.ceil(spread * ((2 * Z_99 + residual_z(residual)) / abs(expected - other)) ** 2)


def primed_share(chance: float) -> float:
    return (1 - chance) * chance


def arm_residual(residual: float) -> float:
    return residual / (PAIR_RUNS * len(RATE_ARMS))


def hold_residual(residual: float) -> float:
    return residual / (2 * PAIR_RUNS * len(HOLD_GROUPS))


def count_shortfall(trials: int, share: float, minimum: int) -> float:
    return NormalDist(trials * share, math.sqrt(trials * share * (1 - share))).cdf(minimum - 0.5)


def exclusion_failure(residual: float) -> float:
    return NormalDist().cdf(-(Z_99 + residual_z(residual)))


def debuff_resist_rate_spec(entry: dict) -> DebuffResistRateSpec:
    mode = entry.get('mode', RATE)
    spec = DebuffResistRateSpec(
        int(entry['spell']), entry['name'], entry['quote'], entry['label_suffix'], mode,
        int(entry['strike_spell']), float(entry['base_chance_pct']),
        tuple(int(aura) for aura in entry.get('clear_auras', ())),
        None if entry.get('striker_level') is None else int(entry['striker_level']), int(entry.get('parts', 1)),
        float(entry.get('residual', DEFAULT_RESIDUAL)), int(entry.get('low_health_pct', 0)),
        int(entry.get('lockout_aura', 0)), int(entry.get('lockout_ms', 0)), int(entry.get('locked_gap_ms', 0)),
        int(entry.get('locked_trials', 0)), int(entry.get('expiry_trials', 0)),
        int(entry.get('expiry_margin_ms', 0)))
    if mode not in (RATE, LOCKOUT):
        raise ValueError(f'{spec.spell} {KIND} mode is {RATE!r} or {LOCKOUT!r}, not {mode!r}')
    if not 0 < spec.base_chance_pct < 50 or spec.parts < 1 or not 0 < spec.residual < 1:
        raise ValueError(f'{spec.spell} {KIND} needs a base chance in (0, 50), parts and a residual in (0, 1)')
    if mode == RATE and not 0 < spec.low_health_pct < 100:
        raise ValueError(f'{spec.spell} {KIND} rate mode needs low_health_pct in (0, 100)')
    if mode == LOCKOUT and (spec.lockout_aura <= 0 or spec.lockout_ms <= 0 or spec.locked_gap_ms <= 0
                            or spec.locked_trials < 1 or spec.expiry_trials < 1
                            or not 0 < spec.expiry_margin_ms < spec.lockout_ms):
        raise ValueError(f'{spec.spell} {KIND} lockout mode needs lockout_aura, lockout_ms, locked_gap_ms, '
                         f'locked_trials, expiry_trials and an expiry margin inside the lockout')
    return spec


def check_label(spec: DebuffResistRateSpec, suffix: str = '') -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}{suffix}'


def read_label(prefix: str, arm: str, trial: int, read: str) -> str:
    return f'{prefix} {arm} {trial} {read}'


def clear_steps(spec: DebuffResistRateSpec) -> list[dict]:
    return [{'action': 'set_aura', 'actor': CASTER, 'spell': aura, 'stacks': 0}
            for aura in (*spec.clear_auras, spec.strike_spell)]


def health_step(pct: int) -> dict:
    return {'action': 'set_health', 'actor': CASTER, 'value': CASTER_HEALTH * pct // 100, 'maximum': CASTER_HEALTH}


def strike_steps(spec: DebuffResistRateSpec, label: str) -> list[dict]:
    return [{'action': 'cast', 'actor': STRIKER, 'spell': spec.strike_spell, 'target': CASTER},
            {'action': 'wait', 'label': f'{KIND} strike', 'ms': STRIKE_WAIT_MS},
            measurement(label, CASTER, 'aura', spell=spec.strike_spell)]


def rate_arm_steps(spec: DebuffResistRateSpec, arm: str, trials: int) -> list[dict]:
    prefix = check_label(spec)
    steps = []
    for trial in range(1, trials + 1):
        steps += clear_steps(spec) + [health_step(spec.low_health_pct if arm == LOW_HEALTH else 100)]
        steps += strike_steps(spec, read_label(prefix, arm, trial, 'applied'))
    return steps + clear_steps(spec)


def rate_trials(spec: DebuffResistRateSpec) -> dict:
    base = spec.base_chance_pct / 100
    residual = arm_residual(spec.residual)
    control = split_trials(base, residual, spec.parts)
    return {CONTROL: control, TREATMENT: split_trials(boosted(base), residual, spec.parts),
            LOW_HEALTH: control}


def rate_chances(spec: DebuffResistRateSpec) -> dict:
    base = spec.base_chance_pct / 100
    return {CONTROL: base, TREATMENT: boosted(base), LOW_HEALTH: base}


def rate_risk(spec: DebuffResistRateSpec) -> dict:
    trials, chances = rate_trials(spec), rate_chances(spec)
    arms = {arm: exact_false_fail(trials[arm] * spec.parts, chances[arm]) for arm in RATE_ARMS}
    return {**arms, 'total': PAIR_RUNS * sum(arms.values())}


def lockout_trial_steps(spec: DebuffResistRateSpec, arm: str, trial: int) -> list[dict]:
    prefix = check_label(spec)
    steps = clear_steps(spec) + [health_step(100)]
    steps += strike_steps(spec, read_label(prefix, arm, trial, 'prime applied'))
    steps.append(measurement(read_label(prefix, arm, trial, 'primed'), CASTER, 'aura', spell=spec.lockout_aura))
    steps.append({'action': 'set_aura', 'actor': CASTER, 'spell': spec.strike_spell, 'stacks': 0})
    if arm == LOCKED:
        steps += [{'action': 'wait', 'label': f'{KIND} locked gap', 'ms': spec.locked_gap_ms}, health_step(100)]
        return steps + strike_steps(spec, read_label(prefix, arm, trial, 'applied'))
    inside = spec.lockout_ms - spec.expiry_margin_ms - STRIKE_WAIT_MS
    steps += [{'action': 'wait', 'label': f'{KIND} inside the lockout', 'ms': inside},
              measurement(read_label(prefix, arm, trial, 'held'), CASTER, 'aura', spell=spec.lockout_aura),
              {'action': 'wait', 'label': f'{KIND} past the lockout', 'ms': 2 * spec.expiry_margin_ms},
              measurement(read_label(prefix, arm, trial, 'ended'), CASTER, 'aura', spell=spec.lockout_aura)]
    return steps


def scenario_steps(class_file: dict, spec: DebuffResistRateSpec) -> list[dict]:
    steps = base_steps(class_file)
    if spec.mode == RATE:
        trials = rate_trials(spec)
        steps += rate_arm_steps(spec, CONTROL, trials[CONTROL])
        steps.append({'action': 'learn', 'actor': CASTER, 'spell': spec.spell})
        steps += rate_arm_steps(spec, TREATMENT, trials[TREATMENT])
        return steps + rate_arm_steps(spec, LOW_HEALTH, trials[LOW_HEALTH])
    steps.append({'action': 'learn', 'actor': CASTER, 'spell': spec.spell})
    for arm, count in ((LOCKED, spec.locked_trials), (EXPIRY, spec.expiry_trials)):
        for trial in range(1, count + 1):
            steps += lockout_trial_steps(spec, arm, trial)
    return steps + clear_steps(spec)


def residual_text(residual: float) -> str:
    return f'{residual:.1e}'


def rate_contract(spec: DebuffResistRateSpec) -> str:
    base = spec.base_chance_pct / 100
    trials, risk = rate_trials(spec), rate_risk(spec)
    return (f'A stationary striker (creature {STRIKER_ENTRY}, no spell hit bonus) casts {spec.strike_spell} at the '
            f'caster once per trial; the trial reads whether it took hold {STRIKE_WAIT_MS} ms later and removes it, '
            f'and removes {list(spec.clear_auras)} before every strike. Control: {trials[CONTROL]} trials before '
            f'{spec.spell} is learned, resisted at the stock chance {base:.4f}. Then {spec.spell} is learned (a real '
            f'learn). Treatment: {trials[TREATMENT]} trials at full health, resisted at {boosted(base):.4f} '
            f'(1 - (1 - p)^2, the second stock roll). Low health: {trials[LOW_HEALTH]} trials at '
            f'{spec.low_health_pct}% health, resisted at the stock chance. Each arm is pooled over {spec.parts} '
            f'part(s) and judged by its Wilson 99% interval inside the G-20 band; each arm is sized so that a '
            f'conformant server leaves its band with probability at most '
            f'{residual_text(arm_residual(spec.residual))} per run, exact binomial through the judge: control '
            f'{residual_text(risk[CONTROL])}, treatment {residual_text(risk[TREATMENT])}, low health '
            f'{residual_text(risk[LOW_HEALTH])} per run, {residual_text(risk["total"])} for the {len(RATE_ARMS)} arms '
            f'over a pair of {PAIR_RUNS} runs')


def lockout_minimum(spec: DebuffResistRateSpec) -> dict:
    base = spec.base_chance_pct / 100
    return {'primed': exclusion_trials(base, boosted(base), spec.residual),
            'unprimed': exclusion_trials(boosted(base), base, spec.residual)}


def lockout_risk(spec: DebuffResistRateSpec) -> dict:
    share, trials = primed_share(spec.base_chance_pct / 100), spec.locked_trials * spec.parts
    minimum = lockout_minimum(spec)
    risk = {'holds': PAIR_RUNS * len(HOLD_GROUPS) * hold_residual(spec.residual),
            'shortfall': PAIR_RUNS * (count_shortfall(trials, share, minimum['primed'])
                                      + count_shortfall(trials, 1 - share, minimum['unprimed'])),
            'exclusion': PAIR_RUNS * 2 * exclusion_failure(spec.residual)}
    return {**risk, 'total': sum(risk.values())}


def lockout_contract(spec: DebuffResistRateSpec) -> str:
    base = spec.base_chance_pct / 100
    risk, minimum = lockout_risk(spec), lockout_minimum(spec)
    hold = residual_z(hold_residual(spec.residual))
    return (f'{spec.spell} is learned (a real learn) and the caster is at full health. A stationary striker '
            f'(creature {STRIKER_ENTRY}, level {spec.striker_level}, no spell hit bonus) casts a priming '
            f'{spec.strike_spell} at the caster after {list(spec.clear_auras)} are removed; the trial is primed when '
            f'{spec.lockout_aura} is on the caster {STRIKE_WAIT_MS} ms later. Locked arm: {spec.locked_trials} trials '
            f'per part, the judged {spec.strike_spell} {spec.locked_gap_ms} ms after the primed read: on primed '
            f'trials it is resisted at the stock chance {base:.4f} (no second roll during the lockout), on the others '
            f'at {boosted(base):.4f}; each group\'s Wilson interval at z {hold:.2f} must hold its own chance and its '
            f'Wilson 99% interval must exclude the other, and the primed share of the locked trials must sit in its '
            f'z {hold:.2f} interval around (1 - p) p = {primed_share(base):.4f} (the lockout starts only when the '
            f'second roll resists). Expiry arm: {spec.expiry_trials} trials per part; on primed trials '
            f'{spec.lockout_aura} must be on the caster {spec.lockout_ms - spec.expiry_margin_ms} ms after the '
            f'priming strike and gone at {spec.lockout_ms + spec.expiry_margin_ms} ms. Pooled over {spec.parts} '
            f'part(s); a group below its minimum ({minimum["primed"]} primed, {minimum["unprimed"]} unprimed '
            f'trials) is insufficient_trials. A conformant server '
            f'fails the locked label with probability at most {residual_text(risk["total"])} per pair of '
            f'{PAIR_RUNS} runs (normal approximation): {residual_text(risk["holds"])} from the '
            f'{len(HOLD_GROUPS)} holds, {residual_text(risk["shortfall"])} from a group count below its minimum, '
            f'{residual_text(risk["exclusion"])} from an interval that keeps the other chance')


def debuff_resist_rate_scenario(class_file: dict, spec: DebuffResistRateSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, spec.base_chance_pct)
    steps = scenario_steps(class_file, spec)
    if len(steps) > MAX_SCENARIO_STEPS:
        raise ValueError(f'{spec.spell} {KIND} takes {len(steps)} steps, above {MAX_SCENARIO_STEPS}: add parts')
    if spec.mode == RATE and rate_risk(spec)['total'] > spec.residual:
        raise ValueError(f'{spec.spell} {KIND} fails a conformant pair with probability '
                         f'{residual_text(rate_risk(spec)["total"])}, above {residual_text(spec.residual)}')
    if spec.mode == LOCKOUT and lockout_risk(spec)['total'] > spec.residual:
        raise ValueError(f'{spec.spell} {KIND} fails a conformant pair with probability '
                         f'{residual_text(lockout_risk(spec)["total"])}, above {residual_text(spec.residual)}: '
                         f'add locked_trials')
    level = class_file['level'] if spec.striker_level is None else spec.striker_level
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour debuff resist rate',
        'contract': rate_contract(spec) if spec.mode == RATE else lockout_contract(spec),
        'players': [{**player_fixture(class_file), 'allow_regeneration': False}],
        'creatures': [{'id': STRIKER, 'owner': CASTER, 'entry': STRIKER_ENTRY, 'level': level,
                       'health': STRIKER_HEALTH, 'distance': STRIKER_DISTANCE, 'stationary': True}],
        'steps': steps}
    base = spec.base_chance_pct / 100
    common = {'kind': KIND, 'metric': 'aura', 'quote': entry.quote, 'prefix': check_label(spec), 'base': base,
              'boosted': boosted(base), 'mode': spec.mode}
    rule = prose_rule(entry.quote, spec.spell)
    if spec.mode == RATE:
        trials = rate_trials(spec)
        minimum = {arm: count * spec.parts for arm, count in trials.items()}
        model = {**common, 'trials': trials, 'minimum': minimum}
        expectations = [
            Expectation(check_label(spec), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.strike_spell, None,
                        f'{boosted(base):.4f}', rule, {**model, 'arms': [CONTROL, TREATMENT]}),
            Expectation(check_label(spec, '_low_health'), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.strike_spell,
                        None, f'{base:.4f}', rule, {**model, 'arms': [CONTROL, LOW_HEALTH]})]
    else:
        model = {**common, 'trials': {LOCKED: spec.locked_trials, EXPIRY: spec.expiry_trials},
                 'minimum': lockout_minimum(spec), 'share': primed_share(base),
                 'hold_z': residual_z(hold_residual(spec.residual))}
        expectations = [
            Expectation(check_label(spec), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.strike_spell, None,
                        f'{base:.4f}', rule, {**model, 'arms': [LOCKED]}),
            Expectation(check_label(spec, '_expiry'), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.lockout_aura, None,
                        str(spec.lockout_ms), rule, {**model, 'arms': [EXPIRY]})]
    return timed(scenario, waited_ms(steps), MAX_SCENARIO_MS), expectations


def arm_reads(run: Run, model: dict, arm: str, reads: tuple[str, ...]) -> tuple[list[dict], str | None]:
    found = []
    for trial in range(1, model['trials'][arm] + 1):
        values = {}
        for read in reads:
            label = read_label(model['prefix'], arm, trial, read)
            if run.values.get(label) is None:
                return [], missing_measurement(run, label)
            values[read] = run.values[label] > 0
        found.append(values)
    return found, None


def judged_rate(resisted: int, trials: int, minimum: int, expected: float) -> tuple[str, float | None,
                                                                                   float | None, str]:
    status, low, high, why = rate_judgement(resisted, trials, minimum, expected)
    if status == 'insufficient_trials' and trials > 0:
        low, high = wilson_interval(resisted, trials)
        return status, low, high, f'rate {resisted / trials:.4f} [{low:.4f}, {high:.4f}]: {why}'
    if low is not None:
        return banded_rate(status, low, high, expected, why)
    return status, low, high, why


def worst(statuses: list[str]) -> str:
    for status in ('unmeasured', 'alert', 'insufficient_trials', 'measured'):
        if status in statuses:
            return status
    return 'ok'


def rate_verdict(base: Verdict, runs: list[Run], model: dict) -> Verdict:
    counts = {arm: [0, 0] for arm in model['arms']}
    for run in runs:
        for arm in model['arms']:
            found, problem = arm_reads(run, model, arm, ('applied',))
            if problem:
                return replace(base, status='unmeasured', explanation=problem)
            counts[arm][0] += len(found)
            counts[arm][1] += sum(not trial['applied'] for trial in found)
    expected = {CONTROL: model['base'], TREATMENT: model['boosted'], LOW_HEALTH: model['base']}
    statuses, parts, detail = [], [], {}
    for arm in model['arms']:
        trials, resisted = counts[arm]
        status, low, high, why = judged_rate(resisted, trials, int(model['minimum'][arm]), expected[arm])
        statuses.append(status)
        detail[arm] = {'trials': trials, 'resisted': resisted, 'low': low, 'high': high}
        parts.append(f'{arm} resisted {resisted} of {trials} against {expected[arm]:.4f}: {status}, {why}')
    judged = model['arms'][-1]
    trials, resisted = counts[judged]
    return replace(base, status=worst(statuses), measured=resisted / trials if trials else None,
                   expected=expected[judged], low=detail[judged]['low'], high=detail[judged]['high'],
                   detail={**detail, 'parts': len(runs)}, explanation='; '.join(parts))


def exclusion_status(resisted: int, trials: int, minimum: int, expected: float, other: float,
                     hold_z: float) -> tuple[str, str]:
    if trials == 0:
        return 'unmeasured', 'no trial'
    low, high = wilson_interval(resisted, trials)
    hold_low, hold_high = wilson_interval(resisted, trials, hold_z)
    text = (f'rate {resisted / trials:.4f}, {trials} trials, Wilson 99% [{low:.4f}, {high:.4f}], z {hold_z:.2f} '
            f'[{hold_low:.4f}, {hold_high:.4f}]')
    if not hold_low <= expected <= hold_high:
        return 'alert', f'{text}: the z {hold_z:.2f} interval excludes {expected:.4f}'
    if trials < minimum:
        return 'insufficient_trials', f'{text}: fewer than the {minimum} trials that exclude {other:.4f}'
    if low <= other <= high:
        return 'insufficient_trials', f'{text}: the 99% interval keeps {other:.4f}'
    return 'ok', f'{text}: holds {expected:.4f} and excludes {other:.4f}'


def share_status(primed: int, trials: int, share: float, hold_z: float) -> tuple[str, str]:
    if trials == 0:
        return 'unmeasured', 'no trial'
    low, high = wilson_interval(primed, trials, hold_z)
    text = f'primed {primed} of {trials} trials, share {primed / trials:.4f}, z {hold_z:.2f} [{low:.4f}, {high:.4f}]'
    if not low <= share <= high:
        return 'alert', f'{text} excludes (1 - p) p = {share:.4f}'
    return 'ok', f'{text} holds (1 - p) p = {share:.4f}'


def locked_verdict(base: Verdict, runs: list[Run], model: dict) -> Verdict:
    tally = {'primed': [0, 0], 'unprimed': [0, 0]}
    for run in runs:
        found, problem = arm_reads(run, model, LOCKED, ('primed', 'applied'))
        if problem:
            return replace(base, status='unmeasured', explanation=problem)
        for trial in found:
            group = tally['primed' if trial['primed'] else 'unprimed']
            group[0] += 1
            group[1] += not trial['applied']
    expected = {'primed': (model['base'], model['boosted']), 'unprimed': (model['boosted'], model['base'])}
    statuses, parts = [], []
    for group, (trials, resisted) in tally.items():
        status, why = exclusion_status(resisted, trials, int(model['minimum'][group]), *expected[group],
                                       model['hold_z'])
        statuses.append(status)
        parts.append(f'{group} trials: {why}')
    primed, unprimed = tally['primed'][0], tally['unprimed'][0]
    status, why = share_status(primed, primed + unprimed, model['share'], model['hold_z'])
    statuses.append(status)
    parts.append(why)
    trials, resisted = tally['primed']
    return replace(base, status=worst(statuses), measured=resisted / trials if trials else None,
                   expected=model['base'], detail={'primed': tally['primed'], 'unprimed': tally['unprimed'],
                                                   'share': primed / (primed + unprimed) if primed + unprimed
                                                   else None, 'parts': len(runs)},
                   explanation='; '.join(parts))


def expiry_verdict(base: Verdict, runs: list[Run], model: dict) -> Verdict:
    primed = held = ended = 0
    for run in runs:
        found, problem = arm_reads(run, model, EXPIRY, ('primed', 'held', 'ended'))
        if problem:
            return replace(base, status='unmeasured', explanation=problem)
        for trial in found:
            if trial['primed']:
                primed += 1
                held += trial['held']
                ended += not trial['ended']
    text = (f'{primed} primed trials: the lockout aura held inside the lockout in {held} and was gone after it in '
            f'{ended}; every primed trial must show both')
    if primed == 0:
        return replace(base, status='insufficient_trials', explanation=f'no primed trial; {text}')
    status = 'ok' if held == primed and ended == primed else 'alert'
    return replace(base, status=status, measured=float(primed), detail={'primed': primed, 'held': held,
                                                                       'ended': ended, 'parts': len(runs)},
                   explanation=text)


def debuff_resist_rate_verdict(base: Verdict, runs: list[Run], model: dict) -> Verdict:
    if model['mode'] == RATE:
        return rate_verdict(base, runs, model)
    return locked_verdict(base, runs, model) if model['arms'] == [LOCKED] else expiry_verdict(base, runs, model)


def debuff_resist_rate_single_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    return debuff_resist_rate_verdict(base, [run], model)


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return debuff_resist_rate_scenario(class_file, debuff_resist_rate_spec(entry))


def label(entry: dict) -> list[str]:
    base = f"{entry['spell']} {BEHAVIOUR_METRIC_DELTA} {entry['label_suffix']}"
    return [base, f'{base}_low_health' if entry.get('mode', RATE) == RATE else f'{base}_expiry']


JUDGES = {BEHAVIOUR_METRIC_DELTA: debuff_resist_rate_single_verdict}
POOLED_JUDGE = debuff_resist_rate_verdict
