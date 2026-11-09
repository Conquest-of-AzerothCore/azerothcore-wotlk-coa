import os
from pathlib import Path
import runpy
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[3]


def main():
    extract = runpy.run_path(str(ROOT / 'apps/coa-tests/client_compat/run.py'))['method']
    source = (ROOT / 'modules/mod-ethereal-bazaar/src/EtherealBazaarTokens.cpp').read_text(encoding='utf-8')
    assert 'void OnPlayerCreatureKill(' not in source
    assert 'OnUnitDeath' not in source and 'UnitScript' not in source
    conf = (ROOT / 'modules/mod-ethereal-bazaar/conf/ethereal_bazaar.conf.dist').read_text()
    assert 'GroupShare' not in source and 'GroupShare' not in conf
    assert 'WasAttackedDirectlyBy' not in source and 'SOLO_KILL_REQUIRES_PLAYER_HIT' not in source
    callback = extract(source, 'void OnPlayerRewardKillRewarder(').replace(' override', '')
    flush = extract(source, 'void FlushPending(')
    queue = extract(source, 'void QueueKillReward(')
    code = r'''
#include <cassert>
#include <cstdint>
#include <functional>
#include <limits>
#include <string>
#include <utility>
using uint32 = std::uint32_t;
struct Map { bool raid = false; bool IsRaid() const { return raid; } };
struct Creature
{
    bool pays = true;
    bool summon = false, critter = false, totem = false, boss = false;
    mutable uint32 levelChecks = 0;
    Map map;
    bool IsSummon() const { return summon; }
    bool IsCritter() const { return critter; }
    bool IsTotem() const { return totem; }
    bool IsDungeonBoss() const { return boss; }
    Map* GetMap() { return &map; }
};
struct Unit { Creature* creature; Creature* ToCreature() { return creature; } };
struct PendingTokens { uint32 Amount = 0; bool Scheduled = false; };
std::string const PendingTokensKey = "tokens";
constexpr uint32 KillPayoutMinimumMs = 1000;
constexpr uint32 KillPayoutSpreadMs = 1000;
struct PlayerData
{
    PendingTokens pending;
    template<class T> T* Get(std::string const&) { return &pending; }
    template<class T> T* GetDefault(std::string const&) { return &pending; }
};
using Milliseconds = int;
struct Events
{
    std::function<void()> callback;
    Milliseconds delay = 0;
    void AddEventAtOffset(std::function<void()> next, Milliseconds offset)
    {
        assert(!callback && offset >= 1000 && offset < 2000);
        delay = offset;
        callback = std::move(next);
    }
    void Run() { std::exchange(callback, nullptr)(); }
};
struct Player;
struct ObjectGuid
{
    Player* owner;
    uint32 counter;
    uint32 GetRawValue() const { return counter; }
};
struct Player
{
    uint32 tokens = 0;
    uint32 payouts = 0;
    uint32 counter = 0;
    PlayerData CustomData;
    Events m_Events;
    ObjectGuid GetGUID() { return {this, counter}; }
};
namespace ObjectAccessor { Player* FindConnectedPlayer(ObjectGuid guid) { return guid.owner; } }
struct KillRewarder { Unit* victim; Unit* GetVictim() { return victim; } };
struct RewardRange { uint32 amount; uint32 Roll() const { return amount; } };
struct TokenSettings
{
    bool Enabled = true, Announce = false;
    RewardRange Creature{2}, DungeonBoss{6}, RaidBoss{30};
};
struct SettingStore { TokenSettings settings; TokenSettings* load() { return &settings; } } Settings;
bool KillPays(Player*, Creature const* creature, TokenSettings const&)
{
    ++creature->levelChecks;
    return creature->pays;
}
uint32 CalculateReward(Player*, uint32 amount, TokenSettings const&) { return amount; }
void Deliver(Player* player, uint32 amount, bool)
{
    if (amount)
    {
        player->tokens += amount;
        ++player->payouts;
    }
}
''' + flush + '\n' + queue + '\n' + callback + r'''
int main()
{
    Creature creature;
    Unit victim{&creature}, pvp{nullptr};
    KillRewarder rewarder{&victim}, playerKill{&pvp}, noVictim{nullptr};
    Player killer, healer;
    healer.counter = 500;
    float rate = 1.0f;
    OnPlayerRewardKillRewarder(&killer, &rewarder, false, rate);
    OnPlayerRewardKillRewarder(&killer, &rewarder, false, rate);
    OnPlayerRewardKillRewarder(&healer, &rewarder, false, rate);
    assert(killer.tokens == 0 && healer.tokens == 0 && rate == 1.0f);
    assert(killer.m_Events.delay == 1000 && healer.m_Events.delay == 1500);
    killer.m_Events.Run();
    assert(killer.tokens == 4 && killer.payouts == 1);
    creature.boss = true;
    OnPlayerRewardKillRewarder(&healer, &rewarder, true, rate);
    assert(healer.tokens == 8 && healer.payouts == 2);
    healer.m_Events.Run();
    assert(healer.tokens == 8 && healer.payouts == 2);
    creature.map.raid = true;
    OnPlayerRewardKillRewarder(&healer, &rewarder, true, rate);
    assert(healer.tokens == 38);
    for (bool Creature::* flag : {&Creature::summon, &Creature::critter, &Creature::totem})
    {
        creature.*flag = true;
        OnPlayerRewardKillRewarder(&healer, &rewarder, false, rate);
        creature.*flag = false;
    }
    OnPlayerRewardKillRewarder(&healer, &playerKill, false, rate);
    OnPlayerRewardKillRewarder(&healer, &noVictim, false, rate);
    OnPlayerRewardKillRewarder(&healer, nullptr, false, rate);
    OnPlayerRewardKillRewarder(nullptr, &rewarder, false, rate);
    assert(healer.tokens == 38);
    creature.pays = false;
    OnPlayerRewardKillRewarder(&healer, &rewarder, true, rate);
    creature.boss = false;
    creature.map.raid = false;
    OnPlayerRewardKillRewarder(&healer, &rewarder, false, rate);
    assert(healer.tokens == 38);
    creature.pays = true;
    OnPlayerRewardKillRewarder(&killer, &rewarder, false, rate);
    FlushPending(&killer);
    killer.m_Events.Run();
    assert(killer.tokens == 6 && killer.payouts == 2);
    Settings.settings.Creature.amount = 0;
    uint32 const checks = creature.levelChecks;
    OnPlayerRewardKillRewarder(&killer, &rewarder, false, rate);
    assert(creature.levelChecks == checks && !killer.m_Events.callback);
    Settings.settings.Creature.amount = 2;
    Settings.settings.Enabled = false;
    OnPlayerRewardKillRewarder(&healer, &rewarder, false, rate);
    assert(healer.tokens == 38 && !healer.m_Events.callback);
}
'''
    code = '#include <initializer_list>\n' + code
    compiler = shutil.which(os.environ.get('CXX', 'c++'))
    assert compiler, 'A C++20 compiler is required'
    with tempfile.TemporaryDirectory(prefix='bazaar-rewards-') as directory:
        cpp = Path(directory) / 'test.cpp'
        exe = Path(directory) / 'test'
        cpp.write_text(code, encoding='utf-8')
        subprocess.run([compiler, '-std=c++20', '-Wall', '-Wextra', '-Werror', str(cpp), '-o', str(exe)],
                       check=True, timeout=60)
        subprocess.run([str(exe)], check=True, timeout=15)
    print('PASS: group credit, coalesced creature payouts, immediate boss payouts, flush without duplicate payout, and exclusions')


if __name__ == '__main__':
    main()
