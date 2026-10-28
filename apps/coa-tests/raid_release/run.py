import os
from pathlib import Path
import runpy
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']

EXPECTED_STAGES = {409: 3, 309: 4, 249: 5, 469: 6, 509: 7, 531: 7, 533: 8}
DIFFICULTY_STAGES = {0: 0, 1: 1, 2: 2}
UNGATED_MAPS = (0, 1, 36, 229, 230, 532, 535, 603, 880, 951)
UNGATED_RAIDS = (532, 535, 603)
DUNGEONS = (36, 229, 230)


def command(source, exe):
    if os.environ.get('VCToolsInstallDir'):
        compiler = Path(os.environ['VCToolsInstallDir']) / 'bin/Hostx64/x64/cl.exe'
        return [str(compiler), '/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/I', str(ROOT / 'src/server/coa'),
                str(source), '/Fe' + str(exe)]
    compiler = shutil.which(os.environ.get('CXX', 'g++'))
    assert compiler, 'Set CXX to a C++17 compiler or run from an MSVC developer environment.'
    return [compiler, '-std=c++17', '-Wall', '-Wextra', '-Werror', '-I', str(ROOT / 'src/server/coa'), str(source),
            '-o', str(exe)]


def harness(source):
    hook = method(source, 'bool OnPlayerCanEnterMap(').replace(' override', '')
    expected = ','.join(f'{{{map_id},{stage}}}' for map_id, stage in EXPECTED_STAGES.items())
    difficulties = ','.join(f'{{{difficulty},{stage}}}' for difficulty, stage in DIFFICULTY_STAGES.items())
    ungated = ','.join(str(map_id) for map_id in UNGATED_MAPS)
    raids = ','.join(str(map_id) for map_id in (*EXPECTED_STAGES, *UNGATED_RAIDS))
    ungated_raids = ','.join(str(map_id) for map_id in UNGATED_RAIDS)
    dungeons = ','.join(str(map_id) for map_id in DUNGEONS)
    return f'''#include "AscensionRaidReleasePolicy.h"
#include <cassert>
#include <cstdint>
#include <utility>
using uint32 = std::uint32_t;
constexpr uint32 LANG_INSTANCE_CLOSED = 2010;
enum Difficulty : uint32 {{ DUNGEON_DIFFICULTY_NORMAL, DUNGEON_DIFFICULTY_HEROIC, DUNGEON_DIFFICULTY_EPIC }};
uint32 const raidMaps[] = {{{raids}}};
struct MapEntry
{{
    uint32 MapID;
    bool IsRaid() const
    {{
        for (uint32 raid : raidMaps)
            if (raid == MapID)
                return true;
        return false;
    }}
}};
struct InstanceTemplate {{ }};
struct MapDifficulty {{ }};
Difficulty g_mapTopDifficulty = DUNGEON_DIFFICULTY_EPIC;
MapDifficulty const* GetDownscaledMapDifficultyData(uint32, Difficulty& difficulty)
{{
    static MapDifficulty const data;
    if (difficulty > g_mapTopDifficulty)
        difficulty = g_mapTopDifficulty;
    return &data;
}}
struct WorldSession
{{
    uint32 messages = 0;
    void SendAreaTriggerMessage(uint32 text) {{ assert(text == LANG_INSTANCE_CLOSED); ++messages; }}
}};
struct Player
{{
    WorldSession session;
    Difficulty dungeonDifficulty = DUNGEON_DIFFICULTY_NORMAL;
    WorldSession* GetSession() {{ return &session; }}
    Difficulty GetDifficulty(bool isRaid) const {{ return isRaid ? DUNGEON_DIFFICULTY_NORMAL : dungeonDifficulty; }}
}};
uint32 g_raidReleaseStage = RaidRelease::AllReleased;
struct Hook
{{
{hook}
}};

bool Enter(Hook& hook, uint32 mapId, Difficulty difficulty, bool login = false)
{{
    Player player;
    player.dungeonDifficulty = difficulty;
    MapEntry entry{{ mapId }};
    bool const open = hook.OnPlayerCanEnterMap(&player, &entry, nullptr, nullptr, login);
    assert(player.session.messages == (open ? 0u : 1u));
    return open;
}}

int main()
{{
    std::pair<uint32, uint32> const expected[] = {{{expected}}};
    std::pair<uint32, uint32> const difficulties[] = {{{difficulties}}};
    uint32 const ungated[] = {{{ungated}}};
    uint32 const ungatedRaids[] = {{{ungated_raids}}};
    uint32 const dungeons[] = {{{dungeons}}};
    Hook hook;
    static_assert(RaidRelease::AllReleased == 8);
    for (uint32 stage = 0; stage <= 10; ++stage)
    {{
        g_raidReleaseStage = stage;
        for (auto const& [mapId, raidStage] : expected)
            for (Difficulty selected : {{ DUNGEON_DIFFICULTY_NORMAL, DUNGEON_DIFFICULTY_EPIC }})
            {{
                assert(Enter(hook, mapId, selected) == (raidStage <= stage));
                assert(Enter(hook, mapId, selected, true) == (raidStage <= stage));
            }}
        for (uint32 mapId : ungated)
            assert(Enter(hook, mapId, DUNGEON_DIFFICULTY_NORMAL));
        for (uint32 mapId : ungatedRaids)
            assert(Enter(hook, mapId, DUNGEON_DIFFICULTY_EPIC));
        for (uint32 mapId : dungeons)
            for (auto const& [difficulty, difficultyStage] : difficulties)
            {{
                assert(Enter(hook, mapId, Difficulty(difficulty)) == (difficultyStage <= stage));
                assert(Enter(hook, mapId, Difficulty(difficulty), true) == (difficultyStage <= stage));
            }}
    }}

    g_raidReleaseStage = RaidRelease::StageMoltenCore;
    assert(Enter(hook, 409, DUNGEON_DIFFICULTY_NORMAL));
    assert(!Enter(hook, 309, DUNGEON_DIFFICULTY_NORMAL));
    assert(!Enter(hook, 249, DUNGEON_DIFFICULTY_NORMAL));
    assert(Enter(hook, 36, DUNGEON_DIFFICULTY_HEROIC));
    assert(Enter(hook, 36, DUNGEON_DIFFICULTY_EPIC));

    g_raidReleaseStage = RaidRelease::StageMythicDungeons;
    assert(Enter(hook, 36, DUNGEON_DIFFICULTY_EPIC));
    assert(!Enter(hook, 409, DUNGEON_DIFFICULTY_NORMAL));

    g_raidReleaseStage = RaidRelease::StageHeroicDungeons;
    assert(Enter(hook, 36, DUNGEON_DIFFICULTY_HEROIC));
    assert(!Enter(hook, 36, DUNGEON_DIFFICULTY_EPIC));
    g_mapTopDifficulty = DUNGEON_DIFFICULTY_HEROIC;
    assert(Enter(hook, 36, DUNGEON_DIFFICULTY_EPIC));

    g_raidReleaseStage = 0;
    g_mapTopDifficulty = DUNGEON_DIFFICULTY_NORMAL;
    assert(Enter(hook, 36, DUNGEON_DIFFICULTY_EPIC));
    return 0;
}}
'''


def main():
    source = (ROOT / 'src/server/coa/AscensionRaidRelease.cpp').read_text(encoding='utf-8')
    loader = (ROOT / 'src/server/coa/CoAScriptLoader.cpp').read_text(encoding='utf-8')
    config = (ROOT / 'src/server/coa/conf/coa.conf.dist').read_text(encoding='utf-8')
    assert '{ PLAYERHOOK_CAN_ENTER_MAP }' in source
    assert '"Ascension.CallboardCache.ReleaseStage"' in source
    assert 'WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_AFTER_CONFIG_LOAD' in source
    assert loader.count('AddSC_AscensionRaidRelease()') == 2
    assert '\nAscension.CallboardCache.ReleaseStage = 3\n' in config
    assert 'Ascension.RaidLock' not in config
    with tempfile.TemporaryDirectory(prefix='coa-raid-release-') as directory:
        out = Path(directory)
        cpp, exe = out / 'raid_release.cpp', out / 'raid_release.exe'
        cpp.write_text(harness(source), encoding='utf-8')
        subprocess.run(command(cpp, exe), cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    print('PASS: Heroic and Mythic dungeon difficulties and the Classic raids open in release-stage order, each '
          'stage keeps the earlier ones open, closed content refuses entry and login with "Instance is closed", '
          'normal dungeons and other maps stay open, and the default opens up to Molten Core')


if __name__ == '__main__':
    main()
