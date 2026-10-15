/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuras.h"
#include "Unit.h"

namespace
{
enum MysticThunderSpells : uint32
{
    SPELL_MYSTIC_THUNDER_MARK = 505214,
    SPELL_MYSTIC_THUNDER_SILENCE = 505347
};

class stormbringer_mystic_thunder : public AllSpellScript
{
public:
    stormbringer_mystic_thunder() : AllSpellScript("stormbringer_mystic_thunder", {ALLSPELLHOOK_ON_CAST}) { }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const*, bool) override
    {
        if (!spell || !caster || spell->IsTriggered())
            return;

        Aura* mark = caster->GetAura(SPELL_MYSTIC_THUNDER_MARK);
        if (!mark)
            return;

        ObjectGuid marker = mark->GetCasterGUID();
        caster->RemoveAurasDueToSpell(SPELL_MYSTIC_THUNDER_MARK, marker);
        caster->CastSpell(caster, SPELL_MYSTIC_THUNDER_SILENCE, true, nullptr, nullptr, marker);
    }
};
}

void AddSC_AscensionStormbringerMysticThunder()
{
    new stormbringer_mystic_thunder();
}
