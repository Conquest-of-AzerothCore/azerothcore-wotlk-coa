/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef MOD_ASCENSION_WISDOMBALL_H
#define MOD_ASCENSION_WISDOMBALL_H

#include "Define.h"
#include <vector>

class Creature;
class Player;
class Quest;
class WorldPacket;

namespace AscensionWisdomball
{
    constexpr uint32 CreatureEntry = 79025;
    constexpr uint32 SummonSpell = 83050;
    constexpr uint32 GreetingTextId = 790250;

    [[nodiscard]] bool IsWisdomball(Creature const* creature);

    [[nodiscard]] Creature* ActiveBall(Player* player);

    [[nodiscard]] Creature* UsableBall(Player* player);

    [[nodiscard]] std::vector<uint32> OfferedQuests(Player* player);
    [[nodiscard]] std::vector<uint32> CarriedQuests(Player* player);
    [[nodiscard]] std::vector<uint32> TurnInQuests(Player* player);

    [[nodiscard]] uint8 DialogStatus(Player* player, Creature* ball);

    bool Accept(Player* player, Creature* ball, Quest const* quest);

    bool HandlePacket(Player* player, WorldPacket const& packet);

    void Forget(Player* player);
}

#endif
