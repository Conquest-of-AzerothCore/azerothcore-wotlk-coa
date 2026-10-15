CLI_DESCRIPTION = """Run relevant fast source checks for a diff. Never compile or start a worldserver.

Use --plan to inspect selection, --base for a branch/PR diff, or --all for the complete fast set.
The existing client-compatibility C++ test is selected separately for CI, where compilation is configured.
"""

import argparse
from fnmatch import fnmatchcase
import json
import os
from pathlib import Path
import subprocess
import sys
import time

from check_change_boundaries import ROOT, changed_paths


GAMEPLAY = 'apps/coa-gameplay-test/'
DBC = 'apps/coa-dbc/'
MECHANICS = 'apps/coa-mechanics/'
COA = 'src/server/coa/'
COA_TESTS = 'apps/coa-tests/'
NATIVE_DBC = 'src/server/shared/DataStores/'
CONTENT = 'apps/coa-world-content/'
CONTROL_FILES = {'tools/check_source.py', 'tools/test_source.py', '.github/workflows/quality.yml'}
SUITES = {
    'source-tools': {
        'paths': ['tools/check_*.py', 'tools/test_*.py', 'tools/comment_policy.py', 'tools/verify_*.py',
                  GAMEPLAY + 'batch.py', GAMEPLAY + 'catalog.py', GAMEPLAY + 'run.py'],
        'commands': [['tools/test_source.py'], ['tools/test_change_boundaries.py'], ['tools/test_registrations.py'],
                     ['tools/test_comments.py'], ['tools/test_verify_all.py']],
    },
    'molten-core-sql': {
        'paths': ['data/sql/updates/pending_db_world/*molten_core*.sql'],
        'commands': [['tools/test_molten_core_smart_scripts_base_entry.py']],
    },
    'codestyle': {
        'paths': ['apps/codestyle/*', '.editorconfig'],
        'commands': [['apps/codestyle/tests/test_scoped_lint.py']],
    },
    'issue-labeler': {
        'paths': ['.github/scripts/*', '.github/workflows/issue-labeler.yml'],
        'commands': [['.github/scripts/test_label_issues.py']],
    },
    'dbc': {
        'paths': [DBC + '*.py', DBC + 'coa-dbc-viewer', DBC + 'viewer.html',
                  NATIVE_DBC + 'DBCStructure.h', NATIVE_DBC + 'DBCfmt.h'],
        'commands': [[DBC + 'test_client_dbc.py'], [DBC + 'test_inspector.py'], [DBC + 'test_capture_sql.py']],
    },
    'mechanics': {
        'paths': [MECHANICS + '*.py', MECHANICS + '*.json', DBC + '*.py',
                  NATIVE_DBC + 'DBCStructure.h', NATIVE_DBC + 'DBCfmt.h', GAMEPLAY + '*.py', GAMEPLAY + '*.json'],
        'commands': [[MECHANICS + 'test_mechanic_map.py'], [MECHANICS + 'mechanic_map.py', 'check']],
    },
    'gameplay': {
        'paths': [GAMEPLAY + '*.py', GAMEPLAY + '*.json', COA + 'CoAGameplayTest*'],
        'commands': [[GAMEPLAY + 'test_runner.py'], [GAMEPLAY + 'test_world_cache.py'],
                     [GAMEPLAY + 'test_verification.py'], [GAMEPLAY + 'test_batch.py'],
                     [GAMEPLAY + 'catalog.py', '--check']],
    },
    'world-content': {
        'paths': [CONTENT + '*.py'],
        'commands': [[CONTENT + 'test_validate_content.py'], [CONTENT + 'test_archive.py']],
    },
    'registrations': {
        'paths': [COA + '*.cpp', COA + '*.h', COA + 'CMakeLists.txt', 'src/server/apps/worldserver/Main.cpp',
                  'tools/*registrations.py'],
        'commands': [['tools/check_registrations.py']],
    },
}
CLIENT_COMPAT_PATHS = [COA_TESTS + 'client_compat/*', COA_TESTS + 'core_integration/*',
                       COA + 'CoASpellbook.*', COA + 'CMakeLists.txt', 'src/server/game/Server/WorldSocket.*',
                       'src/server/game/Entities/Player/*', 'src/server/shared/DataStores/*',
                       'src/common/DataStores/*', 'src/common/Define.h', 'src/common/Common.h']


def matches(paths, patterns):
    return any(fnmatchcase(path, pattern) for path in paths for pattern in patterns)


def select(paths, all_checks=False, mechanic_sources=()):
    full = all_checks or bool(set(paths) & CONTROL_FILES)
    selected = [key for key, suite in SUITES.items() if full or matches(paths, suite['paths'])
                or (key == 'mechanics' and set(paths) & set(mechanic_sources))]
    return {'checks': selected, 'client_compat': full or matches(paths, CLIENT_COMPAT_PATHS)}


def reviewed_sources(root=ROOT):
    entries = json.loads((root / MECHANICS / 'entries.json').read_text(encoding='utf-8'))
    return {step['source']['path'] for entry in entries['entries'] for step in entry['execution']}


def commands_for(selection, base, all_checks=False, allow_historical_sql=False):
    boundaries = ['tools/check_change_boundaries.py', '--base', base]
    if allow_historical_sql:
        boundaries.append('--allow-historical-sql')
    comments = ['tools/check_comments.py', '--base', base]
    if all_checks:
        comments.append('--all')
    return [boundaries, comments, *(command for key in selection['checks'] for command in SUITES[key]['commands'])]


def execute(commands, root=ROOT):
    records = []
    environment = dict(os.environ)
    environment.pop('PYTHONOPTIMIZE', None)
    for arguments in commands:
        started = time.monotonic()
        record = {'command': [sys.executable, '-B', *arguments], 'status': 'failed'}
        try:
            result = subprocess.run(record['command'], cwd=root, capture_output=True, text=True,
                                    timeout=120, env=environment)
            record.update(status='passed' if result.returncode == 0 else 'failed', returncode=result.returncode,
                          output=(result.stdout + result.stderr)[-20000:])
        except (OSError, subprocess.TimeoutExpired) as error:
            record['message'] = str(error)
        record['seconds'] = round(time.monotonic() - started, 3)
        records.append(record)
    return records


def main(argv=None):
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('--base', default='HEAD', help='Compare this Git ref to the working tree, including new files')
    parser.add_argument('--all', action='store_true', help='Run every fast source suite')
    parser.add_argument('--plan', action='store_true', help='Print selected commands without executing them')
    parser.add_argument('--allow-historical-sql', action='store_true',
                        help='Only for an explicitly authorized SQL exception; CI uses its maintainer label')
    parser.add_argument('--github-output', type=Path, help='Append the client_compat selection for the CI build step')
    args = parser.parse_args(argv)
    try:
        paths = changed_paths(args.base)
        selection = select(paths, args.all, reviewed_sources())
        commands = commands_for(selection, args.base, args.all, args.allow_historical_sql)
        result = {'schema': 1, 'scope': 'source checks only; gameplay scenarios and compilation are not executed',
                  'base': args.base, 'changed_files': len(paths), 'selected_suites': selection['checks'],
                  'client_compat': {'selected': selection['client_compat'], 'status': 'not_run',
                                    'reason': 'C++ harness; run separately when relevant or in CI'},
                  'status': 'planned', 'commands': commands}
        if args.github_output:
            with args.github_output.open('a', encoding='utf-8') as output:
                output.write('client_compat=' + str(selection['client_compat']).lower() + '\n')
        if not args.plan:
            result['results'] = execute(commands)
            result['status'] = 'failed' if any(r['status'] == 'failed' for r in result['results']) else 'passed'
        print(json.dumps(result, indent=2))
        return int(result['status'] == 'failed')
    except (OSError, ValueError, KeyError, TypeError, subprocess.CalledProcessError) as error:
        print(f'Source check selection failed: {error}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
