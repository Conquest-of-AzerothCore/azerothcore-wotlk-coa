from dataclasses import dataclass, replace
import math
from pathlib import Path

from behaviours import (BEHAVIOUR_METRIC_DELTA, STRIKER, MetricDeltaStrike, behaviour_entry, prose_rule,
                        required_aura_steps, striker_creature, waited_ms)
from compare import NO_CAST_FAILURE, Run, Verdict, describe_failures, missing_measurement
from hits import timed
from procs import Z_99, wilson_interval
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, dataset, facts_of

KIND = 'block_extension_trials'
ORDER = 51
BLOCK_SPELL = 107
OFF_HAND_SLOT = 16
STRIKE_HEALTH = 50000
STRIKE_MAX_HEALTH = 100000
STRIKE_SETTLE_MS = 300
PASSIVE = 0
TIME_MARGIN = 0.1
BASE_READS = (-0.108, -0.083, 0.083, 0.108)
EXTENDED_READS = (-0.175, -0.05, 0.025, 0.175)
TIME_METRIC = 'game_time_ms'
BLOCKS = (0, 100)
MIN_UNBLOCKED_TRIALS = 24
EXTENSION_MODE = 'extension'
GRANT_MODE = 'grant'
GRANT_KEYS = frozenset({'spell', 'kind', 'mode', 'name', 'quote', 'aura', 'shield', 'strike_spell', 'trials',
                       'control_trials', 'parts', 'block', 'chance_pct', 'half_width_points', 'label_suffix',
                       'void_on_cast_failure', 'observe_source', 'variant', 'duration_spell', 'duration_effect',
                       'min_granted', 'residual_target'})
DURATION_WINDOWS = {'held': (0.905, 0.965), 'gone': (1.035, 1.095)}
DURATION_READS = {'held': 0.93, 'gone': 1.07}
PAIR_RUNS = 2
MAXIMUM_STEPS = 10000
GRANT_STEPS_PER_TRIAL = 9
CONTROL_ARM = 'control'
TREATMENT_ARM = 'treatment'
EXTENSION_KEYS = frozenset({'spell', 'kind', 'name', 'quote', 'aura', 'extension_spell', 'extension_effect', 'shield',
                  'strike_spell', 'cast_power', 'trials', 'label_suffix', 'void_on_cast_failure', 'observe_source', 'block', 'mode', 'variant'})


@dataclass(frozen=True)
class BlockExtensionSpec:
    spell: int
    name: str
    quote: str
    aura: int
    extension_spell: int
    extension_effect: int
    shield: int
    strike_spell: int
    cast_power: int
    trials: int
    label_suffix: str
    void_on_cast_failure: bool
    block: int = 100


def block_extension_spec(entry: dict) -> BlockExtensionSpec:
    unknown = set(entry) - EXTENSION_KEYS
    if unknown:
        raise ValueError(f'{entry["spell"]} {KIND} does not take {sorted(unknown)}')
    if entry.get('mode', EXTENSION_MODE) != EXTENSION_MODE:
        raise ValueError(f'{entry["spell"]} {KIND} mode is {EXTENSION_MODE} or {GRANT_MODE}, not {entry["mode"]!r}')
    trials = entry['trials']
    if isinstance(trials, bool) or not isinstance(trials, int) or trials < 1:
        raise ValueError(f'{entry["spell"]} {KIND} trials is a positive whole count, not {trials!r}')
    if entry.get('void_on_cast_failure', False) not in (True, False):
        raise ValueError(f'{entry["spell"]} {KIND} void_on_cast_failure is true or false')
    block = entry.get('block', 100)
    if isinstance(block, bool) or block not in BLOCKS:
        raise ValueError(f'{entry["spell"]} {KIND} block is 0 or 100, not {block!r}')
    if block == 0 and trials < MIN_UNBLOCKED_TRIALS:
        raise ValueError(f'{entry["spell"]} {KIND} block 0 needs at least {MIN_UNBLOCKED_TRIALS} trials')
    return BlockExtensionSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['aura']),
                              int(entry['extension_spell']), int(entry.get('extension_effect', 0)),
                              int(entry['shield']), int(entry['strike_spell']), int(entry['cast_power']), trials,
                              entry.get('label_suffix', KIND), bool(entry.get('void_on_cast_failure', False)), block)


def mark(spec: BlockExtensionSpec, read: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {read}'


def durations(records: Records, spec: BlockExtensionSpec) -> tuple[int, int]:
    base = int(records.duration_ms(spec.aura))
    extension = int(records.single_value(spec.extension_spell, spec.extension_effect))
    if base <= 0 or extension <= 0:
        raise ValueError(f'{spec.spell} {KIND} needs a finite duration on {spec.aura} and a positive extension')
    return base, extension


def bands(base: int, extension: int) -> dict[str, tuple[float, float]]:
    return {'base': (base * (1 - TIME_MARGIN), base * (1 + TIME_MARGIN)),
            'extended': (base + extension * (1 - TIME_MARGIN), base + extension * (1 + TIME_MARGIN))}


def read_offsets(base: int, extension: int) -> list[int]:
    return sorted([round(base * (1 + shift)) for shift in BASE_READS]
                  + [round(base + extension + extension * shift) for shift in EXTENDED_READS])


def contract(spec: BlockExtensionSpec, base: int, extension: int, offsets: list[int], limits: dict) -> str:
    refused = (' A refused cast voids the run: the verdict is unmeasured, never ok or alert.'
               if spec.void_on_cast_failure else '')
    head = (f'Shield {spec.shield} equipped, Block {BLOCK_SPELL} and {spec.spell} learned. Each of {spec.trials} '
            f'trials removes {spec.aura}, casts it on the caster ({base} ms, DurationIndex), forces block to '
            f'{spec.block}% with dodge and parry at 0 (set_combat_avoidance block, owner ruling O-20) and has a '
            f'passive striker (react state 0: the aura\'s own damage on it starts no blocked swing) cast '
            f'{spec.strike_spell} at the caster once. One strike per application: an extension casts nothing, so the '
            f'number of extensions on an application hit several times is unknown and its expiry could not be '
            f'judged. The aura is read with game-time stamps at {offsets} ms after the cast, which bracket its '
            f'expiry. ')
    base_band = f'{limits["base"][0]:g}..{limits["base"][1]:g} ms'
    if spec.block == 0:
        return (head + f'A trial whose strike is not one unblocked hit (a strike blocked anyway counts as void, not as '
                       f'a failure), or whose cast left no aura, is void. Every other trial must expire inside '
                       f'{base_band}; an extended expiry or any other expiry alerts, a bracket straddling a band '
                       f'edge is unmeasured, and fewer than {MIN_UNBLOCKED_TRIALS} judged trials is unmeasured '
                       f'(a 30% extension on every unblocked strike would escape {MIN_UNBLOCKED_TRIALS} judged '
                       f'trials with probability 0.7^{MIN_UNBLOCKED_TRIALS} = '
                       f'{0.7 ** MIN_UNBLOCKED_TRIALS:.1e}).' + refused)
    return (head + f'A trial whose strike is not one blocked hit, or whose cast left no aura, is void. Every other '
                   f'trial must expire inside {base_band} (not extended) or '
                   f'{limits["extended"][0]:g}..{limits["extended"][1]:g} ms (extended by {extension} ms, '
                   f'{spec.extension_spell} Effect[{spec.extension_effect}], +-10%); any other expiry alerts, a '
                   f'bracket straddling a band edge is unmeasured, and no extended trial is unmeasured. The share '
                   f'of extended trials is reported with its 99% interval and not judged.' + refused)


def block_extension_scenario(class_file: dict, spec: BlockExtensionSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, 1.0)
    base, extension = durations(records, spec)
    offsets = read_offsets(base, extension)
    facts = facts_of(records, spec.aura)

    def trial(index: int) -> list[dict]:
        steps = [{'action': 'cancel_aura', 'actor': CASTER, 'spell': spec.aura},
                 {'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': spec.cast_power},
                 {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.aura}]
        steps += [{**step, 'actor': CASTER} for step in required_aura_steps(facts)]
        steps += [{'action': 'cast', 'actor': CASTER, 'spell': spec.aura, 'target': CASTER},
                  measurement(mark(spec, f'{index} cast time'), CASTER, TIME_METRIC),
                  measurement(mark(spec, f'{index} cast aura'), CASTER, 'aura', spell=spec.aura),
                  {'action': 'wait', 'label': f'trial {index} before the strike', 'ms': STRIKE_SETTLE_MS},
                  {'action': 'set_combat_avoidance', 'actor': CASTER, 'dodge': 0, 'parry': 0, 'block': spec.block},
                  {'action': 'set_health', 'actor': CASTER, 'value': STRIKE_HEALTH, 'maximum': STRIKE_MAX_HEALTH},
                  {'action': 'cast', 'actor': STRIKER, 'spell': spec.strike_spell, 'target': CASTER},
                  {'action': 'wait', 'label': f'trial {index} strike', 'ms': STRIKE_SETTLE_MS},
                  measurement(mark(spec, f'{index} blocked'), CASTER, 'spell_damage_count', spell=spec.strike_spell,
                              caster=STRIKER, target=CASTER, blocked=True),
                  measurement(mark(spec, f'{index} unblocked'), CASTER, 'spell_damage_count',
                              spell=spec.strike_spell, caster=STRIKER, target=CASTER, blocked=False)]
        elapsed = 2 * STRIKE_SETTLE_MS
        for read, offset in enumerate(offsets):
            steps += [{'action': 'wait', 'label': f'trial {index} read {read}', 'ms': offset - elapsed},
                      measurement(mark(spec, f'{index} read {read} time'), CASTER, TIME_METRIC),
                      measurement(mark(spec, f'{index} read {read} aura'), CASTER, 'aura', spell=spec.aura)]
            elapsed = offset
        return steps

    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in (BLOCK_SPELL, spec.aura, spec.spell)]
             + [{'action': 'add_item', 'actor': CASTER, 'item': spec.shield},
                {'action': 'equip', 'actor': CASTER, 'item': spec.shield, 'slot': OFF_HAND_SLOT}]
             + [step for index in range(spec.trials) for step in trial(index)])
    limits = bands(base, extension)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour block extension trials',
        'contract': contract(spec, base, extension, offsets, limits),
        'players': [player_fixture(class_file)],
        'creatures': [striker_creature(class_file, MetricDeltaStrike(spec.strike_spell, STRIKE_HEALTH,
                                                                     STRIKE_MAX_HEALTH, reaction=PASSIVE))],
        'steps': steps}
    trials = [{'cast_time': mark(spec, f'{index} cast time'), 'cast_aura': mark(spec, f'{index} cast aura'),
               'blocked': mark(spec, f'{index} blocked'), 'unblocked': mark(spec, f'{index} unblocked'),
               'reads': [{'time': mark(spec, f'{index} read {read} time'),
                          'aura': mark(spec, f'{index} read {read} aura')} for read in range(len(offsets))]}
              for index in range(spec.trials)]
    model = {'kind': KIND, 'metric': 'aura', 'quote': entry.quote, 'base_ms': base, 'extension_ms': extension,
             'bands': {name: list(limit) for name, limit in limits.items()}, 'trials': trials,
             'void_on_cast_failure': spec.void_on_cast_failure, 'block': spec.block}
    expectation = Expectation(mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.aura, None,
                              str(extension), prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def expiry_bracket(reads: list[tuple[float, float]]) -> tuple[float, float | None] | None:
    present = [time for time, aura in reads if aura]
    gone = [time for time, aura in reads if not aura]
    if gone and present and max(present) > min(gone):
        return None
    return (max(present) if present else 0.0), (min(gone) if gone else None)


def classify(bracket: tuple[float, float | None], limits: dict) -> str:
    low, high = bracket
    for name, (start, end) in limits.items():
        if high is not None and low >= start and high <= end:
            return name
    outside = all((high is not None and high <= start) or low >= end for start, end in limits.values())
    return 'alert' if outside else 'unmeasured'


def trial_outcome(run: Run, trial: dict, previous: dict | None, limits: dict, block: int) -> tuple[str, str]:
    blocked, unblocked = (run.values[trial[key]] - (run.values[previous[key]] if previous else 0.0)
                          for key in ('blocked', 'unblocked'))
    wanted = (1, 0) if block else (0, 1)
    if (blocked, unblocked) != wanted or run.values[trial['cast_aura']] != 1:
        return 'void', f'{blocked:g} blocked and {unblocked:g} unblocked hits, aura after the cast ' \
                       f'{run.values[trial["cast_aura"]]:g}'
    start = run.values[trial['cast_time']]
    reads = [(run.values[read['time']] - start, run.values[read['aura']]) for read in trial['reads']]
    bracket = expiry_bracket(reads)
    if bracket is None:
        return 'alert', f'the aura came back after it was gone: {reads}'
    high = 'still on' if bracket[1] is None else f'{bracket[1]:g}'
    return classify(bracket, limits if block else {'base': limits['base']}), f'expiry in ({bracket[0]:g}, {high}] ms'


def block_extension_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    labels = [label for trial in model['trials'] for key, value in trial.items()
              for label in ([value] if key != 'reads' else [read[part] for read in value for part in read])]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    refused = [reason for reasons in run.cast_failures.values() for reason in reasons if reason != NO_CAST_FAILURE]
    limits = {name: tuple(limit) for name, limit in model['bands'].items()}
    trials = model['trials']
    block = model.get('block', 100)
    outcomes = [trial_outcome(run, trial, trials[index - 1] if index else None, limits, block)
                for index, trial in enumerate(trials)]
    counts = {name: sum(outcome == name for outcome, _ in outcomes)
              for name in ('base', 'extended', 'alert', 'unmeasured', 'void')}
    judged = counts['base'] + counts['extended']
    share = ''
    if judged:
        low, high = wilson_interval(counts['extended'], judged)
        share = f'; extended share {counts["extended"]}/{judged}, 99% interval {low:.3f}..{high:.3f} (not judged)'
    notes = '; '.join(f'trial {index}: {outcome}, {text}' for index, (outcome, text) in enumerate(outcomes)
                      if outcome != 'base')
    explanation = f'trials {counts}{share}; {notes}'
    if model.get('void_on_cast_failure') and refused:
        return replace(base, status='unmeasured', detail=counts,
                       explanation=f'{explanation}; refused casts void the run: {describe_failures(refused)}')
    if counts['alert']:
        status = 'alert'
    elif counts['unmeasured'] or (block and not counts['extended']) or (not block and judged < MIN_UNBLOCKED_TRIALS):
        status = 'unmeasured'
    else:
        status = 'ok'
    return replace(base, status=status, measured=float(counts['extended']), expected=float(model['extension_ms']),
                   detail=counts, explanation=explanation)


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    if entry.get('mode', EXTENSION_MODE) == GRANT_MODE:
        return block_grant_scenario(class_file, block_grant_spec(entry))
    return block_extension_scenario(class_file, block_extension_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', KIND)}"]




@dataclass(frozen=True)
class BlockGrantSpec:
    spell: int
    name: str
    quote: str
    aura: int
    shield: int
    strike_spell: int
    trials: int
    control_trials: int
    parts: int
    block: int
    chance_pct: float | None
    half_width_points: float | None
    label_suffix: str
    void_on_cast_failure: bool
    duration_spell: int = 0
    duration_effect: int = 0
    min_granted: int = 0
    residual_target: float = 0.0


def block_grant_spec(entry: dict) -> BlockGrantSpec:
    unknown = set(entry) - GRANT_KEYS
    if unknown:
        raise ValueError(f'{entry["spell"]} {KIND} mode grant does not take {sorted(unknown)}')
    counts = {key: entry.get(key, default) for key, default in (('trials', None), ('control_trials', 0), ('parts', 1))}
    if any(isinstance(count, bool) or not isinstance(count, int) or count < minimum
           for count, minimum in ((counts['trials'], 1), (counts['control_trials'], 0), (counts['parts'], 1))):
        raise ValueError(f'{entry["spell"]} {KIND} mode grant needs whole trials, control_trials and parts')
    block = entry.get('block', 100)
    if isinstance(block, bool) or block not in BLOCKS:
        raise ValueError(f'{entry["spell"]} {KIND} block is 0 or 100, not {block!r}')
    chance, half_width = entry.get('chance_pct'), entry.get('half_width_points')
    if (chance is None) != (half_width is None) or (chance is not None and (
            block != 100 or not 0 < chance < 100 or not 0 < half_width < 5)):
        raise ValueError(f'{entry["spell"]} {KIND} chance_pct and half_width_points go together, at block 100')
    if chance is None and counts['trials'] * counts['parts'] < MIN_UNBLOCKED_TRIALS:
        raise ValueError(f'{entry["spell"]} {KIND} mode grant at block 0 needs {MIN_UNBLOCKED_TRIALS} trials')
    if entry.get('void_on_cast_failure', False) not in (True, False):
        raise ValueError(f'{entry["spell"]} {KIND} void_on_cast_failure is true or false')
    timed_keys = {'duration_spell', 'min_granted', 'residual_target'}
    if timed_keys & set(entry) and not (
            timed_keys <= set(entry) and block == 100 and chance is None and counts['control_trials'] == 0
            and counts['parts'] == 1 and isinstance(entry['min_granted'], int) and entry['min_granted'] >= 1
            and 0 < entry['residual_target'] < 1):
        raise ValueError(f'{entry["spell"]} {KIND} mode grant duration needs duration_spell, min_granted >= 1 and '
                         f'residual_target in (0, 1), at block 100, without chance_pct, control_trials or parts')
    return BlockGrantSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['aura']),
                          int(entry['shield']), int(entry['strike_spell']), counts['trials'],
                          counts['control_trials'], counts['parts'], block,
                          None if chance is None else float(chance),
                          None if half_width is None else float(half_width), entry.get('label_suffix', KIND),
                          bool(entry.get('void_on_cast_failure', False)), int(entry.get('duration_spell', 0)),
                          int(entry.get('duration_effect', 0)), int(entry.get('min_granted', 0)),
                          float(entry.get('residual_target', 0.0)))


def needed_blocks(chance_pct: float, half_width_points: float) -> int:
    chance = chance_pct / 100
    return math.ceil(Z_99 ** 2 * chance * (1 - chance) / (half_width_points / 100) ** 2)


def grant_mark(spec: BlockGrantSpec, arm: str, index: int, read: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {arm} {index} {read}'


def granted_trials_needed(chance: float, granted: int, residual_target: float) -> int:
    trials = granted
    while PAIR_RUNS * sum(math.comb(trials, count) * chance ** count * (1 - chance) ** (trials - count)
                          for count in range(granted)) > residual_target:
        trials += 1
    return trials


def duration_offsets(duration: int) -> dict[str, int]:
    return {side: round(duration * share) for side, share in DURATION_READS.items()}


def timed_grant_trial(spec: BlockGrantSpec, arm: str, index: int, duration: int) -> list[dict]:
    offsets = duration_offsets(duration)
    steps = grant_trial(spec, arm, index)
    strike = next(position for position, step in enumerate(steps) if step.get('actor') == STRIKER)
    steps[strike:strike + 1] = [measurement(grant_mark(spec, arm, index, 'strike start'), CASTER, TIME_METRIC),
                                steps[strike],
                                measurement(grant_mark(spec, arm, index, 'strike end'), CASTER, TIME_METRIC)]
    elapsed = STRIKE_SETTLE_MS
    for side, offset in offsets.items():
        steps += [{'action': 'wait', 'label': f'{arm} {index} {side} read', 'ms': offset - elapsed},
                  measurement(grant_mark(spec, arm, index, f'{side} time'), CASTER, TIME_METRIC),
                  measurement(grant_mark(spec, arm, index, f'{side} aura'), CASTER, 'aura', spell=spec.aura)]
        elapsed = offset
    return steps


def grant_trial(spec: BlockGrantSpec, arm: str, index: int) -> list[dict]:
    return [{'action': 'cancel_aura', 'actor': CASTER, 'spell': spec.aura},
            measurement(grant_mark(spec, arm, index, 'aura before'), CASTER, 'aura', spell=spec.aura),
            {'action': 'set_combat_avoidance', 'actor': CASTER, 'dodge': 0, 'parry': 0, 'block': spec.block},
            {'action': 'set_health', 'actor': CASTER, 'value': STRIKE_HEALTH, 'maximum': STRIKE_MAX_HEALTH},
            {'action': 'cast', 'actor': STRIKER, 'spell': spec.strike_spell, 'target': CASTER},
            {'action': 'wait', 'label': f'{arm} {index} strike', 'ms': STRIKE_SETTLE_MS},
            measurement(grant_mark(spec, arm, index, 'blocked'), CASTER, 'spell_damage_count',
                        spell=spec.strike_spell, caster=STRIKER, target=CASTER, blocked=True),
            measurement(grant_mark(spec, arm, index, 'unblocked'), CASTER, 'spell_damage_count',
                        spell=spec.strike_spell, caster=STRIKER, target=CASTER, blocked=False),
            measurement(grant_mark(spec, arm, index, 'aura after'), CASTER, 'aura', spell=spec.aura)]


def duration_contract(spec: BlockGrantSpec, duration: int) -> str:
    offsets = duration_offsets(duration)
    windows = {side: (duration * low, duration * high) for side, (low, high) in DURATION_WINDOWS.items()}
    return (f'{spec.trials} trials: game time is read right before and right after the strike, and the aura with '
            f'game-time stamps {offsets["held"]} and {offsets["gone"]} ms after the strike. On a trial whose strike '
            f'granted the aura, it must be on at the first read and gone at the second; their ages from the strike '
            f'must lie in {windows["held"][0]:g}..{windows["held"][1]:g} and {windows["gone"][0]:g}..'
            f'{windows["gone"][1]:g} ms ({duration} ms, {spec.duration_spell} Effect[{spec.duration_effect}], both '
            f'reads inside +-10%), else the trial is void. A trial with no grant is void. A granted trial with the '
            f'aura gone early or still on alerts; fewer than {spec.min_granted} judged granted trials is unmeasured '
            f'({spec.trials} trials at ProcChance leave fewer with probability at most {spec.residual_target:g} per '
            f'pair).')


def grant_contract(spec: BlockGrantSpec, duration: int = 0) -> str:
    wanted = 'blocked' if spec.block else 'an unblocked hit'
    text = (f'Shield {spec.shield} equipped and Block {BLOCK_SPELL} learned. Each trial removes {spec.aura} from the '
            f'caster, reads that it is absent, forces block to {spec.block}% with dodge and parry at 0 '
            f'(set_combat_avoidance block, owner ruling O-20), has a passive striker (react state 0) cast '
            f'{spec.strike_spell} at the caster once and reads the blocked and unblocked hit counts and then the '
            f'aura. A trial whose strike is not {wanted} (counted by the damage log, the cumulative counts '
            f'differenced against the previous trial), or whose aura was on before the strike, is void, never a '
            f'failure. ')
    if spec.control_trials:
        text += (f'Control: {spec.control_trials} trials per part before {spec.spell} is learned; none may show the '
                 f'aura. Then {spec.spell} is learned. ')
    if duration:
        return text + duration_contract(spec, duration)
    if spec.chance_pct is None:
        return text + (f'{spec.trials * spec.parts} trials: no judged trial may show the aura (an unblocked strike '
                       f'grants nothing), and fewer than {MIN_UNBLOCKED_TRIALS} judged trials is unmeasured (a 30% '
                       f'grant on every unblocked strike would escape {MIN_UNBLOCKED_TRIALS} judged trials with '
                       f'probability {0.7 ** MIN_UNBLOCKED_TRIALS:.1e}).')
    needed = needed_blocks(spec.chance_pct, spec.half_width_points)
    return text + (f'{spec.trials} trials in each of {spec.parts} pooled parts ({spec.trials * spec.parts}, the 99% '
                   f'half-width {spec.half_width_points:g} points needs {needed} judged): the share of trials showing '
                   f'the aura must lie in {spec.chance_pct - spec.half_width_points:g}..'
                   f'{spec.chance_pct + spec.half_width_points:g}%, outside it alerts as a finding and fewer than '
                   f'{needed} judged trials is unmeasured. At a true {spec.chance_pct:g}% the share leaves that range '
                   f'with probability {math.erfc(Z_99 / math.sqrt(2)):.1e} per run (about that squared when both runs '
                   f'of a pair must agree).')


def block_grant_scenario(class_file: dict, spec: BlockGrantSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, 1.0)
    arms = [(CONTROL_ARM, spec.control_trials), (TREATMENT_ARM, spec.trials)]
    setup = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': BLOCK_SPELL},
                {'action': 'add_item', 'actor': CASTER, 'item': spec.shield},
                {'action': 'equip', 'actor': CASTER, 'item': spec.shield, 'slot': OFF_HAND_SLOT}])
    steps = list(setup)
    duration = int(records.single_value(spec.duration_spell, spec.duration_effect)) if spec.duration_spell else 0
    if spec.duration_spell:
        chance = records.field('Spell', spec.spell, 'ProcChance') / 100
        needed = granted_trials_needed(chance, spec.min_granted, spec.residual_target)
        if duration <= 0 or not 0 < chance < 1 or spec.trials < needed:
            raise ValueError(f'{spec.spell} {KIND} mode grant duration needs a positive {spec.duration_spell} '
                             f'Effect[{spec.duration_effect}], a ProcChance in (0, 100) and {needed} trials: at '
                             f'ProcChance {chance:g} fewer than {spec.min_granted} grants come with probability at '
                             f'most {spec.residual_target:g} per pair')
    for arm, count in arms:
        if arm == TREATMENT_ARM:
            steps.append({'action': 'learn', 'actor': CASTER, 'spell': spec.spell})
        for index in range(count):
            steps += timed_grant_trial(spec, arm, index, duration) if duration else grant_trial(spec, arm, index)
    if len(steps) > MAXIMUM_STEPS:
        raise ValueError(f'{spec.spell} {KIND} mode grant needs {len(steps)} steps, more than {MAXIMUM_STEPS}')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour block grant trials',
        'contract': grant_contract(spec, duration) + (' A refused cast voids the run: the verdict is unmeasured, never '
                                                      'ok or alert.' if spec.void_on_cast_failure else ''),
        'players': [player_fixture(class_file)],
        'creatures': [striker_creature(class_file, MetricDeltaStrike(spec.strike_spell, STRIKE_HEALTH,
                                                                     STRIKE_MAX_HEALTH, reaction=PASSIVE))],
        'steps': steps}
    reads = ('aura before', 'blocked', 'unblocked', 'aura after')
    if duration:
        reads += ('strike start', 'strike end', 'held time', 'held aura', 'gone time', 'gone aura')
    model = {'kind': KIND, 'mode': GRANT_MODE, 'metric': 'aura', 'quote': entry.quote, 'block': spec.block,
             'chance_pct': spec.chance_pct, 'half_width_points': spec.half_width_points,
             'minimum_judged': (MIN_UNBLOCKED_TRIALS if spec.chance_pct is None
                                else needed_blocks(spec.chance_pct, spec.half_width_points)),
             'arms': {arm: [{read: grant_mark(spec, arm, index, read) for read in reads} for index in range(count)]
                      for arm, count in arms},
             'void_on_cast_failure': spec.void_on_cast_failure}
    if spec.parts > 1:
        model['parts'] = spec.parts
    if duration:
        windows = {side: [duration * low, duration * high] for side, (low, high) in DURATION_WINDOWS.items()}
        model['duration'] = {'expected_ms': duration, 'min_granted': spec.min_granted, **windows}
    expected = (f'{duration}' if duration else '0') if spec.chance_pct is None else f'{spec.chance_pct:g}%'
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}', BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.aura, None, expected, prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def grant_tally(run: Run, model: dict) -> tuple[dict, str | None]:
    wanted = (1, 0) if model['block'] else (0, 1)
    tally = {arm: {'judged': 0, 'granted': 0, 'void': 0} for arm in model['arms']}
    previous = None
    for arm, trials in model['arms'].items():
        for trial in trials:
            missing = next((label for label in trial.values() if run.values.get(label) is None), None)
            if missing is not None:
                return tally, missing_measurement(run, missing)
            hits = tuple(run.values[trial[key]] - (run.values[previous[key]] if previous else 0.0)
                         for key in ('blocked', 'unblocked'))
            previous = trial
            if hits != wanted or run.values[trial['aura before']] != 0:
                tally[arm]['void'] += 1
                continue
            tally[arm]['judged'] += 1
            tally[arm]['granted'] += run.values[trial['aura after']] != 0
    return tally, None


def timed_outcome(values: dict, trial: dict, windows: dict) -> str:
    if values[trial['aura after']] == 0:
        return 'void'
    for side in ('held', 'gone'):
        youngest = values[trial[f'{side} time']] - values[trial['strike end']]
        oldest = values[trial[f'{side} time']] - values[trial['strike start']]
        if youngest < windows[side][0] or oldest > windows[side][1]:
            return 'void'
    return 'ok' if values[trial['held aura']] != 0 and values[trial['gone aura']] == 0 else 'alert'


def timed_grant_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    duration = model['duration']
    wanted = (1, 0)
    counts = {'ok': 0, 'alert': 0, 'void': 0}
    notes = []
    previous = None
    for index, trial in enumerate(model['arms'][TREATMENT_ARM]):
        missing = next((label for label in trial.values() if run.values.get(label) is None), None)
        if missing is not None:
            return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
        hits = tuple(run.values[trial[key]] - (run.values[previous[key]] if previous else 0.0)
                     for key in ('blocked', 'unblocked'))
        previous = trial
        outcome = ('void' if hits != wanted or run.values[trial['aura before']] != 0
                   else timed_outcome(run.values, trial, duration))
        counts[outcome] += 1
        if outcome == 'alert':
            notes.append(f'trial {index}: on {run.values[trial["held aura"]]:g} at '
                         f'{run.values[trial["held time"]] - run.values[trial["strike start"]]:g} ms, on '
                         f'{run.values[trial["gone aura"]]:g} at '
                         f'{run.values[trial["gone time"]] - run.values[trial["strike start"]]:g} ms')
    refused = [reason for reasons in run.cast_failures.values() for reason in reasons if reason != NO_CAST_FAILURE]
    text = (f'granted trials judged on the {duration["expected_ms"]:g} ms grant: {counts["ok"]} ok, '
            f'{counts["alert"]} alert, {counts["void"]} void (no grant, a strike not blocked once, or a read age '
            f'outside {duration["held"]} / {duration["gone"]} ms)' + ''.join(f'; {note}' for note in notes))
    if model.get('void_on_cast_failure') and refused:
        return replace(base, status='unmeasured', detail=counts,
                       explanation=f'{text}; refused casts void the run: {describe_failures(refused)}')
    judged = counts['ok'] + counts['alert']
    status = ('alert' if counts['alert'] else 'unmeasured' if judged < duration['min_granted'] else 'ok')
    return replace(base, status=status, measured=float(counts['ok']), expected=float(duration['expected_ms']),
                   low=duration['held'][0], high=duration['gone'][1], detail=counts,
                   explanation=text + ('' if judged >= duration['min_granted'] else
                                       f'; fewer than the {duration["min_granted"]} judged granted trials needed'))


def block_grant_verdict(base: Verdict, runs: list[Run], model: dict) -> Verdict:
    if 'duration' in model:
        if len(runs) != 1:
            return replace(base, status='unmeasured',
                           explanation=f'{KIND} grant duration judges one run, not {len(runs)}')
        return timed_grant_verdict(base, runs[0], model)
    total = {arm: {'judged': 0, 'granted': 0, 'void': 0} for arm in model['arms']}
    refused = []
    for run in runs:
        tally, problem = grant_tally(run, model)
        if problem is not None:
            return replace(base, status='unmeasured', explanation=problem)
        for arm, counts in tally.items():
            total[arm] = {key: total[arm][key] + counts[key] for key in counts}
        refused += [reason for reasons in run.cast_failures.values() for reason in reasons
                    if reason != NO_CAST_FAILURE]
    detail = {**{f'{arm}_{key}': value for arm, counts in total.items() for key, value in counts.items()},
              **({'parts': len(runs)} if len(runs) > 1 else {})}
    control, treatment = total[CONTROL_ARM], total[TREATMENT_ARM]
    text = (f'control {control["granted"]} grants in {control["judged"]} judged trials ({control["void"]} void); '
            f'treatment {treatment["granted"]} grants in {treatment["judged"]} judged trials ({treatment["void"]} void)')
    if model.get('void_on_cast_failure') and refused:
        return replace(base, status='unmeasured', detail=detail,
                       explanation=f'{text}; refused casts void the run: {describe_failures(refused)}')
    if model['arms'][CONTROL_ARM] and (not control['judged'] or control['granted']):
        return replace(base, status='alert' if control['judged'] else 'unmeasured', detail=detail,
                       explanation=f'{text}; no trial may show the aura before the talent is learned')
    judged, granted = treatment['judged'], treatment['granted']
    if judged < model['minimum_judged']:
        return replace(base, status='unmeasured', detail=detail,
                       explanation=f'{text}; fewer than the {model["minimum_judged"]} judged trials the claim needs')
    if model['chance_pct'] is None:
        status = 'alert' if granted else 'ok'
        return replace(base, status=status, measured=float(granted), expected=0.0, detail=detail,
                       explanation=f'{text}; an unblocked strike must grant nothing')
    expected, half = model['chance_pct'] / 100, model['half_width_points'] / 100
    low, high = wilson_interval(granted, judged)
    rate = granted / judged
    status = 'ok' if expected - half <= rate <= expected + half else 'alert'
    return replace(base, status=status, measured=rate, expected=expected, low=low, high=high, detail=detail,
                   explanation=f'{text}; rate {rate:.4f}, Wilson 99% interval [{low:.4f}, {high:.4f}], range '
                               f'[{expected - half:.4f}, {expected + half:.4f}]'
                               + ('' if status == 'ok' else ': outside the range, a finding for the mentor'))


def single_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    if model.get('mode') == GRANT_MODE:
        return block_grant_verdict(base, [run], model)
    return block_extension_verdict(base, run, model)


JUDGES = {BEHAVIOUR_METRIC_DELTA: single_verdict}
POOLED_JUDGE = block_grant_verdict
