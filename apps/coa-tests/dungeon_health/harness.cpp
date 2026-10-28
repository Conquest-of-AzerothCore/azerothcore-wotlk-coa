#include "DungeonHealth.h"
#include <cassert>
#include <cstdint>
#include <limits>

int main()
{
    DungeonHealth::Values values;
    values[{429, 1, 14323}] = 581500;
    values[{429, 2, 14323}] = 751000;
    values[{429, 1, 11441}] = 73200;
    values[{429, 2, 11441}] = 71400;
    values[{329, 1, 10385}] = 58500;
    values[{429, 1, 14389}] = 31300;
    auto resolve = [&](uint32_t map, uint8_t mode, uint32_t entry, uint32_t current,
                       uint32_t heroic, bool variant = true, bool pet = false, bool boss = false)
    {
        return DungeonHealth::Resolve(values, map, mode, entry, current, heroic, variant, pet, boss);
    };
    assert(resolve(429, 1, 14323, 249825, 249825) == 581500);
    assert(resolve(429, 2, 14323, 69285, 249825) == 751000);
    assert(resolve(429, 1, 11441, 31440, 31440) == 73200);
    assert(resolve(429, 2, 11441, 12576, 31440) == 71400);
    assert(resolve(329, 1, 10385, 31440, 31440) == 58500);
    assert(resolve(329, 2, 10385, 12576, 31440) == 76050);
    assert(resolve(329, 2, 10385, 12576, 31440, true, false, true) == 76050);
    assert(resolve(429, 1, 14389, 6715, 6715, false) == 31300);
    assert(resolve(429, 2, 14389, 6715, 6715, false) == 40690);
    assert(resolve(429, 1, 9999, 10000, 10000) == 23300);
    assert(resolve(429, 2, 9999, 8000, 10000) == 30290);
    assert(resolve(429, 2, 9999, 8000, 10000, true, false, true) == 30290);
    assert(resolve(429, 1, 9999, 10000, 10000, false) == 10000);
    assert(resolve(429, 0, 14323, 61589, 249825) == 61589);
    assert(resolve(429, 3, 14323, 61589, 249825) == 61589);
    assert(resolve(409, 1, 14323, 61589, 249825) == 61589);
    assert(resolve(0, 1, 14323, 61589, 249825) == 61589);
    assert(resolve(429, 1, 14323, 61589, 249825, true, true) == 61589);
    assert(resolve(429, 1, 9999, UINT32_MAX, UINT32_MAX) == UINT32_MAX);
}
