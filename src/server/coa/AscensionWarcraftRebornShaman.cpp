/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Creature.h"
#include "Map.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellScript.h"

namespace AscensionWarcraftReborn
{
namespace
{
constexpr uint32 TIDAL_FORCE_CRIT = 1155166;

class spell_ascension_reborn_tidal_force : public AuraScript
{
    PrepareAuraScript(spell_ascension_reborn_tidal_force);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ TIDAL_FORCE_CRIT });
    }

    void HandleApply(AuraEffect const* aurEff, AuraEffectHandleModes)
    {
        Unit* target = GetTarget();
        target->CastSpell(target, TIDAL_FORCE_CRIT, true, nullptr, aurEff);
        if (Aura* crit = target->GetAura(TIDAL_FORCE_CRIT))
            crit->SetStackAmount(crit->GetSpellInfo()->StackAmount);
    }

    void HandleProc(AuraEffect const*, ProcEventInfo&)
    {
        PreventDefaultAction();
        Unit* target = GetTarget();
        target->RemoveAuraFromStack(TIDAL_FORCE_CRIT);
        if (!target->HasAura(TIDAL_FORCE_CRIT))
            Remove();
    }

    void HandleRemove(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(TIDAL_FORCE_CRIT);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_ascension_reborn_tidal_force::HandleApply, EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        OnEffectProc += AuraEffectProcFn(spell_ascension_reborn_tidal_force::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(spell_ascension_reborn_tidal_force::HandleRemove, EFFECT_0, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_ascension_reborn_totemic_projection : public SpellScript
{
    PrepareSpellScript(spell_ascension_reborn_totemic_projection);

    void HandleDummy(SpellEffIndex)
    {
        Unit* caster = GetCaster();
        WorldLocation const* destination = GetHitDest();
        if (!destination)
            return;
        for (uint8 slot = SUMMON_SLOT_TOTEM_FIRE; slot < MAX_TOTEM_SLOT; ++slot)
            if (Creature* totem = caster->GetMap()->GetCreature(caster->m_SummonSlot[slot]))
                totem->NearTeleportTo(destination->GetPositionX(), destination->GetPositionY(), destination->GetPositionZ(),
                    totem->GetOrientation());
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_ascension_reborn_totemic_projection::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};
}
}

void AddAscensionWarcraftRebornShamanScripts()
{
    using namespace AscensionWarcraftReborn;
    RegisterSpellScript(spell_ascension_reborn_tidal_force);
    RegisterSpellScript(spell_ascension_reborn_totemic_projection);
}
