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
    ClientCache const native = ClientCacheState({1278050, 35.0f}, false);
    assert(native.Item == 1278050);
    assert(native.ChancePct == 35.0f);
    ClientCache const coaLoot = ClientCacheState({1278050, 35.0f}, true);
    assert(coaLoot.Item == 1278050);
    assert(coaLoot.ChancePct == 0.0f);
}
