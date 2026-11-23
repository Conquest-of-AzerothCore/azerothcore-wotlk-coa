#include "ManastormCoALootPolicy.h"
#include <cassert>

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
}
