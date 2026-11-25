from dataclasses import dataclass, replace
import math
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, hit_ratio_cast, prose_rule, waited_ms
from compare import Run, Verdict, banded_rate, missing_measurement, rate_judgement
from hits import creature_fixture, timed
from procs import Z_99, band_trials_needed, rate_band, wilson_interval
from profile import (CASTER, DBC_DIR, base_steps, measurement, off_hand_steps, off_hand_weapon, one_hand_main,
                     player_fixture)
from tooltip import Records
from values import Expectation, TARGET, armed_for, dataset

KIND = 'aura_keep_rate'
ORDER = 43
MAXIMUM_STEPS = 10000
CONTROL = 'control'
TREATMENT = 'treatment'
KEEP_METRIC = 'aura'


@dataclass(frozen=True)
class AuraKeepRateSpec:
    spell: int
    name: str
    quote: str
    aura: int
    consumer: int
    control_spell: int
    chance_pct: float
    trials: int
    control_trials: int
    control_auras: tuple[tuple[int, int], ...]
    learn: tuple[int, ...]
    off_hand_item: int | None = None
    parts: int = 1
    label_suffix: str = 'keep_rate'
    aura_stacks: int = 1


def aura_keep_rate_spec(entry: dict) -> AuraKeepRateSpec:
    spec = AuraKeepRateSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['aura']),
                            int(entry['consumer']), int(entry['control_spell']), float(entry['chance_pct']),
                            int(entry['trials']), int(entry['control_trials']),
                            tuple((int(spell), int(stacks)) for spell, stacks in entry.get('control_auras', ())),
                            tuple(int(spell) for spell in entry.get('learn', ())),
                            None if entry.get('off_hand_item') is None else int(entry['off_hand_item']),
                            int(entry.get('parts', 1)), entry.get('label_suffix', 'keep_rate'),
                            int(entry.get('aura_stacks', 1)))
    if spec.aura_stacks < 1:
        raise ValueError(f'{spec.spell} {KIND} sets aura_stacks of at least 1')
    if not 0 < spec.chance_pct < 100 or spec.trials < 1 or spec.control_trials < 1:
        raise ValueError(f'{spec.spell} {KIND} needs a keep chance below 100%, trials and control trials')
    if spec.control_spell == spec.consumer:
        raise ValueError(f'{spec.spell} {KIND} needs a control spell other than the consumer {spec.consumer}')
    return spec


def residual_failure(chance: float, trials: int) -> float | None:
    spread = math.sqrt(chance * (1 - chance) / trials)
    margin = rate_band(chance) - Z_99 * spread
    return math.erfc(margin / spread / math.sqrt(2)) if margin > 0 else None


def sizing_sentence(spec: AuraKeepRateSpec) -> str:
    chance, total = spec.chance_pct / 100, spec.trials * spec.parts
    needed = band_trials_needed(chance)
    residual = residual_failure(chance, total)
    if total < needed or residual is None:
        return (f' {total} casts over {spec.parts} part(s) are fewer than the {needed} the band needs: G-20 step 1, '
                f'effect present with its interval, not final.')
    return (f' {total} casts over {spec.parts} parts (the band needs {needed}): at a true {spec.chance_pct:g}% a '
            f'conformant server leaves the band with probability {residual:.1e} per run (normal approximation).')


def fixture_sentence(spec: AuraKeepRateSpec) -> str:
    return f' {spec.aura} is set at {spec.aura_stacks} stacks, the consumer\'s cost.' if spec.aura_stacks != 1 else ''


def label_prefix(spell: int, suffix: str) -> str:
    return f'{spell} {BEHAVIOUR_METRIC_DELTA} {suffix}'


def keep_label(prefix: str, arm: str, trial: int, read: str) -> str:
    return f'{prefix} {arm} {trial} {read}'


def trial_steps(records: Records, spec: AuraKeepRateSpec, arm: str, trial: int) -> list[dict]:
    spell = spec.consumer if arm == TREATMENT else spec.control_spell
    fixtures = [] if arm == TREATMENT else [{'action': 'set_aura', 'actor': CASTER, 'spell': aura, 'stacks': stacks}
                                            for aura, stacks in spec.control_auras]
    prefix = label_prefix(spec.spell, spec.label_suffix)
    return (fixtures + [{'action': 'set_aura', 'actor': CASTER, 'spell': spec.aura, 'stacks': spec.aura_stacks}]
             + hit_ratio_cast(records, spell)
             + [measurement(keep_label(prefix, arm, trial, 'aura'), CASTER, KEEP_METRIC, spell=spec.aura),
                measurement(keep_label(prefix, arm, trial, 'cast'), CASTER, 'cast_failure', spell=spell)])


def aura_keep_rate_scenario(class_file: dict, spec: AuraKeepRateSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, spec.chance_pct)
    equip = []
    if spec.off_hand_item is None:
        class_file = armed_for(class_file, records, spec.consumer)
    else:
        off_hand_weapon(class_file, spec.off_hand_item)
        class_file = one_hand_main(class_file)
        if class_file is None:
            raise ValueError(f'{spec.spell} {KIND} dual wields, which needs a one-handed main-hand weapon')
        equip = off_hand_steps(spec.off_hand_item)
    steps = base_steps(class_file) + equip + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                                      for spell in (*spec.learn, spec.consumer, spec.control_spell)]
    for arm, count in ((CONTROL, spec.control_trials), (TREATMENT, spec.trials)):
        for trial in range(1, count + 1):
            steps += trial_steps(records, spec, arm, trial)
    if len(steps) > MAXIMUM_STEPS:
        raise ValueError(f'{spec.spell} {KIND} needs {len(steps)} steps, more than {MAXIMUM_STEPS}')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour aura keep rate',
        'contract': (f'{spec.aura} is set on the caster (harness set_aura, the precondition fixture) before every '
                     f'cast and read on the caster after it. Control: {spec.control_trials} casts of '
                     f'{spec.control_spell} at the dummy keep it every time. Treatment: {spec.trials} casts of '
                     f'{spec.consumer} at the dummy keep it with {spec.chance_pct:g}% chance. A cast that failed is '
                     f'no trial. Pooled over the parts, the kept share must hold {spec.chance_pct:g}% in a Wilson '
                     f'99% interval inside the G-20 band.' + fixture_sentence(spec) + sizing_sentence(spec)),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {'kind': KIND, 'metric': KEEP_METRIC, 'quote': entry.quote, 'chance_pct': spec.chance_pct,
             'minimum_trials': band_trials_needed(spec.chance_pct / 100),
             'prefix': label_prefix(spec.spell, spec.label_suffix), 'aura': spec.aura,
             'arms': {CONTROL: spec.control_trials, TREATMENT: spec.trials}}
    expectation = Expectation(label_prefix(spec.spell, spec.label_suffix), BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.consumer, None, f'{spec.chance_pct:g}%',
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def counted_trials(run: Run, model: dict) -> tuple[dict, str | None]:
    counts = {CONTROL: [0, 0, 0], TREATMENT: [0, 0, 0]}
    for arm, count in model['arms'].items():
        for trial in range(1, count + 1):
            aura, cast = (keep_label(model['prefix'], arm, trial, read) for read in ('aura', 'cast'))
            for read in (aura, cast):
                if run.values.get(read) is None:
                    return counts, missing_measurement(run, read)
            tally = counts[arm]
            if run.values[cast] != 0:
                tally[2] += 1
                continue
            tally[0] += 1
            tally[1] += run.values[aura] != 0
    return counts, None


def keep_rate_verdict(base: Verdict, runs: list[Run], model: dict) -> Verdict:
    control, treatment = [0, 0, 0], [0, 0, 0]
    for run in runs:
        counts, problem = counted_trials(run, model)
        if problem is not None:
            return replace(base, status='unmeasured', explanation=problem)
        control = [total + add for total, add in zip(control, counts[CONTROL])]
        treatment = [total + add for total, add in zip(treatment, counts[TREATMENT])]
    detail = {'control_trials': control[0], 'control_kept': control[1], 'control_failed': control[2],
              'trials': treatment[0], 'kept': treatment[1], 'failed': treatment[2], 'parts': len(runs)}
    if control[0] == 0 or control[1] != control[0]:
        return replace(base, status='unmeasured' if control[0] == 0 else 'alert', detail=detail,
                       explanation=f'control: {control[1]} of {control[0]} casts kept the aura '
                                   f'({control[2]} failed casts); every control cast must keep it')
    expected = float(model['chance_pct']) / 100
    minimum = int(model['minimum_trials'])
    kept, trials = treatment[1], treatment[0]
    status, low, high, why = rate_judgement(kept, trials, minimum, expected)
    if status == 'insufficient_trials':
        low, high = wilson_interval(kept, trials)
        why = (f'rate {kept / trials:.4f}, Wilson 99% interval [{low:.4f}, {high:.4f}]: {why} (G-20 step 1, '
               f'effect present, interval stated, not final)')
    elif low is not None:
        status, low, high, why = banded_rate(status, low, high, expected, why)
    return replace(base, status=status, measured=kept / trials if trials > 0 else None, expected=expected,
                   low=low, high=high, detail=detail,
                   explanation=f'{model["aura"]} set by harness set_aura before every cast (precondition fixture); '
                               f'control kept it in {control[1]} of {control[0]} casts; {kept:g} of {trials:g} '
                               f'casts of the consumer kept it ({treatment[2]} failed casts left out): {why}')


def keep_rate_single_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    return keep_rate_verdict(base, [run], model)


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return aura_keep_rate_scenario(class_file, aura_keep_rate_spec(entry))


def label(entry: dict) -> list[str]:
    return [label_prefix(entry['spell'], entry.get('label_suffix', 'keep_rate'))]


JUDGES = {BEHAVIOUR_METRIC_DELTA: keep_rate_single_verdict}
POOLED_JUDGE = keep_rate_verdict
