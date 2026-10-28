import os
from pathlib import Path
import re
import runpy
import shutil
import sqlite3
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[3]


def main():
    extract = runpy.run_path(str(ROOT / 'apps/coa-tests/client_compat/run.py'))['method']
    source = (ROOT / 'modules/mod-coa-challenges/src/CoA.Challenges.Lifecycle.cpp').read_text()
    callback = extract(source, 'bool AdventureModeChangeBlocked(') + extract(source, 'uint32 LowerAdventureModeLevel(')
    database = (ROOT / 'src/server/database/Database/Implementation/CharacterDatabase.cpp').read_text()
    sql = re.search(r'PrepareStatement\(CHAR_UPD_COA_ADVENTURE_LEVEL,\s*"([^"]+)"', database)[1]
    db = sqlite3.connect(':memory:')
    db.execute('CREATE TABLE coa_character_challenge '
               '(guid, challengeId, level, deaths, hunger, thirst, startTime)')
    db.executemany('INSERT INTO coa_character_challenge VALUES (?,?,?,?,?,?,?)',
                   [(1, 211, 100, 2, 40, 50, 123), (2, 211, 100, 0, 90, 90, 456),
                    (1, 99, 4, 3, 70, 80, 789)])
    db.execute(sql, (1, 1, 211))
    assert list(db.execute('SELECT * FROM coa_character_challenge')) == [
        (1, 211, 1, 2, 40, 50, 123), (2, 211, 100, 0, 90, 90, 456), (1, 99, 4, 3, 70, 80, 789)]
    code = r'''
#include <array>
#include <cassert>
#include <cstdint>
#include <set>
#include <string>
using uint32 = std::uint32_t;
struct Guid { uint32 GetCounter() const { return 1; } };
struct Unit { bool combat = false; bool IsInCombat() const { return combat; } };
struct Group;
struct InstanceScript { bool encounter = false; bool IsEncounterInProgress() const { return encounter; } };
struct Player
{
    std::set<Unit*> m_Controlled;
    Group* group = nullptr;
    InstanceScript* instance = nullptr;
    bool mapAvailable = true;
    void* FindMap() { return mapAvailable ? this : nullptr; }
    bool flight = false, charmed = false;
    uint32 questRefreshes = 0;
    Group* GetGroup() { return group; }
    InstanceScript* GetInstanceScript() { assert(mapAvailable); return instance; }
    bool IsInFlight() const { return flight; }
    bool IsCharmed() const { return charmed; }
    void RefreshQuestLogQueries() { ++questRefreshes; }
    bool alive = true, combat = false, teleporting = false;
    Guid GetGUID() const { return {}; }
    void* GetSession() { return nullptr; }
    bool IsAlive() const { return alive; }
    bool IsInCombat() const { return combat; }
    bool IsBeingTeleported() const { return teleporting; }
};
struct GroupReference
{
    Player* player = nullptr;
    Player* GetSource() { return player; }
    GroupReference* next() { return nullptr; }
};
struct Group
{
    GroupReference member;
    GroupReference* GetFirstMember() { return &member; }
};
struct ChatHandler
{
    explicit ChatHandler(void*) { }
    void SendSysMessage(char const*) { }
    void PSendSysMessage(char const*, uint32) { }
};
uint32 current = 100, applied = 100, writes = 0, refreshes = 0;
bool completed = false, custom = false;
std::set<uint32> active{211};
uint32 ActiveChallengeLevel(uint32, uint32) { return current; }
std::set<uint32> ActiveChallenges(uint32) { return active; }
uint32 ChallengeLevelCount(uint32) { return 100; }
std::string GetActiveCustomTrial(uint32) { return custom ? "trial" : ""; }
bool HasCompletionLevel(uint32, uint32, uint32) { return completed; }
constexpr int CHAR_UPD_COA_ADVENTURE_LEVEL = 1;
struct Statement
{
    std::array<uint32, 3> values{};
    void SetData(unsigned index, uint32 value) { values.at(index) = value; }
};
struct Database
{
    Statement statement;
    Statement* GetPreparedStatement(int id) { assert(id == 1); return &statement; }
    void DirectExecute(Statement* update)
    {
        assert(update->values[1] == 1 && active.contains(update->values[2]));
        current = update->values[0];
        ++writes;
    }
} CharacterDatabase;
void ClearCharChallengeCache(uint32) { }
void RemoveChallengeSpell(Player*, uint32) { applied = 0; }
void ApplyChallengeSpell(Player*, uint32, uint32 level) { assert(applied == 0); applied = level; }
void RefreshLevelScalingTracking(Player*) { ++refreshes; }
void SendActiveList(Player*) { }
void SendCriteriaState(Player*) { }
void BroadcastChallengeSync(Player*, uint32, uint32 level, bool remove)
{
    assert(level == current && !remove);
}
''' + callback + r'''
int main()
{
    Player player;
    assert(LowerAdventureModeLevel(&player, 211, 0) != 0);
    assert(LowerAdventureModeLevel(&player, 211, 100) != 0);
    assert(LowerAdventureModeLevel(&player, 211, 101) != 0);
    assert(LowerAdventureModeLevel(&player, 99, 1) != 0);
    player.combat = true;
    assert(LowerAdventureModeLevel(&player, 211, 1) != 0);
    player.combat = false;
    player.alive = false;
    assert(LowerAdventureModeLevel(&player, 211, 1) != 0);
    player.alive = true;
    player.teleporting = true;
    assert(LowerAdventureModeLevel(&player, 211, 1) != 0);
    player.teleporting = false;
    player.mapAvailable = false;
    assert(LowerAdventureModeLevel(&player, 211, 1) != 0);
    player.mapAvailable = true;
    player.flight = true;
    assert(LowerAdventureModeLevel(&player, 211, 1) != 0);
    player.flight = false;
    player.charmed = true;
    assert(LowerAdventureModeLevel(&player, 211, 1) != 0);
    player.charmed = false;
    Unit pet; pet.combat = true;
    player.m_Controlled.insert(&pet);
    assert(LowerAdventureModeLevel(&player, 211, 1) != 0);
    player.m_Controlled.clear();
    Player friendPlayer;
    Group group; group.member.player = &friendPlayer; player.group = &group;
    friendPlayer.combat = true;
    assert(LowerAdventureModeLevel(&player, 211, 1) != 0);
    friendPlayer.combat = false;
    friendPlayer.m_Controlled.insert(&pet);
    assert(LowerAdventureModeLevel(&player, 211, 1) != 0);
    player.group = nullptr;
    InstanceScript instance; instance.encounter = true; player.instance = &instance;
    assert(LowerAdventureModeLevel(&player, 211, 1) != 0);
    player.instance = nullptr;
    custom = true;
    assert(LowerAdventureModeLevel(&player, 211, 1) != 0);
    custom = false;
    completed = true;
    assert(LowerAdventureModeLevel(&player, 211, 1) != 0);
    completed = false;
    assert(writes == 0 && current == 100 && applied == 100 && player.questRefreshes == 0);
    assert(LowerAdventureModeLevel(&player, 211, 1) == 0);
    assert(current == 1 && applied == 1 && writes == 1 && refreshes == 1 && player.questRefreshes == 1);
    assert(LowerAdventureModeLevel(&player, 211, 100) != 0);
    active = {425}; current = applied = 100;
    assert(LowerAdventureModeLevel(&player, 425, 50) == 0);
    assert(current == 50 && applied == 50 && writes == 2 && refreshes == 2);
}
'''
    compiler = shutil.which(os.environ.get('CXX', 'c++'))
    assert compiler, 'A C++20 compiler is required'
    with tempfile.TemporaryDirectory(prefix='adventure-downscale-') as directory:
        cpp = Path(directory) / 'test.cpp'
        exe = Path(directory) / 'test'
        cpp.write_text(code, encoding='utf-8')
        subprocess.run([compiler, '-std=c++20', '-Wall', '-Wextra', '-Werror', str(cpp), '-o', str(exe)],
                       check=True, timeout=60)
        subprocess.run([str(exe)], check=True, timeout=15)
    print('PASS: downscale guards, normal/prestige modes, aura replacement, persistent level and preserved run state')


if __name__ == '__main__':
    main()
