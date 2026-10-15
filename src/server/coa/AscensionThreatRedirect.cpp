/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellScript.h"
#include "ThreatManager.h"

namespace
{
enum ThreatRedirectSpells : uint32
{
    SPELL_VEERING_WINDS = 574356,
    SPELL_VEERING_WINDS_ACTIVE = 574357,
    SPELL_FERAL_PRESSURE = 534605,
    SPELL_FERAL_PRESSURE_ACTIVE = 535214,
    SPELL_WARNING_SHOT = 534480,
    SPELL_WARNING_SHOT_ACTIVE = 535097
};

uint32 RedirectSpell(uint32 id, bool active)
{
    switch (id)
    {
        case SPELL_VEERING_WINDS:
        case SPELL_VEERING_WINDS_ACTIVE:
            return active ? SPELL_VEERING_WINDS_ACTIVE : SPELL_VEERING_WINDS;
        case SPELL_FERAL_PRESSURE:
        case SPELL_FERAL_PRESSURE_ACTIVE:
            return active ? SPELL_FERAL_PRESSURE_ACTIVE : SPELL_FERAL_PRESSURE;
        case SPELL_WARNING_SHOT:
        case SPELL_WARNING_SHOT_ACTIVE:
            return active ? SPELL_WARNING_SHOT_ACTIVE : SPELL_WARNING_SHOT;
        default:
            return 0;
    }
}

class aura_ascension_threat_redirect : public AuraScript
{
    PrepareAuraScript(aura_ascension_threat_redirect);

    bool Validate(SpellInfo const* info) override
    {
        uint32 active = RedirectSpell(info->Id, true);
        return active && ValidateSpellInfo({active});
    }

    bool CheckProc(ProcEventInfo& event)
    {
        DamageInfo const* damage = event.GetDamageInfo();
        return event.GetActor() == GetTarget() && damage && damage->GetDamage() &&
            GetTarget()->GetThreatMgr().HasRedirects();
    }

    void Activate(AuraEffect const* effect, ProcEventInfo&)
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), RedirectSpell(GetId(), true), true, nullptr, effect);
        Remove(AURA_REMOVE_BY_DEFAULT);
    }

    void OnRemove(AuraEffect const*, AuraEffectHandleModes)
    {
        if (GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_DEFAULT ||
            !GetTarget()->HasAura(RedirectSpell(GetId(), true)))
            GetTarget()->GetThreatMgr().UnregisterRedirectThreat(GetId());
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_threat_redirect::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_ascension_threat_redirect::Activate, EFFECT_1, SPELL_AURA_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_threat_redirect::OnRemove,
            EFFECT_1, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_threat_redirect_active : public AuraScript
{
    PrepareAuraScript(aura_ascension_threat_redirect_active);

    void OnRemove(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->GetThreatMgr().UnregisterRedirectThreat(RedirectSpell(GetId(), false));
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_threat_redirect_active::OnRemove,
            EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class threat_redirect_metadata : public GlobalScript
{
public:
    threat_redirect_metadata() : GlobalScript("threat_redirect_metadata", {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (!RedirectSpell(info->Id, false))
            return;
        info->AttributesCu &= ~SPELL_ATTR0_CU_FORCE_AURA_SAVING;
        info->AttributesCu |= SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED;
    }
};
}

void AddSC_AscensionThreatRedirect()
{
    RegisterSpellScript(aura_ascension_threat_redirect);
    RegisterSpellScript(aura_ascension_threat_redirect_active);
    new threat_redirect_metadata();
}
