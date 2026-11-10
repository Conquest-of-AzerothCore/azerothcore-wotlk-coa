/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AllBattlegroundScript.h"
#include "Battleground.h"
#include "BattlegroundMgr.h"
#include "GameGraveyard.h"
#include "Map.h"
#include "Player.h"
#include "ScriptMgr.h"
#include <algorithm>

namespace
{
constexpr float SPIRIT_GUIDE_QUEUE_RANGE = 30.0f;
constexpr uint32 QUEUE_CHECK_INTERVAL_MS = 1000;

Creature* ClosestOwnSpiritGuide(Player* player, Battleground* bg, float x, float y, float z)
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

        float const distance = guide->GetExactDistSq(x, y, z);
        if (!closest || distance < closestDistance)
        {
            closest = guide;
            closestDistance = distance;
        }
    }
    return closest;
}

void QueueAt(Player* player, Battleground* bg, Creature* guide)
{
    bg->AddPlayerToResurrectQueue(guide->GetGUID(), player->GetGUID());
    sBattlegroundMgr->SendAreaSpiritHealerQueryOpcode(player, bg, guide->GetGUID());
}

void KeepQueuedOnlyNearOwnGuide(Player* player, Battleground* bg)
{
    Creature* guide = ClosestOwnSpiritGuide(player, bg, player->GetPositionX(), player->GetPositionY(),
        player->GetPositionZ());
    bool const inRange = guide && guide->GetExactDist(player) <= SPIRIT_GUIDE_QUEUE_RANGE;
    bool const queued = bg->IsPlayerInResurrectQueue(player->GetGUID());
    if (inRange && !queued)
        QueueAt(player, bg, guide);
    else if (!inRange && queued)
        bg->RemovePlayerFromResurrectQueue(player);
}

bool QueueCheckDue(Battleground const* bg, uint32 diff)
{
    uint32 const now = bg->GetStartTime();
    return now / QUEUE_CHECK_INTERVAL_MS != (now - std::min(now, diff)) / QUEUE_CHECK_INTERVAL_MS;
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

        if (Creature* guide = ClosestOwnSpiritGuide(player, bg, grave->x, grave->y, grave->z))
            QueueAt(player, bg, guide);
    }
};

class ascension_battleground_spirit_queue_range : public AllBattlegroundScript
{
public:
    ascension_battleground_spirit_queue_range()
        : AllBattlegroundScript("ascension_battleground_spirit_queue_range",
            {ALLBATTLEGROUNDHOOK_ON_BATTLEGROUND_UPDATE}) { }

    void OnBattlegroundUpdate(Battleground* bg, uint32 diff) override
    {
        if (bg->isArena() || bg->GetStatus() != STATUS_IN_PROGRESS || !QueueCheckDue(bg, diff))
            return;

        for (auto const& [guid, player] : bg->GetPlayers())
            if (player->IsInWorld() && player->HasPlayerFlag(PLAYER_FLAGS_GHOST) && !player->IsBeingTeleported())
                KeepQueuedOnlyNearOwnGuide(player, bg);
    }
};
}

void AddSC_AscensionBattlegroundSpiritQueue()
{
    new ascension_battleground_spirit_queue();
    new ascension_battleground_spirit_queue_range();
}
