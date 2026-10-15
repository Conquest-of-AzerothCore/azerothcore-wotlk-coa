/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellScript.h"

namespace
{
enum HemostasisSpells : uint32
{
    SPELL_HEMOSTASIS = 681304,
    SPELL_HEMOSTASIS_READY = 302895,
    SPELL_BLOOD_BURST = 803326
};

Player* HemostasisCaster(Unit* unit)
{
    Player* player = unit ? unit->ToPlayer() : nullptr;
    return player && player->getClass() == CLASS_SON_OF_ARUGAL ? player : nullptr;
}

Unit* HemostasisTarget(Player* player)
{
    if (!player || !player->IsAlive() || !player->IsInWorld() || !player->HasActiveSpell(SPELL_HEMOSTASIS))
        return nullptr;
    Aura* window = player->GetAura(SPELL_HEMOSTASIS_READY, player->GetGUID());
    if (!window)
        return nullptr;
    Unit* victim = ObjectAccessor::GetUnit(*player, ObjectGuid(window->GetScriptValue(SPELL_HEMOSTASIS)));
    return victim && victim->IsAlive() && player->InSamePhase(victim) &&
        player->IsValidAttackTarget(victim) && victim->HasAura(SPELL_HEMOSTASIS, player->GetGUID()) ? victim : nullptr;
}

class aura_ascension_hemostasis : public AuraScript
{
    PrepareAuraScript(aura_ascension_hemostasis);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_HEMOSTASIS_READY, SPELL_BLOOD_BURST}); }

    void Apply(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = HemostasisCaster(GetCaster());
        if (!player || !player->HasActiveSpell(SPELL_HEMOSTASIS))
            return;
        if (Aura* window = player->AddAura(SPELL_HEMOSTASIS_READY, player))
        {
            window->SetScriptValue(SPELL_HEMOSTASIS, GetTarget()->GetGUID().GetRawValue());
            if (player->GetSpellMap().find(SPELL_BLOOD_BURST) == player->GetSpellMap().end())
                player->learnSpell(SPELL_BLOOD_BURST, true);
            player->SetTemporarySpellReplacement(SPELL_HEMOSTASIS, SPELL_BLOOD_BURST);
            if (player->GetTemporarySpellReplacement(SPELL_HEMOSTASIS) != SPELL_BLOOD_BURST)
                player->RemoveAurasDueToSpell(SPELL_HEMOSTASIS_READY, player->GetGUID());
        }
    }

    void OnRemove(AuraEffect const*, AuraEffectHandleModes)
    {
        if (Player* player = HemostasisCaster(GetCaster()))
            if (Aura* window = player->GetAura(SPELL_HEMOSTASIS_READY, player->GetGUID()))
                if (window->GetScriptValue(SPELL_HEMOSTASIS) == GetTarget()->GetGUID().GetRawValue())
                    player->RemoveAurasDueToSpell(SPELL_HEMOSTASIS_READY, player->GetGUID());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_hemostasis::Apply,
            EFFECT_0, SPELL_AURA_MOD_STUN, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_hemostasis::OnRemove,
            EFFECT_0, SPELL_AURA_MOD_STUN, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_hemostasis_ready : public AuraScript
{
    PrepareAuraScript(aura_ascension_hemostasis_ready);

    void OnRemove(AuraEffect const*, AuraEffectHandleModes)
    {
        if (Player* player = HemostasisCaster(GetTarget()))
        {
            player->SetTemporarySpellReplacement(SPELL_HEMOSTASIS, 0);
            player->removeSpell(SPELL_BLOOD_BURST, SPEC_MASK_ALL, true);
        }
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_hemostasis_ready::OnRemove,
            EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class hemostasis_burst_target : public AllSpellScript
{
public:
    hemostasis_burst_target() : AllSpellScript("hemostasis_burst_target",
        {ALLSPELLHOOK_CAN_PREPARE, ALLSPELLHOOK_ON_SPELL_CHECK_CAST}) { }

    bool CanPrepare(Spell* spell, SpellCastTargets const*, AuraEffect const*) override
    {
        if (spell->GetSpellInfo()->Id != SPELL_BLOOD_BURST || spell->GetSpellInfo()->SpellFamilyName != 26)
            return true;
        Unit* victim = HemostasisTarget(HemostasisCaster(spell->GetCaster()));
        if (!victim)
            return false;
        spell->m_targets.SetUnitTarget(victim);
        return true;
    }

    void OnSpellCheckCast(Spell* spell, bool, SpellCastResult& result) override
    {
        if (spell->GetSpellInfo()->Id != SPELL_BLOOD_BURST || spell->GetSpellInfo()->SpellFamilyName != 26)
            return;
        Unit* victim = HemostasisTarget(HemostasisCaster(spell->GetCaster()));
        if (!victim || victim != spell->m_targets.GetUnitTarget())
            result = SPELL_FAILED_BAD_TARGETS;
    }
};

class spell_ascension_blood_burst : public SpellScript
{
    PrepareSpellScript(spell_ascension_blood_burst);

    void Release(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        if (Unit* victim = GetHitUnit())
            victim->RemoveAurasDueToSpell(SPELL_HEMOSTASIS, GetCaster()->GetGUID());
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_blood_burst::Release, EFFECT_2, SPELL_EFFECT_REMOVE_AURA);
    }
};

class hemostasis_contracts : public GlobalScript
{
public:
    hemostasis_contracts() : GlobalScript("hemostasis_contracts", {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info && info->Id == SPELL_HEMOSTASIS_READY && info->SpellFamilyName == 26)
        {
            info->AttributesCu |= SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED;
            info->AttributesCu &= ~SPELL_ATTR0_CU_FORCE_AURA_SAVING;
        }
    }
};
}

void AddSC_AscensionBloodmageHemostasis()
{
    RegisterSpellScript(aura_ascension_hemostasis);
    RegisterSpellScript(aura_ascension_hemostasis_ready);
    RegisterSpellScript(spell_ascension_blood_burst);
    new hemostasis_burst_target();
    new hemostasis_contracts();
}
