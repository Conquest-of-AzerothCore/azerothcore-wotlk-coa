#include "../../../src/server/coa/AscensionBloodforgedPolicy.h"
#include <cassert>
#include <iostream>

int main()
{
    using namespace Bloodforged;
    unsigned checked = 0;
    for (unsigned level = 15; level <= 60; ++level)
    {
        auto const& rates = DefaultRates[Band(level)];
        std::array<unsigned, 5> counts{};
        for (unsigned roll = 0; roll < 10000; ++roll)
        {
            ++counts[RollQuality(roll, rates)];
            ++checked;
        }
        assert(counts[2] == rates[0] && counts[3] == rates[1] && counts[4] == rates[2]);
        assert(counts[0] == 10000 - rates[0] - rates[1] - rates[2]);
        assert(counts[2] > counts[3] && counts[3] > counts[4]);
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
    assert(RollQuality(10000, DefaultRates[0]) == 0);
    std::cout << checked << " deterministic roll outcomes verified\n";
}
