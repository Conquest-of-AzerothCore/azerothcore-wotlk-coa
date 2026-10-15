/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionStarcaller.h"
#include "AscensionStarcallerData.h"
#include "DBCStores.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include <algorithm>
namespace AscensionStarcaller
{
void ApplyContracts(SpellInfo* info)
{
    if (!info || info->SpellFamilyName != 32)
        return;
    uint32 id = info->Id;
    if (id == 680805 && info->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_ADD_PCT_MODIFIER &&
        info->Effects[EFFECT_0].MiscValue == SPELLMOD_BONUS_MULTIPLIER &&
        info->Effects[EFFECT_0].SpellClassMask == flag96(0, 4096, 0))
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_ADD_FLAT_MODIFIER;
    auto dummy = [info](uint8 slot) {
        info->Effects[slot].ApplyAuraName = SPELL_AURA_DUMMY;
        info->Effects[slot].TriggerSpell = 0;
    };
    auto mod = [info](uint8 slot, AuraType type, int32 value, uint32 operation, flag96 mask) {
        auto& e = info->Effects[slot];
        e.Effect = SPELL_EFFECT_APPLY_AURA;
        e.ApplyAuraName = type;
        e.BasePoints = value - 1;
        e.DieSides = 1;
        e.MiscValue = operation;
        e.SpellClassMask = mask;
        e.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
        e.TargetB = SpellImplicitTargetInfo();
        e.TriggerSpell = 0;
    };
    for (auto const& list : {std::pair(StarcallerEvents, std::size(StarcallerEvents)),
                             std::pair(StarcallerDrivers, std::size(StarcallerDrivers))})
        for (size_t n = 0; n < list.second; ++n)
            if (list.first[n] == id)
            {
                for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
                    if (info->Effects[i].ApplyAuraName == 42 || info->Effects[i].ApplyAuraName == 354)
                        dummy(i);
                info->ProcFlags = 0;
                info->ProcCharges = 0;
            }
    for (auto const& row : StarcallerCosts)
        if (row.spell == id)
        {
            info->PowerType = POWER_MANA;
            info->UsesMaxManaForCost = true;
            info->ManaCost = 0;
            info->ManaCostPercentage = row.percent;
        }
    if (Named(info, 520590))
    {
        info->RecoveryTime = 0;
        info->CategoryRecoveryTime = 0;
    }
    for (uint32 sid : StarcallerCopies)
        if (id == sid)
        {
            info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
            info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
            info->AttributesEx4 |= SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS;
            info->AttributesCu |= SPELL_ATTR0_CU_IGNORE_ARMOR;
            info->Effects[0].TargetA = SpellImplicitTargetInfo(id == 524703 || id == 804736 ? TARGET_UNIT_TARGET_ALLY
                                                                                            : TARGET_UNIT_TARGET_ENEMY);
            info->Effects[0].TargetB = SpellImplicitTargetInfo();
        }
    if (id == 524781)
    {
        info->Effects[0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[0].TriggerSpell = 0;
        dummy(1);
    }
    if (id == 524643)
        info->SpellFamilyFlags[1] |= 0x40;
    if (id == 706301)
        dummy(0);
    if (id == 800386)
    {
        mod(0, SPELL_AURA_ADD_PCT_MODIFIER, -100, SPELLMOD_CASTING_TIME, flag96(537133056, 8, 0));
        mod(2, SPELL_AURA_ADD_PCT_MODIFIER, 100, SPELLMOD_COST, flag96(536870912, 0, 0));
    }
    if (id == 503583)
    {
        mod(1, SPELL_AURA_ADD_PCT_MODIFIER, -10, SPELLMOD_COST, flag96(0, 268435456, 0));
    }
    if (id == 802985)
    {
        dummy(0);
        info->StackAmount = 4;
    }
    if (id == 804716)
    {
        info->Effects[0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[0].TriggerSpell = 0;
    }
    if (id == 804995)
        info->Effects[1].Effect = info->Effects[2].Effect = 0;
    if (id == 801129 || id == 804736)
        info->Effects[1].Effect = 0;
    if (id == 800510 || id == 803887 || id == 803888)
        dummy(1);
    if (id == 805524)
        dummy(0), dummy(2);
    if (id == 574360)
        dummy(0), dummy(1);
    if (id == 804378)
        dummy(1);
    if (id == 801401 || id == 704232 || id == 560634)
        for (auto& e : info->Effects)
            if (e.Effect)
            {
                e.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
                e.TargetB = SpellImplicitTargetInfo();
            }
    if (id == 680774)
        info->MaxAffectedTargets = 0;
    if (id == 92133)
        info->Effects[0].BasePoints = 7;
    if (id == 92132 || id == 574349)
        dummy(id == 92132 ? 2 : 0);
    if (id == 100250 || id == 801148 || id == 706436)
        info->DurationEntry = sSpellDurationStore.LookupEntry(21);
    if (id == 704787)
    {
        info->Effects[1].MiscValue = 127;
        dummy(2);
    }
    if (id == 500206)
    {
        info->Effects[1].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[1].TriggerSpell = 0;
    }
    if (id == 800393 || id == 800394)
        dummy(2);
    if (id == 800394)
    {
        info->Effects[1].MiscValue = SPELLMOD_COST;
        info->Effects[1].SpellClassMask = flag96(0, 0x40000, 0);
    }
    if (id == 680822)
    {
        info->Effects[1].ApplyAuraName = SPELL_AURA_MOD_TOTAL_STAT_PERCENTAGE;
        info->Effects[2].Effect = 0;
    }
    if (id == 680847)
        dummy(0);
    if (id == 704772)
    {
        dummy(0);
        info->AuraInterruptFlags &= ~(AURA_INTERRUPT_FLAG_CAST | AURA_INTERRUPT_FLAG_SPELL_ATTACK);
        info->Effects[2].ApplyAuraName = SPELL_AURA_MECHANIC_IMMUNITY;
        info->Effects[2].MiscValue = MECHANIC_SNARE;
    }
    if (Named(info, 800505))
    {
        auto& effect = info->Effects[2];
        effect.Effect = SPELL_EFFECT_APPLY_AURA;
        effect.ApplyAuraName = SPELL_AURA_FORCE_MOVE_FORWARD;
        effect.BasePoints = 49;
        effect.DieSides = 1;
        effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
        effect.TargetB = SpellImplicitTargetInfo();
    }
    if (id == 805546)
        info->AuraInterruptFlags |= AURA_INTERRUPT_FLAG_TAKE_DAMAGE;
    if (id == 680705)
    {
        info->Effects[0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[0].Amplitude = 250;
    }
    if (id == 680821)
        dummy(2);
    if (id == 704171)
        dummy(0), info->Effects[1].Effect = 0;
    if (id == 801243)
        mod(0, SPELL_AURA_ADD_PCT_MODIFIER, -100, SPELLMOD_COST, flag96(0, 0, 2097152));
    if (id == 561046)
    {
        dummy(0);
        mod(2, SPELL_AURA_ADD_PCT_MODIFIER, -100, SPELLMOD_COST, flag96(0, 1048576, 512));
    }
    if (id == 561022)
        dummy(0), dummy(1);
    if (id == 561096)
    {
        info->DurationEntry = sSpellDurationStore.LookupEntry(21);
        for (uint8 i = 0; i < 2; ++i)
        {
            auto& e = info->Effects[i];
            e.Effect = SPELL_EFFECT_APPLY_AURA;
            e.ApplyAuraName = i ? SPELL_AURA_MOD_SPELL_HIT_CHANCE : SPELL_AURA_MOD_HIT_CHANCE;
            e.BasePoints = 2;
            e.DieSides = 1;
            e.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
            e.TargetB = SpellImplicitTargetInfo();
        }
    }
    if (id == 536216)
        mod(1, SPELL_AURA_ADD_PCT_MODIFIER, -30, SPELLMOD_COST, flag96(0, 131072, 0));
    if (Any(info, {680223, 572221}))
    {
        int32 value = std::abs(info->Effects[0].BasePoints + 1);
        mod(0, SPELL_AURA_ADD_PCT_MODIFIER, value, SPELLMOD_DAMAGE, flag96(1024, 1572864, 512));
        mod(1, SPELL_AURA_ADD_PCT_MODIFIER, -value, SPELLMOD_COST, flag96(1024, 1048576, 512));
    }
    if (Any(info, {704603, 704605}))
        info->Effects[0].SpellClassMask = flag96(0, 67239936, 2097152);
    if (id == 680779)
        mod(0, SPELL_AURA_ADD_PCT_MODIFIER, 20, SPELLMOD_DAMAGE, flag96(0, 1073872896, 0));
    if (id == 680770 || id == 704788)
        dummy(0);
    if (Any(info, {804385, 807936}))
        info->Effects[0].MiscValue = SPELLMOD_DURATION, info->Effects[1].Effect = 0;
    if (id == 300995 || id == 504003)
        dummy(0);
    if (id == 504694)
    {
        dummy(0);
        mod(1, SPELL_AURA_ADD_FLAT_MODIFIER, 10, SPELLMOD_CRITICAL_CHANCE, flag96(0, 2048, 134217728));
        dummy(2);
    }
    if (id == 680791)
        info->Effects[1].ApplyAuraName = SPELL_AURA_ADD_FLAT_MODIFIER;
    if (id == 681521)
        info->Effects[0].ApplyAuraName = SPELL_AURA_ADD_FLAT_MODIFIER;
    if (id == 520481 || id == 520482)
        dummy(0);
    if (id == 807659)
        dummy(0);
    if (id == 707751 || id == 561062)
        dummy(0), dummy(1);
    if (id == 801975)
        dummy(0);
    if (id == 524638)
        info->Effects[0].MiscValue = SPELLMOD_EFFECT2;
    if (id == 807195)
        info->AuraInterruptFlags |= AURA_INTERRUPT_FLAG_TAKE_DAMAGE;
    if (id == 570231)
    {
        dummy(1);
        info->ProcCharges = 0;
        info->ProcFlags = 0;
    }
    if (id == 954791)
    {
        info->Effects[0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
        info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
    }
    if (id == 561122)
        info->DurationEntry = sSpellDurationStore.LookupEntry(1);
    if (id == 680213 || id == 300256)
    {
        info->Effects[0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[0].TriggerSpell = 0;
        info->Effects[0].Amplitude = id == 680213 ? 499 : 1000;
    }
    if (id == 572319)
        dummy(0), dummy(1);
    if (id == 560634)
        dummy(0), dummy(1), dummy(2);
    if (id == 520422)
    {
        info->Effects[0].TargetA = SpellImplicitTargetInfo(TARGET_DEST_TARGET_ENEMY);
        info->Effects[0].TargetB = SpellImplicitTargetInfo(TARGET_UNIT_DEST_AREA_ENEMY);
        info->Effects[0].RadiusEntry = info->Effects[2].RadiusEntry;
        info->Effects[2].Effect = 0;
    }
    if (id == 807992)
    {
        info->Effects[0].Effect = SPELL_EFFECT_APPLY_AURA;
        info->Effects[0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY);
        info->Effects[0].TargetB = SpellImplicitTargetInfo();
    }
    for (uint32 sid : {801148, 100250, 680790, 706436})
        if (id == sid)
            info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
    info->_InitializeExplicitTargetMask();
}
}
namespace
{
using namespace AscensionStarcaller;
enum StarfireSpells : uint32
{
    SPELL_STARFIRE_SHOT = 801978,
    SPELL_STARFIRE_FLAT_DAMAGE = 801977
};

class starcaller_scaling : public UnitScript
{
  public:
    starcaller_scaling()
        : UnitScript("starcaller_scaling", true,
                     {UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE, UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN,
                      UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK, UNITHOOK_MODIFY_HEAL_RECEIVED,
                      UNITHOOK_MODIFY_MELEE_DAMAGE})
    {
    }
    void ModifySpellEffectBaseValue(Unit const* caster, SpellInfo const* info, uint8 index, float& value) override
    {
        Player* player = Owner(caster);
        if (!player || !info)
            return;
        if (index == EFFECT_0 && Named(info, SPELL_STARFIRE_SHOT))
            value = float(Amount(SPELL_STARFIRE_FLAT_DAMAGE, EFFECT_0, player));
        for (auto const& row : StarcallerCoefficients)
            if (row.spell == info->Id && row.effect == index)
            {
                float healing = row.healing * player->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_ARCANE);
                if (player->HasAura(300995) && Any(info, {800370, 575039, 801401}))
                    healing *= 1.2f;
                value += row.sp * std::max(0, player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_ARCANE)) +
                         row.ap * player->GetTotalAttackPowerValue(BASE_ATTACK) +
                         row.rap * player->GetTotalAttackPowerValue(RANGED_ATTACK) +
                         row.intellect * player->GetStat(STAT_INTELLECT) + row.mana * player->GetMaxPower(POWER_MANA) +
                         healing;
            }
        if (info->Id == 100250 && !index)
            value = player->GetMaxPower(POWER_MANA) * .1f;
        if (info->Id == 801148)
            value = player->GetPower(POWER_MANA) * (index == 2 ? .02f : .005f);
        if (info->Id == 805433 && !index)
            value = float(player->GetMaxPower(POWER_MANA));
        if (info->Id == 574327 && !index)
            value = player->GetPower(POWER_MANA) * .25f;
        if (info->Id == 807816 && !index)
            value = 10;
        if (info->Id == 805436 && !index)
            value += player->GetStat(STAT_INTELLECT) * .1f;
        if (info->Id == 801996 && !index)
            value += player->GetShieldBlockValue() * .5f;
        if (info->Id == 805006 && !index)
            value *= 1 + State(player).chargeDistance / 100.0f;
        value = std::clamp(value, float(INT32_MIN / 2), float(INT32_MAX / 2));
    }
    float Factor(Unit* target, Unit* caster, SpellInfo const* info)
    {
        Player* player = Owner(caster);
        if (!player || !target || Derived(info))
            return 1;
        if (player->GetDistance(target) > 30)
            for (uint32 rank : {704770u, 704769u})
                if (player->HasAura(rank))
                    return 1 + Amount(rank, 1) / 100.0f;
        return 1;
    }
    void ModifySpellDamageTaken(Unit* target, Unit* caster, int32& damage, SpellInfo const* info) override
    {
        damage = int32(damage * Factor(target, caster, info));
    }
    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* caster, uint32& damage, SpellInfo const* info) override
    {
        damage = uint32(damage * Factor(target, caster, info));
    }
    void ModifyMeleeDamage(Unit* target, Unit* caster, uint32& damage) override
    {
        damage = uint32(damage * Factor(target, caster, nullptr));
    }
    void ModifyHealReceived(Unit* target, Unit* caster, uint32& heal, SpellInfo const* info) override
    {
        Player* player = Owner(caster);
        if (!player || !target || Derived(info))
            return;
        float factor = 1;
        if (player->HasAura(801989) && target->GetHealthPct() < 20)
            factor *= 1.3f;
        Aura* aura = player->GetAura(704757);
        if (!aura)
            aura = player->GetAura(704756);
        if (aura)
            for (auto const& pair : target->GetAppliedAuras())
                if (pair.second->GetBase()->GetSpellInfo()->Dispel == DISPEL_POISON ||
                    pair.second->GetBase()->GetSpellInfo()->Dispel == DISPEL_DISEASE)
                {
                    factor *= 1 + Amount(aura->GetId(), 1) / 100.0f;
                    break;
                }
        heal = uint32(heal * factor);
    }
};
}
void AddSC_AscensionStarcallerContracts()
{
    new starcaller_scaling();
}
