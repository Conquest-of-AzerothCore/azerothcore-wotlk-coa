/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionRunemasterScaling.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <set>

namespace
{
struct RunebladeLevelContract
{
    uint32 SpellId;
    uint32 SpellLevel;
    uint32 MaxLevel;
};

constexpr RunebladeLevelContract RunebladeLevels[] =
{
    {707141, 1, 4}, {707143, 6, 10}, {707144, 12, 16}, {707145, 18, 22},
    {707146, 24, 28}, {707147, 30, 34}, {707148, 36, 40}, {573444, 42, 46},
    {573445, 48, 52}, {573446, 54, 58}, {573447, 60, 66}
};

bool IsScalingBrand(uint32 id)
{
    return id == 712299 || (id >= 712301 && id <= 712307);
}

class spell_ascension_runemaster_brand_weapons : public SpellScript
{
    PrepareSpellScript(spell_ascension_runemaster_brand_weapons);

    bool Validate(SpellInfo const* info) override
    {
        if (!info || !IsScalingBrand(info->Id) || info->SpellFamilyName != uint32(CLASS_SPIRIT_MAGE) + 6)
            return false;

        for (uint8 i = EFFECT_0; i <= EFFECT_1; ++i)
            if (info->Effects[i].Effect != SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE || info->Effects[i].TriggerSpell != 712322)
                return false;

        return ValidateSpellInfo({712322});
    }

    bool Load() override
    {
        return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_SPIRIT_MAGE;
    }

    void SuppressDefault(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
    }

    void LaunchWeapon(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
        Unit* target = GetHitUnit();
        SpellInfo const* helper = sSpellMgr->GetSpellInfo(712322);
        if (!target || !helper || !helper->NeedsToBeTriggeredByCaster(GetSpellInfo(), effIndex) ||
            !_launched.insert({target->GetGUID(), effIndex}).second)
            return;

        SpellCastTargets targets;
        targets.SetUnitTarget(target);
        CustomSpellValues values;
        values.AddSpellMod(SPELLVALUE_BASE_POINT0, GetEffectValue());
        values.AddSpellMod(SPELLVALUE_BASE_POINT1, GetEffectValue());
        values.AddSpellMod(SPELLVALUE_BASE_POINT2, GetEffectValue());
        values.AddSpellMod(SPELLVALUE_MELEE_ATTACK_TYPE, effIndex == EFFECT_0 ? BASE_ATTACK : OFF_ATTACK);

        if (helper->CategoryRecoveryTime && GetSpellInfo()->GetCategory() == helper->GetCategory())
            GetCaster()->ToPlayer()->RemoveSpellCooldown(helper->Id);

        GetCaster()->CastSpell(targets, helper, &values,
            TriggerCastFlags(TRIGGERED_FULL_MASK & ~TRIGGERED_NO_PERIODIC_RESET),
            nullptr, nullptr, GetSpell()->GetOriginalCasterGUID());
    }

    void Register() override
    {
        OnEffectLaunch += SpellEffectFn(spell_ascension_runemaster_brand_weapons::SuppressDefault,
            EFFECT_0, SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE);
        OnEffectLaunch += SpellEffectFn(spell_ascension_runemaster_brand_weapons::SuppressDefault,
            EFFECT_1, SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE);
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_runemaster_brand_weapons::LaunchWeapon,
            EFFECT_0, SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE);
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_runemaster_brand_weapons::LaunchWeapon,
            EFFECT_1, SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE);
    }

    std::set<std::pair<ObjectGuid, SpellEffIndex>> _launched;
};
}

void ApplyAscensionRunemasterScalingContracts(SpellInfo* info)
{
    if (!info || info->SpellFamilyName != uint32(CLASS_SPIRIT_MAGE) + 6)
        return;

    if (info->Id == 705557)
        info->Attributes |= SPELL_ATTR0_PASSIVE;

    if (info->Id == 712299 && info->SpellFamilyFlags == flag96(0, 4096, 0) &&
        info->DmgClass == SPELL_DAMAGE_CLASS_MELEE && info->SchoolMask == (SPELL_SCHOOL_MASK_FIRE | SPELL_SCHOOL_MASK_ARCANE) &&
        info->SpellLevel == 11 && info->BaseLevel == 11 && info->MaxLevel == 16 &&
        info->Effects[EFFECT_0].Effect == SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE && info->Effects[EFFECT_0].TriggerSpell == 712322 &&
        info->Effects[EFFECT_1].Effect == SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE && info->Effects[EFFECT_1].TriggerSpell == 712322 &&
        info->Effects[EFFECT_2].Effect == SPELL_EFFECT_TRIGGER_SPELL && info->Effects[EFFECT_2].TriggerSpell == 712323)
        info->SchoolMask = SPELL_SCHOOL_MASK_FIRE;

    for (RunebladeLevelContract const& contract : RunebladeLevels)
        if (info->Id == contract.SpellId && info->SpellLevel == contract.SpellLevel &&
            info->BaseLevel == contract.SpellLevel && info->MaxLevel == contract.MaxLevel &&
            info->SpellFamilyFlags == flag96(0, 0, 262144) && info->DmgClass == SPELL_DAMAGE_CLASS_MELEE &&
            info->SchoolMask == (SPELL_SCHOOL_MASK_FIRE | SPELL_SCHOOL_MASK_NATURE | SPELL_SCHOOL_MASK_FROST) &&
            info->Effects[EFFECT_0].Effect == SPELL_EFFECT_SCHOOL_DAMAGE && !info->Effects[EFFECT_0].BonusMultiplier &&
            info->Effects[EFFECT_1].Effect == SPELL_EFFECT_TRIGGER_SPELL && info->Effects[EFFECT_1].TriggerSpell == 712324 &&
            !info->Effects[EFFECT_2].Effect)
            info->IgnoreSpellLevelPenalty = true;

    if (info->Id < 712301 || info->Id > 712307 || info->SpellFamilyFlags != flag96(0, 4096, 0))
        return;

    SpellEffectInfo const& first = info->Effects[EFFECT_0];
    SpellEffectInfo& second = info->Effects[EFFECT_1];
    if (first.Effect != SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE || second.Effect != SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE ||
        first.TriggerSpell != 712322 || second.TriggerSpell != 712322 || first.DieSides != 1 || second.DieSides != 1 ||
        second.RealPointsPerLevel != 0.32852f || second.BasePoints != (info->Id == 712307 ? 78 : 10))
        return;

    second.BasePoints = first.BasePoints;
    second.RealPointsPerLevel = first.RealPointsPerLevel;
}

void AddAscensionRunemasterScalingScripts()
{
    RegisterSpellScript(spell_ascension_runemaster_brand_weapons);
}
