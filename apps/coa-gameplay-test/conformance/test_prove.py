from dataclasses import replace
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
from unittest import mock

from compare import BuildMismatch, ScenarioDrift, Verdict, write_verdicts
import prove
from pilot import hit_ratio_pilot
from prove import (DRIFT_EXIT, FAILURE_EXIT, FLIP_EXIT, MISSING_EXIT, OK_EXIT, Pilot, ProveSpec, RunTimeout, find_flips,
                   is_under, run_command, verify_command, verify_report)
from prove_ledger import ledger_coverage, ledger_evidence, ledger_rows

CLASS_FILE = {'class_id': 19, 'class_name': 'Templar', 'level': 60}
KEYS = ('scenario-a', 'scenario-b')


def verdict(label, status, scenario='scenario-a', detail=None):
    return Verdict(label, status, 1.0, 1.0, 1.0, 1.0, '', scenario, 1, 1, 'hit_mean', detail)


def row(label, spell=1000001):
    return {'spell': spell, 'clause': f'clause of {label}', 'labels': [label], 'kind': 'claim'}


class Workspace:
    def __init__(self, test: unittest.TestCase):
        self.root = Path(tempfile.mkdtemp())
        test.addCleanup(shutil.rmtree, self.root, True)
        self.worktree = self.root / 'worktree'
        self.worktree.mkdir()
        self.commands: list[list[str]] = []
        self.statuses: list[dict[str, str]] = []
        self.stages: dict = {'build': {'status': 'passed', 'seconds': 5.0}, 'gameplay': {'status': 'passed',
                                                                                          'seconds': 12.5}}
        self.timeout: float | None = None
        self.write_log = True
        self.write_report = True
        self.drift = False
        self.missing: list[list[str]] = []
        self.builds: list[str | None] = []
        self.mixed_builds = False
        self.details: dict[str, dict] = {}
        self.sized_with: list[dict] = []

    def generate(self, out: Path) -> Path:
        files = []
        for key in KEYS:
            (out / 'scenarios').mkdir(exist_ok=True)
            (out / 'scenarios' / f'{key}.json').write_text('{}', encoding='utf-8')
            files.append({'key': key, 'file': f'scenarios/{key}.json'})
        files.append({'key': 'no-scenario', 'file': None})
        manifest = {**CLASS_FILE, 'spell_dbc_sha256': 'f' * 64, 'scenarios': files}
        path = out / 'manifest.json'
        path.write_text(json.dumps(manifest), encoding='utf-8')
        return path

    def runner(self, command, timeout_s, log):
        self.commands.append(list(command))
        self.timeout = timeout_s
        if self.timeout_error:
            raise RunTimeout('too slow')
        number = len(self.commands)
        results = self.worktree / '.cache' / 'verify-all' / f'stamp-{number}'
        results.mkdir(parents=True)
        report = results / 'report.json'
        if self.write_report:
            report.write_text(json.dumps({'stages': self.stages}), encoding='utf-8')
        if self.write_log:
            log.write_text(f'build ok\nVERIFY ALL: INCOMPLETE {report}\n', encoding='utf-8')
        else:
            log.write_text('crashed\n', encoding='utf-8')
        return 3

    timeout_error = False

    def compare(self, manifest_path, results, directory):
        if self.drift:
            raise ScenarioDrift('scenario-a: hash changed')
        if self.mixed_builds:
            raise BuildMismatch('the results hold runs of 2 builds')
        number = int(results.name.split('-')[1])
        statuses = self.statuses[number - 1]
        manifest = json.loads(Path(manifest_path).read_text(encoding='utf-8'))
        build = self.builds[number - 1] if self.builds else None
        verdicts = [replace(verdict(label, status, detail=self.details.get(label)), build=build)
                    for label, status in statuses.items()]
        directory.mkdir(parents=True, exist_ok=True)
        write_verdicts(manifest, manifest_path, results, verdicts, directory)
        missing = self.missing[number - 1] if len(self.missing) >= number else []
        return len(KEYS) - len(missing), list(missing)

    def prove(self, rows=None, runs=2, build=False, enrich=None, annotate=None, out_name='proof',
              pilot=None) -> int:
        spec = ProveSpec(self.root / out_name, self.worktree, runs, build, 600000)
        return prove.prove(spec, self.generate, rows, enrich, annotate, runner=self.runner, compare=self.compare,
                           pilot=pilot)

    def pilot(self, trials: dict[str, int] | None = None) -> Pilot:
        def size(verdicts):
            sized = dict(trials or {})
            return sized, [{'label': label, 'pilot_status': next(v.status for v in verdicts if v.label == label),
                            'trials': count} for label, count in sized.items()]

        def sized(out, chosen):
            self.sized_with.append(dict(chosen))
            return self.generate(out)

        return Pilot(lambda out: None if trials is None else (out.mkdir(parents=True), self.generate(out))[1],
                     size, sized)

    def summary(self, out_name='proof') -> dict:
        return json.loads((self.root / out_name / 'summary.json').read_text(encoding='utf-8'))

    def fragment(self, out_name='proof') -> list:
        return json.loads((self.root / out_name / 'fragment.json').read_text(encoding='utf-8'))


class ProveRunTests(unittest.TestCase):
    def setUp(self):
        self.space = Workspace(self)

    def test_fragment_holds_only_labels_conformant_in_every_run(self):
        self.space.statuses = [{'a': 'ok', 'b': 'tolerated', 'c': 'ok'}, {'a': 'ok', 'b': 'tolerated', 'c': 'ok'}]
        rows = lambda manifest: [row('a'), row('b'), row('c')]
        self.assertEqual(self.space.prove(rows), OK_EXIT)
        self.assertEqual([entry['labels'] for entry in self.space.fragment()], [['a'], ['b'], ['c']])
        self.assertEqual(self.space.summary()['fragment']['rows'], 3)

    def test_seeded_alert_in_the_second_run_removes_the_row(self):
        self.space.statuses = [{'a': 'ok', 'b': 'ok'}, {'a': 'ok', 'b': 'alert'}]
        rows = lambda manifest: [row('a'), row('b')]
        self.assertEqual(self.space.prove(rows), FLIP_EXIT)
        self.assertEqual([entry['labels'] for entry in self.space.fragment()], [['a']])
        excluded = self.space.summary()['fragment']['excluded']
        self.assertEqual([entry['labels'] for entry in excluded], [['b']])

    def test_alert_in_both_runs_is_no_flip_and_no_row(self):
        self.space.statuses = [{'a': 'alert'}, {'a': 'alert'}]
        self.assertEqual(self.space.prove(lambda manifest: [row('a')]), OK_EXIT)
        self.assertEqual(self.space.fragment(), [])
        self.assertEqual(self.space.summary()['flips'], [])

    def test_ok_then_tolerated_is_not_a_flip(self):
        self.space.statuses = [{'a': 'ok'}, {'a': 'tolerated'}]
        self.assertEqual(self.space.prove(lambda manifest: [row('a')]), OK_EXIT)
        self.assertEqual(len(self.space.fragment()), 1)

    def test_flip_gives_exit_one_and_a_flips_entry_and_report(self):
        self.space.statuses = [{'a': 'ok', 'b': 'ok'}, {'a': 'alert', 'b': 'ok'}]
        self.assertEqual(self.space.prove(), FLIP_EXIT)
        summary = self.space.summary()
        self.assertEqual(summary['flips'], [{'label': 'a', 'check': 'hit_mean', 'scenario': 'scenario-a',
                                             'statuses': ['ok', 'alert']}])
        self.assertEqual(summary['exit'], FLIP_EXIT)
        self.assertTrue((self.space.root / 'proof' / 'flips' / 'impact.md').is_file())

    def test_ok_then_insufficient_trials_is_not_judged_and_no_flip(self):
        self.space.statuses = [{'a': 'ok', 'b': 'ok'}, {'a': 'insufficient_trials', 'b': 'ok'}]
        self.space.details = {'a': {'trials_needed': 237}}
        self.assertEqual(self.space.prove(lambda manifest: [row('a'), row('b')]), OK_EXIT)
        summary = self.space.summary()
        self.assertEqual(summary['flips'], [])
        self.assertEqual(summary['not_judged'], [{'label': 'a', 'check': 'hit_mean', 'scenario': 'scenario-a',
                                                  'statuses': ['ok', 'insufficient_trials'], 'trials_needed': 237}])
        self.assertEqual([entry['labels'] for entry in self.space.fragment()], [['b']])

    def test_insufficient_trials_against_an_alert_is_no_flip(self):
        self.space.statuses = [{'a': 'insufficient_trials'}, {'a': 'alert'}]
        self.assertEqual(self.space.prove(), OK_EXIT)
        self.assertEqual(self.space.summary()['not_judged'][0]['trials_needed'], None)

    def test_seeded_two_judged_verdicts_that_differ_beside_an_unjudged_one_flip(self):
        self.space.statuses = [{'a': 'ok'}, {'a': 'insufficient_trials'}, {'a': 'alert'}]
        self.assertEqual(self.space.prove(runs=3), FLIP_EXIT)
        self.assertEqual(self.space.summary()['flips'][0]['statuses'], ['ok', 'insufficient_trials', 'alert'])

    def test_insufficient_trials_against_a_missing_label_is_a_flip(self):
        self.space.statuses = [{'a': 'insufficient_trials'}, {}]
        self.assertEqual(self.space.prove(), FLIP_EXIT)

    def test_label_missing_in_one_run_is_a_flip(self):
        self.space.statuses = [{'a': 'ok'}, {}]
        self.assertEqual(self.space.prove(), FLIP_EXIT)
        self.assertEqual(self.space.summary()['flips'][0]['statuses'], ['ok', None])

    def test_build_stage_only_in_run_one(self):
        self.space.statuses = [{'a': 'ok'}] * 3
        self.space.prove(runs=3, build=True)
        stages = [command[command.index('--stages') + 1] for command in self.space.commands]
        self.assertEqual(stages, ['build,gameplay', 'gameplay', 'gameplay'])

    def test_no_build_without_the_flag(self):
        self.space.statuses = [{'a': 'ok'}] * 2
        self.space.prove()
        self.assertEqual({command[command.index('--stages') + 1] for command in self.space.commands}, {'gameplay'})

    def test_command_runs_every_scenario_file_with_ram_and_the_worktree(self):
        self.space.statuses = [{'a': 'ok'}] * 2
        self.space.prove()
        command = self.space.commands[0]
        self.assertEqual(command[:5], ['coa-verify', '--worktree', str(self.space.worktree), '--ram', '--stages'])
        files = command[command.index('--scenario') + 1:]
        self.assertEqual([Path(path).name for path in files], ['scenario-a.json', 'scenario-b.json'])
        self.assertTrue(all(Path(path).is_absolute() for path in files))
        self.assertNotIn('--jobs', command)

    def test_timeout_is_a_failure_with_no_fragment(self):
        self.space.timeout_error = True
        self.assertEqual(self.space.prove(), FAILURE_EXIT)
        summary = self.space.summary()
        self.assertIn('too slow', summary['failure'])
        self.assertFalse((self.space.root / 'proof' / 'fragment.json').exists())
        self.assertEqual(self.space.timeout, 600.0)

    def test_run_without_a_verify_line_fails(self):
        self.space.write_log = False
        self.assertEqual(self.space.prove(), FAILURE_EXIT)
        self.assertIn('VERIFY ALL', self.space.summary()['failure'])

    def test_run_without_a_report_file_fails(self):
        self.space.write_report = False
        self.assertEqual(self.space.prove(), FAILURE_EXIT)
        self.assertIn('does not exist', self.space.summary()['failure'])

    def test_failed_build_stage_stops_before_any_verdict(self):
        self.space.stages['build'] = {'status': 'failed', 'seconds': 1.0}
        self.assertEqual(self.space.prove(build=True), FAILURE_EXIT)
        self.assertIn('build stage is failed', self.space.summary()['failure'])
        self.assertEqual(len(self.space.commands), 1)

    def test_scenario_drift_has_its_own_exit(self):
        self.space.drift = True
        self.assertEqual(self.space.prove(), DRIFT_EXIT)
        self.assertIn('scenario drift', self.space.summary()['failure'])

    def test_runs_judged_on_different_builds_fail_the_proof(self):
        self.space.statuses = [{'a': 'ok'}, {'a': 'ok'}]
        self.space.builds = ['c' * 64, 'd' * 64]
        self.assertEqual(self.space.prove(lambda manifest: [row('a')]), FAILURE_EXIT)
        summary = self.space.summary()
        self.assertIn('a proof compares runs of one build', summary['failure'])
        self.assertEqual([run['build'] for run in summary['runs']], ['c' * 64, 'd' * 64])

    def test_runs_judged_on_one_build_prove(self):
        self.space.statuses = [{'a': 'ok'}, {'a': 'ok'}]
        self.space.builds = ['c' * 64, 'c' * 64]
        self.assertEqual(self.space.prove(lambda manifest: [row('a')]), OK_EXIT)

    def test_a_results_directory_of_two_builds_fails_the_run(self):
        self.space.statuses = [{'a': 'ok'}, {'a': 'ok'}]
        self.space.mixed_builds = True
        self.assertEqual(self.space.prove(), FAILURE_EXIT)
        self.assertIn('2 builds', self.space.summary()['failure'])

    def test_no_scenario_result_fails_the_run(self):
        self.space.statuses = [{}, {}]
        self.space.missing = [list(KEYS)]
        self.assertEqual(self.space.prove(), MISSING_EXIT)
        self.assertIn('2 of 2 scenarios produced no result', self.space.summary()['failure'])

    def test_seeded_one_missing_result_of_two_fails_and_names_the_scenario(self):
        self.space.statuses = [{'a': 'ok'}, {'a': 'ok'}]
        self.space.missing = [['scenario-b']]
        rows = lambda manifest: [row('a')]
        self.assertEqual(self.space.prove(rows), MISSING_EXIT)
        summary = self.space.summary()
        self.assertIn('1 of 2 scenarios produced no result', summary['failure'])
        self.assertEqual([entry['scenarios'] for entry in summary['missing_results']], [['scenario-b']])
        self.assertEqual(summary['failed_run']['missing_results'], ['scenario-b'])
        self.assertEqual(summary['fragment'], None)
        self.assertFalse((self.space.root / 'proof' / 'fragment.json').exists())
        self.assertEqual(len(self.space.commands), 1)

    def test_seeded_missing_result_in_the_second_run_only_fails(self):
        self.space.statuses = [{'a': 'ok'}, {'a': 'ok'}]
        self.space.missing = [[], ['scenario-a']]
        self.assertEqual(self.space.prove(lambda manifest: [row('a')]), MISSING_EXIT)
        summary = self.space.summary()
        self.assertEqual(summary['missing_results'][0]['scenarios'], ['scenario-a'])
        self.assertTrue(summary['missing_results'][0]['directory'].endswith('run2'))
        self.assertEqual([run['scenarios_without_result'] for run in summary['runs']], [0])

    def test_every_result_present_records_no_missing_scenario(self):
        self.space.statuses = [{'a': 'ok'}, {'a': 'ok'}]
        self.assertEqual(self.space.prove(), OK_EXIT)
        summary = self.space.summary()
        self.assertEqual(summary['missing_results'], [])
        self.assertEqual([run['missing_results'] for run in summary['runs']], [[], []])

    def test_compare_run_names_the_scenarios_without_a_result(self):
        comparison = mock.Mock(runs={'scenario-a': object()}, missing=['scenario-b'], verdicts=[])
        with mock.patch('prove.evaluate', return_value=comparison), mock.patch('prove.write_outputs'):
            self.assertEqual(prove.compare_run(Path('m.json'), Path('r'), Path('d')), (1, ['scenario-b']))

    def test_summary_records_gameplay_seconds_counts_and_statuses_per_run(self):
        self.space.statuses = [{'a': 'ok', 'b': 'alert'}, {'a': 'ok', 'b': 'alert'}]
        self.space.prove()
        runs = self.space.summary()['runs']
        self.assertEqual([run['gameplay_seconds'] for run in runs], [12.5, 12.5])
        self.assertEqual([run['counts']['ok'] for run in runs], [1, 1])
        self.assertEqual([run['counts']['alert'] for run in runs], [1, 1])
        self.assertEqual(runs[0]['verify_status'], 'incomplete')

    def test_enrich_and_annotate_reach_fragment_and_summary(self):
        self.space.statuses = [{'a': 'ok'}] * 2
        enrich = lambda rows, outcomes: [{**entry, 'evidence': f'runs {len(outcomes)}'} for entry in rows]
        annotate = lambda outcomes: {'seen': [outcome.number for outcome in outcomes]}
        self.space.prove(lambda manifest: [row('a')], enrich=enrich, annotate=annotate)
        self.assertEqual(self.space.fragment()[0]['evidence'], 'runs 2')
        self.assertEqual(self.space.summary()['seen'], [1, 2])

    def test_fewer_than_two_runs_is_refused(self):
        with self.assertRaisesRegex(ValueError, 'at least 2 runs'):
            self.space.prove(runs=1)

    def test_a_used_output_directory_is_refused(self):
        (self.space.root / 'proof').mkdir()
        (self.space.root / 'proof' / 'old.json').write_text('{}', encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'not empty'):
            self.space.prove()

    def test_a_manifest_without_scenario_files_fails(self):
        def generate(out):
            path = out / 'manifest.json'
            path.write_text(json.dumps({**CLASS_FILE, 'scenarios': [{'key': 'k', 'file': None}]}), encoding='utf-8')
            return path
        spec = ProveSpec(self.space.root / 'proof', self.space.worktree)
        self.assertEqual(prove.prove(spec, generate, runner=self.space.runner, compare=self.space.compare),
                         FAILURE_EXIT)
        self.assertEqual(self.space.commands, [])


class ProveHelperTests(unittest.TestCase):
    def test_verify_command_has_no_jobs_and_one_scenario_flag(self):
        spec = ProveSpec(Path('/o'), Path('/w'), 2, True)
        command = verify_command(spec, 1, [Path('/o/a.json'), Path('/o/b.json')])
        self.assertEqual(command, ['coa-verify', '--worktree', '/w', '--ram', '--stages', 'build,gameplay',
                                   '--scenario', '/o/a.json', '/o/b.json'])
        self.assertEqual(verify_command(spec, 2, [Path('/o/a.json')])[5], 'gameplay')

    def test_verify_report_reads_the_last_line(self):
        directory = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, directory, True)
        log = directory / 'verify.log'
        log.write_text('VERIFY ALL: FAILED /a/report.json\nmore\nVERIFY ALL: PASSED /b/report.json\n',
                       encoding='utf-8')
        self.assertEqual(verify_report(log), ('passed', Path('/b/report.json')))

    def test_find_flips_compares_status_classes(self):
        from prove import RunOutcome
        first = RunOutcome(1, Path('a'), Path('a'), {}, [verdict('x', 'ok'), verdict('y', 'unmeasured')], {})
        second = RunOutcome(2, Path('b'), Path('b'), {}, [verdict('x', 'closed'), verdict('y', 'alert')], {})
        self.assertEqual([flip['label'] for flip in find_flips([first, second])], ['y'])

    def test_is_under_matches_a_root_and_its_descendants_only(self):
        root = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, root, True)
        self.assertTrue(is_under(root / 'a' / 'b', [root]))
        self.assertTrue(is_under(root, [root]))
        self.assertFalse(is_under(Path(str(root) + '-other'), [root]))


class RunCommandTests(unittest.TestCase):
    def setUp(self):
        self.directory = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.directory, True)

    def test_returns_the_exit_status_and_writes_the_log(self):
        log = self.directory / 'log'
        code = run_command([sys.executable, '-c', 'import sys; print("hello"); sys.exit(3)'], 30, log)
        self.assertEqual(code, 3)
        self.assertEqual(log.read_text(encoding='utf-8').strip(), 'hello')

    def test_timeout_stops_the_process_and_raises(self):
        marker = self.directory / 'finished'
        script = f'import time, pathlib; time.sleep(30); pathlib.Path({str(marker)!r}).write_text("x")'
        with self.assertRaises(RunTimeout):
            run_command([sys.executable, '-c', script], 0.5, self.directory / 'log')
        self.assertFalse(marker.exists())



class PilotRunTests(unittest.TestCase):
    def setUp(self):
        self.space = Workspace(self)

    def test_pilot_runs_first_with_the_build_and_sizes_the_judged_runs(self):
        self.space.statuses = [{'a': 'insufficient_trials'}, {'a': 'ok'}, {'a': 'ok'}]
        code = self.space.prove(lambda manifest: [row('a')], build=True, pilot=self.space.pilot({'a': 394}))
        self.assertEqual(code, OK_EXIT)
        self.assertEqual([command[5] for command in self.space.commands], ['build,gameplay', 'gameplay', 'gameplay'])
        self.assertEqual(self.space.sized_with, [{'a': 394}])
        summary = self.space.summary()
        self.assertEqual(summary['sizing']['trials'], {'a': 394})
        self.assertFalse(summary['sizing']['judged'])
        self.assertEqual(summary['sizing']['labels'][0]['pilot_status'], 'insufficient_trials')
        self.assertEqual([run['run'] for run in summary['runs']], [1, 2])
        self.assertEqual(summary['not_judged'], [])
        self.assertEqual(len(self.space.fragment()), 1)
        self.assertTrue((self.space.root / 'proof' / 'pilot' / 'run1' / 'verify.log').is_file())

    def test_seeded_pilot_alert_neither_flips_nor_removes_the_row(self):
        self.space.statuses = [{'a': 'alert'}, {'a': 'ok'}, {'a': 'ok'}]
        self.assertEqual(self.space.prove(lambda manifest: [row('a')], pilot=self.space.pilot({'a': 40})), OK_EXIT)
        self.assertEqual(self.space.summary()['flips'], [])
        self.assertEqual(len(self.space.fragment()), 1)

    def test_a_pilot_with_nothing_to_size_runs_no_pilot(self):
        self.space.statuses = [{'a': 'ok'}, {'a': 'ok'}]
        self.assertEqual(self.space.prove(pilot=self.space.pilot(None)), OK_EXIT)
        self.assertEqual(len(self.space.commands), 2)
        self.assertIsNone(self.space.summary()['sizing'])
        self.assertEqual(self.space.sized_with, [])

    def test_seeded_missing_pilot_result_fails_before_any_judged_run(self):
        self.space.statuses = [{'a': 'ok'}] * 3
        self.space.missing = [['scenario-a']]
        self.assertEqual(self.space.prove(pilot=self.space.pilot({'a': 40})), MISSING_EXIT)
        summary = self.space.summary()
        self.assertTrue(summary['missing_results'][0]['directory'].endswith('pilot/run1'))
        self.assertEqual(summary['runs'], [])
        self.assertEqual(len(self.space.commands), 1)

    def test_judged_runs_of_another_build_than_the_pilot_fail(self):
        self.space.statuses = [{'a': 'ok'}] * 3
        self.space.builds = ['x', 'y', 'y']
        self.assertEqual(self.space.prove(pilot=self.space.pilot({'a': 40})), FAILURE_EXIT)
        self.assertIn('the pilot', self.space.summary()['failure'])


LEDGER_SHA = 'f' * 64
LEDGER_BUILD = 'c' * 64


def claim(spell, *labels):
    return {'spell': spell, 'clause': f'clause of {spell}', 'labels': list(labels), 'kind': 'claim'}


def manifest_with(*labels):
    return {'scenarios': [{'key': 'scenario-a', 'file': 'scenarios/scenario-a.json',
                           'expectations': [{'label': label} for label in labels]}]}


class LedgerHookTests(unittest.TestCase):
    def setUp(self):
        self.space = Workspace(self)
        self.space.builds = [LEDGER_BUILD, LEDGER_BUILD]
        patcher = mock.patch('profile.server_spell_dbc_sha256', return_value=LEDGER_SHA)
        patcher.start()
        self.addCleanup(patcher.stop)

    def test_rows_hold_the_claims_whose_labels_all_run_with_their_ordinals_resolved(self):
        ledger = [claim(1, '1 effect_value e0'), claim(2, '2 hit_mean', '2 effect_value #0'), claim(3, '3 hit_mean'),
                  {'spell': 4, 'clause': 'Level 10 Passive', 'kind': 'no_claim', 'labels': ['4 hit_mean']}]
        rows = ledger_rows(ledger)(manifest_with('1 effect_value e0 #0', '1 effect_value e0 #1', '2 hit_mean',
                                                 '4 hit_mean'))
        self.assertEqual([(row['spell'], row['labels']) for row in rows],
                         [(1, ['1 effect_value e0 #0', '1 effect_value e0 #1'])])

    def test_seeded_missing_label_keeps_the_claim_out(self):
        ledger = [claim(2, '2 hit_mean', '2 effect_value #0')]
        self.assertEqual(len(ledger_rows(ledger)(manifest_with('2 hit_mean', '2 effect_value #0'))), 1)
        self.assertEqual(ledger_rows(ledger)(manifest_with('2 hit_mean')), [])

    def test_fragment_rows_carry_behaviour_only_when_every_run_shows_it(self):
        self.space.statuses = [{'a': 'ok', 'b': 'ok'}, {'a': 'ok', 'b': 'ok'}]
        rows = lambda manifest: [claim(1, 'a'), claim(2, 'b')]
        self.assertEqual(self.space.prove(rows, enrich=ledger_evidence), OK_EXIT)
        self.assertEqual([entry['evidence'] for entry in self.space.fragment()], ['behaviour', 'behaviour'])
        self.assertEqual({entry['spell_dbc_sha256'] for entry in self.space.fragment()}, {LEDGER_SHA})

    def test_seeded_readback_in_one_run_makes_the_row_data(self):
        self.space.statuses = [{'a': 'ok'}, {'a': 'ok'}]
        readback = {'evidence_runs': 0}

        def evidence(verdict, *args, **kwargs):
            readback['evidence_runs'] += 1
            return 'data' if readback['evidence_runs'] == 2 else 'behaviour'

        with mock.patch('coverage.verdict_evidence', side_effect=evidence):
            self.assertEqual(self.space.prove(lambda manifest: [claim(1, 'a')], enrich=ledger_evidence), OK_EXIT)
        self.assertEqual([entry['evidence'] for entry in self.space.fragment()], ['data'])

    def test_summary_reports_the_ledger_coverage_of_each_run(self):
        self.space.statuses = [{'a': 'ok', 'b': 'alert'}, {'a': 'ok', 'b': 'ok'}]
        ledger = [claim(1, 'a'), claim(2, 'b'), claim(3, 'c')]
        self.assertEqual(self.space.prove(annotate=ledger_coverage(ledger)), FLIP_EXIT)
        figures = self.space.summary()['coverage']
        self.assertEqual([(figure['proven'], figure['behaviour'], figure['total']) for figure in figures],
                         [(1, 1, 3), (2, 2, 3)])

    def test_verdicts_without_a_build_give_no_coverage(self):
        self.space.builds = []
        self.space.statuses = [{'a': 'ok'}, {'a': 'ok'}]
        with self.assertRaisesRegex(ValueError, 'no single build'):
            self.space.prove(annotate=ledger_coverage([claim(1, 'a')]))


def declared(spell, *claims):
    return {'spell': spell, 'clause': f'clause of {spell}', 'kind': 'claim',
            'claims': [{'claim': words, 'labels': list(labels)} for words, *labels in claims]}


class DeclaredClaimRowTests(unittest.TestCase):
    def setUp(self):
        self.space = Workspace(self)
        self.space.builds = [LEDGER_BUILD, LEDGER_BUILD]
        patcher = mock.patch('profile.server_spell_dbc_sha256', return_value=LEDGER_SHA)
        patcher.start()
        self.addCleanup(patcher.stop)

    def test_a_declared_clause_whose_claims_all_run_is_one_row(self):
        ledger = [declared(1, ('damage dealt', '1 effect_value e0'), ('movement speed', '1 e1 run_speed_rate'))]
        rows = ledger_rows(ledger)(manifest_with('1 effect_value e0 #0', '1 e1 run_speed_rate'))
        self.assertEqual(len(rows), 1)
        self.assertEqual([claim['labels'] for claim in rows[0]['claims']],
                         [['1 effect_value e0 #0'], ['1 e1 run_speed_rate']])

    def test_seeded_claim_without_a_running_label_gives_per_claim_rows_only(self):
        ledger = [declared(1, ('damage dealt', '1 effect_value e0'), ('movement speed', '1 e1 run_speed_rate'))]
        rows = ledger_rows(ledger)(manifest_with('1 effect_value e0 #0'))
        self.assertEqual([(row['claim'], row['labels']) for row in rows], [('damage dealt', ['1 effect_value e0 #0'])])
        self.assertNotIn('claims', rows[0])

    def test_a_declared_claim_without_labels_gives_no_row_of_its_own(self):
        ledger = [declared(1, ('damage dealt', '1 effect_value e0'), ('movement speed',))]
        rows = ledger_rows(ledger)(manifest_with('1 effect_value e0 #0'))
        self.assertEqual([row['claim'] for row in rows], ['damage dealt'])

    def test_a_ledger_with_malformed_claims_is_refused(self):
        with self.assertRaisesRegex(ValueError, 'at least 2'):
            ledger_rows([declared(1, ('damage dealt', 'a'))])

    def test_a_proven_declared_clause_is_one_fragment_row_with_its_claims(self):
        self.space.statuses = [{'a': 'ok', 'b': 'ok'}, {'a': 'ok', 'b': 'ok'}]
        rows = lambda manifest: [declared(1, ('first', 'a'), ('second', 'b'))]
        self.assertEqual(self.space.prove(rows, enrich=ledger_evidence), OK_EXIT)
        fragment = self.space.fragment()
        self.assertEqual(len(fragment), 1)
        self.assertEqual([claim['evidence'] for claim in fragment[0]['claims']], ['behaviour', 'behaviour'])
        self.assertEqual(fragment[0]['evidence'], 'behaviour')

    def test_seeded_alert_on_one_claim_keeps_the_declared_clause_out_of_the_fragment(self):
        self.space.statuses = [{'a': 'ok', 'b': 'alert'}, {'a': 'ok', 'b': 'alert'}]
        rows = lambda manifest: [declared(1, ('first', 'a'), ('second', 'b'))]
        self.space.prove(rows, enrich=ledger_evidence)
        self.assertEqual(self.space.fragment(), [])
        self.assertEqual(self.space.summary()['fragment']['excluded'][0]['labels'], ['a', 'b'])

    def test_a_per_claim_row_keeps_its_claim_words_in_the_fragment(self):
        self.space.statuses = [{'a': 'ok'}, {'a': 'ok'}]
        ledger = [declared(1, ('first', 'a'), ('second', 'b'))]
        rows = lambda manifest: ledger_rows(ledger)(manifest_with('a'))
        self.assertEqual(self.space.prove(rows, enrich=ledger_evidence), OK_EXIT)
        self.assertEqual([(row['claim'], row['labels'], row['evidence']) for row in self.space.fragment()],
                         [('first', ['a'], 'behaviour')])

    def test_seeded_partial_proof_leaves_the_declared_clause_unproven_in_the_coverage(self):
        self.space.statuses = [{'a': 'ok'}, {'a': 'ok'}]
        ledger = [declared(1, ('first', 'a'), ('second', 'b')), claim(2, 'a')]
        self.assertEqual(self.space.prove(annotate=ledger_coverage(ledger)), OK_EXIT)
        self.assertEqual([(figure['proven'], figure['total']) for figure in self.space.summary()['coverage']],
                         [(1, 2), (1, 2)])


if __name__ == '__main__':
    unittest.main()


class HitRatioPilotTest(unittest.TestCase):
    def verdict(self, label, status='insufficient_trials', **detail):
        return Verdict(label, status, 19.0, 20.0, 18.0, 22.0, 'pilot', 'scenario', 1, 1, 'behaviour_hit_ratio',
                       detail=detail or None)

    def made(self):
        calls = []

        def make(out, trials):
            calls.append((Path(out), dict(trials)))
            return Path(out) / 'manifest.json'
        return calls, make

    def test_no_hit_ratio_entry_gives_no_pilot(self):
        calls, make = self.made()
        self.assertIsNone(hit_ratio_pilot([], make, make))

    def test_the_pilot_generates_every_label_at_the_pilot_trials(self):
        calls, make = self.made()
        pilot = hit_ratio_pilot(['a', 'b'], make, make, pilot_trials=20)
        pilot.generate(Path('/tmp/pilot'))
        self.assertEqual(calls, [(Path('/tmp/pilot'), {'a': 20, 'b': 20})])

    def test_sizing_takes_the_sized_trials_capped_at_the_scenario_limit(self):
        calls, make = self.made()
        pilot = hit_ratio_pilot(['a', 'b', 'c', 'd'], make, make, pilot_trials=20)
        trials, records = pilot.size([self.verdict('a', sized_trials=60, trial_limit=111),
                                      self.verdict('b', sized_trials=300, trial_limit=111),
                                      self.verdict('c', status='unmeasured')])
        self.assertEqual(trials, {'a': 60, 'b': 111})
        self.assertEqual([record.get('capped') for record in records], [False, True, None, None])
        self.assertIn('reads no interval', records[2]['reason'])
        self.assertIn('holds no verdict', records[3]['reason'])
        pilot.sized(Path('/tmp/out'), trials)
        self.assertEqual(calls[-1], (Path('/tmp/out'), {'a': 60, 'b': 111}))

    def test_a_sized_count_below_the_pilot_keeps_the_pilot_trials(self):
        calls, make = self.made()
        pilot = hit_ratio_pilot(['a'], make, make, pilot_trials=20)
        trials, _ = pilot.size([self.verdict('a', status='ok', sized_trials=5, trial_limit=111)])
        self.assertEqual(trials, {'a': 20})
