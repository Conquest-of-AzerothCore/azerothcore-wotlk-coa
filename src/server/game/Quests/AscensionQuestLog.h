/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_QUEST_LOG_H
#define ASCENSION_QUEST_LOG_H

#include "ObjectGuid.h"
#include "WorldPacket.h"

class Player;
class Quest;

namespace AscensionQuestLog
{
constexpr uint16 UpdateObjectAddonOpcode = 0x0578;
constexpr uint32 RewardXPField = 36;
constexpr uint32 LevelField = 61;
constexpr uint32 ScaledQuestFlag = 0x01000000;

[[nodiscard]] uint32 RewardXPForDisplay(Player* player, Quest const* quest);
[[nodiscard]] WorldPacket BuildRewardXP(ObjectGuid guid, uint16 slot, uint32 rewardXP);
[[nodiscard]] WorldPacket BuildLevel(ObjectGuid guid, uint16 slot, uint32 level);
void SendSlot(Player* player, uint16 slot);
void SendAll(Player* player);
}

#endif
