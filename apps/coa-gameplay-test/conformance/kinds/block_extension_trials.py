from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import (BEHAVIOUR_METRIC_DELTA, STRIKER, MetricDeltaStrike, behaviour_entry, prose_rule,
                        required_aura_steps, striker_creature, waited_ms)
from compare import NO_CAST_FAILURE, Run, Verdict, describe_failures, missing_measurement
from hits import timed
from procs import wilson_interval
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
TIME_MARGIN = 0.1
BASE_READS = (-0.108, -0.083, 0.083, 0.108)
EXTENDED_READS = (-0.175, -0.05, 0.025, 0.175)
TIME_METRIC = 'game_time_ms'
KEYS = frozenset({'spell', 'kind', 'name', 'quote', 'aura', 'extension_spell', 'extension_effect', 'shield',
                  'strike_spell', 'cast_power', 'trials', 'label_suffix', 'void_on_cast_failure', 'observe_source'})


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


def block_extension_spec(entry: dict) -> BlockExtensionSpec:
    unknown = set(entry) - KEYS
    if unknown:
        raise ValueError(f'{entry["spell"]} {KIND} does not take {sorted(unknown)}')
    trials = entry['trials']
    if isinstance(trials, bool) or not isinstance(trials, int) or trials < 1:
        raise ValueError(f'{entry["spell"]} {KIND} trials is a positive whole count, not {trials!r}')
    if entry.get('void_on_cast_failure', False) not in (True, False):
        raise ValueError(f'{entry["spell"]} {KIND} void_on_cast_failure is true or false')
    return BlockExtensionSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['aura']),
                              int(entry['extension_spell']), int(entry.get('extension_effect', 0)),
                              int(entry['shield']), int(entry['strike_spell']), int(entry['cast_power']), trials,
                              entry.get('label_suffix', KIND), bool(entry.get('void_on_cast_failure', False)))


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
                  {'action': 'set_combat_avoidance', 'actor': CASTER, 'dodge': 0, 'parry': 0, 'block': 100},
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
        'contract': (f'Shield {spec.shield} equipped, Block {BLOCK_SPELL} and {spec.spell} learned. Each of '
                     f'{spec.trials} trials removes {spec.aura}, casts it on the caster ({base} ms, DurationIndex), '
                     f'forces block to 100% with dodge and parry at 0 (set_combat_avoidance block, owner ruling '
                     f'O-20) and has a passive striker cast {spec.strike_spell} at the caster once. One strike per '
                     f'application: an extension casts nothing, so the number of extensions on an application hit '
                     f'several times is unknown and its expiry could not be judged. The aura is read with game-time '
                     f'stamps at {offsets} ms after the cast, which bracket its expiry. A trial whose strike is not '
                     f'one blocked hit, or whose cast left no aura, is void. Every other trial must expire inside '
                     f'{limits["base"][0]:g}..{limits["base"][1]:g} ms (not extended) or '
                     f'{limits["extended"][0]:g}..{limits["extended"][1]:g} ms (extended by {extension} ms, '
                     f'{spec.extension_spell} Effect[{spec.extension_effect}], +-10%); any other expiry alerts, a '
                     f'bracket straddling a band edge is unmeasured, and no extended trial is unmeasured. The share '
                     f'of extended trials is reported with its 99% interval and not judged.'
                     + (' A refused cast voids the run: the verdict is unmeasured, never ok or alert.'
                        if spec.void_on_cast_failure else '')),
        'players': [player_fixture(class_file)],
        'creatures': [striker_creature(class_file, MetricDeltaStrike(spec.strike_spell, STRIKE_HEALTH,
                                                                     STRIKE_MAX_HEALTH))],
        'steps': steps}
    trials = [{'cast_time': mark(spec, f'{index} cast time'), 'cast_aura': mark(spec, f'{index} cast aura'),
               'blocked': mark(spec, f'{index} blocked'), 'unblocked': mark(spec, f'{index} unblocked'),
               'reads': [{'time': mark(spec, f'{index} read {read} time'),
                          'aura': mark(spec, f'{index} read {read} aura')} for read in range(len(offsets))]}
              for index in range(spec.trials)]
    model = {'kind': KIND, 'metric': 'aura', 'quote': entry.quote, 'base_ms': base, 'extension_ms': extension,
             'bands': {name: list(limit) for name, limit in limits.items()}, 'trials': trials,
             'void_on_cast_failure': spec.void_on_cast_failure}
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


def trial_outcome(run: Run, trial: dict, previous: dict | None, limits: dict) -> tuple[str, str]:
    blocked, unblocked = (run.values[trial[key]] - (run.values[previous[key]] if previous else 0.0)
                          for key in ('blocked', 'unblocked'))
    if blocked != 1 or unblocked != 0 or run.values[trial['cast_aura']] != 1:
        return 'void', f'{blocked:g} blocked and {unblocked:g} unblocked hits, aura after the cast ' \
                       f'{run.values[trial["cast_aura"]]:g}'
    start = run.values[trial['cast_time']]
    reads = [(run.values[read['time']] - start, run.values[read['aura']]) for read in trial['reads']]
    bracket = expiry_bracket(reads)
    if bracket is None:
        return 'alert', f'the aura came back after it was gone: {reads}'
    high = 'still on' if bracket[1] is None else f'{bracket[1]:g}'
    return classify(bracket, limits), f'expiry in ({bracket[0]:g}, {high}] ms'


def block_extension_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    labels = [label for trial in model['trials'] for key, value in trial.items()
              for label in ([value] if key != 'reads' else [read[part] for read in value for part in read])]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    refused = [reason for reasons in run.cast_failures.values() for reason in reasons if reason != NO_CAST_FAILURE]
    limits = {name: tuple(limit) for name, limit in model['bands'].items()}
    trials = model['trials']
    outcomes = [trial_outcome(run, trial, trials[index - 1] if index else None, limits)
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
    elif counts['unmeasured'] or not counts['extended']:
        status = 'unmeasured'
    else:
        status = 'ok'
    return replace(base, status=status, measured=float(counts['extended']), expected=float(model['extension_ms']),
                   detail=counts, explanation=explanation)


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return block_extension_scenario(class_file, block_extension_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', KIND)}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: block_extension_verdict}
