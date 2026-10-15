#!/usr/bin/env python3
CLI_DESCRIPTION = """Run gameplay scenarios through queue-mode worldservers, then verify them together.

Real clock (default): each worker owns one worldserver at a time and its own world-cache slot, and runs one case
at a time. Failed or unrun catalog cases are rerun once in single mode; a case that failed in a batch and passes
only there is reported as batch-sensitive, and an unrun case that passes there is reported as isolated-only.

Simulated clock (--clock simulated): one worldserver runs up to --lanes cases at once in phase-isolated lanes on a
game clock that skips scripted waits. Cases that enter the normal world phase or are listed as exclusive in
clock_policy.json run while no other case runs.
An accelerated failure remains failed by default. --real-pace-rerun explicitly enables slower same-server
diagnostics after the accelerated queue; a case that passes only there is reported as acceleration-sensitive.
That retry alone does not establish a clock dependency. --isolated-rerun adds single-mode reruns of failed cases.
A case that has not returned its result is treated as hung 3 * timeout_ms / 1000 + 60
seconds after a lane could first have admitted it. This worldserver writes its character database through
--character-db-workers asynchronous connections at READ-COMMITTED isolation; real-clock and single-mode
worldservers keep one worker at the MySQL server's default isolation.

A scenario with an "hour" runs at that realm-local hour. The simulated clock starts its realm-local time at
10:00 and runs such a case exclusively, after the other cases, once it has jumped ahead to that hour; the next
case without an hour, such as a real-pace rerun, jumps back to 10:00 first. The real clock runs it in single mode
instead, on a worldserver whose TZ is a fixed offset that puts local time at the start of that hour; single-mode
reruns do the same.

Scenario files that match no catalog definition are exploratory: they receive native execution only and never
count as combined verification.

A worldserver that stops itself, or that crashes or hangs after it returned an earlier case result or while several
cases were running, fails the batch: the runner cannot rule out a failed teardown or another running case as the
cause. Each case it lost is queued once more, including a case whose result says the worldserver shut down before
the case finished; in lanes, a case that was running then runs alone, and a case that had not started yet keeps its
retry. When the worldserver stops itself, the running cases are those its shutdown results name; after a crash or
hang, they are those a lane could have admitted while the worldserver was last seen running. A slot that loses three
worldservers in a row without a completed case, a batch in which no queue-mode worldserver became ready, and a
worldserver binary that changes during the batch also fail it.

Exit status: 0 when combined verification passed, 3 when only exploratory scenarios ran and passed, 1 otherwise,
130 when interrupted before the report was written.
"""

import argparse
from collections import deque
from contextlib import contextmanager
from dataclasses import dataclass, field, replace
import json
import math
import os
from pathlib import Path
import re
import secrets
import shutil
import signal
import subprocess
import sys
import tempfile
import threading
import time
from types import SimpleNamespace

import catalog
import run
import verification
from world_cache import write_json

CASE_GRACE_SECONDS = 60
STOP_SECONDS = 300
STEP_SECONDS = 0.05
POLL_SECONDS = 0.05
JOIN_SECONDS = 0.2
SERVER_FAILURE_LIMIT = 3
MESSAGE_LIMIT = 2000
CACHE_ROOT = run.ROOT / '.cache' / 'coa-gameplay-tests' / 'world-cache' / 'slots'
SCOPE = '{} plus registered checks; not client rendering or current deployment'
EXPLORATORY_SCOPE = 'exploratory native execution only; not combined verification'
FAILURES = (ValueError, OSError, KeyError, TypeError, subprocess.SubprocessError)
CLEANUP_FIELDS = ('cleanup_failed', 'cache_cleanup_error', 'cleanup_error')
REFRESHED_MODES = ('refreshed', 'created')
STOP_SIGNALS = tuple(getattr(signal, name) for name in ('SIGINT', 'SIGTERM', 'SIGBREAK') if hasattr(signal, name))
EXTERNAL_STOP_SIGNALS = tuple(number for number in STOP_SIGNALS if number != signal.SIGINT)
EXIT_CODES = {'passed': 0, 'failed': 1, 'exploratory': 3}
VERDICTS = {'passed': 'PASSED', 'failed': 'FAILED', 'exploratory': 'EXPLORATORY'}
REAL_CLOCK = 'real'
SIMULATED_CLOCK = 'simulated'
MAX_LANES = 15
MAX_STEP_MS = 2000
DEFAULT_CHARACTER_DB_WORKERS = 16
MAX_DATABASE_WORKERS = 32
SIMULATED_CHARACTER_ISOLATION = 'READ-COMMITTED'
READY_DATABASE_SETTINGS = {'character_db_workers': 'CharacterDatabase.WorkerThreads',
                           'character_db_isolation': 'CharacterDatabase.TransactionIsolation'}
SIMULATED_TIMEOUT_FACTOR = 3
POLICY_FILE = 'clock_policy.json'
CLOCK_OPTIONS = {'step_ms': 'StepMs', 'active_wait_cap_ms': 'ActiveWaitCapMs', 'poll_cap_ms': 'PollCapMs'}
MEASURES = ('lane', 'phase_mask', 'game_elapsed_ms', 'real_elapsed_ms', 'setup_real_ms', 'ticks', 'max_step_ms',
            'realm_local_start')
RECORDED_MEASURES = ('lane', 'game_elapsed_ms', 'real_elapsed_ms', 'realm_local_start')
REAL_CLOCK_MEASURES = ('realm_local_start',)
SINGLE_MEASURES = ('timezone', 'realm_local_start')
ELAPSED_TOTALS = ('game_elapsed_ms', 'real_elapsed_ms')
SHUTDOWN_MESSAGES = ('Server shut down before the scenario completed',
                     'Server shut down before the case teardown completed')


class Interrupted(Exception):
    pass


class ServerExited(ValueError):
    def __init__(self, message, returncode):
        super().__init__(message)
        self.returncode = returncode


class ServerTimeout(ValueError):
    pass


class BinaryChanged(ValueError):
    pass


def requested_exit(returncode):
    return 0 <= returncode <= 255


@dataclass
class Case:
    key: str
    scenario: dict
    source: str | None = None
    requeued: bool = False
    exclusive: bool = False
    pace: str | None = None

    @property
    def exploratory(self):
        return self.source is not None

    @property
    def label(self):
        return f'exploratory:{self.key}' if self.exploratory else self.key

    @property
    def estimate(self):
        waits = sum(step['ms'] for step in self.scenario['steps'] if step['action'] == 'wait')
        return waits / 1000 + STEP_SECONDS * len(self.scenario['steps'])

    @property
    def timeout_seconds(self):
        return self.scenario.get('timeout_ms', 90000) / 1000

    @property
    def hour(self):
        return self.scenario.get('hour')


@dataclass(eq=False)
class Attempt:
    case: Case
    directory: Path
    sequence: int
    run_id: str
    mode: str = 'batch'
    started: float = field(default_factory=time.monotonic)
    admissible_since: float | None = None
    cut_short: bool = False
    spent: bool = True
    status: str = 'running'
    message: str | None = None
    assertions: int | None = None
    scenario_sha256: str | None = None
    measures: dict = field(default_factory=dict)
    seconds: float = 0.0

    @property
    def result(self):
        return self.directory / 'result.json'

    def finish(self, status, message=None, assertions=None):
        self.status, self.message, self.assertions = status, message, assertions
        self.seconds = round(time.monotonic() - self.started, 3)
        return self


class ThreadOutput:
    def __init__(self, stream):
        self.stream = stream
        self.local = threading.local()

    def target(self):
        return getattr(self.local, 'stream', None) or self.stream

    def write(self, text):
        return self.target().write(text)

    def flush(self):
        self.target().flush()

    def __getattr__(self, name):
        return getattr(self.stream, name)


def validated(scenario, where):
    try:
        return run.validate(scenario)
    except (ValueError, KeyError, TypeError) as error:
        raise ValueError(f'{where}: {error}') from None


def exploratory_key(path, taken):
    stem = re.sub(r'[^a-z0-9]+', '-', path.stem.lower()).strip('-') or 'scenario'
    key, number = stem, 1
    while key in taken:
        number += 1
        key = f'{stem}-{number}'
    return key


def longest_first(cases):
    return sorted(cases, key=lambda case: (case.hour is not None, not case.exclusive, -case.estimate, case.label))


def admissible(attempts, lanes):
    result = []
    for attempt in attempts:
        if len(result) == lanes or (attempt.case.exclusive and result):
            break
        result.append(attempt)
        if attempt.case.exclusive:
            break
    return result


def read_report(path):
    try:
        return run.read_json(path)
    except (OSError, ValueError) as error:
        return error


def cut_short(report):
    return isinstance(report, dict) and report.get('status') == 'failed' and report.get('message') in SHUTDOWN_MESSAGES


def measured(report):
    values = {}
    for key in MEASURES:
        if report.get(key) is None:
            continue
        try:
            values[key] = int(report[key])
        except (TypeError, ValueError):
            values[key] = report[key]
    return values


def clock_policy(directory=catalog.DIRECTORY):
    path = directory / POLICY_FILE
    policy = catalog.read_json(path)
    run.require(isinstance(policy, dict) and set(policy) == {'schema', 'exclusive'}
                and type(policy['schema']) is int and policy['schema'] == 1, f'Unsupported clock policy: {path}')
    exclusive = policy['exclusive']
    run.require(isinstance(exclusive, dict), f'{path}: exclusive must map scenario ids to reasons')
    for key, reason in exclusive.items():
        run.require(re.fullmatch(r'[a-z0-9-]+', key) and (directory / 'scenarios' / f'{key}.json').is_file(),
                    f'{path}: unknown scenario {key}')
        run.require(isinstance(reason, str) and reason.strip(), f'{path}: {key} needs a reason')
    return exclusive


def select_cases(values, directory=catalog.DIRECTORY, excluded=()):
    checks = catalog.bindings(directory)
    definitions = {row['id']: catalog.read_json(catalog.ROOT / row['path'])
                   for row in catalog.catalog(directory)}
    fingerprints = {}
    for key, definition in definitions.items():
        fingerprints.setdefault(json.dumps(definition, sort_keys=True), key)
    requested, exploratory, sources = [], {}, set()
    for value in values or sorted(set(definitions) - set(excluded)):
        if value in definitions:
            requested.append(value)
            continue
        path = Path(value)
        run.require(path.is_file(), f'Unknown scenario id or file: {value}')
        scenario = run.read_json(path)
        key = fingerprints.get(json.dumps(scenario, sort_keys=True))
        if key:
            requested.append(key)
        elif str(path.resolve()) not in sources:
            sources.add(str(path.resolve()))
            name = exploratory_key(path, exploratory.keys() | definitions.keys())
            exploratory[name] = Case(name, validated(scenario, value), str(path.resolve()))
    cases = [Case(key, validated(definitions[key], key)) for key in catalog.companion_cases(requested, checks)]
    cases.extend(exploratory.values())
    run.require(cases, 'No scenarios selected')
    return cases


class Server:
    def __init__(self, batch, slot, number):
        self.batch = batch
        self.slot = slot
        self.number = number
        self.batch_id = batch.new_identifier()
        self.name = f'slot-{slot}-{number}'
        self.directory = batch.output / 'servers' / self.name
        self.case_directory = self.directory / 'cases'
        self.attempts = []
        self.running = []
        self.finished = []
        self.lost = []
        self.sequence = 0
        self.completed = 0
        self.failed = False
        self.stuck = False
        self.fatal = False
        self.interrupted = False
        self.phase = 'preparing'
        self.binary_sha256 = batch.binary_sha256
        self.summary = {'schema': 1, 'batch_id': self.batch_id, 'slot': slot, 'restarts': number - 1,
                        'directory': str(self.directory), 'status': 'failed'}

    def run(self):
        started = time.monotonic()
        batch = self.batch
        credentials = Path(tempfile.mkdtemp(prefix='coa-gameplay-batch-'))
        generated = credentials / 'worldserver.conf'
        database = cache = None
        refresh = batch.refresh_pending(self.slot)
        try:
            self.case_directory.mkdir(parents=True)
            database = run.Databases(batch.mysql, batch.dump, credentials, batch.connections, self.batch_id)
            self.summary['databases'] = database.names
            if not batch.args.fresh_databases:
                cache = run.WorldCache(database, batch.cache_root / f'slot-{self.slot}', batch.inputs,
                                       result_directory=self.directory)
            self.summary['world_cache'] = run.world_cache_info(cache)
            run.prepare_databases(database, cache, refresh)
            self.summary['prepare_seconds'] = round(time.monotonic() - started, 3)
            files = {'ready': self.directory / 'ready.json', 'cases': self.case_directory}
            if cache:
                files['start'] = self.directory / 'start.json'
            overrides = run.harness_overrides(batch.connections, database.names, batch.data_dir, self.directory,
                                              credentials, self.batch_id,
                                              cache.metadata['world_id'] if cache else self.batch_id, files,
                                              batch.clock_settings) | batch.database_settings
            run.write_config(batch.source_config, generated, overrides)
            self.serve(run.server_command(batch.binary, generated), run.server_environment(overrides), cache)
        except run.ServerStillRunning as error:
            self.stuck = True
            self.summary['process_id'] = error.pid
            self.fail(str(error), unattributed=True)
        except Interrupted as error:
            self.interrupted = True
            self.summary.update(status='interrupted', message=str(error))
        except BinaryChanged as error:
            self.fatal = True
            self.fail(str(error), unattributed=True)
        except FAILURES as error:
            self.fail(str(error), unattributed=self.phase == 'stopping')
        finally:
            try:
                if refresh and cache and cache.info.get('mode') in REFRESHED_MODES:
                    batch.mark_refreshed(self.slot)
                self.settle_lost()
                if database:
                    self.release(database, cache)
            finally:
                generated.unlink(missing_ok=True)
                if database:
                    database.remove_credentials()
                shutil.rmtree(credentials, ignore_errors=True)
                self.summary['total_seconds'] = round(time.monotonic() - started, 3)
                self.finish()

    def release(self, database, cache):
        try:
            failures = run.release_databases(database, cache, self.stuck, self.summary)
        except FAILURES as error:
            failures = list(database.names.values())
            self.summary.update(status='failed', cleanup_failed=failures, cleanup_error=str(error))
        self.summary['cleanup'] = 'failed' if failures else 'passed'
        if failures:
            self.fail(f'Database cleanup failed: {failures}', unattributed=True)

    def check_start(self):
        if self.batch.stopping.is_set():
            raise Interrupted('Batch interrupted before the worldserver started')
        self.binary_sha256 = run.sha256(self.batch.binary)
        self.summary['binary_sha256'] = self.binary_sha256
        if self.binary_sha256 != self.batch.binary_sha256:
            self.batch.binary_changed = True
            raise BinaryChanged(f'The worldserver binary changed after the batch started: {self.batch.binary}; '
                                'run the batch again once the build is complete')

    def serve(self, command, environment, cache):
        working_directory = self.directory if self.batch.args.server_modules_dir else self.batch.output
        self.check_start()
        with (self.directory / 'worldserver.log').open('wb') as log:
            process = run.start_server(command, working_directory, log, environment)
            try:
                self.phase = 'starting'
                started = time.monotonic()
                ready_path = self.directory / 'ready.json'
                self.wait(process, ready_path.exists, started + self.batch.args.startup_timeout,
                          'Worldserver/harness readiness timed out', 'before readiness')
                ready = run.read_ready(ready_path, self.batch_id)
                run.require(ready.get('mode') == 'queue', 'This worldserver lacks the gameplay queue mode; rebuild it')
                if self.batch.simulated:
                    start_hour = self.batch.clock_settings['StartHour']
                    run.require(ready.get('clock') == SIMULATED_CLOCK
                                and str(ready.get('lanes')) == str(self.batch.lanes)
                                and str(ready.get('start_hour')) == str(start_hour),
                                f'This worldserver did not start {self.batch.lanes} simulated-clock lanes at '
                                f'{start_hour:02d}:00 realm-local time; rebuild it')
                    workers, isolation = (self.batch.database_settings[key] for key in READY_DATABASE_SETTINGS.values())
                    run.require(applied_database_settings(ready, self.batch.database_settings),
                                f'This worldserver did not open {workers} character database workers at {isolation}; '
                                'rebuild it')
                if cache:
                    cache.ready(ready, self.directory / 'start.json', self.batch_id)
                self.batch.server_ready()
                self.summary['startup_seconds'] = round(time.monotonic() - started, 3)
                self.phase = 'serving'
                self.drain(process)
                if self.batch.stopping.is_set():
                    raise Interrupted('Batch interrupted')
                self.phase = 'stopping'
                self.stop(process)
            finally:
                run.stop_process(process)
                self.summary['exit_code'] = process.returncode

    def wait(self, process, condition, deadline, timeout_message, context):
        while not condition():
            if self.batch.stopping.is_set():
                raise Interrupted('Batch interrupted')
            if process.poll() is not None and not condition():
                raise ServerExited(f'Worldserver exited with code {process.returncode} {context}; '
                                   f'see {self.directory / "worldserver.log"}', process.returncode)
            if time.monotonic() >= deadline:
                raise ServerTimeout(timeout_message)
            time.sleep(POLL_SECONDS)

    def drain(self, process):
        try:
            while True:
                self.admit()
                if not self.running:
                    return
                self.poll(process)
        except (ServerExited, ServerTimeout) as error:
            self.lose(error)
            raise
        except (OSError, ValueError, Interrupted) as error:
            self.abandon(error)
            raise

    @property
    def closing(self):
        return any(attempt.cut_short for attempt in self.running)

    def admit(self):
        if self.closing:
            return
        while len(self.running) < self.batch.window:
            case = self.batch.take(idle=not self.running)
            if case is None:
                break
            self.write_case(case)
        now = time.monotonic()
        for attempt in admissible(self.running, self.batch.lanes):
            if attempt.admissible_since is None:
                attempt.admissible_since = now

    def write_case(self, case):
        attempt = Attempt(case, self.batch.case_directory(case), self.sequence, self.batch.new_identifier(),
                          self.batch.mode(case))
        self.attempts.append(attempt)
        self.sequence += 1
        try:
            attempt.directory.mkdir(parents=True)
            scenario_path = attempt.directory / 'scenario.json'
            scenario_path.write_text(json.dumps(case.scenario, indent=2) + '\n', encoding='utf-8')
            attempt.scenario_sha256 = run.sha256(scenario_path)
            write_json(self.case_directory / f'case-{attempt.sequence:06d}.json',
                       self.case_record(attempt, scenario_path))
        except (OSError, ValueError) as error:
            self.batch.announce(attempt.finish('failed', str(error)))
            raise
        attempt.started = time.monotonic()
        self.running.append(attempt)

    def case_record(self, attempt, scenario_path):
        record = {'schema': 1, 'batch_id': self.batch_id, 'sequence': attempt.sequence, 'run_id': attempt.run_id,
                  'scenario_file': scenario_path.as_posix(), 'result_file': attempt.result.as_posix()}
        if self.batch.simulated and attempt.case.exclusive:
            record['exclusive'] = True
        if self.batch.simulated and attempt.case.pace:
            record['pace'] = attempt.case.pace
        if self.batch.simulated and attempt.case.hour is not None:
            record['hour'] = attempt.case.hour
        return record

    def poll(self, process):
        completed = self.collect()
        if process.poll() is not None:
            self.collect()
            if self.batch.stopping.is_set():
                raise Interrupted('Batch interrupted')
            pending = 'before returning the case result' if self.running else 'while it waited for the next case'
            raise ServerExited(f'Worldserver exited with code {process.returncode} {pending}; '
                               f'see {self.directory / "worldserver.log"}', process.returncode)
        if completed or not self.running:
            return
        if self.batch.stopping.is_set():
            raise Interrupted('Batch interrupted')
        now = time.monotonic()
        started = [attempt for attempt in self.running if attempt.admissible_since is not None]
        for attempt in started:
            limit = self.batch.backstop(attempt.case)
            if now >= attempt.admissible_since + limit:
                named = f' {attempt.sequence} ({attempt.case.label})' if len(started) > 1 else ''
                raise ServerTimeout(f'Case{named} timed out after {limit:g} s')
        time.sleep(POLL_SECONDS)

    def collect(self):
        completed = False
        for attempt in [attempt for attempt in self.running if not attempt.cut_short and attempt.result.exists()]:
            report = read_report(attempt.result)
            if cut_short(report):
                attempt.cut_short = True
                continue
            self.running.remove(attempt)
            self.complete(attempt, report)
            completed = True
        return completed

    def complete(self, attempt, report):
        try:
            run.require(not isinstance(report, Exception), str(report))
            run.require(isinstance(report, dict), 'Result is not a JSON object')
            attempt.measures = measured(report)
            run.require(report.get('batch_id') == self.batch_id
                        and str(report.get('sequence')) == str(attempt.sequence),
                        'Result belongs to a different batch case')
            run.check_report(report, attempt.run_id, attempt.case.scenario, 0)
            attempt.finish('passed', assertions=int(report['assertions']))
        except (ValueError, KeyError, TypeError, OSError) as error:
            attempt.finish('failed', str(error))
        self.completed += 1
        self.finished.append(attempt)
        self.batch.announce(attempt)

    def lose(self, error):
        running, self.running = self.running, []
        requested = isinstance(error, ServerExited) and requested_exit(error.returncode)
        started = [attempt for attempt in running
                   if (attempt.cut_short if requested else attempt.admissible_since is not None)]
        waiting = [attempt for attempt in running if attempt not in started]
        earlier = self.finished[-1] if self.finished else None
        if len(started) == 1 and earlier is None and not requested:
            self.batch.announce(started[0].finish('failed', str(error)))
            self.set_aside(waiting, f'{error}; the case had not started', spent=False)
            return
        if requested:
            cause = 'the harness stops a worldserver itself only for teardown, isolation or queue protocol failures'
            if earlier:
                cause += f'; case {earlier.sequence} ({earlier.case.label}) returned the last result'
        elif earlier:
            cause = (f'case {earlier.sequence} ({earlier.case.label}) had already returned its result, so its '
                     'teardown may be the cause')
        elif started:
            cause = f'{len(started)} cases were running at once, so the cause cannot be attributed to one of them'
        else:
            cause = 'no case had started'
        message = f'{error}; {cause}'
        names = ', '.join(f'{attempt.sequence} ({attempt.case.label})' for attempt in started)
        lost = f" case{'s' if len(started) > 1 else ''} {names}" if started else ''
        self.batch.fail(f'{self.name}{lost}: {message}')
        for attempt in started:
            if attempt.case.requeued:
                self.batch.announce(attempt.finish('failed', message))
            else:
                self.set_aside([attempt], message, spent=True)
        self.set_aside(waiting, f'{message}; the case had not started', spent=False)

    def abandon(self, error):
        running, self.running = self.running, []
        if isinstance(error, Interrupted):
            for attempt in running:
                self.batch.announce(attempt.finish('failed', str(error)))
        else:
            self.set_aside(running, f'The runner stopped the worldserver: {error}', spent=False)

    def set_aside(self, attempts, message, spent):
        for attempt in attempts:
            attempt.spent = spent
            self.lost.append(attempt.finish('requeued', message))

    def retry(self, attempt):
        if not attempt.spent:
            return attempt.case
        return replace(attempt.case, requeued=True, exclusive=attempt.case.exclusive or self.batch.lanes > 1)

    def settle_lost(self):
        lost, self.lost = self.lost, []
        retries = []
        for attempt in lost:
            if not self.stuck:
                target = self.directory / 'requeued' / attempt.case.key
                try:
                    target.parent.mkdir(parents=True, exist_ok=True)
                    attempt.directory.rename(target)
                except OSError as error:
                    attempt.message = f'{attempt.message}; the case could not be queued again: {error}'
                else:
                    attempt.directory = target
                    retries.append(self.retry(attempt))
                    self.batch.progress(f'REQUEUED {attempt.case.label} {attempt.seconds:.1f}')
                    continue
            attempt.status = 'failed'
            self.batch.announce(attempt)
        self.batch.requeue(retries)

    def stop(self, process):
        write_json(self.case_directory / f'case-{self.sequence:06d}.json',
                   {'schema': 1, 'batch_id': self.batch_id, 'sequence': self.sequence, 'stop': True})
        deadline = time.monotonic() + STOP_SECONDS
        while process.poll() is None:
            if self.batch.stopping.is_set():
                raise Interrupted('Batch interrupted')
            run.require(time.monotonic() < deadline, f'Worldserver did not stop within {STOP_SECONDS} s')
            time.sleep(POLL_SECONDS)
        run.require(process.returncode == 0, f'Worldserver exited with code {process.returncode} after its queue')
        self.summary['status'] = 'stopped'

    def fail(self, message, unattributed=False):
        self.failed = True
        self.summary['status'] = 'failed'
        self.summary.setdefault('message', message)
        self.batch.progress(f'SERVER {self.name} FAILED: {message}')
        if unattributed:
            self.batch.fail(f'{self.name}: {message}')

    def case_summary(self, attempt, cleanup):
        batch = self.batch
        summary = {'schema': 1, 'run_id': attempt.run_id, 'scenario': attempt.case.scenario['name'],
                   'status': attempt.status, 'binary': str(batch.binary), 'binary_sha256': self.binary_sha256,
                   'scenario_sha256': attempt.scenario_sha256, 'databases': self.summary.get('databases', {}),
                   'world_cache': self.summary.get('world_cache', {}), 'module_config_sha256': batch.module_hashes,
                   'batch': {'id': self.batch_id, 'slot': self.slot, 'sequence': attempt.sequence,
                             'server_directory': str(self.directory)},
                   'seconds': attempt.seconds}
        if batch.simulated:
            summary['simulation'] = {'lanes': batch.lanes, 'pace': attempt.case.pace or 'accelerated',
                                     'exclusive': attempt.case.exclusive, **attempt.measures}
        if attempt.assertions is not None:
            summary['assertions'] = attempt.assertions
        if attempt.message:
            summary['message'] = attempt.message
        if cleanup and attempt.status != 'requeued':
            summary.update(cleanup, status='failed')
            summary.setdefault('message', f"Database cleanup failed: {cleanup.get('cleanup_failed')}")
        return summary

    def finish(self):
        cleanup = {key: self.summary[key] for key in CLEANUP_FIELDS if key in self.summary}
        cases = []
        for attempt in self.attempts:
            summary = self.case_summary(attempt, cleanup)
            if attempt.directory.is_dir():
                (attempt.directory / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n',
                                                                encoding='utf-8')
            entry = {'id': attempt.case.label, 'sequence': attempt.sequence, 'run_id': attempt.run_id,
                     'status': summary['status']}
            if self.batch.simulated:
                entry['mode'] = attempt.mode
            cases.append(entry)
            if attempt.status == 'requeued':
                continue
            if attempt.status == 'passed' and summary['status'] != 'passed':
                self.batch.progress(f'FAIL {attempt.case.label} {attempt.seconds:.1f} cleanup')
            record = {'status': summary['status'], 'mode': attempt.mode, 'directory': str(attempt.directory),
                      'message': summary.get('message'), 'seconds': attempt.seconds, 'server': self.name,
                      'attempt_status': attempt.status}
            recorded = RECORDED_MEASURES if self.batch.simulated else REAL_CLOCK_MEASURES
            record.update({key: attempt.measures[key] for key in recorded if key in attempt.measures})
            self.batch.record(attempt, record)
        self.summary['cases'] = cases
        self.directory.mkdir(parents=True, exist_ok=True)
        (self.directory / 'summary.json').write_text(json.dumps(self.summary, indent=2) + '\n', encoding='utf-8')
        self.batch.add_server({key: value for key, value in self.summary.items() if key != 'cases'}
                              | {'case_count': len(cases)})


def applied_database_settings(ready, settings):
    return all(str(ready.get(field)) == str(settings[key]) for field, key in READY_DATABASE_SETTINGS.items())


def database_settings(args):
    if args.clock != SIMULATED_CLOCK:
        return {}
    return {'CharacterDatabase.WorkerThreads': args.character_db_workers,
            'CharacterDatabase.TransactionIsolation': SIMULATED_CHARACTER_ISOLATION}


class Batch:
    def __init__(self, args, output, cases, directory):
        self.args = args
        self.output = output
        self.cases = cases
        self.directory = directory
        self.simulated = args.clock == SIMULATED_CLOCK
        self.lanes = args.lanes
        self.window = 2 * args.lanes if self.simulated else 1
        self.clock_settings = None
        self.database_settings = database_settings(args)
        if self.simulated:
            self.clock_settings = {'Clock': SIMULATED_CLOCK, 'Lanes': args.lanes,
                                   **{name: getattr(args, option) for option, name in CLOCK_OPTIONS.items()},
                                   'StartHour': run.CLOCK_SETTINGS['StartHour']}
        self.singles = longest_first(case for case in cases if self.single(case))
        self.queue = deque(longest_first(case for case in cases if not self.single(case)))
        self.queued = len(self.queue)
        self.lock = threading.Lock()
        self.console_lock = threading.Lock()
        self.stopping = threading.Event()
        self.stop_requested = False
        self.results = {}
        self.accelerated = {}
        self.real_pace = {}
        self.real_pace_queued = False
        self.isolated = {}
        self.servers = []
        self.failures = []
        self.identifiers = set()
        self.unusable_slots = set()
        self.refreshed_slots = set()
        self.ready_servers = 0
        self.binary_changed = False
        self.console = sys.stdout
        self.router = None
        self.staged = []
        self.module_hashes = {}
        self.binary = args.worldserver.resolve(strict=True)
        self.source_config = args.config.resolve(strict=True)
        self.mysql = args.mysql.resolve(strict=True)
        self.dump = args.mysqldump.resolve(strict=True)
        config = run.read_config(self.source_config)
        self.connections = run.source_connections(config, args.database_client_config)
        self.data_dir = run.data_directory(config, self.binary)
        self.module_source = args.modules_config_dir or self.source_config.parent / 'modules'
        self.module_target = args.server_modules_dir or output / 'configs' / 'modules'
        self.cache_root = args.world_cache_root.resolve()
        self.binary_sha256 = run.sha256(self.binary)
        self.inputs = None
        if not args.fresh_databases:
            self.inputs = run.input_fingerprint(run.ROOT, self.source_config, self.module_source)

    def new_identifier(self):
        with self.lock:
            value = secrets.token_hex(6)
            while value in self.identifiers:
                value = secrets.token_hex(6)
            self.identifiers.add(value)
            return value

    def single(self, case):
        return not self.simulated and case.hour is not None

    def mode(self, case):
        if case.pace == REAL_CLOCK:
            return 'real_pace'
        if self.single(case):
            return 'single'
        return SIMULATED_CLOCK if self.simulated else 'batch'

    def backstop(self, case):
        factor = SIMULATED_TIMEOUT_FACTOR if self.simulated else 1
        return factor * case.timeout_seconds + CASE_GRACE_SECONDS

    def case_directory(self, case):
        folder = 'exploratory' if case.exploratory else 'real-pace' if case.pace == REAL_CLOCK else 'cases'
        return self.output / folder / case.key

    def queue_real_pace(self):
        if (not self.simulated or not self.args.real_pace_rerun or self.real_pace_queued or
                self.queue or self.stopping.is_set()):
            return
        self.real_pace_queued = True
        self.queue.extend(longest_first(replace(case, pace=REAL_CLOCK) for case in self.cases
                                        if not case.exploratory and self.accelerated.get(case.label) != 'passed'))

    def take(self, idle=True):
        with self.lock:
            if self.stopping.is_set():
                return None
            if idle:
                self.queue_real_pace()
            return self.queue.popleft() if self.queue else None

    def requeue(self, cases):
        with self.lock:
            self.queue.extendleft(reversed(cases))

    def pending(self):
        with self.lock:
            self.queue_real_pace()
            return bool(self.queue) and not self.stopping.is_set()

    def record(self, attempt, record):
        with self.lock:
            if attempt.mode == 'real_pace':
                self.real_pace[attempt.case.key] = record
            else:
                self.results[attempt.case.label] = record

    def add_server(self, summary):
        with self.lock:
            self.servers.append(summary)

    def server_ready(self):
        with self.lock:
            self.ready_servers += 1

    def refresh_pending(self, slot):
        with self.lock:
            return self.args.refresh_world and slot not in self.refreshed_slots

    def mark_refreshed(self, slot):
        with self.lock:
            self.refreshed_slots.add(slot)

    def fail(self, message):
        with self.lock:
            self.failures.append(message)

    def progress(self, text):
        with self.console_lock:
            print(text, file=self.console, flush=True)

    def announce(self, attempt):
        if attempt.mode == SIMULATED_CLOCK:
            with self.lock:
                self.accelerated[attempt.case.label] = attempt.status
        pace = ' real-pace' if attempt.mode == 'real_pace' else ''
        self.progress(f"{'PASS' if attempt.status == 'passed' else 'FAIL'} {attempt.case.label} "
                      f'{attempt.seconds:.1f}{pace}')

    def request_stop(self, signum, frame):
        self.stop_requested = True

    def interrupted(self):
        if self.stop_requested and not self.stopping.is_set():
            self.stopping.set()
            self.progress('INTERRUPTED: stopping worldservers and cleaning up')
        return self.stopping.is_set()

    @contextmanager
    def deferred_signals(self):
        handlers = {}
        try:
            if threading.current_thread() is threading.main_thread():
                for number in STOP_SIGNALS:
                    handlers[number] = signal.signal(number, self.request_stop)
            yield
        finally:
            for number, handler in handlers.items():
                signal.signal(number, handler)

    def thread(self, target, slot):
        def body():
            with (self.output / 'logs' / f'slot-{slot}.log').open('a', encoding='utf-8') as log:
                self.router.local.stream = log
                try:
                    target(slot)
                except Exception as error:
                    self.fail(f'slot-{slot}: unexpected {type(error).__name__}: {error}')
                finally:
                    self.router.local.stream = None
        return threading.Thread(target=body, name=f'coa-gameplay-slot-{slot}')

    def run_threads(self, target, slots):
        threads = []
        try:
            for slot in slots:
                if self.interrupted():
                    break
                threads.append(self.thread(target, slot))
                threads[-1].start()
        finally:
            for thread in threads:
                while thread.is_alive():
                    self.interrupted()
                    thread.join(JOIN_SECONDS)

    def work(self, slot):
        failures = number = 0
        while failures < SERVER_FAILURE_LIMIT and self.pending():
            number += 1
            server = Server(self, slot, number)
            server.run()
            if server.completed:
                failures = 0
            if server.failed:
                failures += 1
            if server.stuck:
                with self.lock:
                    self.unusable_slots.add(slot)
                return
            if server.interrupted or server.fatal:
                return
        if failures >= SERVER_FAILURE_LIMIT:
            self.progress(f'SLOT {slot} STOPPED after {failures} consecutive server failures')
            self.fail(f'slot-{slot} stopped after {failures} consecutive worldserver failures without a completed '
                      'case')

    def mark_not_run(self):
        message = 'Interrupted before the case ran' if self.stopping.is_set() else 'No worldserver could run this case'
        for case in self.cases:
            if case.label not in self.results:
                self.results[case.label] = {'status': 'not_run', 'mode': self.mode(case), 'directory': None,
                                            'message': message, 'seconds': 0}
                self.progress(f'FAIL {case.label} 0.0 not run')

    def ladder_record(self, case):
        record = self.results[case.label]
        real = None if case.exploratory else self.real_pace.get(case.key)
        if not real:
            return record
        if real['status'] == 'passed' or not record['directory']:
            return {**real, 'batch': record}
        return {**record, 'real_pace': real}

    def run_singles(self):
        self.run_isolated(self.singles, 'single', 'Single-mode runs at a fixed realm-local hour')

    def rerun_failures(self):
        reruns = [case for case in longest_first(self.cases) if not case.exploratory and not self.single(case)
                  and self.ladder_record(case)['status'] != 'passed']
        if reruns and self.ready_servers:
            self.run_isolated(reruns, 'isolated', 'Isolated reruns')

    def run_isolated(self, cases, mode, name):
        if not cases:
            return
        if self.binary_changed:
            self.fail(f'{name} were skipped: the worldserver binary changed during the batch')
            return
        slots = [slot for slot in range(self.args.jobs) if slot not in self.unusable_slots][:len(cases)]
        if not slots:
            self.fail(f'{name} were skipped: every world-cache slot is still leased by a running server')
            return
        pending = deque(cases)
        self.run_threads(lambda slot: self.isolated_slot(slot, pending, mode), slots)

    def isolated_slot(self, slot, pending, mode):
        while not self.stopping.is_set():
            with self.lock:
                if not pending or slot in self.unusable_slots:
                    return
                case = pending.popleft()
            self.rerun(slot, case, mode)

    def rerun(self, slot, case, mode):
        directory = self.case_directory(case) if mode == 'single' else self.output / 'isolated' / case.key
        refresh = self.refresh_pending(slot)
        parameters = SimpleNamespace(
            worldserver=self.binary, config=self.source_config, mysql=self.mysql, mysqldump=self.dump,
            database_client_config=self.args.database_client_config,
            modules_config_dir=self.args.modules_config_dir, server_modules_dir=self.args.server_modules_dir,
            output=directory, startup_timeout=self.args.startup_timeout, fresh_databases=self.args.fresh_databases,
            refresh_world=refresh, world_cache_dir=self.cache_root / f'slot-{slot}',
            staged_module_configs=self.staged if self.args.server_modules_dir else None,
            should_stop=self.stopping.is_set)
        kind = 'single-mode run' if mode == 'single' else 'isolated rerun'
        started = time.monotonic()
        code, message = 1, None
        try:
            code = run.execute(parameters, case.scenario)
        except KeyboardInterrupt:
            message = f'Batch interrupted during the {kind}'
        except FAILURES as error:
            message = str(error)
        seconds = round(time.monotonic() - started, 3)
        try:
            summary = run.read_json(directory / 'summary.json')
        except (OSError, ValueError):
            summary = {}
        if refresh and summary.get('world_cache', {}).get('mode') in REFRESHED_MODES:
            self.mark_refreshed(slot)
        if summary.get('binary_sha256', self.binary_sha256) != self.binary_sha256:
            code, message = 1, 'The worldserver binary changed during the batch'
            self.fail(f'{kind.capitalize()} of {case.key}: {message}')
        status = 'passed' if code == 0 else 'failed'
        record = {'status': status, 'directory': str(directory), 'message': message or summary.get('message'),
                  'seconds': seconds, 'slot': slot, **{key: summary[key] for key in SINGLE_MEASURES if key in summary}}
        with self.lock:
            if 'process_id' in summary:
                self.unusable_slots.add(slot)
            if mode == 'single':
                self.results[case.label] = {**record, 'mode': mode}
            else:
                self.isolated[case.key] = record
        self.progress(f"{'PASS' if status == 'passed' else 'FAIL'} {case.label} {seconds:.1f} {mode}")

    def final_record(self, case):
        record = self.ladder_record(case)
        isolated = self.isolated.get(case.key)
        if not isolated:
            return record
        if isolated['status'] == 'passed' or not record['directory']:
            return {**{key: value for key, value in isolated.items() if key != 'slot'}, 'mode': 'isolated',
                    'batch': record}
        return {**record, 'isolated': isolated}

    def isolated_passes(self):
        sensitive, isolated_only = [], []
        for key, isolated in sorted(self.isolated.items()):
            if isolated['status'] == 'passed':
                failed_in_batch = self.results[key].get('attempt_status') == 'failed'
                (sensitive if failed_in_batch else isolated_only).append(key)
        return sensitive, isolated_only

    def acceleration_sensitive(self):
        return sorted(key for key, record in self.real_pace.items() if record['status'] == 'passed')

    def native_scope(self):
        if not self.simulated:
            return 'queue-mode native execution'
        settings = self.clock_settings
        return (f"simulated-clock queue-mode native execution ({self.lanes} lanes, {settings['StepMs']} ms steps, "
                f"{settings['ActiveWaitCapMs']} ms wait cap, {settings['PollCapMs']} ms poll cap)")

    def scope(self, keys):
        if not keys:
            return EXPLORATORY_SCOPE
        batch_attempts = any('attempt_status' in self.results[key] for key in keys)
        singles = any(self.results[key]['mode'] == 'single' and self.results[key]['directory'] for key in keys)
        ran = [label for condition, label in ((batch_attempts, self.native_scope()),
                                              (singles, 'single-mode runs at a fixed realm-local hour'),
                                              (self.real_pace, 'real-pace reruns on the same worldserver'),
                                              (self.isolated, 'isolated single-mode reruns')) if condition]
        return SCOPE.format(' and '.join(ran) or 'no native execution')

    def simulation(self):
        settings = self.clock_settings
        return {'step_ms': settings['StepMs'], 'active_wait_cap_ms': settings['ActiveWaitCapMs'],
                'poll_cap_ms': settings['PollCapMs'], 'start_hour': settings['StartHour'],
                'character_db_workers': self.database_settings['CharacterDatabase.WorkerThreads'],
                'character_db_isolation': self.database_settings['CharacterDatabase.TransactionIsolation'],
                'exclusive': sorted(case.key for case in self.cases if case.exclusive)}

    def elapsed_totals(self):
        records = [record for record in self.results.values() if record.get('mode') == SIMULATED_CLOCK]
        return {key: sum(record[key] for record in records if type(record.get(key)) is int)
                for key in ELAPSED_TOTALS}

    def verify(self, records, keys):
        if not keys or self.stopping.is_set():
            return {'status': 'skipped', 'failures': [], 'checks': []}
        directories = []
        for key in keys:
            record = records[key]
            candidates = [record['directory'], record.get('isolated', {}).get('directory')]
            found = [Path(path) for path in candidates if path and (Path(path) / 'summary.json').is_file()]
            if found:
                directories.append(found[0])
        result = verification.verify(directories, self.directory, expected_scenarios=keys)
        (self.output / 'verification.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
        return result

    def report(self, started):
        keys = [case.key for case in self.cases if not case.exploratory]
        records = {case.key: self.final_record(case) for case in self.cases if not case.exploratory}
        exploratory = {case.key: {**self.results[case.label], 'path': case.source}
                       for case in self.cases if case.exploratory}
        outcomes = [record['status'] for record in [*records.values(), *exploratory.values()]]
        checked = self.verify(records, keys)
        interrupted = self.stopping.is_set()
        sensitive, isolated_only = self.isolated_passes()
        accelerated = self.acceleration_sensitive()
        succeeded = all(status == 'passed' for status in outcomes) and not self.failures and not interrupted
        if keys:
            status = 'passed' if succeeded and checked['status'] == 'passed' else 'failed'
        else:
            status = 'exploratory' if succeeded else 'failed'
        result = {
            'schema': 1, 'status': status, 'scope': self.scope(keys),
            'selected': keys, 'exploratory': list(exploratory), 'jobs': self.args.jobs,
            'clock': self.args.clock, 'lanes': self.lanes,
            'binary': str(self.binary), 'binary_sha256': self.binary_sha256,
            'counts': {'passed': outcomes.count('passed'), 'failed': outcomes.count('failed'),
                       'not_run': outcomes.count('not_run'),
                       'passed_on_isolated_rerun': len(sensitive) + len(isolated_only)},
            'cases': dict(sorted(records.items())), 'acceleration_sensitive': accelerated,
            'batch_sensitive': sensitive, 'isolated_only': isolated_only,
            'exploratory_results': exploratory,
            'servers': sorted(self.servers, key=lambda server: (server['slot'], server['restarts'])),
            'verification': {
                'status': checked['status'],
                'failures': [{**failure, 'message': str(failure.get('message', ''))[-MESSAGE_LIMIT:]}
                             for failure in checked['failures']],
                'checks': [{key: check[key] for key in ('script', 'scenarios', 'args', 'status')}
                           for check in checked['checks']]},
            'failures': self.failures, 'interrupted': interrupted,
            'seconds': round(time.monotonic() - started, 3),
        }
        if self.simulated:
            result.update(self.elapsed_totals(), simulation=self.simulation())
        path = self.output / 'gameplay.json'
        path.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
        for key, record in [*records.items(), *exploratory.items()]:
            if record['status'] != 'passed':
                print(f"{key}: {str(record.get('message'))[-300:]}", file=sys.stderr)
        for message in [*self.failures, *(failure['message'] for failure in result['verification']['failures'])]:
            print(str(message)[-MESSAGE_LIMIT:], file=sys.stderr)
        counts = result['counts']
        scope = f"verification {checked['status']}" if keys else 'exploratory native execution only'
        isolated = f', {len(isolated_only)} isolated-only' if isolated_only else ''
        sensitivity = f'{len(accelerated)} acceleration-sensitive, ' if self.simulated else ''
        self.progress(f"GAMEPLAY {VERDICTS[status]}: {counts['passed']} passed, "
                      f"{counts['failed']} failed, {counts['not_run']} not run, "
                      f'{sensitivity}{len(sensitive)} batch-sensitive{isolated}, {len(self.failures)} batch failures, '
                      f'{scope}; {path}')
        return result

    def execute(self, started):
        (self.output / 'logs').mkdir()
        self.router = ThreadOutput(self.console)
        previous = sys.stdout
        sys.stdout = self.router
        try:
            with self.deferred_signals():
                self.staged = run.stage_modules(self.module_source, self.module_target, run.reserved_settings())
                try:
                    self.module_hashes = {path.name: run.sha256(path) for path in self.staged}
                    self.run_threads(self.work, range(min(self.args.jobs, self.queued)))
                    if not self.interrupted():
                        self.run_singles()
                    self.interrupted()
                    self.mark_not_run()
                    if self.queued and not self.ready_servers and not self.stopping.is_set():
                        self.fail('No queue-mode worldserver became ready')
                    if not self.interrupted() and self.args.isolated_rerun:
                        self.rerun_failures()
                finally:
                    for path in self.staged:
                        path.unlink(missing_ok=True)
                self.interrupted()
            return self.report(started)
        finally:
            sys.stdout = previous


def run_batch(args, directory=catalog.DIRECTORY):
    started = time.monotonic()
    cases = select_cases(args.scenario, directory, getattr(args, 'skip_scenario', []))
    if args.clock == SIMULATED_CLOCK:
        exclusive = clock_policy(directory)
        for case in cases:
            world_phase = any(step['action'] == 'set_phase' and step['value'] & 1
                              for step in case.scenario['steps'])
            case.exclusive = (world_phase or case.scenario.get('creature_scaling', False)
                              or (not case.exploratory and case.key in exclusive) or case.hour is not None)
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    run.require(not any(output.iterdir()), f'Output directory must be new or empty: {output}')
    return Batch(args, output, cases, directory).execute(started)


def option_name(option):
    return '--' + option.replace('_', '-')


def resolve_clock(args):
    simulated = args.clock == SIMULATED_CLOCK
    if simulated:
        run.require(args.jobs == 1, '--clock simulated runs one worldserver; use --lanes for concurrent cases')
        args.lanes = MAX_LANES if args.lanes is None else args.lanes
        run.require(1 <= args.lanes <= MAX_LANES, f'--lanes must be between 1 and {MAX_LANES}')
        for option, name in CLOCK_OPTIONS.items():
            value = getattr(args, option)
            value = run.CLOCK_SETTINGS[name] if value is None else value
            run.require(1 <= value <= MAX_STEP_MS, f'{option_name(option)} must be between 1 and {MAX_STEP_MS}')
            setattr(args, option, value)
        if args.character_db_workers is None:
            args.character_db_workers = DEFAULT_CHARACTER_DB_WORKERS
        run.require(1 <= args.character_db_workers <= MAX_DATABASE_WORKERS,
                    f'--character-db-workers must be between 1 and {MAX_DATABASE_WORKERS}')
    else:
        run.require(not args.real_pace_rerun, '--real-pace-rerun requires --clock simulated')
        run.require(args.lanes in (None, 1), '--lanes above 1 requires --clock simulated')
        tuned = [option_name(option) for option in CLOCK_OPTIONS if getattr(args, option) is not None]
        run.require(not tuned, f"Clock tuning ({', '.join(tuned)}) requires --clock simulated")
        run.require(args.character_db_workers in (None, 1), '--character-db-workers above 1 requires --clock simulated')
        args.lanes = 1
        args.character_db_workers = 1
    if args.isolated_rerun is None:
        args.isolated_rerun = not simulated
    return args


def interrupt(signum, frame):
    raise KeyboardInterrupt


def parser():
    result = argparse.ArgumentParser(description=CLI_DESCRIPTION,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    result.add_argument('--worldserver', type=Path, required=True)
    result.add_argument('--config', type=Path, required=True, help='Source worldserver config; never changed')
    result.add_argument('--mysql', type=Path, required=True)
    result.add_argument('--mysqldump', type=Path, required=True)
    result.add_argument('--server-modules-dir', type=Path,
                        help='Directory the worldserver reads module configs from; required outside Windows')
    result.add_argument('--modules-config-dir', type=Path, help='Defaults to the source config directory/modules')
    result.add_argument('--database-client-config', type=Path,
                        help='Optional MySQL [client] file with credentials allowed to create/drop test schemas')
    result.add_argument('--output', type=Path, required=True, help='New or empty directory for all results')
    result.add_argument('--jobs', type=int, default=1,
                        help='Concurrent worldservers (default 1; the simulated clock needs 1)')
    result.add_argument('--clock', choices=(REAL_CLOCK, SIMULATED_CLOCK), default=REAL_CLOCK,
                        help='Real clock with one case per worldserver, or accelerated lanes (default real)')
    result.add_argument('--lanes', type=int,
                        help=f'Concurrent simulated-clock cases (1-{MAX_LANES}, default {MAX_LANES})')
    for option, name in CLOCK_OPTIONS.items():
        result.add_argument(option_name(option), type=int, dest=option,
                            help=f'Simulated clock tuning (default {run.CLOCK_SETTINGS[name]})')
    result.add_argument('--character-db-workers', type=int,
                        help='Asynchronous character database workers of the simulated-clock worldserver, which '
                             f'runs its character database at {SIMULATED_CHARACTER_ISOLATION} isolation '
                             f'(1-{MAX_DATABASE_WORKERS}, default {DEFAULT_CHARACTER_DB_WORKERS}; the real clock '
                             'keeps 1)')
    result.add_argument('--scenario', action='extend', nargs='+', default=[], metavar='ID_OR_PATH',
                        help='Catalog id or scenario file; default: every catalog scenario')
    result.add_argument('--real-pace-rerun', action='store_true',
                        help='Diagnose failed accelerated cases with slower same-server reruns '
                             '(default: off; requires --clock simulated)')
    result.add_argument('--isolated-rerun', action=argparse.BooleanOptionalAction, default=None,
                        help='Rerun failed catalog cases in single mode (default: on for the real clock only)')
    result.add_argument('--startup-timeout', type=float, default=600)
    mode = result.add_mutually_exclusive_group()
    mode.add_argument('--fresh-databases', action='store_true', help='Use disposable copies without the world cache')
    mode.add_argument('--refresh-world', action='store_true', help='Replace each slot world cache on first use')
    result.add_argument('--skip-scenario', nargs='+', default=[], help='Catalog ids omitted from default selection')
    result.add_argument('--world-cache-root', type=Path, default=CACHE_ROOT,
                        help='Parent directory of the per-worker world-cache slots')
    return result


def main(argv=None, directory=catalog.DIRECTORY):
    args = parser().parse_args(argv)
    previous_handlers = {}
    try:
        run.require(args.jobs >= 1, '--jobs must be at least 1')
        run.require(math.isfinite(args.startup_timeout) and args.startup_timeout > 0, 'Invalid startup timeout')
        run.require(args.server_modules_dir or os.name == 'nt',
                    '--server-modules-dir is required outside Windows (the worldserver reads CONF_DIR/modules)')
        resolve_clock(args)
        if threading.current_thread() is threading.main_thread():
            for number in EXTERNAL_STOP_SIGNALS:
                previous_handlers[number] = signal.signal(number, interrupt)
        return EXIT_CODES[run_batch(args, directory)['status']]
    except KeyboardInterrupt:
        print('INTERRUPTED', file=sys.stderr)
        return 130
    except (ValueError, OSError, KeyError, TypeError) as error:
        print(f'ERROR: {error}', file=sys.stderr)
        return 1
    finally:
        for number, handler in previous_handlers.items():
            signal.signal(number, handler)


if __name__ == '__main__':
    sys.exit(main())
