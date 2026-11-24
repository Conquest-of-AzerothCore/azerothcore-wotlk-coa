/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionFelsworn.h"
#include "AscensionFelswornData.h"
#include "DBCStores.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include <algorithm>
#include <cstdlib>
#include <utility>

namespace AscensionFelsworn
{
void ApplyContracts(SpellInfo* info)
{
    if (!info)
        return;
    for (auto const& rift : FelswornRifts)
        if (info->Id == rift.spell)
            info->Effects[0].MiscValue = rift.entry;
    if (info->Id == 805240)
        info->AscensionTargetAuraStateOnlyPrimary = true;
    if (info->SpellFamilyName != 20)
        return;
    uint32 id = info->Id;
    if (id == MannorothFelfury)
        info->Effects[EFFECT_0].MiscValue = 6;
    if (id == BloodOfMannoroth &&
        info->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_MOD_ARMOR_PENETRATION_PCT)
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_ASCENSION_MOD_IGNORE_ARMOR_PCT;
    if (id == 300466)
    {
        info->Effects[EFFECT_0].SpellClassMask = flag96(128, 0, 2097152);
        info->Effects[EFFECT_1].SpellClassMask = flag96(128, 0, 2097152);
    }
    if (id == 578317)
        info->SpellFamilyFlags = flag96(0, 0, 2097152);
    auto dummy = [info](uint8 slot) {
        info->Effects[slot].ApplyAuraName = SPELL_AURA_DUMMY;
        info->Effects[slot].TriggerSpell = 0;
    };
    auto periodic = [info](uint8 slot, uint32 interval) {
        auto& effect = info->Effects[slot];
        effect.Effect = SPELL_EFFECT_APPLY_AURA;
        effect.ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        effect.Amplitude = interval;
        effect.TriggerSpell = 0;
    };
    for (auto const& ids : {std::pair(FelswornEvents, std::size(FelswornEvents)),
                            std::pair(FelswornCastDrivers, std::size(FelswornCastDrivers))})
        for (size_t n = 0; n < ids.second; ++n)
            if (ids.first[n] == id)
            {
                for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
                    if (info->Effects[i].ApplyAuraName == 42 || info->Effects[i].ApplyAuraName == 354)
                        dummy(i);
                info->ProcCharges = 0;
                info->ProcFlags = 0;
            }
    for (uint32 sid : FelswornCopies)
        if (id == sid)
        {
            info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
            info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
            info->AttributesEx4 |= SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS | SPELL_ATTR4_NO_CAST_LOG;
            info->AttributesCu |= SPELL_ATTR0_CU_IGNORE_ARMOR;
            info->ProcFlags = 0;
            info->Effects[0].TargetA = SpellImplicitTargetInfo(
                info->Effects[0].Effect == SPELL_EFFECT_HEAL ? TARGET_UNIT_CASTER : TARGET_UNIT_TARGET_ENEMY);
            info->Effects[0].TargetB = SpellImplicitTargetInfo();
            if (info->Effects[0].Effect == SPELL_EFFECT_HEALTH_LEECH)
                info->Effects[0].ValueMultiplier = 1;
        }
    if (id == 804758 && !info->ProcFlags)
        info->ProcFlags = PROC_FLAG_DONE_MELEE_AUTO_ATTACK | PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS;
    if (id == 804766 && !info->TargetCreatureType)
        info->TargetCreatureType = 1 << (CREATURE_TYPE_DEMON - 1);
    if (id == 804216)
    {
        info->DurationEntry = sSpellDurationStore.LookupEntry(1);
        info->Effects[2].Effect = 0;
    }
    if (id == 803465 || id == 807421 || id == 807428 || id == 807426)
        for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
            if (info->Effects[i].Effect && !(id == 807428 && i == EFFECT_2))
                dummy(i);
    if (id == 807426)
    {
        info->Effects[1].Effect = SPELL_EFFECT_APPLY_AURA;
        info->Effects[1].ApplyAuraName = SPELL_AURA_MOD_MELEE_HASTE;
        info->Effects[1].BasePoints = 14;
        info->Effects[1].DieSides = 1;
        info->Effects[1].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
    }
    if (id == 801043)
        info->Effects[0].MiscValue = 6;
    if (id == 705105)
        info->Effects[0].ApplyAuraName = SPELL_AURA_MOD_INCREASE_ENERGY;
    if (id == 705109 || id == 520249)
    {
        info->Effects[1].ApplyAuraName = SPELL_AURA_OVERRIDE_CLASS_SCRIPTS;
        info->Effects[1].MiscValue = ASCENSION_CREATURE_GLOBAL_CRIT;
        info->Effects[1].MiscValueB = 4;
    }
    if (id == 92087)
        info->Effects[1].MiscValue = ASCENSION_STATE_MASKED_GUARANTEED_CRIT;
    if (id == 704607)
        info->Effects[0].MiscValue = ASCENSION_CREATURE_GLOBAL_CRIT;
    if (id == 705127)
        dummy(0), info->Effects[1].MiscValue = ASCENSION_STATE_GLOBAL_CRIT_DAMAGE;
    if (id == 802180)
    {
        info->Effects[0].MiscValue = ASCENSION_STATE_MASKED_CRIT;
        info->Effects[0].MiscValueB = AURA_STATE_HEALTH_ABOVE_75_PERCENT;
    }
    if (id == 520833)
        dummy(1);
    if (id == 804610 || id == 704611 || id == 300489 || id == 803478 || id == 574146)
        dummy(0);
    if (id == 300489)
        dummy(1);
    if (id == 804613)
        dummy(0);
    if (id == 300470)
        dummy(0);
    if (id == 801573)
    {
        dummy(0), dummy(1);
        info->DurationEntry = sSpellDurationStore.LookupEntry(21);
    }
    if (id == 800220)
        dummy(0);
    if (id == 800203)
        info->Effects[2].Effect = 0;
    if (id == 800209)
        info->Effects[EFFECT_2].MiscValue = SPELL_SCHOOL_MASK_NORMAL;
    if (id >= 707523 && id <= 707527)
        info->Effects[EFFECT_1].MiscValue = SPELL_SCHOOL_MASK_NORMAL;
    if (id == BurningCommander)
    {
        periodic(1, 3000);
        info->Effects[EFFECT_2].Effect = 0;
    }
    if (id == 574145)
        dummy(0);
    if (id == 574150 || id == 804105 || id == 801894)
        for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
            if (info->Effects[i].Effect)
                dummy(i);
    if (id == 800707)
    {
        info->Effects[1].ApplyAuraName = SPELL_AURA_MOD_DODGE_PERCENT;
        info->Effects[1].BasePoints = 9;
        info->Effects[2].Effect = 0;
    }
    if (id == 520252 || id == 520253)
    {
        info->Effects[0].ApplyAuraName = SPELL_AURA_MOD_BASE_RESISTANCE_PCT;
        info->Effects[0].MiscValue = SPELL_SCHOOL_MASK_NORMAL;
        info->Effects[0].MiscValueB = 6;
    }
    if (id == 800206)
    {
        periodic(0, 250);
        info->Effects[1].ApplyAuraName = SPELL_AURA_MOD_DODGE_PERCENT;
        info->Effects[1].BasePoints = -1;
        info->Effects[1].TriggerSpell = 0;
        info->Effects[1].Amplitude = 0;
        dummy(2);
    }
    if (id == 803715)
    {
        info->Effects[0].Effect = SPELL_EFFECT_WEAPON_PERCENT_DAMAGE;
        info->Effects[1].Effect = SPELL_EFFECT_NORMALIZED_WEAPON_DMG;
        info->Effects[1].BasePoints = -1;
        info->Effects[1].RealPointsPerLevel = 0;
        info->Effects[0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY);
        info->Effects[1].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY);
        info->Effects[0].RadiusEntry = nullptr;
        info->Effects[1].RadiusEntry = nullptr;
    }
    if (id == 805241)
        info->Effects[0].RealPointsPerLevel = 0;
    if (id == 570159)
    {
        info->Effects[0].BasePoints = -1;
        info->Effects[0].RealPointsPerLevel = 0;
    }
    if (id == 804336)
        info->AttributesEx3 |= SPELL_ATTR3_REQUIRES_OFF_HAND_WEAPON;
    if (id == 800598)
    {
        info->AttributesEx3 |= SPELL_ATTR3_REQUIRES_OFF_HAND_WEAPON;
        info->Effects[0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY);
        info->Effects[0].TargetB = SpellImplicitTargetInfo();
    }
    if (id == 561216)
    {
        periodic(0, 500);
        info->DurationEntry = sSpellDurationStore.LookupEntry(27);
        info->Effects[1].Effect = 0;
        info->Effects[2].ApplyAuraName = SPELL_AURA_DUMMY;
    }
    if (id == 803904)
        dummy(0);
    if (id == 807163)
    {
        dummy(1);
        info->ProcFlags = info->ProcCharges = 0;
    }
    if (id == 555276)
        dummy(0);
    if (id == 560087)
        dummy(0);
    if (id == 807962)
    {
        dummy(0), dummy(1);
        info->AttributesEx3 |= SPELL_ATTR3_SUPPRESS_CASTER_PROCS;
    }
    if (id == 555277)
        info->Effects[0].MiscValue = SPELLMOD_CASTING_TIME;
    if (id == 807163)
        info->Effects[0].SpellClassMask = flag96(1048576, 16777216, 0);
    if (id == 806128)
        info->Effects[0].SpellClassMask = flag96(0, 524288, 2);
    if (id == 705123 || id == 707846 || id == 706266 || id == 707844)
        dummy(2);
    if (id == 801902)
        info->Effects[0].MiscValue = SPELLMOD_COST;
    if (id == 555739 || id == 806097)
        if (SpellEntry const* stated = sSpellStore.LookupEntry(806095))
            info->Effects[EFFECT_0].BasePoints = stated->EffectBasePoints[EFFECT_0];
    if (id == 560578)
    {
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_ADD_PCT_MODIFIER;
        info->Effects[EFFECT_0].MiscValue = SPELLMOD_DAMAGE;
    }
    if (id == 807424)
    {
        info->Effects[2].MiscValue = SPELLMOD_CASTING_TIME;
        info->Effects[2].ApplyAuraName = SPELL_AURA_ADD_PCT_MODIFIER;
        info->Effects[2].BasePoints = -101;
        info->StackAmount = 1;
    }
    if (id == 802058)
    {
        info->Effects[0].MiscValue = SPELLMOD_CASTING_TIME;
        info->Effects[1].MiscValue = SPELLMOD_COST;
        info->Effects[1].ApplyAuraName = SPELL_AURA_ADD_PCT_MODIFIER;
        info->Effects[1].BasePoints = -101;
        info->Effects[2].ApplyAuraName = SPELL_AURA_FEATHER_FALL;
    }
    if (id == 800355)
    {
        info->SchoolMask = SPELL_SCHOOL_MASK_FIRE | SPELL_SCHOOL_MASK_SHADOW;
        info->Effects[1].Amplitude = uint32(std::max(1, info->GetDuration()));
        info->AttributesEx5 &= ~SPELL_ATTR5_EXTRA_INITIAL_PERIOD;
    }
    if (id == 807727)
    {
        dummy(1);
        info->Effects[2].Effect = SPELL_EFFECT_APPLY_AURA;
        info->Effects[2].ApplyAuraName = SPELL_AURA_SCHOOL_ABSORB;
        info->Effects[2].MiscValue = SPELL_SCHOOL_MASK_NORMAL;
        info->Effects[2].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
    }
    if (id == 804823)
        dummy(0);
    if (id == 807942)
    {
        info->Effects[0].Effect = SPELL_EFFECT_DUMMY;
        info->Effects[0].ApplyAuraName = SPELL_AURA_NONE;
    }
    if (id == 706818)
    {
        dummy(0), dummy(1);
        info->DurationEntry = sSpellDurationStore.LookupEntry(1);
    }
    if (id == 712483)
        dummy(0);
    if (id == 707902)
        info->ProcCharges = 0;
    if (id == 707901)
        dummy(0);
    if (Named(info, 801895))
        info->AscensionIgnoreAbsorb = true;
    if (Named(info, 704368))
        for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
            if (info->Effects[i].TriggerSpell == 803717)
                periodic(i, info->Effects[i].Amplitude);
    if (id >= 552210 && id <= 552213)
    {
        periodic(0, 2000);
        info->Effects[2].Effect = 0;
    }
    if (id == 705121)
    {
        info->Effects[0].Effect = SPELL_EFFECT_DUMMY;
        info->Effects[0].ApplyAuraName = SPELL_AURA_NONE;
        info->Effects[0].TriggerSpell = 0;
    }
    if (id == 712399)
    {
        info->AttributesCu |= SPELL_ATTR0_CU_SHARE_DAMAGE;
        info->Effects[1].Effect = 0;
    }
    if (id == 560284)
        info->Effects[2].Effect = 0;
    if (id == 520832)
        for (uint8 i : { EFFECT_0, EFFECT_2 })
        {
            info->Effects[i].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY);
            info->Effects[i].TargetB = SpellImplicitTargetInfo();
        }
    if (id == 555742)
        info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
    if (id == 805235 || id == 807590)
        info->AuraInterruptFlags |= AURA_INTERRUPT_FLAG_TAKE_DAMAGE;
    if (id == Unphased)
    {
        info->Effects[1].ApplyAuraName = SPELL_AURA_REDUCE_PUSHBACK;
        info->Effects[1].MiscValue = 0;
        info->Effects[1].SpellClassMask = flag96(0, 0, 0);
    }
    info->_InitializeExplicitTargetMask();
}
}

namespace
{
float AttackPowerCoefficient(uint32 spell, uint8 effect)
{
    float coefficient = 0.0f;
    for (auto const& row : FelswornCoefficients)
        if (row.spell == spell && row.effect == effect)
            coefficient += row.ap;
    return coefficient;
}
int32 VictimAttackPower(Unit const* victim, uint32 spell, uint8 effect)
{
    float const coefficient = AttackPowerCoefficient(spell, effect);
    if (coefficient <= 0.0f)
        return 0;
    return int32(coefficient * victim->GetTotalAuraModifier(SPELL_AURA_MELEE_ATTACK_POWER_ATTACKER_BONUS));
}
template <typename Bonus>
int32 Share(Bonus bonus, int32 amount)
{
    if (!amount)
        return 0;
    uint32 const size = uint32(std::abs(amount));
    int32 const share = std::max(0, int32(bonus(2 * size)) - int32(bonus(size)));
    return amount < 0 ? -share : share;
}
WeaponAttackType SpellAttackType(SpellInfo const* info)
{
    switch (info->DmgClass)
    {
        case SPELL_DAMAGE_CLASS_MELEE:
            return info->HasAttribute(SPELL_ATTR3_REQUIRES_OFF_HAND_WEAPON) ? OFF_ATTACK : BASE_ATTACK;
        case SPELL_DAMAGE_CLASS_RANGED:
            return info->IsRangedWeaponSpell() ? RANGED_ATTACK : BASE_ATTACK;
        default:
            return info->HasAttribute(SPELL_ATTR2_AUTO_REPEAT) ? RANGED_ATTACK : BASE_ATTACK;
    }
}
UnitMods WeaponDamageMod(WeaponAttackType attack)
{
    switch (attack)
    {
        case OFF_ATTACK:
            return UNIT_MOD_DAMAGE_OFFHAND;
        case RANGED_ATTACK:
            return UNIT_MOD_DAMAGE_RANGED;
        default:
            return UNIT_MOD_DAMAGE_MAINHAND;
    }
}
std::pair<int32, int32> DirectShares(Unit* caster, Unit* target, SpellInfo const* info, uint8 effect, int32 raw)
{
    SpellSchoolMask const school = info->GetSchoolMask();
    if (info->Effects[effect].Effect == SPELL_EFFECT_NORMALIZED_WEAPON_DMG)
    {
        WeaponAttackType const attack = SpellAttackType(info);
        if (school & SPELL_SCHOOL_MASK_NORMAL)
            raw = int32(raw * caster->GetPctModifierValue(WeaponDamageMod(attack), TOTAL_PCT));
        int32 const done = Share([&](uint32 amount)
            { return caster->MeleeDamageBonusDone(target, amount, attack, info, school); }, raw);
        int32 const taken = Share([&](uint32 amount)
            { return target->MeleeDamageBonusTaken(caster, amount, attack, info, school); }, done);
        return {done, taken};
    }
    int32 const done = Share([&](uint32 amount)
        { return caster->SpellDamageBonusDone(target, info, amount, SPELL_DIRECT_DAMAGE, effect); }, raw);
    int32 const taken = Share([&](uint32 amount)
        { return target->SpellDamageBonusTaken(caster, info, amount, SPELL_DIRECT_DAMAGE); }, done);
    return {done, taken};
}
int32 AreaShare(Spell* spell, Unit* target, uint8 effect, int32 taken)
{
    SpellInfo const* info = spell->GetSpellInfo();
    SpellEffectInfo const& data = info->Effects[effect];
    if (!taken || !(data.IsAreaAuraEffect() || data.IsTargetingArea() ||
                    (data.ChainTarget > 1 && info->DmgClass != SPELL_DAMAGE_CLASS_MAGIC)))
        return taken;
    Unit* caster = spell->GetCaster();
    bool const npcCaster = !caster->IsControlledByPlayer() || info->HasAttribute(SPELL_ATTR7_TREAT_AS_NPC_AOE);
    taken = target->CalculateAOEDamageReduction(taken, info->SchoolMask, npcCaster);
    int32 const targets = int32(spell->GetUniqueTargetInfo()->size());
    if (caster->IsPlayer() && targets > 10)
        taken = taken * 10 / targets;
    return taken;
}
int32 TriggeringAuraAttackPower(Spell* spell, Unit* target)
{
    SpellInfo const* aura = spell->GetTriggeredByAuraSpellInfo();
    if (!aura)
        return 0;
    for (uint8 i = EFFECT_0; i < MAX_SPELL_EFFECTS; ++i)
        if (aura->Effects[i].ApplyAuraName == SPELL_AURA_PERIODIC_TRIGGER_SPELL_WITH_VALUE &&
            aura->Effects[i].TriggerSpell == spell->GetSpellInfo()->Id)
            return VictimAttackPower(target, aura->Id, i);
    return 0;
}
int32 LeechAttackPower(Unit* target, Unit* attacker, SpellInfo const* info)
{
    int32 share = 0;
    for (uint8 i = EFFECT_0; i < MAX_SPELL_EFFECTS; ++i)
        if (info->Effects[i].Effect == SPELL_EFFECT_HEALTH_LEECH)
            if (int32 const raw = VictimAttackPower(target, info->Id, i))
                share += DirectShares(attacker, target, info, i, raw).second;
    return share;
}
int32 AreaPeriodicAttackPower(Unit const* target, SpellInfo const* info)
{
    for (uint8 i = EFFECT_0; i < MAX_SPELL_EFFECTS; ++i)
        if (info->Effects[i].Effect == SPELL_EFFECT_PERSISTENT_AREA_AURA &&
            info->Effects[i].ApplyAuraName == SPELL_AURA_PERIODIC_DAMAGE)
            return VictimAttackPower(target, info->Id, i);
    return 0;
}
}

void AscensionFelsworn::AddVictimAttackPower(Spell* spell, Unit* target, TargetInfo& hit)
{
    Unit* caster = spell->GetCaster();
    SpellInfo const* info = spell->GetSpellInfo();
    if (!Owner(caster) || !target || target == caster || hit.damage <= 0 || hit.missCondition != SPELL_MISS_NONE)
        return;
    for (uint8 i = EFFECT_0; i < MAX_SPELL_EFFECTS; ++i)
    {
        uint32 const effect = info->Effects[i].Effect;
        if (!(hit.effectMask & (1 << i)) ||
            (effect != SPELL_EFFECT_SCHOOL_DAMAGE && effect != SPELL_EFFECT_NORMALIZED_WEAPON_DMG))
            continue;
        int32 raw = VictimAttackPower(target, info->Id, i);
        if (!raw && i == EFFECT_0)
            raw = TriggeringAuraAttackPower(spell, target);
        if (!raw)
            continue;
        auto const [done, taken] = DirectShares(caster, target, info, i, raw);
        hit.damageBeforeTakenMods = std::max(0, hit.damageBeforeTakenMods + done);
        hit.damage = std::max(0, hit.damage + AreaShare(spell, target, i, taken));
    }
}

namespace
{
using namespace AscensionFelsworn;
float Shadowflame(Player* player)
{
    return float(std::max(player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_FIRE),
                          player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW)));
}
constexpr uint32 BANE_OF_CHAOS_RANK_7 = 706420;
void GrantBaneOfChaosPeriodicCrit(Unit* target, Aura* aura)
{
    if (aura->GetId() != BANE_OF_CHAOS_RANK_7)
        return;
    Unit* caster = aura->GetCaster();
    AuraEffect* effect = aura->GetEffect(EFFECT_0);
    if (!caster || !effect || effect->GetAuraType() != SPELL_AURA_PERIODIC_DAMAGE)
        return;
    SpellInfo const* info = aura->GetSpellInfo();
    float chance = caster->SpellDoneCritChance(nullptr, info, info->GetSchoolMask(), BASE_ATTACK, true);
    if (chance > 0.0f)
        chance = target->SpellTakenCritChance(caster, info, info->GetSchoolMask(), chance, BASE_ATTACK, true);
    effect->SetCritChance(std::max(0.0f, chance));
}
class felsworn_scaling : public UnitScript
{
  public:
    felsworn_scaling()
        : UnitScript("felsworn_scaling", true,
                     {UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE, UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN,
                      UNITHOOK_MODIFY_MELEE_DAMAGE, UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK,
                      UNITHOOK_ON_BEFORE_ROLL_MELEE_OUTCOME_AGAINST, UNITHOOK_ON_AURA_APPLY})
    {
    }
    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        if (unit && aura)
            GrantBaneOfChaosPeriodicCrit(unit, aura);
    }
    void ModifySpellEffectBaseValue(Unit const* caster, SpellInfo const* info, uint8 index, float& value) override
    {
        Player* player = Owner(caster);
        if (!player || !info)
            return;
        for (auto const& row : FelswornCoefficients)
            if (row.spell == info->Id && row.effect == index)
            {
                float sp = row.school == 36 ? Shadowflame(player)
                                            : float(player->SpellBaseDamageBonusDone(SpellSchoolMask(row.school)));
                value += row.ap * player->GetTotalAttackPowerValue(BASE_ATTACK) + row.sp * std::max(0.0f, sp) +
                         row.stamina * player->GetStat(STAT_STAMINA) + row.agility * player->GetStat(STAT_AGILITY);
            }
        if (info->Id == 520832 && index == 0 && info->Effects[EFFECT_0].Amplitude > 0)
            value /= float(std::max(1, info->GetMaxDuration() / int32(info->Effects[EFFECT_0].Amplitude)));
        if (Named(info, 801895) && index == 0)
        {
            float fire = float(std::max(0, player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_FIRE)));
            float shadow = float(std::max(0, player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW)));
            value += fire > shadow ? fire : shadow * 1.32f;
        }
        if (info->Id == 805248 && index == 0)
            value = 2.0f * player->GetStat(STAT_STAMINA);
        if (info->Id == 804809 && index == 0)
            value = player->GetStat(STAT_SPIRIT);
        if (info->Id == 500531)
            value = player->GetTotalAttackPowerValue(BASE_ATTACK) * (index == 0 ? .5f : .05f);
        if (player->HasAura(574146) && index == 0 && (Named(info, 801312) || Named(info, 802060) || Twin(info)))
            value += player->GetStat(STAT_AGILITY) * .20f;
        if (player->HasAura(574145) && index == 0 && (Named(info, 802060) || Twin(info)))
            value += player->GetStat(STAT_AGILITY) * .15f;
        if (Named(info, 705129) && index == 0 && player->HasAura(803478))
            value += player->GetMaxHealth() * .10f;
        if ((info->Id == 520252 || info->Id == 520253) && !Inner(player))
            value = 0;
        if (info->Id == 804825 && index == EFFECT_0)
            AddPct(value, State(player).resolvePct);
        value = std::clamp(value, float(INT32_MIN / 2), float(INT32_MAX / 2));
    }
    static float DamageFactor(Unit* target, Unit* attacker, uint32 school, SpellInfo const* info)
    {
        float factor = 1;
        if (Player* player = Owner(target); player && player->HasAura(300470) && player->GetHealthPct() > 75)
            factor *= .95f;
        if (Player* player = Owner(attacker))
        {
            if (target && target->IsCreature() && !target->IsControlledByPlayer() && player->HasAura(807727))
                factor *= .90f;
            if (player->HasAura(300470) && player->GetHealthPct() > 75)
                factor *= 1.05f;
            if (target && (school & SPELL_SCHOOL_MASK_FIRE) && target->HasAura(707901, player->GetGUID()))
                factor *= 1.20f;
            if (target && info && player->HasAura(520833) && Named(info, 802060) && target->GetHealthPct() > 75)
                factor *= 1.25f;
            if (target && info && player->HasAura(804610) && target->HasAuraType(SPELL_AURA_MOD_DECREASE_SPEED) &&
                (Named(info, 801904) || Named(info, 801903) || Twin(info) || info->Id == 520262 || info->Id == 572585))
                factor *= 1.15f;
        }
        return factor;
    }
    void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& damage, SpellInfo const* info) override
    {
        if (info && target && target != attacker && Owner(attacker))
            damage = std::max(0, damage + LeechAttackPower(target, attacker, info));
        if (info && !info->HasAttribute(SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS))
            damage = int32(damage * DamageFactor(target, attacker, info->SchoolMask, info));
    }
    void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& damage) override
    {
        damage = uint32(damage * DamageFactor(target, attacker, SPELL_SCHOOL_MASK_NORMAL, nullptr));
    }
    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& damage, SpellInfo const* info) override
    {
        if (info && target && target != attacker && Owner(attacker))
            damage = uint32(std::max(0, int32(damage) + AreaPeriodicAttackPower(target, info)));
        if (info && !info->HasAttribute(SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS))
            damage = uint32(damage * DamageFactor(target, attacker, info->SchoolMask, info));
    }
    void OnBeforeRollMeleeOutcomeAgainst(Unit const* attacker, Unit const*, WeaponAttackType, int32&, int32&, int32&,
                                         int32&, int32& crit, int32&, int32&, int32&, int32&) override
    {
        if (Player* player = Owner(attacker); player && player->HasAura(803904))
            crit = 10000;
    }
};
}
void AddSC_AscensionFelswornContracts()
{
    new felsworn_scaling();
}
