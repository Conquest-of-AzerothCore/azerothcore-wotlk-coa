/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Unit.h"

namespace
{
constexpr uint32 SunderArmorMaxRank = 58567;
constexpr uint32 DeconstructionBuff = 954083;

class spell_wildcard_deconstruct : public SpellScript
{
    PrepareSpellScript(spell_wildcard_deconstruct);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({DeconstructionBuff});
    }

    void HandleHit()
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!caster || !target)
            return;

        uint32 const sunderArmorId = sSpellMgr->GetSpellTwinFor(SunderArmorMaxRank, GetSpellInfo()->Id);
        Aura const* sunderArmor = sunderArmorId ? target->GetAura(sunderArmorId, caster->GetGUID()) : nullptr;
        if (!sunderArmor)
            return;

        int32 const duration = sunderArmor->GetStackAmount() * 1000;
        caster->CastSpell(caster, DeconstructionBuff, true);
        if (Aura* buff = caster->GetAura(DeconstructionBuff, caster->GetGUID()))
        {
            buff->SetMaxDuration(duration);
            buff->SetDuration(duration);
        }
    }

    void Register() override
    {
        AfterHit += SpellHitFn(spell_wildcard_deconstruct::HandleHit);
    }
};
}

void AddSC_AscensionWildcardDeconstruct()
{
    RegisterSpellScript(spell_wildcard_deconstruct);
}
