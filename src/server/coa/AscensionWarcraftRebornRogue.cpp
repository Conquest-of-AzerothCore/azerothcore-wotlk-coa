/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWarcraftRebornRogue.h"
#include "AscensionWarcraftRebornRules.h"
#include "CellImpl.h"
#include "DBCStores.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include <algorithm>
#include <cmath>

namespace AscensionWarcraftReborn
{
namespace
{
constexpr uint32 HUNGER_FOR_BLOOD_BUFF = 1163848;
constexpr uint32 CUT_TO_THE_CHASE_REFRESH = 9931095;
constexpr uint32 ROGUE_EVISCERATE = 0x20000;
constexpr uint32 ROGUE_ENVENOM = 0x8;
constexpr uint32 ROGUE_CRIMSON_TEMPEST = 0x20000000;
constexpr uint32 ROGUE_AMBUSH = 0x200;
constexpr uint32 ROGUE_RUPTURE = 0x100000;
constexpr float AMBUSH_TOOLTIP_PERCENT = 275.0f;
constexpr uint32 ANESTHETIC_POISON = 1126688;
constexpr int32 ANESTHETIC_POISON_BASE = 67;
constexpr int32 ANESTHETIC_POISON_DIE = 19;
constexpr uint32 RELENTLESS_STRIKES_ENERGY = 1114181;
constexpr float CRIMSON_TEMPEST_HIT_AP = 0.012f;
constexpr float CRIMSON_TEMPEST_BLEED_AP = 0.00744f;
constexpr float POISON_NOVA_AP = 0.0048f;

constexpr float DISPATCH_AP_MIN = 0.056f;

constexpr uint32 RECUPERATE = 2315425;
constexpr uint32 DURATION_0_TO_30_SEC = 588;
constexpr float DISPATCH_AP_MAX = 0.07f;
constexpr uint8 SABER_SLASH_SPREAD_POINTS = 5;
constexpr uint8 SABER_SLASH_SPREAD_TARGETS = 2;
constexpr float SABER_SLASH_SPREAD_RANGE = 10.0f;

uint8 ComboPoints(Unit const* caster)
{
    return caster ? caster->GetComboPoints() : 0;
}

class spell_ascension_reborn_hunger_for_blood : public SpellScript
{
    PrepareSpellScript(spell_ascension_reborn_hunger_for_blood);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ HUNGER_FOR_BLOOD_BUFF });
    }

    void HandleDummy(SpellEffIndex)
    {
        GetCaster()->CastSpell(GetCaster(), HUNGER_FOR_BLOOD_BUFF, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_reborn_hunger_for_blood::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

class spell_ascension_reborn_cut_to_the_chase : public AuraScript
{
    PrepareAuraScript(spell_ascension_reborn_cut_to_the_chase);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ CUT_TO_THE_CHASE_REFRESH });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* procSpell = eventInfo.GetSpellInfo();
        if (!procSpell || procSpell->SpellFamilyName != SPELLFAMILY_ROGUE)
            return false;
        flag96 const& flags = procSpell->SpellFamilyFlags;
        return (flags[0] & ROGUE_EVISCERATE) || (flags[1] & ROGUE_ENVENOM) || (flags[2] & ROGUE_CRIMSON_TEMPEST);
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo&)
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), CUT_TO_THE_CHASE_REFRESH, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_reborn_cut_to_the_chase::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_ascension_reborn_cut_to_the_chase::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class spell_ascension_reborn_crimson_tempest : public SpellScript
{
    PrepareSpellScript(spell_ascension_reborn_crimson_tempest);

    void HandleDamage(SpellEffIndex)
    {
        Unit* caster = GetCaster();
        SetEffectValue(GetEffectValue() + int32(ComboPoints(caster) *
            caster->GetTotalAttackPowerValue(BASE_ATTACK) * CRIMSON_TEMPEST_HIT_AP));
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_reborn_crimson_tempest::HandleDamage, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

class spell_ascension_reborn_crimson_tempest_bleed : public AuraScript
{
    PrepareAuraScript(spell_ascension_reborn_crimson_tempest_bleed);

    void CalculateAmount(AuraEffect const*, int32& amount, bool& canBeRecalculated)
    {
        canBeRecalculated = false;
        if (Unit* caster = GetCaster())
            amount += int32(ComboPoints(caster) * caster->GetTotalAttackPowerValue(BASE_ATTACK) * CRIMSON_TEMPEST_BLEED_AP);
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_ascension_reborn_crimson_tempest_bleed::CalculateAmount, EFFECT_2, SPELL_AURA_PERIODIC_DAMAGE);
    }
};

class spell_ascension_reborn_dispatch : public SpellScript
{
    PrepareSpellScript(spell_ascension_reborn_dispatch);

    void HandleDamage(SpellEffIndex)
    {
        Unit* caster = GetCaster();
        float const power = ComboPoints(caster) * caster->GetTotalAttackPowerValue(BASE_ATTACK);
        SetEffectValue(GetEffectValue() + irand(int32(power * DISPATCH_AP_MIN), int32(power * DISPATCH_AP_MAX)));
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_reborn_dispatch::HandleDamage, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

class spell_ascension_reborn_poison_nova : public SpellScript
{
    PrepareSpellScript(spell_ascension_reborn_poison_nova);

    void HandleDamage(SpellEffIndex)
    {
        Unit* caster = GetCaster();
        float const power = caster->GetTotalAttackPowerValue(BASE_ATTACK) +
            float(std::max(0, caster->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_NATURE)));
        SetEffectValue(GetEffectValue() + int32(ComboPoints(caster) * power * POISON_NOVA_AP));
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_reborn_poison_nova::HandleDamage, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

class spell_ascension_reborn_saber_slash : public SpellScript
{
    PrepareSpellScript(spell_ascension_reborn_saber_slash);

    static Aura* FindRupture(Unit* target, ObjectGuid caster)
    {
        for (auto const& [id, application] : target->GetAppliedAuras())
        {
            Aura* aura = application->GetBase();
            SpellInfo const* info = aura->GetSpellInfo();
            if (aura->GetCasterGUID() == caster && info->SpellFamilyName == SPELLFAMILY_ROGUE &&
                (info->SpellFamilyFlags[0] & ROGUE_RUPTURE))
                return aura;
        }
        return nullptr;
    }

    void HandleSpread(SpellEffIndex)
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!target || ComboPoints(caster) < SABER_SLASH_SPREAD_POINTS)
            return;
        Aura* rupture = FindRupture(target, caster->GetGUID());
        if (!rupture)
            return;

        std::list<Unit*> candidates;
        Acore::AnyUnfriendlyUnitInObjectRangeCheck check(target, caster, SABER_SLASH_SPREAD_RANGE);
        Acore::UnitListSearcher<Acore::AnyUnfriendlyUnitInObjectRangeCheck> searcher(target, candidates, check);
        Cell::VisitObjects(target, searcher, SABER_SLASH_SPREAD_RANGE);
        candidates.remove_if([caster, target](Unit* candidate)
        {
            return candidate == target || !candidate->IsAlive() || !caster->IsValidAttackTarget(candidate) ||
                FindRupture(candidate, caster->GetGUID());
        });
        candidates.sort([target](Unit const* left, Unit const* right)
        {
            return target->GetExactDistSq(left) < target->GetExactDistSq(right);
        });

        uint8 spread = 0;
        for (Unit* candidate : candidates)
        {
            if (spread == SABER_SLASH_SPREAD_TARGETS)
                break;
            Aura* copy = caster->AddAura(rupture->GetId(), candidate);
            if (!copy)
                continue;
            copy->SetMaxDuration(rupture->GetMaxDuration());
            copy->SetDuration(rupture->GetDuration());
            for (uint8 effect = 0; effect < MAX_SPELL_EFFECTS; ++effect)
                if (AuraEffect const* source = rupture->GetEffect(effect))
                    if (AuraEffect* copied = copy->GetEffect(effect))
                        copied->ChangeAmount(source->GetAmount());
            ++spread;
        }
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_reborn_saber_slash::HandleSpread, EFFECT_1, SPELL_EFFECT_DUMMY);
    }
};
}
}

void ApplyAscensionWarcraftRebornRogueContracts(SpellInfo* spellInfo)
{
    using namespace AscensionWarcraftReborn;
    if (!spellInfo || spellInfo->Id < REBORN_SPELL_OFFSET || spellInfo->SpellFamilyName != SPELLFAMILY_ROGUE)
        return;

    if (spellInfo->Id == RECUPERATE && spellInfo->GetMaxDuration() == 1000)
        if (SpellDurationEntry const* duration = sSpellDurationStore.LookupEntry(DURATION_0_TO_30_SEC))
            spellInfo->DurationEntry = duration;

    if ((spellInfo->SpellFamilyFlags[0] & ROGUE_AMBUSH) &&
        spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_NORMALIZED_WEAPON_DMG &&
        spellInfo->Effects[EFFECT_1].Effect == SPELL_EFFECT_WEAPON_PERCENT_DAMAGE &&
        spellInfo->Effects[EFFECT_1].BasePoints + 1 > 0)
    {
        SpellEffectInfo& flat = spellInfo->Effects[EFFECT_0];
        float const scale = AMBUSH_TOOLTIP_PERCENT / float(spellInfo->Effects[EFFECT_1].BasePoints + 1);
        flat.BasePoints = int32(std::lround((flat.BasePoints + 1) * scale)) - 1;
        flat.RealPointsPerLevel *= scale;
    }

    if (spellInfo->Id == ANESTHETIC_POISON && spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_SCHOOL_DAMAGE)
    {
        spellInfo->Effects[EFFECT_0].BasePoints = ANESTHETIC_POISON_BASE;
        spellInfo->Effects[EFFECT_0].DieSides = ANESTHETIC_POISON_DIE;
    }

    if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY &&
        spellInfo->Effects[EFFECT_0].TriggerSpell == RELENTLESS_STRIKES_ENERGY)
        spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_ADD_TARGET_TRIGGER;
}

void AddAscensionWarcraftRebornRogueScripts()
{
    using namespace AscensionWarcraftReborn;
    RegisterSpellScript(spell_ascension_reborn_hunger_for_blood);
    RegisterSpellScript(spell_ascension_reborn_cut_to_the_chase);
    RegisterSpellScript(spell_ascension_reborn_crimson_tempest);
    RegisterSpellScript(spell_ascension_reborn_crimson_tempest_bleed);
    RegisterSpellScript(spell_ascension_reborn_poison_nova);
    RegisterSpellScript(spell_ascension_reborn_dispatch);
    RegisterSpellScript(spell_ascension_reborn_saber_slash);
}
