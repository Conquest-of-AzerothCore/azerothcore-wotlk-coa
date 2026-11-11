CLI_DESCRIPTION = """Check how ObjectMgr::LoadQuestTargetRespawns classes creatures for the quest target respawn caps.

The real loader runs against a small fixture world. Named targets are quest-boss-flagged creatures with at most one
open-world spawn point, a spawn pool counting as one point; flagged creatures with more points and other creatures a
quest needs (kill objective, kill credit, quest-required loot, quest item) are general targets; rares and rare elites
are never classed. Expected classes are written out here, not taken from the implementation. Pass --source-ref to
read ObjectMgr.cpp from another Git ref.
"""

import argparse
import os
from pathlib import Path
import runpy
import shutil
import subprocess
import sys
import tempfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source  # noqa: E402

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']
NONE, GENERAL, NAMED = 0, 1, 2

EXPECTED = {
    101: (NAMED, 'flagged, one open-world spawn'),
    102: (NAMED, 'flagged, three spawns in one pool'),
    103: (GENERAL, 'flagged, spawns in two pools'),
    104: (GENERAL, 'flagged, 44 open-world spawns'),
    105: (NONE, 'flagged rare, one spawn'),
    106: (NONE, 'flagged rare elite, one spawn'),
    107: (NONE, 'rare kill objective'),
    108: (NAMED, 'flagged, one open-world spawn and five dungeon spawns'),
    109: (NAMED, 'flagged, no spawns'),
    110: (GENERAL, 'flagged, one spawn plus a multispawn id2 spawn'),
    111: (GENERAL, 'kill objective'),
    112: (GENERAL, 'second kill credit is a kill objective'),
    113: (GENERAL, 'quest-required creature loot'),
    114: (NONE, 'creature loot without quest-required items'),
    115: (GENERAL, 'creature quest item'),
    116: (NONE, 'needed by no quest'),
    117: (NAMED, 'flagged elite, one spawn'),
    118: (NONE, 'gameobject objective with the same id'),
    119: (NONE, 'empty creature quest item list'),
}


def harness(source):
    loader = method(source('src/server/game/Globals/ObjectMgr.cpp'), 'void ObjectMgr::LoadQuestTargetRespawns()')
    code = (HERE / 'harness.cpp').read_text(encoding='utf-8')
    marker = 'LOAD_QUEST_TARGET_RESPAWNS'
    assert code.count(marker) == 1
    return code.replace(marker, loader)


def compile_harness(code, out):
    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler, 'A C++20 compiler is required'
    source = out / 'harness.cpp'
    source.write_text(code, encoding='utf-8')
    executable = out / ('harness.exe' if os.name == 'nt' else 'harness')
    if Path(compiler).stem.lower() == 'cl':
        flags = ['/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8', str(source), '/Fe' + str(executable)]
    else:
        flags = ['-std=c++20', '-Wall', '-Wextra', '-Werror', str(source), '-o', str(executable)]
    subprocess.run([compiler, *flags], cwd=out, check=True, timeout=120)
    return executable


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('--source-ref', help='Read ObjectMgr.cpp from a local Git ref for regression checks.')
    args = parser.parse_args()

    def source(name):
        if args.source_ref:
            return git_source(['git', 'show', f'{args.source_ref}:{name}'], cwd=ROOT).decode('utf-8')
        return (ROOT / name).read_text(encoding='utf-8')

    with tempfile.TemporaryDirectory(prefix='coa-quest-target-respawn-') as directory:
        executable = compile_harness(harness(source), Path(directory))
        output = subprocess.run([str(executable)], check=True, timeout=30, capture_output=True, text=True).stdout

    values = dict(line.split('=', 1) for line in output.splitlines())
    failures = []
    query = values.pop('query')
    for fragment in ('`creature_loot_template`', '`QuestRequired` = 1', '`Reference` = 0'):
        if fragment not in query:
            failures.append(f'quest loot query lacks {fragment}: {query}')
    for entry, (expected, label) in EXPECTED.items():
        actual = int(values.get(str(entry), -1))
        if actual != expected:
            failures.append(f'{entry} ({label}): got class {actual}, expected {expected}')
    if int(values['reload_stale']) != NONE:
        failures.append('a reload keeps a class from the previous load')
    if int(values['reload_no_loot_113']) != NONE:
        failures.append('a reload without quest-required loot keeps the loot-based class')

    assert not failures, '\n'.join(failures)
    print(f'PASS: {len(EXPECTED)} quest target respawn classes from spawn points, pools, maps, rank, objectives, '
          'kill credit, quest loot and quest items, plus reload')


if __name__ == '__main__':
    main()
