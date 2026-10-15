/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef COA_ASCENSION_DIFFICULTY_RELEASE_H
#define COA_ASCENSION_DIFFICULTY_RELEASE_H

#include "WorldPacket.h"
#include <array>

class Player;

namespace AscensionDifficultyRelease
{
constexpr uint16 GameEventInfoOpcode = 0x09BD;
constexpr std::size_t GameEventInfoSize = 52;

constexpr std::array<uint16, 6> HeroicDungeonEvents = { 394, 395, 396, 436, 437, 447 };
constexpr std::array<uint16, 6> MythicDungeonEvents = { 728, 729, 730, 731, 732, 734 };

[[nodiscard]] WorldPacket BuildActiveEvent(uint16 eventId);
void SendReleasedDifficulties(Player* player);
}

#endif
