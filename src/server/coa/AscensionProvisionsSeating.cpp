/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "SpellInfo.h"

namespace
{
enum ProvisionsSpells : uint32
{
    EatProvisions = 901543
};

class ascension_provisions_seating : public GlobalScript
{
public:
    ascension_provisions_seating() : GlobalScript("ascension_provisions_seating",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == EatProvisions)
            info->AuraInterruptFlags |= AURA_INTERRUPT_FLAG_NOT_SEATED;
    }
};
}

void AddSC_AscensionProvisionsSeating()
{
    new ascension_provisions_seating();
}
