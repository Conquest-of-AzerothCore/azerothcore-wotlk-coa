#include "../../../src/server/coa/CoAGuardLevelPolicy.h"
#include <cassert>

int main()
{
    using CoAGuardLevel::Capped;
    assert(Capped(75, 60) == 60);
    assert(Capped(65, 60) == 60);
    assert(Capped(75, 70) == 70);
    assert(Capped(75, 80) == 75);
    assert(Capped(60, 60) == 60);
    assert(Capped(40, 60) == 40);
    return 0;
}
