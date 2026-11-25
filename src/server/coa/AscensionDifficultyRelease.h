/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef COA_ASCENSION_DIFFICULTY_RELEASE_H
#define COA_ASCENSION_DIFFICULTY_RELEASE_H

#include "WorldPacket.h"
#include <array>
#include <vector>

class Player;

namespace AscensionDifficultyRelease
{
constexpr uint16 GameEventInfoOpcode = 0x09BD;
constexpr std::size_t GameEventInfoSize = 52;

constexpr std::array<uint16, 12> HeroicDungeonEvents = { 394, 395, 396, 436, 437, 447, 339, 400, 401, 402, 403, 404 };
constexpr std::array<uint16, 12> MythicDungeonEvents = { 728, 729, 730, 731, 732, 734, 365, 221, 222, 223, 224, 225 };

[[nodiscard]] WorldPacket BuildActiveEvent(uint16 eventId);
[[nodiscard]] std::vector<uint16> ReleasedEvents(uint32 releasedStage);
void SendReleasedDifficulties(Player* player);
}

#endif
