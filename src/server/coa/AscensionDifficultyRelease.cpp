/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionDifficultyRelease.h"
#include "AscensionRaidReleasePolicy.h"
#include "Player.h"
#include "PlayerScript.h"

namespace AscensionDifficultyRelease
{
namespace
{
constexpr uint8 NormalEventState = 0;
constexpr uint8 Active = 1;
constexpr std::size_t ReservedSize = 28;
}

WorldPacket BuildActiveEvent(uint16 eventId)
{
    WorldPacket data(GameEventInfoOpcode, GameEventInfoSize);
    data << eventId << NormalEventState << uint64(0) << uint64(0) << Active << uint32(0);
    for (std::size_t i = 0; i < ReservedSize; ++i)
        data << uint8(0);
    return data;
}

std::vector<uint16> ReleasedEvents(uint32 releasedStage)
{
    std::vector<uint16> released;
    if (RaidRelease::IsDungeonDifficultyReleased(RaidRelease::DungeonDifficultyHeroic, releasedStage))
        released.insert(released.end(), HeroicDungeonEvents.begin(), HeroicDungeonEvents.end());
    if (RaidRelease::IsDungeonDifficultyReleased(RaidRelease::DungeonDifficultyMythic, releasedStage))
        released.insert(released.end(), MythicDungeonEvents.begin(), MythicDungeonEvents.end());
    return released;
}

void SendReleasedDifficulties(Player* player)
{
    for (uint16 eventId : ReleasedEvents(RaidRelease::ReleasedStage()))
    {
        WorldPacket data = BuildActiveEvent(eventId);
        player->SendDirectMessage(&data);
    }
}

class ReleaseAnnouncer : public PlayerScript
{
public:
    ReleaseAnnouncer() : PlayerScript("AscensionDifficultyRelease", {PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_MAP_CHANGED}) { }

    void OnPlayerLogin(Player* player) override
    {
        SendReleasedDifficulties(player);
    }

    void OnPlayerMapChanged(Player* player) override
    {
        if (!player->GetSession()->IsHeadlessBot())
            SendReleasedDifficulties(player);
    }
};
}

void AddSC_AscensionDifficultyRelease()
{
    new AscensionDifficultyRelease::ReleaseAnnouncer();
}
