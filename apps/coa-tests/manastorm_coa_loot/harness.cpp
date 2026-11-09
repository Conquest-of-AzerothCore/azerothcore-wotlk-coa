#include "ManastormCoALootPolicy.h"
#include <cassert>
#include <limits>

int main()
{
    using namespace ManastormCoALoot;
    Window const saved{1000, 87400, 995};
    assert(CurrentWindow(saved, 1000).Start == 1000);
    assert(CurrentWindow(saved, 87399).Earned == 995);
    assert(CurrentWindow(saved, 87400).Start == 0);
    assert(CurrentWindow(saved, 87400).Earned == 0);
    assert(CurrentWindow(saved, 999).Start == 1000);
    assert(CurrentWindow({}, 5000).Start == 0);
    assert(Remaining(0, 1000) == 1000);
    assert(Remaining(995, 1000) == 5);
    assert(Remaining(1000, 1000) == 0);
    assert(Remaining(1001, 1000) == 0);
    assert(Award(25, 0, 1000) == 25);
    assert(Award(10, 25, 1000) == 10);
    assert(Award(25, 995, 1000) == 5);
    assert(Award(10, 1000, 1000) == 0);
    assert(Award(25, 0, 0) == 0);
    assert(Award(std::numeric_limits<std::uint32_t>::max(), 995, 1000) == 5);
}
