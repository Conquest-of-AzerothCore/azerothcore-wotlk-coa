import contextlib
import filecmp
import hashlib
import io
import json
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest import mock

from conformance import main
import cycle
from cycle import (CHECKPOINT_JSON, CHECKPOINT_MD, NOT_RECORDED, REFACTOR_FILE, STEPS, SUMMARY_FILE, CycleConfig,
                   CycleError, GateChange, Record, Refactor, accepted_diff, disk_percent, load_config)

FIXTURES = Path(__file__).resolve().parent / 'fixtures' / 'cycle'
REPOSITORY = Path(__file__).resolve().parents[3]
BUILD = 'b' * 64
STAMPS = ('20261114-084514', '20261114-090752')
RUNS_ONLY = ('gate', 'refactor', 'archive')
REPLAY = ('gate', 'digests', 'generate', 'source', 'runs', 'compare', 'audit')
JUDGE_CHANGED_KEY = ('503740 behaviour_metric_delta frenzied_snare_immune', 'behaviour_metric_delta',
                     'conformance-necromancer-behaviour-503740-metric-delta-frenzied-snare-immune')
JUDGE_CHANGE_WHY = 'the c16 guard changed the frenzied_snare_immune judge'
DECISIONS = {'rulings': {'81.0': {'status': '3', 'why': 'mentor ruling on X 18:39, confirmed (c8 brief): status 3'}},
             'text_changed': ['125.2']}


def no_missing_result(manifest, results):
    return []


def run_cycle(config, skip, runner, results_check=no_missing_result, **options):
    return cycle.run_cycle(config, skip, runner, results_check=results_check, **options)


def accepting(*keys, why=JUDGE_CHANGE_WHY):
    return cycle.verdict_acceptance({'keys': [list(JUDGE_CHANGED_KEY), *map(list, keys)], 'why': why})


def argument(command, flag):
    return command[command.index(flag) + 1]


class FakeRunner:
    def __init__(self, root: Path, percent: int = 87, verify_line: bool = True, verify: str = 'INCOMPLETE',
                 gameplay_exit: int = 3, gameplay_stage: dict | None = None, failing: str | None = None,
                 stamps: tuple = STAMPS):
        self.root, self.percent, self.verify_line = root, percent, verify_line
        self.verify, self.gameplay_exit, self.failing = verify, gameplay_exit, failing
        self.stamps = stamps
        self.gameplay_stage = gameplay_stage or {'status': 'unavailable', 'summary': {'returncode': 3}}
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
            report = self.root / 'verify-all' / self.stamps[number - 1] / 'report.json'
            report.parent.mkdir(parents=True, exist_ok=True)
            report.write_text(json.dumps({'stages': {'gameplay': self.gameplay_stage}}), encoding='utf-8')
            if self.verify_line:
                log.write_text(f'VERIFY ALL: {self.verify} {report}\n', encoding='utf-8')
            return self.gameplay_exit
        elif kind == 'conformance.py compare':
            run = STAMPS.index(Path(argument(command, '--results')).name) + 1
            shutil.copytree(FIXTURES / 'final16' / f'cmp-run{run}', argument(command, '--out'))
        elif kind == 'conformance.py audit':
            run = 1 if argument(command, '--results').endswith(STAMPS[0]) else 2
            shutil.copy(FIXTURES / 'final16' / f'coverage-run{run}.json', argument(command, '--out'))
        return 1 if kind == self.failing else 0

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
                      decisions=self.decisions, scenarios_dir=self.root / 'scenarios',
                      other_verdicts_accepted=accepting())
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


class GuardRunner(FakeRunner):
    def __init__(self, root: Path, head_creature: dict, base_creature: dict | None = None):
        super().__init__(root)
        self.head_creature, self.base_creature = head_creature, base_creature or {'entry': 36}

    def generate(self, out: Path):
        creature = self.head_creature if out.name == 'head' else self.base_creature
        (out / 'scenarios').mkdir(parents=True)
        scenarios = []
        for number in range(2):
            text = json.dumps({'creatures': [creature if number == 0 else {'entry': 36}]})
            (out / 'scenarios' / f'{number}.json').write_text(text, encoding='utf-8')
            scenarios.append({'key': f'scenario-{number}', 'file': f'scenarios/{number}.json',
                              'sha256': hashlib.sha256(text.encode()).hexdigest()})
        (out / 'manifest.json').write_text(json.dumps({'scenarios': scenarios}), encoding='utf-8')

    def __call__(self, command, cwd, log):
        if command[0] == 'diff':
            self.commands.append(list(command))
            differ = filecmp.dircmp(command[3], command[4])
            return 1 if differ.diff_files or differ.subdirs['scenarios'].diff_files else 0
        return super().__call__(command, cwd, log)


class GateChangeTest(CycleCase):
    ARMOR = GateChange(19, ('min_level_armor',), 'ADR 0658 pins generated fixture armor')

    def gate(self, runner, accepted=()):
        return run_cycle(self.config(guard_classes=(19,), gate_accepted=accepted),
                         [step for step in STEPS if step != 'gate'], runner)

    def test_an_undeclared_change_of_a_guard_class_stops_the_gate(self):
        with self.assertRaisesRegex(CycleError, 'class 19 all differs between head and base; declare'):
            self.gate(GuardRunner(self.root, {'entry': 36, 'min_level_armor': True}))

    def test_a_declared_added_field_passes_the_gate_and_is_logged(self):
        runner = GuardRunner(self.root, {'entry': 36, 'min_level_armor': True})
        self.assertEqual(self.gate(runner, (self.ARMOR,)).done, ['gate'])
        log = (self.root / 'out' / 'logs' / '01-gate.log').read_text(encoding='utf-8')
        self.assertIn("class 19 all: 1 files differ only by the accepted added fields ['min_level_armor'] (ADR 0658",
                      log)
        self.assertEqual(runner.kinds()[-1], 'snapshots.py check')

    def test_a_change_beyond_the_declared_field_stops_the_gate(self):
        runner = GuardRunner(self.root, {'entry': 37, 'min_level_armor': True})
        with self.assertRaisesRegex(CycleError, r"scenarios/0.json: differs beyond the accepted added fields"):
            self.gate(runner, (self.ARMOR,))

    def test_a_changed_value_of_the_declared_field_is_not_an_addition(self):
        runner = GuardRunner(self.root, {'entry': 36, 'min_level_armor': True},
                             {'entry': 36, 'min_level_armor': False})
        with self.assertRaisesRegex(CycleError, 'differs beyond the accepted'):
            self.gate(runner, (self.ARMOR,))

    def test_a_declared_change_that_did_not_happen_stops_the_gate(self):
        with self.assertRaisesRegex(CycleError, 'declares the accepted change .* but no generated file changed'):
            self.gate(GuardRunner(self.root, {'entry': 36}), (self.ARMOR,))

    def test_a_manifest_sha_change_without_a_file_change_is_refused(self):
        head, base = self.root / 'head', self.root / 'base'
        for root, sha in ((head, 'a'), (base, 'b')):
            (root / 'scenarios').mkdir(parents=True)
            (root / 'scenarios' / '0.json').write_text('{}', encoding='utf-8')
            (root / 'manifest.json').write_text(json.dumps({'scenarios': [{'key': 'k', 'file': 'scenarios/0.json',
                                                                           'sha256': sha}]}), encoding='utf-8')
        problems, changed = accepted_diff(head, base, ('min_level_armor',))
        self.assertEqual((problems, changed), (['manifest.json: sha256 of k changed but its file scenarios/0.json '
                                                'did not'], set()))

    def test_a_formatting_only_change_is_not_an_addition(self):
        head, base = self.root / 'head', self.root / 'base'
        for root, text in ((head, '{"entry": 36}'), (base, '{ "entry": 36 }')):
            root.mkdir()
            (root / '0.json').write_text(text, encoding='utf-8')
        self.assertEqual(accepted_diff(head, base, ('min_level_armor',)),
                         (["0.json: differs in formatting only, adding none of the accepted fields "
                           "['min_level_armor']"], set()))

    def test_the_cycle_file_declares_an_accepted_change_of_a_guard_class(self):
        document = {
            'class_id': 23, 'name': 'x', 'worktree': str(REPOSITORY), 'clauses': 'c.json', 'out': 'out',
            'build': BUILD, 'guard_classes': [19],
            'record': {'name': 'r', 'status': 's.json', 'compare': ['a', 'b'], 'manifest': 'm.json'},
            'gate_accepted': [{'class_id': 19, 'added_fields': ['min_level_armor'], 'why': 'ADR 0658'}]}
        path = self.root / 'cycle.json'
        path.write_text(json.dumps(document), encoding='utf-8')
        self.assertEqual(load_config(path).gate_accepted, (GateChange(19, ('min_level_armor',), 'ADR 0658'),))
        document['gate_accepted'][0]['why'] = ''
        path.write_text(json.dumps(document), encoding='utf-8')
        with self.assertRaisesRegex(CycleError, 'gate_accepted'):
            load_config(path)
        with self.assertRaisesRegex(CycleError, 'must be distinct guard classes'):
            run_cycle(self.config(guard_classes=(19,), gate_accepted=(GateChange(23, ('x',), 'y'),)), STEPS,
                      FakeRunner(self.root))


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

    def test_a_failed_or_mismatched_run_stops_before_the_compare(self):
        for runner, reason in ((FakeRunner(self.root, verify='FAILED', gameplay_exit=1), 'FAILED with exit 1'),
                               (FakeRunner(self.root, gameplay_exit=2), 'INCOMPLETE with exit 2'),
                               (FakeRunner(self.root, gameplay_stage={'status': 'unavailable',
                                                                      'summary': {'reason': 'no MySQL'}}),
                                'without a gameplay run \\(no MySQL\\)')):
            shutil.rmtree(self.root / 'out', ignore_errors=True)
            shutil.rmtree(self.root / 'scenarios', ignore_errors=True)
            with self.assertRaisesRegex(CycleError, f'run 1: .*{reason}'):
                run_cycle(self.config(), RUNS_ONLY, runner)
            self.assertEqual(runner.kinds().count('gameplay'), 1)
            self.assertNotIn('conformance.py compare', runner.kinds())
            self.assertEqual((self.summary()[-1]['step'], self.summary()[-1]['state']), ('runs', 'failed'))

    def test_a_run_missing_scenario_results_stops_the_cycle(self):
        runner = FakeRunner(self.root)
        with self.assertRaisesRegex(CycleError, 'runs: 1 scenarios of the manifest have no result in .*: s-1'):
            run_cycle(self.config(), RUNS_ONLY, runner, results_check=lambda manifest, results: ['s-1'])
        self.assertEqual(runner.kinds().count('gameplay'), 1)

    def test_recorded_results_missing_scenarios_stop_the_compare(self):
        config = self.replay(compare=(), coverage=(), results=(self.root / 'r1', self.root / 'r2'))
        runner = FakeRunner(self.root)
        with self.assertRaisesRegex(CycleError, 'compare: 2 scenarios'):
            run_cycle(config, ('gate', 'digests', 'generate', 'source', 'runs'), runner,
                      results_check=lambda manifest, results: ['b', 'a'])
        self.assertEqual(runner.commands, [])

    def test_a_failing_command_stops_the_cycle_at_its_step(self):
        runner = FakeRunner(self.root, failing='source')
        with self.assertRaisesRegex(CycleError, 'source: .* exited 1'):
            run_cycle(self.config(), RUNS_ONLY, runner)
        self.assertNotIn('gameplay', runner.kinds())
        self.assertEqual([entry['state'] for entry in self.summary()][-1], 'failed')

    def test_the_gate_refuses_an_empty_guard_class_list(self):
        with self.assertRaisesRegex(CycleError, 'guard_classes'):
            run_cycle(self.replay(), [step for step in STEPS if step != 'gate'], FakeRunner(self.root))

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

    def test_the_checkpoint_states_the_record_scenarios_matched(self):
        run_cycle(self.replay(), REPLAY, FakeRunner(self.root))
        self.assertEqual(self.checkpoint()['record_scenarios'],
                         {'matched': 22, 'unmatched': 0, 'unmatched_scenarios': []})
        markdown = (self.root / 'out' / CHECKPOINT_MD).read_text(encoding='utf-8')
        self.assertIn('- Record scenarios: 22 matched by entry and label, 0 unmatched', markdown)
        self.assertEqual(self.checkpoint()['record_verdicts'],
                         {'no_scenario_file': 0, 'other': 1, 'other_verdicts': [list(JUDGE_CHANGED_KEY)]})
        self.assertIn('- Record verdicts not compared with the record: 0 with no scenario file, 1 other, ACCEPTED in '
                      f'the cycle file: {JUDGE_CHANGE_WHY}', markdown)

    def test_the_fixture_judge_change_stops_the_cycle_unless_accepted(self):
        with self.assertRaisesRegex(CycleError, 'other 1: 503740 behaviour_metric_delta frenzied_snare_immune'):
            run_cycle(self.replay(other_verdicts_accepted=None), REPLAY, FakeRunner(self.root))

    OTHER_KEY = ('301303 effect_value e0 #0', 'effect_value', 'derived-301303')

    def other_verdict_config(self, **fields) -> CycleConfig:
        record = []
        for index, source in enumerate((FIXTURES / 'record' / 'cmp-run1', FIXTURES / 'record' / 'cmp-run2')):
            document = json.loads((source / 'verdicts.json').read_text(encoding='utf-8'))
            document['verdicts'].append({'label': self.OTHER_KEY[0], 'check': self.OTHER_KEY[1],
                                         'scenario': self.OTHER_KEY[2], 'status': 'ok'})
            out = self.root / f'record-{index}'
            out.mkdir(exist_ok=True)
            (out / 'verdicts.json').write_text(json.dumps(document), encoding='utf-8')
            record.append(out)
        config = self.replay()
        return self.replay(record=Record(config.record.name, config.record.status, config.record.stamps,
                                         tuple(record), config.record.manifest), **fields)

    def test_other_unmatched_record_verdicts_stop_the_cycle(self):
        with self.assertRaisesRegex(CycleError, 'other 2: 301303 effect_value e0 #0 \\| effect_value \\|'):
            run_cycle(self.other_verdict_config(), REPLAY, FakeRunner(self.root))
        self.assertFalse((self.root / 'out' / CHECKPOINT_JSON).exists())

    def test_other_unmatched_record_verdicts_stop_the_tally_step(self):
        steps = [step for step in REPLAY if step != 'tally']
        with self.assertRaisesRegex(CycleError, 'tally: record verdicts not compared'):
            run_cycle(self.other_verdict_config(), steps, FakeRunner(self.root))

    def test_accepted_other_record_verdicts_pass_with_the_reason_in_the_checkpoint(self):
        config = self.other_verdict_config(other_verdicts_accepted=accepting(self.OTHER_KEY, why='mentor M3'))
        run_cycle(config, REPLAY, FakeRunner(self.root))
        document = self.checkpoint()
        self.assertEqual(document['record_verdicts']['other'], 2)
        self.assertEqual(document['record_verdicts_acceptance'],
                         {'why': 'mentor M3', 'count': 2, 'keys': [list(self.OTHER_KEY), list(JUDGE_CHANGED_KEY)]})
        markdown = (self.root / 'out' / CHECKPOINT_MD).read_text(encoding='utf-8')
        self.assertIn('ACCEPTED in the cycle file: mentor M3 (301303 effect_value e0 #0 | effect_value | '
                      'derived-301303, 503740', markdown)

    def test_an_acceptance_that_is_not_the_exact_key_set_still_stops(self):
        stale = ('other', 'effect_value', 'derived-1')
        for acceptance, expected in (
                (accepting(stale),
                 'Not accepted: 301303 effect_value e0 #0 \\| effect_value \\| derived-301303. '
                 'Accepted but not found \\(stale\\): other \\| effect_value \\| derived-1'),
                (accepting(self.OTHER_KEY, stale),
                 'Not accepted: none. Accepted but not found \\(stale\\): other \\| effect_value \\| derived-1')):
            with self.subTest(acceptance=acceptance):
                config = self.other_verdict_config(other_verdicts_accepted=acceptance)
                with self.assertRaisesRegex(CycleError, expected):
                    run_cycle(config, REPLAY, FakeRunner(self.root))

    def test_an_acceptance_with_nothing_found_is_stale(self):
        with self.assertRaisesRegex(CycleError, 'other 0: ; .*Accepted but not found \\(stale\\)'):
            cycle.verdict_acceptance_note(self.replay(), {'other_verdicts': []})
        with self.assertRaisesRegex(CycleError, 'other 1: .*Accepted but not found \\(stale\\): 301303'):
            run_cycle(self.replay(other_verdicts_accepted=accepting(self.OTHER_KEY)), REPLAY, FakeRunner(self.root))

    def test_the_checkpoint_step_stops_on_its_own_when_the_tally_is_skipped(self):
        run_cycle(self.other_verdict_config(other_verdicts_accepted=accepting(self.OTHER_KEY)), REPLAY,
                  FakeRunner(self.root))
        (self.root / 'out' / CHECKPOINT_JSON).unlink()
        with self.assertRaisesRegex(CycleError, '^record verdicts not compared'):
            run_cycle(self.other_verdict_config(), [*REPLAY, 'tally'], FakeRunner(self.root))
        self.assertFalse((self.root / 'out' / CHECKPOINT_JSON).exists())

    def test_an_acceptance_needs_a_reason_and_keys(self):
        for document in ({'count': 1, 'why': 'x'}, {'why': 'x'}, {'keys': [['a', 'b', 'c']]},
                         {'why': ' ', 'keys': [['a', 'b', 'c']]}, {'why': 'x', 'keys': []},
                         {'why': 'x', 'count': 1, 'keys': [['a', 'b', 'c']]}, {'why': 'x', 'keys': [['a', 'b']]},
                         {'why': 'x', 'keys': ['abc']}, {'why': 'x', 'keys': 'abc'},
                         {'why': 'x', 'keys': [['a', 'b', 1]]}, {'why': 'x', 'keys': [['a', 'b', 'c']] * 2},
                         {'why': 3, 'keys': [['a', 'b', 'c']]}):
            with self.subTest(document=document), self.assertRaisesRegex(CycleError, 'other_verdicts_accepted'):
                cycle.verdict_acceptance(document)

    def test_a_malformed_acceptance_in_the_cycle_file_is_a_cycle_error(self):
        for document in ([], 'x', 3, [['a', 'b', 'c']]):
            with self.subTest(document=document), self.assertRaisesRegex(CycleError, 'not an object'):
                cycle.verdict_acceptance(document)

    def test_unmatched_record_scenarios_are_loud_in_the_checkpoint_and_the_command_line(self):
        manifest = json.loads((FIXTURES / 'final16' / 'manifest.json').read_text(encoding='utf-8'))
        manifest['scenarios'] = manifest['scenarios'][1:]
        path = self.root / 'manifest.json'
        path.write_text(json.dumps(manifest), encoding='utf-8')
        removed = (self.OTHER_KEY[0], self.OTHER_KEY[1], 'conformance-necromancer-value-301303')
        run_cycle(self.replay(manifest=path, other_verdicts_accepted=accepting(removed, why='the removed scenario')),
                  REPLAY, FakeRunner(self.root))
        markdown = (self.root / 'out' / CHECKPOINT_MD).read_text(encoding='utf-8')
        self.assertIn('- **WARNING: 1 record scenarios UNMATCHED** (not compared with the record), 21 matched by '
                      'entry and label: conformance-necromancer-value-301303', markdown)
        self.assertEqual(self.checkpoint()['record_scenarios']['unmatched'], 1)
        log = (self.root / 'out' / 'logs' / '11-checkpoint.log').read_text(encoding='utf-8')
        self.assertIn('WARNING record scenarios matched by entry and label: 21, UNMATCHED: 1', log)

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

    def scenario_verdicts(self, name: str, statuses: dict) -> Path:
        directory = self.root / name
        directory.mkdir()
        verdicts = [{'label': '9 moved_a', 'check': 'behaviour_metric_delta', 'scenario': scenario, 'status': status}
                    for scenario, status in statuses.items()]
        (directory / 'verdicts.json').write_text(json.dumps({'verdicts': verdicts}), encoding='utf-8')
        return directory

    def test_a_change_in_one_scenario_of_a_shared_label_is_reported(self):
        entries = [{'kind': 'moved_a', 'spell': 9, 'name': 'Strike'}]
        manifest = self.root / 'manifest.json'
        manifest.write_text(json.dumps({'scenarios': [{'key': key, 'expectations': [
            {'label': '9 moved_a', 'spell_id': 9, 'model': {'kind': 'moved_a'}}]} for key in ('a', 'b')]}),
            encoding='utf-8')
        recorded = {'a': 'ok', 'b': 'alert'}
        record = Record('final14', FIXTURES / 'record-status.json', (),
                        (self.scenario_verdicts('r1', recorded), self.scenario_verdicts('r2', recorded)), manifest)
        refactor = Refactor(('moved_a',), 'abc', 'classes/x.json', 'def', (), ())
        config = self.replay(record=record, manifest=manifest, refactor=refactor,
                             compare=(self.scenario_verdicts('p1', {'a': 'alert', 'b': 'alert'}),
                                      self.scenario_verdicts('p2', recorded)))
        files = {'abc': {'behaviours': entries}, 'def': {'behaviours': entries}}
        with mock.patch('cycle.class_file_at', lambda worktree, rev, path: files[rev]):
            run_cycle(config, (*REPLAY, 'tally', 'archive', 'checkpoint'), FakeRunner(self.root))
        rows = json.loads((self.root / 'out' / REFACTOR_FILE).read_text(encoding='utf-8'))
        self.assertEqual([(row['label'], row['changed'], row.get('changed_scenarios'), row.get('class'))
                          for row in rows], [('9 moved_a', True, ['a'], 'refactor regression')])


    def test_a_missing_verdict_differs_from_a_second_ok(self):
        key = ('9 moved_a', 'behaviour_metric_delta')
        ok = {key: [{'scenario': 's', 'status': 'ok'}]}
        self.assertEqual(cycle.by_scenario([ok, ok], key), {'s': ['ok', 'ok']})
        self.assertEqual(cycle.by_scenario([ok, {}], key), {'s': ['missing', 'ok']})
        self.assertEqual(cycle.changed_scenarios([ok, ok], [ok, {}], key), ['s'])
        self.assertEqual(cycle.changed_scenarios([ok, {}], [{}, ok], key), [])


class ArchiveLedgerTest(CycleCase):
    def repository(self, consumption: bool) -> tuple:
        repo = self.root / 'repo'
        classes = repo / cycle.CONFORMANCE / 'classes'
        classes.mkdir(parents=True)
        (classes / 'x_clauses.json').write_text('["committed"]', encoding='utf-8')
        (classes / 'x.json').write_text('{"class_id": 23}', encoding='utf-8')
        if consumption:
            (classes / 'x_consumption.json').write_text('{}', encoding='utf-8')
        git = ['git', '-C', str(repo), '-c', 'user.name=t', '-c', 'user.email=t@t']
        for command in (['init', '-q'], ['add', '.'], ['commit', '-q', '-m', 'ledger']):
            cycle.subprocess.run([*git, *command], check=True)
        head = cycle.subprocess.run([*git, 'rev-parse', 'HEAD'], capture_output=True, text=True).stdout.strip()
        (classes / 'x.json').write_text('{"class_id": 99}', encoding='utf-8')
        return repo, classes / 'x_clauses.json', head

    def archive(self, consumption: bool = True) -> tuple:
        repo, clauses, head = self.repository(consumption)
        archive = self.root / 'archive'
        run_cycle(self.replay(worktree=repo, clauses=clauses, head=head, archive=archive),
                  (*REPLAY, 'tally', 'refactor', 'checkpoint'), FakeRunner(self.root))
        return archive, head

    def test_the_archive_holds_the_ledger_used_and_the_class_files_at_the_generating_commit(self):
        archive, head = self.archive()
        ledger = archive / 'ledger'
        self.assertEqual(sorted(path.name for path in ledger.iterdir()),
                         ['x.json', 'x_clauses.json', 'x_consumption.json'])
        self.assertEqual((ledger / 'x.json').read_text(encoding='utf-8'), '{"class_id": 23}')
        self.assertEqual((ledger / 'x_clauses.json').read_text(encoding='utf-8'), '["committed"]')
        build = (archive / 'BUILD.txt').read_text(encoding='utf-8')
        self.assertIn(f'Ledger used: ledger/x_clauses.json, equal to {head}:{cycle.CONFORMANCE.as_posix()}'
                      f'/classes/x_clauses.json.', build)
        self.assertIn('--clauses ledger/x_clauses.json', build)
        self.assertIn(f'{cycle.sha256(ledger / "x.json")}  ledger/x.json', build)

    def test_a_ledger_that_differs_from_the_generating_commit_is_stated(self):
        repo, clauses, head = self.repository(False)
        clauses.write_text('["edited"]', encoding='utf-8')
        archive = self.root / 'archive'
        run_cycle(self.replay(worktree=repo, clauses=clauses, head=head, archive=archive),
                  (*REPLAY, 'tally', 'refactor', 'checkpoint'), FakeRunner(self.root))
        build = (archive / 'BUILD.txt').read_text(encoding='utf-8')
        self.assertIn('ledger/x_clauses.json, DIFFERENT from', build)
        self.assertIn(f'No x_consumption.json at {head}.', build)
        self.assertEqual((archive / 'ledger' / 'x_clauses.json').read_text(encoding='utf-8'), '["edited"]')
        committed = archive / 'ledger' / 'committed-x_clauses.json'
        self.assertEqual(committed.read_text(encoding='utf-8'), '["committed"]')
        self.assertIn(f'{cycle.sha256(committed)}  ledger/committed-x_clauses.json', build)


    def test_the_archive_names_the_resolved_generating_commit(self):
        repo, clauses, head = self.repository(False)
        archive = self.root / 'archive'
        run_cycle(self.replay(worktree=repo, clauses=clauses, head='HEAD', archive=archive),
                  (*REPLAY, 'tally', 'refactor', 'checkpoint'), FakeRunner(self.root))
        build = (archive / 'BUILD.txt').read_text(encoding='utf-8')
        self.assertIn(f'Generation commit {head} (worktree', build)
        self.assertIn(f'equal to {head}:', build)
        self.assertNotIn('HEAD', build)

    def test_a_ledger_without_the_clauses_suffix_stops_the_archive(self):
        repo, clauses, _ = self.repository(False)
        archive = self.root / 'archive'
        with self.assertRaisesRegex(CycleError, r'archive: the ledger x.json does not end in _clauses.json'):
            run_cycle(self.replay(worktree=repo, clauses=clauses.with_name('x.json'), head='HEAD', archive=archive),
                      (*REPLAY, 'tally', 'refactor', 'checkpoint'), FakeRunner(self.root))
        self.assertFalse(archive.exists())

    def test_an_unreadable_generating_commit_stops_the_archive(self):
        repo, clauses, _ = self.repository(False)
        archive = self.root / 'archive'
        with self.assertRaisesRegex(CycleError, f'archive: the generating commit {"0" * 40} cannot be read in'):
            run_cycle(self.replay(worktree=repo, clauses=clauses, head='0' * 40, archive=archive),
                      (*REPLAY, 'tally', 'refactor', 'checkpoint'), FakeRunner(self.root))
        self.assertFalse(archive.exists())

    def test_an_archive_without_a_generating_commit_is_refused(self):
        repo, clauses, _ = self.repository(False)
        archive = self.root / 'archive'
        with self.assertRaisesRegex(CycleError, 'the archive step needs "head", the generating commit'):
            run_cycle(self.replay(worktree=repo, clauses=clauses, head=None, archive=archive),
                      (*REPLAY, 'tally', 'refactor', 'checkpoint'), FakeRunner(self.root))
        self.assertFalse(archive.exists())


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
                    'other_verdicts_accepted': {'keys': [list(JUDGE_CHANGED_KEY)], 'why': JUDGE_CHANGE_WHY},
                    'pair': {'stamps': list(STAMPS), 'compare': [str(pair / 'cmp-run1'), str(pair / 'cmp-run2')],
                             'coverage': [str(pair / 'coverage-run1.json'), str(pair / 'coverage-run2.json')]}}
        path = self.root / 'cycle.json'
        path.write_text(json.dumps(document), encoding='utf-8')
        config = load_config(path)
        self.assertEqual((config.out, config.decisions), (self.root / 'out', self.decisions))
        self.assertEqual((config.gameplay_db_workers, config.disk_limit_percent), (4, 97.0))
        skips = [part for step in REPLAY for part in ('--skip', step)]
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            self.assertEqual(main(['cycle', '--config', str(path), *skips]), 0)
        self.assertEqual(self.checkpoint()['count'], 14)
        self.assertIn('record scenarios matched by entry and label: 22, unmatched: 0\n', output.getvalue())
        self.assertIn('WARNING record verdicts not compared with the record: no scenario file 0, OTHER 1 '
                      f'({" | ".join(JUDGE_CHANGED_KEY)})\n', output.getvalue())
        document['pair']['stamps'] = list(STAMPS[:1])
        path.write_text(json.dumps(document), encoding='utf-8')
        with self.assertRaisesRegex(CycleError, 'pair.stamps'):
            load_config(path)


class PairIdentityTest(CycleCase):
    def cycle_file(self, **record) -> Path:
        pair = FIXTURES / 'final16'
        document = {'class_id': 23, 'name': 'final16', 'worktree': str(REPOSITORY), 'clauses': 'c.json', 'out': 'out',
                    'build': BUILD,
                    'record': {'name': 'final14', 'status': 's.json', 'manifest': 'm.json',
                               'compare': [str(FIXTURES / 'record' / 'cmp-run1'),
                                           str(FIXTURES / 'record' / 'cmp-run2')], **record},
                    'pair': {'stamps': [STAMPS[0], STAMPS[0]], 'compare': [str(pair / 'cmp-run1')] * 2}}
        path = self.root / 'cycle.json'
        path.write_text(json.dumps(document), encoding='utf-8')
        return path

    def test_an_empty_record_compare_is_refused(self):
        with self.assertRaisesRegex(CycleError, r'record.compare: a merged pair has 2 entries, found 0'):
            load_config(self.cycle_file(compare=[]))
        config = self.replay(record=Record('final14', FIXTURES / 'record-status.json', (), (),
                                           FIXTURES / 'record' / 'manifest.json'))
        with self.assertRaisesRegex(CycleError, 'record.compare: a merged pair has 2 entries, found 0'):
            run_cycle(config, REPLAY, FakeRunner(self.root))

    def test_a_pair_naming_one_run_twice_is_refused(self):
        config = load_config(self.cycle_file())
        with self.assertRaisesRegex(CycleError, 'pair.stamps: both entries name the same run'):
            run_cycle(config, REPLAY, FakeRunner(self.root))
        pair = FIXTURES / 'final16'
        for field, value in (('compare', (pair / 'cmp-run1',) * 2),
                             ('coverage', (pair / 'coverage-run1.json',) * 2)):
            with self.subTest(field=field):
                with self.assertRaisesRegex(CycleError, f'pair.{field}: both entries name the same run'):
                    run_cycle(self.replay(**{field: value}), REPLAY, FakeRunner(self.root))

    def test_a_restored_pair_naming_one_run_twice_is_refused(self):
        out = self.root / 'out'
        out.mkdir()
        run = {'stamp': STAMPS[0], 'results': str(self.root / STAMPS[0])}
        (out / cycle.PAIR_FILE).write_text(json.dumps({'runs': [run, run]}), encoding='utf-8')
        with self.assertRaisesRegex(CycleError, 'stamps: both entries name the same run'):
            run_cycle(self.replay(stamps=(), compare=()), REPLAY, FakeRunner(self.root))

    def test_an_unnormalised_path_naming_the_same_run_is_refused(self):
        path = self.cycle_file()
        document = json.loads(path.read_text(encoding='utf-8'))
        document['pair'] = {'stamps': list(STAMPS), 'compare': ['/tmp/pair/cmp', '/tmp/pair/../pair/cmp']}
        path.write_text(json.dumps(document), encoding='utf-8')
        with self.assertRaisesRegex(CycleError, 'pair.compare: both entries name the same run'):
            run_cycle(load_config(path), REPLAY, FakeRunner(self.root))

    def test_a_produced_pair_naming_one_run_twice_is_refused(self):
        runner = FakeRunner(self.root, stamps=(STAMPS[0], STAMPS[0]))
        with self.assertRaisesRegex(CycleError, 'runs: produced stamps: both entries name the same run'):
            run_cycle(self.config(), RUNS_ONLY, runner)
        self.assertFalse((self.root / 'out' / cycle.PAIR_FILE).exists())


if __name__ == '__main__':
    unittest.main()
