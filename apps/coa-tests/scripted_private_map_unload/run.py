import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[3]
MAPS = ROOT / 'src/server/game/Maps'


def extract(source, signature):
    start = source.index(signature)
    position = start + len(signature)
    depth = 1
    while depth:
        depth += (source[position] == '(') - (source[position] == ')')
        position += 1
    position = source.index('{', position) + 1
    depth = 1
    while depth:
        depth += (source[position] == '{') - (source[position] == '}')
        position += 1
    return source[start:position]


def sources():
    header = (MAPS / 'Map.h').read_text(encoding='utf-8')
    map_cpp = (MAPS / 'Map.cpp').read_text(encoding='utf-8')
    manager = (MAPS / 'MapMgr.cpp').read_text(encoding='utf-8')
    add_player = extract(map_cpp, 'bool Map::AddPlayerToMap(')
    assert re.search(r'if \(IsScriptedPrivateInstance\(\)\)\s*m_unloadTimer = 0;', add_player)
    update = extract(manager, 'void MapMgr::Update(')
    private_loop = update[update.index('_scriptedPrivateWorldMaps.begin()'):]
    deletion = re.search(r'if \((.+?)\)\s*\{\s*map->UnloadAll\(\);\s*delete map;', private_loop, re.S)
    assert deletion, 'scripted-private world map deletion not found in MapMgr::Update'
    members = '\n'.join(extract(header, signature) for signature in (
        'bool CanUnload(', 'void SetScriptedPrivateOwner(', 'void RequestScriptedPrivateUnload('))
    after_unlink = extract(map_cpp, 'void Map::AfterPlayerUnlinkFromMap(')
    return members, after_unlink, deletion.group(1)


HARNESS = r'''
#include <cassert>
#include <cstdint>
#include <set>
using uint32 = std::uint32_t;
using uint64 = std::uint64_t;
constexpr uint32 MIN_UNLOAD_DELAY = 1;
constexpr uint32 TICK = 1000;
struct ObjectGuid
{
    uint64 value = 0;
    bool IsEmpty() const { return !value; }
    auto operator<=>(ObjectGuid const&) const = default;
};
struct EventProcessor { bool HasEvents() const { return false; } };
struct Map
{
    uint32 m_unloadTimer = 0;
    uint32 _scriptedPrivateUnloadDelay = 120000;
    bool _scriptedPrivateDatabaseSpawns = false;
    ObjectGuid _scriptedPrivateOwner;
    std::set<ObjectGuid> _scriptedPrivateMembers;
    EventProcessor Events;
    uint32 players = 0;
    bool HavePlayers() const { return players != 0; }
    bool IsScriptedPrivateInstance() const { return true; }
    void AddPlayer() { ++players; m_unloadTimer = 0; }
    void RemovePlayer() { --players; AfterPlayerUnlinkFromMap(); }
    void AfterPlayerUnlinkFromMap();
    // ACTUAL_MEMBERS
};
// ACTUAL_AFTER_UNLINK
bool Deletes(Map* map, uint32 mapDiff) { return // ACTUAL_DELETION
; }
uint32 TicksUntilDeleted(Map& map, uint32 limit)
{
    for (uint32 tick = 1; tick <= limit; ++tick)
        if (Deletes(&map, TICK))
            return tick;
    return 0;
}
int main()
{
    ObjectGuid const owner{1}, partner{2};
    Map unused;
    unused.SetScriptedPrivateOwner(owner, {owner, partner});
    assert(TicksUntilDeleted(unused, 600) == 120);

    Map stage;
    stage.SetScriptedPrivateOwner(owner, {owner, partner});
    stage.AddPlayer();
    stage.SetScriptedPrivateOwner(owner, {owner});
    assert(stage.m_unloadTimer == 0);
    assert(TicksUntilDeleted(stage, 600) == 0 && stage.HavePlayers());
    stage.RemovePlayer();
    assert(TicksUntilDeleted(stage, 600) == 120);

    Map armed;
    armed.SetScriptedPrivateOwner(owner);
    armed.AddPlayer();
    armed.m_unloadTimer = MIN_UNLOAD_DELAY;
    assert(TicksUntilDeleted(armed, 600) == 0);
    armed.RemovePlayer();
    assert(TicksUntilDeleted(armed, 1) == 1);

    Map finished;
    finished.SetScriptedPrivateOwner(owner);
    finished.AddPlayer();
    finished.RequestScriptedPrivateUnload();
    assert(TicksUntilDeleted(finished, 600) == 0);
    finished.RemovePlayer();
    assert(TicksUntilDeleted(finished, 1) == 1);
}
'''


def main():
    members, after_unlink, deletion = sources()
    code = (HARNESS.replace('// ACTUAL_MEMBERS', members)
            .replace('// ACTUAL_AFTER_UNLINK', after_unlink)
            .replace('// ACTUAL_DELETION', deletion))
    compiler = shutil.which(os.environ.get('CXX', 'cl' if os.name == 'nt' else 'c++'))
    assert compiler, 'A C++20 compiler is required'
    with tempfile.TemporaryDirectory(prefix='scripted-private-map-unload-') as directory:
        out = Path(directory)
        cpp = out / 'test.cpp'
        exe = out / ('test.exe' if os.name == 'nt' else 'test')
        cpp.write_text(code, encoding='utf-8')
        flags = (['/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', str(cpp), '/Fe' + str(exe)]
                 if Path(compiler).stem.lower() == 'cl'
                 else ['-std=c++20', '-Wall', '-Wextra', '-Werror', str(cpp), '-o', str(exe)])
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=120)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=30)
    print('PASS: scripted-private maps stay loaded while a player is inside, '
          'including after a member refresh, and unload once empty.')


if __name__ == '__main__':
    main()
