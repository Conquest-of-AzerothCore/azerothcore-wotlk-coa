#include "AscensionPvePowerPolicy.h"
#include <iostream>

namespace
{
int failures = 0;

void Expect(bool condition, char const* what)
{
    if (!condition)
    {
        std::cerr << "FAIL: " << what << "\n";
        ++failures;
    }
}
}

int main()
{
    using namespace PvePower;

    for (unsigned points = 0; points < 100; ++points)
        Expect(SpellPower(101600 + points) == points, "PvE Power marker spells map to their points");
    Expect(SpellPower(101599) == 0 && SpellPower(101700) == 0, "spells outside the PvE marker range add nothing");
    Expect(SpellPower(101742) == 0, "PvP Power marker spells add no PvE Power");

    Expect(Cap == 495 && MinimumLevel == 60, "cap and minimum level match the client and the realm");

    Expect(PvpPower::Scale(10000, 495, DamageBasisPoints) == 12475, "495 points deal 24.75% more damage");
    Expect(PvpPower::Scale(10000, 495, DamageBasisPoints, true) == 7525, "495 points take 24.75% less damage");
    Expect(PvpPower::Scale(10000, 495, HealingBasisPoints) == 10990, "495 points heal 9.9% more");
    Expect(PvpPower::Scale(10000, 45, DamageBasisPoints) == 10225, "45 points deal 2.25% more damage");
    Expect(PvpPower::Scale(10000, 45, HealingBasisPoints) == 10090, "45 points heal 0.9% more");
    Expect(PvpPower::Scale(10000, 0, DamageBasisPoints) == 10000, "no points change nothing");

    Expect(PvpPower::Scale(PvpPower::Scale(10000, 495, DamageBasisPoints), 495, DamageBasisPoints) == 15562,
        "PvE and PvP Power multiply");

    for (MapKind kind : {OpenWorld, Instance, Battleground})
        Expect(Applies(DamageMaps, kind), "damage applies on every map");
    Expect(!Applies(HealingMaps, OpenWorld), "healing does not apply in the open world");
    Expect(Applies(HealingMaps, Instance), "healing applies in instances");
    Expect(!Applies(HealingMaps, Battleground), "healing does not apply in battlegrounds");

    if (failures)
        return 1;
    std::cout << "PvE Power mapping, cap, damage, reduction, healing and map scope checks passed\n";
    return 0;
}
