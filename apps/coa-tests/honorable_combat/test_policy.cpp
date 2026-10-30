#include "../../../src/server/coa/AscensionHonorableCombatPolicy.h"
#include <cassert>
#include <iostream>

int main()
{
    using namespace HonorableCombat;
    assert(IsHonorableZone(28) && IsHonorableZone(618));
    assert(!IsHonorableZone(357) && !IsHonorableZone(139) && !IsHonorableZone(0));
    assert(Eligible(28, true) && Eligible(618, true));
    assert(!Eligible(28, false) && !Eligible(357, true));
    assert(ZonesOpcode == 0x0768 && HonorableAura == 9930870 && CombatAura == 9930871);

    for (unsigned criteria : {15691u, 15695u, 21691u, 21695u})
        assert(IsWinCriteria(criteria));
    assert(!IsWinCriteria(15692) && !IsWinCriteria(0));

    assert(CanEngage(1, 0, 2, 0));
    assert(CanEngage(1, 2, 2, 1));
    assert(!CanEngage(3, 0, 2, 1));
    assert(!CanEngage(1, 2, 3, 0));

    assert(BlocksAssist(3, 0, 2, 1));
    assert(BlocksAssist(1, 2, 3, 0));
    assert(!BlocksAssist(1, 2, 1, 2));
    assert(!BlocksAssist(3, 0, 4, 0));

    assert(StartsLock(true, false, false, false));
    assert(!StartsLock(false, false, false, false));
    assert(!StartsLock(true, true, false, false));
    assert(!StartsLock(true, false, true, false));
    assert(!StartsLock(true, false, false, true));

    assert(IsInitiation(false, false));
    assert(!IsInitiation(false, true));
    assert(!IsInitiation(true, false));

    assert(IsWin(1, 1, 28) && IsWin(1, 1, 618));
    assert(!IsWin(3, 1, 28) && !IsWin(1, 1, 357) && !IsWin(0, 0, 28));
    std::cout << "honorable combat policy ok\n";
}
