#include "../../../src/server/coa/CoACreatureScalingPolicy.h"
#include <cassert>
#include <cstdint>
#include <limits>

int main()
{
    using namespace CreatureScaling;
    assert(ContextOf(false, false, true, false, false) == Context::World);
    assert(ContextOf(false, false, true, false, true) == Context::Dungeon);
    assert(ContextOf(false, false, true, true, true) == Context::Raid);
    assert(ContextOf(false, false, false, false, true) == Context::None);
    assert(ContextOf(false, false, false, true, true) == Context::None);
    assert(ContextOf(true, false, true, false, false) == Context::None);
    assert(ContextOf(false, true, true, false, true) == Context::None);

    Settings const settings;
    assert(!settings.enabled);
    assert(Multiplier(settings.health, Context::World, 0) == 2.5f);
    assert(Multiplier(settings.health, Context::World, 1) == 2.5f);
    assert(Multiplier(settings.health, Context::Dungeon, 34) == 2.5f);
    assert(Multiplier(settings.health, Context::Dungeon, 36) == 2.2f);
    assert(Multiplier(settings.health, Context::Dungeon, 43) == 2.0f);
    assert(Multiplier(settings.health, Context::Dungeon, 389) == 3.0f);
    assert(Multiplier(settings.health, Context::Dungeon, 229) == 4.0f);
    assert(Multiplier(settings.health, Context::Raid, 409) == 2.2f);
    assert(Multiplier(settings.health, Context::Raid, 469) == 5.0f);
    assert(Multiplier(settings.health, Context::None, 469) == 1.0f);
    assert(Multiplier(settings.damage, Context::World, 0) == 2.0f);
    assert(Multiplier(settings.damage, Context::Dungeon, 36) == 1.5f);
    assert(Multiplier(settings.damage, Context::Raid, 469) == 1.0f);
    assert(Multiplier(settings.damage, Context::None, 36) == 1.0f);

    assert(Scaled(1000, 2.5f) == 2500);
    assert(Scaled(155, 2.2f) == 341);
    assert(Scaled(1, 0.1f) == 1);
    assert(Scaled(0, 2.0f) == 0);
    assert(Scaled(500, 0.0f) == 500);
    assert(Scaled(std::numeric_limits<std::uint32_t>::max() / 2, 5.0f) == std::numeric_limits<std::uint32_t>::max());

    auto const parsed = ParseMapMultipliers("36:2.2  43:2.0 bad 7: :3 12:x 13:-1 14:1.5z 229:4");
    assert(parsed.size() == 3);
    assert(parsed.at(36) == 2.2f && parsed.at(43) == 2.0f && parsed.at(229) == 4.0f);
    assert(ParseMapMultipliers("").empty());
    assert(ParseMapMultipliers(FormatMapMultipliers(settings.health.maps)) == settings.health.maps);
    assert(FormatMapMultipliers({}).empty());
}
