import os
from pathlib import Path
import runpy
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']

EXPECTED_STAGES = {309: 1, 409: 2, 249: 3, 469: 4, 509: 5, 531: 6, 533: 7}
UNGATED_MAPS = (0, 1, 36, 229, 230, 532, 535, 603, 880, 951)


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
    ungated = ','.join(str(map_id) for map_id in UNGATED_MAPS)
    return f'''#include "AscensionRaidReleasePolicy.h"
#include <cassert>
#include <cstdint>
#include <utility>
using uint32 = std::uint32_t;
constexpr uint32 LANG_INSTANCE_CLOSED = 2010;
struct MapEntry {{ uint32 MapID; }};
struct InstanceTemplate {{ }};
struct MapDifficulty {{ }};
struct WorldSession
{{
    uint32 messages = 0;
    void SendAreaTriggerMessage(uint32 text) {{ assert(text == LANG_INSTANCE_CLOSED); ++messages; }}
}};
struct Player
{{
    WorldSession session;
    WorldSession* GetSession() {{ return &session; }}
}};
uint32 g_raidReleaseStage = RaidRelease::AllRaidsReleased;
struct Hook
{{
{hook}
}};

int main()
{{
    std::pair<uint32, uint32> const expected[] = {{{expected}}};
    uint32 const ungated[] = {{{ungated}}};
    Hook hook;
    static_assert(RaidRelease::AllRaidsReleased == 7);
    for (uint32 stage = 0; stage <= 9; ++stage)
    {{
        g_raidReleaseStage = stage;
        for (auto const& [mapId, raidStage] : expected)
        {{
            Player player;
            MapEntry entry{{ mapId }};
            bool const open = hook.OnPlayerCanEnterMap(&player, &entry, nullptr, nullptr, false);
            assert(open == (raidStage <= stage));
            assert(player.session.messages == (open ? 0u : 1u));
            Player loginPlayer;
            assert(hook.OnPlayerCanEnterMap(&loginPlayer, &entry, nullptr, nullptr, true) == open);
        }}
        for (uint32 mapId : ungated)
        {{
            Player player;
            MapEntry entry{{ mapId }};
            assert(hook.OnPlayerCanEnterMap(&player, &entry, nullptr, nullptr, false));
            assert(player.session.messages == 0);
        }}
    }}
    g_raidReleaseStage = 2;
    Player player;
    MapEntry moltenCore{{ 409 }}, zulGurub{{ 309 }}, onyxia{{ 249 }}, naxxramas{{ 533 }};
    assert(hook.OnPlayerCanEnterMap(&player, &moltenCore, nullptr, nullptr, false));
    assert(hook.OnPlayerCanEnterMap(&player, &zulGurub, nullptr, nullptr, false));
    assert(!hook.OnPlayerCanEnterMap(&player, &onyxia, nullptr, nullptr, false));
    assert(!hook.OnPlayerCanEnterMap(&player, &naxxramas, nullptr, nullptr, false));
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
    assert '\nAscension.CallboardCache.ReleaseStage = 7\n' in config
    assert 'Ascension.RaidLock' not in config
    with tempfile.TemporaryDirectory(prefix='coa-raid-release-') as directory:
        out = Path(directory)
        cpp, exe = out / 'raid_release.cpp', out / 'raid_release.exe'
        cpp.write_text(harness(source), encoding='utf-8')
        subprocess.run(command(cpp, exe), cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    print('PASS: Classic raids open up to the Callboard Cache release stage, closed ones refuse entry and login '
          'with "Instance is closed", other maps stay open, and the default keeps every raid open')


if __name__ == '__main__':
    main()
