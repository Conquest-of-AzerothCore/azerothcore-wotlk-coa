import math
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[3]
RULES = ROOT / 'modules/mod-ethereal-bazaar/src/BazaarDegressionRules.h'
TOKENS = ROOT / 'modules/mod-ethereal-bazaar/src/EtherealBazaarTokens.cpp'
DATA_MAP_DIR = ROOT / 'src/common/Utilities'


def extract_degression_block(source):
    start = source.index('class DegressionState')
    end = source.index('void Grant(')
    return source[start:end]


def main():
    source = TOKENS.read_text(encoding='utf-8')
    assert RULES.exists(), 'BazaarDegressionRules.h is missing'

    boss_branch = source[source.index('if (killed->IsDungeonBoss())'):source.index('Grant(player, ApplyDegression')]
    assert 'ApplyDegression' not in boss_branch, 'the boss branch must stay undegressed'
    assert 'ApplyDegression(player, killed, Wuerfeln("Creature"' in source

    degression_block = extract_degression_block(source)

    code = r'''
#include "BazaarDegressionRules.h"
#include "DataMap.h"

#include <cassert>
#include <cmath>
#include <cstdint>
#include <map>
#include <random>
#include <string>
#include <vector>

using uint32 = std::uint32_t;
using uint64 = std::uint64_t;

namespace GameTime
{
    uint64 g_now = 0;
    struct Seconds
    {
        uint64 value;
        uint64 count() const { return value; }
    };
    Seconds GetGameTime() { return Seconds{g_now}; }
}

double g_rand_draw = 0.0;
double rand_norm() { return g_rand_draw; }

struct ConfigStub
{
    std::map<std::string, uint32> overrides;

    template <class T>
    T GetOption(std::string const& key, T def)
    {
        auto it = overrides.find(key);
        if (it == overrides.end())
            return def;
        return static_cast<T>(it->second);
    }
};
ConfigStub configInstance;
ConfigStub* sConfigMgr = &configInstance;

struct Map
{
    bool world = true;
    bool IsWorldMap() const { return world; }
};

struct Creature
{
    uint32 entry = 1;
    uint32 respawnDelay = 300;
    Map map;
    uint32 GetEntry() const { return entry; }
    uint32 GetRespawnDelay() const { return respawnDelay; }
    Map* GetMap() { return &map; }
};

struct Player
{
    DataMap CustomData;
};

namespace
{
''' + degression_block + r'''
}

int main()
{
    // --- pure arithmetic: multiplier sequence with defaults ---
    double const factor = 67.0 / 100.0;
    for (int kill = 0; kill <= 10; ++kill)
    {
        double const expected = std::pow(factor, double(kill));
        double const actual = BazaarDegression::Multiplier(double(kill), 67);
        assert(std::fabs(actual - expected) < 1e-9);
    }
    assert(std::fabs(BazaarDegression::Multiplier(0, 67) - 1.0) < 1e-12);
    assert(std::fabs(BazaarDegression::Multiplier(1, 67) - 0.67) < 1e-9);
    assert(std::fabs(BazaarDegression::Multiplier(2, 67) - 0.4489) < 1e-9);

    // --- cutoff kicks in at the right kill: heat 7 (kill 8) still pays,
    // heat 8 (kill 9) does not, with the documented defaults ---
    assert(!BazaarDegression::IsBelowCutoff(BazaarDegression::Multiplier(7, 67), 5));
    assert(BazaarDegression::IsBelowCutoff(BazaarDegression::Multiplier(8, 67), 5));

    // --- decay over time, tied to respawn delay and recovery factor ---
    assert(std::fabs(BazaarDegression::DecayHeat(2.0, 600, 300, 2) - 1.0) < 1e-9);
    assert(std::fabs(BazaarDegression::DecayHeat(1.0, 600, 300, 2) - 0.0) < 1e-9);
    assert(BazaarDegression::DecayHeat(0.5, 10000, 300, 2) == 0.0);
    assert(std::fabs(BazaarDegression::DecayHeat(4.0, 300, 300, 1) - 3.0) < 1e-9);
    // a respawn delay of zero falls back to the documented default of 300s
    assert(std::fabs(BazaarDegression::DecayHeat(1.0, 600, 0, 2) - 0.0) < 1e-9);
    // a tiny respawn delay is floored, not treated as a free divide
    assert(BazaarDegression::EffectiveRespawnDelay(0) == 300);
    assert(BazaarDegression::EffectiveRespawnDelay(1) == 1);

    // --- eviction at MaxEntries: the least recently updated entry is dropped ---
    std::vector<BazaarDegression::Entry> entries{
        {1, 0.0, 50}, {2, 0.0, 10}, {3, 0.0, 30}
    };
    assert(BazaarDegression::LeastRecentlyUpdatedIndex(entries) == 1);
    entries[1].lastUpdate = 1000;
    assert(BazaarDegression::LeastRecentlyUpdatedIndex(entries) == 2);

    // --- expectation preserved by stochastic rounding (large sample) ---
    {
        std::mt19937 engine(12345);
        std::uniform_real_distribution<double> uniform(0.0, 1.0);
        uint32 const amount = 7;
        double const multiplier = 0.4489;
        uint64_t sum = 0;
        int const samples = 200000;
        for (int i = 0; i < samples; ++i)
            sum += BazaarDegression::ScaledAmount(amount, multiplier, uniform(engine));
        double const mean = double(sum) / samples;
        double const expected = amount * multiplier;
        assert(std::fabs(mean - expected) < 0.02);
    }

    // --- Enable=0 bypasses degression entirely ---
    {
        Player player;
        Creature creature;
        creature.entry = 42;
        configInstance.overrides["EtherealBazaar.Tokens.Degression.Enable"] = 0;
        uint32 const result = ApplyDegression(&player, &creature, 2);
        assert(result == 2);
        configInstance.overrides.erase("EtherealBazaar.Tokens.Degression.Enable");
    }

    // --- non-open-world kills bypass degression ---
    {
        Player player;
        Creature creature;
        creature.entry = 42;
        creature.map.world = false;
        GameTime::g_now = 0;
        uint32 const result = ApplyDegression(&player, &creature, 2);
        assert(result == 2);
    }

    // --- heat rises by one per kill of the same entry and multiplies the
    // roll accordingly, deterministically with a fixed draw ---
    {
        Player player;
        Creature creature;
        creature.entry = 99;
        creature.respawnDelay = 300;
        GameTime::g_now = 0;
        g_rand_draw = 0.99; // never round up from a fractional remainder

        uint32 const first = ApplyDegression(&player, &creature, 2);
        assert(first == 2); // heat 0, multiplier 1

        uint32 const second = ApplyDegression(&player, &creature, 2);
        assert(second == 1); // heat 1, multiplier .67, 2*.67=1.34; a .99 draw never rounds the .34 up

        for (int i = 0; i < 6; ++i)
            ApplyDegression(&player, &creature, 2); // heats climb to 8

        uint32 const ninth = ApplyDegression(&player, &creature, 2);
        assert(ninth == 0); // heat 8, multiplier .67^8 ~= .04, under the 5% cutoff
    }

    // --- heat still rises on a kill whose pre-rolled amount is zero, so a
    // zero roll never lets a later kill escape its share of the cutoff ---
    {
        Player player;
        Creature creature;
        creature.entry = 7;
        GameTime::g_now = 0;
        g_rand_draw = 0.99;

        uint32 const zeroRoll = ApplyDegression(&player, &creature, 0);
        assert(zeroRoll == 0);

        uint32 const afterZeroRoll = ApplyDegression(&player, &creature, 2);
        assert(afterZeroRoll == 1); // heat 1 from the zero-amount kill, multiplier .67, 2*.67=1.34
    }

    // --- a different entry starts its own multiplier fresh ---
    {
        Player player;
        Creature a;
        a.entry = 1;
        Creature b;
        b.entry = 2;
        GameTime::g_now = 0;
        g_rand_draw = 0.0; // always round up on any fractional remainder

        for (int i = 0; i < 9; ++i)
            ApplyDegression(&player, &a, 2);
        uint32 const aNinth = ApplyDegression(&player, &a, 2);
        assert(aNinth == 0);

        uint32 const bFirst = ApplyDegression(&player, &b, 2);
        assert(bFirst == 2); // fresh entry, heat 0
    }

    // --- the table is bounded and evicts the least recently updated entry ---
    {
        Player player;
        configInstance.overrides["EtherealBazaar.Tokens.Degression.MaxEntries"] = 2;
        GameTime::g_now = 0;
        Creature a; a.entry = 1;
        Creature b; b.entry = 2;
        Creature c; c.entry = 3;
        g_rand_draw = 0.99;

        ApplyDegression(&player, &a, 2);
        GameTime::g_now = 1;
        ApplyDegression(&player, &b, 2);
        GameTime::g_now = 2;
        // a new entry evicts the least recently updated tracked entry (a)
        ApplyDegression(&player, &c, 2);
        GameTime::g_now = 3;
        // a is gone from the table, so it is treated as fresh again (heat 0)
        uint32 const aAgain = ApplyDegression(&player, &a, 2);
        assert(aAgain == 2);

        configInstance.overrides.erase("EtherealBazaar.Tokens.Degression.MaxEntries");
    }

    return 0;
}
'''
    compiler = shutil.which(os.environ.get('CXX', 'c++'))
    assert compiler, 'A C++20 compiler is required'
    with tempfile.TemporaryDirectory(prefix='bazaar-degression-') as directory:
        cpp = Path(directory) / 'test.cpp'
        exe = Path(directory) / 'test'
        cpp.write_text(code, encoding='utf-8')
        subprocess.run([compiler, '-std=c++20', '-Wall', '-Wextra', '-Werror',
                        '-I', str(RULES.parent), '-I', str(DATA_MAP_DIR),
                        str(cpp), '-o', str(exe)], check=True, timeout=120)
        subprocess.run([str(exe)], check=True, timeout=30)
    print('PASS: multiplier/cutoff/decay arithmetic, eviction, stochastic-rounding expectation, '
          'enable/world-map bypass, per-entry heat and a fresh entry, bounded table eviction, boss branch untouched')


if __name__ == '__main__':
    main()
