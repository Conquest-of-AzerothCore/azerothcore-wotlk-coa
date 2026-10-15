#define _USE_MATH_DEFINES
#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <functional>
#include <map>

using int32 = std::int32_t;
using uint8 = std::uint8_t;
using uint16 = std::uint16_t;
using uint32 = std::uint32_t;

#define LOG_DEBUG(...) ((void)0)

// NATIVE_ENUMS

// SOURCE

enum AuraType
{
    SPELL_AURA_MOD_EXPERTISE,
    SPELL_AURA_MOD_COMBAT_RESULT_CHANCE,
    SPELL_AURA_MOD_ENEMY_DODGE,
    SPELL_AURA_MOD_TARGET_RESISTANCE,
    SPELL_AURA_MOD_DODGE_PERCENT,
    SPELL_AURA_MOD_PARRY_PERCENT
};
enum VictimState
{
    VICTIMSTATE_HIT = 1,
    VICTIMSTATE_DODGE = 2
};
enum ServerConfigs
{
    CONFIG_CLASSIC_PLUS_COMBAT_RULES
};
enum SpellSchoolMask : uint32
{
    SPELL_SCHOOL_MASK_FIRE = 4
};
enum SpellModOp
{
    SPELLMOD_RESIST_MISS_CHANCE = 12
};
enum CurrentSpellTypes
{
    CURRENT_MELEE_SPELL = 0
};
constexpr uint32 HITINFO_GLANCING = 0x4000;
constexpr uint8 MAX_ITEM_PROTO_DAMAGES = 2;
constexpr uint32 UNIT_STATE_CONTROLLED = 1;
constexpr uint32 WORLD_TRIGGER = 12999;
constexpr uint32 CREATURE_FLAG_EXTRA_NO_PARRY = 0x1;
constexpr uint32 CREATURE_FLAG_EXTRA_NO_BLOCK = 0x2;
constexpr uint32 CREATURE_FLAG_EXTRA_NO_CRUSHING_BLOWS = 0x4;
constexpr uint32 CREATURE_FLAG_EXTRA_NO_DODGE = 0x8;
constexpr uint32 CREATURE_FLAG_EXTRA_NO_CRIT = 0x10;
constexpr int SPELL_ATTR0_CU_BINARY_SPELL = 1;
constexpr int SPELL_ATTR7_NO_ATTACK_MISS = 2;

struct World
{
    bool classicPlus = true;
    bool getBoolConfig(ServerConfigs) const { return classicPlus; }
};
World world;
World* sWorld = &world;

int32 nextRoll = 0;
bool chanceRoll = false;
int32 urand(int32, int32) { return nextRoll; }
bool roll_chance_i(int32) { return chanceRoll; }
float frand(float low, float high)
{
    if (low > high)
        std::abort();
    return (low + high) / 2.0f;
}

struct SpellInfo
{
    uint32 Id = 0;
    bool binary = false;
    bool HasAttribute(int attribute) const { return attribute == SPELL_ATTR0_CU_BINARY_SPELL && binary; }
};
struct SpellMgr
{
    SpellInfo const* GetSpellInfo(uint32) const { return nullptr; }
};
SpellMgr spellMgr;
SpellMgr* sSpellMgr = &spellMgr;
struct Spell
{
    bool IsNextMeleeSwingSpell() const { return false; }
};

struct Unit;
using Creature = Unit;
using Player = Unit;

struct ScriptMgr
{
    std::function<void(int32&, int32&, int32&)> hook;
    void OnBeforeRollMeleeOutcomeAgainst(Unit const*, Unit const*, WeaponAttackType, int32&, int32&, int32&, int32&,
        int32& crit, int32&, int32& dodge, int32& parry, int32&)
    {
        if (hook)
            hook(crit, dodge, parry);
    }
};
ScriptMgr scripts;
ScriptMgr* sScriptMgr = &scripts;

struct DamageEntry
{
    uint32 damage = 0;
};
struct CalcDamageInfo
{
    uint32 HitInfo = 0;
    uint32 TargetState = 0;
    uint32 cleanDamage = 0;
    std::array<DamageEntry, MAX_ITEM_PROTO_DAMAGES> damages{};
};

struct Unit
{
    bool player = false;
    bool pet = false;
    bool totem = false;
    bool worldBoss = false;
    bool front = true;
    bool dualWield = false;
    bool forgemaster = false;
    bool controlled = false;
    uint8 level = 60;
    uint8 cls = CLASS_WARRIOR;
    int32 weaponSkill = 300;
    int32 defense = 300;
    uint32 flagsExtra = 0;
    int32 resistance = 0;
    int32 penetration = 0;
    int32 avoidanceAura = 0;
    float m_modMeleeHitChance = 0.0f;
    float m_modRangedHitChance = 0.0f;
    std::array<Spell*, 1> m_currentSpells{};

    bool IsPlayer() const { return player; }
    bool IsCreature() const { return !player; }
    bool IsPet() const { return pet; }
    bool IsTotem() const { return totem; }
    bool IsControlledByPlayer() const { return player || pet || controlled; }
    Creature const* ToCreature() const { return player ? nullptr : this; }
    Player const* ToPlayer() const { return player ? this : nullptr; }
    Player* GetSpellModOwner() const { return player ? const_cast<Unit*>(this) : nullptr; }
    bool IsEvadingAttacks() const { return false; }
    bool HasFlagsExtra(uint32 flag) const { return (flagsExtra & flag) != 0; }
    uint32 GetEntry() const { return 1; }
    uint8 GetLevel() const { return level; }
    uint8 getLevelForTarget(Unit const* target) const { return worldBoss && target ? uint8(target->level + 3) : level; }
    uint8 getClass() const { return cls; }
    uint16 GetMaxSkillValueForLevel(Unit const* target = nullptr) const
    {
        return uint16((target ? getLevelForTarget(target) : level) * 5);
    }
    uint32 GetWeaponSkillValue(WeaponAttackType, Unit const* target) const
    {
        return player ? uint32(weaponSkill) : GetMaxSkillValueForLevel(target);
    }
    uint32 GetDefenseSkillValue(Unit const* target = nullptr) const
    {
        return player ? uint32(defense) : GetMaxSkillValueForLevel(target);
    }
    bool HasInArc(double, Unit const*) const { return front; }
    bool HasIgnoreHitDirectionAura() const { return false; }
    bool IsNonMeleeSpellCast(bool, bool, bool) const { return false; }
    bool CanDefendDuringChannel() const { return false; }
    bool HasUnitState(uint32) const { return false; }
    bool HasOffhandWeaponForAttack() const { return dualWield; }
    float GetExpertiseDodgeOrParryReduction(WeaponAttackType) const { return 0.0f; }
    float GetUnitMissChance(WeaponAttackType) const { return 5.0f; }
    int32 GetTotalAuraModifier(AuraType aura) const
    {
        return aura == SPELL_AURA_MOD_DODGE_PERCENT || aura == SPELL_AURA_MOD_PARRY_PERCENT ? avoidanceAura : 0;
    }
    int32 GetTotalAuraModifierByMiscValue(AuraType, int32) const { return 0; }
    int32 GetTotalAuraModifierByMiscMask(AuraType, uint32) const { return penetration; }
    float GetTotalAuraMultiplier(AuraType) const { return 1.0f; }
    int32 GetResistance(SpellSchoolMask) const { return resistance; }
    int32 GetSpellPenetrationItemMod() const { return 0; }
    template<class T> void ApplySpellMod(uint32, SpellModOp, T&) const { }
    bool HasAura(uint32 id) const { return forgemaster && id == 560655; }
    bool CanBlock() const { return forgemaster; }
    bool GetShield(bool) const { return forgemaster; }

    MeleeHitOutcome RollMeleeOutcomeAgainst(Unit const* victim, WeaponAttackType attType, int32 crit_chance,
        int32 miss_chance, int32 dodge_chance, int32 parry_chance, int32 block_chance) const;
    float MeleeSpellMissChance(Unit const* victim, WeaponAttackType attType, int32 skillDiff, uint32 spellId) const;
    static float GetEffectiveResistChance(Unit const* owner, SpellSchoolMask schoolMask, Unit const* victim,
        SpellInfo const* spellInfo = nullptr);
    float GlancingMultiplier(Unit* victim, WeaponAttackType attackType) const;
};

// METHODS

float Unit::GlancingMultiplier(Unit* victim, [[maybe_unused]] WeaponAttackType attackType) const
{
    CalcDamageInfo info;
    CalcDamageInfo* damageInfo = &info;
    damageInfo->damages[0].damage = 1000;
    switch (MELEE_HIT_GLANCING)
    {
        // NATIVE_GLANCING
        default:
            break;
    }
    return float(damageInfo->damages[0].damage) / 1000.0f;
}

void Check(bool condition, char const* label)
{
    if (condition)
        return;
    std::printf("FAIL: %s\n", label);
    std::exit(1);
}

bool Near(double actual, double expected, double tolerance = 0.0005)
{
    return std::fabs(actual - expected) <= tolerance;
}

using Table = std::map<MeleeHitOutcome, int32>;

Table Roll(Unit const& attacker, Unit const& victim, int32 crit, int32 miss, int32 dodge, int32 parry, int32 block)
{
    Table table;
    for (nextRoll = 0; nextRoll < 10000; ++nextRoll)
        ++table[attacker.RollMeleeOutcomeAgainst(&victim, BASE_ATTACK, crit, miss, dodge, parry, block)];
    return table;
}

void Expect(Table const& actual, Table const& expected, char const* label)
{
    if (actual == expected)
        return;
    for (auto const& [outcome, count] : actual)
        std::printf("  actual   %d: %d\n", int(outcome), count);
    for (auto const& [outcome, count] : expected)
        std::printf("  expected %d: %d\n", int(outcome), count);
    Check(false, label);
}

Unit PlayerAt(uint8 level)
{
    Unit unit;
    unit.player = true;
    unit.level = level;
    unit.weaponSkill = level * 5;
    unit.defense = level * 5;
    return unit;
}

Unit CreatureAt(uint8 level)
{
    Unit unit;
    unit.level = level;
    return unit;
}

double ExpectedMitigation(float resistChance)
{
    ClassicPlusCombat::PartialResistChances const chances = ClassicPlusCombat::PartialResistDistribution(resistChance);
    return 0.75 * chances.Resist75 + 0.5 * chances.Resist50 + 0.25 * chances.Resist25;
}

void CheckFormulas()
{
    using namespace ClassicPlusCombat;
    Check(IsClassicContext({ 60, true }, { 63, false }), "level 60 player against a level 63 creature is classic");
    Check(IsClassicContext({ 63, false }, { 60, true }), "level 63 boss against a level 60 player is classic");
    Check(IsClassicContext({ 60, true }, { 60, true }), "level 60 duel is classic");
    Check(IsClassicContext({ 63, false }, { 63, false }), "level 63 creatures are classic");
    Check(!IsClassicContext({ 60, true }, { 64, false }), "level 64 creature is WotLK content");
    Check(!IsClassicContext({ 61, true }, { 61, false }), "level 61 player is WotLK content");
    Check(!IsClassicContext({ 80, true }, { 83, false }), "level 80 player against a boss seen at 83 is WotLK");
    Check(!IsClassicContext({ 83, false }, { 80, true }), "boss seen at 83 against level 80 player is WotLK");
    Check(!IsClassicContext({ 64, false }, { 63, false }), "level 64 creature attacker is WotLK");

    Check(Near(CreatureBaseAvoidance, 5.0), "creatures dodge, parry and block 5% before skill");
    Check(GlancingChance(300, 300, 300) == 1000, "same-level glancing 10%");
    Check(GlancingChance(305, 300, 300) == 2000, "+1 glancing 20%");
    Check(GlancingChance(310, 300, 300) == 3000, "+2 glancing 30%");
    Check(GlancingChance(315, 300, 300) == 4000, "+3 glancing 40%");
    Check(GlancingChance(325, 300, 300) == 4000, "glancing capped at 40%");
    Check(GlancingChance(315, 310, 300) == 4000, "weapon skill above the cap does not reduce glancing");
    Check(GlancingChance(300, 290, 300) == 3000, "missing weapon skill adds 2% per point");
    Check(GlancingChance(285, 300, 300) == 0, "no glancing against lower-level creatures");

    auto const average = [](DamageRange range) { return (range.Low + range.High) / 2.0; };
    Check(Near(average(GlancingDamageRange(300, 300, false)), 0.95), "glancing damage at a 0 gap");
    Check(Near(average(GlancingDamageRange(305, 300, false)), 0.95), "glancing damage at a 5 gap");
    Check(Near(average(GlancingDamageRange(310, 300, false)), 0.85), "glancing damage at a 10 gap");
    Check(Near(average(GlancingDamageRange(315, 300, false)), 0.65), "glancing damage at a 15 gap");
    Check(Near(GlancingDamageRange(300, 300, true).Low, 0.6) && Near(GlancingDamageRange(300, 300, true).High, 0.9),
        "caster glancing damage at a 0 gap");
    Check(Near(GlancingDamageRange(315, 300, true).Low, 0.01) && Near(GlancingDamageRange(315, 300, true).High, 0.45),
        "caster glancing damage at a 15 gap");
    for (int32 gap = -60; gap <= 100; ++gap)
        for (bool caster : { false, true })
        {
            DamageRange const range = GlancingDamageRange(300 + gap, 300, caster);
            Check(range.Low >= 0.01f && range.Low <= range.High && range.High <= 0.99f, "glancing damage bounds");
        }

    Check(Near(WotlkGlancingDamageMultiplier(1), 0.9), "WotLK glancing at +1");
    Check(Near(WotlkGlancingDamageMultiplier(3), 0.7), "WotLK glancing at +3");
    Check(Near(WotlkGlancingDamageMultiplier(7), 0.7), "WotLK glancing capped at +3");
    Check(Near(WotlkGlancingDamageMultiplier(63 - 80), 1.0), "level 80 against authored level 63 never exceeds 100%");
    for (int32 gap = -80; gap <= 80; ++gap)
        Check(WotlkGlancingDamageMultiplier(gap) <= 1.0f, "WotLK glancing never exceeds full damage");

    Check(CreatureAvoidanceChance(Avoidance::Dodge, 500, 300, 300, 315, 63) == 650, "+3 dodge 6.5%");
    Check(CreatureAvoidanceChance(Avoidance::Parry, 500, 300, 300, 315, 63) == 1400, "+3 parry 14%");
    Check(CreatureAvoidanceChance(Avoidance::Block, 500, 300, 300, 315, 63) == 500, "+3 block capped at 5%");
    Check(CreatureAvoidanceChance(Avoidance::Dodge, 500, 300, 300, 310, 62) == 600, "+2 dodge 6%");
    Check(CreatureAvoidanceChance(Avoidance::Parry, 500, 300, 300, 310, 62) == 700, "+2 parry 7%");
    Check(CreatureAvoidanceChance(Avoidance::Dodge, 500, 300, 300, 305, 61) == 550, "+1 dodge 5.5%");
    Check(CreatureAvoidanceChance(Avoidance::Parry, 500, 300, 300, 305, 61) == 600, "+1 parry 6%");
    Check(CreatureAvoidanceChance(Avoidance::Dodge, 500, 300, 300, 285, 57) == 350, "-3 dodge 3.5%");
    Check(CreatureAvoidanceChance(Avoidance::Parry, 500, 300, 300, 285, 57) == 200, "-3 parry 2%");
    Check(CreatureAvoidanceChance(Avoidance::Block, 500, 300, 300, 285, 57) == 350, "-3 block 3.5%");
    Check(CreatureAvoidanceChance(Avoidance::Dodge, 500, 40, 40, 25, 5) == 175, "level 5 creature dodge 1.75%");
    Check(CreatureAvoidanceChance(Avoidance::Parry, 500, 40, 40, 25, 5) == 100, "level 5 creature parry 1%");
    Check(CreatureAvoidanceChance(Avoidance::Block, 500, 40, 40, 25, 5) == 175, "level 5 creature block 1.75%");
    Check(CreatureAvoidanceChance(Avoidance::Dodge, 500, 40, 40, 40, 8) == 400, "level 8 creature dodge 4%");
    Check(CreatureAvoidanceChance(Avoidance::Dodge, 500, 305, 300, 315, 63) == 600, "weapon skill reduces dodge");
    Check(CreatureAvoidanceChance(Avoidance::Parry, 500, 305, 300, 315, 63) == 1400, "parry uses capped skill");

    Check(Near(CreatureMissChance(5.0f, 15, 63), 8.0), "+3 miss 8%");
    Check(Near(CreatureMissChance(5.0f, 10, 62), 6.0), "+2 miss 6%");
    Check(Near(CreatureMissChance(5.0f, 5, 61), 5.5), "+1 miss 5.5%");
    Check(Near(CreatureMissChance(5.0f, 13, 63), 7.6), "13-point gap miss 7.6%");
    Check(Near(CreatureMissChance(24.0f, 15, 63), 27.0), "dual wield +3 miss 27%");
    Check(Near(CreatureMissChance(5.0f, -15, 5), 1.75), "level 5 creature miss 1.75%");
    Check(Near(CreatureMissChance(5.0f, 0, 8), 4.0), "level 8 creature miss 4%");
    Check(Near(8.0 - 9.0 + IgnoredHitChance(9.0f, 15), 0.0), "9% hit caps white misses against +3");
    Check(Near(IgnoredHitChance(1.0f, 15), 1.0), "first 1% hit ignored against +3");
    Check(Near(IgnoredHitChance(0.5f, 15), 0.5), "partial first point of hit ignored");
    Check(Near(IgnoredHitChance(3.0f, 10), 0.0), "hit counts in full at a 10-point gap");
    Check(Near(IgnoredHitChance(0.0f, 15), 0.0), "no hit, nothing ignored");

    Check(Near(5.0 + CreatureVictimCritModifier(300, 300, 315), 2.0), "+3 crit 2%");
    Check(Near(5.0 + CreatureVictimCritModifier(300, 300, 310), 3.0), "+2 crit 3%");
    Check(Near(5.0 + CreatureVictimCritModifier(300, 300, 305), 4.0), "+1 crit 4%");
    Check(Near(5.0 + CreatureVictimCritModifier(300, 300, 300), 5.0), "same-level crit 5%");
    Check(Near(5.0 + CreatureVictimCritModifier(300, 300, 285), 5.6), "-3 crit 5.6%");
    Check(Near(5.0 + CreatureVictimCritModifier(305, 300, 315), 2.0), "skill above cap does not offset suppression");

    Check(Near(ArmorConstant(30), 2950.0) && Near(ArmorConstant(60), 5500.0), "armor constant at 30 and 60");
    Check(Near(ArmorConstant(61), 5585.0) && Near(ArmorConstant(62), 5670.0), "armor constant at 61 and 62");
    Check(Near(ArmorConstant(63), 5755.0), "armor constant at 63");
    Check(Near(10000.0 / (10000.0 + ArmorConstant(63)), 0.6347, 0.0001), "10k armor against level 63");
    Check(Near(5000.0 / (5000.0 + ArmorConstant(60)), 0.4762, 0.0001), "5k armor against level 60");

    Check(Near(SpellResistChance(0, 3, 30, true), 0.055), "level 30 against 33 resists 5.5%");
    Check(Near(SpellResistChance(0, 2, 30, true), 0.035), "level 30 against 32 resists 3.5%");
    Check(Near(SpellResistChance(5, 1, 60, true), 0.03), "level 61 creature with 5 resistance");
    Check(Near(SpellResistChance(10, 2, 60, true), 0.0625), "level 62 creature with 10 resistance");
    Check(Near(SpellResistChance(15, 3, 60, true), 0.0925), "level 63 creature with 15 resistance");
    Check(Near(SpellResistChance(75, 0, 60, true), 0.1875), "75 resistance at level 60");
    Check(Near(SpellResistChance(75, 3, 60, true), 0.2425), "75 resistance against level 63");
    Check(Near(SpellResistChance(0, 3, 3, true), 0.05), "level 3 against 6 resists 5%");
    Check(Near(SpellResistChance(0, -3, 60, true), 0.0), "lower-level creatures do not go below zero");
    Check(Near(SpellResistChance(1000, 0, 60, true), 0.75), "resist capped at 75%");
    Check(Near(SpellResistChance(15, 3, 60, false), 0.0375), "binary spells skip the level term");

    Check(Near(ExpectedMitigation(0.03f), 2.50, 0.006), "mitigation at 3% resist chance");
    Check(Near(ExpectedMitigation(0.035f), 3.31, 0.006), "mitigation at 3.5% resist chance");
    Check(Near(ExpectedMitigation(0.055f), 6.08, 0.006), "mitigation at 5.5% resist chance");
    Check(Near(ExpectedMitigation(0.0625f), 6.58, 0.006), "mitigation at 6.25% resist chance");
    Check(Near(ExpectedMitigation(0.0925f), 9.16, 0.006), "mitigation at 9.25% resist chance");
    Check(Near(ExpectedMitigation(0.1875f), 18.28, 0.006), "mitigation at 18.75% resist chance");
    Check(Near(ExpectedMitigation(0.2425f), 24.25, 0.006), "mitigation at 24.25% resist chance");
    Check(Near(ExpectedMitigation(0.05f), 5.75, 0.006), "mitigation at 5% resist chance");
    PartialResistChances const at8 = PartialResistDistribution(0.08f);
    Check(Near(at8.Resist75, 1.0) && Near(at8.Resist50, 5.0) && Near(at8.Resist25, 18.0), "8% resist row");
    PartialResistChances const at75 = PartialResistDistribution(0.75f);
    Check(Near(at75.Resist75, 80.0) && Near(at75.Resist50, 16.0) && Near(at75.Resist25, 3.0), "75% resist row");
    PartialResistChances const none = PartialResistDistribution(0.0f);
    Check(Near(none.Resist75 + none.Resist50 + none.Resist25, 0.0), "no resist chance never resists");
    Check(PartialResistMultiplier(at8, 0.5f) == 0.75f && PartialResistMultiplier(at8, 3.0f) == 0.5f,
        "75% and 50% buckets");
    Check(PartialResistMultiplier(at8, 10.0f) == 0.25f && PartialResistMultiplier(at8, 30.0f) == 0.0f,
        "25% and unresisted buckets");
    Check(Near(DotResistChanceFactor, 0.1), "DoT partial resists are ten times rarer");
    Check(ResistsDotAsDirectDamage(23461) && ResistsDotAsDirectDamage(28531) && !ResistsDotAsDirectDamage(172),
        "only listed DoTs resist like direct damage");

    Check(BinaryResistChance(0, SpellResistChance(50, 0, 60, false)) == 1250, "binary resist at 50 resistance");
    Check(BinaryResistChance(0, SpellResistChance(100, 0, 60, false)) == 2500, "binary resist at 100 resistance");
    Check(BinaryResistChance(0, SpellResistChance(200, 0, 60, false)) == 5000, "binary resist at 200 resistance");
    Check(BinaryResistChance(400, 0.125f) == 1200, "binary resist scales the remaining hit chance");
    Check(Near(EnergyThreatPerPoint, 5.0), "energy gains cause 5 threat per point");
    Check(Near(20.0 - (300 - 315) * DazeChancePerSkillPoint, 23.0), "daze against +3 creature is 23%");
}

void CheckAvoidanceBase()
{
    Unit beast = CreatureAt(60);
    Check(Near(ClassicCreatureAvoidanceChance(&beast, SPELL_AURA_MOD_PARRY_PERCENT), 5.0), "every creature parries 5%");
    beast.worldBoss = true;
    Check(Near(ClassicCreatureAvoidanceChance(&beast, SPELL_AURA_MOD_DODGE_PERCENT), 5.0), "world boss base dodge 5%");
    beast.avoidanceAura = -10;
    Check(Near(ClassicCreatureAvoidanceChance(&beast, SPELL_AURA_MOD_PARRY_PERCENT), 0.0), "avoidance never negative");
    Unit totem = CreatureAt(60);
    totem.totem = true;
    Check(Near(ClassicCreatureAvoidanceChance(&totem, SPELL_AURA_MOD_PARRY_PERCENT), 0.0), "totems do not parry");
}

void CheckMissChance()
{
    Unit player = PlayerAt(60);
    Unit creature = CreatureAt(63);
    Unit low = CreatureAt(5);
    Unit peer = PlayerAt(60);
    Unit high = PlayerAt(80);
    Unit wotlk = CreatureAt(83);
    auto const miss = [](Unit const& attacker, Unit const& victim)
    {
        int32 const skillDiff = int32(attacker.GetWeaponSkillValue(BASE_ATTACK, &victim)) -
            int32(victim.GetMaxSkillValueForLevel(&attacker));
        return attacker.MeleeSpellMissChance(&victim, BASE_ATTACK, skillDiff, 0);
    };
    Check(Near(miss(player, creature), 8.0), "white miss against +3 is 8%");
    player.m_modMeleeHitChance = 1.0f;
    Check(Near(miss(player, creature), 8.0), "the first 1% hit is ignored against +3");
    player.m_modMeleeHitChance = 3.0f;
    Check(Near(miss(player, creature), 6.0), "3% hit against +3 leaves 6%");
    player.m_modMeleeHitChance = 9.0f;
    Check(Near(miss(player, creature), 0.0), "9% hit removes white misses against +3");
    player.m_modMeleeHitChance = 0.0f;
    player.dualWield = true;
    Check(Near(miss(player, creature), 27.0), "dual wield against +3 misses 27%");
    player.dualWield = false;
    Unit novice = PlayerAt(8);
    Check(Near(miss(novice, low), 1.75), "level 8 against level 5 misses 1.75%");
    Check(Near(miss(player, peer), 5.0), "same-skill players miss each other 5%");
    Unit boss = CreatureAt(63);
    Unit raider = CreatureAt(62);
    Check(Near(miss(boss, player), 4.4), "a level 63 creature misses a level 60 player 4.4%");
    Check(Near(miss(raider, player), 4.6), "a level 62 creature misses a level 60 player 4.6%");
    world.classicPlus = false;
    Check(Near(miss(boss, player), 4.7), "rules off keep the WotLK 0.02 per point against players");
    world.classicPlus = true;
    high.m_modMeleeHitChance = 1.0f;
    Check(Near(miss(high, wotlk), 7.0), "level 80 content keeps full hit value");
    world.classicPlus = false;
    player.m_modMeleeHitChance = 1.0f;
    Check(Near(miss(player, creature), 7.0), "rules off keep full hit value");
    world.classicPlus = true;
}

void CheckResistChance()
{
    Unit caster = PlayerAt(30);
    Unit target = CreatureAt(33);
    SpellSchoolMask const fire = SPELL_SCHOOL_MASK_FIRE;
    Check(Near(Unit::GetEffectiveResistChance(&caster, fire, &target), 0.055), "level 30 against 33 resists 5.5%");
    world.classicPlus = false;
    Check(Near(Unit::GetEffectiveResistChance(&caster, fire, &target), 15.0 / 97.5), "rules off keep WotLK resist");
    world.classicPlus = true;
    Unit sixty = PlayerAt(60);
    Unit raidBoss = CreatureAt(63);
    raidBoss.resistance = 15;
    Check(Near(Unit::GetEffectiveResistChance(&sixty, fire, &raidBoss), 0.0925), "level 63 boss with 15 resistance");
    Unit worldBoss = CreatureAt(83);
    worldBoss.worldBoss = true;
    worldBoss.resistance = 15;
    Check(Near(Unit::GetEffectiveResistChance(&sixty, fire, &worldBoss), 0.0925), "boss level follows the view");
    SpellInfo binary;
    binary.binary = true;
    raidBoss.resistance = 100;
    Check(Near(Unit::GetEffectiveResistChance(&sixty, fire, &raidBoss, &binary), 0.25),
        "binary spells skip the level term");
    Unit duelist = PlayerAt(60);
    duelist.resistance = 75;
    Check(Near(Unit::GetEffectiveResistChance(&sixty, fire, &duelist), 0.1875), "players get no level resistance");
    Unit boss = CreatureAt(63);
    Unit tank = PlayerAt(60);
    Check(Near(Unit::GetEffectiveResistChance(&boss, fire, &tank), 0.0), "creature casters add no level resistance");
    Unit penetrating = PlayerAt(30);
    penetrating.penetration = -10;
    Unit resistant = CreatureAt(30);
    resistant.resistance = 5;
    Check(Near(Unit::GetEffectiveResistChance(&penetrating, fire, &resistant), 0.0), "penetration floors at zero");
    Unit eighty = PlayerAt(80);
    Unit northrend = CreatureAt(83);
    double const constant = 150.0 + (83 - 60) * (83 - 67.5);
    Check(Near(Unit::GetEffectiveResistChance(&eighty, fire, &northrend), 15.0 / (15.0 + constant)),
        "level 80 content keeps WotLK resist");
}

void CheckGlancingDamage()
{
    Unit player = PlayerAt(80);
    Unit ragnaros = CreatureAt(63);
    ragnaros.worldBoss = true;
    float const bossGlance = player.GlancingMultiplier(&ragnaros, BASE_ATTACK);
    Check(bossGlance <= 1.0f, "level 80 glancing blows against Ragnaros stay below full damage");
    Check(Near(bossGlance, 0.7), "level 80 glancing against a boss seen at 83 deals 70%");
    Unit sixty = PlayerAt(60);
    Unit elite = CreatureAt(63);
    Check(Near(sixty.GlancingMultiplier(&elite, BASE_ATTACK), 0.65), "classic +3 glancing averages 65%");
    Unit same = CreatureAt(60);
    Check(Near(sixty.GlancingMultiplier(&same, BASE_ATTACK), 0.95), "classic same-level glancing averages 95%");
    Unit mage = PlayerAt(60);
    mage.cls = CLASS_MAGE;
    Check(Near(mage.GlancingMultiplier(&elite, BASE_ATTACK), 0.23), "caster +3 glancing averages 23%");
    Unit pyromancer = PlayerAt(60);
    pyromancer.cls = CLASS_PYROMANCER;
    Check(Near(pyromancer.GlancingMultiplier(&elite, BASE_ATTACK), 0.23), "custom casters follow their legacy class");
    Unit sunCleric = PlayerAt(60);
    sunCleric.cls = CLASS_SUN_CLERIC;
    Check(Near(sunCleric.GlancingMultiplier(&elite, BASE_ATTACK), 0.65), "Sun Cleric glances as a melee class");
    world.classicPlus = false;
    Unit wotlkTarget = CreatureAt(61);
    Check(Near(sixty.GlancingMultiplier(&wotlkTarget, BASE_ATTACK), 0.9), "rules off keep WotLK glancing at +1");
    world.classicPlus = true;
}

void CheckMeleeTable()
{
    Unit player = PlayerAt(60);
    Unit plus3 = CreatureAt(63);
    Expect(Roll(player, plus3, 200, 800, 500, 500, 500), { { MELEE_HIT_MISS, 800 }, { MELEE_HIT_DODGE, 650 },
        { MELEE_HIT_PARRY, 1400 }, { MELEE_HIT_GLANCING, 4000 }, { MELEE_HIT_BLOCK, 500 }, { MELEE_HIT_CRIT, 200 },
        { MELEE_HIT_NORMAL, 2450 } }, "level 60 against level 63 creature");
    Unit same = CreatureAt(60);
    Expect(Roll(player, same, 500, 500, 500, 500, 500), { { MELEE_HIT_MISS, 500 }, { MELEE_HIT_DODGE, 500 },
        { MELEE_HIT_PARRY, 500 }, { MELEE_HIT_GLANCING, 1000 }, { MELEE_HIT_BLOCK, 500 }, { MELEE_HIT_CRIT, 500 },
        { MELEE_HIT_NORMAL, 6500 } }, "level 60 against level 60 creature");
    Unit guardian = CreatureAt(60);
    guardian.controlled = true;
    Expect(Roll(player, guardian, 500, 500, 500, 500, 500), { { MELEE_HIT_MISS, 500 }, { MELEE_HIT_DODGE, 500 },
        { MELEE_HIT_PARRY, 500 }, { MELEE_HIT_BLOCK, 500 }, { MELEE_HIT_CRIT, 500 }, { MELEE_HIT_NORMAL, 7500 } },
        "player-controlled guardians are not glanced");
    Unit plus1 = CreatureAt(61);
    Expect(Roll(player, plus1, 400, 550, 500, 500, 500), { { MELEE_HIT_MISS, 550 }, { MELEE_HIT_DODGE, 550 },
        { MELEE_HIT_PARRY, 600 }, { MELEE_HIT_GLANCING, 2000 }, { MELEE_HIT_BLOCK, 500 }, { MELEE_HIT_CRIT, 400 },
        { MELEE_HIT_NORMAL, 5400 } }, "level 60 against level 61 creature");
    Unit plus2 = CreatureAt(62);
    Expect(Roll(player, plus2, 300, 600, 500, 500, 500), { { MELEE_HIT_MISS, 600 }, { MELEE_HIT_DODGE, 600 },
        { MELEE_HIT_PARRY, 700 }, { MELEE_HIT_GLANCING, 3000 }, { MELEE_HIT_BLOCK, 500 }, { MELEE_HIT_CRIT, 300 },
        { MELEE_HIT_NORMAL, 4300 } }, "level 60 against level 62 creature");
    Unit minus3 = CreatureAt(57);
    Expect(Roll(player, minus3, 560, 350, 500, 500, 500), { { MELEE_HIT_MISS, 350 }, { MELEE_HIT_DODGE, 350 },
        { MELEE_HIT_PARRY, 200 }, { MELEE_HIT_BLOCK, 350 }, { MELEE_HIT_CRIT, 560 }, { MELEE_HIT_NORMAL, 8190 } },
        "level 60 against level 57 creature");
    Unit novice = PlayerAt(8);
    Unit young = CreatureAt(5);
    Expect(Roll(novice, young, 560, 175, 500, 500, 500), { { MELEE_HIT_MISS, 175 }, { MELEE_HIT_DODGE, 175 },
        { MELEE_HIT_PARRY, 100 }, { MELEE_HIT_BLOCK, 175 }, { MELEE_HIT_CRIT, 560 }, { MELEE_HIT_NORMAL, 8815 } },
        "level 8 against level 5 creature");
    Unit peer = CreatureAt(8);
    Expect(Roll(novice, peer, 500, 400, 500, 500, 500), { { MELEE_HIT_MISS, 400 }, { MELEE_HIT_DODGE, 400 },
        { MELEE_HIT_PARRY, 400 }, { MELEE_HIT_GLANCING, 1000 }, { MELEE_HIT_BLOCK, 400 }, { MELEE_HIT_CRIT, 500 },
        { MELEE_HIT_NORMAL, 6900 } }, "level 8 against level 8 creature");

    plus3.front = false;
    Expect(Roll(player, plus3, 200, 800, 500, 500, 500), { { MELEE_HIT_MISS, 800 }, { MELEE_HIT_DODGE, 650 },
        { MELEE_HIT_GLANCING, 4000 }, { MELEE_HIT_CRIT, 200 }, { MELEE_HIT_NORMAL, 4350 } },
        "level 60 behind a level 63 creature");
    plus3.front = true;

    Unit pet = CreatureAt(60);
    pet.pet = true;
    Expect(Roll(pet, plus3, 200, 800, 500, 500, 500), { { MELEE_HIT_MISS, 800 }, { MELEE_HIT_DODGE, 650 },
        { MELEE_HIT_PARRY, 1400 }, { MELEE_HIT_GLANCING, 4000 }, { MELEE_HIT_BLOCK, 500 }, { MELEE_HIT_CRIT, 200 },
        { MELEE_HIT_NORMAL, 2450 } }, "level 60 pet against level 63 creature");

    scripts.hook = [](int32& crit, int32&, int32&) { crit = 10000; };
    Expect(Roll(player, same, 500, 500, 500, 500, 500), { { MELEE_HIT_MISS, 500 }, { MELEE_HIT_DODGE, 500 },
        { MELEE_HIT_PARRY, 500 }, { MELEE_HIT_BLOCK, 500 }, { MELEE_HIT_CRIT, 8000 } },
        "a guaranteed crit contract is not downgraded to a glancing blow");
    scripts.hook = [](int32&, int32& dodge, int32& parry) { dodge = parry = 0; };
    Expect(Roll(player, plus3, 200, 800, 500, 500, 500), { { MELEE_HIT_MISS, 800 }, { MELEE_HIT_GLANCING, 4000 },
        { MELEE_HIT_BLOCK, 500 }, { MELEE_HIT_CRIT, 200 }, { MELEE_HIT_NORMAL, 4500 } },
        "a contract removing dodge and parry stays removed");
    scripts.hook = nullptr;

    Unit tank = PlayerAt(60);
    Unit boss = CreatureAt(63);
    Expect(Roll(boss, tank, 560, 500, 500, 500, 500), { { MELEE_HIT_MISS, 500 }, { MELEE_HIT_DODGE, 440 },
        { MELEE_HIT_PARRY, 440 }, { MELEE_HIT_BLOCK, 440 }, { MELEE_HIT_CRIT, 560 }, { MELEE_HIT_CRUSHING, 1500 },
        { MELEE_HIT_NORMAL, 6120 } }, "level 63 creature crushes a level 60 player 15%");
    tank.defense = 320;
    Expect(Roll(boss, tank, 560, 500, 500, 500, 500), { { MELEE_HIT_MISS, 500 }, { MELEE_HIT_DODGE, 440 },
        { MELEE_HIT_PARRY, 440 }, { MELEE_HIT_BLOCK, 440 }, { MELEE_HIT_CRIT, 560 }, { MELEE_HIT_CRUSHING, 1500 },
        { MELEE_HIT_NORMAL, 6120 } }, "defense above the level cap does not reduce crushing blows");
    tank.defense = 300;
    Unit worldBoss = CreatureAt(83);
    worldBoss.worldBoss = true;
    Expect(Roll(worldBoss, tank, 560, 500, 500, 500, 500), { { MELEE_HIT_MISS, 500 }, { MELEE_HIT_DODGE, 440 },
        { MELEE_HIT_PARRY, 440 }, { MELEE_HIT_BLOCK, 440 }, { MELEE_HIT_CRIT, 560 }, { MELEE_HIT_CRUSHING, 1500 },
        { MELEE_HIT_NORMAL, 6120 } }, "world boss seen at 63 crushes a level 60 player 15%");
    Unit veteran = PlayerAt(80);
    Expect(Roll(worldBoss, veteran, 560, 500, 500, 500, 500), { { MELEE_HIT_MISS, 500 }, { MELEE_HIT_DODGE, 440 },
        { MELEE_HIT_PARRY, 440 }, { MELEE_HIT_BLOCK, 440 }, { MELEE_HIT_CRIT, 560 }, { MELEE_HIT_NORMAL, 7620 } },
        "world boss seen at 83 does not crush a level 80 player");
    Unit raid = CreatureAt(83);
    Expect(Roll(raid, veteran, 560, 500, 500, 500, 500), { { MELEE_HIT_MISS, 500 }, { MELEE_HIT_DODGE, 440 },
        { MELEE_HIT_PARRY, 440 }, { MELEE_HIT_BLOCK, 440 }, { MELEE_HIT_CRIT, 560 }, { MELEE_HIT_NORMAL, 7620 } },
        "level 83 raid creature does not crush a level 80 player");
    Unit ogre = CreatureAt(64);
    Expect(Roll(ogre, tank, 560, 500, 500, 500, 500), { { MELEE_HIT_MISS, 500 }, { MELEE_HIT_DODGE, 420 },
        { MELEE_HIT_PARRY, 420 }, { MELEE_HIT_BLOCK, 420 }, { MELEE_HIT_CRUSHING, 2500 }, { MELEE_HIT_CRIT, 560 },
        { MELEE_HIT_NORMAL, 5180 } }, "level 64 creature keeps the WotLK crushing roll");
    Unit clumsy = CreatureAt(63);
    clumsy.flagsExtra = CREATURE_FLAG_EXTRA_NO_CRIT;
    Expect(Roll(clumsy, tank, 560, 500, 500, 500, 500), { { MELEE_HIT_MISS, 500 }, { MELEE_HIT_DODGE, 440 },
        { MELEE_HIT_PARRY, 440 }, { MELEE_HIT_BLOCK, 440 }, { MELEE_HIT_CRUSHING, 1500 }, { MELEE_HIT_NORMAL, 6680 } },
        "a creature that cannot crit does not turn crits into crushing blows");
    Unit knight = PlayerAt(60);
    knight.cls = 17;
    knight.forgemaster = true;
    chanceRoll = true;
    Expect(Roll(boss, knight, 560, 500, 500, 500, 500), { { MELEE_HIT_MISS, 500 }, { MELEE_HIT_DODGE, 440 },
        { MELEE_HIT_PARRY, 440 }, { MELEE_HIT_BLOCK, 1940 }, { MELEE_HIT_CRIT, 560 }, { MELEE_HIT_NORMAL, 6120 } },
        "Forgemaster fierce-blow policy blocks classic crushing blows");
    chanceRoll = false;

    Unit wolf = CreatureAt(60);
    wolf.pet = true;
    Expect(Roll(boss, wolf, 560, 500, 500, 500, 500), { { MELEE_HIT_MISS, 500 }, { MELEE_HIT_DODGE, 350 },
        { MELEE_HIT_PARRY, 200 }, { MELEE_HIT_BLOCK, 350 }, { MELEE_HIT_CRIT, 560 }, { MELEE_HIT_CRUSHING, 1500 },
        { MELEE_HIT_NORMAL, 6540 } }, "pets are creature victims in the classic table");

    Unit veteranAttacker = PlayerAt(80);
    Expect(Roll(veteranAttacker, raid, 440, 800, 500, 500, 500), { { MELEE_HIT_MISS, 800 }, { MELEE_HIT_DODGE, 560 },
        { MELEE_HIT_PARRY, 560 }, { MELEE_HIT_BLOCK, 560 }, { MELEE_HIT_GLANCING, 2500 }, { MELEE_HIT_CRIT, 440 },
        { MELEE_HIT_NORMAL, 4580 } }, "level 80 against level 83 keeps the WotLK table");
    world.classicPlus = false;
    Expect(Roll(player, plus3, 440, 800, 500, 500, 500), { { MELEE_HIT_MISS, 800 }, { MELEE_HIT_DODGE, 560 },
        { MELEE_HIT_PARRY, 560 }, { MELEE_HIT_BLOCK, 560 }, { MELEE_HIT_GLANCING, 2500 }, { MELEE_HIT_CRIT, 440 },
        { MELEE_HIT_NORMAL, 4580 } }, "rules off keep the WotLK table");
    Expect(Roll(player, same, 500, 500, 500, 500, 500), { { MELEE_HIT_MISS, 500 }, { MELEE_HIT_DODGE, 500 },
        { MELEE_HIT_PARRY, 500 }, { MELEE_HIT_BLOCK, 500 }, { MELEE_HIT_CRIT, 500 }, { MELEE_HIT_NORMAL, 7500 } },
        "rules off keep no same-level glancing");
    Expect(Roll(boss, tank, 560, 500, 500, 500, 500), { { MELEE_HIT_MISS, 500 }, { MELEE_HIT_DODGE, 440 },
        { MELEE_HIT_PARRY, 440 }, { MELEE_HIT_BLOCK, 440 }, { MELEE_HIT_CRIT, 560 }, { MELEE_HIT_NORMAL, 7620 } },
        "rules off keep the +4 crushing gate");
    world.classicPlus = true;
}

int main()
{
    CheckFormulas();
    CheckGlancingDamage();
    CheckAvoidanceBase();
    CheckMissChance();
    CheckResistChance();
    CheckMeleeTable();
    std::printf("PASS\n");
    return 0;
}
