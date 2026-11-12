from dataclasses import dataclass
import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
from typing import Callable, Mapping, Sequence

from compare import (CONFORMANT, STATUSES, BuildMismatch, ScenarioDrift, Verdict, evaluate, read_verdicts,
                     write_outputs)
from diff import diff_directories, key_of, write_impact

SCENARIO_DIR = 'scenarios'
MANIFEST_FILE = 'manifest.json'
RUN_DIR = 'run{}'
LOG_FILE = 'verify.log'
REPORT_COPY = 'verify-report.json'
FLIPS_DIR = 'flips'
FRAGMENT_FILE = 'fragment.json'
PILOT_DIR = 'pilot'
SUMMARY_FILE = 'summary.json'
SUMMARY_SCHEMA = 1
MIN_RUNS = 2
DEFAULT_TIMEOUT_MS = 600000
TERMINATE_GRACE_S = 30
VERIFY_LINE = re.compile(r'^VERIFY ALL: (PASSED|FAILED|INCOMPLETE) (.+)$', re.MULTILINE)
OK_EXIT = 0
FLIP_EXIT = 1
DRIFT_EXIT = 2
MISSING_EXIT = 3
FAILURE_EXIT = 4
BUILD_STAGE = 'build'
GAMEPLAY_STAGE = 'gameplay'


class ProveFailure(Exception):
    def __init__(self, reason: str, exit_code: int = FAILURE_EXIT, record: dict | None = None):
        super().__init__(reason)
        self.reason = reason
        self.exit_code = exit_code
        self.record = record


class RunTimeout(Exception):
    pass


@dataclass(frozen=True)
class ProveSpec:
    out: Path
    worktree: Path
    runs: int = MIN_RUNS
    build: bool = False
    timeout_ms: int = DEFAULT_TIMEOUT_MS
    verify: tuple[str, ...] = ('coa-verify',)


@dataclass(frozen=True)
class RunOutcome:
    number: int
    directory: Path
    results: Path
    header: dict
    verdicts: list[Verdict]
    record: dict


Runner = Callable[[Sequence[str], float, Path], int]
Generate = Callable[[Path], Path]
Rows = Callable[[dict], list[dict]]
Enrich = Callable[[list[dict], Sequence[RunOutcome]], list[dict]]
Annotate = Callable[[Sequence[RunOutcome]], Mapping]
Compare = Callable[[Path, Path, Path], tuple[int, list[str]]]


@dataclass(frozen=True)
class Pilot:
    generate: Callable[[Path], Path | None]
    size: Callable[[Sequence[Verdict]], tuple[Mapping[str, int], list[dict]]]
    sized: Callable[[Path, Mapping[str, int]], Path]


def stop(process: subprocess.Popen):
    try:
        os.killpg(process.pid, signal.SIGTERM)
        process.wait(timeout=TERMINATE_GRACE_S)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGKILL)
        process.wait()
    except ProcessLookupError:
        process.wait()


def run_command(command: Sequence[str], timeout_s: float, log: Path) -> int:
    with Path(log).open('w', encoding='utf-8') as stream:
        process = subprocess.Popen(list(command), stdout=stream, stderr=subprocess.STDOUT, start_new_session=True)
        try:
            return process.wait(timeout=timeout_s)
        except subprocess.TimeoutExpired:
            stop(process)
            raise RunTimeout(f'{command[0]} did not finish within {timeout_s:g} s') from None
        except BaseException:
            stop(process)
            raise


def is_under(path: Path, roots: Sequence[Path]) -> bool:
    resolved = Path(path).resolve()
    return any(resolved == root.resolve() or root.resolve() in resolved.parents for root in roots)


def verify_command(spec: ProveSpec, number: int, files: Sequence[Path]) -> list[str]:
    stages = f'{BUILD_STAGE},{GAMEPLAY_STAGE}' if spec.build and number == 1 else GAMEPLAY_STAGE
    return [*spec.verify, '--worktree', str(spec.worktree), '--ram', '--stages', stages,
            '--scenario', *map(str, files)]


def verify_report(log: Path) -> tuple[str, Path]:
    matches = VERIFY_LINE.findall(Path(log).read_text(encoding='utf-8', errors='replace'))
    if not matches:
        raise ProveFailure(f'{log} holds no "VERIFY ALL: <status> <report.json>" line')
    status, path = matches[-1]
    return status.lower(), Path(path.strip())


def stage_records(report: dict) -> dict[str, dict]:
    return {name: {'status': stage.get('status'), 'seconds': stage.get('seconds')}
            for name, stage in report.get('stages', {}).items()}


def count_statuses(verdicts: Sequence[Verdict]) -> dict[str, int]:
    return {status: sum(verdict.status == status for verdict in verdicts) for status in STATUSES}


def compare_run(manifest_path: Path, results: Path, directory: Path) -> tuple[int, list[str]]:
    comparison = evaluate(manifest_path, results)
    write_outputs(manifest_path, results, comparison.verdicts, directory)
    return len(comparison.runs), list(comparison.missing)


def execute_run(spec: ProveSpec, number: int, manifest_path: Path, files: Sequence[Path], runner: Runner,
                compare: Compare) -> RunOutcome:
    directory = spec.out / RUN_DIR.format(number)
    directory.mkdir()
    command = verify_command(spec, number, files)
    log = directory / LOG_FILE
    try:
        returncode = runner(command, spec.timeout_ms / 1000, log)
    except RunTimeout as timeout:
        raise ProveFailure(f'run {number}: {timeout}') from timeout
    status, report_path = verify_report(log)
    if not report_path.is_file():
        raise ProveFailure(f'run {number}: {report_path} does not exist')
    shutil.copy2(report_path, directory / REPORT_COPY)
    report = json.loads(report_path.read_text(encoding='utf-8'))
    stages = stage_records(report)
    if spec.build and number == 1 and stages.get(BUILD_STAGE, {}).get('status') != 'passed':
        raise ProveFailure(f'run {number}: the build stage is {stages.get(BUILD_STAGE, {}).get("status")}, see {log}')
    results = report_path.parent
    try:
        with_result, without_result = compare(manifest_path, results, directory)
    except ScenarioDrift as drift:
        raise ProveFailure(f'run {number}: scenario drift, no verdict:\n{drift}', DRIFT_EXIT) from drift
    except BuildMismatch as mismatch:
        raise ProveFailure(f'run {number}: {mismatch}') from mismatch
    header, verdicts = read_verdicts(directory)
    record = {'run': number, 'directory': str(directory), 'command': command, 'returncode': returncode,
              'verify_status': status, 'report': str(report_path), 'results': str(results), 'stages': stages,
              'gameplay_seconds': stages.get(GAMEPLAY_STAGE, {}).get('seconds'),
              'scenarios_with_result': with_result, 'scenarios_without_result': len(without_result),
              'missing_results': sorted(without_result),
              'build': header.get('build'), 'server_commit': header.get('server_commit'),
              'counts': count_statuses(verdicts)}
    if without_result:
        shown = ', '.join(sorted(without_result))
        raise ProveFailure(f'run {number}: {len(without_result)} of {with_result + len(without_result)} scenarios '
                           f'produced no result in {results}: {shown}', MISSING_EXIT, record)
    return RunOutcome(number, directory, results, header, verdicts, record)


CONFORMANT_CLASS = 'conformant'
NOT_JUDGED = 'insufficient_trials'


def status_class(status: str) -> str:
    return CONFORMANT_CLASS if status in CONFORMANT else status


def verdict_statuses(verdicts: Sequence[Verdict]) -> dict[tuple[str, str, str], str]:
    return {key_of(verdict): verdict.status for verdict in verdicts}


def judged(status: str | None) -> bool:
    return status != NOT_JUDGED


def find_flips(runs: Sequence[RunOutcome]) -> list[dict]:
    statuses = [verdict_statuses(run.verdicts) for run in runs]
    keys = sorted(set().union(*statuses))
    flips = []
    for key in keys:
        seen = [status.get(key) for status in statuses]
        missing = None in seen and any(value is not None for value in seen)
        if missing or len({status_class(value) for value in seen if value is not None and judged(value)}) > 1:
            flips.append({'label': key[0], 'check': key[1], 'scenario': key[2], 'statuses': seen})
    return flips


def trials_needed_of(verdict: Verdict) -> int | None:
    return (verdict.detail or {}).get('trials_needed')


def find_not_judged(runs: Sequence[RunOutcome]) -> list[dict]:
    by_key: dict[tuple[str, str, str], list[Verdict | None]] = {}
    for number, run in enumerate(runs):
        for verdict in run.verdicts:
            by_key.setdefault(key_of(verdict), [None] * len(runs))[number] = verdict
    entries = []
    for key in sorted(by_key):
        verdicts = by_key[key]
        unjudged = [verdict for verdict in verdicts if verdict is not None and not judged(verdict.status)]
        if not unjudged:
            continue
        needed = [value for value in map(trials_needed_of, unjudged) if value is not None]
        entries.append({'label': key[0], 'check': key[1], 'scenario': key[2],
                        'statuses': [None if verdict is None else verdict.status for verdict in verdicts],
                        'trials_needed': max(needed) if needed else None})
    return entries


def build_of(outcome: RunOutcome) -> tuple:
    return outcome.header.get('server_commit'), outcome.header.get('build')


def require_one_build(outcomes: Sequence[RunOutcome], pilot: RunOutcome | None = None):
    first, last = pilot or outcomes[0], outcomes[-1]
    if build_of(last) != build_of(first):
        first_name = 'the pilot' if pilot else f'run {first.number}'
        raise ProveFailure(f'run {last.number} judged build {build_of(last)}, {first_name} build '
                           f'{build_of(first)}: a proof compares runs of one build')


def run_pilot(spec: ProveSpec, pilot: Pilot, runner: Runner, compare: Compare
              ) -> tuple[RunOutcome | None, Mapping[str, int], dict | None]:
    directory = spec.out / PILOT_DIR
    manifest_path = pilot.generate(directory)
    if manifest_path is None:
        return None, {}, None
    manifest = json.loads(Path(manifest_path).read_text(encoding='utf-8'))
    files = scenario_files(directory, manifest)
    if not files:
        raise ProveFailure(f'{manifest_path} lists no pilot scenario to run')
    pilot_spec = ProveSpec(directory, spec.worktree, spec.runs, spec.build, spec.timeout_ms, spec.verify)
    outcome = execute_run(pilot_spec, 1, Path(manifest_path), files, runner, compare)
    trials, sized = pilot.size(outcome.verdicts)
    return outcome, trials, {'manifest': str(manifest_path), 'run': outcome.record, 'trials': dict(trials),
                             'labels': sized, 'judged': False}


def write_flip_reports(spec: ProveSpec, runs: Sequence[RunOutcome]) -> list[str]:
    paths = []
    for later in runs[1:]:
        target = spec.out / FLIPS_DIR if len(runs) == MIN_RUNS else spec.out / FLIPS_DIR / RUN_DIR.format(later.number)
        changes = diff_directories(runs[0].directory, later.directory, set())
        paths.append(str(write_impact(changes, set(), runs[0].directory, later.directory, target)))
    return paths


def row_labels(row: dict) -> list[str]:
    return list(row.get('labels') or []) + [label for claim in row.get('claims') or [] for label in claim['labels']]


def conformant_in_every_run(row: dict, runs: Sequence[RunOutcome]) -> bool:
    labels = row_labels(row)
    if not labels:
        return False
    for run in runs:
        statuses = {verdict.label: verdict.status for verdict in run.verdicts}
        if any(statuses.get(label) not in CONFORMANT for label in labels):
            return False
    return True


def write_json(path: Path, document) -> Path:
    Path(path).write_text(json.dumps(document, indent=2) + '\n', encoding='utf-8')
    return Path(path)


def scenario_files(out: Path, manifest: dict) -> list[Path]:
    return sorted((out / entry['file']).resolve() for entry in manifest['scenarios'] if entry['file'])


def prove(spec: ProveSpec, generate: Generate, rows: Rows | None = None, enrich: Enrich | None = None,
          annotate: Annotate | None = None, runner: Runner = run_command, compare: Compare = compare_run,
          pilot: Pilot | None = None) -> int:
    if spec.runs < MIN_RUNS:
        raise ValueError(f'a proof needs at least {MIN_RUNS} runs to detect a flip, not {spec.runs}')
    out = Path(spec.out)
    if out.exists() and (not out.is_dir() or any(out.iterdir())):
        raise ValueError(f'{out} is not empty; prove into a new directory')
    out.mkdir(parents=True, exist_ok=True)
    spec = ProveSpec(out.resolve(), Path(spec.worktree), spec.runs, spec.build, spec.timeout_ms, spec.verify)
    summary = {'schema': SUMMARY_SCHEMA, 'class_id': None, 'manifest': None, 'spell_dbc_sha256': None,
               'scenarios': 0, 'worktree': str(spec.worktree), 'sizing': None, 'runs': [], 'flips': [],
               'not_judged': [], 'flip_reports': [], 'fragment': None, 'missing_results': [], 'failed_run': None,
               'failure': None, 'exit': OK_EXIT}
    outcomes: list[RunOutcome] = []
    try:
        piloted, trials = None, {}
        if pilot is not None:
            piloted, trials, summary['sizing'] = run_pilot(spec, pilot, runner, compare)
        if piloted is not None:
            spec = ProveSpec(spec.out, spec.worktree, spec.runs, False, spec.timeout_ms, spec.verify)
            manifest_path = Path(pilot.sized(spec.out, trials))
        else:
            manifest_path = Path(generate(spec.out))
        manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
        files = scenario_files(spec.out, manifest)
        summary.update({'class_id': manifest['class_id'], 'manifest': str(manifest_path),
                        'spell_dbc_sha256': manifest.get('spell_dbc_sha256'), 'scenarios': len(files)})
        if not files:
            raise ProveFailure(f'{manifest_path} lists no scenario file to run')
        for number in range(1, spec.runs + 1):
            outcomes.append(execute_run(spec, number, manifest_path, files, runner, compare))
            summary['runs'].append(outcomes[-1].record)
            require_one_build(outcomes, piloted)
        summary['flips'] = find_flips(outcomes)
        summary['not_judged'] = find_not_judged(outcomes)
        summary['flip_reports'] = write_flip_reports(spec, outcomes)
        candidates = rows(manifest) if rows else []
        kept = [row for row in candidates if conformant_in_every_run(row, outcomes)]
        excluded = [{'spell': row['spell'], 'clause': row['clause'],
                     **({'claim': row['claim']} if 'claim' in row else {}), 'labels': row_labels(row)}
                    for row in candidates if row not in kept]
        if enrich:
            kept = enrich(kept, outcomes)
        write_json(spec.out / FRAGMENT_FILE, kept)
        summary['fragment'] = {'file': str(spec.out / FRAGMENT_FILE), 'rows': len(kept), 'excluded': excluded}
        if annotate:
            summary.update(annotate(outcomes))
        summary['exit'] = FLIP_EXIT if summary['flips'] else OK_EXIT
    except ProveFailure as failure:
        summary['failure'] = failure.reason
        summary['exit'] = failure.exit_code
        if failure.record is not None:
            summary['failed_run'] = failure.record
            summary['missing_results'] = [{'directory': failure.record['directory'],
                                           'scenarios': failure.record['missing_results']}]
    summary['exit_meaning'] = {OK_EXIT: 'no flip', FLIP_EXIT: 'two judged verdicts differ between runs',
                               DRIFT_EXIT: 'scenario drift', MISSING_EXIT: 'a scenario produced no result',
                               FAILURE_EXIT: 'a run failed'}[summary['exit']]
    write_json(spec.out / SUMMARY_FILE, summary)
    return summary['exit']
