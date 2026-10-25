from contextlib import ExitStack, redirect_stderr, redirect_stdout
from datetime import datetime, timezone
import hashlib
import io
import json
import os
from pathlib import Path
import secrets
import signal
import sys
import tempfile
import threading
import time
from types import SimpleNamespace
import unittest
from unittest.mock import patch

import batch
import catalog
import run
import verification
from world_cache import write_json

DIRECTORY = Path(__file__).resolve().parent
FAKE_SERVER = r'''
import json
import os
from pathlib import Path
import signal
import sys
import threading
import time

sys.path.insert(0, sys.argv[1])
import run

CASE_KEYS = {'schema', 'batch_id', 'sequence', 'run_id', 'scenario_file', 'result_file'}
LANE_KEYS = {'exclusive', 'pace', 'hour'}
STOP_KEYS = {'schema', 'batch_id', 'sequence', 'stop'}
DATABASE_KEYS = ('LoginDatabase.WorkerThreads', 'CharacterDatabase.WorkerThreads', 'LoginDatabase.TransactionIsolation',
                 'CharacterDatabase.TransactionIsolation', 'WorldDatabase.TransactionIsolation')
SCENARIO_SHUTDOWN = 'Server shut down before the scenario completed'
TEARDOWN_SHUTDOWN = 'Server shut down before the case teardown completed'
WINDOWS_ACCESS_VIOLATION = 0xC0000005 - (1 << 32)


def write(path, value):
    temporary = Path(str(path) + '.tmp')
    temporary.write_text(json.dumps(value))
    os.replace(temporary, path)


def log(name, value):
    with open(Path(__file__).with_name(name), 'a') as stream:
        stream.write(json.dumps(value) + '\n')


def listen():
    for line in sys.stdin:
        if line.startswith('server shutdown'):
            os._exit(0)


def crash():
    if hasattr(signal, 'SIGKILL'):
        os.kill(os.getpid(), signal.SIGKILL)
    os._exit(WINDOWS_ACCESS_VIOLATION)


def measures(item, lane, seconds):
    waits = sum(step['ms'] for step in item['scenario']['steps'] if step['action'] == 'wait')
    return {'clock': clock, 'lane': str(lane), 'phase_mask': str(1 << 30 if lane == 0 else 1 << (15 + lane)),
            'game_elapsed_ms': str(waits), 'real_elapsed_ms': str(int(seconds * 1000)), 'setup_real_ms': '1',
            'ticks': '10', 'max_step_ms': '25', 'realm_local_start': item['realm_local_start']}


def read_case(sequence):
    path = Path(cases) / f'case-{sequence:06d}.json'
    if not path.exists():
        return None
    case = json.loads(path.read_text())
    if case['schema'] != 1 or case['batch_id'] != run_id or case['sequence'] != sequence:
        sys.exit(5)
    if case.get('stop'):
        if set(case) != STOP_KEYS:
            sys.exit(11)
        return case
    if not CASE_KEYS <= set(case) <= CASE_KEYS | (LANE_KEYS if simulated else set()):
        sys.exit(11)
    if case.get('exclusive', True) is not True or case.get('pace', 'real') != 'real':
        sys.exit(11)
    if 'hour' in case and (type(case['hour']) is not int or not 0 <= case['hour'] <= 23
                           or case.get('exclusive') is not True):
        sys.exit(11)
    if case['run_id'] in used or Path(case['result_file']).exists():
        sys.exit(8)
    used.add(case['run_id'])
    return case


def admit(case, sequence):
    scenario = json.loads(Path(case['scenario_file']).read_text())
    contract = scenario.get('contract', '')
    pace = case.get('pace', 'accelerated')
    lane = min(set(range(lanes)) - set(running))
    ahead = [path for path in Path(cases).glob('case-*.json') if int(path.stem[5:]) > sequence]
    log('lanes.log', {'sequence': sequence, 'name': scenario['name'], 'lane': lane, 'pace': pace,
                      'exclusive': case.get('exclusive', False), 'ahead': len(ahead), 'hour': case.get('hour'),
                      'running': sorted(item['name'] for item in running.values())})
    realm['hour'] = case.get('hour', start_hour)
    if 'batch-crash' in contract:
        crash()
    now = time.monotonic()
    duration = 1.2 if 'linger' in contract else 0.3 if 'slow' in contract else 0.15 if 'midway' in contract else 0.02
    accelerated = simulated and pace != 'real'
    running[lane] = {
        'case': case, 'scenario': scenario, 'name': scenario['name'], 'sequence': sequence, 'admitted': now,
        'exclusive': case.get('exclusive') is True, 'realm_local_start': f"2026-09-25 {realm['hour']:02d}:00:00",
        'finish': float('inf') if 'batch-hang' in contract else now + duration,
        'crash': now + 0.15 if 'lane-crash' in contract and accelerated else float('inf'),
        'passed': 'batch-fail' not in contract and 'always-fail' not in contract
        and not ('accelerated-fail' in contract and accelerated)}


def report(scenario, run_id, passed, extra):
    steps = []
    for index, step in enumerate(scenario['steps']):
        record = {'index': str(index), 'action': step['action'], 'status': 'completed'}
        if step['action'] == 'assert':
            record.update(status='passed', actual=str(step.get('equals', step.get('min', step.get('max')))))
        elif step['action'] == 'snapshot':
            record['actual'] = '20'
        steps.append(record)
    return {'schema': '1', 'run_id': run_id, 'scenario': scenario['name'],
            'execution': 'socketless-session-handlers', 'status': 'passed' if passed else 'failed',
            'message': 'All assertions passed' if passed else 'Fake native failure',
            'assertions': str(sum(step['action'] == 'assert' for step in scenario['steps'])),
            'completed_steps': str(len(steps)), 'steps': steps, **extra}


def shut_down(code):
    for lane, item in running.items():
        settling = 'settling' in item['scenario'].get('contract', '')
        extra = {'batch_id': run_id, 'sequence': str(item['sequence']),
                 'message': TEARDOWN_SHUTDOWN if settling else SCENARIO_SHUTDOWN,
                 **measures(item, lane, time.monotonic() - item['admitted'])}
        write(item['case']['result_file'], report(item['scenario'], item['case']['run_id'], False, extra))
    os._exit(code)


threading.Thread(target=listen, daemon=True).start()
config = run.read_config(sys.argv[sys.argv.index('-c') + 1])
run_id = config['CoAGameplayTest.RunId']
start = config['CoAGameplayTest.StartFile']
cases = config['CoAGameplayTest.CaseDirectory']
clock = config['CoAGameplayTest.Clock']
lanes = int(config['CoAGameplayTest.Lanes'])
simulated = clock == 'simulated'
start_hour = int(config['CoAGameplayTest.StartHour'])
realm = {'hour': start_hour}
starts = Path(__file__).with_name('starts.log')
with open(starts, 'a') as stream:
    stream.write(f"{'queue' if cases else 'single'} {os.getpid()}\n")
log('clocks.log', {'mode': 'queue' if cases else 'single',
                   **{name: config[f'CoAGameplayTest.{name}'] for name in run.CLOCK_SETTINGS}})
log('databases.log', {'mode': 'queue' if cases else 'single', **{key: config[key] for key in DATABASE_KEYS}})
log('timezones.log', {'mode': 'queue' if cases else 'single', 'TZ': os.environ.get('TZ')})
if cases and (config['CoAGameplayTest.ScenarioFile'] or config['CoAGameplayTest.ResultFile']):
    sys.exit(6)
if clock not in ('real', 'simulated') or not 1 <= lanes <= 15 or lanes > 1 and not simulated \
        or simulated and not cases:
    sys.exit(9)
if cases and '--queue-limit' in sys.argv:
    queue_starts = [line for line in starts.read_text().splitlines() if line.startswith('queue')]
    if len(queue_starts) > int(sys.argv[sys.argv.index('--queue-limit') + 1]):
        sys.exit(1)
ready = {'run_id': run_id, 'status': 'ready', 'waiting_for_start': 'true' if start else 'false'}
if cases:
    ready['mode'] = 'queue'
    if '--without-lanes' not in sys.argv:
        ready.update(clock=clock, lanes=str(lanes))
    if simulated and '--without-start-hour' not in sys.argv:
        ready['start_hour'] = str(realm['hour'])
    if '--without-database-settings' not in sys.argv:
        ready.update(character_db_workers=config['CharacterDatabase.WorkerThreads'],
                     character_db_isolation=config['CharacterDatabase.TransactionIsolation'] or 'REPEATABLE-READ')
write(config['CoAGameplayTest.ReadyFile'], ready)
if start:
    while not Path(start).exists():
        time.sleep(0.01)
    if json.loads(Path(start).read_text())['run_id'] != run_id:
        sys.exit(7)
if not cases:
    scenario = json.loads(Path(config['CoAGameplayTest.ScenarioFile']).read_text())
    passed = 'always-fail' not in scenario.get('contract', '')
    write(config['CoAGameplayTest.ResultFile'],
          report(scenario, run_id, passed, {'realm_local_start': time.strftime('%Y-%m-%d %H:%M:%S')}))
    sys.exit(0)
sequence = 0
used = {run_id}
running = {}
pending = None
idle_since = time.monotonic()
while True:
    now = time.monotonic()
    for lane in sorted(running):
        item = running[lane]
        if now >= item['crash']:
            crash()
        if now >= item['finish']:
            del running[lane]
            extra = {'batch_id': run_id, 'sequence': str(item['sequence']),
                     **measures(item, lane, now - item['admitted'])}
            write(item['case']['result_file'], report(item['scenario'], item['case']['run_id'], item['passed'], extra))
            if 'teardown-abort' in item['scenario'].get('contract', ''):
                shut_down(1)
    while True:
        if pending is None:
            pending = read_case(sequence)
            if pending is None:
                break
            sequence += 1
        if pending.get('stop'):
            if running:
                break
            sys.exit(0)
        exclusive = pending.get('exclusive') is True
        if len(running) >= lanes or any(item['exclusive'] for item in running.values()) or exclusive and running:
            break
        admit(pending, sequence - 1)
        pending = None
    if running or pending is not None:
        idle_since = now
    elif now - idle_since > 30:
        sys.exit(4)
    time.sleep(0.01)
'''
CHECKER = '''import json, sys
from pathlib import Path
for folder in sys.argv[1:3]:
    report = json.loads((Path(folder) / 'result.json').read_text())
    assert report['status'] == 'passed' and report['steps'][0]['actual'] == '20', folder
'''


def scenario(name, contract='', wait=0, timeout_ms=None, snapshot=False, hour=None):
    steps = [{'action': 'wait', 'ms': wait}] if wait else []
    if snapshot:
        steps.append({'action': 'snapshot', 'actor': 'caster', 'metric': 'health', 'save_as': 'healed'})
    steps.append({'action': 'assert', 'actor': 'caster', 'metric': 'health', 'min': 1})
    result = {'schema': 1, 'name': name, 'contract': contract,
              'players': [{'id': 'caster', 'race': 1, 'class': 8}], 'steps': steps}
    if timeout_ms:
        result['timeout_ms'] = timeout_ms
    if hour is not None:
        result['hour'] = hour
    return result


SCENARIOS = {
    'alpha': scenario('Alpha'),
    'beta': scenario('Beta', wait=200),
    'slow-one': scenario('Slow one', 'slow'),
    'slow-two': scenario('Slow two', 'slow'),
    'slow-three': scenario('Slow three', 'slow'),
    'slow-four': scenario('Slow four', 'slow'),
    'pair-one': scenario('Pair one', snapshot=True),
    'pair-two': scenario('Pair two', snapshot=True),
    'flaky': scenario('Flaky', 'batch-fail'),
    'broken': scenario('Broken', 'always-fail'),
    'crash': scenario('Crash', 'batch-crash', wait=1000),
    'late-crash': scenario('Late crash', 'batch-crash'),
    'aborter': scenario('Aborter', 'teardown-abort', wait=500),
    'lane-aborter': scenario('Lane aborter', 'midway teardown-abort', wait=500),
    'slow-aborter': scenario('Slow aborter', 'slow teardown-abort', wait=500),
    'settler': scenario('Settler', 'slow settling', wait=300),
    'hang': scenario('Hang', 'batch-hang', wait=900, timeout_ms=1000),
    'jittery': scenario('Jittery', 'accelerated-fail'),
    'lane-crash': scenario('Lane crash', 'slow lane-crash', wait=1000),
    'linger': scenario('Linger', 'linger', wait=5000),
    'brief': scenario('Brief', timeout_ms=100),
    'noon': scenario('Noon', wait=100, hour=12),
    'dusk': scenario('Dusk', 'batch-fail', hour=18),
    'midnight': scenario('Midnight', 'always-fail', hour=0),
}
SLOW = ['slow-one', 'slow-two', 'slow-three', 'slow-four']
POLICY = {'schema': 1, 'exclusive': {'alpha': 'The fake worldserver treats alpha as process-global'}}
DEFAULT_DATABASES = {'LoginDatabase.WorkerThreads': '1', 'CharacterDatabase.WorkerThreads': '1',
                     'LoginDatabase.TransactionIsolation': '', 'CharacterDatabase.TransactionIsolation': '',
                     'WorldDatabase.TransactionIsolation': ''}
SHIPPED_EXCLUSIVE = {'bloodforged-high-risk-drop', 'coa-prestige-chromie-spawns', 'who-custom-classes',
                     'who-hides-bots', 'who-lists-bots', 'wildcard-season-event',
                     'native-fixture-descendant-cleanup-producer', 'native-fixture-descendant-cleanup-consumer',
                     'vanilla-dungeons-normal', 'vanilla-dungeons-heroic', 'vanilla-dungeons-mythic',
                     'vanilla-dungeons-health', 'mythic-plus-keystone-run', 'mythic-plus-client-data-at-login',
                     'test-zone-bonus-command', 'test-zone-bonus-westfall', 'void-portal-capture',
                     'path-to-ascension-arena-solo-queue-tutorial'}
UTC_EVENING = datetime(2026, 9, 24, 22, 40, tzinfo=timezone.utc)


class FakeCache:
    instances = []

    def __init__(self, database, root, inputs, result_directory=None):
        self.database = database
        self.root = root
        self.inputs = inputs
        self.metadata = {'world_id': secrets.token_hex(6)}
        self.info = {'mode': 'reused', 'retained': False, 'directory': str(root)}
        self.refresh = None
        self.released = False
        FakeCache.instances.append(self)

    def prepare(self, refresh=False):
        self.refresh = refresh
        self.info['mode'] = 'refreshed' if refresh else 'reused'
        self.database.names['world'] = f"coa_test_{self.metadata['world_id']}_world"

    def ready(self, record, start_file, run_id):
        run.require(record.get('waiting_for_start') in (True, 'true'), 'Missing startup barrier')
        write_json(start_file, {'run_id': run_id})
        self.released = True

    def finish(self, server_still_running=False):
        self.info['retained'] = not server_still_running


class BatchTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.path = Path(temporary.name).resolve()
        self.definitions = self.path / 'definitions'
        (self.definitions / 'scenarios').mkdir(parents=True)
        for key, definition in SCENARIOS.items():
            self.write(self.definitions / 'scenarios' / f'{key}.json', definition)
        self.write(self.definitions / 'checks.json', {'schema': 1, 'checks': [
            {'script': 'check_pair.py', 'scenarios': ['pair-one', 'pair-two'], 'args': []}]})
        (self.definitions / 'check_pair.py').write_text(CHECKER, encoding='utf-8')
        self.write(self.definitions / batch.POLICY_FILE, POLICY)
        self.fake = self.path / 'fake_worldserver.py'
        self.fake.write_text(FAKE_SERVER, encoding='utf-8')
        self.worldserver = self.path / 'bin' / 'worldserver'
        self.worldserver.parent.mkdir()
        self.worldserver.write_bytes(b'binary')
        self.config = self.path / 'etc' / 'worldserver.conf'
        (self.config.parent / 'modules').mkdir(parents=True)
        self.config.write_text(''.join(f'{key} = "127.0.0.1;3306;user;secret-password;source_{role}"\n'
                                       for role, key in run.DATABASE_SETTINGS.items()), encoding='utf-8')
        (self.config.parent / 'modules' / 'example.conf').write_text('Example.Enable = 1\n', encoding='utf-8')
        self.server_modules = self.path / 'server-modules'
        self.server_modules.mkdir()
        self.tools = {name: self.path / 'bin' / name for name in ('mysql', 'mysqldump')}
        for path in self.tools.values():
            path.write_bytes(b'')
        self.output = self.path / 'output'
        self.command = lambda config: [sys.executable, str(self.fake), str(DIRECTORY), '-c', str(config)]
        self.cleanup_result = []
        FakeCache.instances = []
        stack = ExitStack()
        self.addCleanup(stack.close)
        stack.enter_context(patch.object(run, 'server_command', lambda binary, config: self.command(config)))
        stack.enter_context(patch.object(run.Databases, 'prepare', lambda database, roles=(): None))
        stack.enter_context(patch.object(run.Databases, 'cleanup', lambda database: list(self.cleanup_result)))
        stack.enter_context(patch.object(run, 'input_fingerprint', return_value='inputs'))
        stack.enter_context(patch.object(batch, 'CASE_GRACE_SECONDS', 0.5))

    def write(self, path, value):
        path.write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8')

    def batch(self, *arguments):
        argv = ['--worldserver', str(self.worldserver), '--config', str(self.config),
                '--mysql', str(self.tools['mysql']), '--mysqldump', str(self.tools['mysqldump']),
                '--server-modules-dir', str(self.server_modules), '--output', str(self.output),
                '--startup-timeout', '20', '--world-cache-root', str(self.path / 'cache'), *arguments]
        self.stdout, self.stderr = io.StringIO(), io.StringIO()
        with redirect_stdout(self.stdout), redirect_stderr(self.stderr):
            code = batch.main(argv, directory=self.definitions)
        report = self.output / 'gameplay.json'
        return code, catalog.read_json(report) if report.exists() else None

    def summary(self, key, folder='cases'):
        return catalog.read_json(self.output / folder / key / 'summary.json')

    def starts(self):
        log = self.path / 'starts.log'
        return [line.split() for line in log.read_text().splitlines()] if log.exists() else []

    def events(self, name):
        log = self.path / name
        return [json.loads(line) for line in log.read_text().splitlines()] if log.exists() else []

    def simulated(self, *arguments):
        return self.batch('--fresh-databases', '--clock', 'simulated', *arguments)

    def test_cases_pass_across_two_workers_with_verifiable_bundles(self):
        code, result = self.batch('--fresh-databases', '--jobs', '2', '--scenario', *SLOW, 'alpha')
        self.assertEqual(code, 0, self.stderr.getvalue())
        self.assertEqual(result['status'], 'passed')
        self.assertEqual(result['counts'], {'passed': 5, 'failed': 0, 'not_run': 0, 'passed_on_isolated_rerun': 0})
        self.assertEqual(result['selected'], sorted([*SLOW, 'alpha']))
        self.assertEqual(result['verification']['status'], 'passed')
        slots, run_ids = set(), set()
        for key in [*SLOW, 'alpha']:
            summary = self.summary(key)
            report = catalog.read_json(self.output / 'cases' / key / 'result.json')
            self.assertEqual(summary['run_id'], report['run_id'])
            self.assertEqual(report['batch_id'], summary['batch']['id'])
            self.assertNotEqual(summary['run_id'], summary['batch']['id'])
            self.assertEqual(summary['world_cache'], {'mode': 'fresh', 'retained': False})
            self.assertEqual(result['cases'][key]['mode'], 'batch')
            slots.add(summary['batch']['slot'])
            run_ids.add(summary['run_id'])
        self.assertEqual(slots, {0, 1})
        self.assertEqual(len(run_ids), 5)
        direct = verification.verify([self.output / 'cases' / key for key in [*SLOW, 'alpha']], self.definitions)
        self.assertEqual(direct['status'], 'passed')
        self.assertEqual({server['status'] for server in result['servers']}, {'stopped'})
        self.assertEqual((result['clock'], result['lanes'], result['acceleration_sensitive']), ('real', 1, []))
        self.assertFalse({'simulation', 'game_elapsed_ms', 'real_elapsed_ms'} & result.keys())
        self.assertNotIn('simulation', self.summary('alpha'))
        self.assertEqual({(entry['Clock'], entry['Lanes']) for entry in self.events('clocks.log')}, {('real', '1')})
        self.assertTrue(self.events('databases.log'))
        self.assertTrue(all(entry == {'mode': 'queue', **DEFAULT_DATABASES} for entry in self.events('databases.log')))
        admissions = self.events('lanes.log')
        self.assertEqual(len(admissions), 5)
        self.assertTrue(all(event['running'] == [] and not event['exclusive'] and event['pace'] == 'accelerated'
                            for event in admissions))
        lines = self.stdout.getvalue().splitlines()
        self.assertEqual(sum(line.startswith('PASS ') for line in lines), 5)
        self.assertTrue(lines[-1].startswith('GAMEPLAY PASSED: 5 passed, 0 failed, 0 not run, 0 batch-sensitive'))
        self.assertTrue(lines[-1].endswith(str(self.output / 'gameplay.json')))
        for path in self.output.rglob('*'):
            if path.is_file():
                self.assertNotIn('secret-password', path.read_text(encoding='utf-8', errors='replace'))

    def test_failing_case_does_not_stop_the_batch(self):
        code, result = self.batch('--fresh-databases', '--no-isolated-rerun', '--scenario', 'alpha', 'broken', 'beta')
        self.assertEqual(code, 1)
        self.assertEqual(result['status'], 'failed')
        self.assertEqual({key: case['status'] for key, case in result['cases'].items()},
                         {'alpha': 'passed', 'beta': 'passed', 'broken': 'failed'})
        self.assertIn('Fake native failure', result['cases']['broken']['message'])
        self.assertEqual([server['status'] for server in result['servers']], ['stopped'])
        self.assertEqual(result['servers'][0]['case_count'], 3)
        self.assertEqual(result['verification']['status'], 'failed')
        self.assertIn('FAIL broken', self.stdout.getvalue())

    def test_crash_mid_case_fails_that_case_and_restarts_the_server(self):
        code, result = self.batch('--fresh-databases', '--no-isolated-rerun', '--scenario', 'crash', 'alpha', 'beta')
        self.assertEqual(code, 1)
        self.assertEqual(result['cases']['crash']['status'], 'failed')
        self.assertIn('before returning the case result', result['cases']['crash']['message'])
        self.assertEqual(result['cases']['alpha']['status'], 'passed')
        self.assertEqual(result['cases']['beta']['status'], 'passed')
        self.assertEqual([server['status'] for server in result['servers']], ['failed', 'stopped'])
        self.assertTrue(self.summary('alpha')['batch']['server_directory'].endswith('slot-0-2'))
        self.assertEqual(result['failures'], [])
        self.assertEqual(self.summary('crash')['status'], 'failed')

    def test_case_timeout_kills_the_server_and_restarts(self):
        code, result = self.batch('--fresh-databases', '--no-isolated-rerun', '--scenario', 'hang', 'alpha')
        self.assertEqual(code, 1)
        self.assertIn('timed out', result['cases']['hang']['message'])
        self.assertEqual(result['cases']['alpha']['status'], 'passed')
        self.assertEqual(len(result['servers']), 2)
        self.assertEqual(result['servers'][0]['exit_code'], 0)
        self.assertEqual([mode for mode, pid in self.starts()], ['queue', 'queue'])

    def test_companions_are_expanded_and_checked(self):
        code, result = self.batch('--fresh-databases', '--scenario', 'pair-one')
        self.assertEqual(code, 0, self.stderr.getvalue())
        self.assertEqual(result['selected'], ['pair-one', 'pair-two'])
        self.assertEqual(result['verification']['checks'], [
            {'script': 'check_pair.py', 'scenarios': ['pair-one', 'pair-two'], 'args': [], 'status': 'passed'}])
        combined = catalog.read_json(self.output / 'verification.json')
        self.assertEqual(combined['scenarios'], ['pair-one', 'pair-two'])

    def test_paths_resolve_to_catalog_ids_or_exploratory_cases(self):
        exact = self.path / 'copy.json'
        self.write(exact, SCENARIOS['alpha'])
        probe = self.path / 'My Probe.json'
        self.write(probe, {**SCENARIOS['alpha'], 'contract': 'A new measurement'})
        code, result = self.batch('--fresh-databases', '--scenario', str(exact), str(probe), str(probe))
        self.assertEqual(code, 0, self.stderr.getvalue())
        self.assertEqual(result['selected'], ['alpha'])
        self.assertEqual(result['exploratory'], ['my-probe'])
        self.assertEqual(list(result['cases']), ['alpha'])
        self.assertEqual(result['exploratory_results']['my-probe']['status'], 'passed')
        self.assertEqual(result['exploratory_results']['my-probe']['path'], str(probe.resolve()))
        self.assertEqual(self.summary('my-probe', 'exploratory')['status'], 'passed')
        self.assertEqual(catalog.read_json(self.output / 'verification.json')['scenarios'], ['alpha'])
        self.assertIn('PASS exploratory:my-probe', self.stdout.getvalue())

    def test_exploratory_only_run_is_not_combined_verification(self):
        probe = self.path / 'probe.json'
        self.write(probe, {**SCENARIOS['beta'], 'contract': 'Exploratory only'})
        code, result = self.batch('--fresh-databases', '--scenario', str(probe))
        self.assertEqual(code, 3, self.stderr.getvalue())
        self.assertEqual(result['status'], 'exploratory')
        self.assertEqual(result['exploratory_results']['probe']['status'], 'passed')
        self.assertEqual(result['scope'], batch.EXPLORATORY_SCOPE)
        self.assertEqual(result['verification']['status'], 'skipped')
        self.assertFalse((self.output / 'verification.json').exists())
        final = self.stdout.getvalue().splitlines()[-1]
        self.assertTrue(final.startswith('GAMEPLAY EXPLORATORY: 1 passed'))
        self.assertIn('exploratory native execution only', final)
        self.assertNotIn('verification passed', final)

    def test_failed_exploratory_only_run_fails(self):
        probe = self.path / 'probe.json'
        self.write(probe, {**SCENARIOS['broken'], 'contract': 'always-fail probe'})
        code, result = self.batch('--fresh-databases', '--scenario', str(probe))
        self.assertEqual(code, 1)
        self.assertEqual(result['status'], 'failed')

    def test_invalid_selection_fails_before_any_server_starts(self):
        invalid = self.path / 'invalid.json'
        self.write(invalid, {**SCENARIOS['alpha'], 'steps': [{'action': 'wait', 'ms': 1}]})
        for selection in (['alpha', str(invalid)], ['missing-scenario']):
            with self.subTest(selection=selection):
                code, result = self.batch('--fresh-databases', '--scenario', *selection)
                self.assertEqual(code, 1)
                self.assertIsNone(result)
                self.assertIn('ERROR', self.stderr.getvalue())
        self.assertEqual(self.starts(), [])
        self.assertFalse(self.output.exists())

    def test_isolated_rerun_marks_batch_sensitive_and_stages_modules_once(self):
        with patch.object(run, 'stage_modules', wraps=run.stage_modules) as staged:
            code, result = self.batch('--fresh-databases', '--jobs', '2', '--scenario', 'flaky', *SLOW[:2])
        self.assertEqual(code, 0, self.stderr.getvalue())
        self.assertEqual(staged.call_count, 1)
        self.assertEqual(list(self.server_modules.iterdir()), [])
        self.assertEqual(result['batch_sensitive'], ['flaky'])
        self.assertEqual(result['isolated_only'], [])
        self.assertEqual(result['counts']['passed_on_isolated_rerun'], 1)
        self.assertEqual(result['failures'], [])
        flaky = result['cases']['flaky']
        self.assertEqual((flaky['status'], flaky['mode'], flaky['batch']['status']), ('passed', 'isolated', 'failed'))
        isolated = self.summary('flaky', 'isolated')
        self.assertEqual(isolated['module_config_sha256'], self.summary('slow-one')['module_config_sha256'])
        self.assertEqual(list(isolated['module_config_sha256']), ['example.conf'])
        evidence = catalog.read_json(self.output / 'verification.json')['evidence']
        self.assertEqual(evidence['flaky']['directory'], str(self.output / 'isolated' / 'flaky'))
        self.assertEqual([mode for mode, pid in self.starts()].count('single'), 1)
        self.assertEqual({(entry['mode'], entry['Clock'], entry['Lanes']) for entry in self.events('clocks.log')},
                         {('queue', 'real', '1'), ('single', 'real', '1')})
        self.assertIn('PASS flaky', self.stdout.getvalue())

    def test_failed_isolated_rerun_keeps_the_case_failed(self):
        code, result = self.batch('--fresh-databases', '--scenario', 'broken', 'alpha')
        self.assertEqual(code, 1)
        broken = result['cases']['broken']
        self.assertEqual((broken['status'], broken['mode'], broken['isolated']['status']),
                         ('failed', 'batch', 'failed'))
        self.assertEqual(result['batch_sensitive'], [])

    def test_repeated_server_failures_leave_cases_not_run(self):
        self.command = lambda config: [sys.executable, '-c', 'raise SystemExit(7)']
        code, result = self.batch('--fresh-databases', '--no-isolated-rerun', '--scenario', 'alpha', 'beta')
        self.assertEqual(code, 1)
        self.assertEqual({case['status'] for case in result['cases'].values()}, {'not_run'})
        self.assertEqual(result['counts']['not_run'], 2)
        self.assertEqual(len(result['servers']), batch.SERVER_FAILURE_LIMIT)
        self.assertIn('exited with code 7 before readiness', result['servers'][0]['message'])
        self.assertIn('SLOT 0 STOPPED', self.stdout.getvalue())
        self.assertEqual(result['failures'], [
            f'slot-0 stopped after {batch.SERVER_FAILURE_LIMIT} consecutive worldserver failures without a '
            'completed case', 'No queue-mode worldserver became ready'])

    def test_cleanup_failure_fails_every_case_of_that_server(self):
        self.cleanup_result = ['coa_test_leftover_auth']
        code, result = self.batch('--fresh-databases', '--no-isolated-rerun', '--scenario', 'alpha', 'beta')
        self.assertEqual(code, 1)
        for key in ('alpha', 'beta'):
            summary = self.summary(key)
            self.assertEqual(summary['status'], 'failed')
            self.assertEqual(summary['cleanup_failed'], ['coa_test_leftover_auth'])
            self.assertEqual(result['cases'][key]['status'], 'failed')
        self.assertTrue(result['failures'])
        self.assertEqual(verification.verify([self.output / 'cases' / 'alpha'], self.definitions)['status'],
                         'failed')

    def test_workers_use_separate_world_cache_slots_behind_the_startup_barrier(self):
        with patch.object(run, 'WorldCache', FakeCache):
            code, result = self.batch('--refresh-world', '--jobs', '2', '--scenario', *SLOW)
        self.assertEqual(code, 0, self.stderr.getvalue())
        self.assertEqual({cache.root for cache in FakeCache.instances},
                         {(self.path / 'cache' / 'slot-0').resolve(), (self.path / 'cache' / 'slot-1').resolve()})
        self.assertTrue(all(cache.released and cache.refresh and cache.inputs == 'inputs'
                            for cache in FakeCache.instances))
        for key in SLOW:
            summary = self.summary(key)
            self.assertTrue(summary['world_cache']['retained'])
            self.assertTrue(summary['databases']['world'].startswith('coa_test_'))
            self.assertNotEqual(summary['databases']['world'], f"coa_test_{summary['batch']['id']}_world")

    @unittest.skipUnless(hasattr(signal, 'SIGTERM') and os.name != 'nt', 'Requires POSIX SIGTERM delivery')
    def test_sigterm_stops_servers_and_writes_a_failed_report(self):
        timer = threading.Timer(1.0, os.kill, (os.getpid(), signal.SIGTERM))
        timer.start()
        self.addCleanup(timer.cancel)
        code, result = self.batch('--fresh-databases', '--scenario', 'hang', 'alpha')
        self.assertEqual(code, 1)
        self.assertTrue(result['interrupted'])
        self.assertEqual(result['status'], 'failed')
        self.assertIn('INTERRUPTED', self.stdout.getvalue())
        self.assertEqual({server['status'] for server in result['servers']}, {'interrupted'})
        for mode, pid in self.starts():
            with self.assertRaises(ProcessLookupError):
                os.kill(int(pid), 0)

    def test_exit_after_a_result_fails_the_batch_and_runs_the_next_case_on_a_new_server(self):
        code, result = self.batch('--fresh-databases', '--scenario', 'aborter', 'alpha')
        self.assertEqual(code, 1)
        self.assertEqual(result['status'], 'failed')
        self.assertEqual({key: (case['status'], case['mode']) for key, case in result['cases'].items()},
                         {'aborter': ('passed', 'batch'), 'alpha': ('passed', 'batch')})
        self.assertEqual(result['batch_sensitive'], [])
        self.assertEqual(len(result['failures']), 1)
        failure = result['failures'][0]
        self.assertTrue(failure.startswith('slot-0-1: Worldserver exited with code 1'), failure)
        self.assertIn('teardown', failure)
        self.assertIn('case 0 (aborter) returned the last result', failure)
        self.assertTrue(self.summary('alpha')['batch']['server_directory'].endswith('slot-0-2'))
        self.assertEqual([event['name'] for event in self.events('lanes.log')], ['Aborter', 'Alpha'])
        self.assertEqual([server['status'] for server in result['servers']], ['failed', 'stopped'])
        self.assertEqual([mode for mode, pid in self.starts()], ['queue', 'queue'])
        self.assertTrue(self.stdout.getvalue().splitlines()[-1].startswith('GAMEPLAY FAILED'))

    def test_crash_after_an_earlier_result_requeues_once_then_charges_the_case(self):
        code, result = self.batch('--fresh-databases', '--no-isolated-rerun', '--scenario', 'beta', 'late-crash')
        self.assertEqual(code, 1)
        self.assertEqual(result['cases']['beta']['status'], 'passed')
        late = result['cases']['late-crash']
        self.assertEqual((late['status'], late['server']), ('failed', 'slot-0-2'))
        self.assertIn('before returning the case result', late['message'])
        self.assertEqual(len(result['failures']), 1)
        self.assertIn('case 0 (beta) had already returned its result', result['failures'][0])
        self.assertEqual([server['status'] for server in result['servers']], ['failed', 'failed'])

    def test_queue_startup_failure_fails_fast_without_isolated_reruns(self):
        command = self.command
        self.command = lambda config: [*command(config), '--queue-limit', '0']
        code, result = self.batch('--fresh-databases', '--scenario', 'alpha', 'beta')
        self.assertEqual(code, 1)
        self.assertEqual(result['status'], 'failed')
        self.assertEqual({case['status'] for case in result['cases'].values()}, {'not_run'})
        self.assertEqual((result['batch_sensitive'], result['isolated_only']), ([], []))
        self.assertIn('No queue-mode worldserver became ready', result['failures'])
        self.assertEqual([mode for mode, pid in self.starts()], ['queue'] * batch.SERVER_FAILURE_LIMIT)
        self.assertTrue(result['scope'].startswith('no native execution'))
        self.assertEqual({server['status'] for server in result['servers']}, {'failed'})

    def test_unrun_case_passing_in_isolation_is_not_batch_sensitive(self):
        command = self.command
        self.command = lambda config: [*command(config), '--queue-limit', '1']
        code, result = self.batch('--fresh-databases', '--scenario', 'crash', 'alpha')
        self.assertEqual(code, 1)
        self.assertEqual(result['status'], 'failed')
        self.assertEqual(result['batch_sensitive'], ['crash'])
        self.assertEqual(result['isolated_only'], ['alpha'])
        self.assertEqual(result['counts']['passed_on_isolated_rerun'], 2)
        self.assertEqual(result['cases']['alpha']['batch']['status'], 'not_run')
        self.assertTrue(any(failure.startswith('slot-0 stopped') for failure in result['failures']))
        self.assertEqual(result['scope'], batch.SCOPE.format('queue-mode native execution and isolated '
                                                             'single-mode reruns'))
        self.assertIn('1 batch-sensitive, 1 isolated-only', self.stdout.getvalue().splitlines()[-1])

    @unittest.skipUnless(hasattr(signal, 'SIGTERM') and os.name != 'nt', 'Requires POSIX SIGTERM delivery')
    def test_signal_while_workers_start_joins_them_before_cleanup(self):
        thread = batch.Batch.thread

        def signalling_thread(instance, target, slot):
            if slot == 1:
                os.kill(os.getpid(), signal.SIGTERM)
            return thread(instance, target, slot)

        handler = signal.getsignal(signal.SIGTERM)
        with patch.object(batch.Batch, 'thread', signalling_thread):
            code, result = self.batch('--fresh-databases', '--jobs', '3', '--scenario', *SLOW[:3])
        self.assertEqual(code, 1)
        self.assertTrue(result['interrupted'])
        self.assertEqual(result['status'], 'failed')
        self.assertFalse([item for item in threading.enumerate() if item.name.startswith('coa-gameplay-slot')])
        self.assertFalse(list((self.output / 'servers').glob('slot-2-*')))
        self.assertEqual(list(self.server_modules.iterdir()), [])
        self.assertEqual(signal.getsignal(signal.SIGTERM), handler)
        for mode, pid in self.starts():
            with self.assertRaises(ProcessLookupError):
                os.kill(int(pid), 0)

    def test_every_external_stop_signal_interrupts_the_runner_and_is_restored(self):
        numbers = tuple(getattr(signal, name) for name in ('SIGTERM', 'SIGUSR1') if hasattr(signal, name))
        before = {number: signal.getsignal(number) for number in numbers}
        during = {}

        def run_batch(args, directory):
            during.update({number: signal.getsignal(number) for number in numbers})
            return {'status': 'passed'}

        with patch.object(batch, 'EXTERNAL_STOP_SIGNALS', numbers), patch.object(batch, 'run_batch', run_batch):
            code, _ = self.batch('--fresh-databases')
        self.assertEqual(code, 0)
        self.assertEqual(during, {number: batch.interrupt for number in numbers})
        self.assertEqual({number: signal.getsignal(number) for number in numbers}, before)
        self.assertNotIn(signal.SIGINT, batch.EXTERNAL_STOP_SIGNALS)
        if hasattr(signal, 'SIGBREAK'):
            self.assertIn(signal.SIGBREAK, batch.EXTERNAL_STOP_SIGNALS)

    @unittest.skipUnless(hasattr(signal, 'SIGTERM') and os.name != 'nt', 'Requires POSIX SIGTERM delivery')
    def test_stop_during_database_preparation_starts_no_worldserver(self):
        def prepare(database, roles=()):
            os.kill(os.getpid(), signal.SIGTERM)
            time.sleep(0.6)

        with patch.object(run.Databases, 'prepare', prepare), \
                patch.object(run, 'start_server', wraps=run.start_server) as start:
            code, result = self.batch('--fresh-databases', '--scenario', 'alpha')
        self.assertEqual(code, 1)
        self.assertEqual(start.call_count, 0)
        self.assertTrue(result['interrupted'])
        self.assertEqual([server['status'] for server in result['servers']], ['interrupted'])
        self.assertEqual(result['cases']['alpha']['status'], 'not_run')

    def test_binary_change_during_the_batch_stops_new_servers_and_fails(self):
        calls = []

        def prepare(database, roles=()):
            calls.append(roles)
            if len(calls) == 2:
                self.worldserver.write_bytes(b'rebuilt')

        with patch.object(run.Databases, 'prepare', prepare):
            code, result = self.batch('--fresh-databases', '--scenario', 'crash', 'alpha')
        self.assertEqual(code, 1)
        self.assertEqual(result['binary_sha256'], hashlib.sha256(b'binary').hexdigest())
        self.assertEqual(self.summary('crash')['binary_sha256'], result['binary_sha256'])
        self.assertEqual(result['cases']['alpha']['status'], 'not_run')
        self.assertTrue(any('binary changed after the batch started' in failure for failure in result['failures']))
        self.assertIn('Isolated reruns were skipped: the worldserver binary changed during the batch',
                      result['failures'])
        self.assertEqual([mode for mode, pid in self.starts()], ['queue'])
        self.assertEqual(result['servers'][1]['binary_sha256'], hashlib.sha256(b'rebuilt').hexdigest())

    def test_refresh_world_is_kept_until_a_slot_is_refreshed(self):
        class FirstCacheFails(FakeCache):
            failed = False

            def __init__(self, *args, **kwargs):
                if not FirstCacheFails.failed:
                    FirstCacheFails.failed = True
                    raise ValueError('World cache server identity is not a complete MySQL UUID')
                super().__init__(*args, **kwargs)

        with patch.object(run, 'WorldCache', FirstCacheFails):
            code, result = self.batch('--refresh-world', '--no-isolated-rerun', '--scenario', 'crash', 'alpha')
        self.assertEqual(code, 1)
        self.assertEqual([cache.refresh for cache in FakeCache.instances], [True, False])
        self.assertEqual(result['cases']['alpha']['status'], 'passed')
        self.assertEqual(self.summary('alpha')['world_cache']['mode'], 'reused')

    def test_harness_overrides_cover_every_reserved_setting(self):
        connections = {role: run.Connection('127.0.0.1', 3306, 'user', 'secret', f'source_{role}')
                       for role in run.DATABASE_SETTINGS}
        names = {role: f'coa_test_012345abcdef_{role}' for role in run.DATABASE_SETTINGS}
        private = self.path / 'private'
        files = {'ready': self.path / 'ready.json', 'cases': self.path / 'cases'}
        overrides = run.harness_overrides(connections, names, self.path, self.path, private, '012345abcdef',
                                          '012345abcdef', files)
        self.assertEqual(set(overrides), run.reserved_settings())
        self.assertEqual({key: str(overrides[key]) for key in DEFAULT_DATABASES}, DEFAULT_DATABASES)
        tuned = batch.database_settings(SimpleNamespace(clock=batch.SIMULATED_CLOCK, character_db_workers=6))
        self.assertLessEqual(set(tuned), run.reserved_settings())
        self.assertEqual(batch.database_settings(SimpleNamespace(clock=batch.REAL_CLOCK, character_db_workers=1)), {})
        self.assertEqual(tuned, {'CharacterDatabase.WorkerThreads': 6,
                                 'CharacterDatabase.TransactionIsolation': 'READ-COMMITTED'})
        self.assertEqual(overrides['TempDir'], private.as_posix())
        self.assertEqual(overrides['CoAGameplayTest.ScenarioFile'], '')
        self.assertEqual(overrides['CoAGameplayTest.CaseDirectory'], (self.path / 'cases').as_posix())
        self.assertEqual({name: overrides[f'CoAGameplayTest.{name}'] for name in run.CLOCK_SETTINGS},
                         {'Clock': 'real', 'Lanes': 1, 'StepMs': 3, 'ActiveWaitCapMs': 25, 'PollCapMs': 10,
                          'StartHour': 10})
        lanes = run.harness_overrides(connections, names, self.path, self.path, private, '012345abcdef',
                                      '012345abcdef', files, {'Clock': 'simulated', 'Lanes': 4, 'StartHour': 3})
        self.assertEqual([lanes[f'CoAGameplayTest.{name}'] for name in ('Clock', 'Lanes', 'StepMs', 'StartHour')],
                         ['simulated', 4, 3, 3])
        with self.assertRaisesRegex(ValueError, 'Unknown harness files'):
            run.harness_overrides(connections, names, self.path, self.path, private, '012345abcdef', '012345abcdef',
                                  {'other': self.path})
        with self.assertRaisesRegex(ValueError, 'Unknown clock settings'):
            run.harness_overrides(connections, names, self.path, self.path, private, '012345abcdef', '012345abcdef',
                                  {}, {'Speed': 2})

    def test_queue_orders_longest_estimated_cases_first(self):
        cases = batch.select_cases(['alpha', 'beta', 'crash', 'hang'], self.definitions)
        self.assertEqual([case.key for case in batch.longest_first(cases)], ['crash', 'hang', 'beta', 'alpha'])
        cases[0].exclusive = True
        self.assertEqual([case.key for case in batch.longest_first(cases)], ['alpha', 'crash', 'hang', 'beta'])

    def test_simulated_lanes_run_cases_concurrently_with_write_ahead(self):
        code, result = self.simulated('--lanes', '2', '--scenario', *SLOW, 'beta')
        self.assertEqual(code, 0, self.stderr.getvalue())
        self.assertEqual((result['status'], result['clock'], result['lanes'], result['jobs']),
                         ('passed', 'simulated', 2, 1))
        self.assertEqual({case['mode'] for case in result['cases'].values()}, {'simulated'})
        self.assertEqual(result['verification']['status'], 'passed')
        self.assertEqual((result['acceleration_sensitive'], result['batch_sensitive']), ([], []))
        self.assertEqual(result['game_elapsed_ms'], 200)
        self.assertIs(type(result['real_elapsed_ms']), int)
        self.assertEqual(result['cases']['beta']['game_elapsed_ms'], 200)
        self.assertEqual(result['simulation'],
                         {'step_ms': 3, 'active_wait_cap_ms': 25, 'poll_cap_ms': 10, 'start_hour': 10,
                          'character_db_workers': batch.DEFAULT_CHARACTER_DB_WORKERS,
                          'character_db_isolation': 'READ-COMMITTED', 'exclusive': []})
        self.assertEqual(self.events('databases.log'),
                         [{'mode': 'queue', **DEFAULT_DATABASES,
                           'CharacterDatabase.WorkerThreads': str(batch.DEFAULT_CHARACTER_DB_WORKERS),
                           'CharacterDatabase.TransactionIsolation': 'READ-COMMITTED'}])
        self.assertTrue(result['scope'].startswith('simulated-clock queue-mode native execution (2 lanes'))
        self.assertEqual([mode for mode, pid in self.starts()], ['queue'])
        self.assertEqual(self.events('clocks.log'), [{'mode': 'queue', 'Clock': 'simulated', 'Lanes': '2',
                                                      'StepMs': '3', 'ActiveWaitCapMs': '25', 'PollCapMs': '10',
                                                      'StartHour': '10'}])
        self.assertEqual({case['realm_local_start'] for case in result['cases'].values()}, {'2026-09-25 10:00:00'})
        admissions = self.events('lanes.log')
        self.assertEqual(sorted(event['name'] for event in admissions),
                         sorted(SCENARIOS[key]['name'] for key in [*SLOW, 'beta']))
        self.assertTrue(any(event['running'] and event['ahead'] for event in admissions))
        self.assertTrue(all(len(event['running']) + 1 + event['ahead'] <= 4 for event in admissions))
        self.assertEqual({event['pace'] for event in admissions}, {'accelerated'})
        simulation = self.summary('slow-one')['simulation']
        self.assertEqual((simulation['lanes'], simulation['pace'], simulation['exclusive']), (2, 'accelerated', False))
        self.assertIn(simulation['lane'], (0, 1))
        self.assertIn('0 not run, 0 acceleration-sensitive, 0 batch-sensitive', self.stdout.getvalue())

    def test_simulated_clock_defaults_to_fifteen_lanes_without_isolated_reruns(self):
        code, result = self.simulated('--scenario', 'broken')
        self.assertEqual(code, 1)
        self.assertEqual(result['lanes'], 15)
        self.assertEqual([entry['Lanes'] for entry in self.events('clocks.log')], ['15'])
        self.assertEqual([mode for mode, pid in self.starts()], ['queue'])
        self.assertFalse((self.output / 'isolated').exists())

    def test_character_database_tuning_applies_to_the_simulated_clock_only(self):
        with self.config.open('a', encoding='utf-8') as source:
            source.write('CharacterDatabase.WorkerThreads = 6\n'
                         'CharacterDatabase.TransactionIsolation = "SERIALIZABLE"\n'
                         'LoginDatabase.TransactionIsolation = "READ-UNCOMMITTED"\n'
                         'WorldDatabase.TransactionIsolation = "READ-UNCOMMITTED"\n')
        code, result = self.simulated('--lanes', '2', '--character-db-workers', '8', '--scenario', 'beta')
        self.assertEqual(code, 0, self.stderr.getvalue())
        self.assertEqual((result['simulation']['character_db_workers'], result['simulation']['character_db_isolation']),
                         (8, 'READ-COMMITTED'))
        self.assertEqual(self.events('databases.log'),
                         [{'mode': 'queue', **DEFAULT_DATABASES, 'CharacterDatabase.WorkerThreads': '8',
                           'CharacterDatabase.TransactionIsolation': 'READ-COMMITTED'}])
        (self.path / 'databases.log').unlink()
        self.output = self.path / 'real-output'
        code, result = self.batch('--fresh-databases', '--character-db-workers', '1', '--scenario', 'broken')
        self.assertEqual(code, 1)
        self.assertEqual(result['cases']['broken']['status'], 'failed')
        self.assertNotIn('simulation', result)
        self.assertEqual(self.events('databases.log'), [{'mode': 'queue', **DEFAULT_DATABASES},
                                                        {'mode': 'single', **DEFAULT_DATABASES}])

    def test_character_database_workers_are_validated_per_clock(self):
        bounds = 'must be between 1 and 32'
        for arguments, message in [(['--character-db-workers', '2'], 'above 1 requires --clock simulated'),
                                   (['--clock', 'simulated', '--character-db-workers', '0'], bounds),
                                   (['--clock', 'simulated', '--character-db-workers', '33'], bounds)]:
            with self.subTest(arguments=arguments):
                code, result = self.batch('--scenario', 'beta', *arguments)
                self.assertEqual((code, result), (1, None))
                self.assertIn(f'--character-db-workers {message}', self.stderr.getvalue())
                self.assertEqual(self.starts(), [])
        resolved = {clock: batch.resolve_clock(batch.parser().parse_args(
            ['--worldserver', 'w', '--config', 'c', '--mysql', 'm', '--mysqldump', 'd', '--output', 'o',
             '--clock', clock])).character_db_workers for clock in (batch.REAL_CLOCK, batch.SIMULATED_CLOCK)}
        self.assertEqual(resolved, {batch.REAL_CLOCK: 1, batch.SIMULATED_CLOCK: batch.DEFAULT_CHARACTER_DB_WORKERS})

    def test_exclusive_cases_run_first_and_alone(self):
        code, result = self.simulated('--lanes', '3', '--scenario', 'alpha', *SLOW[:3])
        self.assertEqual(code, 0, self.stderr.getvalue())
        admissions = self.events('lanes.log')
        first = admissions[0]
        self.assertEqual((first['name'], first['sequence'], first['exclusive'], first['running']),
                         ('Alpha', 0, True, []))
        self.assertEqual([event['exclusive'] for event in admissions[1:]], [False] * 3)
        self.assertFalse(any('Alpha' in event['running'] for event in admissions))
        self.assertEqual(result['simulation']['exclusive'], ['alpha'])
        self.assertTrue(self.summary('alpha')['simulation']['exclusive'])

    def test_world_phase_cases_run_exclusively_without_a_policy_entry(self):
        world_phase = {**SCENARIOS['beta'], 'steps': [*SCENARIOS['beta']['steps'],
                       {'action': 'set_phase', 'actor': 'caster', 'value': 1}]}
        private_phase = {**SCENARIOS['slow-one'], 'steps': [*SCENARIOS['slow-one']['steps'],
                         {'action': 'set_phase', 'actor': 'caster', 'value': 2}]}
        self.write(self.definitions / 'scenarios' / 'beta.json', world_phase)
        self.write(self.definitions / 'scenarios' / 'slow-one.json', private_phase)
        code, result = self.simulated('--lanes', '3', '--scenario', 'beta', *SLOW[:3])
        self.assertEqual(code, 0, self.stderr.getvalue())
        admissions = self.events('lanes.log')
        self.assertEqual((admissions[0]['name'], admissions[0]['exclusive'], admissions[0]['running']),
                         ('Beta', True, []))
        self.assertFalse(any('Beta' in event['running'] for event in admissions))
        self.assertEqual([event['exclusive'] for event in admissions[1:]], [False] * 3)
        self.assertEqual(result['simulation']['exclusive'], ['beta'])
        self.assertTrue(self.summary('beta')['simulation']['exclusive'])

    def test_creature_scaling_cases_run_exclusively_without_a_policy_entry(self):
        self.write(self.definitions / 'scenarios' / 'beta.json', {**SCENARIOS['beta'], 'creature_scaling': True})
        code, result = self.simulated('--lanes', '3', '--scenario', 'beta', *SLOW[:3])
        self.assertEqual(code, 0, self.stderr.getvalue())
        admissions = self.events('lanes.log')
        self.assertEqual((admissions[0]['name'], admissions[0]['exclusive'], admissions[0]['running']),
                         ('Beta', True, []))
        self.assertEqual([event['exclusive'] for event in admissions[1:]], [False] * 3)
        self.assertEqual(result['simulation']['exclusive'], ['beta'])

    def test_vanity_ownership_cases_run_exclusively_without_a_policy_entry(self):
        self.write(self.definitions / 'scenarios' / 'beta.json',
                   {**SCENARIOS['beta'], 'vanity_ownership': {'unlock_all': False}})
        code, result = self.simulated('--lanes', '3', '--scenario', 'beta', *SLOW[:3])
        self.assertEqual(code, 0, self.stderr.getvalue())
        admissions = self.events('lanes.log')
        self.assertEqual((admissions[0]['name'], admissions[0]['exclusive'], admissions[0]['running']),
                         ('Beta', True, []))
        self.assertEqual([event['exclusive'] for event in admissions[1:]], [False] * 3)
        self.assertEqual(result['simulation']['exclusive'], ['beta'])

    def test_two_side_cases_run_exclusively_without_a_policy_entry(self):
        self.write(self.definitions / 'scenarios' / 'beta.json', {**SCENARIOS['beta'], 'two_side': {'trade': True}})
        code, result = self.simulated('--lanes', '3', '--scenario', 'beta', *SLOW[:3])
        self.assertEqual(code, 0, self.stderr.getvalue())
        admissions = self.events('lanes.log')
        self.assertEqual((admissions[0]['name'], admissions[0]['exclusive'], admissions[0]['running']),
                         ('Beta', True, []))
        self.assertEqual([event['exclusive'] for event in admissions[1:]], [False] * 3)
        self.assertEqual(result['simulation']['exclusive'], ['beta'])

    def test_game_event_cases_run_exclusively_without_a_policy_entry(self):
        self.write(self.definitions / 'scenarios' / 'beta.json',
                   {**SCENARIOS['beta'], 'steps': [{'action': 'game_event', 'event': 12, 'active': True},
                                                   *SCENARIOS['beta']['steps']]})
        code, result = self.simulated('--lanes', '3', '--scenario', 'beta', *SLOW[:3])
        self.assertEqual(code, 0, self.stderr.getvalue())
        admissions = self.events('lanes.log')
        self.assertEqual((admissions[0]['name'], admissions[0]['exclusive'], admissions[0]['running']),
                         ('Beta', True, []))
        self.assertEqual([event['exclusive'] for event in admissions[1:]], [False] * 3)
        self.assertEqual(result['simulation']['exclusive'], ['beta'])

    def test_exploratory_world_phase_masks_run_exclusively(self):
        probe = self.path / 'world-phase-probe.json'
        self.write(probe, {**SCENARIOS['slow-one'], 'name': 'Exploratory world phase',
                          'steps': [*SCENARIOS['slow-one']['steps'],
                                    {'action': 'set_phase', 'actor': 'caster', 'value': 3}]})
        code, result = self.simulated('--lanes', '3', '--scenario', str(probe), 'beta', 'slow-two')
        self.assertEqual(code, 0, self.stderr.getvalue())
        admissions = self.events('lanes.log')
        self.assertEqual((admissions[0]['name'], admissions[0]['exclusive'], admissions[0]['running']),
                         ('Exploratory world phase', True, []))
        self.assertFalse(any('Exploratory world phase' in event['running'] for event in admissions))
        self.assertEqual(result['simulation']['exclusive'], ['world-phase-probe'])
        self.assertEqual(result['exploratory_results']['world-phase-probe']['status'], 'passed')
        self.assertTrue(self.summary('world-phase-probe', 'exploratory')['simulation']['exclusive'])

    def test_accelerated_failure_cannot_pass_through_an_automatic_slower_retry(self):
        code, result = self.simulated('--lanes', '2', '--scenario', 'jittery', 'beta')
        self.assertEqual(code, 1)
        self.assertEqual(result['status'], 'failed')
        jittery = result['cases']['jittery']
        self.assertEqual((jittery['status'], jittery['mode']), ('failed', 'simulated'))
        self.assertEqual(jittery['directory'], str(self.output / 'cases' / 'jittery'))
        self.assertEqual(result['cases']['beta']['status'], 'passed')
        self.assertEqual(result['acceleration_sensitive'], [])
        self.assertEqual(result['verification']['status'], 'failed')
        self.assertNotIn('real_pace', jittery)
        self.assertFalse((self.output / 'real-pace').exists())
        self.assertEqual({event['pace'] for event in self.events('lanes.log')}, {'accelerated'})
        self.assertEqual([mode for mode, pid in self.starts()], ['queue'])

    def test_failures_rerun_at_real_pace_on_the_same_worldserver(self):
        code, result = self.simulated('--real-pace-rerun', '--lanes', '2', '--scenario', 'jittery', 'broken', 'beta')
        self.assertEqual(code, 1)
        self.assertEqual(result['status'], 'failed')
        jittery = result['cases']['jittery']
        self.assertEqual((jittery['status'], jittery['mode'], jittery['batch']['mode'], jittery['batch']['status']),
                         ('passed', 'real_pace', 'simulated', 'failed'))
        self.assertEqual(jittery['directory'], str(self.output / 'real-pace' / 'jittery'))
        broken = result['cases']['broken']
        self.assertEqual((broken['status'], broken['mode'], broken['real_pace']['status']),
                         ('failed', 'simulated', 'failed'))
        self.assertEqual((result['cases']['beta']['status'], result['cases']['beta']['mode']), ('passed', 'simulated'))
        self.assertEqual(result['acceleration_sensitive'], ['jittery'])
        self.assertEqual((result['batch_sensitive'], result['isolated_only']), ([], []))
        self.assertEqual([mode for mode, pid in self.starts()], ['queue'])
        self.assertIn('real-pace reruns on the same worldserver', result['scope'])
        admissions = self.events('lanes.log')
        real = [event for event in admissions if event['pace'] == 'real']
        accelerated = [event for event in admissions if event['pace'] == 'accelerated']
        self.assertEqual(sorted(event['name'] for event in real), ['Broken', 'Jittery'])
        self.assertGreater(min(event['sequence'] for event in real), max(event['sequence'] for event in accelerated))
        self.assertTrue(all(set(event['running']) <= {'Broken', 'Jittery'} for event in real))
        self.assertEqual(self.summary('jittery', 'real-pace')['simulation']['pace'], 'real')
        evidence = catalog.read_json(self.output / 'verification.json')['evidence']
        self.assertEqual(evidence['jittery']['directory'], str(self.output / 'real-pace' / 'jittery'))
        lines = self.stdout.getvalue().splitlines()
        self.assertTrue(any(line.startswith('FAIL jittery ') and not line.endswith('real-pace') for line in lines))
        self.assertTrue(any(line.startswith('PASS jittery ') and line.endswith(' real-pace') for line in lines))
        self.assertIn('1 acceleration-sensitive, 0 batch-sensitive', lines[-1])

    def test_isolated_rerun_is_an_opt_in_rung_after_real_pace(self):
        code, result = self.simulated('--real-pace-rerun', '--lanes', '2', '--isolated-rerun',
                                     '--scenario', 'flaky', 'beta')
        self.assertEqual(code, 0, self.stderr.getvalue())
        flaky = result['cases']['flaky']
        self.assertEqual((flaky['status'], flaky['mode'], flaky['batch']['mode']), ('passed', 'isolated', 'simulated'))
        self.assertEqual(flaky['batch']['real_pace']['status'], 'failed')
        self.assertEqual((result['batch_sensitive'], result['acceleration_sensitive']), (['flaky'], []))
        self.assertEqual([mode for mode, pid in self.starts()], ['queue', 'single'])
        self.assertEqual({(entry['mode'], entry['Clock'], entry['Lanes']) for entry in self.events('clocks.log')},
                         {('queue', 'simulated', '2'), ('single', 'real', '1')})
        self.assertIn('isolated single-mode reruns', result['scope'])

    def test_crash_with_several_cases_in_flight_requeues_each_once(self):
        code, result = self.simulated('--real-pace-rerun', '--lanes', '2', '--scenario', 'lane-crash', *SLOW)
        self.assertEqual(code, 1)
        self.assertEqual(len(result['failures']), 1, result['failures'])
        failure = result['failures'][0]
        self.assertTrue(failure.startswith('slot-0-1 cases 0 (lane-crash), 1 (slow-four): Worldserver exited'), failure)
        self.assertIn('2 cases were running at once', failure)
        self.assertEqual([server['status'] for server in result['servers']], ['failed', 'failed', 'stopped'])
        crashed = result['cases']['lane-crash']
        self.assertEqual((crashed['status'], crashed['mode'], crashed['batch']['status'], crashed['batch']['server']),
                         ('passed', 'real_pace', 'failed', 'slot-0-2'))
        self.assertIn('before returning the case result', crashed['batch']['message'])
        self.assertEqual({key: result['cases'][key]['status'] for key in SLOW}, dict.fromkeys(SLOW, 'passed'))
        self.assertEqual(result['acceleration_sensitive'], ['lane-crash'])
        retries = [(event['name'], event['exclusive'], event['pace']) for event in self.events('lanes.log')
                   if event['name'] in ('Lane crash', 'Slow four')]
        self.assertEqual(retries, [('Lane crash', False, 'accelerated'), ('Slow four', False, 'accelerated'),
                                   ('Lane crash', True, 'accelerated'), ('Slow four', True, 'accelerated'),
                                   ('Lane crash', False, 'real')])
        first = self.output / 'servers' / 'slot-0-1' / 'requeued'
        self.assertEqual(sorted(path.name for path in first.iterdir()),
                         ['lane-crash', 'slow-four', 'slow-one', 'slow-three'])
        self.assertIn('had not started', catalog.read_json(first / 'slow-one' / 'summary.json')['message'])
        second = self.output / 'servers' / 'slot-0-2' / 'requeued'
        self.assertEqual(sorted(path.name for path in second.iterdir()), ['slow-four', 'slow-one', 'slow-three'])
        self.assertEqual(self.stdout.getvalue().count('REQUEUED '), 7)

    def test_harness_shutdown_results_requeue_the_lanes_it_was_running(self):
        code, result = self.simulated('--lanes', '3', '--scenario', 'lane-aborter', 'linger', 'settler', 'slow-one')
        self.assertEqual(code, 1)
        self.assertEqual((result['acceleration_sensitive'], result['batch_sensitive']), ([], []))
        self.assertEqual({key: (case['status'], case['mode'], case['server']) for key, case in result['cases'].items()},
                         {'lane-aborter': ('passed', 'simulated', 'slot-0-1'),
                          **{key: ('passed', 'simulated', 'slot-0-2') for key in ('linger', 'settler', 'slow-one')}})
        self.assertEqual(len(result['failures']), 1, result['failures'])
        failure = result['failures'][0]
        self.assertTrue(failure.startswith('slot-0-1 cases 0 (linger), 2 (settler): Worldserver exited with code 1'),
                        failure)
        self.assertIn('queue protocol failures; case 1 (lane-aborter) returned the last result', failure)
        requeued = self.output / 'servers' / 'slot-0-1' / 'requeued'
        self.assertEqual(sorted(path.name for path in requeued.iterdir()), ['linger', 'settler', 'slow-one'])
        messages = [catalog.read_json(requeued / key / 'result.json')['message'] for key in ('linger', 'settler')]
        self.assertEqual(messages, list(batch.SHUTDOWN_MESSAGES))
        self.assertIn('had not started', catalog.read_json(requeued / 'slow-one' / 'summary.json')['message'])
        retries = [(event['name'], event['exclusive']) for event in self.events('lanes.log')
                   if event['name'] != 'Lane aborter']
        self.assertEqual(retries, [('Linger', False), ('Settler', False), ('Linger', True), ('Settler', True),
                                   ('Slow one', False)])
        lines = self.stdout.getvalue().splitlines()
        self.assertFalse([line for line in lines if line.startswith(('FAIL linger', 'FAIL settler'))])
        self.assertEqual(sorted(line.split()[1] for line in lines if line.startswith('REQUEUED ')),
                         ['linger', 'settler', 'slow-one'])

    def test_requested_exit_keeps_the_retry_of_cases_the_harness_never_admitted(self):
        self.write(self.definitions / batch.POLICY_FILE,
                   {'schema': 1, 'exclusive': {'lane-aborter': 'The fake worldserver aborts its queue'}})
        code, result = self.simulated('--lanes', '2', '--scenario', 'lane-aborter', *SLOW[:3])
        self.assertEqual(code, 1)
        self.assertEqual(len(result['failures']), 1, result['failures'])
        failure = result['failures'][0]
        self.assertTrue(failure.startswith('slot-0-1: Worldserver exited with code 1'), failure)
        self.assertIn('case 0 (lane-aborter) returned the last result', failure)
        self.assertEqual([(event['name'], event['exclusive']) for event in self.events('lanes.log')],
                         [('Lane aborter', True), ('Slow one', False), ('Slow three', False), ('Slow two', False)])
        self.assertEqual({key: (case['status'], case['server']) for key, case in result['cases'].items()},
                         {'lane-aborter': ('passed', 'slot-0-1'),
                          **{key: ('passed', 'slot-0-2') for key in SLOW[:3]}})
        requeued = self.output / 'servers' / 'slot-0-1' / 'requeued'
        for key in SLOW[:3]:
            self.assertIn('had not started', catalog.read_json(requeued / key / 'summary.json')['message'])

    def test_exit_with_the_last_result_writes_no_case_to_the_stopped_worldserver(self):
        code, result = self.simulated('--real-pace-rerun', '--lanes', '2',
                                     '--scenario', 'slow-aborter', 'jittery', 'broken')
        self.assertEqual(code, 1)
        self.assertEqual(len(result['failures']), 1, result['failures'])
        failure = result['failures'][0]
        self.assertTrue(failure.startswith('slot-0-1: Worldserver exited with code 1'), failure)
        self.assertIn('case 0 (slow-aborter) returned the last result', failure)
        real = sorted((event['name'], event['exclusive']) for event in self.events('lanes.log')
                      if event['pace'] == 'real')
        self.assertEqual(real, [('Broken', False), ('Jittery', False)])
        self.assertEqual(result['acceleration_sensitive'], ['jittery'])
        broken = result['cases']['broken']
        self.assertEqual((broken['status'], broken['mode'], broken['real_pace']['server']),
                         ('failed', 'simulated', 'slot-0-2'))

    def test_exploratory_keys_never_reuse_catalog_ids_so_lost_lanes_requeue_apart(self):
        probe = self.path / 'lane-crash.json'
        self.write(probe, {**SCENARIOS['lane-crash'], 'contract': 'slow'})
        code, result = self.simulated('--lanes', '2', '--scenario', 'lane-crash', str(probe))
        self.assertEqual(code, 1)
        self.assertEqual(result['exploratory'], ['lane-crash-2'])
        self.assertEqual(result['exploratory_results']['lane-crash-2']['status'], 'passed')
        requeued = self.output / 'servers' / 'slot-0-1' / 'requeued'
        self.assertEqual(sorted(path.name for path in requeued.iterdir()), ['lane-crash', 'lane-crash-2'])
        output = self.stdout.getvalue()
        self.assertIn('REQUEUED exploratory:lane-crash-2 ', output)
        self.assertIn('REQUEUED lane-crash ', output)
        self.assertNotIn('could not be queued again', json.dumps(result))

    def test_only_bare_harness_shutdown_results_count_as_cut_short(self):
        for message in batch.SHUTDOWN_MESSAGES:
            self.assertTrue(batch.cut_short({'status': 'failed', 'message': message}))
        for report in ({'status': 'failed', 'message': f'Fake native failure; {batch.SHUTDOWN_MESSAGES[1]}'},
                       {'status': 'failed', 'message': 'Teardown failed: A fixture group survived teardown'},
                       {'status': 'passed', 'message': batch.SHUTDOWN_MESSAGES[0]},
                       ValueError(batch.SHUTDOWN_MESSAGES[0]), [batch.SHUTDOWN_MESSAGES[0]]):
            self.assertFalse(batch.cut_short(report))

    def test_hang_backstop_starts_when_a_lane_could_admit_the_case(self):
        code, result = self.simulated('--lanes', '1', '--scenario', 'linger', 'brief')
        self.assertEqual(code, 0, self.stderr.getvalue())
        self.assertEqual([event['name'] for event in self.events('lanes.log')], ['Linger', 'Brief'])
        self.assertGreater(result['cases']['brief']['seconds'],
                           batch.SIMULATED_TIMEOUT_FACTOR * 0.1 + batch.CASE_GRACE_SECONDS)
        self.assertEqual(result['failures'], [])

    @unittest.skipUnless(hasattr(signal, 'SIGTERM') and os.name != 'nt', 'Requires POSIX SIGTERM delivery')
    def test_sigterm_fails_every_running_lane(self):
        timer = threading.Timer(1.0, os.kill, (os.getpid(), signal.SIGTERM))
        timer.start()
        self.addCleanup(timer.cancel)
        code, result = self.simulated('--lanes', '2', '--scenario', 'hang', 'linger')
        self.assertEqual(code, 1)
        self.assertTrue(result['interrupted'])
        self.assertEqual({key: (case['status'], case['message']) for key, case in result['cases'].items()},
                         dict.fromkeys(('hang', 'linger'), ('failed', 'Batch interrupted')))
        self.assertEqual([server['status'] for server in result['servers']], ['interrupted'])
        for mode, pid in self.starts():
            with self.assertRaises(ProcessLookupError):
                os.kill(int(pid), 0)

    def test_simulated_clock_needs_a_worldserver_that_started_the_lanes(self):
        command = self.command
        self.command = lambda config: [*command(config), '--without-lanes']
        code, result = self.simulated('--lanes', '2', '--scenario', 'beta')
        self.assertEqual(code, 1)
        self.assertIn('did not start 2 simulated-clock lanes', result['servers'][0]['message'])
        self.assertIn('No queue-mode worldserver became ready', result['failures'])
        self.assertEqual((result['cases']['beta']['status'], result['cases']['beta']['mode']), ('not_run', 'simulated'))
        self.assertEqual(len(result['servers']), batch.SERVER_FAILURE_LIMIT)

    def test_simulated_clock_needs_a_worldserver_that_anchored_its_start_hour(self):
        command = self.command
        self.command = lambda config: [*command(config), '--without-start-hour']
        code, result = self.simulated('--lanes', '2', '--scenario', 'beta')
        self.assertEqual(code, 1)
        self.assertIn('did not start 2 simulated-clock lanes at 10:00 realm-local time; rebuild it',
                      result['servers'][0]['message'])
        self.assertEqual(result['cases']['beta']['status'], 'not_run')

    def test_simulated_hour_cases_run_last_and_alone_at_their_hour(self):
        code, result = self.simulated('--lanes', '2', '--scenario', 'noon', 'alpha', *SLOW[:2])
        self.assertEqual(code, 0, self.stderr.getvalue())
        admissions = self.events('lanes.log')
        self.assertEqual([event['name'] for event in admissions][::3], ['Alpha', 'Noon'])
        noon = admissions[-1]
        self.assertEqual((noon['name'], noon['hour'], noon['exclusive'], noon['running']), ('Noon', 12, True, []))
        self.assertEqual([event['hour'] for event in admissions[:-1]], [None] * 3)
        records = [catalog.read_json(path) for path in sorted(
            (self.output / 'servers' / 'slot-0-1' / 'cases').glob('case-*.json'))]
        self.assertEqual([(record.get('hour'), record.get('exclusive')) for record in records if 'run_id' in record],
                         [(None, True), (None, None), (None, None), (12, True)])
        starts = {key: case['realm_local_start'] for key, case in result['cases'].items()}
        self.assertEqual(starts, {'alpha': '2026-09-25 10:00:00', 'slow-one': '2026-09-25 10:00:00',
                                  'slow-two': '2026-09-25 10:00:00', 'noon': '2026-09-25 12:00:00'})
        self.assertEqual(self.summary('noon')['simulation']['realm_local_start'], '2026-09-25 12:00:00')
        simulation = result['simulation']
        self.assertEqual((simulation['start_hour'], simulation['exclusive']), (10, ['alpha', 'noon']))
        self.assertEqual([mode for mode, pid in self.starts()], ['queue'])
        self.assertEqual(self.events('timezones.log'), [{'mode': 'queue', 'TZ': os.environ.get('TZ')}])

    def test_real_clock_runs_hour_cases_in_single_mode_at_a_fixed_offset(self):
        with patch.object(run, 'utc_now', return_value=UTC_EVENING):
            code, result = self.batch('--fresh-databases', '--jobs', '2', '--scenario', 'noon', *SLOW[:2])
        self.assertEqual(code, 0, self.stderr.getvalue())
        noon = result['cases']['noon']
        self.assertEqual((noon['status'], noon['mode'], noon['directory'], noon['timezone']),
                         ('passed', 'single', str(self.output / 'cases' / 'noon'), 'UTC+10:40'))
        self.assertRegex(noon['realm_local_start'], r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$')
        self.assertEqual(self.summary('noon')['timezone'], 'UTC+10:40')
        modes = [mode for mode, pid in self.starts()]
        self.assertEqual((modes.count('single'), modes[-1], 'queue' in modes), (1, 'single', True))
        self.assertNotIn('Noon', [event['name'] for event in self.events('lanes.log')])
        zones = self.events('timezones.log')
        self.assertEqual([entry['TZ'] for entry in zones if entry['mode'] == 'single'], ['UTC+10:40'])
        self.assertEqual({entry['TZ'] for entry in zones if entry['mode'] == 'queue'}, {os.environ.get('TZ')})
        self.assertEqual({key: result['cases'][key]['mode'] for key in SLOW[:2]}, dict.fromkeys(SLOW[:2], 'batch'))
        self.assertTrue(all('realm_local_start' in result['cases'][key] for key in SLOW[:2]))
        self.assertEqual((result['batch_sensitive'], result['isolated_only'], result['failures']), ([], [], []))
        self.assertEqual(result['scope'], batch.SCOPE.format('queue-mode native execution and single-mode runs at a '
                                                             'fixed realm-local hour'))
        evidence = catalog.read_json(self.output / 'verification.json')['evidence']
        self.assertEqual(evidence['noon']['directory'], str(self.output / 'cases' / 'noon'))
        self.assertTrue(any(line.startswith('PASS noon ') and line.endswith(' single')
                            for line in self.stdout.getvalue().splitlines()))

    def test_real_clock_selection_of_hour_cases_starts_no_queue_server(self):
        code, result = self.batch('--fresh-databases', '--scenario', 'noon')
        self.assertEqual(code, 0, self.stderr.getvalue())
        self.assertEqual([mode for mode, pid in self.starts()], ['single'])
        self.assertEqual((result['failures'], result['servers']), ([], []))
        self.assertEqual(result['cases']['noon']['mode'], 'single')

    def test_failed_single_mode_hour_case_is_not_rerun_in_isolation(self):
        code, result = self.batch('--fresh-databases', '--scenario', 'midnight', 'alpha')
        self.assertEqual(code, 1)
        midnight = result['cases']['midnight']
        self.assertEqual((midnight['status'], midnight['mode']), ('failed', 'single'))
        self.assertNotIn('isolated', midnight)
        self.assertEqual([mode for mode, pid in self.starts()], ['queue', 'single'])
        self.assertFalse((self.output / 'isolated').exists())

    def test_real_pace_reruns_after_an_hour_case_run_at_the_start_hour(self):
        code, result = self.simulated('--real-pace-rerun', '--lanes', '2', '--scenario', 'jittery', 'noon')
        self.assertEqual(code, 0, self.stderr.getvalue())
        self.assertEqual([(event['name'], event['pace'], event['hour']) for event in self.events('lanes.log')],
                         [('Jittery', 'accelerated', None), ('Noon', 'accelerated', 12), ('Jittery', 'real', None)])
        jittery = result['cases']['jittery']
        self.assertEqual((jittery['mode'], jittery['realm_local_start'], jittery['batch']['realm_local_start']),
                         ('real_pace', '2026-09-25 10:00:00', '2026-09-25 10:00:00'))
        self.assertEqual(result['cases']['noon']['realm_local_start'], '2026-09-25 12:00:00')
        self.assertEqual(result['acceleration_sensitive'], ['jittery'])

    def test_single_mode_run_messages_name_the_single_mode_run(self):
        def execute(parameters, scenario):
            if scenario['name'] == 'Midnight':
                raise KeyboardInterrupt
            parameters.output.mkdir(parents=True)
            self.write(parameters.output / 'summary.json', {'binary_sha256': 'rebuilt'})
            return 0

        with patch.object(run, 'execute', side_effect=execute):
            code, result = self.batch('--fresh-databases', '--scenario', 'noon', 'midnight')
        self.assertEqual(code, 1)
        cases = result['cases']
        self.assertEqual([(cases[key]['mode'], cases[key]['message']) for key in ('noon', 'midnight')],
                         [('single', 'The worldserver binary changed during the batch'),
                          ('single', 'Batch interrupted during the single-mode run')])
        self.assertIn('Single-mode run of noon: The worldserver binary changed during the batch', result['failures'])
        self.assertFalse(any('solated rerun' in failure for failure in result['failures']))

    def test_isolated_rerun_of_an_hour_case_uses_its_fixed_offset(self):
        with patch.object(run, 'utc_now', return_value=UTC_EVENING):
            code, result = self.simulated('--lanes', '2', '--isolated-rerun', '--scenario', 'dusk', 'beta')
        self.assertEqual(code, 0, self.stderr.getvalue())
        dusk = result['cases']['dusk']
        self.assertEqual((dusk['status'], dusk['mode'], dusk['timezone'], dusk['batch']['mode']),
                         ('passed', 'isolated', 'UTC+04:40', 'simulated'))
        self.assertEqual(dusk['batch']['realm_local_start'], '2026-09-25 18:00:00')
        self.assertEqual(result['batch_sensitive'], ['dusk'])
        self.assertEqual([(event['hour'], event['pace']) for event in self.events('lanes.log')
                          if event['name'] == 'Dusk'], [(18, 'accelerated')])
        self.assertEqual([entry['TZ'] for entry in self.events('timezones.log') if entry['mode'] == 'single'],
                         ['UTC+04:40'])

    def test_simulated_clock_needs_a_worldserver_that_applied_the_character_database_settings(self):
        command = self.command
        self.command = lambda config: [*command(config), '--without-database-settings']
        code, result = self.simulated('--lanes', '2', '--character-db-workers', '8', '--scenario', 'beta')
        self.assertEqual(code, 1)
        self.assertIn('did not open 8 character database workers at READ-COMMITTED; rebuild it',
                      result['servers'][0]['message'])
        self.assertIn('No queue-mode worldserver became ready', result['failures'])
        self.assertEqual((result['cases']['beta']['status'], result['cases']['beta']['mode']), ('not_run', 'simulated'))
        ready = {'character_db_workers': '8', 'character_db_isolation': 'READ-COMMITTED'}
        settings = batch.database_settings(SimpleNamespace(clock=batch.SIMULATED_CLOCK, character_db_workers=8))
        self.assertTrue(batch.applied_database_settings(ready, settings))
        self.assertFalse(batch.applied_database_settings(ready | {'character_db_isolation': 'REPEATABLE-READ'},
                                                         settings))
        self.assertFalse(batch.applied_database_settings(ready | {'character_db_workers': '16'}, settings))

    def test_clock_arguments_are_validated_before_any_server_starts(self):
        for arguments, message in ((['--clock', 'simulated', '--jobs', '2'], 'runs one worldserver'),
                                   (['--lanes', '2'], '--lanes above 1 requires --clock simulated'),
                                   (['--step-ms', '5', '--poll-cap-ms', '5'],
                                    'Clock tuning (--step-ms, --poll-cap-ms) requires --clock simulated'),
                                   (['--clock', 'simulated', '--lanes', '16'], '--lanes must be between 1 and 15'),
                                   (['--clock', 'simulated', '--lanes', '0'], '--lanes must be between 1 and 15'),
                                   (['--clock', 'simulated', '--poll-cap-ms', '0'], 'between 1 and 2000'),
                                   (['--clock', 'simulated', '--active-wait-cap-ms', '2001'], 'between 1 and 2000')):
            with self.subTest(arguments=arguments):
                code, result = self.batch('--fresh-databases', *arguments, '--scenario', 'alpha')
                self.assertEqual(code, 1)
                self.assertIsNone(result)
                self.assertIn(message, self.stderr.getvalue())
        self.assertEqual(self.starts(), [])
        self.assertFalse(self.output.exists())

    def test_invalid_clock_policy_fails_before_any_server_starts(self):
        for policy, message in (({'schema': 1, 'exclusive': {'missing': 'Global state'}}, 'unknown scenario missing'),
                                ({'schema': 1, 'exclusive': {'alpha': ' '}}, 'alpha needs a reason'),
                                ({'schema': 1, 'exclusive': ['alpha']}, 'exclusive must map scenario ids'),
                                ({'schema': 2, 'exclusive': {}}, 'Unsupported clock policy'),
                                ({'schema': 1, 'exclusive': {}, 'extra': 1}, 'Unsupported clock policy')):
            with self.subTest(policy=policy):
                self.write(self.definitions / batch.POLICY_FILE, policy)
                code, result = self.simulated('--scenario', 'beta')
                self.assertEqual(code, 1)
                self.assertIsNone(result)
                self.assertIn(message, self.stderr.getvalue())
        self.assertEqual(self.starts(), [])

    def test_shipped_clock_policy_names_catalog_cases_with_reasons(self):
        policy = batch.clock_policy()
        self.assertEqual(set(policy), SHIPPED_EXCLUSIVE)
        self.assertTrue(all(reason.strip() for reason in policy.values()))


if __name__ == '__main__':
    unittest.main()
