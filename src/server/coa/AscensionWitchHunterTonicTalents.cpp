/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <array>
#include <limits>

namespace
{
constexpr uint32 SPELL_TONIC_SUPPLY = 705497;
constexpr std::array<uint32, 11> WITCH_HUNTER_TONIC_CASTS =
{{
    680491, 572295, 572296, 572297, 572298,
    802276, 802277, 802278, 802279, 802308, 802826
}};

uint32 GetWitchHunterTonicRoot(SpellInfo const* spellInfo)
{
    if (!spellInfo || spellInfo->SpellFamilyName != uint32(CLASS_WITCH_HUNTER) + 6 ||
        !(spellInfo->SpellFamilyFlags[2] & 512))
        return 0;

    switch (spellInfo->Id)
    {
        case 572295:
        case 572296:
        case 572297:
        case 572298:
        case 680491:
            return 680491;
        case 802308:
        case 802279:
            return 802279;
        case 802276:
        case 802277:
        case 802278:
        case 802826:
            return spellInfo->Id;
        default:
            return 0;
    }
}

class spell_ascension_witch_hunter_tonic_supply : public SpellScript
{
    PrepareSpellScript(spell_ascension_witch_hunter_tonic_supply);

    bool Validate(SpellInfo const* spellInfo) override
    {
        SpellInfo const* talent = sSpellMgr->GetSpellInfo(SPELL_TONIC_SUPPLY);
        return GetWitchHunterTonicRoot(spellInfo) && talent &&
            talent->SpellFamilyName == uint32(CLASS_WITCH_HUNTER) + 6 &&
            talent->Effects[EFFECT_0].IsAura(SPELL_AURA_DUMMY);
    }

    bool Load() override
    {
        Unit* caster = GetCaster();
        return caster && caster->IsPlayer() && caster->ToPlayer()->getClass() == CLASS_WITCH_HUNTER && !GetSpell()->IsTriggered();
    }

    void ReduceOtherTonics()
    {
        Player* player = GetCaster()->ToPlayer();
        AuraEffect const* effect = player->GetAuraEffect(SPELL_TONIC_SUPPLY, EFFECT_0);
        if (!effect || effect->GetAmount() >= 0)
            return;

        uint32 reduction = uint32(std::min(-int64(effect->GetAmount()), int64(std::numeric_limits<int32>::max())));
        uint32 consumedRoot = GetWitchHunterTonicRoot(GetSpellInfo());
        if (!consumedRoot)
            return;

        for (uint32 id : WITCH_HUNTER_TONIC_CASTS)
        {
            uint32 otherRoot = GetWitchHunterTonicRoot(sSpellMgr->GetSpellInfo(id));
            if (!otherRoot || otherRoot == consumedRoot)
                continue;

            uint32 remaining = player->GetSpellCooldownDelay(id);
            if (!remaining)
                continue;

            if (remaining <= reduction)
                player->RemoveSpellCooldown(id, true);
            else
                player->ModifySpellCooldown(id, -int32(reduction));
        }
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_ascension_witch_hunter_tonic_supply::ReduceOtherTonics);
    }
};
}

void AddAscensionWitchHunterTonicTalentScripts()
{
    RegisterSpellScript(spell_ascension_witch_hunter_tonic_supply);
}
