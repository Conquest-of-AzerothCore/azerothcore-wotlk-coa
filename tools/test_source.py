from contextlib import redirect_stdout
import io
import json
import os
from pathlib import Path
import subprocess
import tempfile
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
            result = check_source.execute([['one.py'], ['two.py']])
        self.assertEqual([entry['status'] for entry in result], ['failed', 'passed'])
        self.assertNotIn('PYTHONOPTIMIZE', execute.call_args.kwargs['env'])


class WorkflowWhitespaceTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='coa-workflow-whitespace-')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.git('init', '-b', 'main')

    def git(self, *arguments):
        return subprocess.run(['git', '-c', 'user.name=CoA fixture', '-c', 'user.email=fixture@example.invalid',
                               '-c', 'commit.gpgsign=false', *arguments], cwd=self.root,
                              capture_output=True, text=True, check=True).stdout.strip()

    def commit(self, name, contents):
        (self.root / name).write_text(contents, encoding='utf-8')
        self.git('add', name)
        self.git('commit', '-m', 'fixture')
        return self.git('rev-parse', 'HEAD')

    def workflow_script(self):
        workflow = (check_source.ROOT / '.github/workflows/quality.yml').read_text(encoding='utf-8')
        marker = '      - name: Check whitespace across the change\n'
        if marker not in workflow:
            return workflow.rsplit('      - run: ', 1)[1].strip()
        block = workflow.split(marker, 1)[1]
        self.assertIn("CHECK_WHITESPACE_BASE: ${{ github.event_name == 'push' && github.event.before || '' }}", block)
        lines = block.split('        run: |\n', 1)[1].splitlines()
        return '\n'.join(line[10:] for line in lines if line.startswith('          '))

    def check_whitespace(self, base=''):
        environment = dict(os.environ, CHECK_WHITESPACE_BASE=base)
        return subprocess.run(['bash', '-e', '-o', 'pipefail', '-c', self.workflow_script()], cwd=self.root,
                              capture_output=True, text=True, env=environment)

    def test_push_checks_earlier_commits_when_the_last_commit_is_clean(self):
        before = self.commit('baseline.txt', 'clean\n')
        self.commit('earlier.txt', 'trailing whitespace \n')
        self.commit('last.txt', 'clean\n')
        last_only = subprocess.run(['git', 'diff', '--check', 'HEAD^', 'HEAD'], cwd=self.root,
                                   capture_output=True, text=True)
        self.assertEqual(last_only.returncode, 0)
        result = self.check_whitespace(before)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('earlier.txt', result.stdout)
        self.assertIn('trailing whitespace', result.stdout)

    def test_shallow_checkout_fetches_the_pre_push_commit(self):
        before = self.commit('baseline.txt', 'clean\n')
        self.commit('earlier.txt', 'trailing whitespace \n')
        self.commit('last.txt', 'clean\n')
        source = self.root
        checkout = source / 'checkout'
        self.git('clone', '--depth=2', source.as_uri(), str(checkout))
        self.root = checkout
        missing = subprocess.run(['git', 'cat-file', '-e', before + '^{commit}'], cwd=checkout,
                                 capture_output=True, text=True)
        self.assertNotEqual(missing.returncode, 0)
        result = self.check_whitespace(before)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('earlier.txt', result.stdout)
        self.assertIn('trailing whitespace', result.stdout)
        self.git('cat-file', '-e', before + '^{commit}')

    def test_pull_request_merge_keeps_the_first_parent_comparison(self):
        self.commit('baseline.txt', 'clean\n')
        self.git('checkout', '-b', 'feature')
        self.commit('feature.txt', 'trailing whitespace \n')
        self.git('checkout', 'main')
        self.commit('main.txt', 'clean\n')
        self.git('merge', '--no-ff', 'feature', '-m', 'fixture merge')
        result = self.check_whitespace()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('feature.txt', result.stdout)

    def test_clean_root_commit_passes_without_a_parent(self):
        self.commit('root.txt', 'clean\n')
        self.assertEqual(self.check_whitespace().returncode, 0)

    def test_initial_push_checks_all_commits_from_the_empty_tree(self):
        self.commit('root.txt', 'trailing whitespace \n')
        self.commit('last.txt', 'clean\n')
        result = self.check_whitespace('0' * 40)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('root.txt', result.stdout)
        self.assertIn('trailing whitespace', result.stdout)


if __name__ == '__main__':
    unittest.main()
