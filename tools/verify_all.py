CLI_DESCRIPTION = """Verify the checkout with one command: fast source checks, the native build, the Google Test
units, standalone Python/C++ harness scripts and the catalog gameplay scenarios in queue-mode worldservers.

Stages run in order: source, build, unit, harness, gameplay. --stages and --skip choose stages; --scenario,
--spell, --quest and --query narrow gameplay and --harness narrows the harness stage without disabling others.
Gameplay runs by default in one worldserver on a simulated clock, with --gameplay-lanes concurrent cases and
--gameplay-db-workers character database workers at READ-COMMITTED isolation. Accelerated failures remain failed;
--gameplay-real-pace-rerun explicitly enables slower same-server diagnostics. --gameplay-clock real runs the
real-clock reference instead: --gameplay-jobs parallel worldservers, one case at a time each, with one character
database worker and isolated single-mode reruns.
Settings come from the optional conf/verify-all.json plus auto-detection. --plan prints the resolved plan as JSON
and executes nothing. Exit status: 0 every selected stage passed, 1 something failed or was blocked, 3 nothing
failed but some scope was unavailable (a gameplay selection of exploratory scenario files only included),
2 invalid invocation or settings.
"""

import argparse
import ast
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from datetime import datetime, timezone
import importlib.util
import itertools
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import signal
import subprocess
import sys
import threading
import time

from check_change_boundaries import ROOT
from check_source import SUITES


STAGES = ('source', 'build', 'unit', 'harness', 'gameplay')
BUILD_DEPENDENT = frozenset({'unit', 'gameplay'})
GAMEPLAY_DIRECTORY = 'apps/coa-gameplay-test'
DEFAULT_SETTINGS = 'conf/verify-all.json'
PATH_SETTINGS = ('build_directory', 'worldserver', 'worldserver_config', 'mysql', 'mysqldump',
                 'database_client_config', 'server_modules_dir', 'modules_config_dir', 'dbc_directory',
                 'workspace_tools', 'datamine_directory', 'mysql_server_bin')
COUNT_SETTINGS = ('jobs', 'gameplay_jobs', 'gameplay_db_workers')
SETTING_KEYS = frozenset((*PATH_SETTINGS, *COUNT_SETTINGS, 'cmake_args'))
CONFIGURED_DIRECTORIES = ('dbc_directory', 'datamine_directory', 'workspace_tools', 'mysql_server_bin')
PROGRAM_SETTINGS = ('mysql', 'mysqldump')
MYSQL_CLIENT_DIRECTORIES = (Path('/opt/homebrew/opt/mysql-client/bin'), Path('/usr/local/opt/mysql-client/bin'))
HOMEBREW_READLINE_DIRECTORIES = (Path('/opt/homebrew/opt/readline'), Path('/usr/local/opt/readline'))
HARNESS_DBC_DEFAULT = 'env/dist/data/dbc'
CMAKE_TRUE = frozenset({'1', 'ON', 'YES', 'TRUE', 'Y'})
GENERATOR_OUTPUTS = (('Ninja', 'build.ninja'), ('Makefiles', 'Makefile'), ('Visual Studio', '*.sln*'),
                     ('Xcode', '*.xcodeproj'))
MULTI_CONFIG_GENERATORS = ('Visual Studio', 'Xcode', 'Multi-Config')
DEFAULT_CONFIGURATION = 'RelWithDebInfo'
WINDOWS = os.name == 'nt'
PROCESS_GROUP_FLAG = getattr(subprocess, 'CREATE_NEW_PROCESS_GROUP', 0x200)
BREAK_SIGNAL = getattr(signal, 'CTRL_BREAK_EVENT', None)
WINDOWS_COMMAND_LIMIT = 32767
COMMAND_MARGIN = 1024
HARNESS_TIMEOUT = 900
STOP_GRACE = 300
TAIL = 4000
MSVC_REQUIREMENT = re.compile(r'''environ\[\s*['"]VCToolsInstallDir['"]\s*\]''')
MSVC_LOOKUP = re.compile(r'''environ\.get\(\s*['"]VCToolsInstallDir['"]''')
PORTABLE_COMPILER = re.compile(r'''\bCXX\b|clang|g\+\+|['"]c\+\+['"]''')
WORKSPACE_TOOL = re.compile(r'Test-[A-Za-z0-9_-]+\.py')
SIBLING_HARNESS = re.compile(r'''['"]([A-Za-z0-9_]+)/run\.py['"]''')
CTEST_SUMMARY = re.compile(r'(\d+)% tests passed, (\d+) tests? failed out of (\d+)')
EXIT_CODES = {'passed': 0, 'failed': 1, 'incomplete': 3}
WORLD_DATABASE_FLAGS = {'fresh': '--fresh-databases', 'refresh': '--refresh-world'}
SIMULATED_CLOCK = 'simulated'
REAL_CLOCK = 'real'
GAMEPLAY_CLOCKS = (SIMULATED_CLOCK, REAL_CLOCK)
DEFAULT_GAMEPLAY_LANES = 15
MAXIMUM_GAMEPLAY_LANES = 15
DEFAULT_GAMEPLAY_DB_WORKERS = 16
MAXIMUM_GAMEPLAY_DB_WORKERS = 32
USAGE_ERROR = 2
GAMEPLAY_EXPLORATORY_EXIT = 3
EXPLORATORY_ONLY = 'only exploratory scenarios ran; they passed natively, without combined verification'
STOPPING = threading.Event()
ACTIVE = set()
ACTIVE_LOCK = threading.Lock()


class Interrupted(RuntimeError):
    pass


@dataclass
class Outcome:
    returncode: int | None
    stdout: str = ''
    stderr: str = ''
    timed_out: bool = False


@dataclass
class Context:
    root: Path
    raw: dict
    settings: dict
    output: Path
    stages: list
    jobs: int
    gameplay_jobs: int
    gameplay_clock: str
    gameplay_lanes: int
    base: str | None
    scenarios: list
    harness: list
    environment: dict
    world_databases: str | None = None
    gameplay_db_workers: int = 1
    gameplay_real_pace_rerun: bool = False


def absolute(value, base):
    path = Path(value).expanduser()
    return path if path.is_absolute() else base / path


def executable_name(name):
    return name + '.exe' if WINDOWS else name


def is_executable(path):
    return path.is_file() and os.access(path, os.X_OK)


def load_settings(path, explicit):
    if not path.is_file():
        if explicit:
            raise ValueError(f'Settings file not found: {path}')
        return {}
    try:
        data = json.loads(path.read_text(encoding='utf-8-sig'))
    except ValueError as error:
        raise ValueError(f'Invalid JSON in settings file {path}: {error}') from None
    if not isinstance(data, dict):
        raise ValueError(f'Settings must be a JSON object: {path}')
    unknown = sorted(set(data) - SETTING_KEYS)
    if unknown:
        raise ValueError(f'Unknown settings in {path}: {", ".join(unknown)}')
    data = {key: value for key, value in data.items() if value is not None}
    for key in PATH_SETTINGS:
        if key in data and not (isinstance(data[key], str) and data[key].strip()):
            raise ValueError(f'Setting {key} must be a path string')
    for key in COUNT_SETTINGS:
        if key in data and not (type(data[key]) is int and data[key] > 0):
            raise ValueError(f'Setting {key} must be a positive integer')
    if data.get('gameplay_db_workers', 1) > MAXIMUM_GAMEPLAY_DB_WORKERS:
        raise ValueError(f'Setting gameplay_db_workers must be at most {MAXIMUM_GAMEPLAY_DB_WORKERS}')
    arguments = data.get('cmake_args', [])
    if not isinstance(arguments, list) or not all(isinstance(argument, str) for argument in arguments):
        raise ValueError('Setting cmake_args must be a list of strings')
    return data


def cmake_cache(build):
    path = build / 'CMakeCache.txt'
    if not path.is_file():
        return {}
    values = {}
    for line in path.read_text(encoding='utf-8', errors='replace').splitlines():
        match = re.match(r'([A-Za-z0-9_.+-]+):[A-Za-z_]+=(.*)\Z', line)
        if match:
            values.setdefault(match[1], match[2])
    return values


def testing_enabled(cache):
    return cache.get('BUILD_TESTING', '').strip().upper() in CMAKE_TRUE


def build_configuration(cache):
    generator = cache.get('CMAKE_GENERATOR', '')
    if cache.get('CMAKE_CONFIGURATION_TYPES') or any(marker in generator for marker in MULTI_CONFIG_GENERATORS):
        return cache.get('CMAKE_BUILD_TYPE') or DEFAULT_CONFIGURATION
    return None


def build_files_generated(build, cache):
    generator = cache.get('CMAKE_GENERATOR', '')
    patterns = ([pattern for marker, pattern in GENERATOR_OUTPUTS if marker in generator]
                or [pattern for _, pattern in GENERATOR_OUTPUTS])
    return any(next(build.glob(pattern), None) is not None for pattern in patterns)


def needs_configure(build):
    return not (build / 'CMakeCache.txt').is_file() or not build_files_generated(build, cmake_cache(build))


def conf_directory(cache, worldserver, windows):
    prefix = cache.get('CMAKE_INSTALL_PREFIX')
    if not windows:
        if cache.get('CONF_DIR'):
            return Path(cache['CONF_DIR'])
        return Path(prefix) / 'etc' if prefix else None
    candidates = [directory / 'configs' for directory in (worldserver.parent if worldserver else None,
                                                           Path(prefix) if prefix else None) if directory]
    return next((candidate for candidate in candidates if (candidate / 'worldserver.conf').is_file()),
                next(iter(candidates), None))


def find_program(name, environment, fallbacks=()):
    found = shutil.which(name, path=environment.get('PATH', ''))
    if found:
        return Path(found)
    return next((Path(directory) / executable_name(name) for directory in fallbacks
                 if is_executable(Path(directory) / executable_name(name))), None)


def find_mysql_tool(name, environment):
    return find_program(name, environment, MYSQL_CLIENT_DIRECTORIES)


def cached_program(cache, key):
    value = cache.get(key)
    return Path(value) if value and is_executable(Path(value)) else None


def mysql_client_directory(cache, environment):
    configured = cached_program(cache, 'MYSQL_CONFIG')
    found = configured or find_mysql_tool('mysql_config', environment)
    return found.parent if found else None


def configured_program(value, root, environment):
    if Path(value).name == value:
        found = shutil.which(value, path=environment.get('PATH', ''))
        if found:
            return Path(found)
    return absolute(value, root)


def find_worldserver(build, configuration=None):
    name = executable_name('worldserver')
    found = []
    for directory, subdirectories, files in os.walk(build):
        subdirectories[:] = sorted(entry for entry in subdirectories
                                   if entry != 'CMakeFiles' and not entry.startswith('.'))
        if name in files and is_executable(Path(directory) / name):
            found.append(Path(directory) / name)
    preferred = [path for path in found if configuration in path.parts]
    return max(preferred or found, key=lambda path: path.stat().st_mtime, default=None)


def gameplay_module(name):
    key = f'coa_gameplay_{name}'
    if key in sys.modules:
        return sys.modules[key]
    directory = ROOT / GAMEPLAY_DIRECTORY
    if str(directory) not in sys.path:
        sys.path.append(str(directory))
    spec = importlib.util.spec_from_file_location(key, directory / f'{name}.py')
    module = importlib.util.module_from_spec(spec)
    sys.modules[key] = module
    try:
        spec.loader.exec_module(module)
    except BaseException:
        sys.modules.pop(key, None)
        raise
    return module


def load_catalog():
    return gameplay_module('catalog')


def data_directory(config_path, worldserver, environment):
    runner = gameplay_module('run')
    try:
        value = Path(runner.source_setting(runner.read_config(config_path), 'DataDir', '.', environment))
    except (OSError, ValueError, UnicodeError):
        return None
    if value.is_absolute():
        return value
    return (worldserver.parent / value).resolve() if worldserver else None


def dbc_directory(settings, environment, root):
    if settings['dbc_directory']:
        return settings['dbc_directory']
    candidates = [Path(environment['COA_DBC_DIR'])] if environment.get('COA_DBC_DIR') else []
    config = settings['worldserver_config']
    if config and config.is_file():
        data = data_directory(config, settings['worldserver'], environment)
        if data:
            candidates.append(data / 'dbc')
    candidates.append(root / HARNESS_DBC_DEFAULT)
    return next((candidate for candidate in candidates if (candidate / 'Spell.dbc').is_file()), None)


def resolve_settings(raw, root, environment):
    settings = {key: absolute(raw[key], root) if key in raw else None for key in PATH_SETTINGS}
    for tool in PROGRAM_SETTINGS:
        if tool in raw:
            settings[tool] = configured_program(raw[tool], root, environment)
    build = settings['build_directory'] = settings['build_directory'] or root / 'build'
    cache = cmake_cache(build)
    settings['configuration'] = build_configuration(cache)
    settings['worldserver'] = settings['worldserver'] or find_worldserver(build, settings['configuration'])
    conf = conf_directory(cache, settings['worldserver'], WINDOWS)
    settings['conf_dir'] = conf
    if conf:
        settings['worldserver_config'] = settings['worldserver_config'] or conf / 'worldserver.conf'
        if not WINDOWS:
            settings['server_modules_dir'] = settings['server_modules_dir'] or conf / 'modules'
    for tool in ('mysql', 'mysqldump'):
        settings[tool] = settings[tool] or find_mysql_tool(tool, environment)
    settings['mysql_client_bin'] = mysql_client_directory(cache, environment)
    settings['dbc_directory'] = dbc_directory(settings, environment, root)
    return settings


def check_configured_directories(raw, settings):
    for key in CONFIGURED_DIRECTORIES:
        if key in raw and not settings[key].is_dir():
            raise ValueError(f'Configured {key} does not exist: {settings[key]}')


def optional_text(value):
    return str(value) if value else None


def settings_report(settings):
    return {key: optional_text(value) for key, value in settings.items()}


def child_environment(environment):
    result = dict(environment)
    result.pop('PYTHONOPTIMIZE', None)
    return result


def build_environment(context):
    result = child_environment(context.environment)
    directory = context.settings.get('mysql_client_bin')
    entries = [entry for entry in result.get('PATH', '').split(os.pathsep) if entry]
    if directory and str(directory) not in entries:
        result['PATH'] = os.pathsep.join([str(directory), *entries])
    return result


def process_group_options():
    return {'creationflags': PROCESS_GROUP_FLAG} if WINDOWS else {'start_new_session': True}


def launch(command, **options):
    if STOPPING.is_set():
        raise Interrupted('Verification was interrupted')
    process = subprocess.Popen([str(part) for part in command], stdin=subprocess.DEVNULL, **options,
                               **process_group_options())
    with ACTIVE_LOCK:
        ACTIVE.add(process)
    if STOPPING.is_set():
        kill_tree(process)
    return process


def release(process):
    with ACTIVE_LOCK:
        ACTIVE.discard(process)


def request_stop(process):
    if process.poll() is not None:
        return
    try:
        if WINDOWS:
            process.send_signal(BREAK_SIGNAL)
        else:
            process.terminate()
    except OSError:
        pass


def kill_tree(process):
    if WINDOWS:
        if process.poll() is None:
            subprocess.run(['taskkill', '/T', '/F', '/PID', str(process.pid)], capture_output=True, check=False)
    else:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except (ProcessLookupError, PermissionError):
            pass
    try:
        process.kill()
    except OSError:
        pass


def stop_active(grace=STOP_GRACE):
    with ACTIVE_LOCK:
        processes = list(ACTIVE)
    for process in processes:
        request_stop(process)
    deadline = time.monotonic() + grace
    try:
        for process in processes:
            process.wait(timeout=max(0.0, deadline - time.monotonic()))
    except (KeyboardInterrupt, subprocess.TimeoutExpired):
        pass
    for process in processes:
        kill_tree(process)
        release(process)


def command_text(command):
    return shlex.join(str(part) for part in command)


def run_logged(command, log, environment, cwd):
    with log.open('a', encoding='utf-8') as stream:
        stream.write(f'$ {command_text(command)}\n')
        stream.flush()
        process = launch(command, cwd=cwd, env=environment, stdout=stream, stderr=subprocess.STDOUT)
        returncode = process.wait()
    release(process)
    return returncode


def run_captured(command, environment, cwd, timeout=None):
    process = launch(command, cwd=cwd, env=environment, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                     text=True, encoding='utf-8', errors='replace')
    try:
        stdout, stderr = process.communicate(timeout=timeout)
        outcome = Outcome(process.returncode, stdout or '', stderr or '')
    except subprocess.TimeoutExpired:
        kill_tree(process)
        stdout, stderr = process.communicate()
        outcome = Outcome(None, stdout or '', stderr or '', timed_out=True)
    release(process)
    return outcome


def read_text(path):
    try:
        return path.read_text(encoding='utf-8', errors='replace')
    except OSError:
        return ''


def read_tail(path):
    return read_text(path)[-TAIL:]


def source_command(base):
    return [sys.executable, '-B', 'tools/check_source.py', *(['--base', base] if base else ['--all'])]


def stage_source(context, log):
    outcome = run_captured(source_command(context.base), child_environment(context.environment), context.root)
    log.write_text(f'$ {command_text(source_command(context.base))}\n{outcome.stdout}{outcome.stderr}',
                   encoding='utf-8')
    try:
        data = json.loads(outcome.stdout)
    except ValueError:
        data = None
    if not isinstance(data, dict):
        return 'failed', {'returncode': outcome.returncode, 'message': 'check_source.py printed no JSON result',
                          'tail': (outcome.stdout + outcome.stderr)[-TAIL:]}
    results = data.get('results', [])
    failed = [command_text(result.get('command', [])[2:]) for result in results if result.get('status') != 'passed']
    summary = {'counts': {'passed': len(results) - len(failed), 'failed': len(failed)},
               'selected_suites': data.get('selected_suites', []), 'failed_commands': failed}
    passed = outcome.returncode == 0 and data.get('status') == 'passed' and not failed
    return ('passed' if passed else 'failed'), summary


def cmake_program(context):
    cache = cmake_cache(context.settings['build_directory'])
    return cached_program(cache, 'CMAKE_COMMAND') or find_program('cmake', context.environment)


def ctest_program(context):
    cache = cmake_cache(context.settings['build_directory'])
    cmake = cmake_program(context)
    sibling = cmake.parent / executable_name('ctest') if cmake else None
    return (cached_program(cache, 'CMAKE_CTEST_COMMAND') or find_program('ctest', context.environment)
            or (sibling if sibling and is_executable(sibling) else None))


def configure_arguments(context):
    if 'cmake_args' in context.raw:
        return list(context.raw['cmake_args'])
    cached = cmake_cache(context.settings['build_directory']).get('CMAKE_GENERATOR')
    if cached:
        generator = ['-G', cached]
    elif find_program('ninja', context.environment):
        generator = ['-G', 'Ninja']
    else:
        generator = []
    prefix = (context.root / 'env/dist').as_posix()
    return [*generator, '-DCMAKE_BUILD_TYPE=RelWithDebInfo', '-DAPPS_BUILD=world-only', '-DSCRIPTS=static',
            '-DMODULES=static', '-DBUILD_TESTING=ON', f'-DCMAKE_INSTALL_PREFIX={prefix}', *readline_arguments(),
            *line_table_debug_arguments()]


def line_table_debug_arguments(platform=sys.platform):
    if platform != 'darwin':
        return []
    flags = '-O2 -g1 -DNDEBUG'
    return [f'-DCMAKE_C_FLAGS_RELWITHDEBINFO={flags}', f'-DCMAKE_CXX_FLAGS_RELWITHDEBINFO={flags}']


def readline_arguments(platform=sys.platform, candidates=HOMEBREW_READLINE_DIRECTORIES):
    if platform != 'darwin':
        return []
    for directory in candidates:
        library = directory / 'lib' / 'libreadline.dylib'
        if library.is_file():
            return [f'-DREADLINE_LIBRARY={library.as_posix()}',
                    f"-DREADLINE_INCLUDE_DIR={(directory / 'include').as_posix()}"]
    return []


def configure_command(context, cmake):
    build = context.settings['build_directory']
    return [str(cmake), '-S', str(context.root), '-B', str(build), *configure_arguments(context)]


def reconfigure_command(context, cmake):
    return [str(cmake), '-S', str(context.root), '-B', str(context.settings['build_directory']), '-DBUILD_TESTING=ON']


def configuration_arguments(context, flag):
    configuration = build_configuration(cmake_cache(context.settings['build_directory']))
    return [flag, configuration] if configuration else []


def compile_command(context, cmake):
    return [str(cmake), '--build', str(context.settings['build_directory']),
            *configuration_arguments(context, '--config'), '--parallel', str(context.jobs)]


def planned_build_steps(context, cmake):
    build = context.settings['build_directory']
    steps = []
    if needs_configure(build):
        steps.append(['configure', configure_command(context, cmake)])
    elif not testing_enabled(cmake_cache(build)):
        steps.append(['reconfigure', reconfigure_command(context, cmake)])
    steps.append(['build', compile_command(context, cmake)])
    return steps


def stage_build(context, log):
    cmake = cmake_program(context)
    if cmake is None:
        return 'unavailable', {'reason': 'cmake was not found on PATH'}
    build = context.settings['build_directory']
    environment = build_environment(context)
    completed = []

    def step(label, command):
        returncode = run_logged(command, log, environment, context.root)
        if returncode:
            return {'steps': completed, 'message': f'{label} failed with exit code {returncode}',
                    'returncode': returncode, 'tail': read_tail(log)}
        completed.append(label)
        return None

    if needs_configure(build):
        failure = step('configure', configure_command(context, cmake))
        if failure:
            return 'failed', failure
    if not testing_enabled(cmake_cache(build)):
        failure = step('reconfigure', reconfigure_command(context, cmake))
        if failure:
            return 'failed', failure
    failure = step('build', compile_command(context, cmake))
    if failure:
        return 'failed', failure
    return 'passed', {'steps': completed, 'build_directory': str(build),
                      'configuration': build_configuration(cmake_cache(build)),
                      'path_prefix': optional_text(context.settings['mysql_client_bin'])}


def unit_command(context, ctest):
    return [str(ctest), '--test-dir', str(context.settings['build_directory']),
            *configuration_arguments(context, '-C'), '--output-on-failure', '--parallel', str(context.jobs),
            '--no-tests=error']


def unit_blocker(context):
    build = context.settings['build_directory']
    if not (build / 'CTestTestfile.cmake').is_file():
        return f'no configured test build in {build}'
    if not testing_enabled(cmake_cache(build)):
        return f'BUILD_TESTING is off in {build}'
    if ctest_program(context) is None:
        return 'ctest was not found'
    return None


def stage_unit(context, log):
    blocker = unit_blocker(context)
    if blocker:
        return 'unavailable', {'reason': blocker}
    returncode = run_logged(unit_command(context, ctest_program(context)), log,
                            child_environment(context.environment), context.root)
    text = read_text(log)
    summary = {'returncode': returncode}
    matches = CTEST_SUMMARY.findall(text)
    if matches:
        _, failed, total = matches[-1]
        summary['counts'] = {'tests': int(total), 'failed': int(failed)}
    if returncode:
        summary['tail'] = text[-TAIL:]
    return ('passed' if returncode == 0 else 'failed'), summary


def repository_files(root):
    result = subprocess.run(['git', '-c', 'core.quotepath=false', 'ls-files', '--cached', '--others',
                             '--exclude-standard', '-z'], cwd=root, check=True, capture_output=True)
    return sorted({name for name in result.stdout.decode('utf-8').split('\0') if name})


def registered_scripts():
    return {command[0] for suite in SUITES.values() for command in suite['commands']}


def is_harness_script(name):
    path = Path(name)
    return name.startswith('apps/coa-tests/') and len(path.parts) == 4 and path.name == 'run.py'


def harness_scripts(names, registered, root):
    return [name for name in names
            if (is_harness_script(name) or (Path(name).name.startswith('test_') and name.endswith('.py')
                                            and name not in registered))
            and (root / name).is_file()]


def harness_name(name):
    path = Path(name)
    return path.parent.name if path.name == 'run.py' else path.stem


def harness_keys(name):
    path = Path(name)
    return {name, harness_name(name), path.parent.name, path.parent.as_posix()}


def filter_harness(names, filters):
    if not filters:
        return list(names)
    unmatched = [value for value in filters if not any(value in harness_keys(name) for name in names)]
    if unmatched:
        raise ValueError(f'No harness script matches: {", ".join(unmatched)}')
    return [name for name in names if harness_keys(name) & set(filters)]


def parse_source(source):
    try:
        return ast.parse(source)
    except SyntaxError:
        return ast.Module(body=[], type_ignores=[])


def is_add_argument(node):
    return isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute) and node.func.attr == 'add_argument'


def is_repository_parent(node):
    return (isinstance(node, ast.Attribute) and node.attr == 'parent' and isinstance(node.value, ast.Name)
            and node.value.id == 'ROOT')


def outside_references(tree):
    defaults = {id(inner) for node in ast.walk(tree) if is_add_argument(node)
                for keyword in node.keywords if keyword.arg == 'default' for inner in ast.walk(keyword.value)}
    return {node.right.value for node in ast.walk(tree)
            if isinstance(node, ast.BinOp) and isinstance(node.op, ast.Div) and id(node) not in defaults
            and is_repository_parent(node.left) and isinstance(node.right, ast.Constant)
            and isinstance(node.right.value, str)}


def reachable_sources(name, source, root):
    texts, seen, pending = [source], {name}, SIBLING_HARNESS.findall(source)
    while pending:
        sibling = f'apps/coa-tests/{pending.pop()}/run.py'
        if sibling in seen or not (root / sibling).is_file():
            continue
        seen.add(sibling)
        text = (root / sibling).read_text(encoding='utf-8', errors='replace')
        texts.append(text)
        pending.extend(SIBLING_HARNESS.findall(text))
    return texts


def compiler_problem(source, environment):
    if 'VCToolsInstallDir' not in source or environment.get('VCToolsInstallDir'):
        return None
    fallback = MSVC_LOOKUP if WINDOWS else PORTABLE_COMPILER
    if MSVC_REQUIREMENT.search(source) and not fallback.search(source):
        return 'requires the MSVC toolchain (VCToolsInstallDir is unset)'
    if WINDOWS:
        compiler = environment.get('CXX') or 'cl.exe'
        if find_program(compiler, environment) is None:
            return f'requires the MSVC toolchain or {compiler} on PATH (VCToolsInstallDir is unset)'
    return None


def declared_options(tree):
    options = {}
    for node in ast.walk(tree):
        if not is_add_argument(node):
            continue
        names = [argument.value for argument in node.args
                 if isinstance(argument, ast.Constant) and isinstance(argument.value, str)]
        if not names:
            continue
        keywords = {keyword.arg: keyword.value for keyword in node.keywords if keyword.arg}
        if names[0].startswith('-'):
            flag = next((value for value in names if value.startswith('--')), names[0])
            value = keywords.get('required')
            required = isinstance(value, ast.Constant) and value.value is True
        else:
            flag = names[0]
            nargs = keywords.get('nargs')
            required = not (isinstance(nargs, ast.Constant) and nargs.value in ('?', '*'))
        options[flag] = options.get(flag, False) or required
    return options


def supplied_arguments(settings):
    dbc = settings.get('dbc_directory')
    datamine = settings.get('datamine_directory')
    values = {}
    if dbc and (dbc / 'Spell.dbc').is_file():
        values['--spell-dbc'] = dbc / 'Spell.dbc'
    if dbc and dbc.is_dir():
        values['--dbc-dir'] = dbc
    if datamine and datamine.is_dir():
        values['--datamine-dir'] = datamine
    server = settings.get('mysql_server_bin')
    if server and all(is_executable(server / executable_name(name)) for name in ('mysql', 'mysqld')):
        values['--mysql-bin'] = server
    return values


def classify_harness(name, settings, environment, root):
    source = (root / name).read_text(encoding='utf-8', errors='replace')
    tree = parse_source(source)
    options = declared_options(tree)
    command = [sys.executable, '-B', name]
    reasons = []
    compiler = next(filter(None, (compiler_problem(text, environment)
                                  for text in reachable_sources(name, source, root))), None)
    if compiler:
        reasons.append(compiler)
    tools = sorted(set(WORKSPACE_TOOL.findall(source)))
    external = outside_references(tree)
    if tools and '--workspace-tools' in options:
        directory = settings.get('workspace_tools') or root.parent / 'tools'
        missing = [tool for tool in tools if not (directory / tool).is_file()]
        if missing:
            reasons.append(f'requires workspace tools missing from {directory}: {", ".join(missing)}')
        else:
            command += ['--workspace-tools', str(directory)]
    else:
        external |= {f'tools/{tool}' for tool in tools}
    absent = sorted(reference for reference in external if not (root.parent / reference).exists())
    if absent:
        reasons.append(f'requires files outside the repository missing from {root.parent}: {", ".join(absent)}')
    supplied = supplied_arguments(settings)
    unsupplied = [flag for flag, required in options.items() if required and flag not in supplied]
    if unsupplied:
        reasons.append(f'requires {", ".join(unsupplied)}, which the settings cannot supply')
    for flag in options:
        if flag in supplied:
            command += [flag, str(supplied[flag])]
    entry = {'name': harness_name(name), 'path': name, 'command': command}
    if reasons:
        entry.update(status='unavailable', reason='; '.join(reasons))
    else:
        entry['status'] = 'run'
    return entry


def harness_environment(context):
    environment = child_environment(context.environment)
    if context.settings.get('dbc_directory'):
        environment['COA_DBC_DIR'] = str(context.settings['dbc_directory'])
    return environment


def run_harness(entry, environment, log, lock, root):
    started = time.monotonic()
    try:
        outcome = run_captured(entry['command'], environment, root, timeout=HARNESS_TIMEOUT)
    except OSError as error:
        outcome = Outcome(None, '', str(error))
    result = {'name': entry['name'], 'status': 'passed' if outcome.returncode == 0 else 'failed',
              'seconds': round(time.monotonic() - started, 3)}
    if outcome.timed_out:
        result['message'] = f'timed out after {HARNESS_TIMEOUT} s'
    elif outcome.returncode is not None:
        result['returncode'] = outcome.returncode
    output = outcome.stdout + outcome.stderr
    if result['status'] == 'failed':
        result['tail'] = output[-TAIL:]
    with lock, log.open('a', encoding='utf-8') as stream:
        stream.write(f"== {entry['path']}: {result['status']} ({result['seconds']} s)\n"
                     f"$ {command_text(entry['command'])}\n{output}\n")
    return result


def stage_harness(context, log):
    log.write_text('', encoding='utf-8')
    results = {entry['path']: {'name': entry['name'], 'status': 'unavailable', 'reason': entry['reason']}
               for entry in context.harness if entry['status'] == 'unavailable'}
    runnable = [entry for entry in context.harness if entry['status'] == 'run']
    environment = harness_environment(context)
    lock = threading.Lock()
    if runnable:
        executor = ThreadPoolExecutor(max_workers=max(1, min(context.jobs, len(runnable))))
        try:
            finished = list(executor.map(lambda entry: run_harness(entry, environment, log, lock, context.root),
                                         runnable))
        finally:
            executor.shutdown(wait=False, cancel_futures=True)
        results.update({entry['path']: result for entry, result in zip(runnable, finished)})
    counts = {status: sum(result['status'] == status for result in results.values())
              for status in ('passed', 'failed', 'unavailable')}
    status = 'failed' if counts['failed'] else 'unavailable' if counts['unavailable'] else 'passed'
    return status, {'counts': counts, 'scripts': dict(sorted(results.items()))}


def resolve_scenarios(args):
    requested = list(args.scenario or [])
    filtered = args.spell is not None or args.quest is not None or bool(args.query)
    if not requested and not filtered:
        return []
    catalog = load_catalog()
    rows = catalog.catalog()
    known = {row['id'] for row in rows}
    selected = []
    for value in requested:
        if value in known:
            selected.append(value)
        elif Path(value).is_file():
            selected.append(scenario_file(value, rows))
        else:
            raise ValueError(f'Unknown scenario (neither a catalog id nor a file): {value}')
    if filtered:
        matches = catalog.select(rows, args.query or '', args.spell, args.quest)
        if not matches:
            raise ValueError('No catalog scenario matches the --spell/--quest/--query filters')
        selected += [row['id'] for row in matches]
    selected = list(dict.fromkeys(selected))
    return [] if set(selected) == known else selected


def scenario_file(value, rows):
    resolved = Path(value).resolve()
    catalog_id = next((row['id'] for row in rows if (ROOT / row['path']).resolve() == resolved), None)
    if catalog_id:
        return catalog_id
    runner = gameplay_module('run')
    try:
        runner.validate(runner.read_json(resolved))
    except (OSError, ValueError, KeyError, TypeError) as error:
        raise ValueError(f'Invalid scenario file {value}: {error}') from None
    return str(resolved)


def inactive_module_scenarios(context, rows=None):
    rows = load_catalog().catalog() if rows is None else rows
    modules = [row for row in rows if row.get('module')]
    if not modules or context.scenarios:
        return []
    runner = gameplay_module('run')
    cache = cmake_cache(context.settings['build_directory'])
    config_path = context.settings.get('worldserver_config')
    config = runner.read_config(config_path) if config_path and config_path.is_file() else {}
    config_directory = context.settings.get('modules_config_dir')
    if config_directory is None and config_path:
        config_directory = config_path.parent / 'modules'
    if config_directory:
        for path in sorted(config_directory.glob('*.conf')):
            config.update(runner.read_config(path))
    skipped = []
    for row in modules:
        mode = cache.get('MODULE_' + row['module'].upper(), 'default')
        built = mode != 'disabled' and (mode != 'default' or cache.get('MODULES', 'static') != 'disabled')
        enabled = all(str(runner.source_setting(config, key, default, context.environment)).upper() in CMAKE_TRUE
                      for key, default in row.get('configuration', {}).items())
        if (built and enabled) != row.get('module_active', True):
            skipped.append(row['id'])
    return skipped


def scenario_plan(context):
    catalog = load_catalog()
    rows = catalog.catalog()
    if not context.scenarios:
        skipped = inactive_module_scenarios(context, rows)
        if skipped:
            return {'selection': 'all enabled catalog scenarios', 'count': len(rows) - len(skipped),
                    'skipped_optional': skipped}
        return {'selection': 'all catalog scenarios', 'count': len(rows)}
    known = {row['id'] for row in rows}
    cases = [value for value in context.scenarios if value in known]
    exploratory = [value for value in context.scenarios if value not in known]
    expanded = catalog.companion_cases(cases, catalog.bindings())
    return {'selection': context.scenarios, 'count': len(expanded) + len(exploratory), 'catalog_cases': expanded,
            'exploratory': exploratory}


def gameplay_prerequisites(settings, environment):
    required = ['worldserver', 'worldserver_config', 'mysql', 'mysqldump']
    if not WINDOWS:
        required.append('server_modules_dir')
    optional = [key for key in ('database_client_config', 'modules_config_dir') if settings.get(key)]
    missing = []
    for key in required + optional:
        path = settings.get(key)
        if path is None:
            missing.append(key)
        elif not path.exists():
            missing.append(f'{key} ({path})')
    return missing, [*client_data_problems(settings, environment), *module_staging_problems(settings)]


def client_data_problems(settings, environment):
    config, worldserver = settings.get('worldserver_config'), settings.get('worldserver')
    if not (config and config.is_file() and worldserver and worldserver.is_file()):
        return []
    data = data_directory(config, worldserver, environment)
    if data is None:
        return [f'DataDir could not be read from {config}']
    if not (data / 'dbc' / 'Spell.dbc').is_file():
        return [f'DataDir from {config} resolves to {data} for {worldserver}, which has no dbc/Spell.dbc; '
                'set an absolute DataDir']
    return []


def module_staging_problems(settings):
    target, config = settings.get('server_modules_dir'), settings.get('worldserver_config')
    if not (target and target.is_dir()):
        return []
    existing = sorted(path.name for path in target.glob('*.conf'))
    if not existing:
        return []
    source = settings.get('modules_config_dir') or (config.parent / 'modules' if config else None)
    if source and source.resolve() == target.resolve():
        return [f'the module config source equals server_modules_dir {target}; set modules_config_dir to a '
                'separate directory or use a worldserver_config outside that config directory']
    return [f'server_modules_dir {target} already holds module configs ({", ".join(existing)}); the gameplay '
            'runner stages its own there and needs it without *.conf files']


def prerequisite_reason(missing, problems):
    return '; '.join([*(['missing ' + ', '.join(missing)] if missing else []), *problems])


def gameplay_command(context):
    settings = context.settings
    command = [sys.executable, '-B', f'{GAMEPLAY_DIRECTORY}/batch.py', '--worldserver', settings['worldserver'],
               '--config', settings['worldserver_config'], '--mysql', settings['mysql'],
               '--mysqldump', settings['mysqldump']]
    for key, flag in (('server_modules_dir', '--server-modules-dir'), ('modules_config_dir', '--modules-config-dir'),
                      ('database_client_config', '--database-client-config')):
        if settings.get(key):
            command += [flag, settings[key]]
    command += ['--output', context.output / 'gameplay', '--jobs', context.gameplay_jobs]
    if context.gameplay_clock == SIMULATED_CLOCK:
        command += ['--clock', SIMULATED_CLOCK, '--lanes', context.gameplay_lanes,
                    '--character-db-workers', context.gameplay_db_workers]
    if context.gameplay_real_pace_rerun:
        command.append('--real-pace-rerun')
    if context.world_databases:
        command.append(WORLD_DATABASE_FLAGS[context.world_databases])
    if context.scenarios:
        command += ['--scenario', *context.scenarios]
    else:
        skipped = inactive_module_scenarios(context)
        if skipped:
            command += ['--skip-scenario', *skipped]
    return [str(part) for part in command]


def check_command_length(context):
    if not (WINDOWS and 'gameplay' in context.stages and context.scenarios):
        return
    if len(subprocess.list2cmdline(gameplay_command(context))) + COMMAND_MARGIN > WINDOWS_COMMAND_LIMIT:
        raise ValueError(f'The gameplay selection of {len(context.scenarios)} scenarios exceeds the Windows '
                         'command-line limit; narrow --scenario/--spell/--quest/--query or select the whole catalog')


def stage_gameplay(context, log):
    missing, problems = gameplay_prerequisites(context.settings, context.environment)
    if missing or problems:
        return 'unavailable', {'reason': prerequisite_reason(missing, problems), 'missing': missing,
                               'problems': problems}
    returncode = run_logged(gameplay_command(context), log, child_environment(context.environment), context.root)
    report = context.output / 'gameplay' / 'gameplay.json'
    summary = {'returncode': returncode, 'report': str(report), 'selection': context.scenarios or 'all'}
    try:
        data = json.loads(report.read_text(encoding='utf-8'))
    except (OSError, ValueError):
        data = None
    if not isinstance(data, dict):
        summary.update(message='The gameplay runner wrote no readable gameplay.json', tail=read_tail(log))
        return 'failed', summary
    cases = {**(data.get('cases') or {}), **(data.get('exploratory_results') or {})}
    summary.update(counts=data.get('counts') or {}, verification=(data.get('verification') or {}).get('status'),
                   clock=data.get('clock', context.gameplay_clock), lanes=data.get('lanes', context.gameplay_lanes),
                   db_workers=(data.get('simulation') or {}).get('character_db_workers', context.gameplay_db_workers),
                   acceleration_sensitive=data.get('acceleration_sensitive') or [],
                   batch_sensitive=data.get('batch_sensitive') or [], isolated_only=data.get('isolated_only') or [],
                   exploratory=data.get('exploratory') or [], batch_failures=data.get('failures') or [],
                   failed_cases=sorted(key for key, case in cases.items() if case.get('status') != 'passed'))
    if returncode == 0 and data.get('status') == 'passed':
        return 'passed', summary
    if returncode == GAMEPLAY_EXPLORATORY_EXIT and data.get('status') == 'exploratory':
        summary['reason'] = EXPLORATORY_ONLY
        return 'unavailable', summary
    summary['tail'] = read_tail(log)
    return 'failed', summary


STAGE_FUNCTIONS = {'source': stage_source, 'build': stage_build, 'unit': stage_unit, 'harness': stage_harness,
                   'gameplay': stage_gameplay}


def dependency_result(name, records):
    if name not in BUILD_DEPENDENT:
        return None
    build = records.get('build', {}).get('status')
    if build in ('failed', 'blocked'):
        return 'blocked', {'reason': 'the build stage failed'}
    if build == 'unavailable':
        return 'unavailable', {'reason': 'the build stage was unavailable'}
    return None


def execute_stage(name, context, records):
    log = context.output / f'{name}.log'
    started = time.monotonic()
    result = dependency_result(name, records)
    if result is None:
        try:
            result = STAGE_FUNCTIONS[name](context, log)
        except Interrupted:
            raise
        except Exception as error:
            result = 'failed', {'message': f'{type(error).__name__}: {error}'}
    status, summary = result
    return {'status': status, 'seconds': round(time.monotonic() - started, 3), 'summary': summary,
            'log': str(log) if log.exists() else None}


def clock_brief(summary):
    lanes = summary.get('lanes')
    return f"{summary['clock']} clock" + (f', {lanes} lanes' if type(lanes) is int and lanes > 1 else '')


def brief(summary):
    parts = []
    if summary.get('counts'):
        parts.append(', '.join(f'{value} {key}' for key, value in summary['counts'].items()))
    if summary.get('clock'):
        parts.append(clock_brief(summary))
    for key in ('acceleration_sensitive', 'batch_sensitive'):
        if summary.get(key):
            parts.append(f"{len(summary[key])} {key.replace('_', '-')}")
    if summary.get('steps') and 'message' not in summary:
        parts.append(', '.join(summary['steps']))
    parts += [summary[key] for key in ('reason', 'message') if summary.get(key)]
    return '; '.join(parts)


def stage_line(name, record):
    return f"{name:<9}{record['status'].upper():<12}{record['seconds']:>9.1f} s  {brief(record['summary'])}".rstrip()


def overall_status(records):
    statuses = {record['status'] for record in records.values()}
    if statuses & {'failed', 'blocked'}:
        return 'failed'
    if 'unavailable' in statuses:
        return 'incomplete'
    return 'passed'


def plain_record(context, name, status, summary):
    log = context.output / f'{name}.log'
    return {'status': status, 'seconds': 0.0, 'summary': summary, 'log': str(log) if log.exists() else None}


def report_line(name, record, printed):
    printed.add(name)
    print(stage_line(name, record), flush=True)


def interrupted_records(context, records, current, printed):
    for name in STAGES:
        if name in printed:
            continue
        if name not in context.stages:
            report_line(name, plain_record(context, name, 'skipped', {}), printed)
            continue
        if name not in records:
            records[name] = plain_record(context, name, 'failed' if name == current else 'blocked',
                                         {'reason': 'interrupted' if name == current else 'interrupted earlier'})
        report_line(name, records[name], printed)


def run(context):
    context.output.mkdir(parents=True, exist_ok=True)
    started = time.monotonic()
    records = {}
    printed = set()
    current = None
    try:
        for name in STAGES:
            if name not in context.stages:
                report_line(name, plain_record(context, name, 'skipped', {}), printed)
                continue
            current = name
            records[name] = execute_stage(name, context, records)
            report_line(name, records[name], printed)
            if name == 'build':
                context.settings = resolve_settings(context.raw, context.root, context.environment)
    except (KeyboardInterrupt, Interrupted):
        STOPPING.set()
        stop_active()
        interrupted_records(context, records, current, printed)
    stages = {name: records.get(name, plain_record(context, name, 'skipped', {})) for name in STAGES}
    status = overall_status(records)
    report = {'schema': 1, 'status': status, 'stages': stages, 'settings': settings_report(context.settings),
              'output': str(context.output), 'seconds': round(time.monotonic() - started, 3)}
    path = context.output / 'report.json'
    path.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(f'VERIFY ALL: {status.upper()} {path}', flush=True)
    return EXIT_CODES[status]


def build_resolved(context):
    keys = {'worldserver'}
    if context.settings['conf_dir'] is None or (WINDOWS and context.settings['worldserver'] is None):
        keys |= {'worldserver_config', 'server_modules_dir'}
    return keys - {key for key in PATH_SETTINGS if key in context.raw}


def prerequisite_key(entry):
    return entry.split(' ', 1)[0]


def stage_plan(name, context):
    if name not in context.stages:
        return {'selected': False}
    plan = {'selected': True}
    if name == 'source':
        plan['commands'] = [source_command(context.base)]
    elif name == 'build':
        cmake = cmake_program(context)
        if cmake is None:
            plan.update(status='unavailable', reason='cmake was not found on PATH')
        else:
            plan['steps'] = planned_build_steps(context, cmake)
        plan['configuration'] = context.settings['configuration']
        plan['path_prefix'] = optional_text(context.settings['mysql_client_bin'])
    elif name == 'unit':
        plan['commands'] = [unit_command(context, ctest_program(context) or 'ctest')]
        blocker = unit_blocker(context)
        if blocker and 'build' in context.stages:
            plan['note'] = f'{blocker} before the build stage runs'
        elif blocker:
            plan.update(status='unavailable', reason=blocker)
    elif name == 'harness':
        plan['runnable'] = sum(entry['status'] == 'run' for entry in context.harness)
        plan['unavailable'] = sum(entry['status'] == 'unavailable' for entry in context.harness)
        plan['timeout_seconds'] = HARNESS_TIMEOUT
        plan['coa_dbc_dir'] = harness_environment(context).get('COA_DBC_DIR')
    elif name == 'gameplay':
        missing, problems = gameplay_prerequisites(context.settings, context.environment)
        resolvable = build_resolved(context) if 'build' in context.stages else set()
        pending = {prerequisite_key(entry) for entry in missing} & resolvable
        waiting = [entry for entry in missing if prerequisite_key(entry) not in pending]
        if pending:
            plan['note'] = f'{", ".join(sorted(pending))} resolved from the build directory after the build stage'
        if waiting or problems:
            plan.update(status='unavailable', reason=prerequisite_reason(waiting, problems), missing=waiting,
                        problems=problems)
        else:
            placeholders = {key: Path(f'<{key} after build>') for key in pending}
            planned = Context(**{**vars(context), 'settings': {**context.settings, **placeholders}})
            plan['commands'] = [gameplay_command(planned)]
        plan['scenarios'] = scenario_plan(context)
        plan['gameplay_jobs'] = context.gameplay_jobs
        plan['clock'] = context.gameplay_clock
        plan['lanes'] = context.gameplay_lanes
        plan['db_workers'] = context.gameplay_db_workers
    return plan


def plan(context):
    harness = {'counts': {status: sum(entry['status'] == status for entry in context.harness)
                          for status in ('run', 'unavailable')},
               'scripts': context.harness} if 'harness' in context.stages else None
    return {'schema': 1, 'status': 'planned', 'output': str(context.output), 'order': list(STAGES),
            'stages': {name: stage_plan(name, context) for name in STAGES}, 'harness': harness,
            'jobs': {'build_unit_harness': context.jobs, 'gameplay': context.gameplay_jobs},
            'settings': settings_report(context.settings)}


def stage_list(value):
    names = [name.strip() for name in value.split(',') if name.strip()]
    unknown = [name for name in names if name not in STAGES]
    if unknown or not names:
        raise argparse.ArgumentTypeError(f'expected a comma list of {", ".join(STAGES)}')
    return names


def positive_integer(value):
    number = int(value)
    if number <= 0:
        raise argparse.ArgumentTypeError('must be a positive integer')
    return number


def lane_count(value):
    number = int(value)
    if not 1 <= number <= MAXIMUM_GAMEPLAY_LANES:
        raise argparse.ArgumentTypeError(f'must be an integer from 1 to {MAXIMUM_GAMEPLAY_LANES}')
    return number


def database_worker_count(value):
    number = int(value)
    if not 1 <= number <= MAXIMUM_GAMEPLAY_DB_WORKERS:
        raise argparse.ArgumentTypeError(f'must be an integer from 1 to {MAXIMUM_GAMEPLAY_DB_WORKERS}')
    return number


def parser():
    result = argparse.ArgumentParser(description=CLI_DESCRIPTION,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    result.add_argument('--settings', type=Path, help=f'JSON settings file (default: {DEFAULT_SETTINGS})')
    result.add_argument('--stages', type=stage_list, default=list(STAGES), help='Comma list of stages to run')
    result.add_argument('--skip', type=stage_list, default=[], help='Comma list of stages to leave out')
    result.add_argument('--scenario', nargs='+', action='extend', metavar='ID_OR_PATH',
                        help='Gameplay catalog ids or scenario files')
    result.add_argument('--spell', type=int, help='Gameplay scenarios that cast this spell')
    result.add_argument('--quest', type=int, help='Gameplay scenarios that use this quest')
    result.add_argument('--query', default='', help='Gameplay scenarios whose id, name or contract match')
    result.add_argument('--harness', nargs='+', action='extend', metavar='NAME',
                        help='Harness scripts by directory name or file stem')
    result.add_argument('--base', help='Source checks for the diff against this Git ref instead of --all')
    result.add_argument('--jobs', type=positive_integer, help='Build, unit and harness parallelism')
    result.add_argument('--gameplay-clock', choices=GAMEPLAY_CLOCKS, default=SIMULATED_CLOCK,
                        help='Gameplay clock: one accelerated worldserver, or the real-clock reference '
                             f'(default: {SIMULATED_CLOCK})')
    result.add_argument('--gameplay-real-pace-rerun', action='store_true',
                        help='Diagnose failed accelerated cases with slower same-server reruns '
                             '(default: off; requires --gameplay-clock simulated)')
    result.add_argument('--gameplay-lanes', type=lane_count,
                        help=f'Concurrent cases in the simulated-clock worldserver (default: {DEFAULT_GAMEPLAY_LANES})')
    result.add_argument('--gameplay-jobs', type=positive_integer, help='Concurrent real-clock gameplay worldservers')
    result.add_argument('--gameplay-db-workers', type=database_worker_count,
                        help='Asynchronous character database workers of the simulated-clock worldserver '
                             f'(default: settings gameplay_db_workers or {DEFAULT_GAMEPLAY_DB_WORKERS}; the real clock '
                             'keeps 1)')
    result.add_argument('--output', type=Path, help='New or empty result directory')
    world = result.add_mutually_exclusive_group()
    world.add_argument('--fresh-databases', dest='world_databases', action='store_const', const='fresh',
                       help='Gameplay: disposable database copies instead of the world-cache slots')
    world.add_argument('--refresh-world', dest='world_databases', action='store_const', const='refresh',
                       help='Gameplay: replace each world-cache slot on first use')
    result.add_argument('--plan', action='store_true', help='Print the resolved plan as JSON and execute nothing')
    return result


def output_candidates(root):
    stamp = datetime.now(timezone.utc).strftime('%Y%m%d-%H%M%S')
    base = root / '.cache' / 'verify-all'
    yield base / stamp
    for suffix in itertools.count(2):
        yield base / f'{stamp}-{suffix}'


def default_output(root):
    return next(candidate for candidate in output_candidates(root) if not candidate.exists())


def check_output(output):
    if output.exists() and (not output.is_dir() or any(output.iterdir())):
        raise ValueError(f'Output directory is not empty: {output}')


def claim_output(requested, root):
    if requested is None:
        for candidate in output_candidates(root):
            try:
                candidate.mkdir(parents=True)
            except FileExistsError:
                continue
            return candidate
    existed = requested.exists()
    check_output(requested)
    if not existed:
        try:
            requested.mkdir(parents=True)
        except FileExistsError:
            raise ValueError(f'Output directory was created by another run: {requested}') from None
    return requested


def check_gameplay_concurrency(args):
    if args.gameplay_real_pace_rerun and args.gameplay_clock != SIMULATED_CLOCK:
        raise ValueError('--gameplay-real-pace-rerun requires --gameplay-clock simulated')
    if args.gameplay_clock == SIMULATED_CLOCK and args.gameplay_jobs not in (None, 1):
        raise ValueError('--gameplay-jobs above 1 requires --gameplay-clock real; the simulated clock runs one '
                         'worldserver with --gameplay-lanes concurrent cases')
    if args.gameplay_clock == REAL_CLOCK and args.gameplay_lanes not in (None, 1):
        raise ValueError('--gameplay-lanes above 1 requires --gameplay-clock simulated; real-clock worldservers '
                         'run one case at a time')
    if args.gameplay_clock == REAL_CLOCK and args.gameplay_db_workers not in (None, 1):
        raise ValueError('--gameplay-db-workers above 1 requires --gameplay-clock simulated; real-clock worldservers '
                         'keep one character database worker')


def gameplay_concurrency(args, raw, cpu):
    if args.gameplay_clock == SIMULATED_CLOCK:
        return 1, args.gameplay_lanes or DEFAULT_GAMEPLAY_LANES
    return args.gameplay_jobs or raw.get('gameplay_jobs') or max(1, min(4, cpu // 3)), 1


def gameplay_db_workers(args, raw):
    if args.gameplay_clock == SIMULATED_CLOCK:
        return args.gameplay_db_workers or raw.get('gameplay_db_workers') or DEFAULT_GAMEPLAY_DB_WORKERS
    return 1


def prepare(args, root, environment):
    stages = [name for name in STAGES if name in args.stages and name not in args.skip]
    if not stages:
        raise ValueError('No stages selected')
    if 'gameplay' in stages:
        check_gameplay_concurrency(args)
    settings_path = args.settings.resolve() if args.settings else root / DEFAULT_SETTINGS
    raw = load_settings(settings_path, explicit=args.settings is not None)
    settings = resolve_settings(raw, root, environment)
    check_configured_directories(raw, settings)
    cpu = os.cpu_count() or 1
    jobs = args.jobs or raw.get('jobs') or cpu
    gameplay_jobs, gameplay_lanes = gameplay_concurrency(args, raw, cpu)
    requested = args.output.resolve() if args.output else None
    output = requested or default_output(root)
    check_output(output)
    harness = []
    if 'harness' in stages:
        names = filter_harness(harness_scripts(repository_files(root), registered_scripts(), root), args.harness)
        harness = [classify_harness(name, settings, environment, root) for name in names]
    scenarios = resolve_scenarios(args) if 'gameplay' in stages else []
    context = Context(root, raw, settings, output, stages, jobs, gameplay_jobs, args.gameplay_clock, gameplay_lanes,
                      args.base, scenarios, harness, environment, args.world_databases,
                      gameplay_db_workers(args, raw), args.gameplay_real_pace_rerun)
    check_command_length(context)
    if not args.plan:
        context.output = claim_output(requested, root)
    return context


def raise_keyboard_interrupt(signum, frame):
    raise KeyboardInterrupt


def main(argv=None, root=ROOT, environment=None):
    args = parser().parse_args(argv)
    environment = dict(os.environ if environment is None else environment)
    try:
        context = prepare(args, root, environment)
        if args.plan:
            print(json.dumps(plan(context), indent=2))
            return 0
    except (OSError, ValueError, KeyError, TypeError, subprocess.CalledProcessError) as error:
        print(f'ERROR: {error}', file=sys.stderr)
        return USAGE_ERROR
    previous = None
    installed = threading.current_thread() is threading.main_thread() and hasattr(signal, 'SIGTERM')
    if installed:
        previous = signal.signal(signal.SIGTERM, raise_keyboard_interrupt)
    try:
        return run(context)
    finally:
        if installed:
            signal.signal(signal.SIGTERM, previous)


if __name__ == '__main__':
    sys.exit(main())
