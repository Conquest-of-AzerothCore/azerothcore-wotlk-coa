/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionDifficultyRelease.h"
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

void SendReleasedDifficulties(Player* player)
{
    for (auto const& events : { HeroicDungeonEvents, MythicDungeonEvents })
        for (uint16 eventId : events)
        {
            WorldPacket data = BuildActiveEvent(eventId);
            player->SendDirectMessage(&data);
        }
}

class LoginAnnouncer : public PlayerScript
{
public:
    LoginAnnouncer() : PlayerScript("AscensionDifficultyRelease", {PLAYERHOOK_ON_LOGIN}) { }

    void OnPlayerLogin(Player* player) override
    {
        SendReleasedDifficulties(player);
    }
};
}

void AddSC_AscensionDifficultyRelease()
{
    new AscensionDifficultyRelease::LoginAnnouncer();
}
