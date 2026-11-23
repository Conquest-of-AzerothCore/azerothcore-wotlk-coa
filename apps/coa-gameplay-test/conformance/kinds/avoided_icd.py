from dataclasses import dataclass, replace
import math
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, waited_ms
from compare import Verdict, describe_failures, failure_reasons, missing_measurement
from hits import DRAIN_MS, timed
import proc_avoided
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, dataset

KIND = 'avoided_icd'
ORDER = 51
METRIC = 'event_interval_min_ms'
BAND_PCT = 5
NEIGHBOUR_PCT = 10
MIN_INTERVALS = 20
MIN_AVOIDED_PER_HIT = 10
DODGE, PARRY = 50, 50
QUIET_SHIFT_YD = 20
QUIET_WAIT_MS = 200
FIELDS = {'spell', 'name', 'kind', 'variant', 'label_suffix', 'quote', 'hit_spell', 'timer_ms', 'striker_entry',
          'strikers', 'striker_auras', 'swing_ms', 'control_windows', 'windows', 'observe_source'}


@dataclass(frozen=True)
class AvoidedIcdSpec:
    spell: int
    name: str
    quote: str
    hit_spell: int
    timer_ms: int
    striker_entry: int
    strikers: int
    striker_auras: tuple[int, ...]
    swing_ms: int
    control_windows: int
    windows: int
    label_suffix: str


def avoided_icd_spec(entry: dict) -> AvoidedIcdSpec:
    if set(entry) - FIELDS:
        raise ValueError(f'{entry["spell"]} {KIND} has unknown fields {sorted(set(entry) - FIELDS)}')
    spec = AvoidedIcdSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['hit_spell']),
                          int(entry['timer_ms']), int(entry['striker_entry']), int(entry['strikers']),
                          tuple(int(spell) for spell in entry.get('striker_auras', ())), int(entry['swing_ms']),
                          int(entry['control_windows']), int(entry['windows']), entry.get('label_suffix', KIND))
    if spec.timer_ms <= 0 or spec.swing_ms <= 0 or spec.control_windows < 1:
        raise ValueError(f'{spec.spell} {KIND} needs a positive timer_ms, swing_ms and control_windows')
    if spec.windows * spec.swing_ms < (MIN_INTERVALS + 2) * spec.timer_ms * (100 + NEIGHBOUR_PCT) / 100:
        raise ValueError(f'{spec.spell} {KIND} windows of {spec.swing_ms} ms hold fewer than {MIN_INTERVALS} '
                         f'intervals of a timer {NEIGHBOUR_PCT}% longer than {spec.timer_ms} ms')
    proc_avoided.checked_trigger(avoided_entry(spec))
    return spec


def avoided_entry(spec: AvoidedIcdSpec) -> dict:
    return {'aura': spec.spell, 'trigger': {'action': proc_avoided.AVOIDED, 'striker_entry': spec.striker_entry,
                                            'swing_ms': spec.swing_ms, 'dodge': DODGE, 'parry': PARRY,
                                            'strikers': spec.strikers, 'striker_auras': list(spec.striker_auras),
                                            'count_misses': True}}


def mark(spec: AvoidedIcdSpec, read: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {read}'


def quiet_distance_label(spec: AvoidedIcdSpec, striker: str) -> str:
    return mark(spec, f'quiet distance {striker}')


def quiet_minimum_yd() -> float:
    from behaviours import STRIKER_DISTANCE
    return QUIET_SHIFT_YD - STRIKER_DISTANCE


def quiet_steps(spec: AvoidedIcdSpec, avoided: dict) -> list[dict]:
    return ([{'action': 'relocate', 'actor': CASTER, 'dx': QUIET_SHIFT_YD},
             {'action': 'wait', 'label': 'quiet', 'ms': QUIET_WAIT_MS}]
            + [measurement(quiet_distance_label(spec, striker), CASTER, 'distance', target=striker)
               for striker in proc_avoided.striker_ids(avoided)]
            + [measurement(mark(spec, 'attacks first'), CASTER, 'melee_attacks_taken')])


def band(spec: AvoidedIcdSpec) -> tuple[float, float]:
    margin = spec.timer_ms * BAND_PCT / 100
    return spec.timer_ms - margin, spec.timer_ms + margin


def residual_text(spec: AvoidedIcdSpec) -> str:
    low, high = band(spec)
    gap = spec.timer_ms / MIN_AVOIDED_PER_HIT
    return (f'residual: a {spec.timer_ms} ms timer reads its shortest interval above {high:g} ms only when every one '
            f'of at least {MIN_INTERVALS} intervals waits more than {high - spec.timer_ms:g} ms for the next avoided '
            f'swing, and a timer {NEIGHBOUR_PCT}% shorter reads it at {low:g} ms or more only when each waits '
            f'{low - spec.timer_ms * (100 - NEIGHBOUR_PCT) / 100:g} ms or more; with at least {MIN_AVOIDED_PER_HIT} '
            f'avoided swings per hit (a mean gap of at most {gap:g} ms) and independent uniform swing phases, an '
            f'assumption not measured, each wait exceeds {high - spec.timer_ms:g} ms with probability at most 1/2, so '
            f'a wrong verdict has probability at most 2^-{MIN_INTERVALS} = {0.5 ** MIN_INTERVALS:.1e} per run')


def avoided_icd_scenario(class_file: dict, spec: AvoidedIcdSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, float(spec.timer_ms))
    avoided = avoided_entry(spec)
    trials, attempts = mark(spec, 'avoided'), mark(spec, 'attacks')
    start_trials, start_attempts = mark(spec, 'start avoided'), mark(spec, 'start attacks')
    hits = {'spell': spec.hit_spell}
    steps = (base_steps(class_file) + proc_avoided.engage_steps(avoided)
             + proc_avoided.attempt_steps(avoided, spec.control_windows, spec.swing_ms)
             + [{'action': 'wait', 'label': 'control drain', 'ms': DRAIN_MS},
                measurement(mark(spec, 'control hits'), CASTER, 'spell_damage_count', **hits)]
             + proc_avoided.trial_steps(start_trials, start_attempts, True)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
             + proc_avoided.attempt_steps(avoided, spec.windows, spec.swing_ms)
             + [{'action': 'wait', 'label': 'drain', 'ms': DRAIN_MS}] + proc_avoided.guard_steps(avoided)
             + quiet_steps(spec, avoided)
             + proc_avoided.trial_steps(trials, attempts, True)
             + [measurement(mark(spec, 'hits'), CASTER, 'spell_damage_count', **hits),
                measurement(mark(spec, 'shortest'), CASTER, METRIC, stream='spell_damage', **hits),
                measurement(mark(spec, 'median'), CASTER, 'event_interval_median_ms', stream='spell_damage',
                            **hits)])
    low, high = band(spec)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour avoided icd',
        'contract': (f'{spec.strikers} aggressive stationary strikers {spec.striker_entry} swing at the caster, whose '
                     f'dodge and parry are set to {DODGE}% and {PARRY}% before every {spec.swing_ms} ms window, so '
                     f'every swing is dodged, parried or missed; {spec.control_windows} windows before {spec.spell} '
                     f'is learned must give no {spec.hit_spell} hit, then {spec.windows} windows with it. The '
                     f'shortest interval between two {spec.hit_spell} hits must lie in [{low:g}, {high:g}] ms, which '
                     f'excludes a timer {NEIGHBOUR_PCT}% shorter or longer than {spec.timer_ms} ms; the run is void '
                     f'with fewer than {MIN_INTERVALS} intervals, fewer than {MIN_AVOIDED_PER_HIT} avoided swings '
                     f'per hit, attacks taken other than the dodged, parried and missed swings, a total of '
                     f'attacks taken that changed while the swing outcomes were read, a caster that stayed within '
                     f'{quiet_minimum_yd():g} yd of a striker after the {QUIET_SHIFT_YD} yd relocation that quiets '
                     f'the strikers before the reads, or a refused cast; '
                     f'{residual_text(spec)}.'),
        'players': [player_fixture(class_file)],
        'creatures': proc_avoided.striker_fixtures(class_file, avoided),
        'steps': steps}
    labels = proc_avoided.trial_labels(trials, True)
    start_labels = proc_avoided.trial_labels(start_trials, True)
    model = {'kind': KIND, 'metric': METRIC, 'quote': entry.quote, 'timer_ms': spec.timer_ms, 'band': [low, high],
             'min_intervals': MIN_INTERVALS, 'min_avoided_per_hit': MIN_AVOIDED_PER_HIT,
             'reads': {'control_hits': mark(spec, 'control hits'), 'hits': mark(spec, 'hits'),
                       'shortest': mark(spec, 'shortest'), 'median': mark(spec, 'median'),
                       'avoided': list(labels.values()), 'start_avoided': list(start_labels.values()),
                       'attacks': attempts, 'attacks_first': mark(spec, 'attacks first'),
                       'quiet_distances': [quiet_distance_label(spec, striker)
                                           for striker in proc_avoided.striker_ids(avoided)]},
             'quiet_minimum_yd': quiet_minimum_yd(),
             'residual': residual_text(spec)}
    expectation = Expectation(mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.hit_spell, None,
                              str(spec.timer_ms), prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def avoided_icd_verdict(base: Verdict, run, model: dict) -> Verdict:
    reads = model['reads']
    labels = ([reads[name] for name in ('control_hits', 'hits', 'attacks', 'attacks_first')] + reads['avoided']
              + reads['start_avoided'] + reads['quiet_distances'])
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    failures = {spell: failure_reasons(run, spell) for spell in run.cast_failures}
    refused = '; '.join(f'{spell}: {describe_failures(reasons)}' for spell, reasons in failures.items() if reasons)
    if refused:
        return replace(base, status='unmeasured', explanation=f'void: refused casts {refused}')
    nearest = min(run.values[label] for label in reads['quiet_distances'])
    if nearest < model['quiet_minimum_yd']:
        return replace(base, status='unmeasured',
                       explanation=f'void: the caster stands {nearest:g} yd from a striker after the relocation that '
                                   f'quiets the strikers, below {model["quiet_minimum_yd"]:g} yd, so a swing may '
                                   f'still land in the reads')
    first, last = run.values[reads['attacks_first']], run.values[reads['attacks']]
    if first != last:
        return replace(base, status='unmeasured',
                       explanation=f'void: attacks taken changed from {first:g} to {last:g} while the swing '
                                   f'outcomes were read')
    imbalance = proc_avoided.attack_imbalance({'total': reads['attacks'], 'parts': reads['avoided']}, run.values)
    if imbalance:
        return replace(base, status='unmeasured', explanation=f'void: {imbalance}')
    control = run.values[reads['control_hits']]
    if control > 0:
        return replace(base, measured=control, expected=0.0,
                       explanation=f'{control:g} hits before the passive is learned')
    hits = run.values[reads['hits']]
    avoided = sum(run.values[label] for label in reads['avoided']) - sum(
        run.values[label] for label in reads['start_avoided'])
    shortest, median = run.values.get(reads['shortest']), run.values.get(reads['median'])
    notes = (f'{hits:g} hits, {avoided:g} avoided swings after the learn, shortest interval '
             f'{"none" if shortest is None or math.isnan(shortest) else f"{shortest:g} ms"}, median '
             f'{"none" if median is None or math.isnan(median) else f"{median:g} ms"}')
    if hits - 1 < model['min_intervals'] or shortest is None or math.isnan(shortest):
        return replace(base, status='unmeasured',
                       explanation=f'void: fewer than {model["min_intervals"]} intervals ({notes})')
    if avoided < model['min_avoided_per_hit'] * hits:
        return replace(base, status='unmeasured',
                       explanation=f'void: fewer than {model["min_avoided_per_hit"]} avoided swings per hit, too '
                                   f'sparse to load the timer ({notes})')
    low, high = model['band']
    status = 'ok' if low <= shortest <= high else 'alert'
    return replace(base, status=status, measured=shortest, expected=float(model['timer_ms']), low=low, high=high,
                   explanation=f'shortest interval {shortest:g} ms against [{low:g}, {high:g}]: {notes}')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return avoided_icd_scenario(class_file, avoided_icd_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', KIND)}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: avoided_icd_verdict}
