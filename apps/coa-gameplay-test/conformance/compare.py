from collections import Counter
from dataclasses import dataclass, replace
import hashlib
import json
import math
from pathlib import Path
import re
from typing import Callable, Mapping

from hits import UNMODELLED, Z_99, HitModel, Modifier, Unmodelled, measured_hit_model
from profile import DBC_DIR, caster_stats_from, known_aura_label, probe_aura_label
from tooltip import CasterStats, Readout, read_tooltip
from values import UNMEASURABLE, UNREADABLE, Expectation, dataset

STATUSES = ('ok', 'alert', 'unreadable', 'unmodelled', 'ambiguous_tooltip', 'insufficient_trials')
ABSOLUTE_TOLERANCE = 1.0
RELATIVE_TOLERANCE = 0.005
FLOAT_EPSILON = 1e-9
TOKEN_CHECKS = frozenset({'effect_value', 'aura_amount', 'aura_duration_ms'})
HIT_CHECKS = frozenset({'hit_mean', 'melee_mean'})
READ_RULE = 'read '
ORDINAL = re.compile(r'#(\d+)$')
DIVIDED_TOKEN = re.compile(r'\$/(\d+);')
UNSIGNED_TOKEN = re.compile(r'\$(?:/\d+;)?\d*[smM][1-3]')
COST_DIVISOR = re.compile(r'ManaCost divisor (\d+)')
EXPLORATORY = ('gameplay', 'exploratory')
ALERT_COLUMNS = ('scenario', 'spell_id', 'rank_id', 'label', 'check', 'status', 'measured', 'expected', 'low', 'high',
                 'deviation', 'explanation')
ALERTS_FILE = 'alerts.tsv'
REPORT_FILE = 'report.md'

Reader = Callable[[int, CasterStats], Readout]
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


@dataclass(frozen=True)
class Run:
    key: str
    status: str
    message: str
    values: dict[str, float]
    steps: list[dict]
    max_step_ms: float | None


@dataclass(frozen=True)
class Tokens:
    readout: Readout | None
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
               result.get('steps', []), None if max_step is None else number(max_step, 'max_step_ms'))


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


def dbc_reader(manifest: dict) -> Reader:
    dbc = dataset(Path(manifest.get('dbc_dir', DBC_DIR)))
    return lambda rank_id, caster: read_tooltip(dbc, rank_id, caster)


def read_tokens(level: int, entry: dict, run: Run, reader: Reader) -> Tokens:
    try:
        caster = caster_stats_from(run.values, level)
    except KeyError as error:
        return Tokens(None, f'base measurement {error} is missing from {run.key}')
    readout = reader(entry['rank_id'], caster)
    texts = [value.text for value in readout.values]
    if texts != entry['tokens']:
        return Tokens(None, f'tooltip tokens read with the measured stats {texts} differ from the generated '
                            f'tokens {entry["tokens"]}')
    return Tokens(readout)


def deterministic(base: Verdict, measured: float, judged: float, expected: float, why: str) -> Verdict:
    margin = max(ABSOLUTE_TOLERANCE, RELATIVE_TOLERANCE * abs(expected))
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
    return sum(number(step.get('elapsed_ms', 0), 'elapsed_ms') + run.max_step_ms
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


def judge_token(base: Verdict, expectation: Expectation, run: Run, measured: float, tokens: Tokens) -> Verdict:
    if tokens.error:
        return replace(base, measured=measured, explanation=tokens.error)
    ordinal = ORDINAL.search(expectation.label)
    values = tokens.readout.values
    if not ordinal or int(ordinal.group(1)) >= len(values):
        return replace(base, measured=measured, explanation=f'no tooltip token for {expectation.label!r}')
    index = int(ordinal.group(1))
    token = values[index]
    if token.text != expectation.displayed:
        return replace(base, measured=measured,
                       explanation=f'token #{index} reads {token.text!r}, generated as {expectation.displayed!r}')
    if expectation.check == 'aura_duration_ms':
        return judge_time(base, run, measured, token.value, f'{token.text} read with the measured stats')
    expected = token.value * token_divisor(token.text)
    if UNSIGNED_TOKEN.fullmatch(token.text):
        return deterministic(base, measured, abs(measured), expected,
                             f'{token.text} is shown unsigned, so the magnitude of the measured value is compared')
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
    if count < minimum:
        return replace(base, status='insufficient_trials', measured=mean,
                       explanation=f'{count:g} usable hits, fewer than the {minimum} the mean needs')
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
                               f'{describe_modifiers(expected.modifiers)}')


def judge(manifest: dict, entry: dict, run: Run | None, expectation: Expectation, tokens: Tokens | None,
          hit_model: HitModelSource) -> Verdict:
    base = Verdict(expectation.label, 'alert', None, None, None, None, '', entry['key'], expectation.spell_id,
                   expectation.rank_id, expectation.check)
    rule, check = expectation.rule, expectation.check
    measured = run.values.get(expectation.label) if run else None
    if check == 'unmodelled' or rule.startswith(UNMODELLED) or rule.startswith(UNMEASURABLE):
        return replace(base, status='unmodelled', measured=measured, explanation=rule)
    if rule.startswith(UNREADABLE):
        return replace(base, status='unreadable', measured=measured, explanation=rule)
    if run is None:
        return replace(base, explanation=f'{entry["key"]} has no scenario to measure {check}')
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
        return judge_token(base, expectation, run, measured, tokens)
    return replace(base, measured=measured, explanation=f'no comparison for check {check!r} with rule {rule!r}')


def evaluate(manifest_path: Path, results_dir: Path, *, reader: Reader | None = None,
             hit_model: HitModelSource | None = None) -> Comparison:
    manifest = json.loads(Path(manifest_path).read_text(encoding='utf-8'))
    runs, missing = load_runs(manifest, Path(results_dir))
    reader = reader or dbc_reader(manifest)
    hit_model = hit_model or measured_hit_model
    verdicts = []
    for entry in manifest['scenarios']:
        run = runs.get(entry['key'])
        if entry.get('file') and run is None:
            continue
        tokens = read_tokens(manifest['level'], entry, run, reader) if run and entry['kind'] == 'value' else None
        verdicts += [judge(manifest, entry, run, Expectation(**data), tokens, hit_model)
                     for data in entry['expectations']]
    return Comparison(manifest, runs, missing, verdicts)


def compare(manifest: Path, results_dir: Path, *, reader: Reader | None = None,
            hit_model: HitModelSource | None = None) -> list[Verdict]:
    return evaluate(manifest, results_dir, reader=reader, hit_model=hit_model).verdicts


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
        if verdict.status == 'ok':
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
    return alerts, report
