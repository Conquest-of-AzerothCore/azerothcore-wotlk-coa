/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "LFGMgr.h"
#include "Player.h"
#include "PlayerScript.h"
#include <algorithm>

namespace
{
constexpr uint8 ClientClassicDungeonListMaxLevel = 59;

[[nodiscard]] bool IsClientClassicDungeonList(Player const* player, lfg::LfgDungeonSet const& dungeons)
{
    return player->GetLevel() <= ClientClassicDungeonListMaxLevel && dungeons.size() > 1 &&
           std::ranges::all_of(dungeons, [](uint32 dungeonId)
           {
               return sLFGMgr->GetClassicRandomFallback(dungeonId) != nullptr;
           });
}

class lfg_classic_dungeon_list_join : public PlayerScript
{
public:
    lfg_classic_dungeon_list_join() : PlayerScript("lfg_classic_dungeon_list_join", {PLAYERHOOK_CAN_JOIN_LFG}) { }

    bool OnPlayerCanJoinLfg(Player* player, uint8, lfg::LfgDungeonSet& dungeons, std::string const&) override
    {
        if (IsClientClassicDungeonList(player, dungeons) && sLFGMgr->GetLFGDungeon(lfg::LFG_DUNGEON_RANDOM_CLASSIC))
            dungeons = { lfg::LFG_DUNGEON_RANDOM_CLASSIC };

        return true;
    }
};
}

void AddSC_AscensionLfgClassicDungeonList()
{
    new lfg_classic_dungeon_list_join();
}
