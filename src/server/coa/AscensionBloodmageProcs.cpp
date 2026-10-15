/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Unit.h"

namespace
{

constexpr uint32 BLOODMAGE_SPELL_FAMILY = 26;
constexpr uint32 BLOODMAGE_BLOOD_CRAVING = 800780;

constexpr uint32 GRIM_OMEN_STRIKE_MASK1 = 1 | 8388608;

constexpr uint32 BLOODMAGE_HOWL_MASK1 = 4;
constexpr uint32 BLOODMAGE_HOWL_MASK2 = 128 | 2048 | 131072;

class aura_ascension_bloodmage_infection : public AuraScript
{
    PrepareAuraScript(aura_ascension_bloodmage_infection);

    bool CheckProc(ProcEventInfo& event)
    {
        Unit* victim = event.GetActionTarget();
        return victim && victim->HasAuraWithMechanic(1ULL << MECHANIC_BLEED);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_bloodmage_infection::CheckProc);
    }
};

class aura_ascension_bloodmage_grim_omen : public AuraScript
{
    PrepareAuraScript(aura_ascension_bloodmage_grim_omen);

    bool CheckProc(ProcEventInfo& event)
    {
        SpellInfo const* spellInfo = event.GetSpellInfo();
        if (!spellInfo || spellInfo->SpellFamilyName != BLOODMAGE_SPELL_FAMILY)
            return false;

        if (spellInfo->SpellFamilyFlags.HasFlag(0, BLOODMAGE_HOWL_MASK1, BLOODMAGE_HOWL_MASK2))
            return (event.GetSpellPhaseMask() & PROC_SPELL_PHASE_CAST) != 0;

        if (spellInfo->SpellFamilyFlags.HasFlag(0, GRIM_OMEN_STRIKE_MASK1, 0))
            return (event.GetSpellPhaseMask() & PROC_SPELL_PHASE_HIT) != 0 &&
                (event.GetHitMask() & PROC_HIT_CRITICAL) != 0;

        return false;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_bloodmage_grim_omen::CheckProc);
    }
};

class aura_ascension_bloodmage_packleader : public AuraScript
{
    PrepareAuraScript(aura_ascension_bloodmage_packleader);

    bool CheckProc(ProcEventInfo& event)
    {
        SpellInfo const* spellInfo = event.GetSpellInfo();
        return spellInfo && spellInfo->Id != BLOODMAGE_BLOOD_CRAVING &&
            spellInfo->SpellFamilyName == BLOODMAGE_SPELL_FAMILY &&
            spellInfo->SpellFamilyFlags.HasFlag(0, BLOODMAGE_HOWL_MASK1, BLOODMAGE_HOWL_MASK2) &&
            (event.GetSpellPhaseMask() & PROC_SPELL_PHASE_CAST) != 0;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_bloodmage_packleader::CheckProc);
    }
};

class aura_ascension_bloodmage_malediction : public AuraScript
{
    PrepareAuraScript(aura_ascension_bloodmage_malediction);

    bool CheckProc(ProcEventInfo& event)
    {
        Unit* actor = event.GetActor();
        return actor && actor->GetGUID() == GetCasterGUID();
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_bloodmage_malediction::CheckProc);
    }
};
}

void AddSC_AscensionBloodmageProcs()
{
    RegisterSpellScript(aura_ascension_bloodmage_infection);
    RegisterSpellScript(aura_ascension_bloodmage_grim_omen);
    RegisterSpellScript(aura_ascension_bloodmage_packleader);
    RegisterSpellScript(aura_ascension_bloodmage_malediction);
}
