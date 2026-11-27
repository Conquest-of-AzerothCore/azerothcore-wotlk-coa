#include "POLICY_HEADER"
#include <algorithm>
#include <array>
#include <cmath>
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
enum UnitMods { UNIT_MOD_STAT_START, UNIT_MOD_HEALTH = 5, UNIT_MOD_MANA, UNIT_MOD_ARMOR };
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
    uint32 baseArmor = 10;
    uint32 armor = 10;
    float armorBasePct = 1.0f;
    float armorTotalPct = 1.0f;
    float bgOutputRatio = 1.0f;
    float bgArmorLift = 0.0f;
    uint32 minObservedHealth = 100;
    uint32 healthChanges = 0;
    std::array<uint32, MAX_POWERS> powers{100, 30, 40, 50, 60, 0, 70};
    std::array<uint32, MAX_POWERS> maxima{100, 100, 100, 100, 100, 0, 100};
    std::array<float, 5> stats{};
    bool IsPet() const { return pet; }
    float GetBattlegroundOutputRatio() const { return bgOutputRatio; }
    void SetBattlegroundOutputRatio(float ratio) { bgOutputRatio = ratio; }
    float GetBattlegroundArmorLift() const { return bgArmorLift; }
    void SetBattlegroundArmorLift(float value) { bgArmorLift = value; }
    void ResetObservedHealth()
    {
        minObservedHealth = health;
        healthChanges = 0;
    }
    uint32 GetHealth() const { return health; }
    uint32 GetMaxHealth() const { return maxHealth; }
    uint32 GetArmor() const { return armor; }
    uint32 GetArmorWithoutBattlegroundLift() const
    {
        if (bgArmorLift <= 0.0f)
            return armor;
        float const effectiveLift = bgArmorLift * armorBasePct * armorTotalPct;
        long const rounded = effectiveLift > 0.0f ? std::lround(effectiveLift) : 0L;
        uint32 const remove = rounded > 0L ? static_cast<uint32>(rounded) : 0u;
        return armor > remove ? armor - remove : 0u;
    }
    uint32 GetPower(Powers power) const { return powers[power]; }
    void SetHealth(uint32 value)
    {
        uint32 const next = std::min(value, maxHealth);
        if (next != health)
        {
            health = next;
            ++healthChanges;
        }
        minObservedHealth = std::min(minObservedHealth, health);
    }
    void SetPower(Powers power, uint32 value) { powers[power] = std::min(value, maxima[power]); }
    void HandleStatFlatModifier(UnitMods mod, int, float amount, bool apply)
    {
        int const delta = int(apply ? amount : -amount);
        if (mod == UNIT_MOD_HEALTH)
        {
            CHECK(armor == uint32(std::lround((float(baseArmor) + bgArmorLift) * armorBasePct * armorTotalPct)));
            uint32 const oldMax = maxHealth;
            maxHealth += delta;
            if (maxHealth < health)
                SetHealth(maxHealth);
            else if (oldMax != maxHealth)
                ++healthChanges;
        }
        else if (mod == UNIT_MOD_ARMOR)
        {
            int const updated = int(armor) + delta;
            armor = uint32(std::max(0, updated));
            CHECK(armor == uint32(std::max(0, int(baseArmor) + int(bgArmorLift))));
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
    Policy::ArmorTier tier = Policy::ArmorTier::Cloth;
    bool rebornArmor = true;
    Policy::GearValues gear{};
    uint8 GetLevel() const { return level; }
};
uint32 LiftTargetLevel(Player const*) { return 29; }
Policy::LevelValues PlayerLevelValues(Player const*, uint8 level)
{
    return {uint32(level) * 10, uint32(level) * 10, {0, 0, uint32(level) + 20, 0, 0}};
}
Policy::ArmorTier PlayerArmorTier(Player const* player, uint8) { return player->tier; }
bool PlayerUsesRebornArmor(Player const* player) { return player->rebornArmor; }
Policy::GearValues PlayerGearValues(Player const* player, bool removingOffhand = false)
{
    Policy::GearValues gear = player->gear;
    if (removingOffhand)
        gear.hasShield = false;
    return gear;
}

// ACTUAL_REFRESH

int main()
{
    Policy::Lift const large{200.0f, 50.0f};
    Policy::Lift const small{100.0f, 25.0f};
    for (bool pet : {false, true})
    {
        Unit unit;
        unit.pet = pet;
        unit.SetPower(POWER_MANA, 40);
        auto const powers = unit.powers;
        ApplyLift(&unit, large, 2.0f);
        CHECK(unit.maxHealth == 300 && unit.health == 300);
        CHECK(unit.armor == 60 && unit.GetBattlegroundArmorLift() == 50.0f);
        CHECK(unit.CustomData.Get<AppliedLift>(LiftKey)->ratio == 2.0f);
        CHECK(unit.GetBattlegroundOutputRatio() == 2.0f);
        CHECK(unit.stats[STAT_STAMINA] == 0.0f);
        CHECK(unit.powers == powers && unit.maxima[POWER_MANA] == 100);
        RemoveLift(&unit);
        CHECK(unit.maxHealth == 100 && unit.health == 100);
        CHECK(unit.armor == 10 && unit.GetBattlegroundArmorLift() == 0.0f);
        CHECK(unit.GetBattlegroundOutputRatio() == 1.0f);
        CHECK(!unit.CustomData.Get<AppliedLift>(LiftKey));

        unit.SetHealth(50);
        ApplyLift(&unit, large, 2.0f);
        CHECK(unit.health == 150);
        ApplyLift(&unit, small, 1.5f);
        CHECK(unit.maxHealth == 200 && unit.health == 100 && unit.armor == 35);
        CHECK(unit.CustomData.Get<AppliedLift>(LiftKey)->ratio == 1.5f);
        CHECK(unit.GetBattlegroundOutputRatio() == 1.5f);
        ApplyLift(&unit, large, 2.0f, false);
        CHECK(unit.maxHealth == 300 && unit.health == 100 && unit.armor == 60);
        ApplyLift(&unit, large, 2.0f);
        CHECK(unit.health == 100);
        RemoveLift(&unit);
        CHECK(unit.health == 33 && unit.powers == powers && unit.armor == 10);
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
    player.armor = 10;
    player.SetHealth(260);
    RefreshPlayerLift(&player);
    uint32 const clothGapTwelve = uint32(std::lround(Policy::GearArmorBudget(Policy::ArmorTier::Cloth, 29, true) -
        Policy::GearArmorBudget(Policy::ArmorTier::Cloth, 12, true)));
    CHECK(player.maxHealth == 600 + 207 && player.health == 600 + 207);
    CHECK(player.armor == 10 + clothGapTwelve && player.GetBattlegroundArmorLift() == float(clothGapTwelve));
    CHECK(player.stats[STAT_STAMINA] == 0.0f);
    CHECK(player.CustomData.Get<AppliedLift>(LiftKey)->targetLevel == 29u);
    float const ratio = player.CustomData.Get<AppliedLift>(LiftKey)->ratio;
    CHECK(ratio > 2.307f && ratio < 2.308f);
    CHECK(player.GetBattlegroundOutputRatio() == ratio);
    player.SetHealth(400);
    player.gear.health = 250.0f;
    player.maxHealth += 250;
    RefreshPlayerLift(&player, false);
    CHECK(player.maxHealth == 600 + 250 + (365 - 250) && player.health == 400);
    CHECK(player.GetBattlegroundOutputRatio() == ratio);
    player.gear.health = 0.0f;
    player.maxHealth -= 250;
    RefreshPlayerLift(&player, false);
    CHECK(player.maxHealth == 600 + 207 && player.health == 400);
    player.SetHealth(player.maxHealth);
    player.gear.health = 1000.0f;
    player.maxHealth += 1000;
    RefreshPlayerLift(&player, false);
    CHECK(player.maxHealth == 600 + 1000 && player.health == 600 + 207);
    player.gear.health = 0.0f;
    player.maxHealth -= 1000;
    RefreshPlayerLift(&player, false);
    CHECK(player.maxHealth == 600 + 207 && player.health == 600 + 207);
    player.SetHealth(400);
    player.level = 13;
    player.maxHealth += 20;
    RefreshPlayerLift(&player);
    CHECK(player.maxHealth == 600 + 198 && player.health == uint32(std::lround(400.0 * 798.0 / 827.0)));
    CHECK(player.stats[STAT_STAMINA] == 0.0f);
    CHECK(player.GetBattlegroundOutputRatio() > 2.142f && player.GetBattlegroundOutputRatio() < 2.143f);
    CHECK(player.CustomData.Get<AppliedLift>(LiftKey)->targetLevel == 29u);
    RefreshPlayerLift(&player);
    CHECK(player.health == uint32(std::lround(400.0 * 798.0 / 827.0)));
    player.level = 29;
    RefreshPlayerLift(&player);
    CHECK(player.maxHealth == 280 && player.health == 135 && player.armor == 10);
    CHECK(player.GetBattlegroundArmorLift() == 0.0f);
    CHECK(player.stats[STAT_STAMINA] == 0.0f);
    CHECK(player.GetBattlegroundOutputRatio() == 1.0f);
    CHECK(!player.CustomData.Get<AppliedLift>(LiftKey));

    Player swapper;
    swapper.maxHealth = 260;
    swapper.baseArmor = 10;
    swapper.armor = 10;
    swapper.SetHealth(260);
    RefreshPlayerLift(&swapper);
    CHECK(swapper.maxHealth == 600 + 207);
    swapper.SetHealth(700);
    swapper.ResetObservedHealth();
    RefreshPlayerLift(&swapper, false);
    CHECK(swapper.health == 700 && swapper.minObservedHealth == 700 && swapper.healthChanges == 0);
    swapper.gear.health = 250.0f;
    swapper.maxHealth += 250;
    swapper.ResetObservedHealth();
    RefreshPlayerLift(&swapper, false);
    CHECK(swapper.maxHealth == 600 + 365 && swapper.health == 700 && swapper.minObservedHealth == 700);

    swapper.gear.hasShield = true;
    swapper.gear.shieldArmor = 100.0f;
    RefreshPlayerLift(&swapper, false);
    uint32 const shieldGapTwelve = uint32(std::lround(Policy::GearShieldArmorBudget(29, true) -
        Policy::GearShieldArmorBudget(12, true)));
    CHECK(swapper.GetBattlegroundArmorLift() == float(clothGapTwelve + shieldGapTwelve));
    CHECK(swapper.armor == 10 + clothGapTwelve + shieldGapTwelve);
    swapper.gear.shieldArmor = 400.0f;
    RefreshPlayerLift(&swapper, false);
    uint32 const shrunkShield = uint32(std::lround(Policy::GearShieldArmorBudget(29, true) - 400.0f));
    CHECK(swapper.GetBattlegroundArmorLift() == float(clothGapTwelve + shrunkShield));
    swapper.gear.shieldArmor = 0.0f;
    RefreshPlayerLift(&swapper, false, true);
    CHECK(swapper.GetBattlegroundArmorLift() == float(clothGapTwelve));
    CHECK(swapper.armor == 10 + clothGapTwelve);

    Unit pctUnit;
    pctUnit.baseArmor = 492;
    pctUnit.armorBasePct = 1.25f;
    pctUnit.armorTotalPct = 1.20f;
    pctUnit.armor = 1967;
    pctUnit.SetBattlegroundArmorLift(819.0f);
    CHECK(pctUnit.GetArmorWithoutBattlegroundLift() == 738u);
    pctUnit.armor = 500;
    CHECK(pctUnit.GetArmorWithoutBattlegroundLift() == 0u);
}
