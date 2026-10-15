/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "Unit.h"

namespace
{
constexpr uint32 SPELL_RAID_MARKER_REMOVAL = 499587;
constexpr uint32 SPELL_RAID_MARKER_FIRST = 499588;
constexpr uint32 SPELL_RAID_MARKER_LAST = 499595;

class spell_ascension_raid_marker_removal : public SpellScript
{
    PrepareSpellScript(spell_ascension_raid_marker_removal);

    bool Validate(SpellInfo const* info) override
    {
        return info->Id == SPELL_RAID_MARKER_REMOVAL && info->Effects[EFFECT_0].Effect == SPELL_EFFECT_DUMMY;
    }

    void RemoveMarkers(SpellEffIndex)
    {
        Unit* caster = GetCaster();
        for (uint32 spellId = SPELL_RAID_MARKER_FIRST; spellId <= SPELL_RAID_MARKER_LAST; ++spellId)
            caster->RemoveDynObject(spellId);
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_ascension_raid_marker_removal::RemoveMarkers, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};
}

void AddAscensionRaidMarkerScripts()
{
    RegisterSpellScript(spell_ascension_raid_marker_removal);
}
