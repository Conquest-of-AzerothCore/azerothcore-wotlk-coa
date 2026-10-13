/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionAverageItemLevel.h"
#include "GlobalScript.h"
#include "Group.h"
#include "LFGMgr.h"
#include "Player.h"
#include "PlayerScript.h"
#include "WorldSession.h"
#include <array>
#include <utility>

namespace
{
constexpr std::array<std::pair<uint32, uint32>, 4> RandomDungeonItemLevels = {{
    { 1258, 40 },
    { 2258, 58 },
    { 418, 70 },
    { 419, 108 },
}};

[[nodiscard]] uint32 RequiredItemLevel(uint32 dungeonId)
{
    for (auto const& [dungeon, itemLevel] : RandomDungeonItemLevels)
        if (dungeon == dungeonId)
            return itemLevel;
    return 0;
}

[[nodiscard]] bool BelowRequiredItemLevel(Player const* player, uint32 dungeonId)
{
    uint32 const required = RequiredItemLevel(dungeonId);
    return required && AscensionAverageItemLevel::Equipped(player) < float(required);
}

[[nodiscard]] bool ContinuesAssignedDungeon(Group const* group)
{
    return group && group->isLFGGroup() && sLFGMgr->GetState(group->GetGUID()) != lfg::LFG_STATE_FINISHED_DUNGEON;
}

class lfg_random_dungeon_item_level_lock : public GlobalScript
{
public:
    lfg_random_dungeon_item_level_lock()
        : GlobalScript("lfg_random_dungeon_item_level_lock", {GLOBALHOOK_ON_INITIALIZE_LOCKED_DUNGEONS}) { }

    void OnInitializeLockedDungeons(Player* player, uint8&, uint32& lockData, lfg::LFGDungeonData const* dungeon) override
    {
        if (!lockData && dungeon && BelowRequiredItemLevel(player, dungeon->id))
            lockData = lfg::LFG_LOCKSTATUS_TOO_LOW_GEAR_SCORE;
    }
};

class lfg_random_dungeon_item_level_join : public PlayerScript
{
public:
    lfg_random_dungeon_item_level_join()
        : PlayerScript("lfg_random_dungeon_item_level_join", {PLAYERHOOK_CAN_JOIN_LFG}) { }

    bool OnPlayerCanJoinLfg(Player* player, uint8, lfg::LfgDungeonSet& dungeons, std::string const&) override
    {
        Group const* group = player->GetGroup();
        if (dungeons.size() != 1 || ContinuesAssignedDungeon(group))
            return true;

        lfg::LFGDungeonData const* dungeon = sLFGMgr->GetLFGDungeon(*dungeons.begin());
        if (!dungeon || !RequiredItemLevel(dungeon->id))
            return true;

        lfg::LfgJoinResultData result(group ? lfg::LFG_JOIN_PARTY_NOT_MEET_REQS : lfg::LFG_JOIN_NOT_MEET_REQS);
        auto lockIfBelow = [&](Player const* member)
        {
            if (BelowRequiredItemLevel(member, dungeon->id))
                result.lockmap[member->GetGUID()][dungeon->Entry()] = lfg::LFG_LOCKSTATUS_TOO_LOW_GEAR_SCORE;
        };

        if (group)
        {
            for (GroupReference const* member = group->GetFirstMember(); member; member = member->next())
                if (Player const* source = member->GetSource())
                    lockIfBelow(source);
        }
        else
            lockIfBelow(player);

        if (result.lockmap.empty())
            return true;

        player->GetSession()->SendLfgJoinResult(result);
        return false;
    }
};
}

void AddSC_AscensionLfgItemLevel()
{
    new lfg_random_dungeon_item_level_lock();
    new lfg_random_dungeon_item_level_join();
}
