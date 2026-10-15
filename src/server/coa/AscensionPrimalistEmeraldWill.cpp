/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellInfo.h"

namespace
{
enum EmeraldWillSpells : uint32
{
    EmeraldWill = 500302,
    SoothingTouch = 520841,
    EmeraldWillHeal = 525015
};

class primalist_emerald_will : public AllSpellScript
{
public:
    primalist_emerald_will() : AllSpellScript("primalist_emerald_will",
        {ALLSPELLHOOK_ON_SUCCESSFUL_DISPEL}) { }

    void OnSpellSuccessfulDispel(Spell* spell, Unit* target, SpellEffIndex effect, uint32 count) override
    {
        Unit* caster = spell->GetCaster();
        SpellInfo const* info = spell->GetSpellInfo();
        if (!count || !target || !target->IsAlive() || !caster->IsPlayer() ||
            caster->getClass() != CLASS_WILDWALKER || info->Id != SoothingTouch || info->SpellFamilyName != 37 ||
            !caster->HasAura(EmeraldWill, caster->GetGUID()))
            return;
        int32 type = info->Effects[effect].MiscValue;
        if (type == DISPEL_POISON || type == DISPEL_DISEASE)
            caster->CastSpell(target, EmeraldWillHeal, TRIGGERED_FULL_MASK);
    }
};
}

void AddSC_AscensionPrimalistEmeraldWill()
{
    new primalist_emerald_will();
}
