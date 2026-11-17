/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellInfo.h"
#include "Unit.h"

namespace
{
constexpr uint32 MagmaFissureInstantCast = 803299;

bool IsMagmaFissure(SpellInfo const* info)
{
    switch (info->Id)
    {
        case 802793:
        case 803826:
        case 803827:
        case 803828:
        case 803829:
            return info->SpellFamilyName == 37;
        default:
            return false;
    }
}

class primalist_magma_fissure_metadata : public GlobalScript
{
public:
    primalist_magma_fissure_metadata() : GlobalScript("primalist_magma_fissure_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (IsMagmaFissure(info))
            info->AscensionIgnoreAbsorb = true;
    }
};

class primalist_magma_fissure_instant_cast : public AllSpellScript
{
public:
    primalist_magma_fissure_instant_cast() : AllSpellScript("primalist_magma_fissure_instant_cast",
        {ALLSPELLHOOK_ON_CAST}) { }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* spellInfo, bool) override
    {
        if (caster && caster->IsPlayer() && !spell->IsTriggered() && IsMagmaFissure(spellInfo))
            caster->CastSpell(caster, MagmaFissureInstantCast, true);
    }
};
}

void AddSC_AscensionPrimalistMagmaFissure()
{
    new primalist_magma_fissure_metadata();
    new primalist_magma_fissure_instant_cast();
}
