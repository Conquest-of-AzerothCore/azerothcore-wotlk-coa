/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionBossControlRolesPolicy.h"
#include "AscensionSpecialization.h"
#include "AscensionSpecLoot.h"
#include "ItemTemplate.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <array>

namespace
{
constexpr uint32 RuneOfMetamorphosis = 966348;
constexpr uint32 PhysicalRune = 966350;
constexpr uint32 CasterRune = 966351;
constexpr uint32 OwlkinKnowledge = 966352;
constexpr uint32 HealerRune = 966353;
constexpr uint32 TankRune = 966361;
constexpr uint32 TransformationVisual = 14140;
constexpr uint32 FirstArcaneInfusion = 909584;
constexpr uint32 FirstArcaneExplosion = 909588;
constexpr std::array<float, 4> ArcaneRangedCoefficients = {1.0f, 1.08f, 1.16f, 1.24f};
constexpr int32 ArcanePlayerDamagePct = 10;
constexpr uint32 DirectSpellProcFlags = PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS |
    PROC_FLAG_DONE_SPELL_RANGED_DMG_CLASS | PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_NEG |
    PROC_FLAG_DONE_SPELL_NONE_DMG_CLASS_NEG;

bool IsArcaneInfusion(uint32 spellId)
{
    return spellId >= FirstArcaneInfusion && spellId < FirstArcaneExplosion;
}

uint32 RuneFor(Player const* player)
{
    uint32 const spec = GetAscensionActiveSpecialization(player);
    if (std::ranges::find(BossControlRoles::TankSpecializations, spec) != BossControlRoles::TankSpecializations.end())
        return TankRune;
    if (std::ranges::find(BossControlRoles::HealerSpecializations, spec) !=
        BossControlRoles::HealerSpecializations.end())
        return HealerRune;

    auto const stats = AscensionSpecLoot::ActivePrimaryStats(player);
    for (uint32 stat : stats)
    {
        if (stat == ITEM_MOD_INTELLECT || stat == ITEM_MOD_SPIRIT)
            return CasterRune;
        if (stat == ITEM_MOD_STRENGTH || stat == ITEM_MOD_AGILITY)
            return PhysicalRune;
    }
    return PhysicalRune;
}

class BlackwingTrinketSpellData : public GlobalScript
{
public:
    BlackwingTrinketSpellData() : GlobalScript("BlackwingTrinketSpellData",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* spell) override
    {
        if (IsArcaneInfusion(spell->Id))
        {
            spell->ProcFlags = PROC_FLAG_DONE_SPELL_RANGED_DMG_CLASS;
            spell->Effects[EFFECT_0].SpellClassMask = {};
        }

        if (spell->Id >= FirstArcaneExplosion && spell->Id < FirstArcaneExplosion + ArcaneRangedCoefficients.size())
        {
            spell->Targets = TARGET_FLAG_DEST_LOCATION;
            spell->Effects[EFFECT_0].TargetA = SpellImplicitTargetInfo();
        }

        switch (spell->Id)
        {
            case RuneOfMetamorphosis:
            case PhysicalRune:
            case CasterRune:
            case HealerRune:
                spell->Stances = 0;
                spell->StancesNot = 0;
                break;
            default:
                break;
        }

        if (spell->Id == PhysicalRune)
        {
            spell->Effects[EFFECT_0].MiscValue |= 1 << CR_HASTE_RANGED;
            SpellEffectInfo& hit = spell->Effects[EFFECT_1];
            hit.ApplyAuraName = SPELL_AURA_MOD_RATING;
            hit.MiscValue = (1 << CR_HIT_MELEE) | (1 << CR_HIT_RANGED);
            spell->Effects[EFFECT_2].Effect = 0;
            spell->Effects[EFFECT_2].ApplyAuraName = SPELL_AURA_NONE;
        }

        if (spell->Id == CasterRune)
        {
            spell->ProcFlags = DirectSpellProcFlags;
            spell->Effects[EFFECT_0].SpellClassMask = {};
        }
    }
};

class spell_blackwing_arcane_infusion : public AuraScript
{
    PrepareAuraScript(spell_blackwing_arcane_infusion);

    bool Validate(SpellInfo const* spell) override
    {
        return IsArcaneInfusion(spell->Id) &&
            ValidateSpellInfo({FirstArcaneExplosion + spell->Id - FirstArcaneInfusion});
    }

    bool Check(ProcEventInfo& event)
    {
        Spell const* shot = event.GetProcSpell();
        return shot && !shot->IsTriggered() && shot->GetSpellInfo()->IsRangedWeaponSpell() &&
            !shot->GetSpellInfo()->IsAutoRepeatRangedSpell() && event.GetActionTarget() &&
            event.GetDamageInfo() && event.GetDamageInfo()->GetDamage() &&
            (event.GetTypeMask() & PROC_FLAG_DONE_SPELL_RANGED_DMG_CLASS) &&
            !(event.GetTypeMask() & PROC_FLAG_DONE_PERIODIC);
    }

    void Explode(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Unit* target = event.GetActionTarget();
        SpellCastTargets targets;
        targets.SetDst(*target);
        SpellInfo const* explosion = sSpellMgr->GetSpellInfo(FirstArcaneExplosion + GetId() - FirstArcaneInfusion);
        GetTarget()->CastSpell(targets, explosion, nullptr, TRIGGERED_FULL_MASK, nullptr, effect);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_blackwing_arcane_infusion::Check);
        OnEffectProc += AuraEffectProcFn(spell_blackwing_arcane_infusion::Explode, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_blackwing_arcane_explosion : public SpellScript
{
    PrepareSpellScript(spell_blackwing_arcane_explosion);

    void Scale(SpellEffIndex)
    {
        float const coefficient = ArcaneRangedCoefficients[GetSpellInfo()->Id - FirstArcaneExplosion];
        int32 damage = GetEffectValue() + int32(coefficient * GetCaster()->GetTotalAttackPowerValue(RANGED_ATTACK));
        if (GetHitUnit()->IsControlledByPlayer())
            damage = CalculatePct(damage, ArcanePlayerDamagePct);
        SetEffectValue(damage);
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_blackwing_arcane_explosion::Scale, EFFECT_0,
            SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

class spell_blackwing_rune_of_metamorphosis : public SpellScript
{
    PrepareSpellScript(spell_blackwing_rune_of_metamorphosis);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({PhysicalRune, CasterRune, HealerRune, TankRune});
    }

    void Apply(SpellEffIndex)
    {
        PreventHitDefaultEffect(EFFECT_0);
        if (Player* player = GetCaster()->ToPlayer())
        {
            uint32 const rune = RuneFor(player);
            for (uint32 other : {PhysicalRune, CasterRune, HealerRune, TankRune})
                if (other != rune)
                    player->RemoveAurasDueToSpell(other, player->GetGUID());
            if (player->CastSpell(player, rune, true) == SPELL_CAST_OK)
                player->SendPlaySpellVisual(TransformationVisual);
        }
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_blackwing_rune_of_metamorphosis::Apply, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

class spell_blackwing_owlkin_rune : public AuraScript
{
    PrepareAuraScript(spell_blackwing_owlkin_rune);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({OwlkinKnowledge});
    }

    bool Check(ProcEventInfo& event)
    {
        return event.GetDamageInfo() && event.GetDamageInfo()->GetDamage() &&
            !(event.GetTypeMask() & PROC_FLAG_DONE_PERIODIC);
    }

    void Stack(AuraEffect const* effect, ProcEventInfo&)
    {
        PreventDefaultAction();
        Unit* wearer = GetTarget();
        wearer->CastSpell(wearer, OwlkinKnowledge, true, nullptr, effect);
        if (Aura* knowledge = wearer->GetAura(OwlkinKnowledge, wearer->GetGUID()))
            knowledge->SetDuration(GetAura()->GetDuration());
    }

    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(OwlkinKnowledge, GetTarget()->GetGUID());
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_blackwing_owlkin_rune::Check);
        OnEffectProc += AuraEffectProcFn(spell_blackwing_owlkin_rune::Stack, EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_blackwing_owlkin_rune::Remove, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
    }
};
}

void AddSC_AscensionBlackwingTrinkets()
{
    new BlackwingTrinketSpellData();
    RegisterSpellScript(spell_blackwing_arcane_infusion);
    RegisterSpellScript(spell_blackwing_arcane_explosion);
    RegisterSpellScript(spell_blackwing_rune_of_metamorphosis);
    RegisterSpellScript(spell_blackwing_owlkin_rune);
}
