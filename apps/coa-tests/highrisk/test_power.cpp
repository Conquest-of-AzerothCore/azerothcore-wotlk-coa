#include "../../../src/server/coa/AscensionPvpPowerPolicy.h"
#include <cassert>
#include <iostream>

int main()
{
    using namespace PvpPower;
    for (unsigned points = 0; points < 100; ++points)
        assert(SpellPower(101700 + points) == points);
    assert(SpellPower(101699) == 0 && SpellPower(101800) == 0);
    assert(SpellPower(9930954) == 5 && SpellPower(9930957) == 10);
    assert(Scale(10000, 100, 5) == 10500);
    assert(Scale(10000, 100, 2) == 10200);
    assert(Scale(10000, 100, 5, true) == 9500);
    assert(Scale(10000, 495, 5) == 12475);
    assert(Scale(10000, 495, 2) == 10990);
    assert(Scale(10000, 495, 5, true) == 7525);
    assert(Scale(10000, 5000, 5) == Scale(10000, 495, 5));
    assert(Scale(0, 495, 5) == 0);
    assert(Scale(10000, 0, 5) == 10000);
    assert(Scale(4294967295u, 0, 5) == 4294967295u);
    assert(Scale(4294967295u, 495, 5) == 2147483647u);
    for (bool instance : {false, true})
        for (bool battleground : {false, true})
            for (bool highRisk : {false, true})
                for (bool warMode : {false, true})
                    assert(HealingContext(instance, battleground, highRisk, warMode)
                        == (battleground || (!instance && (highRisk || warMode))));
    std::cout << "PvP Power mapping, cap, damage, reduction, healing and context checks passed\n";
}
