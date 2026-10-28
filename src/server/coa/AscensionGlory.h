/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef COA_ASCENSION_GLORY_H
#define COA_ASCENSION_GLORY_H

#include "ObjectGuid.h"
#include "WorldPacket.h"

class Player;

namespace AscensionGlory
{
constexpr char Setting[] = "core.coa_glory";
constexpr uint16 UpdateObjectAddonOpcode = 0x0578;
constexpr uint32 AddonField = 35;
constexpr uint32 KillingBlowGlory = 1;
constexpr uint32 ObjectiveGlory = 5;

[[nodiscard]] uint32 Accrue(uint32 glory, uint32 earned);
[[nodiscard]] uint32 ObjectiveReward(uint32 scoreType, uint32 count);
[[nodiscard]] WorldPacket BuildUpdate(ObjectGuid guid, uint32 glory);
[[nodiscard]] uint32 Get(Player const* player);
void Earn(Player* player, uint32 glory);
void Send(Player* player);
}

#endif
