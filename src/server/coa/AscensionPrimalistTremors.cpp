/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "SpellScript.h"

namespace
{
constexpr uint32 TremorsFreeCast = 562312;

class aura_ascension_primalist_periodic_damage : public AuraScript
{
    PrepareAuraScript(aura_ascension_primalist_periodic_damage);

    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        Unit* victim = event.GetActionTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        return owner->IsPlayer() && owner->getClass() == CLASS_WILDWALKER && owner->IsAlive() &&
            GetCaster() == owner && event.GetActor() == owner && victim && victim != owner &&
            !owner->IsFriendlyTo(victim) && damage && damage->GetDamage() && damage->GetDamageType() == DOT;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_primalist_periodic_damage::Check);
    }
};

class primalist_tremors_metadata : public GlobalScript
{
public:
    primalist_tremors_metadata() : GlobalScript("primalist_tremors_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == TremorsFreeCast && info->SpellFamilyName == 37 &&
            info->Effects[EFFECT_0].IsAura(SPELL_AURA_ADD_PCT_MODIFIER) &&
            info->Effects[EFFECT_0].MiscValue == SPELLMOD_COST)
            info->Effects[EFFECT_0].SpellClassMask[0] |= 64;
    }
};
}

void AddSC_AscensionPrimalistTremors()
{
    RegisterSpellScript(aura_ascension_primalist_periodic_damage);
    new primalist_tremors_metadata();
}
