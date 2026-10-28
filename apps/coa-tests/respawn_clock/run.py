CLI_DESCRIPTION = """Check the creature respawn clock with the real Creature corpse, loot, despawn and respawn code.

Vanilla (vmangos Creature::SetDeathState/Update) starts the respawn timer at death and removes the corpse once the
respawn time passes; AzerothCore counts the delay from corpse removal. Expected times come from both rules
written out here, not from the implementation. Pass --source-ref to run the same checks on another Git ref.
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
DEATH = 1000
VMANGOS_DEFAULT_RESPAWN_DELAY = 25
DECAY = {0: 60, 1: 300}


def block(source, anchor):
    start = source.index('{', source.index(anchor))
    end, depth = start + 1, 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end]


def harness(source):
    creature = source('src/server/game/Entities/Creature/Creature.cpp')
    header = source('src/server/game/Entities/Creature/Creature.h')
    clock = method(header, 'namespace CreatureRespawnClock') if 'namespace CreatureRespawnClock' in header else ''
    update = method(creature, 'void Creature::Update(uint32 diff)')
    cases = update[update.index('        case DeathState::Dead:'):update.index('        case DeathState::Alive:')]
    died = block(method(creature, 'void Creature::setDeathState('), 'if (state == DeathState::JustDied)')
    signatures = ['void Creature::RemoveCorpse(', 'void Creature::AllLootRemovedFromCorpse()',
                  'void Creature::ForcedDespawn(', 'void Creature::SaveRespawnTime()']
    if 'bool Creature::IsRespawnTimerFromDeath() const' in creature:
        signatures.append('bool Creature::IsRespawnTimerFromDeath() const')
    methods = '\n'.join(method(creature, signature) for signature in signatures)
    code = (HERE / 'harness.cpp').read_text(encoding='utf-8')
    for marker, text in (('// NATIVE_CLOCK', clock), ('// NATIVE_JUST_DIED', died),
                         ('// NATIVE_DEAD_AND_CORPSE', cases), ('// METHODS', methods)):
        assert code.count(marker) == 1
        code = code.replace(marker, text)
    return code


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


def run(executable, **case):
    arguments = [f'{key}={int(value)}' for key, value in case.items()]
    output = subprocess.run([str(executable), *arguments], check=True, timeout=30, capture_output=True, text=True)
    return {key: int(value) for key, value in (part.split('=') for part in output.stdout.split())}


def corpse_end(decay, rate_pct, loot=None, skin=None):
    end, cuts = DEATH + decay, 0
    for moment, skinned in sorted((t, s) for t, s in ((loot, False), (skin, True)) if t is not None):
        if moment < end:
            cut = int((end - moment) * rate_pct / 100)
            cuts += cut
            end = moment if skinned else end - cut
    return end, cuts


def azerothcore(rank=0, delay=300, rate_pct=50, divisor=1, loot=None, skin=None, despawn=None, despawn_timer=0,
                alive_despawn=None, compat=1, **_):
    decay = DECAY[rank]
    if alive_despawn is not None:
        return {'corpse': DEATH, 'respawn': DEATH + (alive_despawn or delay)}
    end, cuts = corpse_end(decay, rate_pct, loot, skin)
    respawn = DEATH + delay // divisor + decay - cuts
    if despawn is not None and despawn < end:
        pending = respawn
        respawn = despawn + (despawn_timer or delay)
        if not compat and not despawn_timer:
            respawn = max(respawn, pending)
        return {'corpse': despawn, 'respawn': respawn}
    return {'corpse': end, 'respawn': max(respawn, end)}


def vanilla(rank=0, delay=300, rate_pct=50, divisor=1, loot=None, skin=None, despawn=None, despawn_timer=0,
            alive_despawn=None, roll=None, roll_ms=0, **_):
    decay = DECAY[rank]
    if alive_despawn is not None:
        return {'corpse': DEATH, 'respawn': DEATH + (alive_despawn or delay)}
    respawn = DEATH + max(delay, VMANGOS_DEFAULT_RESPAWN_DELAY) // divisor
    end = min(corpse_end(decay, rate_pct, loot, skin)[0], respawn)
    if despawn is not None and despawn < end:
        return {'corpse': despawn, 'respawn': despawn + despawn_timer if despawn_timer else respawn}
    if roll is not None and roll + roll_ms // 1000 > end:
        end = roll + roll_ms // 1000
        return {'corpse': end, 'respawn': end}
    return {'corpse': end, 'respawn': respawn}


CASES = [
    ('normal mob, 300 s', dict(delay=300)),
    ('Hogger-like elite, 180 s under 300 s decay', dict(rank=1, delay=180)),
    ('looted normal mob', dict(delay=300, loot=1010)),
    ('looted short elite', dict(rank=1, delay=180, loot=1020)),
    ('looted then skinned', dict(delay=300, loot=1010, skin=1020)),
    ('0 s placeholder delay', dict(delay=0)),
    ('1 s quest mob', dict(delay=1)),
    ('scripted corpse despawn', dict(delay=300, despawn=1030)),
    ('scripted corpse despawn with timer', dict(delay=300, despawn=1030, despawn_timer=120)),
    ('living despawn', dict(delay=300, alive_despawn=0)),
    ('living despawn, 0 s delay', dict(delay=0, alive_despawn=0)),
    ('living despawn with timer', dict(delay=300, alive_despawn=45)),
    ('dynamic spawn mode', dict(delay=300, compat=0)),
    ('dynamic spawn mode, looted', dict(delay=300, compat=0, loot=1010)),
    ('dynamic spawn mode, short elite', dict(rank=1, delay=180, compat=0)),
    ('dynamic respawn rate', dict(delay=300, divisor=2)),
    ('no looted decay', dict(rank=1, delay=180, loot=1020, rate_pct=0)),
]


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('--source-ref', help='Read Creature.cpp/.h from a local Git ref for regression checks.')
    args = parser.parse_args()

    def source(name):
        if args.source_ref:
            return git_source(['git', 'show', f'{args.source_ref}:{name}'], cwd=ROOT).decode('utf-8')
        return (ROOT / name).read_text(encoding='utf-8')

    failures = []

    def check(label, actual, expected):
        if any(actual[key] != value for key, value in expected.items()):
            failures.append(f'{label}: got {actual}, expected {expected}')

    with tempfile.TemporaryDirectory(prefix='coa-respawn-clock-') as directory:
        executable = compile_harness(harness(source), Path(directory))
        for label, case in CASES:
            decay = {'decay': DECAY[case.get('rank', 0)]}
            check('vanilla clock, ' + label, run(executable, config=1, **decay, **case), vanilla(**case))
            check('config off, ' + label, run(executable, config=0, **decay, **case), azerothcore(**case))
            expected = azerothcore(**case)
            if not case.get('compat', 1):
                expected = {'corpse': expected['corpse']}
            for exempt in (dict(spawn=0), dict(summon=1), dict(db=0)):
                check(', '.join(exempt) + ' exempt, ' + label,
                      run(executable, config=1, **exempt, **decay, **case), expected)

        for config in (0, 1):
            for delay, expected_delay in ((375, 30), (25, 25), (10, 25)):
                check(f'named quest target, config {config}, delay {delay}',
                      run(executable, config=config, decay=300, delay=delay, named=1),
                      {'corpse': DEATH + expected_delay, 'respawn': DEATH + expected_delay})
        check('named flag does not shorten dungeon respawns',
              run(executable, config=1, decay=60, delay=7200, dungeon=1, named=1),
              {'corpse': DEATH + 60, 'death_save': DEATH + 7200})
        for config in (0, 1):
            check(f'named flag preserves world boss respawns, config {config}',
                  run(executable, config=config, decay=300, delay=7200, named=1, worldboss=1),
                  {'corpse': DEATH + 300, 'death_save': DEATH + 7200 + (0 if config else 300)})

        roll = dict(rank=1, delay=180, roll=1170, roll_ms=60000)
        check('group roll holds the corpse past the respawn time',
              run(executable, config=1, decay=300, **roll), vanilla(**roll))
        died = run(executable, config=1, decay=300, rank=1, delay=180)
        check('elite respawn saved at death', died, {'death_save': DEATH + 180})
        check('elite respawn saved at death, config off', run(executable, config=0, decay=300, rank=1, delay=180),
              {'death_save': DEATH + 180 + 300})
        dungeon = run(executable, config=1, decay=60, delay=7200, dungeon=1)
        check('dungeon trash saved at death', dungeon, {'death_save': DEATH + 7200})
        for label, case in (('short elite', dict(rank=1, delay=180)), ('0 s delay', dict(rank=1, delay=0))):
            check('dynamic spawn mode keeps one copy, ' + label,
                  run(executable, config=1, decay=300, compat=0, **case), {'duplicate': 0})
        dynamic_roll = run(executable, config=1, decay=300, compat=0, **roll)
        roll_end = roll['roll'] + roll['roll_ms'] // 1000
        if dynamic_roll['duplicate'] or not roll_end <= dynamic_roll['respawn'] <= roll_end + 1:
            failures.append(f'dynamic spawn mode waits for the group roll: got {dynamic_roll}, expected no duplicate '
                            f'and a respawn at {roll_end}-{roll_end + 1}')

    assert not failures, '\n'.join(failures)
    print(f'PASS: {len(CASES)} death/loot/skin/despawn/dynamic-mode cases on the vanilla clock and on the '
          'AzerothCore clock, exemptions, group roll and saved respawn times')


if __name__ == '__main__':
    main()
