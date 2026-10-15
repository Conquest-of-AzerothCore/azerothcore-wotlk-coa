/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionPyromancer.h"
#include "AscensionPyromancerData.h"
#include "DBCStores.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include <algorithm>
#include <cmath>
namespace AscensionPyromancer
{
void ApplyContracts(SpellInfo* info)
{
    if (!info || info->SpellFamilyName != 30)
        return;
    uint32 id = info->Id;
    auto dummy = [info](uint8 slot)
    {
        info->Effects[slot].ApplyAuraName = SPELL_AURA_DUMMY;
        info->Effects[slot].TriggerSpell = 0;
    };
    auto mod = [info](uint8 slot, AuraType type, int32 value, uint32 operation, flag96 mask)
    {
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
    for (auto const& list : {std::pair(PyromancerEvents, std::size(PyromancerEvents)),
                             std::pair(PyromancerDrivers, std::size(PyromancerDrivers))})
        for (size_t n = 0; n < list.second; ++n)
            if (list.first[n] == id)
            {
                for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
                    if (info->Effects[i].ApplyAuraName == SPELL_AURA_PROC_TRIGGER_SPELL ||
                        info->Effects[i].ApplyAuraName == SPELL_AURA_PROC_TRIGGER_DAMAGE ||
                        info->Effects[i].ApplyAuraName == 347 || info->Effects[i].ApplyAuraName == 354)
                        dummy(i);
                info->ProcFlags = info->ProcCharges = 0;
            }
    for (uint32 copy : PyromancerCopies)
        if (id == copy)
        {
            info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
            info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
            info->AttributesEx4 |= SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS;
            info->AttributesCu |= SPELL_ATTR0_CU_IGNORE_ARMOR;
            info->AscensionInheritsResolvedAmount = id != 520826;
            bool helpful = id == 704274 || id == 707892 || id == 707595 || id == 807403;
            info->Effects[0].TargetA =
                SpellImplicitTargetInfo(helpful ? TARGET_UNIT_TARGET_ALLY : TARGET_UNIT_TARGET_ENEMY);
            info->Effects[0].TargetB = SpellImplicitTargetInfo();
        }
    if (id == 503864)
        info->Effects[0].Effect = SPELL_EFFECT_SCHOOL_DAMAGE;
    if (id == 520868)
        info->Effects[0].Effect = SPELL_EFFECT_DUMMY;
    if (id == 572806)
        info->Effects[1].Effect = info->Effects[2].Effect = 0;
    if (Named(info, 802174))
        info->Effects[1].Effect = info->Effects[2].Effect = 0;
    if (Named(info, 805500))
        dummy(1), dummy(2);
    if (Any(info, {800791, 706874}))
        dummy(1);
    if (id == 520927)
        dummy(1);
    if (id == 524707)
        info->ProcCharges = 3;
    if (id == 680962 || id == 807403 || id == 520826)
        for (uint8 slot = 1; slot < MAX_SPELL_EFFECTS; ++slot)
        {
            auto& effect = info->Effects[slot];
            effect.Effect = SPELL_EFFECT_APPLY_AURA;
            dummy(slot);
            effect.BasePoints = -1;
            effect.DieSides = 1;
            effect.Amplitude = 0;
            effect.SpellClassMask = flag96();
            effect.TargetA = info->Effects[0].TargetA;
            effect.TargetB = SpellImplicitTargetInfo();
        }
    if (id == 680367 || id == 681366)
    {
        info->Effects[id == 680367 ? 0 : 1].ApplyAuraName = SPELL_AURA_MOD_HEALING_DONE_PERCENT;
        if (id == 680367)
            info->Effects[1].Effect = 0;
    }
    if (id == 807402)
        info->Effects[1].Effect = 0;
    if (id == 680842)
        info->ExcludeTargetAuraSpell = 681265;
    if (id == 807768)
        info->Effects[0].Effect = SPELL_EFFECT_DUMMY;
    if (id == 802120 || id == 680369)
    {
        info->Effects[0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[0].TriggerSpell = 0;
    }
    if (id == 573220)
    {
        info->Effects[1].MiscValue = 21362;
    }
    if (id == 704853)
        info->Effects[0].ApplyAuraName = SPELL_AURA_ADD_FLAT_MODIFIER;
    if (id == 706650)
        dummy(0), info->Effects[0].BasePoints = 29;
    if (id == 706238)
        dummy(0), info->Effects[1].Effect = 0;
    if (id == 706877 || id == 706889 || id == 300751)
        dummy(0);
    if (id == 805474)
        dummy(0);
    if (id == 807542)
    {
        mod(0, SPELL_AURA_ADD_PCT_MODIFIER, 0, SPELLMOD_CASTING_TIME, flag96(2097152, 0, 0));
        info->StackAmount = 1;
    }
    if (id == 900755)
        info->DurationEntry = sSpellDurationStore.LookupEntry(21);
    if (id == 806783)
        info->Effects[0].SpellClassMask = flag96(2, 0, 1048576);
    if (id == 525059)
        info->Effects[1].SpellClassMask = flag96(0, 0, 2048);
    if (id == 520823)
    {
        info->Effects[1].Effect = 0;
        mod(1, SPELL_AURA_ADD_PCT_MODIFIER, -100, SPELLMOD_COST, flag96(134217728, 0, 8192));
    }
    if (id == 680387)
        dummy(1);
    if (id == 807944)
        for (uint8 i = 0; i < 2; ++i)
        {
            info->Effects[i].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
            info->Effects[i].TriggerSpell = 0;
            info->Effects[i].Amplitude = i ? 1000 : 5000;
        }
    if (id == 807540)
        info->Effects[1].Effect = 0;
    if (id == 680372)
        info->Effects[2].Effect = 0;
    if (id == 803380)
        info->Effects[0].Effect = 0;
    if (id == 706893)
        mod(1, SPELL_AURA_ADD_FLAT_MODIFIER, -500, SPELLMOD_DURATION, flag96(0, 0, 8388608));
    if (id == 807224)
        info->StackAmount = 5;
    if (id == 803712)
        info->StackAmount = 3;
    if (id == 707480 || id == 704823)
    {
        flag96 mask;
        for (uint32 root : {800792, 802174, 801915, 805500, 800818, 520019, 680369, 704278, 706854, 802791})
            if (SpellInfo const* spender = sSpellMgr->GetSpellInfo(root))
                mask |= spender->SpellFamilyFlags;
        info->Effects[0].SpellClassMask = mask;
    }
    if (id == 704277)
        info->DurationEntry = sSpellDurationStore.LookupEntry(1);
    if (id == 802173 || id == 520826 || id == 680370 || id == 680371)
    {
        info->AscensionIgnoreAbsorbAndResistance = true;
    }
    if (id == 680370 || id == 680371)
        info->Attributes |= SPELL_ATTR0_NO_IMMUNITIES;
    for (uint32 heal : {707110, 706856, 806742, 806743, 806749, 712482})
        if (id == heal)
        {
            info->Effects[0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
            info->Effects[0].TargetB = SpellImplicitTargetInfo();
        }
    if (id == 803704 || id == 680366)
    {
        info->Effects[0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY);
        info->Effects[0].TargetB = SpellImplicitTargetInfo();
    }
    if (id == 803704)
    {
        info->Effects[1].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY);
        info->Effects[1].TargetB = SpellImplicitTargetInfo();
    }
    info->_InitializeExplicitTargetMask();
}
}
namespace
{
using namespace AscensionPyromancer;
class pyromancer_scaling : public UnitScript
{
  public:
    pyromancer_scaling()
        : UnitScript("pyromancer_scaling", true,
                     {UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE, UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN,
                      UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK, UNITHOOK_MODIFY_HEAL_RECEIVED, UNITHOOK_ON_AURA_APPLY,
                      UNITHOOK_ON_PERIODIC_DAMAGE_RESULT})
    {
    }
    void ModifySpellEffectBaseValue(Unit const* caster, SpellInfo const* info, uint8 index, float& value) override
    {
        Player* player = Owner(caster);
        if (!player || !info)
            return;
        for (auto const& row : PyromancerCoefficients)
            if (row.spell == info->Id && row.effect == index)
            {
                float sp = row.sp;
                if (Any(info, {803950, 800790}))
                {
                    float percent = sp * 100;
                    player->ApplySpellMod(info->Id, SPELLMOD_BONUS_MULTIPLIER, percent);
                    sp = percent / 100;
                }
                value += sp * std::max(0, player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_FIRE)) +
                         row.spirit * player->GetStat(STAT_SPIRIT) +
                         row.healing * std::max(0, player->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_FIRE));
            }
        if ((info->Id == 680370 || info->Id == 680371) && !index)
            value *= 1 + State(player).ignis * Amount(680382) / 100.0f;
        value = std::clamp(value, float(INT32_MIN / 2), float(INT32_MAX / 2));
    }
    static float Cataclysmic(Player* player, Unit* target)
    {
        uint32 rank = 0;
        for (uint32 id : {807912, 807882, 804617})
            if (!rank && player->HasAura(id))
                rank = id;
        if (!rank)
            return 1;
        uint32 count = 0;
        for (auto const& pair : target->GetAppliedAuras())
        {
            Aura const* aura = pair.second->GetBase();
            if (aura->GetCasterGUID() == player->GetGUID() &&
                Any(aura->GetSpellInfo(), {805500, 800791, 680962, 706874}))
                ++count;
        }
        return std::pow(1 + Amount(rank, 0, player) / 100.0f, count);
    }
    float Factor(Unit* target, Unit* caster, SpellInfo const* info)
    {
        Player* player = Owner(caster);
        if (!player || !info || !target || Derived(info))
            return 1;
        float factor = 1;
        if (Any(info, {800792, 801915}) && player->HasAura(706889) && Burning(player, target))
            factor *= 1 + Amount(706889) / 100.0f;
        if (Named(info, 805500) && player->HasAura(706238) && target->GetHealthPct() < 35)
            factor *= 1 + Amount(706238) / 100.0f;
        if (Named(info, 800792) && player->HasAura(520884))
            factor *= 1 + Burning(player, target) * .15f;
        if (Named(info, 800790))
            factor *= Cataclysmic(player, target);
        return factor;
    }
    void ModifySpellDamageTaken(Unit* target, Unit* caster, int32& damage, SpellInfo const* info) override
    {
        damage = int32(damage * Factor(target, caster, info));
    }
    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* caster, uint32& damage, SpellInfo const* info) override
    {
        damage = uint32(damage * Factor(target, caster, info));
    }
    void ModifyHealReceived(Unit* target, Unit* caster, uint32& healing, SpellInfo const* info) override
    {
        Player* player = Owner(caster);
        if (!player || !target || !info || info->SpellFamilyName != 30 || Derived(info))
            return;
        if (Aura* aura = target->GetAura(805474, player->GetGUID()))
            AddPct(healing, aura->GetStackAmount() * Amount(805474));
    }
    void OnAuraApply(Unit* target, Aura* aura) override
    {
        Player* player = Owner(target);
        if (player == target && player && aura->GetSpellInfo()->HasAura(SPELL_AURA_MOD_STUN) && player->HasAura(524818))
            Cast(player, player, 524819);
    }
    void OnPeriodicDamageResult(Unit*, Unit* caster, uint32 damage, SpellInfo const* info) override
    {
        Player* player = Owner(caster);
        if (player && info && info->Id == 807540 && damage)
        {
            Resource(player, HeatAura, 1);
            Mana(player, (player->GetMaxPower(POWER_MANA) - player->GetPower(POWER_MANA)) * 2 / 100, 807402);
        }
    }
};
}
void AddSC_AscensionPyromancerContracts()
{
    new pyromancer_scaling();
}
