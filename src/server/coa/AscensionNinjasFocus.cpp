/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Item.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellScript.h"

namespace
{
constexpr uint32 SPELL_NINJAS_FOCUS_AGILITY = 968746;

class aura_ascension_ninjas_focus : public AuraScript
{
    PrepareAuraScript(aura_ascension_ninjas_focus);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_NINJAS_FOCUS_AGILITY});
    }

    void CastFromWeapon(AuraEffect const* effect, ProcEventInfo&)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        Player* player = owner->ToPlayer();
        Item* weapon = player ? player->GetItemByGuid(GetAura()->GetCastItemGUID()) : nullptr;
        owner->CastSpell(owner, SPELL_NINJAS_FOCUS_AGILITY, TRIGGERED_FULL_MASK, weapon, effect);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(aura_ascension_ninjas_focus::CastFromWeapon, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class ninjas_focus_contracts : public GlobalScript
{
public:
    ninjas_focus_contracts() : GlobalScript("ninjas_focus_contracts", {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info && info->Id == SPELL_NINJAS_FOCUS_AGILITY)
            info->AttributesCu |= SPELL_ATTR0_CU_ENCHANT_PROC;
    }
};
}

void AddSC_AscensionNinjasFocus()
{
    RegisterSpellScript(aura_ascension_ninjas_focus);
    new ninjas_focus_contracts();
}
