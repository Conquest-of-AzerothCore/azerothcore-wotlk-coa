import json
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest import mock

from conformance import main
from cycle import (CHECKPOINT_JSON, CHECKPOINT_MD, NOT_RECORDED, REFACTOR_FILE, STEPS, SUMMARY_FILE, CycleConfig,
                   CycleError, Record, Refactor, disk_percent, load_config, run_cycle)

FIXTURES = Path(__file__).resolve().parent / 'fixtures' / 'cycle'
REPOSITORY = Path(__file__).resolve().parents[3]
BUILD = 'b' * 64
STAMPS = ('20261114-084514', '20261114-090752')
RUNS_ONLY = ('gate', 'refactor', 'archive')
REPLAY = ('gate', 'digests', 'generate', 'source', 'runs', 'compare', 'audit')
DECISIONS = {'rulings': {'81.0': {'status': '3', 'why': 'mentor ruling on X 18:39, confirmed (c8 brief): status 3'}},
             'text_changed': ['125.2']}


def argument(command, flag):
    return command[command.index(flag) + 1]


class FakeRunner:
    def __init__(self, root: Path, percent: int = 87, verify_line: bool = True):
        self.root, self.percent, self.verify_line = root, percent, verify_line
        self.commands = []

    def kind(self, command):
        if command[0] in ('df', 'sh', 'diff'):
            return command[0]
        if '--stages' in command:
            return argument(command, '--stages')
        script = Path(command[2]).name
        return f'{script} {command[3]}'

    def __call__(self, command, cwd, log):
        command = list(command)
        self.commands.append(command)
        log.parent.mkdir(parents=True, exist_ok=True)
        kind = self.kind(command)
        if kind == 'df':
            log.write_text(f'Filesystem 1024-blocks Used Available Capacity Mounted on\n'
                           f'/dev/x 10 9 1 {self.percent}% /\n', encoding='utf-8')
        elif kind == 'conformance.py generate':
            self.generate(Path(argument(command, '--out')))
        elif kind == 'gameplay':
            number = sum(1 for found in self.commands if '--stages' in found and 'gameplay' in found)
            report = self.root / 'verify-all' / STAMPS[number - 1] / 'report.json'
            report.parent.mkdir(parents=True, exist_ok=True)
            report.write_text('{}', encoding='utf-8')
            if self.verify_line:
                log.write_text(f'VERIFY ALL: INCOMPLETE {report}\n', encoding='utf-8')
        elif kind == 'conformance.py compare':
            run = STAMPS.index(Path(argument(command, '--results')).name) + 1
            shutil.copytree(FIXTURES / 'final16' / f'cmp-run{run}', argument(command, '--out'))
        elif kind == 'conformance.py audit':
            run = 1 if argument(command, '--results').endswith(STAMPS[0]) else 2
            shutil.copy(FIXTURES / 'final16' / f'coverage-run{run}.json', argument(command, '--out'))
        return 0

    def generate(self, out: Path):
        manifest = json.loads((FIXTURES / 'final16' / 'manifest.json').read_text(encoding='utf-8'))
        (out / 'scenarios').mkdir(parents=True)
        for number, scenario in enumerate(manifest['scenarios']):
            scenario['file'] = f'scenarios/{number}.json'
            (out / scenario['file']).write_text('{}', encoding='utf-8')
        (out / 'manifest.json').write_text(json.dumps(manifest), encoding='utf-8')

    def kinds(self):
        return [self.kind(command) for command in self.commands]


class CycleCase(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.root = Path(self.directory.name)
        self.decisions = self.root / 'decisions.json'
        self.decisions.write_text(json.dumps(DECISIONS), encoding='utf-8')

    def tearDown(self):
        self.directory.cleanup()

    def config(self, **fields) -> CycleConfig:
        record = Record('final14', FIXTURES / 'record-status.json', ('20261114-033327', '20261114-035622'),
                        (FIXTURES / 'record' / 'cmp-run1', FIXTURES / 'record' / 'cmp-run2'),
                        FIXTURES / 'record' / 'manifest.json')
        values = dict(class_id=23, name='final16', worktree=REPOSITORY, head='055a888543', base='origin/main',
                      clauses=FIXTURES / 'clauses.json', out=self.root / 'out', build=BUILD, record=record,
                      decisions=self.decisions, scenarios_dir=self.root / 'scenarios')
        values.update(fields)
        return CycleConfig(**values)

    def replay(self, name='final16', **fields) -> CycleConfig:
        pair = FIXTURES / name
        values = dict(name=name, manifest=pair / 'manifest.json', stamps=STAMPS,
                      compare=(pair / 'cmp-run1', pair / 'cmp-run2'),
                      coverage=(pair / 'coverage-run1.json', pair / 'coverage-run2.json'))
        values.update(fields)
        return self.config(**values)

    def checkpoint(self) -> dict:
        return json.loads((self.root / 'out' / CHECKPOINT_JSON).read_text(encoding='utf-8'))

    def summary(self) -> list:
        return json.loads((self.root / 'out' / SUMMARY_FILE).read_text(encoding='utf-8'))['steps']


class StepOrderTest(CycleCase):
    def test_every_step_runs_in_order_and_writes_its_log(self):
        runner = FakeRunner(self.root)
        cycle = run_cycle(self.config(), RUNS_ONLY, runner)
        self.assertEqual(runner.kinds(), ['snapshots.py check', 'conformance.py generate', 'source', 'df',
                                          'gameplay', 'df', 'gameplay', 'conformance.py compare',
                                          'conformance.py compare', 'conformance.py audit', 'conformance.py audit'])
        self.assertEqual(cycle.done, [step for step in STEPS if step not in RUNS_ONLY])
        self.assertEqual([entry['state'] for entry in self.summary()],
                         ['skipped' if step in RUNS_ONLY else 'done' for step in STEPS])
        logs = sorted(path.name for path in (self.root / 'out' / 'logs').glob('[0-9]*.log'))
        self.assertEqual(logs, [f'{number:02d}-{step}.log' for number, step in enumerate(STEPS, 1)])
        self.assertEqual(cycle.stamps, list(STAMPS))
        self.assertEqual(self.checkpoint()['count'], 14)

    def test_the_run_commands_name_the_runner_workers_and_every_scenario(self):
        runner = FakeRunner(self.root)
        run_cycle(self.config(gameplay_runner=('coa-verify', '--worktree', '{worktree}', '--ram'),
                              gameplay_db_workers=4), RUNS_ONLY, runner)
        gameplay = [command for command in runner.commands if 'gameplay' in command]
        self.assertEqual(len(gameplay), 2)
        self.assertEqual(gameplay[0][:9], ['coa-verify', '--worktree', str(REPOSITORY), '--ram', '--stages',
                                           'gameplay', '--gameplay-db-workers', '4', '--scenario'])
        manifest = json.loads((FIXTURES / 'final16' / 'manifest.json').read_text(encoding='utf-8'))
        self.assertEqual(len(gameplay[0]) - 9, len(manifest['scenarios']))
        source = next(command for command in runner.commands if 'source' in command)
        self.assertEqual(source[-4:], ['--stages', 'source', '--base', 'origin/main'])
        compare = next(command for command in runner.commands if 'compare' in command)
        self.assertEqual(argument(compare, '--build'), BUILD)
        self.assertEqual(Path(argument(compare, '--out')).name, f'final16-cmp-{STAMPS[0]}')

    def test_the_gate_regenerates_each_guarded_generation_at_head_and_base(self):
        runner = FakeRunner(self.root)
        run_cycle(self.config(guard_classes=(19,)), [step for step in STEPS if step != 'gate'], runner)
        self.assertEqual(runner.kinds(), ['sh', 'conformance.py generate', 'conformance.py generate', 'diff',
                                          'conformance.py generate', 'conformance.py generate', 'diff',
                                          'snapshots.py check'])
        self.assertIn("archive --format=tar origin/main apps src data/sql/updates | tar -x", runner.commands[0][2])
        self.assertEqual(runner.commands[4][-1], '--stack')
        self.assertEqual(runner.commands[-1][-2:], ['--class', '19'])
        self.assertFalse((self.root / 'out' / 'gate' / 'base-tree').exists())


class SkipTest(CycleCase):
    def test_skipped_steps_issue_no_command_and_log_the_skip(self):
        runner = FakeRunner(self.root)
        run_cycle(self.replay(), REPLAY, runner)
        self.assertEqual(runner.commands, [])
        self.assertEqual((self.root / 'out' / 'logs' / '05-runs.log').read_text(encoding='utf-8'), 'skipped\n')
        self.assertEqual([entry['step'] for entry in self.summary() if entry['state'] == 'done'],
                         ['tally', 'refactor', 'archive', 'checkpoint'])

    def test_existing_outputs_require_their_step_to_be_skipped(self):
        with self.assertRaisesRegex(CycleError, 'skip the compare step'):
            run_cycle(self.replay(), ('gate', 'runs'), FakeRunner(self.root))
        with self.assertRaisesRegex(CycleError, 'skip the audit step'):
            run_cycle(self.replay(), ('gate', 'runs', 'compare'), FakeRunner(self.root))

    def test_an_unknown_step_is_refused(self):
        with self.assertRaisesRegex(CycleError, 'unknown steps'):
            run_cycle(self.replay(), (*REPLAY, 'deploy'), FakeRunner(self.root))

    def test_the_write_digests_flag_rewrites_instead_of_checking(self):
        runner = FakeRunner(self.root)
        run_cycle(self.replay(), [step for step in STEPS if step != 'digests'], runner, write_digests=True)
        self.assertEqual(runner.kinds(), ['snapshots.py write'])


class RefusalTest(CycleCase):
    def test_a_disk_above_the_limit_stops_before_the_run(self):
        runner = FakeRunner(self.root, percent=98)
        with self.assertRaisesRegex(CycleError, 'above the limit 97%; no run'):
            run_cycle(self.config(), RUNS_ONLY, runner)
        self.assertNotIn('gameplay', runner.kinds())
        self.assertEqual(self.summary()[-1]['step'], 'runs')
        self.assertEqual(self.summary()[-1]['state'], 'failed')

    def test_generate_refuses_a_non_empty_directory(self):
        (self.root / 'scenarios').mkdir()
        (self.root / 'scenarios' / 'old.json').write_text('{}', encoding='utf-8')
        runner = FakeRunner(self.root)
        with self.assertRaisesRegex(CycleError, 'is not empty'):
            run_cycle(self.config(), RUNS_ONLY, runner)
        self.assertNotIn('conformance.py generate', runner.kinds())

    def test_a_run_without_a_verify_line_stops_the_cycle(self):
        with self.assertRaisesRegex(CycleError, 'VERIFY ALL'):
            run_cycle(self.config(), RUNS_ONLY, FakeRunner(self.root, verify_line=False))

    def test_the_disk_percentage_is_read_from_the_last_line(self):
        self.assertEqual(disk_percent('Filesystem Capacity\n/dev/a 10 5 5 63% /var/lib/mysql\n'), 63.0)
        with self.assertRaises(CycleError):
            disk_percent('no figure')


class CheckpointTest(CycleCase):
    def test_the_checkpoint_holds_count_delta_flips_stamps_and_no_cost(self):
        run_cycle(self.replay('final15', previous_status=FIXTURES / 'final16-status.json'), REPLAY,
                  FakeRunner(self.root))
        document = self.checkpoint()
        self.assertEqual((document['count'], document['total'], document['previous_count'], document['delta']),
                         (13, 14, 14, -1))
        self.assertEqual(document['previous'], 'final16-status.json')
        self.assertEqual(document['statuses'], {'1': 8, '2': 4, '3': 1, 'not final': 1})
        self.assertEqual(document['flips'], {'in_pair': ['389.0'], 'against_record': ['389.0']})
        self.assertEqual((document['lost'], document['gained']), (['389.0'], []))
        self.assertEqual(document['stamps'], list(STAMPS))
        self.assertEqual(document['record'], {'name': 'final14', 'stamps': ['20261114-033327', '20261114-035622']})
        self.assertEqual((document['build'], document['head']), (BUILD, '055a888543'))
        self.assertEqual(document['cost'], NOT_RECORDED)
        self.assertEqual(document['refactor_gate'], NOT_RECORDED)
        markdown = (self.root / 'out' / CHECKPOINT_MD).read_text(encoding='utf-8')
        self.assertIn('- Count: **13 / 14 = 92.9%**, delta **-1** vs 14 (final16-status.json)', markdown)
        self.assertIn('- Cost: not recorded', markdown)

    def test_a_cost_file_fills_the_cost_field(self):
        cost = self.root / 'cost.json'
        cost.write_text(json.dumps({'roles': {'author': {'input': 10}}}), encoding='utf-8')
        run_cycle(self.replay(cost=cost), REPLAY, FakeRunner(self.root))
        self.assertEqual(self.checkpoint()['cost'], {'roles': {'author': {'input': 10}}})
        self.assertEqual(self.checkpoint()['delta'], 0)

    def test_the_tally_writes_the_status_files_of_the_pair(self):
        run_cycle(self.replay(), REPLAY, FakeRunner(self.root))
        rows = json.loads((self.root / 'out' / 'final16-status.json').read_text(encoding='utf-8'))
        self.assertEqual(rows, json.loads((FIXTURES / 'final16-status.json').read_text(encoding='utf-8')))


class RefactorGateTest(CycleCase):
    def verdicts(self, name: str, status: str) -> Path:
        directory = self.root / name
        directory.mkdir()
        verdicts = [{'label': f'9 {kind}', 'check': 'behaviour_metric_delta', 'scenario': 's', 'status': status}
                    for kind in ('moved_a', 'moved_b', 'moved_c')]
        (directory / 'verdicts.json').write_text(json.dumps({'verdicts': verdicts}), encoding='utf-8')
        return directory

    def test_changed_labels_of_moved_kinds_are_classed(self):
        entries = [{'kind': 'moved_a', 'spell': 9, 'name': 'Raise a minion'},
                   {'kind': 'moved_b', 'spell': 9, 'name': 'Strike', 'value': 2},
                   {'kind': 'moved_c', 'spell': 9, 'name': 'Strike'}, {'kind': 'kept', 'spell': 9}]
        before = [dict(entry, value=1) if entry['kind'] == 'moved_b' else entry for entry in entries]
        manifest = self.root / 'manifest.json'
        manifest.write_text(json.dumps({'scenarios': [{'key': 's', 'expectations': [
            {'label': f'9 {kind}', 'spell_id': 9, 'model': {'kind': kind}} for kind in ('moved_a', 'moved_b',
                                                                                     'moved_c')]}]}),
            encoding='utf-8')
        record = Record('final14', FIXTURES / 'record-status.json', (), (self.verdicts('r1', 'ok'),
                                                                          self.verdicts('r2', 'ok')), manifest)
        refactor = Refactor(('moved_a', 'moved_b', 'moved_c'), 'abc', 'classes/x.json', 'def', ('raise',), ())
        config = self.replay(record=record, manifest=manifest, refactor=refactor,
                             compare=(self.verdicts('p1', 'alert'), self.verdicts('p2', 'ok')))
        files = {'abc': {'behaviours': before}, 'def': {'behaviours': entries}}
        skip = (*REPLAY, 'tally', 'archive', 'checkpoint')
        with mock.patch('cycle.class_file_at', lambda worktree, rev, path: files[rev]):
            run_cycle(config, skip, FakeRunner(self.root))
        rows = json.loads((self.root / 'out' / REFACTOR_FILE).read_text(encoding='utf-8'))
        self.assertEqual({row['label']: row['class'] for row in rows},
                         {'9 moved_a': 'seed suspect (reads DB data)',
                          '9 moved_b': 'explained: entry changed since final14 (abc)',
                          '9 moved_c': 'refactor regression'})
        self.assertEqual(rows[0]['record'], [['ok'], ['ok']])
        self.assertEqual(rows[0]['pair'], [['alert'], ['ok']])


class CommandLineTest(CycleCase):
    def test_the_cycle_subcommand_reads_a_cycle_file_with_relative_paths(self):
        pair = FIXTURES / 'final16'
        document = {'class_id': 23, 'name': 'final16', 'worktree': str(REPOSITORY), 'head': 'abc',
                    'clauses': str(FIXTURES / 'clauses.json'), 'out': 'out', 'build': BUILD,
                    'decisions': 'decisions.json', 'manifest': str(pair / 'manifest.json'),
                    'record': {'name': 'final14', 'status': str(FIXTURES / 'record-status.json'),
                               'compare': [str(FIXTURES / 'record' / 'cmp-run1'),
                                           str(FIXTURES / 'record' / 'cmp-run2')],
                               'manifest': str(FIXTURES / 'record' / 'manifest.json')},
                    'pair': {'stamps': list(STAMPS), 'compare': [str(pair / 'cmp-run1'), str(pair / 'cmp-run2')],
                             'coverage': [str(pair / 'coverage-run1.json'), str(pair / 'coverage-run2.json')]}}
        path = self.root / 'cycle.json'
        path.write_text(json.dumps(document), encoding='utf-8')
        config = load_config(path)
        self.assertEqual((config.out, config.decisions), (self.root / 'out', self.decisions))
        self.assertEqual((config.gameplay_db_workers, config.disk_limit_percent), (4, 97.0))
        skips = [part for step in REPLAY for part in ('--skip', step)]
        self.assertEqual(main(['cycle', '--config', str(path), *skips]), 0)
        self.assertEqual(self.checkpoint()['count'], 14)
        document['pair']['stamps'] = list(STAMPS[:1])
        path.write_text(json.dumps(document), encoding='utf-8')
        with self.assertRaisesRegex(CycleError, 'pair.stamps'):
            load_config(path)


if __name__ == '__main__':
    unittest.main()
