import copy
from contextlib import redirect_stderr, redirect_stdout
import hashlib
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch

import catalog
import run
import verification
import workflow


class VerificationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.path = Path(self.temp.name)
        self.definitions = self.path / 'definitions'
        (self.definitions / 'scenarios').mkdir(parents=True)
        self.scenario = {
            'schema': 1, 'name': 'Measured healing', 'contract': 'Measured healing is 20% of a 100-point hit',
            'players': [{'id': 'caster', 'race': 1, 'class': 8}],
            'steps': [{'action': 'snapshot', 'actor': 'caster', 'metric': 'health', 'save_as': 'healed'},
                      {'action': 'assert', 'actor': 'caster', 'metric': 'health', 'min': 1}]}
        self.write(self.definitions / 'scenarios' / 'measured.json', self.scenario)
        self.checks = {'schema': 1, 'checks': [
            {'script': 'check_healing.py', 'scenarios': ['measured'], 'args': []}]}
        self.write(self.definitions / 'checks.json', self.checks)
        (self.definitions / 'check_healing.py').write_text(
            'import json, sys\nfrom pathlib import Path\n'
            'r=json.loads((Path(sys.argv[1])/"result.json").read_text())\n'
            'assert float(r["steps"][0]["actual"]) == 20, "Incorrect copied heal"\n')
        self.folder = self.bundle('run-one', 20)

    def tearDown(self):
        self.temp.cleanup()

    def write(self, path, data):
        path.write_text(json.dumps(data, indent=2) + '\n')

    def bundle(self, name, actual, scenario=None):
        scenario = scenario or self.scenario
        folder = self.path / name
        folder.mkdir()
        self.write(folder / 'scenario.json', scenario)
        self.write(folder / 'summary.json', {
            'status': 'passed', 'run_id': 'abc123', 'scenario': scenario['name'],
            'binary_sha256': 'a' * 64,
            'scenario_sha256': hashlib.sha256((folder / 'scenario.json').read_bytes()).hexdigest()})
        steps = []
        for index, step in enumerate(scenario['steps']):
            record = {'index': index, 'action': step['action'], 'status': 'completed',
                      'label': step.get('label', step['action'])}
            if step['action'] == 'snapshot':
                record['actual'] = actual[step['save_as']] if isinstance(actual, dict) else actual
            elif step['action'] == 'assert':
                record.update(status='passed', actual=step.get('equals', step.get('min', step.get('max', 100))))
            steps.append(record)
        self.write(folder / 'result.json', {
            'schema': 1, 'status': 'passed', 'run_id': 'abc123', 'scenario': scenario['name'],
            'execution': 'socketless-session-handlers', 'completed_steps': len(steps),
            'assertions': sum(step['action'] == 'assert' for step in steps), 'steps': steps})
        return folder

    def verify(self, *folders):
        return verification.verify(list(folders or [self.folder]), self.definitions)

    def workflow(self, native, scenario=None, native_only=False):
        self.stdout, self.stderr = io.StringIO(), io.StringIO()
        with redirect_stderr(self.stderr), redirect_stdout(self.stdout):
            return workflow.run_registered(SimpleNamespace(output=None, native_only=native_only),
                                           scenario or self.scenario, native, directory=self.definitions)

    def test_correct_observation_passes_registered_check(self):
        result = self.verify()
        self.assertEqual(result['status'], 'passed')
        self.assertEqual(len(result['checks']), 1)

    def test_native_pass_with_incorrect_healing_fails_even_when_python_optimization_is_set(self):
        wrong = self.bundle('wrong', 10)
        with patch.dict(os.environ, {'PYTHONOPTIMIZE': '1'}):
            result = self.verify(wrong)
        self.assertEqual(result['status'], 'failed')
        self.assertIn('Incorrect copied heal', result['checks'][0]['output'])

    def test_replenishment_detects_duplicate_scaling_wrong_recipient_and_expiry_failure(self):
        scenario = catalog.read_json(catalog.DIRECTORY / 'scenarios/ascension-replenishment.json')
        values = {'primalist_max_mana': 1000, 'ally_max_mana': 2000,
                  'primalist_first': 50, 'primalist_total': 150, 'ally_first': 100, 'ally_total': 300}
        good = self.bundle('replenishment', values, scenario)
        self.assertEqual(verification.verify([good])['status'], 'passed')
        for name, changes in [('double-scaling', {'primalist_first': 100, 'primalist_total': 300}),
                              ('wrong-recipient', {'ally_first': 50, 'ally_total': 150})]:
            with self.subTest(mistake=name):
                wrong = self.bundle(name, {**values, **changes}, scenario)
                result = verification.verify([wrong])
                self.assertEqual(result['status'], 'failed')
                self.assertEqual(result['checks'][0]['status'], 'failed')
        report = catalog.read_json(good / 'result.json')
        report['steps'][-1]['actual'] = 1
        self.write(good / 'result.json', report)
        result = verification.verify([good])
        self.assertEqual(result['status'], 'failed')
        self.assertEqual(result['checks'][0]['status'], 'blocked')

    def test_stale_scenario_is_rejected_before_checker(self):
        changed = copy.deepcopy(self.scenario)
        changed['contract'] = 'A different expectation'
        self.write(self.definitions / 'scenarios' / 'measured.json', changed)
        result = self.verify()
        self.assertEqual(result['status'], 'failed')
        self.assertEqual(result['checks'], [])

    def test_missing_companion_cannot_pass(self):
        other = copy.deepcopy(self.scenario)
        other['name'] = 'Companion'
        self.write(self.definitions / 'scenarios' / 'other.json', other)
        self.checks['checks'][0]['scenarios'].append('other')
        self.write(self.definitions / 'checks.json', self.checks)
        result = self.verify()
        self.assertEqual(result['status'], 'failed')
        self.assertEqual(result['checks'][0]['status'], 'blocked')
        self.assertIn('other', result['checks'][0]['message'])
        self.assertEqual(result['required_scenarios'], ['measured', 'other'])

    def test_missing_evidence_failed_cleanup_and_wrong_hash_cannot_pass(self):
        for changes in [{'status': 'failed'}, {'cleanup_failed': ['owned_test_db']},
                        {'scenario_sha256': '0' * 64}, {'run_id': 'wrong'}, {'binary_sha256': ''}]:
            summary = catalog.read_json(self.folder / 'summary.json')
            original = copy.deepcopy(summary)
            summary.update(changes)
            self.write(self.folder / 'summary.json', summary)
            with self.subTest(changes=changes):
                self.assertEqual(self.verify()['status'], 'failed')
            self.write(self.folder / 'summary.json', original)
        report = catalog.read_json(self.folder / 'result.json')
        report['steps'].pop()
        self.write(self.folder / 'result.json', report)
        self.assertEqual(self.verify()['status'], 'failed')

    def test_false_assertion_pass_flag_does_not_override_actual_number(self):
        report = catalog.read_json(self.folder / 'result.json')
        report['steps'][1]['actual'] = 0
        self.write(self.folder / 'result.json', report)
        self.assertEqual(self.verify()['status'], 'failed')

    def test_empty_and_duplicate_results_cannot_pass(self):
        self.assertEqual(verification.verify([], self.definitions)['status'], 'failed')
        self.assertEqual(self.verify(self.folder, self.folder)['status'], 'failed')

    def test_catalog_derives_spell_links_and_enforces_checker_paths(self):
        scenario = copy.deepcopy(self.scenario)
        scenario['steps'].insert(0, {'action': 'learn', 'actor': 'caster', 'spell': 116})
        self.write(self.definitions / 'scenarios' / 'measured.json', scenario)
        rows = catalog.catalog(self.definitions)
        self.assertEqual(catalog.select(rows, spell=116)[0]['id'], 'measured')
        self.checks['checks'][0]['script'] = '../check_healing.py'
        self.write(self.definitions / 'checks.json', self.checks)
        with self.assertRaises(ValueError):
            catalog.bindings(self.definitions)

    def test_companion_closure(self):
        checks = [{'scenarios': ['a', 'b']}, {'scenarios': ['b', 'c']}]
        self.assertEqual(catalog.companion_cases(['a'], checks), ['a', 'b', 'c'])

    def test_unregistered_checker_blocks_run_before_native_execution(self):
        (self.definitions / 'check_forgotten.py').write_text('raise AssertionError("Must run")\n')
        native = Mock()
        with self.assertRaisesRegex(ValueError, 'Unregistered result checkers'):
            self.workflow(native)
        native.assert_not_called()

    def test_modified_scenario_requires_explicit_native_only_mode(self):
        changed = copy.deepcopy(self.scenario)
        changed['contract'] = 'Exploratory measurement'
        native = Mock(return_value=0)
        with self.assertRaisesRegex(ValueError, '--native-only'):
            self.workflow(native, changed)
        native.assert_not_called()
        self.assertEqual(self.workflow(native, changed, native_only=True), 0)
        native.assert_called_once()
        self.assertIn('NATIVE ONLY', self.stdout.getvalue())
        self.assertNotIn('VERIFICATION PASSED', self.stdout.getvalue())

    def test_invalid_companion_is_rejected_before_any_native_execution(self):
        other = copy.deepcopy(self.scenario)
        other['name'] = 'Invalid companion'
        other['steps'][0]['action'] = 'unsupported'
        self.write(self.definitions / 'scenarios' / 'other.json', other)
        self.checks['checks'][0]['scenarios'].append('other')
        self.write(self.definitions / 'checks.json', self.checks)
        native = Mock()
        with self.assertRaises(ValueError):
            self.workflow(native)
        native.assert_not_called()

    def test_checker_timeout_and_startup_error_are_failed_check_records(self):
        for error in [subprocess.TimeoutExpired('checker', 60), OSError('Cannot start checker')]:
            with self.subTest(error=error), patch.object(verification.subprocess, 'run', side_effect=error):
                result = self.verify()
            self.assertEqual(result['status'], 'failed')
            self.assertEqual(result['checks'][0]['status'], 'failed')
            self.assertIn(str(error), result['checks'][0]['message'])

    def test_quest_lookup_and_list_contracts(self):
        definition = copy.deepcopy(self.scenario)
        definition['contract'] = ['Quest reward rule', 'Preserve unrelated spells']
        definition['steps'].insert(0, {'action': 'reward_quest', 'actor': 'caster', 'quest': 7})
        self.write(self.definitions / 'scenarios' / 'measured.json', definition)
        rows = catalog.catalog(self.definitions)
        found = catalog.select(rows, query='reward rule', quest=7)
        self.assertEqual(len(found), 1)
        self.assertEqual(found[0]['entities']['quest'], [7])
        self.assertEqual(catalog.select(rows, spell=7), [])

    def test_registered_workflow_propagates_postcheck_failure(self):
        wrong = self.bundle('incorrect-native-pass', 10)
        def native(args, scenario):
            args.result_directory = wrong
            return 0
        result = self.workflow(native)
        self.assertEqual(result, 1)
        self.assertEqual(catalog.read_json(wrong / 'verification.json')['status'], 'failed')
        self.assertNotIn('VERIFICATION PASSED', self.stdout.getvalue())

    def test_native_failure_still_writes_combined_outcome_and_blocks_checker(self):
        summary = catalog.read_json(self.folder / 'summary.json')
        summary.update(status='failed', cleanup_failed=['owned_test_db'])
        self.write(self.folder / 'summary.json', summary)
        def native(args, scenario):
            args.result_directory = self.folder
            return 1
        self.assertEqual(self.workflow(native), 1)
        result = catalog.read_json(self.folder / 'verification.json')
        self.assertEqual(result['status'], 'failed')
        self.assertEqual(result['checks'][0]['status'], 'blocked')
        self.assertIn('VERIFICATION FAILED', self.stdout.getvalue())

    def test_preflight_exception_reports_combined_failure_without_a_result_directory(self):
        self.assertEqual(self.workflow(Mock(side_effect=OSError('Missing executable'))), 1)
        self.assertIn('VERIFICATION FAILED', self.stdout.getvalue())
        self.assertIn('Missing executable', self.stderr.getvalue())

    def test_native_nonzero_cannot_pass_even_with_a_passing_bundle(self):
        def native(args, scenario):
            args.result_directory = self.folder
            return 9
        self.assertEqual(self.workflow(native), 1)
        self.assertEqual(catalog.read_json(self.folder / 'verification.json')['status'], 'failed')

    def test_companion_workflow_executes_both_required_scenarios(self):
        calls = []
        other = copy.deepcopy(self.scenario)
        other['name'] = 'Other'
        self.write(self.definitions / 'scenarios' / 'other.json', other)
        self.checks['checks'][0]['scenarios'].append('other')
        self.write(self.definitions / 'checks.json', self.checks)
        other_folder = self.bundle('companion', 20, other)
        def native(args, scenario):
            calls.append(scenario['name'])
            args.result_directory = self.folder if scenario == self.scenario else other_folder
            return 0
        self.assertEqual(self.workflow(native), 0)
        self.assertEqual(calls, ['Measured healing', 'Other'])
        result = catalog.read_json(self.folder / 'verification.json')
        self.assertEqual(result['scenarios'], ['measured', 'other'])
        self.assertEqual(len(result['checks']), 1)

        calls.clear()
        def failing_native(args, scenario):
            calls.append(scenario['name'])
            args.result_directory = self.folder
            return 1
        self.assertEqual(self.workflow(failing_native), 1)
        self.assertEqual(calls, ['Measured healing'])
        result = catalog.read_json(self.folder / 'verification.json')
        self.assertEqual(result['required_scenarios'], ['measured', 'other'])
        self.assertEqual(result['checks'][0]['status'], 'blocked')

    def test_real_primalist_bindings_reject_incorrect_conversion_values(self):
        script = 'check_primalist_native_conversions.py'
        checks = [check for check in catalog.bindings() if check['script'] == script]
        self.assertEqual({(tuple(c['scenarios']), tuple(c['args'])) for c in checks}, {
            (('primalist-everlasting-rage',), ('everlasting',)), (('primalist-king-mountain',), ('king',))})
        shutil.copyfile(catalog.DIRECTORY / script, self.definitions / script)
        self.checks['checks'].extend(checks)
        self.write(self.definitions / 'checks.json', self.checks)
        for check in checks:
            source = catalog.DIRECTORY / 'scenarios' / (check['scenarios'][0] + '.json')
            shutil.copyfile(source, self.definitions / 'scenarios' / source.name)
        for check in checks:
            case = check['scenarios'][0]
            scenario = catalog.read_json(self.definitions / 'scenarios' / (case + '.json'))
            values = {}
            if check['args'] == ['everlasting']:
                for rank in ['first', 'highest']:
                    for phase, duration, interval in [('baseline', 12000, 2000), ('talented', 18000, 1800),
                                                      ('removed', 12000, 2000)]:
                        values.update({f'{rank}_{phase}_duration': duration, f'{rank}_{phase}_interval': interval,
                                       f'{rank}_{phase}_hit_before': 0})
                corrupt = {'first_talented_duration': 12000, 'highest_talented_interval': 2000,
                           'first_removed_interval': 1800}
            else:
                observations = [('baseline', 200, 300, 0, 1000, 0), ('learned', 200, 300, 30, 1090, 1),
                                ('strength', 300, 300, 45, 1290, 1), ('stamina', 300, 400, 45, 1320, 1),
                                ('removed', 300, 400, 0, 1200, 0)]
                for phase, strength, stamina, rating, ap, linked in observations:
                    values.update({f'{phase}_stat_0': strength, f'{phase}_stat_2': stamina,
                                   f'{phase}_ap': ap, f'{phase}_linked': linked})
                    values.update({f'{phase}_rating_{key}': 10 + rating for key in [2, 3, 17, 18, 19]})
                corrupt = {'learned_rating_2': 41, 'stamina_ap': 1200, 'removed_linked': 1}
            good = self.bundle(case, values, scenario)
            def native(args, definition):
                args.result_directory = good
                return 0
            self.assertEqual(self.workflow(native, scenario), 0)
            result = catalog.read_json(good / 'verification.json')
            self.assertEqual(result['checks'][0]['args'], check['args'])
            for key, wrong in corrupt.items():
                with self.subTest(case=case, measurement=key):
                    bad = self.bundle(case + '-' + key, {**values, key: wrong}, scenario)
                    def native(args, definition):
                        args.result_directory = bad
                        return 0
                    self.assertEqual(self.workflow(native, scenario), 1)
                    result = catalog.read_json(bad / 'verification.json')
                    self.assertEqual(result['checks'][0]['status'], 'failed')

            scenario_path = catalog.DIRECTORY / 'scenarios' / (case + '.json')
            arguments = ['run', str(scenario_path), '--worldserver', 'fixture', '--config', 'c',
                         '--mysql', 'm', '--mysqldump', 'd', '--server-modules-dir', 'sm']
            for folder, expected in [(good, 0), (bad, 1)]:
                def native(args, definition):
                    self.assertEqual(definition, scenario)
                    args.result_directory = folder
                    return 0
                with patch.object(run, 'execute', side_effect=native), \
                        redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
                    self.assertEqual(run.main(arguments), expected)


    def test_oblivion_requires_full_healing_without_added_damage(self):
        case = 'chronomancer-oblivion-epoch-overhealing'
        scenario = catalog.read_json(catalog.DIRECTORY / 'scenarios' / (case + '.json'))
        self.write(self.definitions / 'scenarios' / (case + '.json'), scenario)
        script = 'check_chronomancer_oblivion.py'
        shutil.copyfile(catalog.DIRECTORY / script, self.definitions / script)
        self.checks['checks'].extend(check for check in catalog.bindings() if check['script'] == script)
        self.write(self.definitions / 'checks.json', self.checks)
        values = {step['save_as']: 0 for step in scenario['steps'] if step['action'] == 'snapshot'}
        values.update(full_healing=1000, full_damage=1000, boosted_healing=3000, boosted_damage=3000)
        good = self.bundle(case, values, scenario)
        self.assertEqual(self.verify(good)['status'], 'passed')
        for key, amount in [('full_damage', 0), ('full_damage', 100), ('full_damage', 2000),
                            ('boosted_damage', 5000), ('full_healing', 0)]:
            with self.subTest(measurement=key, amount=amount):
                bad = self.bundle(f'{case}-{key}-{amount}', {**values, key: amount}, scenario)
                outcome = self.verify(bad)
                self.assertEqual(outcome['status'], 'failed')
                self.assertEqual(outcome['checks'][0]['status'], 'failed')


if __name__ == '__main__':
    unittest.main()
