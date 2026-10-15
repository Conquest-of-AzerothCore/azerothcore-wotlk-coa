/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellScript.h"

namespace
{
enum CataclysmSpells : uint32
{
    SeismicReset = 680445,
    SeismicGraspReset = 681380
};

class aura_ascension_primalist_cataclysm : public AuraScript
{
    PrepareAuraScript(aura_ascension_primalist_cataclysm);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SeismicReset, SeismicGraspReset}); }

    bool Load() override
    {
        return GetUnitOwner()->IsPlayer() && GetUnitOwner()->getClass() == CLASS_WILDWALKER &&
            GetCasterGUID() == GetUnitOwner()->GetGUID();
    }

    void Reset(AuraEffect const*, ProcEventInfo&)
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), SeismicReset, TRIGGERED_FULL_MASK);
        GetTarget()->CastSpell(GetTarget(), SeismicGraspReset, TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(aura_ascension_primalist_cataclysm::Reset,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};
}

void AddSC_AscensionPrimalistCataclysm()
{
    RegisterSpellScript(aura_ascension_primalist_cataclysm);
}
