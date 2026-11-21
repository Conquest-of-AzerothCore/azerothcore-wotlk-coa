from concurrent.futures import ThreadPoolExecutor
from contextlib import redirect_stdout
import io
import json
import os
import subprocess
import threading
import time
import unittest
from unittest.mock import patch

import check_source


class SourceSelectionTests(unittest.TestCase):
    def test_every_selection_includes_comment_enforcement(self):
        for paths in [[], ['README.md'], ['src/server/coa/AscensionExample.cpp']]:
            commands = check_source.commands_for(check_source.select(paths), 'fixture-base')
            self.assertIn(['tools/check_comments.py', '--base', 'fixture-base'], commands)
        commands = check_source.commands_for(check_source.select([], all_checks=True), 'HEAD', all_checks=True)
        self.assertIn(['tools/check_comments.py', '--base', 'HEAD', '--all'], commands)

    def test_policy_changes_select_the_comment_regressions(self):
        selected = check_source.select(['tools/comment_policy.py'])
        commands = check_source.commands_for(selected, 'HEAD')
        self.assertIn(['tools/test_comments.py'], commands)

    def test_comment_failure_fails_the_combined_command(self):
        output = io.StringIO()
        with patch.object(check_source, 'changed_paths', return_value=['tools/example.py']), \
                patch.object(check_source, 'reviewed_sources', return_value=set()), \
                patch.object(check_source, 'execute', return_value=[
                    {'command': ['tools/check_comments.py'], 'status': 'failed'}]), redirect_stdout(output):
            status = check_source.main([])
        self.assertEqual(status, 1)
        self.assertEqual(json.loads(output.getvalue())['status'], 'failed')

    def test_documentation_does_not_select_gameplay_or_compile_checks(self):
        self.assertEqual(check_source.select(['README.md', 'apps/coa-gameplay-test/README.md']),
                         {'checks': [], 'client_compat': False})

    def test_scenario_changes_select_combined_verification_and_mechanic_links(self):
        result = check_source.select(['apps/coa-gameplay-test/scenarios/primalist-king-mountain.json'])
        self.assertEqual(set(result['checks']), {'gameplay', 'mechanics'})
        self.assertFalse(result['client_compat'])

    def test_world_cache_selects_ownership_cleanup_tests(self):
        result = check_source.select(['apps/coa-gameplay-test/world_cache.py'])
        self.assertIn('gameplay', result['checks'])
        self.assertIn(['apps/coa-gameplay-test/test_world_cache.py'], check_source.SUITES['gameplay']['commands'])

    def test_conformance_dependencies_select_the_conformance_suite(self):
        paths = ['apps/coa-gameplay-test/conformance/compare.py', 'apps/coa-gameplay-test/run.py',
                 'apps/coa-gameplay-test/batch.py', 'apps/coa-gameplay-test/catalog.py',
                 'apps/coa-gameplay-test/verification.py', 'apps/coa-gameplay-test/world_cache.py',
                 'apps/coa-dbc/inspect_dbc.py', 'src/server/coa/AscensionSpellProgressionData.h',
                 'src/server/shared/SharedDefines.h']
        for path in paths:
            with self.subTest(path=path):
                self.assertIn('conformance', check_source.select([path])['checks'])

    def test_conformance_selection_checks_every_finished_class_snapshot(self):
        commands = check_source.commands_for(check_source.select(['apps/coa-gameplay-test/conformance/compare.py']),
                                             'HEAD')
        classes = [entry['class_id'] for entry in check_source.finished_classes()]
        self.assertTrue({19, 23} <= set(classes))
        for class_id in classes:
            self.assertIn(['apps/coa-gameplay-test/conformance/snapshots.py', 'check', '--class', str(class_id)],
                          commands)
        self.assertIn(['apps/coa-gameplay-test/conformance/test_snapshots.py'], commands)
        documentation = check_source.commands_for(check_source.select(['README.md']), 'HEAD')
        self.assertFalse(any('snapshots.py' in part for command in documentation for part in command))

    def test_shared_engine_files_print_the_rerun_of_every_finished_class(self):
        self.assertIsNone(check_source.conformance_reruns(['src/server/coa/AscensionTemplar.cpp', 'README.md']))
        reruns = check_source.conformance_reruns(['src/server/game/Spells/SpellEffects.cpp', 'README.md'])
        self.assertEqual(reruns['engine_files'], ['src/server/game/Spells/SpellEffects.cpp'])
        self.assertFalse(reruns['enforced'])
        selections = {(entry['class_id'], entry['generation']): entry['commands'] for entry in reruns['classes']}
        self.assertTrue({(19, 'all'), (19, 'stack'), (23, 'all')} <= set(selections))
        self.assertIn('generate --class 19 --stack --out .cache/conformance/rerun-templar-stack',
                      selections[(19, 'stack')][0])
        self.assertIn('--stages build,gameplay --scenario .cache/conformance/rerun-necromancer-all/scenarios/*.json',
                      selections[(23, 'all')][1])
        self.assertIn('diff --before <count of record compare output>', selections[(23, 'all')][3])
        self.assertIn('necromancer (23) all:', check_source.rerun_text(reruns))

    def test_the_rerun_listing_reaches_the_json_result_without_failing_it(self):
        output = io.StringIO()
        errors = io.StringIO()
        with patch.object(check_source, 'changed_paths', return_value=['src/server/game/Entities/Unit/Unit.cpp']), \
                patch.object(check_source, 'reviewed_sources', return_value=set()), \
                patch.object(check_source, 'execute', return_value=[
                    {'command': ['tools/check_comments.py'], 'status': 'passed'}]), redirect_stdout(output), \
                patch('sys.stderr', errors):
            status = check_source.main([])
        self.assertEqual(status, 0)
        result = json.loads(output.getvalue())
        self.assertEqual(result['conformance_reruns']['engine_files'], ['src/server/game/Entities/Unit/Unit.cpp'])
        self.assertIn('Shared engine files changed', errors.getvalue())

    def test_new_or_deleted_module_sources_require_registration_check(self):
        for path in ['src/server/coa/AscensionExample.cpp',
                     'src/server/coa/nested/Example.cpp']:
            self.assertEqual(check_source.select([path])['checks'], ['registrations'])

    def test_native_spell_layout_sources_select_dbc_and_mechanic_checks(self):
        for path in ['src/server/shared/DataStores/DBCStructure.h', 'src/server/shared/DataStores/DBCfmt.h']:
            with self.subTest(path=path):
                self.assertTrue({'dbc', 'mechanics'} <= set(check_source.select([path])['checks']))

    def test_reviewed_execution_sources_select_map_integrity_checks(self):
        path = 'src/server/game/Handlers/QuestHandler.cpp'
        result = check_source.select([path], mechanic_sources=[path])
        self.assertEqual(result['checks'], ['mechanics'])

    def test_test_selection_changes_run_all_fast_suites(self):
        for path in check_source.CONTROL_FILES:
            result = check_source.select([path])
            self.assertEqual(result['checks'], list(check_source.SUITES))
            self.assertTrue(result['client_compat'])

    def test_client_harness_changes_are_selected_but_never_run_by_the_source_command(self):
        result = check_source.select(['src/server/shared/DataStores/DBCStore.cpp'])
        self.assertTrue(result['client_compat'])
        self.assertEqual(result['checks'], [])
        self.assertFalse(any('client_compat/run.py' in ' '.join(command)
                             for suite in check_source.SUITES.values() for command in suite['commands']))

    def test_failed_and_timed_out_checks_cannot_report_passed(self):
        outcomes = [subprocess.CompletedProcess([], 1, '', 'failed assertion'),
                    subprocess.TimeoutExpired('checker', 120), OSError('cannot execute')]
        for outcome in outcomes:
            with self.subTest(outcome=outcome):
                kwargs = {'side_effect': outcome} if isinstance(outcome, Exception) else {'return_value': outcome}
                with patch.object(check_source.subprocess, 'run', **kwargs):
                    result = check_source.execute([['test.py']])
                self.assertEqual(result[0]['status'], 'failed')

    def test_checks_keep_assertions_enabled_and_continue_after_failure(self):
        with patch.dict('os.environ', {'PYTHONOPTIMIZE': '1'}), \
                patch.object(check_source.subprocess, 'run', side_effect=[
                    subprocess.CompletedProcess([], 1, '', 'first failed'),
                    subprocess.CompletedProcess([], 0, 'second passed', '')]) as execute:
            result = check_source.execute([['one.py'], ['two.py']], jobs=1)
        self.assertEqual([entry['status'] for entry in result], ['failed', 'passed'])
        self.assertNotIn('PYTHONOPTIMIZE', execute.call_args.kwargs['env'])

    def test_commands_run_concurrently_up_to_the_job_limit(self):
        barrier = threading.Barrier(2, timeout=5)

        def run(command, **_kwargs):
            barrier.wait()
            return subprocess.CompletedProcess(command, 0, 'ok', '')

        with patch.object(check_source.subprocess, 'run', side_effect=run):
            result = check_source.execute([['one.py'], ['two.py']], jobs=2)
        self.assertEqual([entry['status'] for entry in result], ['passed', 'passed'])

    def test_jobs_defaults_to_the_cpu_count_but_never_exceeds_the_command_count(self):
        with patch.object(check_source.os, 'cpu_count', return_value=8), \
                patch.object(check_source, 'ThreadPoolExecutor', wraps=ThreadPoolExecutor) as pool, \
                patch.object(check_source.subprocess, 'run',
                            return_value=subprocess.CompletedProcess([], 0, '', '')):
            check_source.execute([['one.py'], ['two.py']])
        pool.assert_called_once_with(max_workers=2)

    def test_results_keep_command_order_regardless_of_finish_order(self):
        delays = {'slow.py': 0.05, 'fast.py': 0.0}

        def run(command, **_kwargs):
            time.sleep(delays[command[-1]])
            return subprocess.CompletedProcess(command, 0, command[-1], '')

        with patch.object(check_source.subprocess, 'run', side_effect=run):
            result = check_source.execute([['slow.py'], ['fast.py']], jobs=2)
        self.assertEqual([entry['command'][-1] for entry in result], ['slow.py', 'fast.py'])


if __name__ == '__main__':
    unittest.main()
