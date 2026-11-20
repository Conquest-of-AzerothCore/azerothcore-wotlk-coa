#include "POLICY_HEADER"
#include <algorithm>
#include <array>
#include <cassert>
#include <cstdint>
#include <memory>

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
        ApplyLift(&unit, large);
        assert(unit.health == 100);
        unit.SetHealth(250);
        unit.SetPower(POWER_MANA, 240);
        auto const powers = unit.powers;
        ApplyLift(&unit, large);
        assert(unit.health == 250 && unit.powers == powers);
        ApplyLift(&unit, small);
        assert(unit.health == 200 && unit.maxima[POWER_MANA] == 100);
        ApplyLift(&unit, large);
        assert(unit.health == 200);
        unit.SetHealth(0);
        ApplyLift(&unit, large);
        assert(unit.health == 0);
        unit.SetHealth(250);
        RemoveLift(&unit);
        assert(unit.health == 100);
        assert(!unit.CustomData.Get<AppliedLift>(LiftKey));
        ApplyLift(&unit, large);
        unit.SetHealth(250);
        ApplyLift(&unit, {});
        assert(unit.health == 100);
    }

    Unit pet;
    pet.pet = true;
    ApplyLift(&pet, {0, 5});
    assert(pet.stats[STAT_STAMINA] == 5.0f && pet.stats[STAT_STRENGTH] == 0.0f);
    RemoveLift(&pet);
    assert(pet.stats[STAT_STAMINA] == 0.0f);

    Player player;
    player.maxHealth = 120;
    RefreshPlayerLift(&player);
    player.level = 13;
    player.maxHealth += 10;
    player.SetHealth(player.maxHealth);
    RefreshPlayerLift(&player);
    assert(player.maxHealth == 290 && player.health == 290);
    RefreshPlayerLift(&player);
    assert(player.health == 290);
    player.level = 29;
    RefreshPlayerLift(&player);
    assert(player.health == 130);
}
