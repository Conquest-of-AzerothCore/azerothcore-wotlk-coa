/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Battleground.h"
#include "BattlegroundMgr.h"
#include "GameGraveyard.h"
#include "Map.h"
#include "Player.h"
#include "ScriptMgr.h"

namespace
{
Creature* ClosestOwnSpiritGuide(Player* player, Battleground* bg, GraveyardStruct const* grave)
{
    uint32 const ownGuideEntry = player->GetBgTeamId() == TEAM_ALLIANCE
        ? BG_CREATURE_ENTRY_A_SPIRITGUIDE : BG_CREATURE_ENTRY_H_SPIRITGUIDE;

    Creature* closest = nullptr;
    float closestDistance = 0.0f;
    for (ObjectGuid const& guid : bg->BgCreatures)
    {
        Creature* guide = player->GetMap()->GetCreature(guid);
        if (!guide || !guide->IsSpiritGuide() || guide->GetEntry() != ownGuideEntry)
            continue;

        float const distance = guide->GetExactDistSq(grave->x, grave->y, grave->z);
        if (!closest || distance < closestDistance)
        {
            closest = guide;
            closestDistance = distance;
        }
    }
    return closest;
}

class ascension_battleground_spirit_queue : public PlayerScript
{
public:
    ascension_battleground_spirit_queue()
        : PlayerScript("ascension_battleground_spirit_queue", {PLAYERHOOK_ON_PLAYER_RELEASED_GHOST}) { }

    void OnPlayerReleasedGhost(Player* player) override
    {
        Battleground* bg = player->GetBattleground();
        if (!bg || bg->isArena() || bg->GetStatus() != STATUS_IN_PROGRESS)
            return;

        GraveyardStruct const* grave = bg->GetClosestGraveyard(player);
        if (!grave)
            return;

        Creature* guide = ClosestOwnSpiritGuide(player, bg, grave);
        if (!guide)
            return;

        bg->AddPlayerToResurrectQueue(guide->GetGUID(), player->GetGUID());
        sBattlegroundMgr->SendAreaSpiritHealerQueryOpcode(player, bg, guide->GetGUID());
    }
};
}

void AddSC_AscensionBattlegroundSpiritQueue()
{
    new ascension_battleground_spirit_queue();
}
