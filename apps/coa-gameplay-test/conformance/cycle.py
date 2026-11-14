from collections import defaultdict
from dataclasses import dataclass, field
import hashlib
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
from typing import Callable, Sequence

from tally import (FINAL, TallyError, TallyInputs, load_decisions, match_line, record_match, tally, tally_lines,
                   tally_record_verdicts, verdict_line, write_status)

STEPS = ('gate', 'digests', 'generate', 'source', 'runs', 'compare', 'audit', 'tally', 'refactor', 'archive',
         'checkpoint')
CONFORMANCE = Path('apps/coa-gameplay-test/conformance')
NOT_RECORDED = 'not recorded'
DEFAULT_RUNNER = ('python3', '-B', 'tools/verify_all.py')
DEFAULT_DISK_CHECKS = ({'name': '/', 'command': ['df', '-P', '/']},)
DEFAULT_GATE_PATHS = ('apps', 'src', 'data/sql/updates')
CHECKPOINT_JSON = 'checkpoint.json'
CHECKPOINT_MD = 'checkpoint.md'
PAIR_FILE = 'pair.json'
SUMMARY_FILE = 'cycle-summary.json'
REFACTOR_FILE = 'refactor-gate.json'
FAILED = 2
ACCEPTED_RUNS = {'PASSED': 0, 'INCOMPLETE': 3}

Runner = Callable[[Sequence[str], Path, Path], int]
ResultsCheck = Callable[[dict, Path], list]


class CycleError(RuntimeError):
    pass


@dataclass(frozen=True)
class Record:
    name: str
    status: Path
    stamps: tuple
    compare: tuple
    manifest: Path


@dataclass(frozen=True)
class Refactor:
    moved_kinds: tuple
    record_commit: str
    class_file: str
    class_file_rev: str | None
    db_words: tuple
    db_kinds: tuple


@dataclass(frozen=True)
class GateChange:
    class_id: int
    added_fields: tuple
    why: str


@dataclass(frozen=True)
class CycleConfig:
    class_id: int
    name: str
    worktree: Path
    head: str | None
    base: str | None
    clauses: Path
    out: Path
    build: str
    record: Record
    decisions: Path | None
    scenarios_dir: Path | None = None
    manifest: Path | None = None
    source_runner: tuple = DEFAULT_RUNNER
    gameplay_runner: tuple = DEFAULT_RUNNER
    gameplay_db_workers: int = 4
    disk_limit_percent: float = 97.0
    disk_checks: tuple = DEFAULT_DISK_CHECKS
    guard_classes: tuple = ()
    gate_archive_paths: tuple = DEFAULT_GATE_PATHS
    gate_accepted: tuple = ()
    stamps: tuple = ()
    results: tuple = ()
    compare: tuple = ()
    coverage: tuple = ()
    refactor: Refactor | None = None
    archive: Path | None = None
    cost: Path | None = None
    previous_status: Path | None = None


@dataclass
class Cycle:
    config: CycleConfig
    runner: Runner
    skip: frozenset
    write_digests: bool = False
    results_check: ResultsCheck | None = None
    stamps: list = field(default_factory=list)
    results: list = field(default_factory=list)
    tally_result: dict | None = None
    refactor_rows: list | None = None
    done: list = field(default_factory=list)


def resolve(base: Path, value) -> Path | None:
    if value is None:
        return None
    path = Path(value).expanduser()
    return Path(os.path.normpath(path)) if path.is_absolute() else (base / path).resolve()


def require(document: dict, name: str, where: str = 'cycle file'):
    if name not in document:
        raise CycleError(f'{where}: missing field "{name}"')
    return document[name]


def pair_of(values, name: str, required: bool = False) -> tuple:
    if (values or required) and len(values or ()) != 2:
        raise CycleError(f'{name}: a merged pair has 2 entries, found {len(values or ())}')
    return tuple(values or ())


def distinct_pair(values, name: str) -> None:
    if len(values) == 2 and values[0] == values[1]:
        raise CycleError(f'{name}: both entries name the same run {values[0]}; a merged pair is two runs')


def gate_change(document: dict) -> GateChange:
    fields = tuple(str(name) for name in document.get('added_fields', ()))
    why = str(document.get('why', '')).strip()
    if not fields or not why:
        raise CycleError(f'gate_accepted: {document} needs "class_id", a non-empty "added_fields" and a "why"')
    return GateChange(int(require(document, 'class_id', 'gate_accepted')), fields, why)


def load_config(path: Path) -> CycleConfig:
    path = Path(path).resolve()
    document = json.loads(path.read_text(encoding='utf-8'))
    base = path.parent
    record = require(document, 'record')
    pair = document.get('pair', {})
    refactor = document.get('refactor')
    return CycleConfig(
        class_id=int(require(document, 'class_id')),
        name=str(require(document, 'name')),
        worktree=resolve(base, require(document, 'worktree')),
        head=document.get('head'),
        base=document.get('base'),
        clauses=resolve(base, require(document, 'clauses')),
        out=resolve(base, require(document, 'out')),
        build=str(require(document, 'build')),
        record=Record(str(require(record, 'name', 'record')), resolve(base, require(record, 'status', 'record')),
                      pair_of(record.get('stamps'), 'record.stamps'),
                      tuple(resolve(base, item) for item in pair_of(require(record, 'compare', 'record'),
                                                                     'record.compare', required=True)),
                      resolve(base, require(record, 'manifest', 'record'))),
        decisions=resolve(base, document.get('decisions')),
        scenarios_dir=resolve(base, document.get('scenarios_dir')),
        manifest=resolve(base, document.get('manifest')),
        source_runner=tuple(document.get('source_runner', DEFAULT_RUNNER)),
        gameplay_runner=tuple(document.get('gameplay_runner', DEFAULT_RUNNER)),
        gameplay_db_workers=int(document.get('gameplay_db_workers', 4)),
        disk_limit_percent=float(document.get('disk_limit_percent', 97)),
        disk_checks=tuple(document.get('disk_checks', DEFAULT_DISK_CHECKS)),
        guard_classes=tuple(int(item) for item in document.get('guard_classes', ())),
        gate_archive_paths=tuple(document.get('gate_archive_paths', DEFAULT_GATE_PATHS)),
        gate_accepted=tuple(gate_change(item) for item in document.get('gate_accepted', ())),
        stamps=pair_of(pair.get('stamps'), 'pair.stamps'),
        results=tuple(resolve(base, item) for item in pair_of(pair.get('results'), 'pair.results')),
        compare=tuple(resolve(base, item) for item in pair_of(pair.get('compare'), 'pair.compare')),
        coverage=tuple(resolve(base, item) for item in pair_of(pair.get('coverage'), 'pair.coverage')),
        refactor=Refactor(tuple(refactor['moved_kinds']), str(require(refactor, 'record_commit', 'refactor')),
                          str(require(refactor, 'class_file', 'refactor')), refactor.get('class_file_rev'),
                          tuple(refactor.get('db_words', ())), tuple(refactor.get('db_kinds', ())))
        if refactor and refactor.get('moved_kinds') else None,
        archive=resolve(base, document.get('archive')),
        cost=resolve(base, document.get('cost')),
        previous_status=resolve(base, document.get('previous_status')))


def validate(config: CycleConfig, skip: frozenset) -> None:
    unknown = set(skip) - set(STEPS)
    if unknown:
        raise CycleError(f'unknown steps {sorted(unknown)}; steps are {", ".join(STEPS)}')
    if config.compare and 'compare' not in skip:
        raise CycleError('pair.compare names existing compare outputs: skip the compare step')
    if config.coverage and 'audit' not in skip:
        raise CycleError('pair.coverage names existing audits: skip the audit step')
    if {'generate', 'runs'} - skip and config.scenarios_dir is None:
        raise CycleError('the generate and runs steps need "scenarios_dir"')
    if {'source', 'gate'} - skip and not config.base:
        raise CycleError('the gate and source steps need "base"')
    if config.archive is not None and 'archive' not in skip and not config.head:
        raise CycleError('the archive step needs "head", the generating commit')
    pair_of(config.record.compare, 'record.compare', required=True)
    accepted = [change.class_id for change in config.gate_accepted]
    if len(accepted) != len(set(accepted)) or set(accepted) - set(config.guard_classes):
        raise CycleError(f'gate_accepted: classes {accepted} must be distinct guard classes '
                         f'{list(config.guard_classes)}')
    for name, values in (('record.stamps', config.record.stamps), ('record.compare', config.record.compare),
                         ('pair.stamps', config.stamps), ('pair.results', config.results),
                         ('pair.compare', config.compare), ('pair.coverage', config.coverage)):
        distinct_pair(values, name)


def run_logged(command: Sequence[str], cwd: Path, log: Path) -> int:
    log.parent.mkdir(parents=True, exist_ok=True)
    with log.open('a', encoding='utf-8') as stream:
        stream.write('$ ' + shlex.join(map(str, command)) + '\n')
        stream.flush()
        return subprocess.run(list(map(str, command)), cwd=str(cwd), stdout=stream, stderr=subprocess.STDOUT).returncode


def log_path(cycle: Cycle, step: str) -> Path:
    return cycle.config.out / 'logs' / f'{STEPS.index(step) + 1:02d}-{step}.log'


def note(cycle: Cycle, step: str, text: str) -> None:
    path = log_path(cycle, step)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('a', encoding='utf-8') as stream:
        stream.write(text.rstrip('\n') + '\n')


def call(cycle: Cycle, step: str, command: Sequence[str], cwd: Path | None = None) -> int:
    code = cycle.runner([str(part) for part in command], cwd or cycle.config.worktree, log_path(cycle, step))
    note(cycle, step, f'exit {code}')
    return code


def must(cycle: Cycle, step: str, command: Sequence[str], cwd: Path | None = None) -> None:
    code = call(cycle, step, command, cwd)
    if code != 0:
        raise CycleError(f'{step}: {shlex.join(map(str, command))} exited {code} ({log_path(cycle, step)})')


def tool(root: Path, script: str = 'conformance.py') -> list:
    return [sys.executable, '-B', str(root / CONFORMANCE / script)]


def runner_command(template: Sequence[str], worktree: Path) -> list:
    return [str(part).replace('{worktree}', str(worktree)) for part in template]


def manifest_path(config: CycleConfig) -> Path:
    if config.manifest:
        return config.manifest
    if config.scenarios_dir is None:
        raise CycleError('no manifest: set "manifest" or "scenarios_dir"')
    return config.scenarios_dir / 'manifest.json'


def without_fields(node, fields: tuple):
    if isinstance(node, dict):
        return {key: without_fields(value, fields) for key, value in node.items() if key not in fields}
    if isinstance(node, list):
        return [without_fields(value, fields) for value in node]
    return node


def files_under(root: Path) -> set:
    return {path.relative_to(root).as_posix() for path in Path(root).rglob('*') if path.is_file()}


def read_json(path: Path):
    try:
        return json.loads(Path(path).read_text(encoding='utf-8'))
    except ValueError:
        return None


def manifest_problems(head: dict, base: dict, fields: tuple, changed: set) -> list:
    def plain(manifest):
        return {**manifest, 'scenarios': [{key: value for key, value in scenario.items() if key != 'sha256'}
                                          for scenario in manifest.get('scenarios', [])]}
    if plain(without_fields(head, fields)) != plain(base):
        return ['manifest.json: differs beyond the accepted fields and the scenario sha256']
    return [f"manifest.json: sha256 of {now.get('key')} changed but its file {now.get('file')} did not"
            for now, before in zip(head['scenarios'], base['scenarios'])
            if now.get('sha256') != before.get('sha256') and now.get('file') not in changed]


def accepted_diff(head: Path, base: Path, fields: tuple) -> tuple:
    head_files, base_files = files_under(head), files_under(base)
    problems = [f'{name}: only in {"head" if name in head_files else "base"}'
                for name in sorted(head_files ^ base_files)]
    changed = set()
    for name in sorted(head_files & base_files - {'manifest.json'}):
        if (head / name).read_bytes() == (base / name).read_bytes():
            continue
        now, before = read_json(head / name), read_json(base / name)
        if now is None or before is None or without_fields(now, fields) != before:
            problems.append(f'{name}: differs beyond the accepted added fields {list(fields)}')
        else:
            changed.add(name)
    if 'manifest.json' in head_files & base_files:
        now, before = read_json(head / 'manifest.json'), read_json(base / 'manifest.json')
        if now is None or before is None:
            problems.append('manifest.json: not JSON')
        elif now != before:
            problems += manifest_problems(now, before, fields, changed)
    return problems, changed


def gate_generation(cycle: Cycle, head: Path, base: Path, change: GateChange | None, label: str) -> int:
    if call(cycle, 'gate', ['diff', '-r', '-q', head, base]) == 0:
        return 0
    if change is None:
        raise CycleError(f'gate: {label} differs between head and base; declare an intended change in '
                         f'"gate_accepted" ({log_path(cycle, "gate")})')
    problems, changed = accepted_diff(head, base, change.added_fields)
    if problems:
        raise CycleError(f'gate: {label} differs beyond the accepted change {list(change.added_fields)}: '
                         f'{"; ".join(problems[:20])}{" ..." if len(problems) > 20 else ""}')
    note(cycle, 'gate', f'{label}: {len(changed)} files differ only by the accepted added fields '
                        f'{list(change.added_fields)} ({change.why})')
    return len(changed)


def step_gate(cycle: Cycle) -> None:
    from snapshots import GENERATIONS
    config = cycle.config
    if not config.guard_classes:
        raise CycleError('gate: "guard_classes" is empty; list the finished classes to guard or skip the gate')
    accepted = {change.class_id: change for change in config.gate_accepted}
    gate = config.out / 'gate'
    tree = gate / 'base-tree'
    if tree.exists():
        shutil.rmtree(tree)
    tree.mkdir(parents=True)
    archive = (f'git -C {shlex.quote(str(config.worktree))} archive --format=tar {shlex.quote(config.base)} '
               f'{" ".join(map(shlex.quote, config.gate_archive_paths))} | tar -x -C {shlex.quote(str(tree))}')
    must(cycle, 'gate', ['sh', '-c', archive])
    try:
        for class_id in config.guard_classes:
            if class_id not in GENERATIONS:
                raise CycleError(f'gate: class {class_id} is not a finished class of snapshots.py')
            changed = 0
            for generation, arguments in GENERATIONS[class_id].items():
                head, base = gate / f'{class_id}-{generation}' / 'head', gate / f'{class_id}-{generation}' / 'base'
                for root, out in ((config.worktree, head), (tree, base)):
                    if out.exists():
                        shutil.rmtree(out)
                    must(cycle, 'gate', [*tool(root), 'generate', '--class', class_id, '--out', out, *arguments],
                         root / CONFORMANCE)
                changed += gate_generation(cycle, head, base, accepted.get(class_id), f'class {class_id} {generation}')
                shutil.rmtree(head.parent, ignore_errors=True)
            if class_id in accepted and not changed:
                raise CycleError(f'gate: class {class_id} declares the accepted change '
                                 f'{list(accepted[class_id].added_fields)}, but no generated file changed')
            must(cycle, 'gate', [*tool(config.worktree, 'snapshots.py'), 'check', '--class', class_id],
                 config.worktree / CONFORMANCE)
    finally:
        shutil.rmtree(tree, ignore_errors=True)


def step_digests(cycle: Cycle) -> None:
    config = cycle.config
    command = 'write' if cycle.write_digests else 'check'
    must(cycle, 'digests', [*tool(config.worktree, 'snapshots.py'), command, '--class', config.class_id],
         config.worktree / CONFORMANCE)


def step_generate(cycle: Cycle) -> None:
    out = cycle.config.scenarios_dir
    if out.exists() and any(out.iterdir()):
        raise CycleError(f'generate: {out} is not empty; generate into an empty directory')
    must(cycle, 'generate', [*tool(cycle.config.worktree), 'generate', '--class', cycle.config.class_id, '--out', out],
         cycle.config.worktree / CONFORMANCE)


def step_source(cycle: Cycle) -> None:
    config = cycle.config
    must(cycle, 'source', [*runner_command(config.source_runner, config.worktree), '--stages', 'source', '--base',
                           config.base])


def disk_percent(output: str) -> float:
    lines = [line for line in output.strip().splitlines() if line.strip()]
    for part in lines[-1].split() if lines else []:
        if part.endswith('%') and part[:-1].isdigit():
            return float(part[:-1])
    raise CycleError(f'no use percentage in the disk check output: {output.strip()!r}')


def disk_check(cycle: Cycle, number: int) -> None:
    config = cycle.config
    for position, check in enumerate(config.disk_checks, 1):
        log = config.out / 'logs' / f'disk-run{number}-{position}.txt'
        log.unlink(missing_ok=True)
        code = cycle.runner([str(part) for part in check['command']], config.worktree, log)
        output = log.read_text(encoding='utf-8', errors='replace') if log.exists() else ''
        note(cycle, 'runs', f"disk before run {number}, {check['name']}: {output.strip().splitlines()[-1:]}")
        if code != 0:
            raise CycleError(f"runs: disk check {check['name']} exited {code}; no run")
        percent = disk_percent(output)
        if percent > config.disk_limit_percent:
            raise CycleError(f"runs: {check['name']} at {percent:g}% is above the limit "
                             f"{config.disk_limit_percent:g}%; no run")


def verify_report(log: Path) -> tuple:
    from prove import VERIFY_LINE
    matches = VERIFY_LINE.findall(log.read_text(encoding='utf-8', errors='replace')) if log.exists() else []
    if not matches:
        raise CycleError(f'runs: {log} holds no "VERIFY ALL: <status> <report.json>" line')
    status, report = matches[-1]
    return status, Path(report.strip())


def missing_results(manifest: dict, results: Path) -> list:
    from compare import ScenarioDrift, load_runs
    try:
        return load_runs(manifest, Path(results))[1]
    except ScenarioDrift as drift:
        raise CycleError(f'scenario drift in {results}, no verdict:\n{drift}') from None


def require_results(cycle: Cycle, step: str, manifest: dict, results: Path) -> None:
    missing = sorted((cycle.results_check or missing_results)(manifest, results))
    if missing:
        raise CycleError(f'{step}: {len(missing)} scenarios of the manifest have no result in {results}: '
                         f'{", ".join(missing[:20])}{" ..." if len(missing) > 20 else ""}')


def require_run(number: int, code: int, status: str, report: Path, log: Path) -> None:
    if ACCEPTED_RUNS.get(status) != code:
        raise CycleError(f'run {number}: VERIFY ALL: {status} with exit {code}; a counted run ends PASSED (exit 0) or '
                         f'INCOMPLETE (exit 3) ({log})')
    if not report.is_file():
        raise CycleError(f'run {number}: {report} does not exist ({log})')
    gameplay = json.loads(report.read_text(encoding='utf-8')).get('stages', {}).get('gameplay', {})
    if gameplay.get('status') != 'passed' and 'returncode' not in gameplay.get('summary', {}):
        raise CycleError(f"run {number}: the gameplay stage is {gameplay.get('status')} without a gameplay run "
                         f"({gameplay.get('summary', {}).get('reason')}) ({log})")


def step_runs(cycle: Cycle) -> None:
    config = cycle.config
    manifest = json.loads(manifest_path(config).read_text(encoding='utf-8'))
    files = sorted(str((config.scenarios_dir / entry['file']).resolve()) for entry in manifest['scenarios']
                   if entry['file'])
    if not files:
        raise CycleError(f'runs: {manifest_path(config)} lists no scenario file')
    runs = []
    for number in (1, 2):
        disk_check(cycle, number)
        log = config.out / 'logs' / f'run{number}.log'
        log.unlink(missing_ok=True)
        command = [*runner_command(config.gameplay_runner, config.worktree), '--stages', 'gameplay',
                   '--gameplay-db-workers', str(config.gameplay_db_workers), '--scenario', *files]
        code = cycle.runner(command, config.worktree, log)
        status, report = verify_report(log)
        note(cycle, 'runs', f'run {number}: exit {code}, VERIFY ALL: {status} {report}')
        require_run(number, code, status, report, log)
        require_results(cycle, 'runs', manifest, report.parent)
        runs.append({'number': number, 'exit': code, 'verify': status, 'report': str(report),
                     'stamp': report.parent.name, 'results': str(report.parent)})
    stamps = [run['stamp'] for run in runs]
    results = [Path(os.path.normpath(run['results'])) for run in runs]
    distinct_pair(stamps, 'runs: produced stamps')
    distinct_pair(results, 'runs: produced results')
    cycle.stamps, cycle.results = stamps, results
    (config.out / PAIR_FILE).write_text(json.dumps({'runs': runs, 'scenarios': len(files)}, indent=1) + '\n',
                                        encoding='utf-8')


def compare_dirs(cycle: Cycle) -> list:
    config = cycle.config
    return list(config.compare) or [config.out / f'{config.name}-cmp-{stamp}' for stamp in cycle.stamps]


def coverage_files(cycle: Cycle) -> list:
    config = cycle.config
    return list(config.coverage) or [config.out / f'coverage-{config.name}-{stamp}.json' for stamp in cycle.stamps]


def step_compare(cycle: Cycle) -> None:
    config = cycle.config
    if len(cycle.results) != 2:
        raise CycleError('compare: no results of the pair; run the pair or set pair.results')
    if 'runs' in cycle.skip:
        manifest = json.loads(manifest_path(config).read_text(encoding='utf-8'))
        for results in cycle.results:
            require_results(cycle, 'compare', manifest, results)
    for results, out in zip(cycle.results, compare_dirs(cycle)):
        must(cycle, 'compare', [*tool(config.worktree), 'compare', '--manifest', manifest_path(config), '--results',
                                results, '--out', out, '--build', config.build], config.worktree / CONFORMANCE)


def step_audit(cycle: Cycle) -> None:
    config = cycle.config
    for directory, out in zip(compare_dirs(cycle), coverage_files(cycle)):
        must(cycle, 'audit', [*tool(config.worktree), 'audit', '--class', config.class_id, '--clauses',
                              config.clauses, '--results', directory, '--manifest', manifest_path(config), '--out',
                              out], config.worktree / CONFORMANCE)


def status_paths(config: CycleConfig) -> tuple:
    return config.out / f'{config.name}-status.json', config.out / f'{config.name}-status.md'


def step_tally(cycle: Cycle) -> None:
    config = cycle.config
    directories, coverage = compare_dirs(cycle), coverage_files(cycle)
    if len(directories) != 2 or len(coverage) != 2:
        raise CycleError('tally: the pair needs two compare outputs and two audits')
    try:
        inputs = TallyInputs(config.clauses, config.record.status, config.record.compare, config.record.manifest,
                             tuple(directories), tuple(coverage), manifest_path(config),
                             load_decisions(config.decisions))
        result = tally(inputs)
    except (TallyError, KeyError, IndexError, OSError) as error:
        raise CycleError(f'tally: {error}') from None
    json_path, markdown_path = status_paths(config)
    write_status(result, json_path, markdown_path, f'{config.name} status (class {config.class_id})')
    for line in tally_lines(result):
        note(cycle, 'tally', line)
    cycle.tally_result = result


def moved_entries(node, kinds: tuple, found: list) -> list:
    if isinstance(node, dict):
        if node.get('kind') in kinds and 'spell' in node:
            found.append(node)
        for value in node.values():
            moved_entries(value, kinds, found)
    elif isinstance(node, list):
        for value in node:
            moved_entries(value, kinds, found)
    return found


def class_file_at(worktree: Path, rev: str, path: str) -> dict:
    text = subprocess.run(['git', '-C', str(worktree), 'show', f'{rev}:{path}'], capture_output=True, text=True,
                          check=True).stdout
    return json.loads(text)


def label_verdicts(directory: Path) -> dict:
    out = defaultdict(list)
    for verdict in json.loads((Path(directory) / 'verdicts.json').read_text(encoding='utf-8'))['verdicts']:
        out[(verdict['label'], verdict['check'])].append(verdict)
    return out


def by_scenario(runs: list, key: tuple) -> dict:
    scenarios = {verdict['scenario'] for run in runs for verdict in run.get(key, [])}
    found = {}
    for scenario in scenarios:
        found[scenario] = sorted(
            '+'.join(sorted({verdict['status'] for verdict in run.get(key, []) if verdict['scenario'] == scenario}))
            or 'missing' for run in runs)
    return found


def changed_scenarios(old: list, new: list, key: tuple) -> list:
    before, after = by_scenario(old, key), by_scenario(new, key)
    return sorted(scenario for scenario in set(before) | set(after) if before.get(scenario) != after.get(scenario))


def refactor_class(info: dict, refactor: Refactor, record: Record) -> str:
    if info['entry_changed_since_record']:
        return f'explained: entry changed since {record.name} ({refactor.record_commit})'
    if any(word in (info['name'] or '').lower() for word in refactor.db_words) or info['kind'] in refactor.db_kinds:
        return 'seed suspect (reads DB data)'
    return 'refactor regression'


def refactor_rows(config: CycleConfig, directories: list) -> list:
    from kinds import kind_labels
    refactor = config.refactor
    labeller = kind_labels()
    if refactor.class_file_rev:
        head_file = class_file_at(config.worktree, refactor.class_file_rev, refactor.class_file)
    else:
        head_file = json.loads((config.worktree / refactor.class_file).read_text(encoding='utf-8'))
    head = moved_entries(head_file, refactor.moved_kinds, [])
    record_keyed = {json.dumps(entry, sort_keys=True) for entry in
                    moved_entries(class_file_at(config.worktree, refactor.record_commit, refactor.class_file),
                                  refactor.moved_kinds, [])}
    by_model = defaultdict(list)
    for scenario in json.loads(manifest_path(config).read_text(encoding='utf-8'))['scenarios']:
        for expectation in scenario['expectations']:
            model = expectation.get('model')
            if isinstance(model, dict) and model.get('kind'):
                by_model[(model['kind'], str(expectation.get('spell_id')))].append(expectation['label'])
    labels = {}
    for entry in head:
        changed = json.dumps(entry, sort_keys=True) not in record_keyed
        found = labeller[entry['kind']](entry) if entry['kind'] in labeller else by_model[(entry['kind'],
                                                                                            str(entry['spell']))]
        for label in found:
            labels[label] = {'kind': entry['kind'], 'entry_changed_since_record': changed, 'name': entry.get('name')}
    old = [label_verdicts(directory) for directory in config.record.compare]
    new = [label_verdicts(directory) for directory in directories]
    rows = []
    for label, info in sorted(labels.items()):
        checks = sorted({key[1] for run in old + new for key in run if key[0] == label})
        for check in checks or ['(none)']:
            before = [[verdict['status'] for verdict in run.get((label, check), [])] for run in old]
            after = [[verdict['status'] for verdict in run.get((label, check), [])] for run in new]
            row = {'label': label, 'check': check, **info, 'record': before, 'pair': after,
                   'record_measured': [[verdict.get('measured') for verdict in run.get((label, check), [])]
                                       for run in old],
                   'pair_measured': [[verdict.get('measured') for verdict in run.get((label, check), [])]
                                     for run in new]}
            moved = changed_scenarios(old, new, (label, check))
            row['changed'] = bool(moved)
            if moved:
                row['class'] = refactor_class(info, refactor, config.record)
                row['changed_scenarios'] = moved
            rows.append(row)
    return rows


def step_refactor(cycle: Cycle) -> None:
    config = cycle.config
    if config.refactor is None:
        note(cycle, 'refactor', 'no moved_kinds: no refactor gate')
        return
    try:
        rows = refactor_rows(config, compare_dirs(cycle))
    except (subprocess.CalledProcessError, OSError, KeyError) as error:
        raise CycleError(f'refactor: {error}') from None
    (config.out / REFACTOR_FILE).write_text(json.dumps(rows, indent=1) + '\n', encoding='utf-8')
    changed = [row for row in rows if row['changed']]
    labels = {row['label'] for row in rows}
    note(cycle, 'refactor', f'labels {len(labels)}, label/check rows {len(rows)}, changed {len(changed)}')
    for row in changed:
        note(cycle, 'refactor', f"{row['label']} {row['check']} {row['kind']} {row['record']} {row['pair']} "
                                f"{row['class']}")
    cycle.refactor_rows = rows


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with Path(path).open('rb') as stream:
        for block in iter(lambda: stream.read(1 << 20), b''):
            digest.update(block)
    return digest.hexdigest()


def file_at(worktree: Path, rev: str, path: str) -> bytes | None:
    found = subprocess.run(['git', '-C', str(worktree), 'show', f'{rev}:{path}'], capture_output=True)
    return found.stdout if found.returncode == 0 else None


def generating_commit(config: CycleConfig) -> str:
    found = subprocess.run(['git', '-C', str(config.worktree), 'rev-parse', '--verify', '--quiet',
                            f'{config.head}^{{commit}}'], capture_output=True, text=True)
    if found.returncode != 0:
        raise CycleError(f'archive: the generating commit {config.head} cannot be read in {config.worktree}')
    return config.head


def archive_ledger(config: CycleConfig, rev: str) -> list:
    from profile import CLAUSE_LEDGER_SUFFIX, CONSUMPTION_SUFFIX
    ledger = config.archive / 'ledger'
    ledger.mkdir()
    used = config.clauses.read_bytes()
    (ledger / config.clauses.name).write_bytes(used)
    stem = config.clauses.stem.removesuffix(CLAUSE_LEDGER_SUFFIX)
    classes = (CONFORMANCE / 'classes').as_posix()
    committed = file_at(config.worktree, rev, f'{classes}/{config.clauses.name}')
    if committed is None:
        raise CycleError(f'archive: {classes}/{config.clauses.name} does not exist at {rev}')
    state = 'equal to' if committed == used else 'DIFFERENT from'
    lines = [f'Ledger used: ledger/{config.clauses.name}, {state} {rev}:{classes}/{config.clauses.name}.']
    if committed != used:
        (ledger / f'committed-{config.clauses.name}').write_bytes(committed)
        lines.append(f'Committed ledger ledger/committed-{config.clauses.name} from '
                     f'{rev}:{classes}/{config.clauses.name}.')
    for name, required in ((f'{stem}.json', True), (f'{stem}{CONSUMPTION_SUFFIX}.json', False)):
        content = file_at(config.worktree, rev, f'{classes}/{name}')
        if content is None:
            if required:
                raise CycleError(f'archive: the class file {classes}/{name} does not exist at {rev}')
            lines.append(f'No {name} at {rev}.')
            continue
        (ledger / name).write_bytes(content)
        lines.append(f'Class file ledger/{name} from {rev}:{classes}/{name}.')
    return lines + [f'{sha256(path)}  ledger/{path.name}' for path in sorted(ledger.iterdir())]


def step_archive(cycle: Cycle) -> None:
    config = cycle.config
    if config.archive is None:
        note(cycle, 'archive', 'no "archive" directory: nothing archived')
        return
    if config.archive.exists():
        raise CycleError(f'archive: {config.archive} exists; an archive is written once')
    if len(cycle.stamps) != 2:
        raise CycleError('archive: the pair has no two stamps; run the pair or set pair.stamps')
    rev = generating_commit(config)
    config.archive.mkdir(parents=True)
    for stamp, directory, coverage in zip(cycle.stamps, compare_dirs(cycle), coverage_files(cycle)):
        shutil.copytree(directory, config.archive / f'{config.name}-cmp-{stamp}')
        shutil.copy2(coverage, config.archive / f'coverage-{config.name}-{stamp}.json')
    for stamp, results in zip(cycle.stamps, cycle.results):
        report = Path(results) / 'report.json'
        if report.exists():
            (config.archive / f'verify-all-{stamp}').mkdir()
            shutil.copy2(report, config.archive / f'verify-all-{stamp}' / 'report.json')
        else:
            note(cycle, 'archive', f'{report} not found: not archived')
    manifest = config.archive / 'manifest.json'
    shutil.copy2(manifest_path(config), manifest)
    json_path, markdown_path = status_paths(config)
    for path in (json_path, markdown_path):
        if path.exists():
            shutil.copy2(path, config.archive / path.name)
    ledger = archive_ledger(config, rev)
    build = [f'Class {config.class_id} re-auditable verdict set, {config.name} merged pair.',
             f'Runs: {" and ".join(cycle.stamps)}.',
             f'compare --build {config.build}.',
             f'Generation commit {rev} (worktree {config.worktree.name}).',
             f'Re-audit: conformance.py audit --class {config.class_id} --clauses ledger/{config.clauses.name} '
             f'--results <{config.name}-cmp-STAMP> --manifest manifest.json --out <file>',
             *ledger,
             f'{sha256(manifest)}  manifest.json']
    (config.archive / 'BUILD.txt').write_text('\n'.join(build) + '\n', encoding='utf-8')
    note(cycle, 'archive', f'archived into {config.archive}')


def final_keys(rows: list) -> set:
    return {row['key'] for row in rows if row['status'] in FINAL}


def cost_of(config: CycleConfig):
    if config.cost is None:
        return NOT_RECORDED
    return json.loads(config.cost.read_text(encoding='utf-8'))


def head_sha(worktree: Path) -> str:
    found = subprocess.run(['git', '-C', str(worktree), 'rev-parse', 'HEAD'], capture_output=True, text=True)
    return found.stdout.strip() if found.returncode == 0 else NOT_RECORDED


def tally_rows(cycle: Cycle) -> list:
    if cycle.tally_result is not None:
        return cycle.tally_result['rows']
    json_path = status_paths(cycle.config)[0]
    if not json_path.exists():
        raise CycleError(f'checkpoint: no tally ({json_path}); run the tally step')
    return json.loads(json_path.read_text(encoding='utf-8'))


def record_scenarios(cycle: Cycle) -> dict:
    if cycle.tally_result is not None:
        return cycle.tally_result['record_scenarios']
    config = cycle.config
    return record_match(json.loads(config.record.manifest.read_text(encoding='utf-8')),
                        json.loads(manifest_path(config).read_text(encoding='utf-8')))


def record_verdicts(cycle: Cycle) -> dict:
    if cycle.tally_result is not None:
        return cycle.tally_result['record_verdicts']
    config = cycle.config
    inputs = TallyInputs(config.clauses, config.record.status, config.record.compare, config.record.manifest,
                         tuple(compare_dirs(cycle)), (), manifest_path(config), load_decisions(None))
    return tally_record_verdicts(inputs)


def checkpoint_document(cycle: Cycle) -> dict:
    config = cycle.config
    rows = tally_rows(cycle)
    now = final_keys(rows)
    before = final_keys(json.loads((config.previous_status or config.record.status).read_text(encoding='utf-8')))
    keys = [row['key'] for row in rows]
    lost = [key for key in keys if key in before - now] + sorted(before - now - set(keys))
    statuses = defaultdict(int)
    for row in rows:
        statuses[row['status']] += 1
    refactor = NOT_RECORDED
    if cycle.refactor_rows is not None:
        refactor = {'rows': len(cycle.refactor_rows),
                    'changed': sum(1 for row in cycle.refactor_rows if row['changed'])}
    return {
        'class_id': config.class_id,
        'name': config.name,
        'count': len(now),
        'total': len(rows),
        'previous_count': len(before),
        'previous': config.previous_status.name if config.previous_status else f'record {config.record.name}',
        'delta': len(now) - len(before),
        'statuses': dict(sorted(statuses.items())),
        'flips': {'in_pair': [row['key'] for row in rows if row['flips_in_pair']],
                  'against_record': [row['key'] for row in rows if row['flips_vs_record']]},
        'record_scenarios': record_scenarios(cycle),
        'record_verdicts': record_verdicts(cycle),
        'lost': lost,
        'gained': [row['key'] for row in rows if row['key'] in now - before],
        'stamps': list(cycle.stamps),
        'record': {'name': config.record.name, 'stamps': list(config.record.stamps)},
        'build': config.build,
        'head': config.head or head_sha(config.worktree),
        'refactor_gate': refactor,
        'steps': [*cycle.done, 'checkpoint'],
        'cost': cost_of(config),
    }


def match_markdown(match: dict) -> str:
    if not match['unmatched']:
        return f"Record scenarios: {match['matched']} matched by entry and label, 0 unmatched"
    return (f"**WARNING: {match['unmatched']} record scenarios UNMATCHED** (not compared with the record), "
            f"{match['matched']} matched by entry and label: {', '.join(match['unmatched_scenarios'][:10])}"
            f"{' ...' if match['unmatched'] > 10 else ''}")


def verdict_markdown(verdicts: dict) -> str:
    counts = f"{verdicts['no_scenario_file']} with no scenario file, {verdicts['other']} other"
    if not verdicts['other']:
        return f'Record verdicts not compared with the record: {counts}'
    shown = ', '.join(' | '.join(key) for key in verdicts['other_verdicts'][:10])
    return (f"**WARNING: record verdicts not compared with the record: {counts}**: {shown}"
            f"{' ...' if verdicts['other'] > 10 else ''}")


def checkpoint_markdown(document: dict) -> str:
    total = document['total']
    share = f"{100.0 * document['count'] / total:.1f}%" if total else 'n/a'
    statuses = ', '.join(f'{status}: {count}' for status, count in document['statuses'].items())
    cost = document['cost'] if isinstance(document['cost'], str) else json.dumps(document['cost'], sort_keys=True)
    refactor = document['refactor_gate']
    lines = [f"# Checkpoint {document['name']} (class {document['class_id']})", '',
             f"- Count: **{document['count']} / {total} = {share}**, delta **{document['delta']:+d}** vs "
             f"{document['previous_count']} ({document['previous']})",
             f'- Statuses: {statuses}',
             f"- Flips: {len(document['flips']['in_pair'])} in the pair "
             f"({', '.join(document['flips']['in_pair']) or 'none'}), "
             f"{len(document['flips']['against_record'])} against the record "
             f"({', '.join(document['flips']['against_record']) or 'none'})",
             f"- {match_markdown(document['record_scenarios'])}",
             f"- {verdict_markdown(document['record_verdicts'])}",
             f"- Lost: {', '.join(document['lost']) or 'none'}; gained: {', '.join(document['gained']) or 'none'}",
             f"- Stamps: {' / '.join(document['stamps']) or NOT_RECORDED}; record {document['record']['name']} "
             f"({' / '.join(document['record']['stamps']) or NOT_RECORDED})",
             f"- Build: {document['build']}; head {document['head']}",
             f"- Refactor gate: {refactor if isinstance(refactor, str) else json.dumps(refactor, sort_keys=True)}",
             f"- Steps: {', '.join(document['steps'])}",
             f'- Cost: {cost}']
    return '\n'.join(lines) + '\n'


def step_checkpoint(cycle: Cycle) -> None:
    out = cycle.config.out
    document = checkpoint_document(cycle)
    (out / CHECKPOINT_JSON).write_text(json.dumps(document, indent=1) + '\n', encoding='utf-8')
    (out / CHECKPOINT_MD).write_text(checkpoint_markdown(document), encoding='utf-8')
    note(cycle, 'checkpoint', f"{document['count']} / {document['total']}, delta {document['delta']:+d}")
    note(cycle, 'checkpoint', match_line(document['record_scenarios']))
    note(cycle, 'checkpoint', verdict_line(document['record_verdicts']))


HANDLERS = {'gate': step_gate, 'digests': step_digests, 'generate': step_generate, 'source': step_source,
            'runs': step_runs, 'compare': step_compare, 'audit': step_audit, 'tally': step_tally,
            'refactor': step_refactor, 'archive': step_archive, 'checkpoint': step_checkpoint}


def known_pair(cycle: Cycle) -> None:
    config = cycle.config
    pair_file = config.out / PAIR_FILE
    if config.stamps:
        cycle.stamps = list(config.stamps)
        cycle.results = list(config.results)
    elif pair_file.exists():
        runs = json.loads(pair_file.read_text(encoding='utf-8'))['runs']
        cycle.stamps = [run['stamp'] for run in runs]
        cycle.results = [Path(run['results']) for run in runs]
        pair_of(cycle.stamps, str(pair_file))
        distinct_pair(cycle.stamps, f'{pair_file} stamps')
        distinct_pair(cycle.results, f'{pair_file} results')


def run_cycle(config: CycleConfig, skip: Sequence[str] = (), runner: Runner = run_logged,
              write_digests: bool = False, results_check: ResultsCheck | None = None) -> Cycle:
    skipped = frozenset(skip)
    validate(config, skipped)
    config.out.mkdir(parents=True, exist_ok=True)
    cycle = Cycle(config, runner, skipped, write_digests, results_check)
    known_pair(cycle)
    summary = {'steps': []}
    try:
        for step in STEPS:
            if step in skipped:
                note(cycle, step, 'skipped')
                summary['steps'].append({'step': step, 'state': 'skipped'})
                continue
            note(cycle, step, f'start {step}')
            HANDLERS[step](cycle)
            cycle.done.append(step)
            summary['steps'].append({'step': step, 'state': 'done'})
    except Exception as error:
        reason = str(error) if isinstance(error, CycleError) else f'{type(error).__name__}: {error}'
        summary['steps'].append({'step': step, 'state': 'failed', 'reason': reason})
        note(cycle, step, f'failed: {reason}')
        raise
    finally:
        (config.out / SUMMARY_FILE).write_text(json.dumps(summary, indent=1) + '\n', encoding='utf-8')
    return cycle


def add_cycle_arguments(parser) -> None:
    parser.add_argument('--config', type=Path, required=True, help='the cycle file (cycle.json)')
    parser.add_argument('--skip', action='append', default=[], choices=STEPS,
                        help='a step not to run; repeatable')
    parser.add_argument('--write-digests', dest='write_digests', action='store_true',
                        help='the digests step rewrites snapshots/<class>.json instead of checking it')


def cycle_command(args) -> int:
    try:
        cycle = run_cycle(load_config(args.config), args.skip, write_digests=args.write_digests)
    except CycleError as error:
        print(f'Cycle stopped: {error}', file=sys.stderr)
        return FAILED
    config = cycle.config
    print(f"{config.out / SUMMARY_FILE}: done {', '.join(cycle.done) or 'nothing'}")
    if cycle.tally_result:
        lines = tally_lines(cycle.tally_result)
        for line in [lines[1], *(line for line in lines if line.startswith('LOST '))]:
            print(line)
    if {'tally', 'checkpoint'} & set(cycle.done):
        print(match_line(record_scenarios(cycle)))
        print(verdict_line(record_verdicts(cycle)))
    if (config.out / CHECKPOINT_MD).exists() and 'checkpoint' in cycle.done:
        print(config.out / CHECKPOINT_MD)
    return 0
