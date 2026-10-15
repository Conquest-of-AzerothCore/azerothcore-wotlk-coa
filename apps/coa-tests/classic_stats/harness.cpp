#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <initializer_list>
#include <optional>
#include <type_traits>
using uint8 = std::uint8_t;
using uint32 = std::uint32_t;
using int32 = std::int32_t;
// ENUMS
#define GT_MAX_LEVEL 100
// SOURCE
enum WorldBoolConfigs { CONFIG_LOW_LEVEL_REGEN_BOOST, CONFIG_CLASSIC_PLUS_STAT_FORMULAS };
enum Rates { RATE_HEALTH };
struct World
{
    bool classic = false;
    bool getBoolConfig(WorldBoolConfigs config) const { return config == CONFIG_CLASSIC_PLUS_STAT_FORMULAS && classic; }
    float getRate(Rates) const { return 1.0f; }
};
World world;
World* sWorld = &world;
struct Player;
struct ScriptMgr
{
    bool OnPlayerCanRegenerate(Player*, uint32) const { return true; }
};
ScriptMgr scripts;
ScriptMgr* sScriptMgr = &scripts;
enum AuraType
{
    SPELL_AURA_PREVENT_REGENERATE_POWER, SPELL_AURA_MOD_HEALTH_REGEN_PERCENT, SPELL_AURA_MOD_REGEN,
    SPELL_AURA_MOD_REGEN_DURING_COMBAT, SPELL_AURA_MOD_HEALTH_REGEN_IN_COMBAT
};
constexpr int IN_MILLISECONDS = 1000;
template<class T> void ApplyPct(T& value, int32 pct) { value = value * pct / 100.0f; }
enum UnitMods { UNIT_MOD_STAT_START = 0 };
enum UnitModifierPctType { BASE_PCT };
template<class E> constexpr auto AsUnderlyingType(E value) { return static_cast<std::underlying_type_t<E>>(value); }
struct GtBaseEntry { float base; };
struct GtRatioEntry { float ratio; };
using GtChanceToMeleeCritBaseEntry = GtBaseEntry;
using GtChanceToSpellCritBaseEntry = GtBaseEntry;
using GtChanceToMeleeCritEntry = GtRatioEntry;
using GtChanceToSpellCritEntry = GtRatioEntry;
using GtOCTRegenHPEntry = GtRatioEntry;
using GtRegenHPPerSptEntry = GtRatioEntry;
template<class Entry, std::size_t Size>
struct Store
{
    std::array<Entry, Size> rows;
    Entry const* LookupEntry(uint32 index) const { return index < Size ? &rows[index] : nullptr; }
};
// NATIVE_DBC
struct Player
{
    uint8 playerLevel = 60;
    uint32 playerClass = CLASS_WARRIOR;
    std::array<float, 5> stats{};
    float createAgility = 0.0f;
    bool polymorphed = false;
    bool standing = true;
    uint32 maxHealth = 100000;
    float m_baseHealthRegen = 0.0f;
    int32 healed = 0;
    uint8 GetLevel() const { return playerLevel; }
    uint32 getClass() const { return playerClass; }
    float GetStat(Stats stat) const { return stats[stat]; }
    float GetCreateStat(Stats) const { return createAgility; }
    float GetPctModifierValue(UnitMods, UnitModifierPctType) const { return 1.0f; }
    bool HasAuraTypeWithMiscvalue(AuraType, uint32) const { return false; }
    uint32 GetHealth() const { return 1; }
    uint32 GetMaxHealth() const { return maxHealth; }
    bool IsPolymorphed() const { return polymorphed; }
    bool IsInCombat() const { return false; }
    bool HasRegenDuringCombatAura() const { return false; }
    bool IsStandState() const { return standing; }
    float GetTotalAuraMultiplier(AuraType) const { return 1.0f; }
    int32 GetTotalAuraModifier(AuraType) const { return 0; }
    void ModifyHealth(int32 value) { healed = value; }
    float GetMeleeCritFromAgility();
    void GetDodgeFromAgility(float& diminishing, float& nondiminishing);
    float GetSpellCritFromIntellect();
    float OCTRegenHPPerSpirit();
    void RegenerateHealth();
    float ShamanBranchAttackPower();
};
// NATIVE
Player MakePlayer(uint32 playerClass, uint8 level, float strength, float agility, float intellect, float spirit,
    float createAgility)
{
    Player player;
    player.playerClass = playerClass;
    player.playerLevel = level;
    player.stats = { strength, agility, 0.0f, intellect, spirit };
    player.createAgility = createAgility;
    return player;
}
void Measure(char const* name, Player player, bool polymorphed, bool standing)
{
    for (bool classic : { false, true })
    {
        world.classic = classic;
        Player measured = player;
        float diminishing = 0.0f;
        float nondiminishing = 0.0f;
        measured.GetDodgeFromAgility(diminishing, nondiminishing);
        measured.polymorphed = polymorphed;
        measured.standing = standing;
        measured.RegenerateHealth();
        std::printf("%s %d %.9g %.9g %.9g %.9g %.9g %.9g %d\n", name, classic ? 1 : 0,
            double(measured.GetMeleeCritFromAgility()), double(diminishing), double(nondiminishing),
            double(measured.GetSpellCritFromIntellect()), double(measured.OCTRegenHPPerSpirit()),
            double(measured.ShamanBranchAttackPower()), measured.healed);
    }
}
int main()
{
    // DBC_CASES
    return 0;
}
