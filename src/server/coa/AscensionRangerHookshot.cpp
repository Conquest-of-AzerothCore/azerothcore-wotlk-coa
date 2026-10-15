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
constexpr uint32 HookReady = 803857;
constexpr uint32 Hooked = 803852;
constexpr uint32 HookRoot = 800360;

Player* HookRanger(Unit* caster)
{
    Player* player = caster ? caster->ToPlayer() : nullptr;
    return player && player->getClass() == CLASS_RANGER ? player : nullptr;
}

Unit* HookTarget(Player* player)
{
    if (!player || !player->IsAlive() || !player->IsInWorld())
        return nullptr;
    Aura* ready = player->GetAura(HookReady, player->GetGUID());
    if (!ready || !player->HasActiveSpell(uint32(ready->GetScriptValue(HookRoot))))
        return nullptr;
    Unit* target = ObjectAccessor::GetUnit(*player, ObjectGuid(ready->GetScriptValue(Hooked)));
    return target && target->IsAlive() && player->InSamePhase(target) &&
        player->IsValidAttackTarget(target) ? target : nullptr;
}

class spell_ascension_hookshot : public SpellScript
{
    PrepareSpellScript(spell_ascension_hookshot);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({HookReady, Hooked}); }
    bool Load() override { return HookRanger(GetCaster()) != nullptr; }

    void Latch(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Player* player = GetCaster()->ToPlayer();
        Unit* target = GetHitUnit();
        if (!target || !target->IsAlive() || !player->IsValidAttackTarget(target) ||
            !target->HasAuraState(AURA_STATE_BLEEDING))
            return;
        player->RemoveAurasDueToSpell(HookReady, player->GetGUID());
        if (Aura* ready = player->AddAura(HookReady, player))
        {
            uint32 original = GetSpellInfo()->Id;
            ready->SetScriptValue(HookRoot, original);
            ready->SetScriptValue(Hooked, target->GetGUID().GetRawValue());
            if (player->GetSpellMap().find(Hooked) == player->GetSpellMap().end())
                player->learnSpell(Hooked, true);
            player->SetTemporarySpellReplacement(original, Hooked);
            if (player->GetTemporarySpellReplacement(original) != Hooked)
                player->RemoveAurasDueToSpell(HookReady, player->GetGUID());
        }
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_hookshot::Latch, EFFECT_1, SPELL_EFFECT_TRIGGER_SPELL);
    }
};

class aura_ascension_hookshot_ready : public AuraScript
{
    PrepareAuraScript(aura_ascension_hookshot_ready);

    void Clear(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = HookRanger(GetTarget());
        if (!player || GetCaster() != player)
            return;
        if (uint32 original = uint32(GetAura()->GetScriptValue(HookRoot)))
            player->SetTemporarySpellReplacement(original, 0);
        player->removeSpell(Hooked, SPEC_MASK_ALL, true);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_hookshot_ready::Clear,
            EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class ranger_hookshot_casts : public AllSpellScript
{
public:
    ranger_hookshot_casts() : AllSpellScript("ranger_hookshot_casts",
        {ALLSPELLHOOK_CAN_PREPARE, ALLSPELLHOOK_ON_SPELL_CHECK_CAST, ALLSPELLHOOK_ON_BEFORE_EFFECTS}) { }

    bool IsFollowup(Spell* spell) const
    {
        return spell->GetSpellInfo()->Id == Hooked && spell->GetSpellInfo()->SpellFamilyName == 27;
    }

    bool CanPrepare(Spell* spell, SpellCastTargets const*, AuraEffect const*) override
    {
        if (!IsFollowup(spell))
            return true;
        Unit* target = HookTarget(HookRanger(spell->GetCaster()));
        if (!target)
            return false;
        spell->m_targets.SetUnitTarget(target);
        return true;
    }

    void OnSpellCheckCast(Spell* spell, bool, SpellCastResult& result) override
    {
        if (!IsFollowup(spell))
            return;
        Unit* target = HookTarget(HookRanger(spell->GetCaster()));
        if (!target || target != spell->m_targets.GetUnitTarget())
            result = SPELL_FAILED_BAD_TARGETS;
    }

    void OnSpellBeforeEffects(Spell* spell, Unit* caster, SpellInfo const*) override
    {
        if (IsFollowup(spell))
            caster->RemoveAurasDueToSpell(HookReady, caster->GetGUID());
    }
};

class ranger_hookshot_contracts : public GlobalScript
{
public:
    ranger_hookshot_contracts() : GlobalScript("ranger_hookshot_contracts",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info && info->Id == HookReady && info->SpellFamilyName == 27)
        {
            info->AttributesCu &= ~SPELL_ATTR0_CU_FORCE_AURA_SAVING;
            info->AttributesCu |= SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED;
        }
    }
};
}

void AddSC_AscensionRangerHookshot()
{
    RegisterSpellScript(spell_ascension_hookshot);
    RegisterSpellScript(aura_ascension_hookshot_ready);
    new ranger_hookshot_casts();
    new ranger_hookshot_contracts();
}
