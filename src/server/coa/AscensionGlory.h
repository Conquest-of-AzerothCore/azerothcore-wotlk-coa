/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef COA_ASCENSION_GLORY_H
#define COA_ASCENSION_GLORY_H

#include "ObjectGuid.h"
#include "SharedDefines.h"
#include "WorldPacket.h"
#include <array>
#include <string>

class Player;

namespace AscensionGlory
{
constexpr char Setting[] = "core.coa_glory";
constexpr uint16 UpdateObjectAddonOpcode = 0x0578;
constexpr uint32 AddonField = 35;
constexpr uint32 HonorableKillGlory = 5;
constexpr uint32 KillingBlowBonusGlory = 5;
constexpr uint32 BattlegroundWinGlory = 50;
constexpr uint32 WarsongFlagCaptureGlory = 33;
constexpr uint32 NodeCaptureGlory = 50;
constexpr uint32 ObjectiveGlory = 5;
inline constexpr std::array<uint32, 15> RankThresholds =
    {0, 250, 500, 1000, 2000, 4000, 8000, 15000, 25000, 40000, 60000, 90000, 125000, 175000, 250000};

[[nodiscard]] uint32 Accrue(uint32 glory, uint32 earned);
[[nodiscard]] uint32 ObjectiveReward(BattlegroundTypeId bgType, uint32 scoreType, uint32 count);
[[nodiscard]] uint32 GloryToNextRank(uint32 glory);
[[nodiscard]] std::string GainMessage(uint32 earned, uint32 total);
[[nodiscard]] WorldPacket BuildUpdate(ObjectGuid guid, uint32 glory);
[[nodiscard]] uint32 Get(Player const* player);
void Earn(Player* player, uint32 glory);
void Send(Player* player);
}

#endif
