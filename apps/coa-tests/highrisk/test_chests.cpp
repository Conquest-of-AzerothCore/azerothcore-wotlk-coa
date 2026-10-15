#include "../../../src/server/coa/AscensionHighRiskPolicy.h"
#include <cassert>
#include <limits>

int main()
{
    using namespace HighRisk;
    for (unsigned level = 1; level <= 80; ++level)
    {
        assert(Eligible(level, true, false, false) == (level >= 15));
        assert(!Eligible(level, true, true, false));
        assert(!Eligible(level, true, false, true));
        assert(!Eligible(level, false, false, false));
    }
    assert(GearLimit(15) == 1 && GearLimit(59) == 1 && GearLimit(60) == 2);
    assert(GoldLoss(0, 5) == 0 && GoldLoss(19, 5) == 0 && GoldLoss(20, 5) == 1);
    assert(GoldLoss(100000, 3) == 3000);
    assert(GoldLoss(2147483646, 5) == 107374182);
    assert(GoldLoss(std::numeric_limits<unsigned>::max(), 100) == 4294967295U);
}
