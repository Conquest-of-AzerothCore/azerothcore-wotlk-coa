/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionReaperDirge.h"
#include "Item.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <set>

namespace
{
constexpr uint32 SPELL_DIRGE_HIT = 801311;
constexpr uint32 SPELL_SOUL_FRAGMENT = 805077;

bool IsCurrentDirge(uint32 spellId)
{
    return spellId == 801328 || (spellId >= 803834 && spellId <= 803839);
}

bool IsDirgeHitContract(SpellInfo const* info)
{
    return info && info->Id == SPELL_DIRGE_HIT &&
        info->SpellFamilyName == uint32(CLASS_REAPER) + 6 &&
        info->DmgClass == SPELL_DAMAGE_CLASS_MELEE &&
        info->SchoolMask == (SPELL_SCHOOL_MASK_FROST | SPELL_SCHOOL_MASK_SHADOW) &&
        info->SpellFamilyFlags == flag96(8, 0, 0) &&
        info->EquippedItemClass == ITEM_CLASS_WEAPON &&
        info->EquippedItemSubClassMask == 34961 &&
        info->HasAttribute(SPELL_ATTR3_REQUIRES_OFF_HAND_WEAPON) &&
        info->Effects[EFFECT_0].Effect == SPELL_EFFECT_WEAPON_PERCENT_DAMAGE &&
        info->Effects[EFFECT_0].BasePoints == -1 && info->Effects[EFFECT_0].DieSides == 1 &&
        info->Effects[EFFECT_1].Effect == SPELL_EFFECT_TRIGGER_SPELL &&
        info->Effects[EFFECT_1].TriggerSpell == SPELL_SOUL_FRAGMENT &&
        !info->Effects[EFFECT_2].Effect;
}

SpellCastResult CheckDirgeWeapons(Player const* player)
{
    if (!player->GetWeaponForAttack(BASE_ATTACK, true))
        return SPELL_FAILED_EQUIPPED_ITEM_CLASS_MAINHAND;
    if (!player->GetWeaponForAttack(OFF_ATTACK, true))
        return SPELL_FAILED_EQUIPPED_ITEM_CLASS_OFFHAND;
    return SPELL_CAST_OK;
}

class spell_ascension_reaper_dirge_weapons : public SpellScript
{
    PrepareSpellScript(spell_ascension_reaper_dirge_weapons);

    bool Validate(SpellInfo const* info) override
    {
        if (!info || !IsCurrentDirge(info->Id) ||
            info->SpellFamilyName != uint32(CLASS_REAPER) + 6 ||
            info->DmgClass != SPELL_DAMAGE_CLASS_MELEE ||
            info->SchoolMask != (SPELL_SCHOOL_MASK_FROST | SPELL_SCHOOL_MASK_SHADOW) ||
            info->SpellFamilyFlags != flag96(0, 1048576, 65536) || info->Effects[EFFECT_2].Effect)
            return false;

        for (uint8 i = EFFECT_0; i <= EFFECT_1; ++i)
            if (info->Effects[i].Effect != SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE ||
                info->Effects[i].TriggerSpell != SPELL_DIRGE_HIT)
                return false;

        return IsDirgeHitContract(sSpellMgr->GetSpellInfo(SPELL_DIRGE_HIT));
    }

    bool Load() override
    {
        return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_REAPER;
    }

    SpellCastResult CheckWeapons()
    {
        return CheckDirgeWeapons(GetCaster()->ToPlayer());
    }

    void SuppressDefault(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
    }

    void LaunchWeapon(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
        Unit* target = GetHitUnit();
        Player* player = GetCaster()->ToPlayer();
        SpellInfo const* helper = sSpellMgr->GetSpellInfo(SPELL_DIRGE_HIT);
        if (!target || !helper || CheckDirgeWeapons(player) != SPELL_CAST_OK ||
            !helper->NeedsToBeTriggeredByCaster(GetSpellInfo(), effIndex) ||
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
            player->RemoveSpellCooldown(helper->Id);

        player->CastSpell(targets, helper, &values,
            TriggerCastFlags(TRIGGERED_FULL_MASK & ~TRIGGERED_NO_PERIODIC_RESET),
            nullptr, nullptr, GetSpell()->GetOriginalCasterGUID());
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_reaper_dirge_weapons::CheckWeapons);
        OnEffectLaunch += SpellEffectFn(spell_ascension_reaper_dirge_weapons::SuppressDefault,
            EFFECT_0, SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE);
        OnEffectLaunch += SpellEffectFn(spell_ascension_reaper_dirge_weapons::SuppressDefault,
            EFFECT_1, SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE);
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_reaper_dirge_weapons::LaunchWeapon,
            EFFECT_0, SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE);
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_reaper_dirge_weapons::LaunchWeapon,
            EFFECT_1, SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE);
    }

    std::set<std::pair<ObjectGuid, SpellEffIndex>> _launched;
};

class spell_ascension_reaper_dirge_dagger : public SpellScript
{
    PrepareSpellScript(spell_ascension_reaper_dirge_dagger);

    bool Validate(SpellInfo const* info) override
    {
        return IsDirgeHitContract(info);
    }

    bool Load() override
    {
        return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_REAPER;
    }

    void ApplyDaggerMultiplier()
    {
        WeaponAttackType hand = GetSpell()->GetScriptMeleeAttackType();
        if (hand != BASE_ATTACK && hand != OFF_ATTACK)
            return;

        if (Item* weapon = GetCaster()->ToPlayer()->GetWeaponForAttack(hand, true))
        {
            float multiplier = weapon->GetTemplate()->SubClass == ITEM_SUBCLASS_WEAPON_DAGGER ? 1.85f : 1.0f;
            GetSpell()->SetScriptWeaponDamageMultiplier(multiplier);
        }
    }

    void Register() override
    {
        BeforeCast += SpellCastFn(spell_ascension_reaper_dirge_dagger::ApplyDaggerMultiplier);
    }
};
}

void AddSC_AscensionReaperDirge()
{
    RegisterSpellScript(spell_ascension_reaper_dirge_weapons);
    RegisterSpellScript(spell_ascension_reaper_dirge_dagger);
}
