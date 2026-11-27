/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionGlory.h"
#include "AllBattlegroundScript.h"
#include "Battleground.h"
#include "BattlegroundScore.h"
#include "Chat.h"
#include "Player.h"
#include "PlayerScript.h"
#include "StringFormat.h"
#include <algorithm>
#include <limits>

namespace AscensionGlory
{
uint32 Accrue(uint32 glory, uint32 earned)
{
    return glory + std::min(earned, std::numeric_limits<uint32>::max() - glory);
}

uint32 ObjectiveReward(BattlegroundTypeId bgType, uint32 scoreType, uint32 count)
{
    uint32 each = 0;
    switch (scoreType)
    {
        case SCORE_FLAG_CAPTURES:
            each = bgType == BATTLEGROUND_WS ? WarsongFlagCaptureGlory : ObjectiveGlory;
            break;
        case SCORE_BASES_ASSAULTED:
        case SCORE_BASES_DEFENDED:
        case SCORE_GRAVEYARDS_ASSAULTED:
        case SCORE_GRAVEYARDS_DEFENDED:
        case SCORE_TOWERS_ASSAULTED:
        case SCORE_TOWERS_DEFENDED:
        case SCORE_MINES_CAPTURED:
            each = ObjectiveGlory;
            break;
        default:
            return 0;
    }

    return uint32(std::min<uint64>(uint64(each) * count, std::numeric_limits<uint32>::max()));
}

uint32 GloryToNextRank(uint32 glory)
{
    auto const next = std::upper_bound(RankThresholds.begin(), RankThresholds.end(), glory);
    return next == RankThresholds.end() ? 0 : *next - glory;
}

std::string GainMessage(uint32 earned, uint32 total)
{
    uint32 const needed = GloryToNextRank(total);
    if (!needed)
        return Acore::StringFormat("You gained {} Glory.", earned);

    return Acore::StringFormat("You gained {} Glory. {} Glory needed to reach the next rank.", earned, needed);
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
    uint32 const total = Accrue(Get(player), glory);
    player->UpdatePlayerSetting(Setting, 0, total);
    Send(player);
    ChatHandler(player->GetSession()).SendSysMessage(GainMessage(glory, total));
}

void Send(Player* player)
{
    WorldPacket data = BuildUpdate(player->GetGUID(), Get(player));
    player->SendDirectMessage(&data);
}

class KillingBlowTracker : public PlayerScript
{
public:
    KillingBlowTracker() : PlayerScript("AscensionGlory",
        {PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_MAP_CHANGED, PLAYERHOOK_ON_VICTIM_REWARD_AFTER,
            PLAYERHOOK_ON_HONORABLE_KILLING_BLOW}) { }

    void OnPlayerLogin(Player* player) override
    {
        Send(player);
    }

    void OnPlayerMapChanged(Player* player) override
    {
        if (player->IsInWorld())
            Send(player);
    }

    void OnPlayerVictimRewardAfter(Player* player, Player*, uint32&, int32&, float&) override
    {
        Earn(player, HonorableKillGlory);
    }

    void OnPlayerHonorableKillingBlow(Player* killer, Player*) override
    {
        Earn(killer, KillingBlowBonusGlory);
    }
};

class ObjectiveTracker : public AllBattlegroundScript
{
public:
    ObjectiveTracker() : AllBattlegroundScript("AscensionGloryObjectives",
        {ALLBATTLEGROUNDHOOK_ON_BATTLEGROUND_UPDATE_PLAYER_SCORE}) { }

    void OnBattlegroundUpdatePlayerScore(Battleground* bg, Player* player, uint32 type, uint32 value) override
    {
        uint32 const glory = ObjectiveReward(bg->GetBgTypeID(), type, value);
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
