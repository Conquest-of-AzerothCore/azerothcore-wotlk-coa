/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Unit.h"
#include <unordered_set>

namespace
{
enum WildcardPhysicalSpells : uint32
{
    ToolsOfWar = 271020,
    ToolsOfWarBuff = 271021,
    MartialCrescendo = 271051,
    MartialCrescendoBuff = 271052
};

class aura_wildcard_unique_physical_ability : public AuraScript
{
    PrepareAuraScript(aura_wildcard_unique_physical_ability);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ToolsOfWarBuff, MartialCrescendoBuff});
    }

    uint32 Buff() const
    {
        return GetId() == ToolsOfWar ? ToolsOfWarBuff : MartialCrescendoBuff;
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        return eventInfo.GetSpellInfo() && damage && damage->GetDamage();
    }

    void HandleProc(AuraEffect const*, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* target = GetTarget();
        Aura* buff = target->GetAura(Buff(), target->GetGUID());
        if (!buff)
            _used.clear();

        if (eventInfo.GetDamageInfo()->GetSchoolMask() & ~SPELL_SCHOOL_MASK_NORMAL)
        {
            target->RemoveAurasDueToSpell(Buff(), target->GetGUID());
            _used.clear();
            return;
        }

        if (eventInfo.GetTypeMask() & PROC_FLAG_DONE_PERIODIC)
            return;

        if (!_used.insert(sSpellMgr->GetFirstSpellInChain(eventInfo.GetSpellInfo()->Id)).second)
            return;

        if (!buff)
        {
            target->CastSpell(target, Buff(), true);
            return;
        }

        int32 const duration = buff->GetDuration();
        buff->ModStackAmount(1);
        buff->SetDuration(duration);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_unique_physical_ability::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_unique_physical_ability::HandleProc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }

    std::unordered_set<uint32> _used;
};
}

void AddSC_AscensionWildcardPhysical()
{
    RegisterSpellScript(aura_wildcard_unique_physical_ability);
}
