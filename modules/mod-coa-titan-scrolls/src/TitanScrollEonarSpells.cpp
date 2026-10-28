/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "SharedDefines.h"

namespace
{
constexpr uint32 TITAN_SCROLL_EONAR_BLESSING = 993963;

class titan_scroll_eonar_spells : public GlobalScript
{
public:
    titan_scroll_eonar_spells() : GlobalScript("titan_scroll_eonar_spells",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (!info)
            return;

        if (info->Id == TITAN_SCROLL_EONAR_BLESSING)
        {
            // Shipped with TargetB = TARGET_NONE on both effects, which routes
            // DynObjAura::FillTargetMap into AnyAoETargetUnitInObjectRangeCheck
            // (attackable units only) instead of AnyFriendlyUnitInObjectRangeCheck.
            // Without this the ground heal lands on nearby enemies, not the caster.
            for (uint8 i = EFFECT_0; i <= EFFECT_1; ++i)
                info->Effects[i].TargetB = SpellImplicitTargetInfo(TARGET_DEST_DYNOBJ_ALLY);
        }
    }
};
}

void AddSC_titan_scroll_eonar_spells()
{
    new titan_scroll_eonar_spells();
}
