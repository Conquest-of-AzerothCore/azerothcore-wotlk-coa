CLI_DESCRIPTION = """Run relevant fast source checks for a diff. Never compile or start a worldserver.

Use --plan to inspect selection, --base for a branch/PR diff, or --all for the complete fast set.
The existing client-compatibility C++ test is selected separately for CI, where compilation is configured.
"""

import argparse
from concurrent.futures import ThreadPoolExecutor
from fnmatch import fnmatchcase
import json
import os
from pathlib import Path
import subprocess
import sys
import time

from check_change_boundaries import ROOT, changed_paths


GAMEPLAY = 'apps/coa-gameplay-test/'
CONFORMANCE = GAMEPLAY + 'conformance/'
DBC = 'apps/coa-dbc/'
MECHANICS = 'apps/coa-mechanics/'
COA = 'src/server/coa/'
COA_TESTS = 'apps/coa-tests/'
NATIVE_DBC = 'src/server/shared/DataStores/'
CONTENT = 'apps/coa-world-content/'
SNAPSHOTS = CONFORMANCE + 'snapshots/'
ENGINE_FILES = ['src/server/game/Entities/Unit/Unit.cpp', 'src/server/game/Entities/Unit/Unit.h',
                'src/server/game/Entities/Unit/StatSystem.cpp', 'src/server/game/Spells/Spell.cpp',
                'src/server/game/Spells/Spell.h', 'src/server/game/Spells/SpellEffects.cpp',
                'src/server/game/Spells/SpellInfo.cpp', 'src/server/game/Spells/SpellInfo.h',
                'src/server/game/Spells/SpellInfoCorrections.cpp', 'src/server/game/Spells/SpellMgr.cpp',
                'src/server/game/Spells/SpellMgr.h', 'src/server/game/Spells/SpellScript.cpp',
                'src/server/game/Spells/Auras/SpellAuraEffects.cpp', 'src/server/game/Spells/Auras/SpellAuras.cpp']
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
        'commands': [['tools/test_molten_core_smart_scripts_base_entry.py'],
                     ['tools/test_molten_core_damage_info.py']],
    },
    'molten-core-bosses': {
        'paths': ['src/server/scripts/EasternKingdoms/BlackrockMountain/MoltenCore/boss_ragnaros.cpp',
                  'modules/mod-coa-raid-difficulty/src/boss_geddon_coa.cpp',
                  'modules/mod-coa-raid-difficulty/src/boss_magmadar_coa.cpp',
                  'modules/mod-coa-raid-difficulty/src/boss_shazzrah_coa.cpp',
                  'data/sql/updates/pending_db_world/*molten_core_lucifron_impending_doom.sql'],
        'commands': [['tools/test_molten_core_boss_timings.py']],
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
    'conformance': {
        'paths': [CONFORMANCE + '*', GAMEPLAY + 'run.py', GAMEPLAY + 'batch.py', GAMEPLAY + 'catalog.py',
                  GAMEPLAY + 'verification.py', GAMEPLAY + 'world_cache.py', DBC + '*.py',
                  COA + 'AscensionSpellProgressionData.h', COA + 'AscensionLiveBaselineData.h',
                  'src/server/shared/SharedDefines.h'],
        'commands': [[CONFORMANCE + 'test_mitigation.py'], [CONFORMANCE + 'test_classes.py'],
                     [CONFORMANCE + 'test_tooltip.py'], [CONFORMANCE + 'test_values.py'],
                     [CONFORMANCE + 'test_hits.py'], [CONFORMANCE + 'test_compare.py'],
                     [CONFORMANCE + 'test_procs.py'], [CONFORMANCE + 'test_stack.py'],
                     [CONFORMANCE + 'test_diff.py'], [CONFORMANCE + 'test_passives.py'],
                     [CONFORMANCE + 'test_behaviours.py'], [CONFORMANCE + 'test_observations.py'],
                     [CONFORMANCE + 'test_tooltip_readings.py'],
                     [CONFORMANCE + 'test_triggers.py'], [CONFORMANCE + 'test_questions.py'],
                     [CONFORMANCE + 'test_coverage.py'], [CONFORMANCE + 'test_scaffold.py'],
                     [CONFORMANCE + 'test_sheets.py'], [CONFORMANCE + 'test_records.py'],
                     [CONFORMANCE + 'test_score.py'], [CONFORMANCE + 'test_prove.py'],
                     [CONFORMANCE + 'test_expiry.py'], [CONFORMANCE + 'test_kinds.py'],
                     [CONFORMANCE + 'test_mutants.py'],
                     [CONFORMANCE + 'test_k3.py'], [CONFORMANCE + 'test_sample.py'],
                     [CONFORMANCE + 'test_packets.py'], [CONFORMANCE + 'test_class_map.py'],
                     [CONFORMANCE + 'test_audit.py'], [CONFORMANCE + 'test_buckets.py'],
                     [CONFORMANCE + 'test_aura354.py'], [CONFORMANCE + 'test_ledger.py'],
                     [CONFORMANCE + 'test_minions.py'], [CONFORMANCE + 'test_snapshots.py']],
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


def finished_classes(root=ROOT):
    classes = []
    for path in sorted((root / SNAPSHOTS).glob('*.json')):
        snapshot = json.loads(path.read_text(encoding='utf-8'))
        classes.append({'class_id': snapshot['class_id'], 'class_name': snapshot['class_name'],
                        'generations': {name: generation['arguments']
                                        for name, generation in sorted(snapshot['generations'].items())}})
    return classes


def snapshot_commands(root=ROOT):
    return [[CONFORMANCE + 'snapshots.py', 'check', '--class', str(entry['class_id'])]
            for entry in finished_classes(root)]


def conformance_reruns(paths, root=ROOT):
    engine = sorted(set(paths) & set(ENGINE_FILES))
    if not engine:
        return None
    tool = 'python -B ' + CONFORMANCE + 'conformance.py'
    classes = []
    for entry in finished_classes(root):
        for name, arguments in entry['generations'].items():
            out = f".cache/conformance/rerun-{entry['class_name']}-{name}"
            classes.append({'class_id': entry['class_id'], 'class_name': entry['class_name'], 'generation': name,
                            'commands': [' '.join([tool, 'generate', '--class', str(entry['class_id']), *arguments,
                                                   '--out', out]),
                                         'python -B tools/verify_all.py --stages build,gameplay --scenario '
                                         f'{out}/scenarios/*.json',
                                         f'{tool} compare --manifest {out}/manifest.json --results <verify_all output>',
                                         f'{tool} diff --before <count of record compare output> --after {out}']})
    return {'engine_files': engine, 'enforced': False,
            'rule': 'a shared engine file changed: run every selection below and record each diff as no regression '
                    'against the class count of record before a PR (docs/coa/class-conformance.md)',
            'classes': classes}


def rerun_text(reruns):
    lines = ['Shared engine files changed: ' + ', '.join(reruns['engine_files']), reruns['rule'] + ':']
    for entry in reruns['classes']:
        lines.append(f"  {entry['class_name']} ({entry['class_id']}) {entry['generation']}:")
        lines += ['    ' + command for command in entry['commands']]
    return '\n'.join(lines) + '\n'


def commands_for(selection, base, all_checks=False, allow_historical_sql=False):
    boundaries = ['tools/check_change_boundaries.py', '--base', base]
    if allow_historical_sql:
        boundaries.append('--allow-historical-sql')
    comments = ['tools/check_comments.py', '--base', base]
    if all_checks:
        comments.append('--all')
    snapshots = snapshot_commands() if 'conformance' in selection['checks'] else []
    return [boundaries, comments, *(command for key in selection['checks'] for command in SUITES[key]['commands']),
            *snapshots]


def run_command(arguments, root, environment):
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
    return record


def execute(commands, root=ROOT, jobs=None):
    environment = dict(os.environ)
    environment.pop('PYTHONOPTIMIZE', None)
    workers = max(1, min(jobs or os.cpu_count() or 1, len(commands))) if commands else 1
    if workers <= 1:
        return [run_command(arguments, root, environment) for arguments in commands]
    with ThreadPoolExecutor(max_workers=workers) as pool:
        return list(pool.map(lambda arguments: run_command(arguments, root, environment), commands))


def main(argv=None):
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('--base', default='HEAD', help='Compare this Git ref to the working tree, including new files')
    parser.add_argument('--all', action='store_true', help='Run every fast source suite')
    parser.add_argument('--plan', action='store_true', help='Print selected commands without executing them')
    parser.add_argument('--allow-historical-sql', action='store_true',
                        help='Only for an explicitly authorized SQL exception; CI uses its maintainer label')
    parser.add_argument('--github-output', type=Path, help='Append the client_compat selection for the CI build step')
    parser.add_argument('--jobs', type=int, help='Concurrent commands to run; defaults to the CPU count')
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
        reruns = conformance_reruns(paths)
        if reruns:
            result['conformance_reruns'] = reruns
            sys.stderr.write(rerun_text(reruns))
        if args.github_output:
            with args.github_output.open('a', encoding='utf-8') as output:
                output.write('client_compat=' + str(selection['client_compat']).lower() + '\n')
        if not args.plan:
            result['results'] = execute(commands, jobs=args.jobs)
            result['status'] = 'failed' if any(r['status'] == 'failed' for r in result['results']) else 'passed'
        print(json.dumps(result, indent=2))
        return int(result['status'] == 'failed')
    except (OSError, ValueError, KeyError, TypeError, subprocess.CalledProcessError) as error:
        print(f'Source check selection failed: {error}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
