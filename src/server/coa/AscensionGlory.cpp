/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionGlory.h"
#include "AllBattlegroundScript.h"
#include "Battleground.h"
#include "BattlegroundScore.h"
#include "Player.h"
#include "PlayerScript.h"
#include <algorithm>
#include <limits>

namespace AscensionGlory
{
uint32 Accrue(uint32 glory, uint32 earned)
{
    return glory + std::min(earned, std::numeric_limits<uint32>::max() - glory);
}

uint32 ObjectiveReward(uint32 scoreType, uint32 count)
{
    switch (scoreType)
    {
        case SCORE_FLAG_CAPTURES:
        case SCORE_BASES_ASSAULTED:
        case SCORE_BASES_DEFENDED:
        case SCORE_GRAVEYARDS_ASSAULTED:
        case SCORE_GRAVEYARDS_DEFENDED:
        case SCORE_TOWERS_ASSAULTED:
        case SCORE_TOWERS_DEFENDED:
        case SCORE_MINES_CAPTURED:
            return uint32(std::min<uint64>(uint64(ObjectiveGlory) * count, std::numeric_limits<uint32>::max()));
        default:
            return 0;
    }
}

WorldPacket BuildUpdate(ObjectGuid guid, uint32 glory)
{
    WorldPacket data(UpdateObjectAddonOpcode, 16);
    data << guid << AddonField << glory;
    return data;
}

uint32 Get(Player const* player)
{
    PlayerSettingVector const* settings = player->FindPlayerSettings(Setting);
    return settings && !settings->empty() ? settings->front().value : 0;
}

void Earn(Player* player, uint32 glory)
{
    player->UpdatePlayerSetting(Setting, 0, Accrue(Get(player), glory));
    Send(player);
}

void Send(Player* player)
{
    WorldPacket data = BuildUpdate(player->GetGUID(), Get(player));
    player->SendDirectMessage(&data);
}

class KillingBlowTracker : public PlayerScript
{
public:
    KillingBlowTracker() : PlayerScript("AscensionGlory", {PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_HONORABLE_KILLING_BLOW}) { }

    void OnPlayerLogin(Player* player) override
    {
        Send(player);
    }

    void OnPlayerHonorableKillingBlow(Player* killer, Player*) override
    {
        Earn(killer, KillingBlowGlory);
    }
};

class ObjectiveTracker : public AllBattlegroundScript
{
public:
    ObjectiveTracker() : AllBattlegroundScript("AscensionGloryObjectives",
        {ALLBATTLEGROUNDHOOK_ON_BATTLEGROUND_UPDATE_PLAYER_SCORE}) { }

    void OnBattlegroundUpdatePlayerScore(Battleground* bg, Player* player, uint32 type, uint32 value) override
    {
        uint32 const glory = ObjectiveReward(type, value);
        if (!glory)
            return;

        TeamId const team = player->GetBgTeamId();
        for (auto const& [guid, member] : bg->GetPlayers())
            if (member->GetBgTeamId() == team)
                Earn(member, glory);
    }
};
}

void AddSC_AscensionGlory()
{
    new AscensionGlory::KillingBlowTracker();
    new AscensionGlory::ObjectiveTracker();
}
