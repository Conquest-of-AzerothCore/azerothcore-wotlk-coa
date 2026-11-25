#include "POLICY_HEADER"
#include <algorithm>
#include <array>
#include <cstdint>
#include <memory>
#include <cstdlib>
#include <iostream>

#define CHECK(condition) \
    do \
    { \
        if (!(condition)) \
        { \
            std::cerr << __FILE__ << ':' << __LINE__ << ": " << #condition << '\n'; \
            std::exit(1); \
        } \
    } while (false)

using uint8 = std::uint8_t;
using uint32 = std::uint32_t;
namespace Policy = AscensionBattlegroundBracketsPolicy;
enum Stats { STAT_STRENGTH, STAT_AGILITY, STAT_STAMINA, STAT_INTELLECT, STAT_SPIRIT };
enum UnitMods { UNIT_MOD_STAT_START, UNIT_MOD_HEALTH = 5, UNIT_MOD_MANA };
enum Powers { POWER_MANA, POWER_RAGE, POWER_FOCUS, POWER_ENERGY, POWER_HAPPINESS, POWER_RUNE,
    POWER_RUNIC_POWER, MAX_POWERS };
constexpr int BASE_VALUE = 0;

struct DataMap
{
    struct Base { virtual ~Base() = default; };
    std::unique_ptr<Base> value;
    template<class T> T* Get(char const*) { return static_cast<T*>(value.get()); }
    void Erase(char const*) { value.reset(); }
    void Set(char const*, Base* applied) { value.reset(applied); }
};

struct Unit
{
    DataMap CustomData;
    bool pet = false;
    uint32 health = 100;
    uint32 maxHealth = 100;
    std::array<uint32, MAX_POWERS> powers{100, 30, 40, 50, 60, 0, 70};
    std::array<uint32, MAX_POWERS> maxima{100, 100, 100, 100, 100, 0, 100};
    std::array<float, 5> stats{};
    bool IsPet() const { return pet; }
    float GetCreateStat(Stats stat) const { return stats[stat]; }
    void SetCreateStat(Stats stat, float value) { stats[stat] = value; }
    void UpdateStats(Stats) { }
    uint32 GetHealth() const { return health; }
    uint32 GetMaxHealth() const { return maxHealth; }
    uint32 GetPower(Powers power) const { return powers[power]; }
    void SetHealth(uint32 value) { health = std::min(value, maxHealth); }
    void SetPower(Powers power, uint32 value) { powers[power] = std::min(value, maxima[power]); }
    void HandleStatFlatModifier(UnitMods mod, int, float amount, bool apply)
    {
        int const delta = int(apply ? amount : -amount);
        if (mod == UNIT_MOD_HEALTH)
        {
            maxHealth += delta;
            SetHealth(health);
        }
        else if (mod == UNIT_MOD_MANA)
        {
            maxima[POWER_MANA] += delta;
            SetPower(POWER_MANA, powers[POWER_MANA]);
        }
    }
};

// ACTUAL_LIFT

struct Player : Unit
{
    uint8 level = 12;
    uint8 GetLevel() const { return level; }
};
uint32 LiftTargetLevel(Player const*) { return 29; }
Policy::LevelValues PlayerLevelValues(Player const*, uint8 level)
{
    return {uint32(level) * 10, uint32(level) * 10, {}};
}

// ACTUAL_REFRESH

int main()
{
    Policy::Lift const large{200, 0};
    Policy::Lift const small{100, 0};
    for (bool pet : {false, true})
    {
        Unit unit;
        unit.pet = pet;
        unit.SetPower(POWER_MANA, 40);
        auto const powers = unit.powers;
        ApplyLift(&unit, large, 2.0f);
        CHECK(unit.maxHealth == 300 && unit.health == 300);
        CHECK(unit.CustomData.Get<AppliedLift>(LiftKey)->ratio == 2.0f);
        CHECK(unit.powers == powers && unit.maxima[POWER_MANA] == 100);
        RemoveLift(&unit);
        CHECK(unit.maxHealth == 100 && unit.health == 100);
        CHECK(!unit.CustomData.Get<AppliedLift>(LiftKey));

        unit.SetHealth(50);
        ApplyLift(&unit, large, 2.0f);
        CHECK(unit.health == 150);
        ApplyLift(&unit, small, 1.5f);
        CHECK(unit.maxHealth == 200 && unit.health == 100);
        CHECK(unit.CustomData.Get<AppliedLift>(LiftKey)->ratio == 1.5f);
        ApplyLift(&unit, large, 2.0f);
        CHECK(unit.health == 150);
        RemoveLift(&unit);
        CHECK(unit.health == 50 && unit.powers == powers);

        unit.SetHealth(0);
        ApplyLift(&unit, large, 2.0f);
        CHECK(unit.health == 0);
        RemoveLift(&unit);
        CHECK(unit.health == 0);

        unit.SetHealth(1);
        ApplyLift(&unit, large, 2.0f);
        CHECK(unit.health == 3);
        unit.SetHealth(1);
        RemoveLift(&unit);
        CHECK(unit.health == 1);

        unit.SetHealth(100);
        ApplyLift(&unit, large, 2.0f);
        ApplyLift(&unit, {}, 1.0f);
        CHECK(unit.maxHealth == 100 && unit.health == 100);
        CHECK(!unit.CustomData.Get<AppliedLift>(LiftKey));
    }

    Unit pet;
    pet.pet = true;
    ApplyLift(&pet, {0, 5}, 1.0f);
    CHECK(pet.stats[STAT_STAMINA] == 5.0f && pet.stats[STAT_STRENGTH] == 0.0f);
    RemoveLift(&pet);
    CHECK(pet.stats[STAT_STAMINA] == 0.0f);

    Player player;
    player.maxHealth = 120;
    player.SetHealth(120);
    RefreshPlayerLift(&player);
    CHECK(player.maxHealth == 290 && player.health == 290);
    float const ratio = player.CustomData.Get<AppliedLift>(LiftKey)->ratio;
    CHECK(ratio > 2.416f && ratio < 2.417f);
    player.SetHealth(145);
    player.level = 13;
    player.maxHealth += 10;
    RefreshPlayerLift(&player);
    CHECK(player.maxHealth == 290 && player.health == 140);
    RefreshPlayerLift(&player);
    CHECK(player.health == 140);
    player.level = 29;
    RefreshPlayerLift(&player);
    CHECK(player.maxHealth == 130 && player.health == 63);
    CHECK(!player.CustomData.Get<AppliedLift>(LiftKey));
}
