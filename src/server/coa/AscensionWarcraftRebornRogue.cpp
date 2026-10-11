/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellScript.h"

namespace AscensionWarcraftReborn
{
namespace
{
constexpr uint32 HUNGER_FOR_BLOOD_BUFF = 1163848;
constexpr uint32 CUT_TO_THE_CHASE_REFRESH = 9931095;
constexpr uint32 ROGUE_EVISCERATE = 0x20000;
constexpr uint32 ROGUE_ENVENOM = 0x8;
constexpr uint32 ROGUE_CRIMSON_TEMPEST = 0x20000000;

class spell_ascension_reborn_hunger_for_blood : public SpellScript
{
    PrepareSpellScript(spell_ascension_reborn_hunger_for_blood);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ HUNGER_FOR_BLOOD_BUFF });
    }

    void HandleDummy(SpellEffIndex)
    {
        GetCaster()->CastSpell(GetCaster(), HUNGER_FOR_BLOOD_BUFF, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_reborn_hunger_for_blood::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

class spell_ascension_reborn_cut_to_the_chase : public AuraScript
{
    PrepareAuraScript(spell_ascension_reborn_cut_to_the_chase);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ CUT_TO_THE_CHASE_REFRESH });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* procSpell = eventInfo.GetSpellInfo();
        if (!procSpell || procSpell->SpellFamilyName != SPELLFAMILY_ROGUE)
            return false;
        flag96 const& flags = procSpell->SpellFamilyFlags;
        return (flags[0] & ROGUE_EVISCERATE) || (flags[1] & ROGUE_ENVENOM) || (flags[2] & ROGUE_CRIMSON_TEMPEST);
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo&)
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), CUT_TO_THE_CHASE_REFRESH, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_reborn_cut_to_the_chase::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_ascension_reborn_cut_to_the_chase::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};
}
}

void AddAscensionWarcraftRebornRogueScripts()
{
    using namespace AscensionWarcraftReborn;
    RegisterSpellScript(spell_ascension_reborn_hunger_for_blood);
    RegisterSpellScript(spell_ascension_reborn_cut_to_the_chase);
}
