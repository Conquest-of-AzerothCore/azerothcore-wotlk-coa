/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionScalingBaseData.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "Unit.h"

#include <algorithm>

namespace
{
double ScalingBase(uint8 level)
{
    return 0.0267291844060354 + 0.0048541098014737 * level + 0.0001859597762293 * level * level;
}

Player const* LevelOwner(Unit const* caster)
{
    if (!caster)
        return nullptr;
    if (Player const* player = caster->ToPlayer())
        return player;
    if (Unit const* owner = caster->GetOwner())
        return owner->ToPlayer();
    return nullptr;
}

class ascension_scaling_base : public UnitScript
{
public:
    ascension_scaling_base() : UnitScript("ascension_scaling_base",
        true, {UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE}) { }

    void ModifySpellEffectBaseValue(Unit const* caster, SpellInfo const* info, uint8 index,
        float& value) override
    {
        if (!info || index >= MAX_SPELL_EFFECTS || value == 0.0f)
            return;

        auto const entry = std::lower_bound(AscensionCompatData::ScalingBaseSpells.begin(),
            AscensionCompatData::ScalingBaseSpells.end(), info->Id,
            [](AscensionCompatData::ScalingBaseEntry const& row, uint32 id) { return row.Spell < id; });
        if (entry == AscensionCompatData::ScalingBaseSpells.end() || entry->Spell != info->Id ||
            !(entry->EffectMask & (1 << index)))
            return;

        Player const* player = LevelOwner(caster);
        if (!player)
            return;

        value = float(double(value) * ScalingBase(player->GetLevel()));
    }
};
}

void AddAscensionScalingBaseScripts()
{
    new ascension_scaling_base();
}
