/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellInfo.h"

namespace
{
class primalist_physical_spell_crit : public AllSpellScript
{
public:
    primalist_physical_spell_crit() : AllSpellScript("primalist_physical_spell_crit",
        {ALLSPELLHOOK_ON_CRIT_CHANCE}) { }

    void OnSpellCritChance(Spell* spell, Unit* target, float& chance) override
    {
        Unit* caster = spell->GetCaster();
        SpellInfo const* info = spell->GetSpellInfo();
        if (!target || !caster->IsPlayer() || caster->getClass() != CLASS_WILDWALKER ||
            info->SpellFamilyName != 37 || info->DmgClass != SPELL_DAMAGE_CLASS_MAGIC ||
            info->GetSchoolMask() != SPELL_SCHOOL_MASK_NORMAL || !info->IsCritCapable() ||
            info->HasAttribute(SPELL_ATTR2_CANT_CRIT))
            return;
        chance += caster->SpellDoneCritChance(target, info, SPELL_SCHOOL_MASK_NATURE, BASE_ATTACK, false) -
            caster->SpellDoneCritChance(target, info, info->GetSchoolMask(), BASE_ATTACK, false);
    }
};
}

void AddSC_AscensionPrimalistPhysicalCrit()
{
    new primalist_physical_spell_crit();
}
