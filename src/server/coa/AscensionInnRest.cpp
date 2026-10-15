/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"

namespace
{
enum InnRest : uint32
{
    SPELL_RESTING = 997615,
    SPELL_WELL_RESTED = 997616
};

class player_ascension_inn_rest : public PlayerScript
{
public:
    player_ascension_inn_rest() : PlayerScript("player_ascension_inn_rest", {PLAYERHOOK_ON_UPDATE}) { }

    void OnPlayerUpdate(Player* player, uint32) override
    {
        bool inInn = player->HasRestFlag(REST_FLAG_IN_TAVERN) && player->IsAlive();
        if (inInn == player->HasAura(SPELL_RESTING))
            return;

        if (inInn)
            player->CastSpell(player, SPELL_RESTING, TRIGGERED_FULL_MASK);
        else
            player->RemoveAurasDueToSpell(SPELL_RESTING);
    }
};

class aura_ascension_inn_resting : public AuraScript
{
    PrepareAuraScript(aura_ascension_inn_resting);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_WELL_RESTED});
    }

    void GrantWellRested(AuraEffect const*, AuraEffectHandleModes)
    {
        if (GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE)
            return;

        if (Player* player = GetTarget()->ToPlayer())
            player->CastSpell(player, SPELL_WELL_RESTED, TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_inn_resting::GrantWellRested,
            EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};
}

void AddSC_AscensionInnRest()
{
    new player_ascension_inn_rest();
    RegisterSpellScript(aura_ascension_inn_resting);
}
