/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionSunCleric.h"
#include "AscensionSunClericData.h"
#include "AscensionClientSpellPatches.h"
#include "DBCStores.h"
#include "DynamicObject.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include <algorithm>
namespace AscensionSunCleric
{
constexpr uint32 SpellRangeAnywhere = 13;
constexpr uint32 SunDownDuration = 39;
constexpr uint32 SunwellVisual = 560124;
void ApplyContracts(SpellInfo* info)
{
    if (!info || info->SpellFamilyName != 33)
        return;
    uint32 id = info->Id;
    if (id == SunwellVisual)
        info->AttributesCu |= SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED;
    if (id == 800624)
        info->AttributesEx &= ~SPELL_ATTR1_NO_THREAT;
    if (id == Rejuvenating)
        for (auto& effect : info->Effects)
            if (effect.IsAura())
            {
                effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
                effect.TargetB = SpellImplicitTargetInfo();
            }
    auto dummy = [info](uint8 slot)
    {
        info->Effects[slot].ApplyAuraName = SPELL_AURA_DUMMY;
        info->Effects[slot].TriggerSpell = 0;
    };
    auto aura = [info](uint8 slot, AuraType type, int32 amount, int32 misc, uint32 target)
    {
        auto& effect = info->Effects[slot];
        effect.Effect = SPELL_EFFECT_APPLY_AURA;
        effect.ApplyAuraName = type;
        effect.BasePoints = amount;
        effect.DieSides = 0;
        effect.MiscValue = misc;
        effect.TriggerSpell = 0;
        effect.TargetA = SpellImplicitTargetInfo(target);
        effect.TargetB = SpellImplicitTargetInfo();
    };
    for (auto list : {std::pair(SunClericEvents, std::size(SunClericEvents)),
                     std::pair(SunClericDrivers, std::size(SunClericDrivers)),
                     std::pair(SunClericFinite, std::size(SunClericFinite))})
        for (size_t n = 0; n < list.second; ++n)
            if (list.first[n] == id)
            {
                for (uint8 slot = 0; slot < MAX_SPELL_EFFECTS; ++slot)
                    if (info->Effects[slot].ApplyAuraName == SPELL_AURA_PROC_TRIGGER_SPELL ||
                        info->Effects[slot].ApplyAuraName == 354)
                        dummy(slot);
                info->ProcFlags = info->ProcCharges = 0;
            }
    for (uint32 copy : SunClericCopies)
        if (id == copy)
        {
            info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
            info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
            info->AttributesEx4 |= SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS;
            info->AttributesCu |= SPELL_ATTR0_CU_IGNORE_ARMOR;
            info->AscensionInheritsResolvedAmount = true;
            bool damage = id == 803490 || id == 803493 || id == 807853 || id == 707774 ||
                          id == 570147 || id == 807078 || id == 807215;
            info->Effects[0].TargetA = SpellImplicitTargetInfo(damage ? TARGET_UNIT_TARGET_ENEMY : TARGET_UNIT_TARGET_ALLY);
            info->Effects[0].TargetB = SpellImplicitTargetInfo();
            if (id == 707774)
                info->Effects[0].Effect = SPELL_EFFECT_SCHOOL_DAMAGE;
        }
    if (id == 807994)
        info->AttributesEx2 &= ~SPELL_ATTR2_CANT_CRIT;
    if (id == 300350)
        info->Attributes |= SPELL_ATTR0_PASSIVE;
    if (id == 807058)
    {
        info->Effects[0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY);
        info->RangeEntry = sSpellRangeStore.LookupEntry(SpellRangeAnywhere);
    }
    if (id == 704911)
    {
        info->Effects[0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
        info->Effects[0].TargetB = SpellImplicitTargetInfo();
    }
    if (id == DawnCast)
    {
        info->CasterAuraSpell = 0;
        info->ExcludeCasterAuraSpell = 0;
        Ascension::ClientSpellPatches::Instance().Register(id);
    }
    if (id == Dawn)
    {
        dummy(0);
        info->ProcCharges = 10;
        info->Attributes &= ~SPELL_ATTR0_AURA_IS_DEBUFF;
        info->Attributes &= ~SPELL_ATTR0_NO_AURA_CANCEL;
        info->AttributesCu &= ~SPELL_ATTR0_CU_NEGATIVE;
        Ascension::ClientSpellPatches::Instance().Register(id);
    }
    if (id == SolarPower)
        dummy(1);
    if (id == 800764)
    {
        info->Effects[1].Effect = SPELL_EFFECT_DUMMY;
        info->Effects[2].MiscValue = 10;
    }
    if (id == 803719)
        dummy(2);
    if (id == 807435)
        dummy(2);
    if (id == 807749)
    {
        dummy(0);
        dummy(1);
        info->Effects[2].ApplyAuraName = SPELL_AURA_MOD_CRIT_PCT;
    }
    if (id == 803492 || id == 807750 || id == 807751 || id == 807752 || id == 803500 || id == 807446 ||
        id == 805481 || id == 805491 || id == 681471)
        for (uint8 slot = 0; slot < MAX_SPELL_EFFECTS; ++slot)
            if (info->Effects[slot].Effect)
                dummy(slot);
    if (id == 803238)
    {
        aura(0, SPELL_AURA_DUMMY, 0, 0, TARGET_UNIT_CASTER);
        info->DurationEntry = sSpellDurationStore.LookupEntry(1);
    }
    if (id == 806118)
    {
        info->Effects[2].TargetA = SpellImplicitTargetInfo(TARGET_DEST_DEST);
        info->Effects[2].TargetB = SpellImplicitTargetInfo(TARGET_UNIT_DEST_AREA_ALLY);
    }
    if (id == 301242)
        info->Effects[0].SpellClassMask = flag96(0x8000, 0x40200, 0x4000);
    if (id == 680642)
        info->Effects[0].SpellClassMask = flag96(0, 512, 0);
    if (id == 300354)
        info->Effects[0].SpellClassMask = flag96(32768, 0, 0);
    if (id == 800722)
    {
        info->Effects[1].SpellClassMask = flag96(0, 512, 0);
        dummy(2);
    }
    if (id == 807299)
        for (auto& effect : info->Effects)
            effect.SpellClassMask = flag96(0, 2, 0);
    if (id == 301242)
        info->ProcCharges = 2;
    if (id == 301265)
        info->ProcCharges = 3;
    if (id == 560095)
        info->ProcCharges = 5;
    if (id == 680888)
        info->ProcCharges = 1;
    if (id == 503691)
    {
        info->Effects[0].Effect = SPELL_EFFECT_DUMMY;
        info->Effects[2].Effect = 0;
    }
    if (id == 681506 || id == 707517 || id == 300325 || id == 680618 || id == 806458)
        dummy(0);
    if (id == 300343)
    {
        dummy(0);
        dummy(1);
    }
    if (id == 707767)
        dummy(0);
    if (id == 804032 || id == 680650)
        dummy(1);
    if (id == 300353)
    {
        dummy(1);
        dummy(2);
    }
    if (id == 805816)
        dummy(0);
    if (id == 300723)
        aura(2, SPELL_AURA_MOD_DAMAGE_PERCENT_DONE, 30, SPELL_SCHOOL_MASK_HOLY | SPELL_SCHOOL_MASK_FIRE, TARGET_UNIT_CASTER);
    if (id == 707776)
    {
        aura(0, SPELL_AURA_MOD_SHIELD_BLOCKVALUE, 0, 0, TARGET_UNIT_CASTER);
        info->DurationEntry = sSpellDurationStore.LookupEntry(21);
    }
    if (id == 301006)
        info->DurationEntry = sSpellDurationStore.LookupEntry(21);
    if (id == 301368)
        info->Effects[1].Effect = 0;
    if (id == 800602)
        dummy(1);
    if (id == 300344)
    {
        dummy(0);
        dummy(1);
    }
    if (id == 704909)
    {
        dummy(1);
        aura(2, SPELL_AURA_MOD_HEALING_DONE_PERCENT, info->Effects[0].CalcValue(), 0, TARGET_UNIT_CASTER);
    }
    if (id == 807080)
        dummy(0);
    if (id == 680624)
        dummy(1);
    if (id == 520647)
        info->Effects[1].Effect = 0;
    if (id == 560347)
        aura(0, SPELL_AURA_SPLIT_DAMAGE_PCT, 30, SPELL_SCHOOL_MASK_ALL, TARGET_UNIT_TARGET_ALLY);
    if (id == 505340)
    {
        info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
        info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
        info->AttributesEx4 |= SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS;
        info->AscensionInheritsResolvedAmount = true;
    }
    if (Named(info, 500141))
        info->Effects[0].ChainTarget = 5;
    if (Named(info, 800231))
        for (auto& effect : info->Effects)
            if (effect.Effect == 168)
                effect.Effect = SPELL_EFFECT_DUMMY;
    if (id == 707768)
    {
        info->Effects[0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
        info->Effects[0].BasePoints = 9;
    }
    if (id == 520024 || id == 520026 || id == 807441 || id == 680630)
        for (auto& effect : info->Effects)
            if (effect.Effect)
                effect.Effect = SPELL_EFFECT_DUMMY;
    if (id == 680639)
        info->Effects[2].SpellClassMask = flag96(67108864, 0, 8388608);
    if (id == Bless)
    {
        info->AttributesEx5 &= ~SPELL_ATTR5_LIMIT_N;
        info->Effects[0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[0].TriggerSpell = 0;
        dummy(2);
    }
    if (id == 704926)
        info->Effects[1].Effect = SPELL_EFFECT_DUMMY;
    if (id == 804252)
        for (auto& effect : info->Effects)
            if (effect.Effect)
            {
                effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY);
                effect.TargetB = SpellImplicitTargetInfo();
            }
    for (uint32 talent : {561328,704585,805267,300314,707078,300363,300621,300626,300334,704935,680656})
        if (id == talent)
            for (uint8 slot = 0; slot < MAX_SPELL_EFFECTS; ++slot)
                if (info->Effects[slot].ApplyAuraName == SPELL_AURA_PERIODIC_TRIGGER_SPELL ||
                    info->Effects[slot].ApplyAuraName == SPELL_AURA_PERIODIC_TRIGGER_SPELL_WITH_VALUE)
                    dummy(slot);
    for (uint32 periodic : {300361,572752,704930,570125})
        if (id == periodic)
        {
            uint8 slot = id == 570125 ? 2 : 0;
            if (id == 570125 || id == 572752)
                aura(slot, SPELL_AURA_PERIODIC_DUMMY, 0, 0, TARGET_UNIT_TARGET_ENEMY);
            else
                info->Effects[slot].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
            info->Effects[slot].TriggerSpell = 0;
            if (id == 570125)
                info->Effects[slot].Amplitude = 500;
            if (id == 572752)
            {
                info->Effects[slot].Amplitude = 1900;
                info->DurationEntry = sSpellDurationStore.LookupEntry(SunDownDuration);
            }
        }
    info->_InitializeExplicitTargetMask();
}
}
namespace
{
using namespace AscensionSunCleric;
class sun_cleric_scaling : public UnitScript
{
public:
    sun_cleric_scaling() : UnitScript("sun_cleric_scaling", true,
        {UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE, UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN,
         UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK, UNITHOOK_MODIFY_MELEE_DAMAGE,
         UNITHOOK_ON_DAMAGE}) { }
    void ModifySpellEffectBaseValue(Unit const* caster, SpellInfo const* info, uint8 index, float& value) override
    {
        Player* player = Owner(caster);
        if (!player || !info || info->SpellFamilyName != 33 || Derived(info))
            return;
        SpellSchoolMask powerSchool = info->Id == 804752 ? SPELL_SCHOOL_MASK_HOLY : info->GetSchoolMask();
        for (auto const& row : SunClericCoefficients)
            if (row.spell == info->Id && row.effect == index)
                value += row.sp * std::max(0, player->SpellBaseDamageBonusDone(powerSchool)) +
                         row.ap * player->GetTotalAttackPowerValue(BASE_ATTACK) +
                         row.healing * std::max(0, player->SpellBaseHealingBonusDone(info->GetSchoolMask())) +
                         row.stamina * player->GetStat(STAT_STAMINA) + row.intellect * player->GetStat(STAT_INTELLECT) +
                         row.strength * player->GetStat(STAT_STRENGTH);
        if (Named(info, 500154) && !index && player->HasAura(680656))
            value += .25f * player->GetTotalAttackPowerValue(BASE_ATTACK);
        if (Named(info, 800654) && !index)
            value += player->GetShieldBlockValue();
        if (info->Id == 807064 && !index)
            value *= 1 + State(player).sunchargeStacks * .25f;
        if (idIsJustice(info) && index == 1)
        {
            value += .2f * (player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_FIRE) -
                            player->SpellBaseDamageBonusDone(info->GetSchoolMask()));
        }
        value = std::clamp(value, float(INT32_MIN / 2), float(INT32_MAX / 2));
    }
    bool idIsJustice(SpellInfo const* info)
    {
        return Any(info, {524857,525005,525006,525007,572849,572850,572040,572041,572042,572043,572044,572045});
    }
    float Factor(Unit* target, Unit* caster, SpellInfo const* info)
    {
        Player* player = Owner(caster);
        if (!player || !target || !info || info->SpellFamilyName != 33 || Derived(info))
            return 1;
        float factor = 1;
        if ((info->SchoolMask & SPELL_SCHOOL_MASK_FIRE) && player->HasAura(806458))
        {
            bool burning = false;
            for (auto const& pair : target->GetAppliedAuras())
                if (auto* aura = pair.second->GetBase(); aura->GetSpellInfo()->SchoolMask & SPELL_SCHOOL_MASK_FIRE)
                    if (aura->HasEffectType(SPELL_AURA_PERIODIC_DAMAGE))
                        burning = true;
            if (burning)
                factor *= 1 + Amount(806458) / 100.0f;
        }
        if (info->Id == 807058 && target->GetHealthPct() < 35 && player->HasAura(300325))
            factor *= 1 + Amount(300325) / 100.0f;
        return factor;
    }
    void ModifySpellDamageTaken(Unit* target, Unit* caster, int32& damage, SpellInfo const* info) override
    {
        damage = int32(damage * Factor(target, caster, info));
    }
    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* caster, uint32& damage, SpellInfo const* info) override
    {
        if (!info || !info->HasAura(SPELL_AURA_PERIODIC_HEAL))
            damage = uint32(damage * Factor(target, caster, info));
    }
    void ModifyMeleeDamage(Unit*, Unit* caster, uint32& damage) override
    {
        Player* player = Owner(caster);
        if (player == caster && player && player->HasAura(807749))
            AddPct(damage, Amount(807749, 1));
    }
    void OnDamage(Unit*, Unit* victim, uint32& damage) override
    {
        Player* player = Owner(victim);
        if (player && player == victim && player->HasAura(805816) &&
            int64(player->GetHealth()) - damage < int64(player->CountPctFromMaxHealth(35)))
            damage -= CalculatePct(damage, Amount(805816));
        if (player && player == victim && int64(player->GetHealth()) - damage < int64(player->CountPctFromMaxHealth(10)))
            if (DynamicObject* zone = player->GetDynObject(520647))
                zone->Remove();
    }
};
}
void AddSC_AscensionSunClericContracts()
{
    new sun_cleric_scaling();
}
