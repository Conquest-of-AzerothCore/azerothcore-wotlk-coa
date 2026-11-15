/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionCustomClassData.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include <algorithm>
#include <string_view>

namespace
{
bool TaughtByClass(uint32 spellId)
{
    return std::any_of(AscensionCompatData::ClassSpells.begin(), AscensionCompatData::ClassSpells.end(),
        [spellId](AscensionCompatData::ClassSpell const& spell) { return spell.SpellId == spellId; });
}

class greater_class_buffs_allow_low_level : public GlobalScript
{
public:
    greater_class_buffs_allow_low_level() : GlobalScript("greater_class_buffs_allow_low_level",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (!info->SpellName[0] || !std::string_view(info->SpellName[0]).starts_with("Greater "))
            return;
        bool raidAura = std::any_of(std::begin(info->Effects), std::end(info->Effects), [](SpellEffectInfo const& effect)
        {
            return effect.Effect == SPELL_EFFECT_APPLY_AURA && effect.TargetA.GetTarget() == TARGET_UNIT_CASTER_AREA_RAID;
        });
        if (raidAura && TaughtByClass(info->Id))
            info->AttributesEx2 |= SPELL_ATTR2_ALLOW_LOW_LEVEL_BUFF;
    }
};
}

void AddSC_AscensionGreaterClassBuffs()
{
    new greater_class_buffs_allow_low_level();
}
