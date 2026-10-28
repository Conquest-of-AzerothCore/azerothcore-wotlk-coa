/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionFelsworn.h"
#include "AscensionFelswornData.h"
#include "DBCStores.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include <algorithm>

namespace AscensionFelsworn
{
void ApplyContracts(SpellInfo* info)
{
    if (!info)
        return;
    for (auto const& rift : FelswornRifts)
        if (info->Id == rift.spell)
            info->Effects[0].MiscValue = rift.entry;
    if (info->SpellFamilyName != 20)
        return;
    uint32 id = info->Id;
    if (id == MannorothFelfury)
        info->Effects[EFFECT_0].MiscValue = 6;
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
            info->AttributesEx4 |= SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS;
            info->AttributesCu |= SPELL_ATTR0_CU_IGNORE_ARMOR;
            info->ProcFlags = 0;
            info->Effects[0].TargetA = SpellImplicitTargetInfo(
                info->Effects[0].Effect == SPELL_EFFECT_HEAL ? TARGET_UNIT_CASTER : TARGET_UNIT_TARGET_ENEMY);
            info->Effects[0].TargetB = SpellImplicitTargetInfo();
            if (info->Effects[0].Effect == SPELL_EFFECT_HEALTH_LEECH)
                info->Effects[0].ValueMultiplier = 1;
        }
    if (id == 804216)
    {
        info->DurationEntry = sSpellDurationStore.LookupEntry(1);
        info->Effects[2].Effect = 0;
        info->StartRecoveryCategory = 133;
        info->StartRecoveryTime = 1000;
    }
    if (id == 803465 || id == 807421 || id == 807428 || id == 807426)
        for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
            if (info->Effects[i].Effect)
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
        info->Effects[1].BasePoints = id == 705109 ? 2 : 4;
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
        info->Effects[2].ApplyAuraName = SPELL_AURA_MECHANIC_IMMUNITY_MASK;
        info->Effects[2].MiscValue = IMMUNE_TO_MOVEMENT_IMPAIRMENT_AND_LOSS_CONTROL_MASK;
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
    if (id == 801902)
        info->Effects[0].MiscValue = SPELLMOD_COST;
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
    if (Named(info, 704368))
        for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
            if (info->Effects[i].TriggerSpell == 803717)
                periodic(i, 2000);
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
    {
        info->Effects[0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY);
        info->Effects[0].TargetB = SpellImplicitTargetInfo();
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
using namespace AscensionFelsworn;
float Shadowflame(Player* player)
{
    return float(std::max(player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_FIRE),
                          player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW)));
}
class felsworn_scaling : public UnitScript
{
  public:
    felsworn_scaling()
        : UnitScript("felsworn_scaling", true,
                     {UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE, UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN,
                      UNITHOOK_MODIFY_MELEE_DAMAGE, UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK,
                      UNITHOOK_ON_BEFORE_ROLL_MELEE_OUTCOME_AGAINST})
    {
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
        if (info && !info->HasAttribute(SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS))
            damage = int32(damage * DamageFactor(target, attacker, info->SchoolMask, info));
    }
    void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& damage) override
    {
        damage = uint32(damage * DamageFactor(target, attacker, SPELL_SCHOOL_MASK_NORMAL, nullptr));
    }
    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& damage, SpellInfo const* info) override
    {
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
