from contextlib import redirect_stderr, redirect_stdout
import io
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

import check_source
import verify_all


SECRET = 'SECRET-PASSWORD-VALUE'
SCENARIO = verify_all.ROOT / 'apps/coa-gameplay-test/scenarios/frostbolt.json'


def write(path, text=''):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8')
    return path


def executable(path):
    write(path, '#!/bin/sh\nexit 0\n')
    path.chmod(path.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
    return path


def program(directory, name):
    return executable(directory / verify_all.executable_name(name))


def fake_catalog():
    real = verify_all.load_catalog()
    rows = [{'id': 'frost', 'name': 'Frostbolt', 'contract': 'slows the target', 'spells': [116],
             'entities': {'quest': []}, 'path': 'scenarios/frost.json'},
            {'id': 'quest', 'name': 'Quest credit', 'contract': '', 'spells': [],
             'entities': {'quest': [42]}, 'path': 'scenarios/quest.json'}]
    checks = [{'script': 'check_pair.py', 'scenarios': ['frost', 'quest'], 'args': []}]
    return SimpleNamespace(catalog=lambda: rows, select=real.select, bindings=lambda: checks,
                           companion_cases=real.companion_cases)


class Workspace:
    def __init__(self, directory, configured=True, testing='ON'):
        self.base = Path(directory).resolve()
        self.root = self.base / 'repo'
        self.build = self.root / 'build'
        self.client = self.base / 'mysql-client'
        self.tools = self.base / 'bin'
        self.conf = self.base / 'dist' / 'etc'
        self.dbc = self.base / 'data' / 'dbc'
        self.worldserver = program(self.build / 'src/server/apps', 'worldserver')
        for name in ('mysql', 'mysqldump', 'mysql_config'):
            program(self.client, name)
        for name in ('cmake', 'ctest', 'ninja'):
            program(self.tools, name)
        write(self.conf / 'worldserver.conf', f'DataDir = "{self.dbc.parent.as_posix()}"\n'
              f'LoginDatabaseInfo = "127.0.0.1;3306;acore;{SECRET};acore_auth"\n')
        (self.conf / 'modules').mkdir(parents=True)
        write(self.dbc / 'Spell.dbc', 'WDBC')
        if configured:
            self.configure(testing)
        self.environment = {'PATH': str(self.tools)}

    def configure(self, testing='ON'):
        write(self.build / 'CMakeCache.txt', f'CMAKE_INSTALL_PREFIX:PATH={self.conf.parent.as_posix()}\n'
              f'BUILD_TESTING:BOOL={testing}\nMYSQL_CONFIG:FILEPATH={(self.client / "mysql_config").as_posix()}\n'
              'CMAKE_GENERATOR:INTERNAL=Ninja\n')
        write(self.build / 'build.ninja')
        write(self.build / 'CTestTestfile.cmake')

    def settings(self, raw=None):
        with patch.object(verify_all, 'MYSQL_CLIENT_DIRECTORIES', (self.client,)):
            return verify_all.resolve_settings(raw or {}, self.root, self.environment)

    def context(self, raw=None, **overrides):
        values = {'root': self.root, 'raw': raw or {}, 'settings': self.settings(raw), 'output': self.base / 'out',
                  'stages': list(verify_all.STAGES), 'jobs': 3, 'gameplay_jobs': 2,
                  'gameplay_clock': verify_all.REAL_CLOCK, 'gameplay_lanes': 1, 'base': None, 'scenarios': [],
                  'harness': [], 'environment': self.environment}
        values.update(overrides)
        values['output'].mkdir(parents=True, exist_ok=True)
        return verify_all.Context(**values)


class WorkspaceTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.addCleanup(verify_all.STOPPING.clear)

    def workspace(self, **options):
        return Workspace(tempfile.mkdtemp(dir=self.directory.name), **options)

    def run_main(self, workspace, arguments, files=()):
        stdout, stderr = io.StringIO(), io.StringIO()
        with patch.object(verify_all, 'MYSQL_CLIENT_DIRECTORIES', (workspace.client,)), \
                patch.object(verify_all, 'repository_files', return_value=list(files)), \
                redirect_stdout(stdout), redirect_stderr(stderr):
            status = verify_all.main(arguments, root=workspace.root, environment=workspace.environment)
        return status, stdout.getvalue(), stderr.getvalue()


class SettingsTests(WorkspaceTest):
    def test_unknown_setting_keys_are_rejected(self):
        path = write(Path(self.directory.name) / 'settings.json', json.dumps({'worldserver': 'x', 'ports': 1}))
        with self.assertRaisesRegex(ValueError, 'Unknown settings.*ports'):
            verify_all.load_settings(path, explicit=True)

    def test_default_settings_are_optional_but_an_explicit_file_must_exist(self):
        missing = Path(self.directory.name) / 'missing.json'
        self.assertEqual(verify_all.load_settings(missing, explicit=False), {})
        with self.assertRaisesRegex(ValueError, 'not found'):
            verify_all.load_settings(missing, explicit=True)

    def test_setting_values_are_type_checked(self):
        for data in [{'jobs': 0}, {'gameplay_jobs': True}, {'cmake_args': '-G Ninja'}, {'mysql': ''}, [],
                     {'gameplay_db_workers': 0}, {'gameplay_db_workers': '4'}, {'gameplay_db_workers': 33}]:
            with self.subTest(data=data):
                path = write(Path(self.directory.name) / 'settings.json', json.dumps(data))
                with self.assertRaises(ValueError):
                    verify_all.load_settings(path, explicit=True)
        path = write(Path(self.directory.name) / 'settings.json', json.dumps({'gameplay_db_workers': 32}))
        self.assertEqual(verify_all.load_settings(path, explicit=True), {'gameplay_db_workers': 32})

    def test_relative_setting_paths_resolve_against_the_repository(self):
        workspace = self.workspace()
        settings = workspace.settings({'worldserver': 'custom/worldserver', 'dbc_directory': 'client/dbc',
                                       'build_directory': 'out/build'})
        self.assertEqual(settings['worldserver'], workspace.root / 'custom/worldserver')
        self.assertEqual(settings['dbc_directory'], workspace.root / 'client/dbc')
        self.assertEqual(settings['build_directory'], workspace.root / 'out/build')

    def test_auto_detection_reads_the_build_cache_worldserver_config_and_mysql_client(self):
        workspace = self.workspace()
        settings = workspace.settings()
        self.assertEqual(settings['worldserver'], workspace.worldserver)
        self.assertEqual(settings['conf_dir'], workspace.conf)
        self.assertEqual(settings['worldserver_config'], workspace.conf / 'worldserver.conf')
        self.assertEqual(settings['mysql'], workspace.client / verify_all.executable_name('mysql'))
        self.assertEqual(settings['mysqldump'], workspace.client / verify_all.executable_name('mysqldump'))
        self.assertEqual(settings['mysql_client_bin'], workspace.client)
        self.assertEqual(settings['dbc_directory'], workspace.dbc)
        if os.name != 'nt':
            self.assertEqual(settings['server_modules_dir'], workspace.conf / 'modules')

    def test_the_newest_worldserver_in_the_build_directory_is_selected(self):
        workspace = self.workspace()
        stale = program(workspace.build / 'bin', 'worldserver')
        os.utime(stale, (1, 1))
        self.assertEqual(workspace.settings()['worldserver'], workspace.worldserver)
        os.utime(workspace.worldserver, (1, 1))
        os.utime(stale, (2, 2))
        program(workspace.build / 'CMakeFiles', 'worldserver')
        self.assertEqual(workspace.settings()['worldserver'], stale)

    def test_path_programs_take_precedence_over_the_homebrew_client_directories(self):
        workspace = self.workspace()
        on_path = program(workspace.tools, 'mysql')
        self.assertEqual(workspace.settings()['mysql'], on_path)

    def test_dbc_directory_falls_back_to_the_harness_default(self):
        workspace = self.workspace()
        (workspace.conf / 'worldserver.conf').unlink()
        self.assertIsNone(workspace.settings()['dbc_directory'])
        default = write(workspace.root / verify_all.HARNESS_DBC_DEFAULT / 'Spell.dbc').parent
        self.assertEqual(workspace.settings()['dbc_directory'], default)

    def test_invalid_settings_json_names_the_file(self):
        path = write(Path(self.directory.name) / 'settings.json', '{"jobs": 1,}')
        with self.assertRaisesRegex(ValueError, f'Invalid JSON in settings file {re.escape(str(path))}'):
            verify_all.load_settings(path, explicit=True)

    def test_configured_directories_must_exist(self):
        workspace = self.workspace()
        absent = workspace.base / 'absent'
        for key in verify_all.CONFIGURED_DIRECTORIES:
            with self.subTest(key=key):
                settings = write(workspace.base / f'{key}.json', json.dumps({key: str(absent)}))
                status, stdout, stderr = self.run_main(workspace, ['--settings', str(settings), '--plan'])
                self.assertEqual(status, verify_all.USAGE_ERROR)
                self.assertIn(f'Configured {key} does not exist: {absent}', stderr)
                self.assertEqual(stdout, '')

    def test_bare_program_names_resolve_through_path(self):
        workspace = self.workspace()
        custom = program(workspace.tools, 'mysql-custom')
        settings = workspace.settings({'mysql': custom.name, 'mysqldump': 'bin/mysqldump'})
        self.assertEqual(settings['mysql'], custom)
        self.assertEqual(settings['mysqldump'], workspace.root / 'bin/mysqldump')
        self.assertEqual(workspace.settings({'mysql': 'not-installed'})['mysql'], workspace.root / 'not-installed')

    def test_windows_configs_are_found_next_to_the_worldserver_then_under_the_install_prefix(self):
        base = Path(self.directory.name)
        worldserver = base / 'build/bin/RelWithDebInfo/worldserver.exe'
        prefix = base / 'dist'
        cache = {'CMAKE_INSTALL_PREFIX': prefix.as_posix(), 'CONF_DIR': (base / 'etc').as_posix()}
        self.assertEqual(verify_all.conf_directory(cache, worldserver, True), worldserver.parent / 'configs')
        write(prefix / 'configs/worldserver.conf')
        self.assertEqual(verify_all.conf_directory(cache, worldserver, True), prefix / 'configs')
        self.assertEqual(verify_all.conf_directory(cache, None, True), prefix / 'configs')
        write(worldserver.parent / 'configs/worldserver.conf')
        self.assertEqual(verify_all.conf_directory(cache, worldserver, True), worldserver.parent / 'configs')
        self.assertEqual(verify_all.conf_directory(cache, worldserver, False), base / 'etc')
        self.assertEqual(verify_all.conf_directory({'CMAKE_INSTALL_PREFIX': prefix.as_posix()}, worldserver, False),
                         prefix / 'etc')


class BuildTests(WorkspaceTest):
    def record_commands(self, workspace, testing_after_configure='ON'):
        calls = []

        def run_logged(command, log, environment, cwd):
            calls.append((command, environment))
            if '-S' in command:
                workspace.configure(testing_after_configure)
            return 0
        return calls, patch.object(verify_all, 'run_logged', side_effect=run_logged)

    def test_missing_cache_is_configured_with_default_arguments_and_never_installed(self):
        workspace = self.workspace(configured=False)
        calls, runner = self.record_commands(workspace)
        with runner:
            status, summary = verify_all.stage_build(workspace.context(), workspace.base / 'out/build.log')
        self.assertEqual(status, 'passed')
        self.assertEqual(summary['steps'], ['configure', 'build'])
        configure, build = (command for command, _ in calls)
        self.assertEqual(configure[1:5], ['-S', str(workspace.root), '-B', str(workspace.build)])
        for argument in ['-G', 'Ninja', '-DBUILD_TESTING=ON', '-DAPPS_BUILD=world-only',
                         f'-DCMAKE_INSTALL_PREFIX={(workspace.root / "env/dist").as_posix()}']:
            self.assertIn(argument, configure)
        self.assertEqual(build[1:], ['--build', str(workspace.build), '--parallel', '3'])
        self.assertFalse(any('install' in part for command, _ in calls for part in command[1:]
                             if not part.startswith('-DCMAKE_INSTALL_PREFIX=')))

    def test_macos_configure_uses_homebrew_readline_instead_of_the_sdk_stub(self):
        workspace = self.workspace()
        prefix = workspace.base / 'readline'
        write(prefix / 'lib' / 'libreadline.dylib')
        expected = [f"-DREADLINE_LIBRARY={(prefix / 'lib' / 'libreadline.dylib').as_posix()}",
                    f"-DREADLINE_INCLUDE_DIR={(prefix / 'include').as_posix()}"]
        self.assertEqual(verify_all.readline_arguments('darwin', (workspace.base / 'absent', prefix)), expected)
        self.assertEqual(verify_all.readline_arguments('linux', (prefix,)), [])
        self.assertEqual(verify_all.readline_arguments('darwin', (workspace.base / 'absent',)), [])

    def test_macos_configure_keeps_line_tables_with_a_level_every_compiler_accepts(self):
        flags = '-O2 -g1 -DNDEBUG'
        arguments = verify_all.line_table_debug_arguments('darwin')
        self.assertEqual(arguments, [f'-DCMAKE_C_FLAGS_RELWITHDEBINFO={flags}',
                                     f'-DCMAKE_CXX_FLAGS_RELWITHDEBINFO={flags}'])
        self.assertFalse(any('-gline-tables-only' in argument for argument in arguments))
        self.assertEqual(verify_all.line_table_debug_arguments('linux'), [])
        self.assertEqual(verify_all.line_table_debug_arguments('win32'), [])

    def test_custom_cmake_arguments_replace_the_defaults(self):
        workspace = self.workspace(configured=False)
        calls, runner = self.record_commands(workspace)
        with runner:
            verify_all.stage_build(workspace.context({'cmake_args': ['-DNOPCH=1']}), workspace.base / 'out/b.log')
        self.assertEqual(calls[0][0][5:], ['-DNOPCH=1'])

    def test_disabled_testing_is_reconfigured_before_building(self):
        for configured in (True, False):
            with self.subTest(configured=configured):
                workspace = self.workspace(configured=configured, testing='OFF')
                calls, runner = self.record_commands(workspace, testing_after_configure='OFF')
                with runner:
                    status, summary = verify_all.stage_build(workspace.context(), workspace.base / 'out/b.log')
                self.assertEqual(status, 'passed')
                expected = ['reconfigure', 'build'] if configured else ['configure', 'reconfigure', 'build']
                self.assertEqual(summary['steps'], expected)
                self.assertIn('-DBUILD_TESTING=ON', calls[-2][0])

    def test_a_failed_configure_is_repeated_with_the_cached_generator_on_the_next_run(self):
        workspace = self.workspace(configured=False)
        log = workspace.base / 'out/build.log'

        def failing(command, log, environment, cwd):
            write(workspace.build / 'CMakeCache.txt',
                  'CMAKE_GENERATOR:INTERNAL=Unix Makefiles\nBUILD_TESTING:BOOL=ON\n')
            return 1
        with patch.object(verify_all, 'run_logged', side_effect=failing):
            status, summary = verify_all.stage_build(workspace.context(), log)
        self.assertEqual((status, summary['message']), ('failed', 'configure failed with exit code 1'))
        context = workspace.context()
        self.assertEqual([step for step, _ in verify_all.planned_build_steps(context, 'cmake')],
                         ['configure', 'build'])
        calls, runner = self.record_commands(workspace)
        with runner:
            status, summary = verify_all.stage_build(context, log)
        self.assertEqual((status, summary['steps']), ('passed', ['configure', 'build']))
        self.assertEqual(calls[0][0][5:7], ['-G', 'Unix Makefiles'])

    def test_multi_config_builds_select_the_configured_build_type(self):
        workspace = self.workspace()
        write(workspace.build / 'CMakeCache.txt', 'CMAKE_GENERATOR:INTERNAL=Visual Studio 17 2022\n'
              'CMAKE_CONFIGURATION_TYPES:STRING=Debug;Release;MinSizeRel;RelWithDebInfo\n'
              'CMAKE_BUILD_TYPE:STRING=RelWithDebInfo\nBUILD_TESTING:BOOL=ON\n')
        write(workspace.build / 'AzerothCore.sln')
        release = program(workspace.build / 'bin/RelWithDebInfo', 'worldserver')
        program(workspace.build / 'bin/Debug', 'worldserver')
        os.utime(release, (1, 1))
        context = workspace.context()
        self.assertEqual((context.settings['configuration'], context.settings['worldserver']),
                         ('RelWithDebInfo', release))
        self.assertEqual(verify_all.unit_command(context, 'ctest')[3:5], ['-C', 'RelWithDebInfo'])
        calls, runner = self.record_commands(workspace)
        with runner:
            status, summary = verify_all.stage_build(context, workspace.base / 'out/build.log')
        self.assertEqual((status, summary['steps'], summary['configuration']), ('passed', ['build'], 'RelWithDebInfo'))
        self.assertEqual(calls[0][0][1:], ['--build', str(workspace.build), '--config', 'RelWithDebInfo',
                                           '--parallel', '3'])

    def test_cmake_runs_with_the_mysql_client_directory_on_path(self):
        workspace = self.workspace()
        calls, runner = self.record_commands(workspace)
        with runner:
            verify_all.stage_build(workspace.context(), workspace.base / 'out/build.log')
        path = calls[0][1]['PATH'].split(os.pathsep)
        self.assertEqual(path[:2], [str(workspace.client), str(workspace.tools)])

    def test_failed_build_blocks_unit_and_gameplay(self):
        workspace = self.workspace()
        output = workspace.base / 'result'
        with patch.object(verify_all, 'run_logged', return_value=2):
            status, stdout, _ = self.run_main(workspace, ['--stages', 'build,unit,gameplay', '--output', str(output)])
        report = json.loads((output / 'report.json').read_text(encoding='utf-8'))
        self.assertEqual(status, 1)
        self.assertEqual({name: stage['status'] for name, stage in report['stages'].items()},
                         {'source': 'skipped', 'build': 'failed', 'unit': 'blocked', 'harness': 'skipped',
                          'gameplay': 'blocked'})
        self.assertIn('build failed with exit code 2', report['stages']['build']['summary']['message'])
        self.assertTrue(stdout.rstrip().endswith(f'VERIFY ALL: FAILED {output / "report.json"}'))


class UnitStageTests(WorkspaceTest):
    def test_ctest_runs_the_configured_build_and_reports_counts(self):
        workspace = self.workspace()
        calls = []

        def run_logged(command, log, environment, cwd):
            calls.append(command)
            write(log, '100% tests passed, 0 tests failed out of 7\n')
            return 0
        with patch.object(verify_all, 'run_logged', side_effect=run_logged):
            status, summary = verify_all.stage_unit(workspace.context(), workspace.base / 'out/unit.log')
        self.assertEqual(status, 'passed')
        self.assertEqual(summary['counts'], {'tests': 7, 'failed': 0})
        self.assertEqual(calls[0][1:], ['--test-dir', str(workspace.build), '--output-on-failure', '--parallel', '3',
                                        '--no-tests=error'])

    def test_unit_stage_is_unavailable_without_a_testing_build(self):
        for testing in ('OFF', None):
            with self.subTest(testing=testing):
                workspace = self.workspace(configured=testing is not None, testing=testing or 'ON')
                with patch.object(verify_all, 'run_logged', side_effect=AssertionError):
                    status, summary = verify_all.stage_unit(workspace.context(), workspace.base / 'out/unit.log')
                self.assertEqual(status, 'unavailable')
                self.assertIn(str(workspace.build), summary['reason'])


class HarnessClassificationTests(WorkspaceTest):
    def classify(self, workspace, source, settings=None, environment=None, name='apps/coa-tests/case/run.py'):
        write(workspace.root / name, source)
        return verify_all.classify_harness(name, settings if settings is not None else workspace.settings(),
                                           environment or {}, workspace.root)

    def test_discovery_includes_harnesses_and_unregistered_test_scripts(self):
        workspace = self.workspace()
        names = ['apps/coa-tests/alpha/run.py', 'apps/coa-tests/alpha/helper.py', 'apps/coa-tests/a/b/run.py',
                 'apps/coa-tests/test_beta.py', 'apps/other/test_gamma.py', 'apps/other/gamma.py',
                 'tools/test_verify_all.py', 'apps/coa-gameplay-test/test_batch.py', 'tools/test_source.py',
                 'apps/coa-tests/deleted/run.py']
        for name in names[:-1]:
            write(workspace.root / name)
        found = verify_all.harness_scripts(names, verify_all.registered_scripts(), workspace.root)
        self.assertEqual(found, ['apps/coa-tests/alpha/run.py', 'apps/coa-tests/test_beta.py',
                                 'apps/other/test_gamma.py'])

    def test_filters_match_directory_names_and_file_stems(self):
        names = ['apps/coa-tests/alpha/run.py', 'apps/coa-tests/bugreport/test_relay.py', 'apps/other/test_gamma.py']
        self.assertEqual(verify_all.filter_harness(names, ['alpha', 'test_gamma']),
                         ['apps/coa-tests/alpha/run.py', 'apps/other/test_gamma.py'])
        self.assertEqual(verify_all.filter_harness(names, ['bugreport']), ['apps/coa-tests/bugreport/test_relay.py'])
        self.assertEqual(verify_all.filter_harness(names, []), names)
        with self.assertRaisesRegex(ValueError, 'No harness script matches: missing'):
            verify_all.filter_harness(names, ['alpha', 'missing'])

    def test_msvc_only_scripts_are_unavailable_without_the_toolchain(self):
        workspace = self.workspace()
        source = "import os\ncompiler = os.environ['VCToolsInstallDir'] + '/cl.exe'\n"
        entry = self.classify(workspace, source)
        self.assertEqual(entry['status'], 'unavailable')
        self.assertIn('MSVC', entry['reason'])
        self.assertEqual(self.classify(workspace, source, environment={'VCToolsInstallDir': 'C:/VC'})['status'], 'run')

    def test_scripts_that_load_an_msvc_only_sibling_harness_are_unavailable_too(self):
        workspace = self.workspace()
        write(workspace.root / 'apps/coa-tests/helper/run.py', "import os\nos.environ['VCToolsInstallDir']\n")
        write(workspace.root / 'apps/coa-tests/middle/run.py', "runpy.run_path(HERE.parent / 'helper/run.py')\n")
        source = "import runpy\nrunpy.run_path(str(HERE.parent / 'middle/run.py'))\n"
        entry = self.classify(workspace, source)
        self.assertEqual(entry['status'], 'unavailable')
        self.assertIn('MSVC', entry['reason'])
        write(workspace.root / 'apps/coa-tests/portable/run.py', "import os\nos.environ.get('CXX', 'c++')\n")
        write(workspace.root / 'apps/coa-tests/middle/run.py',
              "runpy.run_path(HERE.parent / 'helper/run.py')\nrunpy.run_path(HERE.parent / 'portable/run.py')\n")
        self.assertEqual(self.classify(workspace, source)['status'], 'unavailable')
        write(workspace.root / 'apps/coa-tests/middle/run.py', "runpy.run_path(HERE.parent / 'portable/run.py')\n")
        self.assertEqual(self.classify(workspace, source)['status'], 'run')

    def test_scripts_with_a_portable_compiler_fallback_run_outside_windows(self):
        workspace = self.workspace()
        source = ("import os, shutil\nmsvc = os.name == 'nt'\ncompiler = os.environ['VCToolsInstallDir'] if msvc "
                  "else shutil.which(os.environ.get('CXX', 'c++'))\n")
        with patch.object(verify_all, 'WINDOWS', False):
            self.assertEqual(self.classify(workspace, source)['status'], 'run')

    def test_windows_scripts_need_the_msvc_toolchain_or_a_compiler_on_path(self):
        workspace = self.workspace()
        settings = workspace.settings()
        unconditional = (verify_all.ROOT / 'apps/coa-tests/classic_stats/run.py').read_text(encoding='utf-8')
        fallback = (verify_all.ROOT / 'apps/coa-tests/classic_combat/run.py').read_text(encoding='utf-8')
        compilers = workspace.base / 'compilers'
        path = {'PATH': str(compilers)}

        def classify(source, environment):
            return self.classify(workspace, source, settings=settings, environment=environment)
        with patch.object(verify_all, 'WINDOWS', True):
            self.assertIn('requires the MSVC toolchain (', classify(unconditional, path)['reason'])
            self.assertIn('requires the MSVC toolchain or cl.exe on PATH', classify(fallback, path)['reason'])
            executable(compilers / 'cl.exe')
            self.assertEqual(classify(fallback, path)['status'], 'run')
            self.assertEqual(classify(unconditional, path)['status'], 'unavailable')
            self.assertEqual(classify(unconditional, {'VCToolsInstallDir': 'C:/VC'})['status'], 'run')
            self.assertIn('clang++ on PATH', classify(fallback, {'PATH': '', 'CXX': 'clang++'})['reason'])
        with patch.object(verify_all, 'WINDOWS', False):
            self.assertEqual([classify(source, {})['status'] for source in (unconditional, fallback)], ['run', 'run'])

    def test_missing_workspace_tools_are_unavailable_and_present_ones_are_passed(self):
        workspace = self.workspace()
        source = ("import argparse\nfrom pathlib import Path\nparser = argparse.ArgumentParser()\n"
                  "parser.add_argument('--workspace-tools', type=Path, default=ROOT.parent / 'tools')\n"
                  "path = args.workspace_tools / 'Test-LocalLoginCollections.py'\n")
        entry = self.classify(workspace, source)
        self.assertEqual(entry['status'], 'unavailable')
        self.assertIn(f"missing from {workspace.base / 'tools'}: Test-LocalLoginCollections.py", entry['reason'])
        write(workspace.base / 'tools' / 'Test-LocalLoginCollections.py')
        entry = self.classify(workspace, source)
        self.assertEqual(entry['status'], 'run')
        self.assertEqual(entry['command'][-2:], ['--workspace-tools', str(workspace.base / 'tools')])

    def test_configured_workspace_tools_replace_the_default_directory(self):
        workspace = self.workspace()
        custom = workspace.base / 'custom-tools'
        write(custom / 'Test-TemplarCompletion.py')
        source = ("parser.add_argument('--workspace-tools', type=Path, default=ROOT.parent / 'tools')\n"
                  "load(args.workspace_tools / 'Test-TemplarCompletion.py')\n")
        entry = self.classify(workspace, source, settings=workspace.settings({'workspace_tools': str(custom)}))
        self.assertEqual(entry['command'][-2:], ['--workspace-tools', str(custom)])

    def test_fixed_workspace_tool_paths_are_checked_in_the_default_directory(self):
        workspace = self.workspace()
        source = "path = ROOT.parent / 'tools/Test-StarcallerCompletion.py'\n"
        settings = workspace.settings({'workspace_tools': str(workspace.base / 'elsewhere')})
        write(workspace.base / 'elsewhere' / 'Test-StarcallerCompletion.py')
        self.assertEqual(self.classify(workspace, source, settings=settings)['status'], 'unavailable')
        write(workspace.base / 'tools' / 'Test-StarcallerCompletion.py')
        entry = self.classify(workspace, source, settings=settings)
        self.assertEqual(entry['status'], 'run')
        self.assertNotIn('--workspace-tools', entry['command'])

    def test_scripts_reading_the_sibling_datamine_are_unavailable_without_it(self):
        workspace = self.workspace()
        name = 'apps/coa-tests/secondary_appearances/run.py'
        source = (verify_all.ROOT / name).read_text(encoding='utf-8')
        entry = self.classify(workspace, source, name=name)
        self.assertEqual(entry['status'], 'unavailable')
        self.assertEqual(entry['reason'], f'requires files outside the repository missing from {workspace.base}: '
                                          'client-reference/coa-datamine/raw/tables')
        (workspace.base / 'client-reference/coa-datamine/raw/tables').mkdir(parents=True)
        self.assertEqual(self.classify(workspace, source, name=name)['status'], 'run')

    def test_argument_defaults_outside_the_repository_are_not_requirements(self):
        workspace = self.workspace()
        source = ("parser.add_argument('--workspace-tools', type=Path, default=str(ROOT.parent / 'tools'))\n"
                  "parser.add_argument('--cache', type=Path, default=ROOT.parent / 'cache')\n")
        self.assertEqual(self.classify(workspace, source)['status'], 'run')

    def test_required_arguments_are_supplied_from_settings_or_make_the_script_unavailable(self):
        workspace = self.workspace()
        datamine = workspace.base / 'datamine'
        datamine.mkdir()
        source = ("parser.add_argument('--spell-dbc', type=Path, required=True)\n"
                  "parser.add_argument(\n    '--datamine-dir',\n    type=Path,\n    required=True,\n)\n")
        entry = self.classify(workspace, source)
        self.assertEqual(entry['status'], 'unavailable')
        self.assertIn('requires --datamine-dir', entry['reason'])
        entry = self.classify(workspace, source, settings=workspace.settings({'datamine_directory': str(datamine)}))
        self.assertEqual(entry['status'], 'run')
        self.assertEqual(entry['command'][3:], ['--spell-dbc', str(workspace.dbc / 'Spell.dbc'),
                                                '--datamine-dir', str(datamine)])
        mysql_source = "parser.add_argument('--mysql-bin', type=Path, required=True)\n"
        entry = self.classify(workspace, mysql_source)
        self.assertEqual(entry['status'], 'unavailable')
        self.assertIn('--mysql-bin', entry['reason'])
        server = workspace.base / 'mysql-server' / 'bin'
        client = write(server / verify_all.executable_name('mysql'), '')
        client.chmod(0o755)
        settings = workspace.settings({'mysql_server_bin': str(server)})
        self.assertEqual(self.classify(workspace, mysql_source, settings=settings)['status'], 'unavailable')
        write(server / verify_all.executable_name('mysqld'), '').chmod(0o755)
        entry = self.classify(workspace, mysql_source, settings=settings)
        self.assertEqual(entry['status'], 'run')
        self.assertEqual(entry['command'][3:], ['--mysql-bin', str(server)])

    def test_optional_suppliable_arguments_are_passed_when_known(self):
        workspace = self.workspace()
        source = ("parser.add_argument('--dbc-dir', type=Path)\nparser.add_argument('--before')\n"
                  "parser.add_argument('--datamine-dir', type=Path)\n")
        entry = self.classify(workspace, source, name='apps/coa-tests/test_alpha.py')
        self.assertEqual(entry['status'], 'run')
        self.assertEqual(entry['name'], 'test_alpha')
        self.assertEqual(entry['command'][3:], ['--dbc-dir', str(workspace.dbc)])


class HarnessExecutionTests(WorkspaceTest):
    def entry(self, workspace, name, source):
        path = write(workspace.root / 'apps/coa-tests' / name / 'run.py', source)
        entry = verify_all.classify_harness(path.relative_to(workspace.root).as_posix(), workspace.settings(), {},
                                            workspace.root)
        self.assertEqual(entry['status'], 'run')
        return entry

    def test_scripts_run_in_parallel_with_the_dbc_directory_and_a_timeout(self):
        workspace = self.workspace()
        expected = str(workspace.dbc)
        entries = [
            self.entry(workspace, 'passes', f"import os, sys\nprint('ok')\nsys.exit(os.environ['COA_DBC_DIR'] != "
                                            f"{expected!r} or 'PYTHONOPTIMIZE' in os.environ)\n"),
            self.entry(workspace, 'fails', "import sys\nprint('broken assertion')\nsys.exit(4)\n"),
            self.entry(workspace, 'hangs', "import subprocess, sys, time\n"
                                           "subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(60)'])\n"
                                           "time.sleep(60)\n"),
            {'name': 'msvc', 'path': 'apps/coa-tests/msvc/run.py', 'status': 'unavailable', 'reason': 'MSVC'},
        ]
        context = workspace.context(harness=entries, environment={**os.environ, 'PYTHONOPTIMIZE': '1'})
        log = context.output / 'harness.log'
        with patch.object(verify_all, 'HARNESS_TIMEOUT', 3):
            status, summary = verify_all.stage_harness(context, log)
        scripts = summary['scripts']
        self.assertEqual(status, 'failed')
        self.assertEqual(summary['counts'], {'passed': 1, 'failed': 2, 'unavailable': 1})
        self.assertEqual(scripts['apps/coa-tests/passes/run.py']['status'], 'passed')
        self.assertEqual(scripts['apps/coa-tests/fails/run.py']['returncode'], 4)
        self.assertIn('broken assertion', scripts['apps/coa-tests/fails/run.py']['tail'])
        self.assertEqual(scripts['apps/coa-tests/hangs/run.py']['message'], 'timed out after 3 s')
        self.assertLess(scripts['apps/coa-tests/hangs/run.py']['seconds'], 30)
        self.assertEqual(scripts['apps/coa-tests/msvc/run.py'], {'name': 'msvc', 'status': 'unavailable',
                                                                 'reason': 'MSVC'})
        self.assertIn('broken assertion', log.read_text(encoding='utf-8'))

    def test_unavailable_scripts_make_the_stage_incomplete_without_failing_it(self):
        workspace = self.workspace()
        entries = [self.entry(workspace, 'passes', 'print("ok")\n'),
                   {'name': 'tools', 'path': 'apps/coa-tests/tools/run.py', 'status': 'unavailable', 'reason': 'x'}]
        status, summary = verify_all.stage_harness(workspace.context(harness=entries),
                                                   workspace.base / 'out/harness.log')
        self.assertEqual(status, 'unavailable')
        self.assertEqual(summary['counts'], {'passed': 1, 'failed': 0, 'unavailable': 1})


class FakeProcess:
    def __init__(self, calls, pid, exits_on_break):
        self.calls, self.pid, self.exits_on_break, self.returncode = calls, pid, exits_on_break, None

    def poll(self):
        return self.returncode

    def send_signal(self, value):
        self.calls.append(('break', self.pid, value))
        if self.exits_on_break:
            self.returncode = 0

    def terminate(self):
        self.calls.append(('terminate', self.pid))

    def wait(self, timeout=None):
        if self.returncode is None:
            raise subprocess.TimeoutExpired('fake', timeout)
        return self.returncode

    def kill(self):
        self.calls.append(('kill', self.pid))
        self.returncode = self.returncode if self.returncode is not None else -9


class ProcessControlTests(unittest.TestCase):
    def tearDown(self):
        verify_all.STOPPING.clear()

    def test_windows_children_get_a_process_group_and_a_break_before_the_tree_is_killed(self):
        calls = []
        stubborn, cooperative = FakeProcess(calls, 11, False), FakeProcess(calls, 22, True)

        def taskkill(command, **options):
            calls.append(('taskkill', int(command[-1])))
        with patch.object(verify_all, 'WINDOWS', True), \
                patch.object(verify_all.subprocess, 'run', side_effect=taskkill):
            self.assertEqual(verify_all.process_group_options(), {'creationflags': verify_all.PROCESS_GROUP_FLAG})
            with verify_all.ACTIVE_LOCK:
                verify_all.ACTIVE.update({stubborn, cooperative})
            verify_all.stop_active(grace=0.01)
        self.assertEqual([call for call in calls if call[1] == 11],
                         [('break', 11, verify_all.BREAK_SIGNAL), ('taskkill', 11), ('kill', 11)])
        self.assertEqual([call[0] for call in calls if call[1] == 22], ['break', 'kill'])
        self.assertNotIn(stubborn, verify_all.ACTIVE)
        self.assertNotIn(cooperative, verify_all.ACTIVE)

    def test_stop_active_terminates_running_processes_and_refuses_new_ones(self):
        process = verify_all.launch([verify_all.sys.executable, '-c', 'import time; time.sleep(60)'])
        self.assertIn(process, verify_all.ACTIVE)
        verify_all.STOPPING.set()
        verify_all.stop_active(grace=5)
        self.assertIsNotNone(process.poll())
        self.assertNotIn(process, verify_all.ACTIVE)
        with self.assertRaises(verify_all.Interrupted):
            verify_all.launch([verify_all.sys.executable, '-c', 'pass'])


class GameplayTests(WorkspaceTest):
    def test_default_gameplay_omits_disabled_modules_and_accepts_explicit_opt_in(self):
        workspace = self.workspace()
        row = {'id': 'optional-case', 'module': 'mod-optional', 'configuration': {'Optional.Enable': False}}
        inactive = dict(row, id='inactive-case', module_active=False)
        context = workspace.context()
        self.assertEqual(verify_all.inactive_module_scenarios(context, [row, inactive]), ['optional-case'])
        modules = workspace.base / 'module-configs'
        write(modules / 'optional.conf', 'Optional.Enable = 1\n')
        context.settings['modules_config_dir'] = modules
        self.assertEqual(verify_all.inactive_module_scenarios(context, [row, inactive]), ['inactive-case'])
        with (workspace.build / 'CMakeCache.txt').open('a') as cache:
            cache.write('MODULE_MOD-OPTIONAL:STRING=disabled\n')
        self.assertEqual(verify_all.inactive_module_scenarios(context, [row, inactive]), ['optional-case'])

    def test_default_gameplay_observes_environment_configuration_overrides(self):
        workspace = self.workspace()
        context = workspace.context()
        row = {'id': 'optional-case', 'module': 'mod-optional', 'configuration': {'Optional.Enable': False}}
        context.environment['AC_OPTIONAL_ENABLE'] = 'true'
        self.assertEqual(verify_all.inactive_module_scenarios(context, [row]), [])

    def test_missing_prerequisites_make_gameplay_unavailable_with_their_names(self):
        workspace = self.workspace()
        (workspace.conf / 'worldserver.conf').unlink()
        (workspace.client / verify_all.executable_name('mysqldump')).unlink()
        context = workspace.context()
        with patch.object(verify_all, 'run_logged', side_effect=AssertionError):
            status, summary = verify_all.stage_gameplay(context, context.output / 'gameplay.log')
        self.assertEqual(status, 'unavailable')
        self.assertEqual(summary['missing'][0], f"worldserver_config ({workspace.conf / 'worldserver.conf'})")
        self.assertIn('mysqldump', summary['missing'])

    def test_batch_runner_receives_the_selection_and_its_report_decides_the_status(self):
        workspace = self.workspace()
        context = workspace.context(scenarios=['frost', '/tmp/exploratory.json'])
        calls = []
        outcomes = iter([
            (0, {'status': 'passed', 'counts': {'passed': 3, 'failed': 0}, 'cases': {'frost': {'status': 'passed'}},
                 'verification': {'status': 'passed'}, 'batch_sensitive': ['frost']}),
            (1, {'status': 'failed', 'counts': {'passed': 1, 'failed': 1}, 'cases': {
                'frost': {'status': 'failed'}, 'quest': {'status': 'passed'}}, 'verification': {'status': 'failed'}}),
            (0, None),
        ])

        def run_logged(command, log, environment, cwd):
            calls.append(command)
            returncode, report = next(outcomes)
            directory = context.output / 'gameplay'
            directory.mkdir(parents=True, exist_ok=True)
            (directory / 'gameplay.json').unlink(missing_ok=True)
            if report is not None:
                write(directory / 'gameplay.json', json.dumps(report))
            write(log, 'FAIL frost 3.2\n')
            return returncode
        with patch.object(verify_all, 'run_logged', side_effect=run_logged):
            results = [verify_all.stage_gameplay(context, context.output / 'gameplay.log') for _ in range(3)]
        self.assertEqual([status for status, _ in results], ['passed', 'failed', 'failed'])
        self.assertEqual(results[0][1]['batch_sensitive'], ['frost'])
        self.assertEqual((results[0][1]['clock'], results[0][1]['lanes'], results[0][1]['acceleration_sensitive']),
                         ('real', 1, []))
        self.assertEqual(results[1][1]['failed_cases'], ['frost'])
        self.assertIn('no readable gameplay.json', results[2][1]['message'])
        command = calls[0]
        self.assertEqual(command[1:3], ['-B', 'apps/coa-gameplay-test/batch.py'])
        pairs = dict(zip(command[3::2], command[4::2]))
        self.assertEqual(pairs['--worldserver'], str(workspace.worldserver))
        self.assertEqual(pairs['--config'], str(workspace.conf / 'worldserver.conf'))
        self.assertEqual(pairs['--output'], str(context.output / 'gameplay'))
        self.assertEqual(pairs['--jobs'], '2')
        self.assertNotIn('--clock', command)
        self.assertNotIn('--lanes', command)
        self.assertNotIn('--character-db-workers', command)
        self.assertEqual(results[0][1]['db_workers'], 1)
        self.assertEqual(command[-3:], ['--scenario', 'frost', '/tmp/exploratory.json'])
        if os.name != 'nt':
            self.assertEqual(pairs['--server-modules-dir'], str(workspace.conf / 'modules'))

    def test_slower_gameplay_diagnostics_are_explicit_and_require_the_simulated_clock(self):
        workspace = self.workspace()
        args = verify_all.parser().parse_args(['--stages', 'gameplay', '--plan'])
        self.assertFalse(args.gameplay_real_pace_rerun)
        context = workspace.context(gameplay_clock=verify_all.SIMULATED_CLOCK, gameplay_jobs=1)
        self.assertNotIn('--real-pace-rerun', verify_all.gameplay_command(context))
        context.gameplay_real_pace_rerun = True
        self.assertIn('--real-pace-rerun', verify_all.gameplay_command(context))
        requested = verify_all.parser().parse_args(['--gameplay-real-pace-rerun'])
        verify_all.check_gameplay_concurrency(requested)
        requested.gameplay_clock = verify_all.REAL_CLOCK
        with self.assertRaisesRegex(ValueError, 'requires --gameplay-clock simulated'):
            verify_all.check_gameplay_concurrency(requested)

    def test_simulated_clock_runs_one_lane_server_and_reports_acceleration_sensitive_cases(self):
        workspace = self.workspace()
        context = workspace.context(gameplay_clock=verify_all.SIMULATED_CLOCK, gameplay_jobs=1, gameplay_lanes=15,
                                    gameplay_db_workers=4, scenarios=['frost', 'quest'])
        report = {'status': 'passed', 'clock': 'simulated', 'lanes': 15,
                  'simulation': {'character_db_workers': 4, 'character_db_isolation': 'READ-COMMITTED'},
                  'counts': {'passed': 2, 'failed': 0, 'not_run': 0},
                  'cases': {'frost': {'status': 'passed', 'mode': 'simulated'},
                            'quest': {'status': 'passed', 'mode': 'real_pace'}},
                  'acceleration_sensitive': ['quest'], 'batch_sensitive': [], 'verification': {'status': 'passed'}}
        calls = []

        def run_logged(command, log, environment, cwd):
            calls.append(command)
            write(context.output / 'gameplay' / 'gameplay.json', json.dumps(report))
            write(log, 'GAMEPLAY PASSED\n')
            return 0
        with patch.object(verify_all, 'run_logged', side_effect=run_logged):
            status, summary = verify_all.stage_gameplay(context, context.output / 'gameplay.log')
        self.assertEqual(status, 'passed')
        self.assertEqual([summary[key] for key in ('clock', 'lanes', 'acceleration_sensitive', 'failed_cases')],
                         ['simulated', 15, ['quest'], []])
        pairs = dict(zip(calls[0][3::2], calls[0][4::2]))
        self.assertEqual((pairs['--jobs'], pairs['--clock'], pairs['--lanes'], pairs['--character-db-workers']),
                         ('1', 'simulated', '15', '4'))
        self.assertEqual(summary['db_workers'], 4)
        line = verify_all.stage_line('gameplay', {'status': status, 'seconds': 1.0, 'summary': summary})
        self.assertIn('2 passed, 0 failed, 0 not_run; simulated clock, 15 lanes; 1 acceleration-sensitive', line)
        real = verify_all.brief({**summary, 'clock': 'real', 'lanes': 1, 'acceleration_sensitive': [],
                                 'batch_sensitive': ['frost']})
        self.assertEqual(real, '2 passed, 0 failed, 0 not_run; real clock; 1 batch-sensitive')

    def test_exploratory_only_runs_are_incomplete_and_batch_failures_are_reported(self):
        workspace = self.workspace()
        context = workspace.context(scenarios=['/tmp/probe.json'])
        batch = verify_all.gameplay_module('batch')
        exploratory = {'status': 'exploratory', 'counts': {'passed': 1, 'failed': 0}, 'cases': {},
                       'exploratory': ['probe'], 'exploratory_results': {'probe': {'status': 'passed'}},
                       'verification': {'status': 'skipped'}, 'failures': []}
        unattributed = {'status': 'failed', 'counts': {'passed': 2, 'failed': 0}, 'verification': {'status': 'passed'},
                        'cases': {'frost': {'status': 'passed'}, 'quest': {'status': 'passed'}},
                        'batch_sensitive': [], 'isolated_only': ['quest'], 'failures': ['slot-0-1: exited']}
        outcomes = iter([(batch.EXIT_CODES['exploratory'], exploratory), (batch.EXIT_CODES['failed'], unattributed),
                         (batch.EXIT_CODES['exploratory'], {**exploratory, 'status': 'failed'})])

        def run_logged(command, log, environment, cwd):
            returncode, report = next(outcomes)
            write(context.output / 'gameplay' / 'gameplay.json', json.dumps(report))
            write(log, 'GAMEPLAY\n')
            return returncode
        with patch.object(verify_all, 'run_logged', side_effect=run_logged):
            results = [verify_all.stage_gameplay(context, context.output / 'gameplay.log') for _ in range(3)]
        self.assertEqual([status for status, _ in results], ['unavailable', 'failed', 'failed'])
        self.assertEqual(results[0][1]['reason'], verify_all.EXPLORATORY_ONLY)
        self.assertEqual(verify_all.overall_status({'gameplay': {'status': results[0][0]}}), 'incomplete')
        self.assertEqual((results[1][1]['failed_cases'], results[1][1]['batch_failures'],
                          results[1][1]['isolated_only']), ([], ['slot-0-1: exited'], ['quest']))

    def test_catalog_filters_and_scenario_paths_resolve_before_running(self):
        workspace = self.workspace()
        exploratory = write(workspace.base / 'probe.json', SCENARIO.read_text(encoding='utf-8'))
        cases = [(['--spell', '116'], ['frost']), (['--quest', '42'], ['quest']), (['--query', 'slows'], ['frost']),
                 (['--scenario', 'quest', str(exploratory), '--spell', '116'], ['quest', str(exploratory), 'frost']),
                 (['--scenario', 'quest', 'frost'], []), (['--query', 'e'], []), ([], [])]
        with patch.object(verify_all, 'load_catalog', return_value=fake_catalog()):
            for arguments, expected in cases:
                with self.subTest(arguments=arguments):
                    self.assertEqual(verify_all.resolve_scenarios(verify_all.parser().parse_args(arguments)), expected)
            for arguments, message in [(['--spell', '1'], 'No catalog scenario'), (['--scenario', 'nope'], 'nope')]:
                with self.subTest(arguments=arguments), self.assertRaisesRegex(ValueError, message):
                    verify_all.resolve_scenarios(verify_all.parser().parse_args(arguments))

    def test_catalog_scenario_files_are_selected_by_id(self):
        args = verify_all.parser().parse_args(['--scenario', str(SCENARIO)])
        self.assertEqual(verify_all.resolve_scenarios(args), ['frostbolt'])

    def test_invalid_exploratory_scenario_files_are_rejected_before_any_stage(self):
        workspace = self.workspace()
        broken = write(workspace.base / 'broken.json', '{"name": "broken", ')
        incomplete = write(workspace.base / 'incomplete.json', '{"schema": 1}')
        for path in (broken, incomplete):
            with self.subTest(path=path.name), patch.object(verify_all, 'load_catalog', return_value=fake_catalog()):
                status, stdout, stderr = self.run_main(workspace, ['--stages', 'gameplay', '--scenario', str(path)])
                self.assertEqual(status, verify_all.USAGE_ERROR)
                self.assertIn(f'Invalid scenario file {path}', stderr)
                self.assertEqual(stdout, '')
        self.assertFalse((workspace.root / '.cache').exists())

    def test_relative_data_directory_must_hold_client_data_for_the_selected_worldserver(self):
        workspace = self.workspace()
        write(workspace.conf / 'worldserver.conf', 'DataDir = "../data"\n')
        context = workspace.context()
        with patch.object(verify_all, 'run_logged', side_effect=AssertionError):
            status, summary = verify_all.stage_gameplay(context, context.output / 'gameplay.log')
        resolved = (workspace.worldserver.parent / '../data').resolve()
        self.assertEqual((status, summary['missing']), ('unavailable', []))
        self.assertEqual(summary['problems'], [
            f"DataDir from {workspace.conf / 'worldserver.conf'} resolves to {resolved} for {workspace.worldserver}, "
            'which has no dbc/Spell.dbc; set an absolute DataDir'])
        write(resolved / 'dbc' / 'Spell.dbc')
        self.assertEqual(verify_all.gameplay_prerequisites(context.settings, context.environment), ([], []))

    def test_module_configs_already_in_the_server_modules_directory_make_gameplay_unavailable(self):
        workspace = self.workspace()
        write(workspace.conf / 'modules' / 'mod_ascension_compat.conf', 'Enabled = 1\n')
        write(workspace.conf / 'modules' / 'spellbook.conf.dist')
        separate = workspace.base / 'module-configs'
        separate.mkdir()
        with patch.object(verify_all, 'WINDOWS', False):
            shared = workspace.context()
            _, problems = verify_all.gameplay_prerequisites(shared.settings, shared.environment)
            self.assertEqual(problems, [
                f"the module config source equals server_modules_dir {workspace.conf / 'modules'}; set "
                'modules_config_dir to a separate directory or use a worldserver_config outside that config directory'])
            context = workspace.context({'modules_config_dir': str(separate)})
            with patch.object(verify_all, 'run_logged', side_effect=AssertionError):
                status, summary = verify_all.stage_gameplay(context, context.output / 'gameplay.log')
            self.assertEqual(status, 'unavailable')
            self.assertIn('already holds module configs (mod_ascension_compat.conf)', summary['reason'])
            (workspace.conf / 'modules' / 'mod_ascension_compat.conf').unlink()
            self.assertEqual(verify_all.gameplay_prerequisites(context.settings, context.environment), ([], []))

    def test_gameplay_command_is_accepted_by_the_batch_runner(self):
        workspace = self.workspace()
        client = write(workspace.base / 'client.cnf', '[client]\n')
        modules = workspace.base / 'module-configs'
        modules.mkdir()
        context = workspace.context({'database_client_config': str(client), 'modules_config_dir': str(modules)},
                                    scenarios=['frost', '/tmp/probe.json'])
        batch = verify_all.gameplay_module('batch')

        def accepted(context):
            return batch.resolve_clock(batch.parser().parse_args(verify_all.gameplay_command(context)[3:]))
        args = accepted(context)
        self.assertEqual((args.worldserver, args.config, args.mysql, args.mysqldump),
                         (workspace.worldserver, workspace.conf / 'worldserver.conf',
                          workspace.client / verify_all.executable_name('mysql'),
                          workspace.client / verify_all.executable_name('mysqldump')))
        self.assertEqual((args.modules_config_dir, args.database_client_config, args.output, args.jobs, args.scenario),
                         (modules, client, context.output / 'gameplay', 2, ['frost', '/tmp/probe.json']))
        self.assertEqual((args.clock, args.lanes, args.isolated_rerun, args.character_db_workers),
                         ('real', 1, True, 1))
        self.assertEqual(args.server_modules_dir, context.settings['server_modules_dir'])
        self.assertFalse(args.fresh_databases or args.refresh_world)
        for mode, flag in (('fresh', 'fresh_databases'), ('refresh', 'refresh_world')):
            context.world_databases = mode
            self.assertTrue(getattr(accepted(context), flag))
        requested = verify_all.parser().parse_args(['--gameplay-lanes', '7'])
        jobs, lanes = verify_all.gameplay_concurrency(requested, {'gameplay_jobs': 3}, 12)
        simulated = workspace.context(scenarios=context.scenarios, gameplay_clock=requested.gameplay_clock,
                                      gameplay_jobs=jobs, gameplay_lanes=lanes,
                                      gameplay_db_workers=verify_all.gameplay_db_workers(requested, {}))
        args = accepted(simulated)
        self.assertEqual((args.clock, args.lanes, args.jobs, args.isolated_rerun, args.scenario),
                         ('simulated', 7, 1, False, ['frost', '/tmp/probe.json']))
        self.assertEqual(args.character_db_workers, verify_all.DEFAULT_GAMEPLAY_DB_WORKERS)
        defaults = verify_all.gameplay_module('run').CLOCK_SETTINGS
        self.assertEqual((args.step_ms, args.active_wait_cap_ms, args.poll_cap_ms),
                         (defaults['StepMs'], defaults['ActiveWaitCapMs'], defaults['PollCapMs']))

    def test_world_database_modes_are_exclusive_options(self):
        self.assertEqual(verify_all.parser().parse_args(['--refresh-world']).world_databases, 'refresh')
        self.assertIsNone(verify_all.parser().parse_args([]).world_databases)
        with redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
            verify_all.parser().parse_args(['--fresh-databases', '--refresh-world'])

    def planned_gameplay(self, workspace, arguments):
        with patch.object(verify_all, 'load_catalog', return_value=fake_catalog()):
            status, stdout, stderr = self.run_main(workspace, ['--stages', 'gameplay', '--plan', *arguments])
        self.assertEqual((status, stderr), (0, ''))
        return json.loads(stdout)['stages']['gameplay']

    def test_gameplay_clock_defaults_to_one_simulated_server_and_real_keeps_parallel_servers(self):
        workspace = self.workspace()
        settings = write(workspace.base / 'settings.json', json.dumps({'gameplay_jobs': 3, 'gameplay_db_workers': 6}))
        default = verify_all.DEFAULT_GAMEPLAY_DB_WORKERS
        cases = [([], ('simulated', 15, 1, default)), (['--gameplay-lanes', '4'], ('simulated', 4, 1, default)),
                 (['--settings', str(settings)], ('simulated', 15, 1, 6)),
                 (['--settings', str(settings), '--gameplay-db-workers', '8'], ('simulated', 15, 1, 8)),
                 (['--gameplay-clock', 'real', '--settings', str(settings)], ('real', 1, 3, 1)),
                 (['--gameplay-clock', 'real', '--gameplay-jobs', '5'], ('real', 1, 5, 1))]
        for arguments, (clock, lanes, jobs, db_workers) in cases:
            with self.subTest(arguments=arguments):
                plan = self.planned_gameplay(workspace, arguments)
                self.assertEqual((plan['clock'], plan['lanes'], plan['gameplay_jobs'], plan['db_workers']),
                                 (clock, lanes, jobs, db_workers))
                command = plan['commands'][0]
                self.assertEqual(command[command.index('--jobs') + 1], str(jobs))
                if clock == 'simulated':
                    self.assertEqual(command[command.index('--clock'):command.index('--clock') + 6],
                                     ['--clock', 'simulated', '--lanes', str(lanes), '--character-db-workers',
                                      str(db_workers)])
                else:
                    self.assertFalse({'--clock', '--lanes', '--character-db-workers'} & set(command))

    def test_gameplay_concurrency_options_must_match_the_clock(self):
        workspace = self.workspace()
        for arguments, message in [(['--gameplay-jobs', '2'], '--gameplay-jobs above 1 requires --gameplay-clock real'),
                                   (['--gameplay-clock', 'real', '--gameplay-lanes', '2'],
                                    '--gameplay-lanes above 1 requires --gameplay-clock simulated'),
                                   (['--gameplay-clock', 'real', '--gameplay-db-workers', '2'],
                                    '--gameplay-db-workers above 1 requires --gameplay-clock simulated')]:
            with self.subTest(arguments=arguments):
                status, stdout, stderr = self.run_main(workspace, ['--stages', 'gameplay', *arguments])
                self.assertEqual((status, stdout), (verify_all.USAGE_ERROR, ''))
                self.assertIn(message, stderr)
        self.assertFalse((workspace.root / '.cache').exists())
        for arguments, (clock, lanes) in [(['--gameplay-jobs', '1'], ('simulated', 15)),
                                          (['--gameplay-clock', 'real', '--gameplay-lanes', '1'], ('real', 1)),
                                          (['--gameplay-clock', 'real', '--gameplay-db-workers', '1'], ('real', 1))]:
            with self.subTest(arguments=arguments):
                plan = self.planned_gameplay(workspace, arguments)
                self.assertEqual((plan['clock'], plan['lanes']), (clock, lanes))
        status, stdout, stderr = self.run_main(workspace, ['--stages', 'source', '--plan', '--gameplay-jobs', '2'])
        self.assertEqual((status, stderr), (0, ''))
        self.assertFalse(json.loads(stdout)['stages']['gameplay']['selected'])
        for arguments in (['--gameplay-lanes', '0'], ['--gameplay-lanes', '16'], ['--gameplay-clock', 'fast'],
                          ['--gameplay-db-workers', '0'], ['--gameplay-db-workers', '33']):
            with self.subTest(arguments=arguments), redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
                verify_all.parser().parse_args(arguments)
        self.assertEqual(verify_all.parser().parse_args(['--gameplay-lanes', '15']).gameplay_lanes, 15)
        self.assertEqual(verify_all.parser().parse_args(['--gameplay-db-workers', '32']).gameplay_db_workers, 32)

    def test_windows_selections_beyond_the_command_line_limit_are_rejected(self):
        workspace = self.workspace()
        selection = [f'scenario-{index:05d}-' + 'x' * 40 for index in range(800)]
        small, large = workspace.context(scenarios=selection[:10]), workspace.context(scenarios=selection)
        verify_all.check_command_length(large)
        with patch.object(verify_all, 'WINDOWS', True):
            verify_all.check_command_length(small)
            with self.assertRaisesRegex(ValueError, '800 scenarios exceeds the Windows command-line limit'):
                verify_all.check_command_length(large)


class ReportTests(WorkspaceTest):
    def run_with(self, workspace, results, arguments=()):
        output = workspace.base / 'result'
        functions = {name: (lambda status: lambda context, log: (status, {'reason': f'{status} fixture'}))(status)
                     for name, status in results.items()}
        with patch.dict(verify_all.STAGE_FUNCTIONS, functions):
            status, stdout, _ = self.run_main(workspace, ['--output', str(output), *arguments])
        return status, stdout, json.loads((output / 'report.json').read_text(encoding='utf-8'))

    def test_exit_code_and_final_line_follow_the_worst_selected_stage(self):
        cases = [({}, 0, 'PASSED'), ({'harness': 'unavailable'}, 3, 'INCOMPLETE'),
                 ({'harness': 'unavailable', 'source': 'failed'}, 1, 'FAILED')]
        for overrides, code, label in cases:
            with self.subTest(overrides=overrides):
                workspace = self.workspace()
                results = {name: 'passed' for name in verify_all.STAGES} | overrides
                status, stdout, report = self.run_with(workspace, results)
                self.assertEqual(status, code)
                self.assertEqual(report['status'], label.lower())
                self.assertEqual(stdout.splitlines()[-1],
                                 f"VERIFY ALL: {label} {workspace.base / 'result' / 'report.json'}")
                self.assertEqual(len(stdout.splitlines()), len(verify_all.STAGES) + 1)
                self.assertEqual(set(report), {'schema', 'status', 'stages', 'settings', 'output', 'seconds'})
                for stage in report['stages'].values():
                    self.assertEqual(set(stage), {'status', 'seconds', 'summary', 'log'})
                self.assertNotIn(SECRET, json.dumps(report) + stdout)

    def test_skipped_stages_do_not_affect_the_result(self):
        workspace = self.workspace()
        status, stdout, report = self.run_with(workspace, {'source': 'passed', 'unit': 'failed'},
                                          ['--stages', 'source,unit', '--skip', 'unit'])
        self.assertEqual(status, 0)
        self.assertEqual([name for name, stage in report['stages'].items() if stage['status'] != 'skipped'],
                         ['source'])
        self.assertEqual([line.split()[1] for line in stdout.splitlines()[:-1]],
                         ['PASSED', 'SKIPPED', 'SKIPPED', 'SKIPPED', 'SKIPPED'])

    def test_interrupt_fails_the_running_stage_blocks_the_rest_and_stops_processes(self):
        workspace = self.workspace()
        output = workspace.base / 'interrupted'

        def interrupted(context, log):
            raise KeyboardInterrupt
        with patch.object(verify_all, 'stop_active') as stop, \
                patch.dict(verify_all.STAGE_FUNCTIONS, {'source': lambda context, log: ('passed', {}),
                                                        'build': interrupted}):
            status, stdout, _ = self.run_main(workspace, ['--stages', 'source,build,unit', '--output', str(output)])
        report = json.loads((output / 'report.json').read_text(encoding='utf-8'))
        self.assertEqual(status, 1)
        self.assertEqual([report['stages'][name]['status'] for name in ('source', 'build', 'unit')],
                         ['passed', 'failed', 'blocked'])
        self.assertTrue(verify_all.STOPPING.is_set())
        self.assertEqual([line.split()[:2] for line in stdout.splitlines()],
                         [['source', 'PASSED'], ['build', 'FAILED'], ['unit', 'BLOCKED'], ['harness', 'SKIPPED'],
                          ['gameplay', 'SKIPPED'], ['VERIFY', 'ALL:']])
        stop.assert_called_once()

    def test_unexpected_stage_errors_fail_the_stage_and_still_write_the_report(self):
        workspace = self.workspace()

        def broken(context, log):
            raise KeyError('cases')
        with patch.dict(verify_all.STAGE_FUNCTIONS, {'source': broken}):
            output = workspace.base / 'broken'
            status, stdout, _ = self.run_main(workspace, ['--stages', 'source', '--output', str(output)])
        report = json.loads((output / 'report.json').read_text(encoding='utf-8'))
        self.assertEqual(status, 1)
        self.assertEqual(report['stages']['source']['summary']['message'], "KeyError: 'cases'")

    def test_unavailable_build_makes_dependent_stages_unavailable(self):
        workspace = self.workspace()
        workspace.environment['PATH'] = str(workspace.base / 'empty')
        with patch.dict(verify_all.STAGE_FUNCTIONS, {'harness': lambda context, log: ('passed', {})}):
            output = workspace.base / 'nocmake'
            status, _, _ = self.run_main(workspace, ['--stages', 'build,unit,harness,gameplay', '--output',
                                                     str(output)])
        report = json.loads((output / 'report.json').read_text(encoding='utf-8'))
        self.assertEqual(status, 3)
        self.assertEqual([report['stages'][name]['status'] for name in ('build', 'unit', 'harness', 'gameplay')],
                         ['unavailable', 'unavailable', 'passed', 'unavailable'])

    def test_invalid_invocations_exit_with_a_usage_error(self):
        workspace = self.workspace()
        write(workspace.base / 'used' / 'report.json', '{}')
        settings = write(workspace.base / 'settings.json', json.dumps({'unknown': 1}))
        for arguments in (['--output', str(workspace.base / 'used')], ['--settings', str(settings)],
                          ['--stages', 'source', '--skip', 'source'], ['--harness', 'missing', '--stages', 'harness']):
            with self.subTest(arguments=arguments):
                status, stdout, stderr = self.run_main(workspace, arguments)
                self.assertEqual(status, verify_all.USAGE_ERROR)
                self.assertIn('ERROR:', stderr)
                self.assertEqual(stdout, '')
        self.assertFalse((workspace.root / '.cache').exists())

    def test_default_outputs_are_claimed_atomically(self):
        root = Path(self.directory.name) / 'repo'
        claimed = [verify_all.claim_output(None, root) for _ in range(3)]
        self.assertEqual(len(set(claimed)), 3)
        self.assertTrue(all(path.is_dir() and path.parent == root / '.cache/verify-all' for path in claimed))

    def test_an_explicit_output_created_by_another_run_is_rejected(self):
        root = Path(self.directory.name) / 'repo'
        target = Path(self.directory.name) / 'explicit'
        with patch.object(Path, 'mkdir', side_effect=FileExistsError), \
                self.assertRaisesRegex(ValueError, 'created by another run'):
            verify_all.claim_output(target, root)
        self.assertEqual(verify_all.claim_output(target, root), target)
        self.assertTrue(target.is_dir())
        self.assertEqual(verify_all.claim_output(target, root), target)
        write(target / 'report.json')
        with self.assertRaisesRegex(ValueError, 'not empty'):
            verify_all.claim_output(target, root)

    def test_plan_executes_nothing_and_prints_no_secrets(self):
        workspace = self.workspace()
        write(workspace.root / 'apps/coa-tests/alpha/run.py', "parser.add_argument('--dbc-dir', type=Path)\n")
        write(workspace.root / 'apps/coa-tests/beta/run.py', "import os\nos.environ['VCToolsInstallDir']\n")
        output = workspace.base / 'planned'
        with patch.object(verify_all, 'launch', side_effect=AssertionError('executed')), \
                patch.object(verify_all, 'run_logged', side_effect=AssertionError('executed')), \
                patch.object(verify_all, 'run_captured', side_effect=AssertionError('executed')), \
                patch.object(verify_all, 'load_catalog', return_value=fake_catalog()):
            status, stdout, _ = self.run_main(workspace, ['--plan', '--output', str(output), '--spell', '116'],
                                              files=['apps/coa-tests/alpha/run.py', 'apps/coa-tests/beta/run.py'])
        plan = json.loads(stdout)
        self.assertEqual(status, 0)
        self.assertFalse(output.exists())
        self.assertNotIn(SECRET, stdout)
        self.assertEqual(plan['stages']['source']['commands'][0][2:], ['tools/check_source.py', '--all'])
        self.assertEqual([step[0] for step in plan['stages']['build']['steps']], ['build'])
        self.assertEqual(plan['harness']['counts'], {'run': 1, 'unavailable': 1})
        self.assertEqual(plan['stages']['gameplay']['scenarios']['count'], 2)
        self.assertIn('--scenario', plan['stages']['gameplay']['commands'][0])
        self.assertEqual(plan['settings']['worldserver_config'], str(workspace.conf / 'worldserver.conf'))


class SourceStageTests(WorkspaceTest):
    def test_check_source_json_decides_the_status_and_names_failed_commands(self):
        workspace = self.workspace()
        result = {'status': 'failed', 'selected_suites': ['gameplay'], 'results': [
            {'command': ['python', '-B', 'tools/check_comments.py', '--all'], 'status': 'passed'},
            {'command': ['python', '-B', 'apps/coa-gameplay-test/test_batch.py'], 'status': 'failed'}]}
        cases = [(verify_all.Outcome(1, json.dumps(result)), 'failed'),
                 (verify_all.Outcome(0, json.dumps({**result, 'status': 'passed', 'results': result['results'][:1]})),
                  'passed'),
                 (verify_all.Outcome(1, 'Traceback', 'boom'), 'failed')]
        for outcome, expected in cases:
            with self.subTest(expected=expected), \
                    patch.object(verify_all, 'run_captured', return_value=outcome) as runner:
                context = workspace.context(base='origin/main' if expected == 'passed' else None)
                status, summary = verify_all.stage_source(context, context.output / 'source.log')
                self.assertEqual(status, expected)
                arguments = runner.call_args.args[0][2:]
                self.assertEqual(arguments, ['tools/check_source.py', '--base', 'origin/main'] if context.base
                                 else ['tools/check_source.py', '--all'])
        self.assertIn('printed no JSON', summary['message'])


class RegistrationTests(unittest.TestCase):
    def test_verify_all_changes_select_its_regressions(self):
        self.assertIn('source-tools', check_source.select(['tools/verify_all.py'])['checks'])
        self.assertIn(['tools/test_verify_all.py'], check_source.SUITES['source-tools']['commands'])

    def test_gameplay_changes_run_the_batch_runner_regressions(self):
        self.assertIn('gameplay', check_source.select(['apps/coa-gameplay-test/batch.py'])['checks'])
        self.assertIn(['apps/coa-gameplay-test/test_batch.py'], check_source.SUITES['gameplay']['commands'])

    def test_gameplay_interfaces_used_by_verify_all_select_its_regressions(self):
        for name in ('batch.py', 'catalog.py', 'run.py'):
            with self.subTest(name=name):
                self.assertIn('source-tools', check_source.select([f'apps/coa-gameplay-test/{name}'])['checks'])
        self.assertNotIn('source-tools', check_source.select(['apps/coa-gameplay-test/scenarios/frostbolt.json'])
                         ['checks'])


if __name__ == '__main__':
    unittest.main()
