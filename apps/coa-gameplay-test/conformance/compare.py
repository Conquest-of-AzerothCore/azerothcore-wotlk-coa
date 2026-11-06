from collections import Counter
from dataclasses import asdict, dataclass, field, replace
from functools import lru_cache
import hashlib
import json
import math
from pathlib import Path
import re
from statistics import fmean
from typing import Callable, Mapping, Protocol

from hits import MEAN_HALF_WIDTH, UNMODELLED, Z_99, HitModel, Modifier, Unmodelled, measured_hit_model
from passives import PASSIVE_DELTA, VERSUS_AURA_STATE
from procs import AMBIGUOUS_TOOLTIP, CAST, PROC_CHECK, chance_of, wilson_interval
from profile import DBC_DIR, caster_stats_from, known_aura_label, probe_aura_label
from stack import (ADDS, MEASURED, MELEE_SOURCE, MULTIPLIES, STACK_CHECKS, STACK_DPS, STACK_SOURCE, TALENT_DELTA,
                   levers, mean_interval, ratio_interval)
from tooltip import CasterStats, Displayed, ForcedPoints, Readout, Records, Tooltip, Unreadable
from triggers import EVENT_TOLERANCE, TRIGGER_CHECK
from values import CAST_MARGIN_MS, CAST_WAIT_LABEL, EFFECTS, UNMEASURABLE, UNREADABLE, Expectation, dataset

STATUSES = ('ok', 'alert', 'unreadable', 'unmodelled', 'ambiguous_tooltip', 'insufficient_trials', 'unmeasured',
            MEASURED)
NOT_ALERTS = frozenset({'ok', MEASURED})
CAST_DEPENDENT_CHECKS = frozenset({'cooldown_ms', 'aura_amount', 'aura_duration_ms'})
NO_CAST_FAILURE = 0
CAST_RESULTS_HEADER = Path(__file__).resolve().parents[3] / 'src/server/shared/SharedDefines.h'
CAST_RESULT_ENUM = re.compile(r'enum SpellCastResult\b[^{]*\{(?P<body>[^}]*)\}')
CAST_RESULT_ENTRY = re.compile(r'^\s*(?P<name>SPELL_\w+)\s*=\s*(?P<code>\d+)', re.MULTILINE)
ABSOLUTE_TOLERANCE = 1.0
RELATIVE_TOLERANCE = 0.005
FLOAT_EPSILON = 1e-9
TOKEN_CHECKS = frozenset({'effect_value', 'aura_amount', 'aura_duration_ms'})
ROLLED_CHECKS = frozenset({'effect_value', 'aura_amount'})
ROLL_SPREAD = 'roll_spread'
HIT_CHECKS = frozenset({'hit_mean', 'melee_mean'})
READ_RULE = 'read '
ORDINAL = re.compile(r'#(\d+)$')
DIVIDED_TOKEN = re.compile(r'\$/(\d+);')
PLAIN_TOKEN = re.compile(r'\$(?:/\d+;)?(?P<spell>\d*)(?P<letter>[smM])(?P<digit>[1-3])')
FIXED_DIE_SIDES = (0, 1)
COST_DIVISOR = re.compile(r'ManaCost divisor (\d+)')
EXPLORATORY = ('gameplay', 'exploratory')
ALERT_COLUMNS = ('scenario', 'spell_id', 'rank_id', 'label', 'check', 'status', 'measured', 'expected', 'low', 'high',
                 'deviation', 'explanation')
ALERTS_FILE = 'alerts.tsv'
REPORT_FILE = 'report.md'
LEVERS_FILE = 'levers.md'
VERDICTS_FILE = 'verdicts.json'
VERDICTS_SCHEMA = 1
PERCENT_POINT_METRICS = frozenset({'melee_crit_chance', 'spell_crit_chance', 'melee_hit_chance', 'spell_hit_chance',
                                   'parry_chance', 'dodge_chance', 'spell_done_crit_chance'})
FRACTIONAL_METRICS = PERCENT_POINT_METRICS | {'weapon_damage_min'}
FRACTIONAL_FLOOR = 0.01
CRITICAL_DAMAGE_BASE = 1000
DURATION_KIND = 'duration_ms'
PASSIVE_METRIC = 'metric'
READINGS_QUESTION = 'readings'
TEXT_QUESTION = 'text'
AURA_REQUIREMENTS = ('EquippedItemClass', 'Stances', 'CasterAuraSpell')
MODIFIER_KINDS = {'spell_damage_done': 'damage', 'spell_healing_done': 'heal'}
QUESTION_SUBJECTS = {'spell_critical_damage': 'a critical hit of {spell}', 'spell_damage_done': 'a hit of {spell}',
                     'spell_healing_done': 'a heal of {spell}'}

HitModelSource = Callable[[dict, Expectation, Mapping[str, float]], HitModel]


class ScenarioDrift(ValueError):
    pass


@dataclass(frozen=True)
class Verdict:
    label: str
    status: str
    measured: float | None
    expected: float | None
    low: float | None
    high: float | None
    explanation: str
    scenario: str = ''
    spell_id: int = 0
    rank_id: int = 0
    check: str = ''
    detail: dict | None = field(default=None, hash=False)


@dataclass(frozen=True)
class Run:
    key: str
    status: str
    message: str
    values: dict[str, float]
    steps: list[dict]
    max_step_ms: float | None
    cast_failures: dict[int, list[int]] = field(default_factory=dict)


class TooltipSource(Protocol):
    def read(self, rank_id: int, caster: CasterStats, forced: tuple[int, int, int] | None = None) -> Readout: ...

    def effect_points(self, spell_id: int, effect: int) -> tuple[int, int]: ...

    def first_effect(self, rank_id: int) -> int | None: ...

    def spell_field(self, spell_id: int, name: str): ...


class DbcTooltips:
    def __init__(self, dbc_dir: Path):
        self.dbc = dataset(Path(dbc_dir))
        self.records = Records(self.dbc)

    def read(self, rank_id: int, caster: CasterStats, forced: tuple[int, int, int] | None = None) -> Readout:
        records = self.records if forced is None else ForcedPoints(self.dbc, *forced)
        return Tooltip(records, rank_id, caster).read(records.field('Spell', rank_id, 'Description[enUS]'))

    def effect_points(self, spell_id: int, effect: int) -> tuple[int, int]:
        return (self.records.field('Spell', spell_id, f'EffectBasePoints[{effect}]'),
                self.records.field('Spell', spell_id, f'EffectDieSides[{effect}]'))

    def first_effect(self, rank_id: int) -> int | None:
        return next((effect for effect in EFFECTS if self.records.field('Spell', rank_id, f'Effect[{effect}]')), None)

    def spell_field(self, spell_id: int, name: str):
        return self.records.field('Spell', spell_id, name)


@dataclass(frozen=True)
class Tokens:
    readout: Readout | None
    caster: CasterStats | None = None
    error: str = ''


@dataclass(frozen=True)
class Comparison:
    manifest: dict
    runs: dict[str, Run]
    missing: list[str]
    verdicts: list[Verdict]


def number(text, label: str) -> float:
    try:
        return float(text)
    except (TypeError, ValueError):
        raise ValueError(f'{label}: harness value {text!r} is not a number') from None


def measured_values(result: dict) -> dict[str, float]:
    return {step['label']: number(step['actual'], step['label'])
            for step in result.get('steps', []) if 'actual' in step}


def file_sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def recorded_scenario_hash(directory: Path) -> str | None:
    summary = directory / 'summary.json'
    if summary.is_file():
        recorded = json.loads(summary.read_text(encoding='utf-8')).get('scenario_sha256')
        if recorded:
            return recorded
    scenario = directory / 'scenario.json'
    return file_sha256(scenario) if scenario.is_file() else None


def runs_by_hash(results_dir: Path) -> dict[str, Path]:
    found = {}
    for directory in sorted(results_dir.joinpath(*EXPLORATORY).glob('*/')):
        recorded = recorded_scenario_hash(directory)
        if recorded and (directory / 'result.json').is_file():
            found.setdefault(recorded, directory)
    return found


def load_run(results_dir: Path, entry: dict, by_hash: Mapping[str, Path]) -> Run | None:
    directory = results_dir.joinpath(*EXPLORATORY, entry['key'])
    if not directory.is_dir() and entry['sha256'] in by_hash:
        directory = by_hash[entry['sha256']]
    result_path = directory / 'result.json'
    if not result_path.is_file():
        return None
    found = recorded_scenario_hash(directory)
    if found != entry['sha256']:
        raise ScenarioDrift(f'{entry["key"]}: scenario hash {found} of {directory} does not match the manifest '
                            f'hash {entry["sha256"]}')
    result = json.loads(result_path.read_text(encoding='utf-8'))
    max_step = result.get('max_step_ms')
    return Run(entry['key'], result.get('status', ''), result.get('message') or '', measured_values(result),
               result.get('steps', []), None if max_step is None else number(max_step, 'max_step_ms'),
               cast_failures(result))


def cast_failures(result: dict) -> dict[int, list[int]]:
    failures: dict[int, list[int]] = {}
    for failure in result.get('cast_failures', []):
        failures.setdefault(int(number(failure['spell'], 'cast_failures.spell')), []).append(
            int(number(failure['reason'], 'cast_failures.reason')))
    return failures


@lru_cache(maxsize=None)
def cast_result_names(header: Path = CAST_RESULTS_HEADER) -> dict[int, str]:
    if not header.is_file():
        return {}
    enum = CAST_RESULT_ENUM.search(header.read_text(encoding='utf-8'))
    if not enum:
        return {}
    return {int(entry.group('code')): entry.group('name') for entry in CAST_RESULT_ENTRY.finditer(enum.group('body'))}


def failure_reasons(run: Run, rank_id: int) -> list[int]:
    return [reason for reason in run.cast_failures.get(rank_id, []) if reason != NO_CAST_FAILURE]


def cast_result_name(reason: int) -> str:
    return f'{cast_result_names().get(reason, "SpellCastResult")} ({reason})'


def failed_cast(run: Run, rank_id: int) -> str | None:
    reasons = failure_reasons(run, rank_id)
    step = int(run.values.get(f'{rank_id} cast_failure', NO_CAST_FAILURE))
    if step != NO_CAST_FAILURE:
        reasons.append(step)
    return ', '.join(cast_result_name(reason) for reason in dict.fromkeys(reasons)) or None


def describe_failures(reasons: list[int]) -> str:
    return ', '.join(f'{count} x {cast_result_name(reason)}' for reason, count in Counter(reasons).items())


def load_runs(manifest: dict, results_dir: Path) -> tuple[dict[str, Run], list[str]]:
    runs, missing, drift = {}, [], []
    by_hash = runs_by_hash(results_dir)
    for entry in manifest['scenarios']:
        if not entry.get('file'):
            continue
        try:
            run = load_run(results_dir, entry, by_hash)
        except ScenarioDrift as error:
            drift.append(str(error))
            continue
        if run is None:
            missing.append(entry['key'])
        else:
            runs[entry['key']] = run
    if drift:
        raise ScenarioDrift('\n'.join(drift))
    return runs, missing


def read_tokens(level: int, entry: dict, run: Run, tooltips: TooltipSource) -> Tokens:
    try:
        caster = caster_stats_from(run.values, level)
    except KeyError as error:
        return Tokens(None, error=f'base measurement {error} is missing from {run.key}')
    readout = tooltips.read(entry['rank_id'], caster)
    texts = [value.text for value in readout.values]
    if texts != entry['tokens']:
        return Tokens(None, error=f'tooltip tokens read with the measured stats {texts} differ from the generated '
                                  f'tokens {entry["tokens"]}')
    return Tokens(readout, caster)


def margin_of(expected: float) -> float:
    return max(ABSOLUTE_TOLERANCE, RELATIVE_TOLERANCE * abs(expected))


def deterministic(base: Verdict, measured: float, judged: float, expected: float, why: str) -> Verdict:
    margin = margin_of(expected)
    low, high = expected - margin, expected + margin
    status = 'ok' if low - FLOAT_EPSILON <= judged <= high + FLOAT_EPSILON else 'alert'
    return replace(base, status=status, measured=measured, expected=expected, low=low, high=high,
                   explanation=f'{why}; |measured - expected| <= max({ABSOLUTE_TOLERANCE:g}, '
                               f'{RELATIVE_TOLERANCE:.1%} of expected)')


def elapsed_bound(run: Run, label: str) -> float | None:
    position = next((index for index, step in enumerate(run.steps) if step.get('label') == label), None)
    if position is None or run.max_step_ms is None:
        return None
    cast = max((index for index in range(position) if run.steps[index].get('action') == 'cast'), default=position)
    return sum(CAST_MARGIN_MS + run.max_step_ms if step.get('label') == CAST_WAIT_LABEL
               else number(step.get('elapsed_ms', 0), 'elapsed_ms') + run.max_step_ms
               for step in run.steps[cast + 1:position + 1])


def judge_time(base: Verdict, run: Run, measured: float, expected: float, why: str) -> Verdict:
    window = elapsed_bound(run, base.label)
    if window is None:
        return replace(base, measured=measured, expected=expected,
                       explanation=f'{why}; no step timing in {run.key} bounds the time elapsed since the cast')
    low = expected - window
    status = 'ok' if low - FLOAT_EPSILON <= measured <= expected + FLOAT_EPSILON else 'alert'
    return replace(base, status=status, measured=measured, expected=expected, low=low, high=expected,
                   explanation=f'{why}; expected - W <= measured <= expected, W = {window:g} ms elapsed since the '
                               f'cast step (step elapsed_ms plus max_step_ms {run.max_step_ms:g} per step)')


def token_divisor(text: str) -> int:
    divided = DIVIDED_TOKEN.match(text)
    return int(divided.group(1)) if divided else 1


def plain_sign(points: int) -> int:
    return -1 if points < 0 else 1


def displayed_points(tooltips: TooltipSource, plain: re.Match, rank_id: int) -> int:
    base_points, die_sides = tooltips.effect_points(int(plain.group('spell') or rank_id), int(plain.group('digit')) - 1)
    return base_points + (die_sides if plain.group('letter') == 'M' else 1)


def roll_range(base_points: int, die_sides: int) -> range:
    low, high = sorted((base_points + 1, base_points + die_sides))
    return range(low, high + 1)


def judge_roll(base: Verdict, expectation: Expectation, measured: float, tokens: Tokens, tooltips: TooltipSource,
               index: int, rolls: range) -> Verdict:
    token = tokens.readout.values[index]
    plain = PLAIN_TOKEN.fullmatch(token.text)
    effect = expectation.effect_index
    values = []
    for roll in rolls:
        readout = tooltips.read(expectation.rank_id, tokens.caster, (expectation.rank_id, effect, roll))
        if index >= len(readout.values) or readout.values[index].text != token.text:
            return replace(base, status='unmodelled', measured=measured,
                           explanation=f'{token.text} is unreadable with roll {roll} of effect {effect}')
        value = readout.values[index].value * token_divisor(token.text)
        values.append(value * plain_sign(roll) if plain else value)
    steps = [after - before for before, after in zip(values, values[1:])]
    if not (all(step >= -FLOAT_EPSILON for step in steps) or all(step <= FLOAT_EPSILON for step in steps)):
        return replace(base, status='unmodelled', measured=measured,
                       explanation=f'{token.text} is not monotone in the roll {rolls.start}..{rolls.stop - 1} of '
                                   f'effect {effect}')
    least, most = min(values), max(values)
    low, high = least - margin_of(least), most + margin_of(most)
    status = 'ok' if low - FLOAT_EPSILON <= measured <= high + FLOAT_EPSILON else 'alert'
    return replace(base, status=status, measured=measured, expected=(least + most) / 2, low=low, high=high,
                   explanation=f'{token.text} over the roll {rolls.start}..{rolls.stop - 1} of effect {effect} '
                               f'(spell_effect_value is one SpellEffectInfo::CalcValue roll): {least:g} to {most:g}, '
                               f'each bound widened by max({ABSOLUTE_TOLERANCE:g}, {RELATIVE_TOLERANCE:.1%})')


def token_drift(expectation: Expectation, tokens: Tokens | None) -> str | None:
    if tokens is None:
        return f'no tooltip reading for {expectation.label!r}'
    if tokens.error:
        return tokens.error
    ordinal = ORDINAL.search(expectation.label)
    values = tokens.readout.values
    if not ordinal or int(ordinal.group(1)) >= len(values):
        return f'no tooltip token for {expectation.label!r}'
    index = int(ordinal.group(1))
    if values[index].text != expectation.displayed:
        return f'token #{index} reads {values[index].text!r}, generated as {expectation.displayed!r}'
    return None


def judge_token(base: Verdict, expectation: Expectation, run: Run, measured: float, tokens: Tokens,
                tooltips: TooltipSource) -> Verdict:
    index = int(ORDINAL.search(expectation.label).group(1))
    token = tokens.readout.values[index]
    if expectation.check == 'aura_duration_ms':
        return judge_time(base, run, measured, token.value, f'{token.text} read with the measured stats')
    if expectation.effect_index is not None:
        base_points, die_sides = tooltips.effect_points(expectation.rank_id, expectation.effect_index)
        if die_sides not in FIXED_DIE_SIDES:
            return judge_roll(base, expectation, measured, tokens, tooltips, index, roll_range(base_points, die_sides))
    expected = token.value * token_divisor(token.text)
    plain = PLAIN_TOKEN.fullmatch(token.text)
    if plain:
        points = displayed_points(tooltips, plain, expectation.rank_id)
        return deterministic(base, measured, measured, expected * plain_sign(points),
                             f'{token.text} is shown unsigned; the expected value takes the sign of its Spell.dbc '
                             f'points {points}')
    if measured * expected < 0:
        return replace(base, status='ambiguous_tooltip', measured=measured, expected=expected,
                       explanation=f'{token.text} evaluates to {expected:g}, the measured value has the opposite sign')
    return deterministic(base, measured, measured, expected, f'{token.text} read with the measured stats')


def describe_modifiers(modifiers: tuple[Modifier, ...]) -> str:
    return ', '.join(f'{modifier.spell_id} effect {modifier.effect_index} aura {modifier.aura} '
                     f'{modifier.percent:+d}%' for modifier in modifiers) or 'none'


def judge_hit(base: Verdict, class_file: dict, expectation: Expectation, run: Run,
              hit_model: HitModelSource) -> Verdict:
    model = expectation.model or {}
    labels = model.get('measurements', {})
    total, count = run.values.get(labels.get('total')), run.values.get(labels.get('count'))
    if total is None or count is None:
        return replace(base, explanation=f'no hit measurements {labels} in {run.key} ({run.status}: {run.message})')
    mean = total / count if count > 0 else None
    minimum = model['minimum_hits']
    reasons = failure_reasons(run, expectation.rank_id)
    failures = f'; failed casts: {describe_failures(reasons)}' if reasons else ''
    if count <= 0 and reasons:
        return replace(base, status='unmeasured', measured=mean,
                       explanation=f'no usable hit{failures}')
    if count < minimum:
        return replace(base, status='insufficient_trials', measured=mean,
                       explanation=f'{count:g} usable hits, fewer than the {minimum} the mean needs{failures}')
    try:
        expected = hit_model(class_file, expectation, run.values)
    except Unmodelled as error:
        return replace(base, status='unmodelled', measured=mean, explanation=UNMODELLED + error.reason)
    except KeyError as error:
        return replace(base, measured=mean, explanation=f'measurement {error} is missing from {run.key}')
    shown = ' | '.join(expected.displayed)
    if shown != expectation.displayed:
        return replace(base, measured=mean, expected=expected.mean,
                       explanation=f'hit tokens with the measured stats {shown!r} differ from the generated '
                                   f'{expectation.displayed!r}')
    half = Z_99 * expected.sigma / math.sqrt(count)
    low, high = expected.mean - half, expected.mean + half
    status = 'ok' if low - FLOAT_EPSILON <= mean <= high + FLOAT_EPSILON else 'alert'
    return replace(base, status=status, measured=mean, expected=expected.mean, low=low, high=high,
                   explanation=f'{count:g} usable hits; {expected.kind} model mean {expected.mean:.3f} sigma '
                               f'{expected.sigma:.3f} from the measured stats and target, 99% interval of the mean; '
                               f'tooltip mean {expected.tooltip_mean:.2f} (display only); modifiers '
                               f'{describe_modifiers(expected.modifiers)}{failures}')


ProcPart = tuple[dict, Run, Expectation]


RateJudgement = tuple[str, float | None, float | None, str]


def rate_judgement(procs: float, trials: float, minimum: int, expected: float) -> RateJudgement:
    if procs < 0:
        return 'alert', None, None, 'fewer events than the trigger casts they exclude'
    if trials <= 0:
        return 'unmeasured', None, None, 'no trial'
    if procs > trials:
        return 'alert', None, None, 'more procs than trials'
    if trials < minimum:
        return 'insufficient_trials', None, None, f'fewer than the {minimum} trials the rate needs'
    low, high = wilson_interval(procs, trials)
    status = 'ok' if low - FLOAT_EPSILON <= expected <= high + FLOAT_EPSILON else 'alert'
    return status, low, high, f'rate {procs / trials:.4f}, Wilson 99% interval [{low:.4f}, {high:.4f}]'


def proc_readings(model: dict) -> list[dict]:
    return model.get('readings') or [{'name': 'triggering hits only', 'labels': [model['measurements']['trials']]}]


def player_casts(model: dict, run: Run, trigger: int) -> float:
    return model['part_attempts'] - len(failure_reasons(run, trigger)) if model.get('exclude_trigger_casts') else 0.0


def judge_proc(manifest: dict, parts: list[ProcPart], tooltips: TooltipSource) -> Verdict:
    first_entry, first_run, expectation = parts[0]
    model = expectation.model
    base = Verdict(expectation.label, 'alert', None, None, None, None, '', first_entry['key'], expectation.spell_id,
                   expectation.rank_id, expectation.check)
    labels = model['measurements']
    readings = proc_readings(model)
    event_labels = model.get('event_labels') or [labels['events']]
    wanted = [labels['aura']] + list(dict.fromkeys(
        event_labels + [label for reading in readings for label in reading['labels']]))
    trigger = model['trigger']['spell'] if model['trigger']['action'] == CAST else 0
    totals = dict.fromkeys(wanted[1:], 0.0)
    events = 0.0
    counted, without_aura, unmeasured, reasons = [], [], [], []
    for _, run, _ in parts:
        if trigger:
            reasons += failure_reasons(run, trigger)
        values = [run.values.get(label) for label in wanted]
        if None in values:
            unmeasured.append(f'{run.key} ({run.status}: {run.message})')
        elif values[0] <= 0:
            without_aura.append(run.key)
        else:
            counted.append(run.key)
            for label, value in zip(wanted[1:], values[1:]):
                totals[label] += value
            events -= player_casts(model, run, trigger)
    events += sum(totals[label] for label in event_labels)
    procs = events / model['events_per_proc']
    trials = totals[labels['trials']]
    notes = f'{len(counted)} of {model["parts"]} parts'
    if without_aura:
        notes += f'; aura {expectation.spell_id} absent in {", ".join(without_aura)}'
    if unmeasured:
        notes += f'; no proc measurements in {", ".join(unmeasured)}'
    if reasons:
        notes += f'; failed casts: {describe_failures(reasons)}'
    measured = procs / trials if trials > 0 else None
    if trials <= 0:
        status = 'alert' if unmeasured and not (without_aura or reasons) else 'unmeasured'
        return replace(base, status=status, measured=measured,
                       explanation=f'no usable trial: no triggering hit was measured ({notes})')
    try:
        caster = caster_stats_from(first_run.values, manifest['level'])
    except KeyError as error:
        return replace(base, measured=measured, explanation=f'base measurement {error} is missing from {first_run.key}')
    chance = chance_of(tooltips.read(expectation.rank_id, caster).values, expectation.displayed)
    if chance is None:
        return replace(base, measured=measured, explanation=f'the tooltip of {expectation.rank_id} no longer shows '
                                                            f'the chance token {expectation.displayed}')
    if abs(chance - model['chance_pct']) > FLOAT_EPSILON:
        return replace(base, measured=measured, expected=chance / 100,
                       explanation=f'{expectation.displayed} shows {chance:g}%, generated as {model["chance_pct"]:g}%')
    expected = chance / 100
    judged = []
    for reading in readings:
        excluded = events if reading.get('minus_events') else 0.0
        reading_trials = sum(totals[label] for label in reading['labels']) - excluded
        status, low, high, why = rate_judgement(procs, reading_trials, model['minimum_trials'], expected)
        judged.append((status, procs / reading_trials if reading_trials > 0 else None, low, high,
                       f'{reading["name"]}: {procs:g} procs in {reading_trials:g} trials, {why}: {status}'))
    statuses = {status for status, *_ in judged}
    status, rate, low, high, _ = judged[0]
    if len(statuses) > 1:
        status, low, high = 'ambiguous_tooltip', None, None
    readings_text = '; '.join(text for *_, text in judged)
    lead = 'the readings of the trials disagree; ' if len(statuses) > 1 else ''
    minus = f' minus the completed player casts of {trigger}' if model.get('exclude_trigger_casts') else ''
    return replace(base, status=status, measured=rate, expected=expected, low=low, high=high,
                   explanation=f'{lead}{readings_text} ({notes}); {expectation.displayed} shows {chance:g}%; '
                               f'{expectation.rule}; events: {" + ".join(event_labels)}{minus}, '
                               f'{model["events_per_proc"]} per proc')


def trigger_counts(run: Run, labels: dict, with_baseline: bool) -> tuple[float, float, float, float] | None:
    names = ('baseline_trials', 'without', 'trials', 'events') if with_baseline else ('trials', 'events')
    values = [run.values.get(labels[name]) for name in names]
    if None in values:
        return None
    return tuple(values) if with_baseline else (0.0, 0.0, *values)


def judge_trigger(parts: list[ProcPart]) -> Verdict:
    first_entry, _, expectation = parts[0]
    model = expectation.model
    base = Verdict(expectation.label, 'alert', None, None, None, None, '', first_entry['key'], expectation.spell_id,
                   expectation.rank_id, expectation.check)
    labels = model['measurements']
    trigger = model['trigger']['spell'] if model['trigger']['action'] == CAST else 0
    observed = f'{model["observe_metric"]} of {model["observe_spell"]}'
    trials = events = 0.0
    baseline: tuple[float, float] | None = None
    counted, without_aura, unmeasured, reasons = [], [], [], []
    for _, run, part in parts:
        if trigger:
            reasons += failure_reasons(run, trigger)
        with_baseline = part.model['baseline_attempts'] > 0
        found = trigger_counts(run, labels, with_baseline)
        aura = run.values.get(labels['aura'])
        if found is None or aura is None:
            unmeasured.append(f'{run.key} ({run.status}: {run.message})')
            continue
        baseline_trials, without, total_trials, total_events = found
        if with_baseline:
            baseline = (baseline_trials, without)
        if aura <= 0:
            without_aura.append(run.key)
            continue
        counted.append(run.key)
        trials += total_trials - baseline_trials
        events += total_events - without
    notes = f'{len(counted)} of {model["parts"]} parts'
    if without_aura:
        notes += f'; aura {expectation.spell_id} absent in {", ".join(without_aura)}'
    if unmeasured:
        notes += f'; no trigger measurements in {", ".join(unmeasured)}'
    if reasons:
        notes += f'; failed casts: {describe_failures(reasons)}'
    if baseline is not None and baseline[1] > 0:
        return replace(base, measured=baseline[1], expected=0.0, low=0.0, high=0.0,
                       explanation=f'{observed} occurred {baseline[1]:g} times in {baseline[0]:g} baseline trials '
                                   f'without the passive ({notes})')
    if trials <= 0:
        status = 'alert' if unmeasured and not (without_aura or reasons) else 'unmeasured'
        return replace(base, status=status, explanation=f'no usable trial with the passive learned ({notes})')
    expected = trials * model['per_trigger']
    low, high = expected - EVENT_TOLERANCE, expected + EVENT_TOLERANCE
    counts = (f'{events:g} events ({observed}) in {trials:g} trials ({model["trial_metric"]}), '
              f'{model["per_trigger"]:g} per trigger expects {expected:g}')
    judged = replace(base, measured=events, expected=expected, low=low, high=high)
    if trials < model['minimum_trials']:
        return replace(judged, status='insufficient_trials',
                       explanation=f'{counts}; fewer than the {model["minimum_trials"]} trials the check needs '
                                   f'({notes})')
    status = 'ok' if low - FLOAT_EPSILON <= events <= high + FLOAT_EPSILON else 'alert'
    if status == 'ok' and (baseline is None or baseline[0] <= 0):
        return replace(judged, status='unmeasured',
                       explanation=f'{counts}; the baseline without the passive has no trial, so the events are not '
                                   f'tied to the passive ({notes})')
    return replace(judged, status=status, explanation=f'{counts}; no event in {baseline[0]:g} baseline trials '
                                                      f'without the passive; {expectation.rule} ({notes})')


DETAIL_KEYS = ('config', 'baseline', 'index', 'passes', 'source', 'talents')


def stack_detail(model: dict | None, values: list[float] | None = None) -> dict:
    detail = {key: (model or {})[key] for key in DETAIL_KEYS if key in (model or {})}
    if values is not None:
        detail['per_pass'] = values
    return detail


def failures_note(runs: list[Run], spells: set[int] | None = None) -> str:
    by_spell: dict[int, list[int]] = {}
    for run in runs:
        for spell, reasons in run.cast_failures.items():
            if spells is None or spell in spells:
                by_spell.setdefault(spell, []).extend(reason for reason in reasons if reason != NO_CAST_FAILURE)
    parts = [f'{spell}: {describe_failures(reasons)}' for spell, reasons in sorted(by_spell.items()) if reasons]
    return f'; failed casts {"; ".join(parts)}' if parts else ''


def listed(values: list[float]) -> str:
    return ', '.join(f'{value:.6g}' for value in values)


def unusable_run(run: Run) -> str:
    return f'{run.key} ({run.status}: {run.message})'


def measured_stack_verdict(base: Verdict, model: dict, values: list[float], unusable: list[str], why: str) -> Verdict:
    passes = model['passes']
    detail = stack_detail(model, values)
    notes = f'{len(values)} of {passes} passes' + (f'; not usable: {", ".join(unusable)}' if unusable else '')
    if not values:
        return replace(base, detail=detail, explanation=f'no usable pass ({notes}); {why}')
    if len(values) < passes:
        return replace(base, status='insufficient_trials', measured=fmean(values), detail=detail,
                       explanation=f'{notes}, fewer than the {passes} the interval needs: {listed(values)}; {why}')
    mean, low, high = mean_interval(values)
    return replace(base, status=MEASURED, measured=mean, low=low, high=high, detail=detail,
                   explanation=f'{notes}: {listed(values)}; 99% Student t interval of the mean of the passes; {why}')


def judge_stack_dps(base: Verdict, parts: list[ProcPart]) -> Verdict:
    expectation = parts[0][2]
    model = expectation.model
    labels, seconds = model['measurements'], model['rotation_ms'] / 1000
    values, unusable = [], []
    for _, run, _ in parts:
        start, end = run.values.get(labels['health_start']), run.values.get(labels['health_end'])
        if start is None or end is None:
            unusable.append(unusable_run(run))
        else:
            values.append((start - end) / seconds)
    return measured_stack_verdict(base, model, values, unusable,
                                  expectation.rule + failures_note([run for _, run, _ in parts]))


def judge_stack_source(base: Verdict, parts: list[ProcPart]) -> Verdict:
    expectation = parts[0][2]
    model = expectation.model
    labels, seconds, source = model['measurements'], model['rotation_ms'] / 1000, model['source']
    values, counts, unusable = [], [], []
    for _, run, _ in parts:
        total, count = run.values.get(labels['total']), run.values.get(labels['count'])
        if total is None or count is None:
            unusable.append(unusable_run(run))
        else:
            values.append(total / seconds)
            counts.append(count)
    failures = failures_note([run for _, run, _ in parts], {source}) if source != MELEE_SOURCE else ''
    if values and not any(counts) and failures:
        return replace(base, status='unmeasured', measured=0.0, detail=stack_detail(model, values),
                       explanation=f'no hit of {source} in {len(values)} passes{failures}')
    return measured_stack_verdict(base, model, values, unusable,
                                  f'{expectation.rule}; hits per pass: {listed(counts)}{failures}')


def per_hit_means(runs: list[Run], labels: dict) -> tuple[list[float], list[str], list[str]]:
    means, empty, unusable = [], [], []
    for run in runs:
        total, count = run.values.get(labels['total']), run.values.get(labels['count'])
        if total is None or count is None:
            unusable.append(unusable_run(run))
        elif count <= 0:
            empty.append(run.key)
        else:
            means.append(total / count)
    return means, empty, unusable


def known_percents(manifest: dict, model: dict, runs: list[Run]) -> tuple[list[tuple[str, float]], str | None]:
    found = []
    for row in manifest.get('known_modifiers', []):
        if row['applies_to'] != 'damage' or not row['school_mask'] & model['school_mask']:
            continue
        present = [run.values.get(known_aura_label(row['spell_id']), 0) > 0 for run in runs]
        if all(present):
            found.append((f'known aura {row["spell_id"]} effect {row["effect_index"]} aura {row["aura"]}',
                          float(row['percent'])))
        elif any(present):
            return [], (f'known aura {row["spell_id"]} is present in {sum(present)} of {len(present)} passes, so the '
                        f'configurations differ by more than the talent')
    return found, None


def composition_readings(model: dict, known: list[tuple[str, float]]) -> list[tuple[str, float, str]]:
    bonus = model['bonus_pct']
    readings = [(MULTIPLIES, bonus, 'the bonus scales the per-hit damage of the previous configuration, known '
                                    'modifiers and earlier bonuses included')]
    others = known + [(f'{item["token"]} of {item["talent"]}', item['bonus_pct'])
                      for item in model.get('earlier_bonuses') or []]
    if others:
        stacked = sum(percent for _, percent in others)
        names = ', '.join(f'{name} {percent:+g}%' for name, percent in others)
        readings.append((ADDS, 100 * bonus / (100 + stacked),
                         f'the bonus adds to the other percents of the hit, {names}: 100 x {bonus:g} / (100 '
                         f'{stacked:+g})'))
    return readings


def passes_needed(passes: int, relative_half: float) -> int:
    return math.ceil(passes * (relative_half / MEAN_HALF_WIDTH) ** 2)


def judge_talent_delta(manifest: dict, parts: list[ProcPart], config_runs: dict[str, dict[str, Run]],
                       tooltips: TooltipSource) -> Verdict:
    entry, _, expectation = parts[0]
    model = expectation.model
    base = Verdict(expectation.label, 'alert', None, None, None, None, '', entry['key'], expectation.spell_id,
                   expectation.rank_id, expectation.check, stack_detail(model))
    source, passes = model['source'], model['passes']
    current_runs = list(config_runs.get(model['config'], {}).values())
    baseline_runs = list(config_runs.get(model['baseline'], {}).values())
    current, current_empty, current_unusable = per_hit_means(current_runs, model['measurements'])
    baseline, baseline_empty, baseline_unusable = per_hit_means(baseline_runs, model['measurements'])
    failures = failures_note(current_runs + baseline_runs, {source})
    notes = []
    for name, means, empty, unusable in ((model['config'], current, current_empty, current_unusable),
                                         (model['baseline'], baseline, baseline_empty, baseline_unusable)):
        note = f'{name}: {len(means)} of {passes} passes'
        if empty:
            note += f', no hit of {source} in {", ".join(empty)}'
        if unusable:
            note += f', not usable: {", ".join(unusable)}'
        notes.append(note)
    notes_text = '; '.join(notes)
    if (not current and current_empty) or (not baseline and baseline_empty):
        return replace(base, status='unmeasured',
                       explanation=f'no non-critical, unblocked hit of {source} ({notes_text}){failures}')
    if not current or not baseline:
        return replace(base, explanation=f'no per-hit measurement of {source} ({notes_text})')
    measured = (fmean(current) / fmean(baseline) - 1) * 100
    if len(current) < passes or len(baseline) < passes:
        return replace(base, status='insufficient_trials', measured=measured,
                       explanation=f'{notes_text}, fewer than the {passes} passes the interval needs{failures}')
    try:
        caster = caster_stats_from(current_runs[0].values, manifest['level'])
    except KeyError as error:
        return replace(base, measured=measured, explanation=f'base measurement {error} is missing from '
                                                            f'{current_runs[0].key}')
    shown = next((value.value for value in tooltips.read(expectation.rank_id, caster).values
                  if value.text == model['token']), None)
    if shown is None:
        return replace(base, measured=measured, explanation=f'the tooltip of {expectation.rank_id} no longer shows '
                                                            f'{model["token"]}')
    if abs(shown - model['bonus_pct']) > FLOAT_EPSILON:
        return replace(base, measured=measured, expected=shown,
                       explanation=f'{model["token"]} shows {shown:g}%, generated as {model["bonus_pct"]:g}%')
    known, mixed = known_percents(manifest, model, current_runs + baseline_runs)
    if mixed:
        return replace(base, status='unmodelled', measured=measured, explanation=mixed)
    delta, low, high = ratio_interval(current, baseline)
    half = (high - low) / 2
    relative = half / (100 + model['bonus_pct'])
    if relative > MEAN_HALF_WIDTH + FLOAT_EPSILON:
        needed = passes_needed(min(len(current), len(baseline)), relative)
        return replace(base, status='insufficient_trials', measured=delta, expected=model['bonus_pct'], low=low,
                       high=high, explanation=f'half-width {half:.3g} points is {relative:.2%} of the expected ratio '
                                              f'{1 + model["bonus_pct"] / 100:g}, above the {MEAN_HALF_WIDTH:.0%} '
                                              f'bound of hit means; about {needed} passes per configuration would '
                                              f'meet it (observed variance, same t quantile); per-hit means of '
                                              f'{source}: {listed(current)} against {listed(baseline)}{failures}')
    judged = [(name, expected, 'ok' if low - FLOAT_EPSILON <= expected <= high + FLOAT_EPSILON else 'alert', why)
              for name, expected, why in composition_readings(model, known)]
    statuses = {status for _, _, status, _ in judged}
    status = judged[0][2] if len(statuses) == 1 else 'ambiguous_tooltip'
    lead = 'the composition readings disagree; ' if len(statuses) > 1 else ''
    readings = '; '.join(f'{name} ({why}): expected {expected:.4g}%: {status}'
                         for name, expected, status, why in judged)
    return replace(base, status=status, measured=delta, expected=judged[0][1], low=low, high=high,
                   explanation=f'{lead}{readings}; per-hit means of {source} in {len(current)} and {len(baseline)} '
                               f'passes: {listed(current)} against {listed(baseline)}; 99% Welch interval of the '
                               f'ratio of the means, half-width {relative:.2%} of the expected ratio; '
                               f'{expectation.rule}{failures}')


def judge_stack(manifest: dict, stack_parts: dict[str, list[ProcPart]], tooltips: TooltipSource,
                hit_model: HitModelSource) -> list[Verdict]:
    config_runs: dict[str, dict[str, Run]] = {}
    for parts in stack_parts.values():
        for entry, run, expectation in parts:
            if expectation.check == STACK_DPS:
                config_runs.setdefault(expectation.model['config'], {})[entry['key']] = run
    verdicts = []
    for parts in stack_parts.values():
        entry, run, expectation = parts[0]
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', entry['key'], expectation.spell_id,
                       expectation.rank_id, expectation.check)
        if expectation.rule.startswith((UNMODELLED, UNREADABLE, AMBIGUOUS_TOOLTIP)):
            verdict = judge(manifest, entry, run, expectation, None, tooltips, hit_model)
            verdicts.append(replace(verdict, detail=stack_detail(expectation.model)))
        elif expectation.check == STACK_DPS:
            verdicts.append(judge_stack_dps(base, parts))
        elif expectation.check == STACK_SOURCE:
            verdicts.append(judge_stack_source(base, parts))
        else:
            verdicts.append(judge_talent_delta(manifest, parts, config_runs, tooltips))
    return verdicts


@dataclass(frozen=True)
class DeltaReading:
    name: str
    delta: float
    why: str


def delta_floor(metric: str) -> float:
    return FRACTIONAL_FLOOR if metric in FRACTIONAL_METRICS else ABSOLUTE_TOLERANCE


def delta_margin(metric: str, expected: float) -> float:
    floor = delta_floor(metric)
    return max(floor, RELATIVE_TOLERANCE * abs(expected))


def delta_status(metric: str, measured: float, expected: float) -> str:
    return 'ok' if abs(measured - expected) <= delta_margin(metric, expected) + FLOAT_EPSILON else 'alert'


def question_detail(kind: str, question: str, readings: list[dict], measured: float | None) -> dict:
    return {'kind': kind, 'question': question, 'readings': readings, 'measured': measured}


def missing_measurement(run: Run, label: str) -> str:
    return f'no measurement {label!r} in {run.key} ({run.status}: {run.message})'


def undivided(token: Displayed) -> float:
    return token.value if token.kind == DURATION_KIND else token.value * token_divisor(token.text)


def signed_token(token: Displayed, points: float | None, tooltips: TooltipSource, rank_id: int) -> tuple[float, str]:
    value = undivided(token)
    if points is not None:
        return (math.copysign(value, points),
                f'{token.text} reads {token.value:g}, signed by the effect points {points:g}')
    plain = PLAIN_TOKEN.fullmatch(token.text)
    if plain:
        shown = displayed_points(tooltips, plain, rank_id)
        return value * plain_sign(shown), f'{token.text} reads {token.value:g}, signed by its Spell.dbc points {shown}'
    return value, f'{token.text} reads {token.value:g}'


def present_modifiers(manifest: dict, model: dict, run: Run, tooltips: TooltipSource) -> list[tuple[str, float]]:
    kind = MODIFIER_KINDS.get(model['metric'])
    school = tooltips.spell_field(model['target'], 'SchoolMask')
    return [(f'known aura {row["spell_id"]} effect {row["effect_index"]} aura {row["aura"]} {row["percent"]:+d}%',
             float(row['percent'])) for row in manifest.get('known_modifiers', [])
            if row['applies_to'] == kind and row['school_mask'] & school
            and run.values.get(known_aura_label(row['spell_id']), 0) > 0]


def delta_readings(manifest: dict, run: Run, model: dict, before: float, value: float,
                   tooltips: TooltipSource) -> list[DeltaReading]:
    relation = model['relation']
    if relation in ('spell_mod_flat', 'add'):
        return [DeltaReading(relation, value, f'delta {value:+g}')]
    if relation in ('spell_mod_pct', 'scale', 'ratio'):
        return [DeltaReading(relation, before * value / 100, f'delta = before x {value:+g}%')]
    if relation == 'share':
        source = run.values[model['source_label']]
        return [DeltaReading(relation, source * value / 100,
                             f'delta = {model["source_label"]} {source:g} measured before the learn x {value:+g}%')]
    if relation == 'haste':
        return [DeltaReading('divides', before * 100 / (100 + value) - before, f'after = before / (1 {value:+g}%)')]
    if relation == 'crit_damage':
        return [DeltaReading('whole', before * value / 100, f'the whole critical hit x (1 {value:+g}%)'),
                DeltaReading('bonus', (before - CRITICAL_DAMAGE_BASE) * value / 100,
                             f'the critical bonus above the fixed base {CRITICAL_DAMAGE_BASE} x (1 {value:+g}%)')]
    if relation == 'composition':
        readings = [DeltaReading(MULTIPLIES, before * value / 100,
                                 'the bonus multiplies the value, known modifiers included')]
        known = present_modifiers(manifest, model, run, tooltips)
        if known:
            stacked = sum(percent for _, percent in known)
            names = ', '.join(name for name, _ in known)
            readings.append(DeltaReading(ADDS, before * value / (100 + stacked),
                                         f'the bonus adds to the percents of {names}: before x {value:g} / (100 '
                                         f'{stacked:+g})'))
        return readings
    return []


def target_name(tooltips: TooltipSource, spell_id: int) -> str:
    return f'{tooltips.spell_field(spell_id, "SpellName[enUS]")} {spell_id}'


def same_group(model: dict, other: dict) -> bool:
    def without_spell(fields: dict) -> dict:
        return {key: value for key, value in fields.items() if key != 'spell'}

    return ((other['effect'], other['metric'], without_spell(other['fields']))
            == (model['effect'], model['metric'], without_spell(model['fields'])))


def target_group(entry: dict, model: dict) -> list[dict]:
    return [data['model'] for data in entry['expectations']
            if data['check'] == PASSIVE_DELTA and data['model'] and same_group(model, data['model'])]


def interval_verdict(base: Verdict, metric: str, delta: float, judged: list[tuple[DeltaReading, str]],
                     context: str) -> Verdict:
    reading, status = judged[0]
    margin = delta_margin(metric, reading.delta)
    floor = delta_floor(metric)
    readings = '; '.join(f'{item.name} ({item.why}): expected delta {item.delta:+.6g}: {item_status}'
                         for item, item_status in judged)
    return replace(base, status=status, measured=delta, expected=reading.delta, low=reading.delta - margin,
                   high=reading.delta + margin,
                   explanation=f'{context}; {readings}; |delta - expected| <= max({floor:g}, '
                               f'{RELATIVE_TOLERANCE:.1%} of expected)')


def change(before: float, delta: float) -> str:
    return f'{100 * delta / before:+.4g}%' if before else f'{delta:+.6g}'


def judge_readings(base: Verdict, entry: dict, model: dict, judged: list[tuple[DeltaReading, str]], before: float,
                   delta: float, context: str, tooltips: TooltipSource) -> Verdict:
    statuses = {status for _, status in judged}
    if len(statuses) == 1:
        return interval_verdict(base, model['metric'], delta, judged, context)
    spell = (tooltips.spell_field(model['target'], 'SpellName[enUS]') if model['target'] is not None
             else model['metric'])
    subject = QUESTION_SUBJECTS.get(model['metric'], model['metric']).format(spell=spell)
    changes = ' or by '.join(change(before, reading.delta) for reading, _ in judged)
    question = f'With {entry["spell_name"]} learned, does {subject} change by {changes}?'
    readings = [{'name': reading.name, 'expected': before + reading.delta, 'delta': reading.delta, 'status': status,
                 'measured': before + delta} for reading, status in judged]
    text = '; '.join(f'{reading.name} ({reading.why}): expected delta {reading.delta:+.6g}: {status}'
                     for reading, status in judged)
    return replace(base, status='ambiguous_tooltip', measured=delta, expected=judged[0][0].delta,
                   explanation=f'the readings disagree; {context}; {text}',
                   detail={'question': question_detail(READINGS_QUESTION, question, readings, before + delta)})


def mask_matches(manifest: dict, run: Run, entry: dict, model: dict, value: float,
                 tooltips: TooltipSource) -> list[tuple[dict, float, float, DeltaReading]]:
    matches = []
    for other in target_group(entry, model):
        if other['named'] or not other['in_mask']:
            continue
        before, after = run.values.get(other['before_label']), run.values.get(other['after_label'])
        if before is None or after is None:
            continue
        readings = delta_readings(manifest, run, other, before, value, tooltips)
        if readings and delta_status(other['metric'], after - before, readings[0].delta) == 'ok':
            matches.append((other, before, after - before, readings[0]))
    return matches


def judge_modifier_target(base: Verdict, manifest: dict, entry: dict, run: Run, model: dict, value: float,
                          before: float, delta: float, judged: list[tuple[DeltaReading, str]], context: str,
                          tooltips: TooltipSource) -> Verdict:
    name = target_name(tooltips, model['target'])
    if not model['named'] and any(other['named'] for other in target_group(entry, model)):
        return replace(base, status=MEASURED, measured=delta, expected=judged[0][0].delta,
                       explanation=f'{context}; {name} is in the class mask but the tooltip names other spells: '
                                   f'reported, not judged')
    reading, status = judged[0]
    if status == 'ok' or model['in_mask']:
        return interval_verdict(base, model['metric'], delta, judged, context)
    matches = mask_matches(manifest, run, entry, model, value, tooltips)
    if not matches:
        verdict = interval_verdict(base, model['metric'], delta, judged, context)
        return replace(verdict, explanation=f'{verdict.explanation}; {name} is named outside the class mask and no '
                                            f'mask spell shows the expected delta')
    others = ', '.join(target_name(tooltips, other['target']) for other, *_ in matches)
    question = (f'{entry["spell_name"]} names {name}, but its modifier changed {model["metric"]} of {others} by '
                f'{reading.delta:+g} and of {name} by {delta:+g} here: with {entry["spell_name"]} learned on live, '
                f'does {name} change as the tooltip says?')
    readings = [{'name': name, 'expected': before + reading.delta, 'delta': reading.delta, 'status': status,
                 'measured': before + delta}]
    readings += [{'name': target_name(tooltips, other['target']), 'expected': other_before + other_reading.delta,
                  'delta': other_reading.delta, 'status': 'ok', 'measured': other_before + other_delta}
                 for other, other_before, other_delta, other_reading in matches]
    return replace(base, status='ambiguous_tooltip', measured=delta, expected=reading.delta,
                   explanation=f'the tooltip names {name}, the modifier applies to {others}; {context}; '
                               f'{reading.name}: expected delta {reading.delta:+.6g}',
                   detail={'question': question_detail(TEXT_QUESTION, question, readings, before + delta)})


def judge_passive(manifest: dict, entry: dict, run: Run | None, expectation: Expectation,
                  tooltips: TooltipSource) -> Verdict:
    verdict = passive_verdict(manifest, entry, run, expectation, tooltips)
    return replace(verdict, detail={**(verdict.detail or {}), PASSIVE_METRIC: expectation.model['metric']})


def passive_verdict(manifest: dict, entry: dict, run: Run | None, expectation: Expectation,
                    tooltips: TooltipSource) -> Verdict:
    model = expectation.model
    rank_id = expectation.rank_id
    base = Verdict(expectation.label, 'alert', None, None, None, None, '', entry['key'], expectation.spell_id,
                   rank_id, expectation.check)
    if run is None:
        return replace(base, explanation=f'{entry["key"]} has no scenario to measure {expectation.check}')
    aura = run.values.get(model['aura_label'])
    if aura is None:
        return replace(base, explanation=missing_measurement(run, model['aura_label']))
    if aura <= 0:
        requirements = ', '.join(f'{name} {tooltips.spell_field(rank_id, name)}' for name in AURA_REQUIREMENTS)
        return replace(base, status='unmeasured', explanation=f'passive aura {rank_id} absent after learn '
                                                              f'({requirements})')
    before, after = run.values.get(model['before_label']), run.values.get(model['after_label'])
    if before is None or after is None:
        label = model['before_label'] if before is None else model['after_label']
        return replace(base, status='alert' if model['judged'] else 'unmeasured',
                       explanation=missing_measurement(run, label))
    delta = after - before
    moved = f'{model["metric"]} {before:g} before and {after:g} after the learn, delta {delta:+g}'
    if not model['judged']:
        return replace(base, status=MEASURED, measured=delta,
                       explanation=f'{moved}; reported, not judged: the tooltip does not single out this quantity')
    effect = model['effect']
    if tooltips.spell_field(rank_id, f'EffectApplyAuraName[{effect}]') == VERSUS_AURA_STATE:
        state = tooltips.spell_field(rank_id, f'EffectMiscValue[{effect}]')
        return replace(base, status='unmeasured', measured=delta,
                       explanation=f'{moved}; aura {VERSUS_AURA_STATE} applies against a target in aura state '
                                   f'{state}, which the scenario neither establishes nor measures on the dummy')
    try:
        caster = caster_stats_from(run.values, manifest['level'])
    except KeyError as error:
        return replace(base, measured=delta, explanation=f'base measurement {error} is missing from {run.key}')
    token = next((value for value in tooltips.read(rank_id, caster).values if value.text == expectation.displayed),
                 None)
    if token is None:
        return replace(base, measured=delta, explanation=f'{expectation.displayed} is no token of the tooltip of '
                                                         f'{rank_id} read with the measured stats')
    value, sign = signed_token(token, model['points'], tooltips, rank_id)
    if model['relation'] == 'share' and model['source_label'] not in run.values:
        return replace(base, measured=delta, explanation=missing_measurement(run, model['source_label']))
    readings = delta_readings(manifest, run, model, before, value, tooltips)
    if not readings:
        return replace(base, measured=delta, explanation=f'no comparison for relation {model["relation"]!r}')
    judged = [(reading, delta_status(model['metric'], delta, reading.delta)) for reading in readings]
    context = f'{moved}; {sign}, expected {value:+g}'
    if model['named'] is not None:
        return judge_modifier_target(base, manifest, entry, run, model, value, before, delta, judged, context,
                                     tooltips)
    return judge_readings(base, entry, model, judged, before, delta, context, tooltips)


def roll_spread(expectation: Expectation, tooltips: TooltipSource) -> int:
    try:
        effect = expectation.effect_index
        if effect is None:
            effect = tooltips.first_effect(expectation.rank_id)
        if effect is None:
            return 0
        return max(0, abs(tooltips.effect_points(expectation.rank_id, effect)[1]) - 1)
    except Unreadable:
        return 0


def judge(manifest: dict, entry: dict, run: Run | None, expectation: Expectation, tokens: Tokens | None,
          tooltips: TooltipSource, hit_model: HitModelSource) -> Verdict:
    verdict = judge_expectation(manifest, entry, run, expectation, tokens, tooltips, hit_model)
    if expectation.check not in ROLLED_CHECKS or verdict.measured is None:
        return verdict
    spread = roll_spread(expectation, tooltips)
    if not spread:
        return verdict
    return replace(verdict, detail={**(verdict.detail or {}), ROLL_SPREAD: spread})


def judge_expectation(manifest: dict, entry: dict, run: Run | None, expectation: Expectation,
                      tokens: Tokens | None, tooltips: TooltipSource, hit_model: HitModelSource) -> Verdict:
    base = Verdict(expectation.label, 'alert', None, None, None, None, '', entry['key'], expectation.spell_id,
                   expectation.rank_id, expectation.check)
    rule, check = expectation.rule, expectation.check
    measured = run.values.get(expectation.label) if run else None
    if check == 'unmodelled' or rule.startswith(UNMODELLED) or rule.startswith(UNMEASURABLE):
        return replace(base, status='unmodelled', measured=measured, explanation=rule)
    if rule.startswith(UNREADABLE):
        return replace(base, status='unreadable', measured=measured, explanation=rule)
    if rule.startswith(AMBIGUOUS_TOOLTIP):
        return replace(base, status='ambiguous_tooltip', measured=measured, explanation=rule)
    if check == PASSIVE_DELTA:
        return judge_passive(manifest, entry, run, expectation, tooltips)
    if run is None:
        return replace(base, explanation=f'{entry["key"]} has no scenario to measure {check}')
    if check in TOKEN_CHECKS and rule.startswith(READ_RULE):
        drift = token_drift(expectation, tokens)
        if drift:
            return replace(base, measured=measured, explanation=drift)
    failure = failed_cast(run, expectation.rank_id) if check in CAST_DEPENDENT_CHECKS else None
    if failure:
        return replace(base, status='unmeasured', measured=measured, explanation=f'cast failed: {failure}')
    if check in HIT_CHECKS:
        return judge_hit(base, manifest['class_file'], expectation, run, hit_model)
    if measured is None:
        return replace(base, explanation=f'no measurement {expectation.label!r} in {run.key} '
                                         f'({run.status}: {run.message})')
    if check == 'known_aura':
        status = 'ok' if measured > 0 else 'alert'
        return replace(base, status=status, measured=measured, expected=1.0, low=1.0, high=1.0,
                       explanation=f'known aura {expectation.spell_id} on the reference character')
    if check == 'power_cost':
        divisor = COST_DIVISOR.fullmatch(rule)
        if divisor:
            shown = measured / int(divisor.group(1))
            return deterministic(base, shown, shown, float(expectation.displayed),
                                 f'spell_power_cost divided by the display divisor {divisor.group(1)}')
    if check == 'cooldown_ms':
        return judge_time(base, run, measured, float(expectation.displayed), rule)
    if check in TOKEN_CHECKS and rule.startswith(READ_RULE):
        return judge_token(base, expectation, run, measured, tokens, tooltips)
    return replace(base, measured=measured, explanation=f'no comparison for check {check!r} with rule {rule!r}')


def evaluate(manifest_path: Path, results_dir: Path, *, tooltips: TooltipSource | None = None,
             hit_model: HitModelSource | None = None) -> Comparison:
    manifest = json.loads(Path(manifest_path).read_text(encoding='utf-8'))
    runs, missing = load_runs(manifest, Path(results_dir))
    tooltips = tooltips or DbcTooltips(manifest.get('dbc_dir', DBC_DIR))
    hit_model = hit_model or measured_hit_model
    verdicts = []
    proc_parts: dict[str, list[ProcPart]] = {}
    stack_parts: dict[str, list[ProcPart]] = {}
    trigger_parts: dict[str, list[ProcPart]] = {}
    for entry in manifest['scenarios']:
        run = runs.get(entry['key'])
        if entry.get('file') and run is None:
            continue
        tokens = read_tokens(manifest['level'], entry, run, tooltips) if run and entry['kind'] == 'value' else None
        for data in entry['expectations']:
            expectation = Expectation(**data)
            if expectation.check == PROC_CHECK and run is not None:
                proc_parts.setdefault(expectation.label, []).append((entry, run, expectation))
            elif expectation.check in STACK_CHECKS and run is not None:
                stack_parts.setdefault(expectation.label, []).append((entry, run, expectation))
            elif expectation.check == TRIGGER_CHECK and run is not None:
                trigger_parts.setdefault(expectation.label, []).append((entry, run, expectation))
            else:
                verdicts.append(judge(manifest, entry, run, expectation, tokens, tooltips, hit_model))
    verdicts += [judge_proc(manifest, parts, tooltips) for parts in proc_parts.values()]
    verdicts += [judge_trigger(parts) for parts in trigger_parts.values()]
    verdicts += judge_stack(manifest, stack_parts, tooltips, hit_model)
    return Comparison(manifest, runs, missing, verdicts)


def compare(manifest: Path, results_dir: Path, *, tooltips: TooltipSource | None = None,
            hit_model: HitModelSource | None = None) -> list[Verdict]:
    return evaluate(manifest, results_dir, tooltips=tooltips, hit_model=hit_model).verdicts


def cell(value) -> str:
    if value is None:
        return ''
    if isinstance(value, float):
        return f'{value:.6g}'
    return str(value).replace('\t', ' ').replace('\n', ' ')


def alert_rows(verdicts: list[Verdict]) -> list[str]:
    rows = ['\t'.join(ALERT_COLUMNS)]
    for verdict in sorted(verdicts, key=lambda verdict: (verdict.spell_id, verdict.rank_id, verdict.label,
                                                         verdict.scenario)):
        if verdict.status in NOT_ALERTS:
            continue
        deviation = (verdict.measured - verdict.expected
                     if verdict.measured is not None and verdict.expected is not None else None)
        rows.append('\t'.join(cell(value) for value in (
            verdict.scenario, verdict.spell_id, verdict.rank_id, verdict.label, verdict.check, verdict.status,
            verdict.measured, verdict.expected, verdict.low, verdict.high, deviation, verdict.explanation)))
    return rows


def presence(runs: dict[str, Run], label: str) -> str:
    measured = [run.values[label] for run in runs.values() if label in run.values]
    return f'{sum(value > 0 for value in measured)} of {len(measured)} runs'


def passive_lines(manifest: dict, verdicts: list[Verdict]) -> list[str]:
    families = {(entry['key'], data['label']): (data['model'] or {}).get('family', '')
                for entry in manifest['scenarios'] if entry['kind'] == 'passive' for data in entry['expectations']}
    by_family: dict[str, Counter] = {}
    for verdict in verdicts:
        family = families.get((verdict.scenario, verdict.label))
        if family is not None:
            by_family.setdefault(family, Counter())[verdict.status] += 1
    if not by_family:
        return []
    lines = ['', '## Passives', '', 'Verdicts of the passive effects by measurement family.', '',
             '| family | ' + ' | '.join(STATUSES) + ' |', '|---|' + '---|' * len(STATUSES)]
    for family in sorted(by_family):
        counts = ' | '.join(str(by_family[family].get(status, 0)) for status in STATUSES)
        lines.append(f'| {family} | {counts} |')
    return lines


def report_lines(manifest: dict, manifest_path: Path, results_dir: Path, runs: dict[str, Run], missing: list[str],
                 verdicts: list[Verdict]) -> list[str]:
    statuses = Counter(verdict.status for verdict in verdicts)
    failed = sorted((key, run) for key, run in runs.items() if run.status != 'passed')
    lines = [f'# Class conformance: {manifest["class_name"]} (class {manifest["class_id"]})', '',
             f'- Manifest: `{manifest_path}`', f'- Results: `{results_dir}`',
             f'- Scenarios: {len(runs)} with a result, {len(missing)} without a result, {len(failed)} not passed',
             '', '## Verdicts by status', '', '| status | count |', '|---|---|']
    lines += [f'| {status} | {statuses.get(status, 0)} |' for status in STATUSES]
    lines += ['', '## Known modifiers', '',
              'Applied to a hit model only when the run measures the aura on the character; values from Spell.dbc.',
              '', '| aura | effect | aura type | EffectBasePoints | EffectRealPointsPerLevel | value at level '
              f'{manifest["level"]} | measured present |', '|---|---|---|---|---|---|---|']
    modifiers = manifest.get('known_modifiers', [])
    for aura in manifest['class_file'].get('known_auras', []):
        rows = [modifier for modifier in modifiers if modifier['spell_id'] == aura]
        present = presence(runs, known_aura_label(aura))
        if not rows:
            lines.append(f'| {aura} | | no damage or healing modifier | | | | {present} |')
        for row in rows:
            lines.append(f'| {aura} | {row["effect_index"]} | {row["aura"]} | {row["base_points"]} | '
                         f'{row["real_points_per_level"]:g} | {row["percent"]:+d}% | {present} |')
    probes = manifest['class_file'].get('probe_auras', [])
    if probes:
        lines += ['', '## Probe auras', '', 'Measured and reported, never used to explain a deviation.', '',
                  '| aura | measured present |', '|---|---|']
        lines += [f'| {aura} | {presence(runs, probe_aura_label(aura))} |' for aura in probes]
    names = {entry['spell_id']: entry['spell_name'] for entry in manifest['scenarios']}
    by_spell: dict[int, Counter] = {}
    for verdict in verdicts:
        if verdict.check != 'known_aura':
            by_spell.setdefault(verdict.spell_id, Counter())[verdict.status] += 1
    lines += ['', '## Verdicts by spell', '', '| spell | name | ' + ' | '.join(STATUSES) + ' |',
              '|---|---|' + '---|' * len(STATUSES)]
    for spell_id in sorted(by_spell):
        counts = ' | '.join(str(by_spell[spell_id].get(status, 0)) for status in STATUSES)
        lines.append(f'| {spell_id} | {names.get(spell_id, "")} | {counts} |')
    lines += passive_lines(manifest, verdicts)
    if missing:
        lines += ['', '## Scenarios without a result', ''] + [f'- `{key}`' for key in missing]
    if failed:
        lines += ['', '## Runs that did not pass', ''] + [f'- `{key}`: {run.status}: {run.message}'
                                                          for key, run in failed]
    return lines + ['']


def write_outputs(manifest_path: Path, results_dir: Path, verdicts: list[Verdict], out_dir: Path) -> tuple[Path, Path]:
    manifest = json.loads(Path(manifest_path).read_text(encoding='utf-8'))
    runs, missing = load_runs(manifest, Path(results_dir))
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    alerts, report = out_dir / ALERTS_FILE, out_dir / REPORT_FILE
    alerts.write_text('\n'.join(alert_rows(verdicts)) + '\n', encoding='utf-8')
    report.write_text('\n'.join(report_lines(manifest, Path(manifest_path), Path(results_dir), runs, missing,
                                             verdicts)), encoding='utf-8')
    write_verdicts(manifest, Path(manifest_path), Path(results_dir), verdicts, out_dir)
    return alerts, report


def write_verdicts(manifest: dict, manifest_path: Path, results_dir: Path, verdicts: list[Verdict],
                   out_dir: Path) -> Path:
    document = {'schema': VERDICTS_SCHEMA, 'class_id': manifest['class_id'], 'class_name': manifest['class_name'],
                'level': manifest['level'], 'manifest': str(manifest_path), 'results': str(results_dir),
                'verdicts': [asdict(verdict) for verdict in verdicts]}
    path = Path(out_dir) / VERDICTS_FILE
    path.write_text(json.dumps(document, indent=2) + '\n', encoding='utf-8')
    return path


def read_verdicts(directory: Path) -> tuple[dict, list[Verdict]]:
    path = Path(directory) / VERDICTS_FILE
    if not path.is_file():
        raise ValueError(f'{path} does not exist; run conformance.py compare with this version to write it')
    document = json.loads(path.read_text(encoding='utf-8'))
    if document.get('schema') != VERDICTS_SCHEMA:
        raise ValueError(f'{path} has schema {document.get("schema")!r}, expected {VERDICTS_SCHEMA}')
    header = {key: value for key, value in document.items() if key != 'verdicts'}
    return header, [Verdict(**data) for data in document['verdicts']]


def amount(value: float | None, digits: int = 1) -> str:
    return '' if value is None else f'{value:.{digits}f}'


def change_decision(before: Verdict | None, after: Verdict) -> tuple[str, str]:
    if before is None:
        return '', ''
    if before.status != MEASURED or after.status != MEASURED:
        return '', f'no: DPS {before.status} then {after.status}'
    if min(fmean(before.detail['per_pass']), fmean(after.detail['per_pass'])) <= 0:
        return '', 'no: DPS mean is not above 0 on a side'
    delta, low, high = ratio_interval(after.detail['per_pass'], before.detail['per_pass'])
    relative = (high - low) / 2 / (100 + delta)
    span = f'{low:.2f} to {high:.2f}'
    if low <= 0 <= high:
        return span, 'no: the interval holds 0'
    if relative > MEAN_HALF_WIDTH + FLOAT_EPSILON:
        return span, f'no: half-width {relative:.2%} of the ratio, above {MEAN_HALF_WIDTH:.0%}'
    return span, 'yes'


def stack_runs(manifest: dict, runs: dict[str, Run]) -> dict[str, Run]:
    keys = {entry['key'] for entry in manifest['scenarios'] if entry['kind'] == 'stack'}
    return {key: run for key, run in runs.items() if key in keys}


def lever_lines(manifest: dict, manifest_path: Path, results_dir: Path, runs: dict[str, Run],
                verdicts: list[Verdict]) -> list[str]:
    class_file = manifest['class_file']
    rotation = class_file.get('rotation', {})
    sources = rotation.get('sources', []) + [MELEE_SOURCE]
    found = levers(verdicts)
    by_config = {verdict.detail['config']: verdict for verdict in verdicts
                 if verdict.check == STACK_DPS and verdict.detail}
    deltas = sorted((verdict for verdict in verdicts if verdict.check == TALENT_DELTA and verdict.detail),
                    key=lambda verdict: (verdict.detail['index'], verdict.spell_id))
    cycle = ', '.join(f'{step["action"]} {step.get("spell", step.get("ms", ""))}' for step in rotation.get('cycle', []))
    seconds = rotation['cycles'] * sum(step['ms'] for step in rotation['cycle'] if step['action'] == 'wait') / 1000
    lines = [f'# Lever map: {manifest["class_name"]} (class {manifest["class_id"]})', '',
             f'- Manifest: `{manifest_path}`', f'- Results: `{results_dir}`',
             f'- Rotation ({rotation.get("source", "class file")}): {rotation["cycles"]} cycles of [{cycle}], '
             f'auto attack {"on" if rotation.get("auto_attack") else "off"}, drain {rotation["drain_ms"]} ms; '
             f'damage per second of rotation ({seconds:g} s); the configurations add talents cumulatively.',
             '- Interval: 99% Student t interval of the mean of the passes; a talent delta is the ratio of the mean '
             'non-critical, unblocked hits of its source against the previous configuration, with a Welch interval.',
             '', '## Configurations', '',
             '| config | talents added | passes | DPS | 99% interval | change | change % | change 99% interval | '
             'decisive | tooltip bonus % | status |', '|---|---|---|---|---|---|---|---|---|---|---|']
    previous = None
    for lever in found:
        verdict = by_config[lever.config]
        change = (lever.dps_mean - previous.dps_mean
                  if previous and previous.dps_mean is not None and lever.dps_mean is not None else None)
        talents = ', '.join(str(talent) for talent in verdict.detail.get('talents', [])) or 'none'
        interval = f'{amount(lever.dps_low)} to {amount(lever.dps_high)}' if lever.dps_low is not None else ''
        span, decisive = change_decision(by_config[previous.config] if previous else None, verdict)
        lines.append(f'| {lever.config} | {talents} | {len(verdict.detail.get("per_pass", []))} | '
                     f'{amount(lever.dps_mean)} | {interval} | {amount(change)} | {amount(lever.delta_pct, 2)} | '
                     f'{span} | {decisive} | {amount(lever.tooltip_delta_pct, 2)} | {verdict.status} |')
        previous = lever
    names = ['melee' if source == MELEE_SOURCE else str(source) for source in sources]
    lines += ['', '## Damage per second by source', '',
              '| config | ' + ' | '.join(names) + ' | unattributed |', '|---|' + '---|' * (len(names) + 1)]
    for lever in found:
        cells = [amount(lever.sources.get(source)) for source in sources]
        rest = (lever.dps_mean - sum(lever.sources.values())) if lever.dps_mean is not None else None
        lines.append(f'| {lever.config} | ' + ' | '.join(cells) + f' | {amount(rest)} |')
    lines += ['', '## Change by source against the previous configuration', '',
              '| config | ' + ' | '.join(names) + ' |', '|---|' + '---|' * len(names)]
    for before, after in zip(found, found[1:]):
        cells = [amount(after.sources[source] - before.sources[source])
                 if source in after.sources and source in before.sources else '' for source in sources]
        lines.append(f'| {after.config} | ' + ' | '.join(cells) + ' |')
    lines += ['', '## Talent deltas', '', 'Measured change of the per-hit damage of the source, in percent.', '',
              '| config | talent | source | measured % | 99% interval | tooltip % | status | explanation |',
              '|---|---|---|---|---|---|---|---|']
    for verdict in deltas:
        interval = f'{amount(verdict.low, 2)} to {amount(verdict.high, 2)}' if verdict.low is not None else ''
        lines.append(f'| {verdict.detail["config"]} | {verdict.spell_id} | {verdict.detail.get("source", "")} | '
                     f'{amount(verdict.measured, 2)} | {interval} | {amount(verdict.expected, 2)} | {verdict.status} | '
                     f'{cell(verdict.explanation)} |')
    measured_runs = stack_runs(manifest, runs)
    lines += ['', '## Known modifiers', '', 'Measured on the character in the stack runs; values from Spell.dbc.', '',
              '| aura | effect | aura type | value | measured present |', '|---|---|---|---|---|']
    for aura in class_file.get('known_auras', []):
        rows = [row for row in manifest.get('known_modifiers', []) if row['spell_id'] == aura]
        present = presence(measured_runs, known_aura_label(aura))
        lines += [f'| {aura} | {row["effect_index"]} | {row["aura"]} | {row["percent"]:+d}% | {present} |'
                  for row in rows] or [f'| {aura} | | | | {present} |']
    for aura in class_file.get('probe_auras', []):
        lines.append(f'| {aura} (probe) | | | | {presence(measured_runs, probe_aura_label(aura))} |')
    lines += ['', '## Passes', '']
    lines += [f'- {verdict.label}: {verdict.status}: {verdict.explanation}' for verdict in verdicts
              if verdict.check in (STACK_DPS, STACK_SOURCE)]
    return lines + ['']


def write_levers(manifest_path: Path, results_dir: Path, verdicts: list[Verdict], out_dir: Path) -> Path:
    manifest = json.loads(Path(manifest_path).read_text(encoding='utf-8'))
    runs, _ = load_runs(manifest, Path(results_dir))
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    path = out_dir / LEVERS_FILE
    path.write_text('\n'.join(lever_lines(manifest, Path(manifest_path), Path(results_dir), runs, verdicts)),
                    encoding='utf-8')
    return path
