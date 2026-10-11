/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "UnitDefines.h"

namespace
{
constexpr uint32 TREE_OF_LIFE = 33891;
constexpr uint32 DRUID_THORNS = 0x100;
constexpr uint32 DRUID_NATURES_GRASP = 0x100000;
constexpr uint32 DRUID_INNERVATE = 0x1000;
constexpr uint32 DRUID_BARKSKIN = 0x40000;

bool IsHealingSpell(SpellInfo const* spell)
{
    return spell->HasEffect(SPELL_EFFECT_HEAL) || spell->HasEffect(SPELL_EFFECT_HEAL_PCT) ||
        spell->HasEffect(SPELL_EFFECT_HEAL_MAX_HEALTH) || spell->HasAura(SPELL_AURA_PERIODIC_HEAL) ||
        spell->HasAura(SPELL_AURA_OBS_MOD_HEALTH);
}

bool IsNamedTreeSpell(SpellInfo const* spell)
{
    if (spell->SpellFamilyName != SPELLFAMILY_DRUID)
        return false;
    flag96 const& flags = spell->SpellFamilyFlags;
    return (flags[0] & (DRUID_THORNS | DRUID_NATURES_GRASP)) || (flags[1] & (DRUID_INNERVATE | DRUID_BARKSKIN));
}

bool AllowedInTreeOfLife(SpellInfo const* spell)
{
    return spell->Id == TREE_OF_LIFE || IsHealingSpell(spell) || IsNamedTreeSpell(spell) ||
        (spell->IsPositive() && spell->CheckShapeshift(FORM_TREE) == SPELL_CAST_OK);
}

class aura_ascension_tree_of_life : public AuraScript
{
    PrepareAuraScript(aura_ascension_tree_of_life);

    bool CheckProc(ProcEventInfo&)
    {
        return false;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_tree_of_life::CheckProc);
    }
};

class AscensionTreeOfLifeCasts : public AllSpellScript
{
public:
    AscensionTreeOfLifeCasts() : AllSpellScript("AscensionTreeOfLifeCasts", { ALLSPELLHOOK_ON_SPELL_CHECK_CAST }) { }

    void OnSpellCheckCast(Spell* spell, bool strict, SpellCastResult& result) override
    {
        Player* player = spell->GetCaster()->ToPlayer();
        if (!strict || result != SPELL_CAST_OK || !player || spell->IsTriggered() ||
            player->GetShapeshiftForm() != FORM_TREE)
            return;
        if (!AllowedInTreeOfLife(spell->GetSpellInfo()))
            player->RemoveAurasByType(SPELL_AURA_MOD_SHAPESHIFT);
    }
};
}

void AddSC_AscensionTreeOfLife()
{
    RegisterSpellScript(aura_ascension_tree_of_life);
    new AscensionTreeOfLifeCasts();
}
