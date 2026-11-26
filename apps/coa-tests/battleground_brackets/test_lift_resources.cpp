#include "POLICY_HEADER"
#include <algorithm>
#include <array>
#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <memory>

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
    float bgOutputRatio = 1.0f;
    std::array<uint32, MAX_POWERS> powers{100, 30, 40, 50, 60, 0, 70};
    std::array<uint32, MAX_POWERS> maxima{100, 100, 100, 100, 100, 0, 100};
    std::array<float, 5> stats{};
    bool IsPet() const { return pet; }
    float GetBattlegroundOutputRatio() const { return bgOutputRatio; }
    void SetBattlegroundOutputRatio(float ratio) { bgOutputRatio = ratio; }
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
        else if (mod >= UNIT_MOD_STAT_START && mod < UNIT_MOD_HEALTH)
            stats[int(mod) - int(UNIT_MOD_STAT_START)] += apply ? amount : -amount;
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
    return {uint32(level) * 10, uint32(level) * 10, {0, 0, uint32(level) + 20, 0, 0}};
}

// ACTUAL_REFRESH

int main()
{
    Policy::Lift const large{200.0f};
    Policy::Lift const small{100.0f};
    for (bool pet : {false, true})
    {
        Unit unit;
        unit.pet = pet;
        unit.SetPower(POWER_MANA, 40);
        auto const powers = unit.powers;
        ApplyLift(&unit, large, 2.0f);
        CHECK(unit.maxHealth == 300 && unit.health == 300);
        CHECK(unit.CustomData.Get<AppliedLift>(LiftKey)->ratio == 2.0f);
        CHECK(unit.GetBattlegroundOutputRatio() == 2.0f);
        CHECK(unit.stats[STAT_STAMINA] == 0.0f);
        CHECK(unit.powers == powers && unit.maxima[POWER_MANA] == 100);
        RemoveLift(&unit);
        CHECK(unit.maxHealth == 100 && unit.health == 100);
        CHECK(unit.GetBattlegroundOutputRatio() == 1.0f);
        CHECK(!unit.CustomData.Get<AppliedLift>(LiftKey));

        unit.SetHealth(50);
        ApplyLift(&unit, large, 2.0f);
        CHECK(unit.health == 150);
        ApplyLift(&unit, small, 1.5f);
        CHECK(unit.maxHealth == 200 && unit.health == 100);
        CHECK(unit.CustomData.Get<AppliedLift>(LiftKey)->ratio == 1.5f);
        CHECK(unit.GetBattlegroundOutputRatio() == 1.5f);
        ApplyLift(&unit, large, 2.0f);
        CHECK(unit.health == 150);
        RemoveLift(&unit);
        CHECK(unit.health == 50 && unit.powers == powers);
        CHECK(unit.GetBattlegroundOutputRatio() == 1.0f);

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
        CHECK(unit.GetBattlegroundOutputRatio() == 1.0f);
        CHECK(!unit.CustomData.Get<AppliedLift>(LiftKey));
    }

    Unit pet;
    pet.pet = true;
    pet.maxHealth = 184;
    pet.SetHealth(184);
    Policy::LevelValues const impOwn{184, 0, {0, 0, 20, 0, 0}};
    Policy::LevelValues const impTop{591, 0, {0, 0, 39, 0, 0}};
    ApplyLift(&pet, Policy::LiftBetween(impOwn, impTop), Policy::OutputRatio(184.0f, 591.0f));
    CHECK(pet.maxHealth == 591 && pet.health == 591);
    CHECK(pet.stats[STAT_STAMINA] == 0.0f && pet.stats[STAT_STRENGTH] == 0.0f);
    CHECK(pet.GetBattlegroundOutputRatio() > 3.211f && pet.GetBattlegroundOutputRatio() < 3.212f);
    RemoveLift(&pet);
    CHECK(pet.maxHealth == 184 && pet.health == 184);
    CHECK(pet.stats[STAT_STAMINA] == 0.0f && pet.GetBattlegroundOutputRatio() == 1.0f);

    Player player;
    player.maxHealth = 260;
    player.SetHealth(260);
    RefreshPlayerLift(&player);
    CHECK(player.maxHealth == 600 && player.health == 600);
    CHECK(player.stats[STAT_STAMINA] == 0.0f);
    float const ratio = player.CustomData.Get<AppliedLift>(LiftKey)->ratio;
    CHECK(ratio > 2.307f && ratio < 2.308f);
    CHECK(player.GetBattlegroundOutputRatio() == ratio);
    player.SetHealth(300);
    player.level = 13;
    player.maxHealth += 20;
    RefreshPlayerLift(&player);
    CHECK(player.maxHealth == 600 && player.health == 290);
    CHECK(player.stats[STAT_STAMINA] == 0.0f);
    CHECK(player.GetBattlegroundOutputRatio() > 2.142f && player.GetBattlegroundOutputRatio() < 2.143f);
    RefreshPlayerLift(&player);
    CHECK(player.health == 290);
    player.level = 29;
    RefreshPlayerLift(&player);
    CHECK(player.maxHealth == 280 && player.health == 135);
    CHECK(player.stats[STAT_STAMINA] == 0.0f);
    CHECK(player.GetBattlegroundOutputRatio() == 1.0f);
    CHECK(!player.CustomData.Get<AppliedLift>(LiftKey));
}
