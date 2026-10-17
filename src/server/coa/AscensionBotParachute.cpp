/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "WorldSession.h"

namespace
{
constexpr uint32 SPELL_PARACHUTE_BUFF = 44795;

bool IsBot(Player const* player)
{
    WorldSession* session = player->GetSession();
    return !session || session->IsBot();
}

bool Grounded(Unit const* unit)
{
    return !unit->IsFalling();
}

class coa_bot_parachute : public PlayerScript
{
public:
    coa_bot_parachute() : PlayerScript("coa_bot_parachute", { PLAYERHOOK_ON_UPDATE }) { }

    void OnPlayerUpdate(Player* player, uint32) override
    {
        if (!IsBot(player) || player->IsInFlight() || !player->HasAura(SPELL_PARACHUTE_BUFF))
            return;

        if (Grounded(player))
            player->RemoveAurasDueToSpell(SPELL_PARACHUTE_BUFF);
    }
};
}

void AddSC_AscensionBotParachute()
{
    new coa_bot_parachute();
}
