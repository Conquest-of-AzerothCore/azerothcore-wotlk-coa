/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Creature.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"

namespace
{
constexpr uint32 SPELL_BARNABUS_WHISTLE = 79347;
constexpr uint32 CREATURE_BARNABUS = 2753;

class spell_ascension_barnabus_whistle : public SpellScript
{
    PrepareSpellScript(spell_ascension_barnabus_whistle);

    bool Validate(SpellInfo const* info) override
    {
        return info->Id == SPELL_BARNABUS_WHISTLE && info->Effects[EFFECT_0].Effect == SPELL_EFFECT_DUMMY;
    }

    SpellCastResult CheckCast()
    {
        Player* player = GetCaster()->ToPlayer();
        CreatureTemplate const* creature = sObjectMgr->GetCreatureTemplate(CREATURE_BARNABUS);
        if (!player || !creature || !creature->IsTameable(player->CanTameExoticPets()))
            return SPELL_FAILED_BAD_TARGETS;
        if (player->GetPetGUID() || player->GetCharmGUID() || player->IsExistPet())
            return SPELL_FAILED_ALREADY_HAVE_SUMMON;
        return SPELL_CAST_OK;
    }

    void Tame(SpellEffIndex effect)
    {
        PreventHitDefaultEffect(effect);
        if (Player* player = GetHitPlayer())
            player->CreatePet(CREATURE_BARNABUS, SPELL_BARNABUS_WHISTLE);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_barnabus_whistle::CheckCast);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_barnabus_whistle::Tame, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};
}

void AddAscensionBarnabusWhistleScripts()
{
    RegisterSpellScript(spell_ascension_barnabus_whistle);
}
