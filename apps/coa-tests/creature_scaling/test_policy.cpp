#include "../../../src/server/coa/CoACreatureScalingPolicy.h"
#include <cassert>
#include <cmath>
#include <cstdint>
#include <limits>

namespace
{
bool Near(float a, float b)
{
    return std::fabs(a - b) < 1e-4f;
}

float Eval(char const* text, std::uint8_t level)
{
    auto const formula = CreatureScaling::Formula::Parse(text);
    assert(formula);
    return formula->Evaluate(level);
}
}

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
    assert(Near(Multiplier(settings.health, Context::World, 0, 1), 1.183f));
    assert(Near(Multiplier(settings.health, Context::World, 1, 40), 1.69f));
    assert(Near(Multiplier(settings.health, Context::World, 530, 60), 1.95f));
    assert(Multiplier(settings.health, Context::Dungeon, 34, 25) == 2.5f);
    assert(Multiplier(settings.health, Context::Dungeon, 429, 59) == 2.5f);
    assert(Multiplier(settings.health, Context::Dungeon, 36, 20) == 2.2f);
    assert(Multiplier(settings.health, Context::Dungeon, 43, 20) == 2.0f);
    assert(Multiplier(settings.health, Context::Dungeon, 389, 16) == 3.0f);
    assert(Multiplier(settings.health, Context::Dungeon, 229, 58) == 4.0f);
    assert(Multiplier(settings.health, Context::Raid, 409, 60) == 2.2f);
    assert(Multiplier(settings.health, Context::Raid, 469, 60) == 5.0f);
    assert(Multiplier(settings.health, Context::None, 469, 60) == 1.0f);
    assert(Near(Multiplier(settings.damage, Context::World, 0, 1), 2.173f));
    assert(Near(Multiplier(settings.damage, Context::World, 1, 60), 2.94f));
    assert(Multiplier(settings.damage, Context::Dungeon, 36, 20) == 1.5f);
    assert(Multiplier(settings.damage, Context::Raid, 469, 60) == 1.0f);
    assert(Multiplier(settings.damage, Context::None, 36, 20) == 1.0f);
    assert(settings.health.maps.size() == 5 && settings.damage.maps.empty());
    assert(Formula::Of("level +").Text() == "1" && Near(Formula::Of("level +").Evaluate(30), 1.0f));

    assert(Scaled(1000, 2.5f) == 2500);
    assert(Scaled(155, 2.2f) == 341);
    assert(Scaled(1, 0.1f) == 1);
    assert(Scaled(0, 2.0f) == 0);
    assert(Scaled(500, 0.0f) == 500);
    assert(Scaled(std::numeric_limits<std::uint32_t>::max() / 2, 5.0f) == std::numeric_limits<std::uint32_t>::max());

    assert(Near(Eval("2.5", 1), 2.5f) && Near(Eval("2.5", 60), 2.5f));
    assert(Near(Eval("1.17 + 0.013 * level", 1), 1.183f));
    assert(Near(Eval("1.17 + 0.013 * level", 60), 1.95f));
    assert(Near(Eval("1.17+0.013*level", 40), 1.69f));
    assert(Near(Eval("(level + 10) / 20", 30), 2.0f));
    assert(Near(Eval("2 * level - 3 * 4", 10), 8.0f));
    assert(Near(Eval("-1 + 3", 0), 2.0f));
    assert(Near(Eval("max(1.2, min(3.5, 0.3 + 0.08 * level))", 5), 1.2f));
    assert(Near(Eval("max(1.2, min(3.5, 0.3 + 0.08 * level))", 25), 2.3f));
    assert(Near(Eval("max(1.2, min(3.5, 0.3 + 0.08 * level))", 60), 3.5f));
    assert(Eval("1 / 0", 5) == 0.0f);
    assert(Eval("1 - 2", 5) == 0.0f);
    assert(Scaled(500, Eval("1 - 2", 5)) == 500);
    for (char const* bad : { "", "level +", "2..5", "lvl", "levels", "min(1)", "max(1, 2", "(1 + 2", "1 2", "2x", "*3" })
        assert(!Formula::Parse(bad));
    assert(Formula::Parse(" 1.17 + 0.013 * level ")->Text() == "1.17+0.013*level");
    assert(!Formula::Parse("2.5")->UsesLevel() && Formula::Parse("0.5 * level")->UsesLevel());

    Multipliers curved{ *Formula::Parse("1.17 + 0.013 * level"), 2.5f, 2.2f, { { 43, *Formula::Parse("0.3+0.08*level") } } };
    assert(Near(Multiplier(curved, Context::World, 1, 40), 1.69f));
    assert(Near(Multiplier(curved, Context::Dungeon, 43, 20), 1.9f));
    assert(Multiplier(curved, Context::Dungeon, 34, 20) == 2.5f);
    assert(Multiplier(curved, Context::None, 43, 20) == 1.0f);

    auto const parsed = ParseMapMultipliers("36:2.2  43:2.0 bad 7: :3 12:x 13:-1 14:1.5z 229:4");
    assert(ParseMapMultipliers(FormatMapMultipliers(settings.health.maps)) == settings.health.maps);
    assert(parsed.size() == 3);
    assert(Near(parsed.at(36).Evaluate(1), 2.2f) && Near(parsed.at(43).Evaluate(1), 2.0f));
    assert(Near(parsed.at(229).Evaluate(1), 4.0f));
    assert(ParseMapMultipliers("").empty());
    assert(ParseMapMultipliers(FormatMapMultipliers(settings.health.maps)) == settings.health.maps);
    assert(FormatMapMultipliers({}).empty());

    auto const formulas = ParseMapMultipliers("43:0.3+0.08*level 189:max(2.5,0.09*level)");
    assert(formulas.size() == 2 && Near(formulas.at(43).Evaluate(20), 1.9f) && Near(formulas.at(189).Evaluate(36), 3.24f));
    auto const separated = ParseMapMultipliers("43: 0.3 + 0.08 * level; 36: 2.2 ;bad; 7:");
    assert(separated.size() == 2 && Near(separated.at(43).Evaluate(25), 2.3f) && Near(separated.at(36).Evaluate(1), 2.2f));
    assert(ParseMapMultipliers(FormatMapMultipliers(separated)) == separated);

    assert(Near(Multiplier(settings.damageSpread, Context::World, 0, 1), 1.8f));
    assert(Near(Multiplier(settings.damageSpread, Context::World, 0, 5), 1.6f));
    assert(Near(Multiplier(settings.damageSpread, Context::World, 0, 60), 1.55f));
    assert(Multiplier(settings.damageSpread, Context::Dungeon, 36, 20) == 0.0f);
    assert(Multiplier(settings.damageSpread, Context::Raid, 409, 63) == 0.0f);
    assert(SpellMultiplier(settings, Context::World, 0, 60, false) == 1.0f);
    assert(Near(SpellMultiplier(settings, Context::World, 0, 60, true), 2.94f));
    assert(SpellMultiplier(settings, Context::Dungeon, 36, 20, false) == 1.5f);
    assert(SpellMultiplier(settings, Context::Raid, 409, 63, false) == 1.0f);
    assert(SpellMultiplier(settings, Context::None, 0, 60, false) == 1.0f);
    Settings mapped;
    mapped.spellDamage.maps = ParseMapMultipliers("36:0.8");
    assert(Near(SpellMultiplier(mapped, Context::Dungeon, 36, 20, false), 0.8f));
    assert(SpellMultiplier(mapped, Context::Dungeon, 36, 20, true) == 1.5f);
    assert(SpellMultiplier(mapped, Context::None, 36, 20, false) == 1.0f);
    float low = 1.55f;
    float high = 1.68f;
    ScaleRange(low, high, 4.0f, 1.55f);
    assert(Near((low + high) / 2.0f, 6.46f) && Near(high / low, 1.55f));
    low = 2.0f;
    high = 3.0f;
    ScaleRange(low, high, 2.0f, 0.0f);
    assert(Near(low, 4.0f) && Near(high, 6.0f));
    low = 2.0f;
    high = 3.0f;
    ScaleRange(low, high, 0.0f, 1.0f);
    assert(Near(low, 2.0f) && Near(high, 3.0f));
}
