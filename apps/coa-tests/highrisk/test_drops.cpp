#include "../../../src/server/coa/AscensionBloodforgedPolicy.h"
#include <cassert>
#include <cmath>
#include <iostream>

int main()
{
    using namespace Bloodforged;
    unsigned checked = 0;
    for (unsigned level = 15; level <= 60; ++level)
    {
        auto const& rates = DefaultRates[Band(level)];
        assert(ValidRates(rates));
        for (unsigned quality = 0; quality < rates.size(); ++quality)
        {
            float total = 0.0f;
            for (std::size_t pool : {1u, 5u, 9u, 250u})
                total += EntryChance(rates[quality], pool) * static_cast<float>(pool);
            assert(std::abs(total - 4.0f * static_cast<float>(rates[quality]) / 100.0f) < 0.01f);
            ++checked;
        }
        assert(!EligibleItem(70, 80, level));
        assert(!EligibleItem(80, 100, level));
        assert(!EligibleItem(1, 150, level));
        assert(EligibleItem(0, 15, level));
        assert(!EligibleItem(0, 162, level));
    }
    assert(Band(24) == 0 && Band(25) == 1);
    assert(Band(34) == 1 && Band(35) == 2);
    assert(Band(44) == 2 && Band(45) == 3);
    assert(Band(54) == 3 && Band(55) == 4);
    assert(EligibleItem(10, 15, 15));
    assert(!EligibleItem(29, 34, 28));
    assert(EligibleItem(29, 34, 29));
    assert(!ValidRates({10001, 2, 1}));
    assert(!ValidRates({1, 2, 3}));
    assert(!ValidRates({2, 2, 1}));
    assert(!ValidRates({2, 1, 1}));
    assert(!EligibleItem(10, 15, 14));
    assert(!EligibleItem(60, 65, 70));
    assert(InGearTier(61, 60, 90));
    assert(!InGearTier(15, 60, 90));
    assert(InGearTier(37, 55, 37));
    assert(EntryChance(450, 0) == 0.0f);
    assert(std::abs(EntryChance(450, 9) - 0.5f) < 0.0001f);
    for (Rates const& rates : DefaultRates)
        assert(rates[0] == 0);
    assert(ValidRates({0, 50, 0}));
    assert(!ValidRates({0, 50, 50}));
    assert(!ValidRates({40, 50, 0}));
    assert(DefaultBlueMaxItemLevel == 57);
    assert(DefaultEpicMaxItemLevelByStage[1] == 61 && DefaultEpicMaxItemLevelByStage[2] == 64);
    assert(DefaultEpicMaxItemLevelByStage[3] == 65 && DefaultEpicMaxItemLevelByStage[4] == 70);
    assert(WithinItemLevelCap(3, 57, 57, 61));
    assert(!WithinItemLevelCap(3, 58, 57, 61));
    assert(WithinItemLevelCap(4, 61, 57, 61));
    assert(!WithinItemLevelCap(4, 62, 57, 61));
    for (std::uint32_t zone : {28u, 139u, 46u, 4u, 16u, 618u, 490u, 1377u})
        assert(IsEndgameZone(zone));
    assert(!IsEndgameZone(12) && !IsEndgameZone(0) && !IsEndgameZone(41));
    assert(AllowedInZone(60, true, true));
    assert(!AllowedInZone(60, false, true));
    assert(AllowedInZone(59, false, true));
    assert(AllowedInZone(60, false, false));
    assert(DefaultRare.raidPercent == 15 && DefaultRare.heroicRaidPercent == 5);
    assert(DefaultRareElite.raidPercent == 25 && DefaultRareElite.heroicRaidPercent == 10);
    assert(DefaultRare.respawnMinMinutes == 90 && DefaultRare.respawnMaxMinutes == 150);
    assert(DefaultRareElite.respawnMinMinutes == 150 && DefaultRareElite.respawnMaxMinutes == 210);
    std::cout << checked << " rate invariants verified\n";
}
