import os
from pathlib import Path
import runpy
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[3]


def main():
    extract = runpy.run_path(str(ROOT / 'apps/coa-tests/client_compat/run.py'))['method']
    source = (ROOT / 'modules/mod-ethereal-bazaar/src/EtherealBazaarTokens.cpp').read_text()
    assert 'void OnPlayerCreatureKill(' not in source
    assert 'OnUnitDeath' not in source and 'UnitScript' not in source
    conf = (ROOT / 'modules/mod-ethereal-bazaar/conf/ethereal_bazaar.conf.dist').read_text()
    assert 'GroupShare' not in source and 'GroupShare' not in conf
    callback = extract(source, 'void OnPlayerRewardKillRewarder(').replace(' override', '')
    code = r'''
#include <cassert>
#include <cstdint>
using uint32 = std::uint32_t;
struct Map { bool raid = false; bool IsRaid() const { return raid; } };
struct Creature
{
    bool summon = false, critter = false, totem = false, boss = false;
    Map map;
    bool IsSummon() const { return summon; }
    bool IsCritter() const { return critter; }
    bool IsTotem() const { return totem; }
    bool IsDungeonBoss() const { return boss; }
    Map* GetMap() { return &map; }
};
struct Unit { Creature* creature; Creature* ToCreature() { return creature; } };
struct Player { uint32 tokens = 0; };
struct KillRewarder { Unit* victim; Unit* GetVictim() { return victim; } };
bool enabled = true;
bool Enabled() { return enabled; }
uint32 Wuerfeln(char const*, uint32 lo, uint32) { return lo ? lo : 3; }
void Grant(Player* player, uint32 amount, char const*) { player->tokens += amount; }
''' + callback + r'''
int main()
{
    Creature creature;
    Unit victim{&creature}, pvp{nullptr};
    KillRewarder rewarder{&victim}, playerKill{&pvp}, noVictim{nullptr};
    Player killer, healer;
    float rate = 1.0f;
    OnPlayerRewardKillRewarder(&killer, &rewarder, false, rate);
    OnPlayerRewardKillRewarder(&healer, &rewarder, false, rate);
    assert(killer.tokens == 3 && healer.tokens == 3 && rate == 1.0f);
    creature.boss = true;
    OnPlayerRewardKillRewarder(&healer, &rewarder, true, rate);
    assert(healer.tokens == 17);
    creature.map.raid = true;
    OnPlayerRewardKillRewarder(&healer, &rewarder, true, rate);
    assert(healer.tokens == 58);
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
    enabled = false;
    OnPlayerRewardKillRewarder(&healer, &rewarder, false, rate);
    assert(healer.tokens == 58);
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
    print('PASS: one kill-credit path for all group members, reward bands, exclusions, PvP, disabled and null guards')


if __name__ == '__main__':
    main()
