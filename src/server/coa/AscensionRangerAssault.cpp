/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Item.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellScript.h"
#include <algorithm>
#include <limits>

namespace
{
class spell_ascension_ranger_assault : public SpellScript
{
    PrepareSpellScript(spell_ascension_ranger_assault);

    bool _scaled = false;

    bool Validate(SpellInfo const* spellInfo) override
    {
        return spellInfo && (spellInfo->Id == 803108 || (spellInfo->Id >= 503099 && spellInfo->Id <= 503105)) &&
            spellInfo->SpellFamilyName == uint32(CLASS_RANGER) + 6 &&
            spellInfo->SpellFamilyFlags == flag96(0, 32768, 0) && spellInfo->DmgClass == SPELL_DAMAGE_CLASS_MELEE &&
            spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_SCHOOL_DAMAGE &&
            spellInfo->Effects[EFFECT_2].Effect == SPELL_EFFECT_WEAPON_PERCENT_DAMAGE &&
            spellInfo->Effects[EFFECT_2].BasePoints == 99 && spellInfo->Effects[EFFECT_2].DieSides == 1;
    }

    bool Load() override
    {
        Unit* caster = GetCaster();
        return caster && caster->IsPlayer() && caster->ToPlayer()->getClass() == CLASS_RANGER;
    }

    void ScaleWeaponDamage(SpellEffIndex)
    {
        if (_scaled)
            return;
        _scaled = true;

        Player* caster = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        Item* weapon = caster ? caster->GetWeaponForAttack(BASE_ATTACK, true) : nullptr;
        if (!weapon || weapon->GetTemplate()->SubClass != ITEM_SUBCLASS_WEAPON_DAGGER)
            return;

        int64 const percent = (int64(GetSpellValue()->EffectBasePoints[EFFECT_2]) + 1) * 7 / 4;
        GetSpell()->SetSpellValue(SPELLVALUE_BASE_POINT2, int32(std::clamp<int64>(percent, 0, std::numeric_limits<int32>::max())));
    }

    void Register() override
    {
        OnEffectLaunch += SpellEffectFn(spell_ascension_ranger_assault::ScaleWeaponDamage, EFFECT_2, SPELL_EFFECT_WEAPON_PERCENT_DAMAGE);
    }
};
}

void AddAscensionRangerAssaultScripts()
{
    RegisterSpellScript(spell_ascension_ranger_assault);
}
