/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionAverageItemLevel.h"
#include "AscensionItemPower.h"
#include "Group.h"
#include "LFGMgr.h"
#include "Player.h"
#include "PlayerScript.h"
#include "WorldSession.h"
#include <algorithm>
#include <array>

namespace
{
struct RandomDungeonRequirement
{
    uint32 dungeonId;
    uint32 itemLevel;
    uint32 pvePower;
};

constexpr std::array<RandomDungeonRequirement, 4> RandomDungeonRequirements = {{
    { 1258, 40, 0 },
    { 2258, 58, 350 },
    { 418, 70, 0 },
    { 419, 108, 350 },
}};

[[nodiscard]] RandomDungeonRequirement const* FindRequirement(uint32 dungeonId)
{
    auto const found =
        std::ranges::find(RandomDungeonRequirements, dungeonId, &RandomDungeonRequirement::dungeonId);
    return found != RandomDungeonRequirements.end() ? &*found : nullptr;
}

[[nodiscard]] bool MissesRequirement(Player const* player, RandomDungeonRequirement const& requirement)
{
    return AscensionAverageItemLevel::Equipped(player) < float(requirement.itemLevel) ||
           AscensionItemPower::EquippedPvE(player) < requirement.pvePower;
}

[[nodiscard]] bool ContinuesAssignedDungeon(Group const* group)
{
    return group && group->isLFGGroup() && sLFGMgr->GetState(group->GetGUID()) != lfg::LFG_STATE_FINISHED_DUNGEON;
}

class lfg_random_dungeon_requirements_join : public PlayerScript
{
public:
    lfg_random_dungeon_requirements_join()
        : PlayerScript("lfg_random_dungeon_requirements_join", {PLAYERHOOK_CAN_JOIN_LFG}) { }

    bool OnPlayerCanJoinLfg(Player* player, uint8, lfg::LfgDungeonSet& dungeons, std::string const&) override
    {
        Group const* group = player->GetGroup();
        if (dungeons.size() != 1 || ContinuesAssignedDungeon(group))
            return true;

        lfg::LFGDungeonData const* dungeon = sLFGMgr->GetLFGDungeon(*dungeons.begin());
        RandomDungeonRequirement const* requirement = dungeon ? FindRequirement(dungeon->id) : nullptr;
        if (!requirement)
            return true;

        lfg::LfgJoinResultData result(group ? lfg::LFG_JOIN_PARTY_NOT_MEET_REQS : lfg::LFG_JOIN_NOT_MEET_REQS);
        auto lockIfMissing = [&](Player const* member)
        {
            if (MissesRequirement(member, *requirement))
                result.lockmap[member->GetGUID()][dungeon->Entry()] = lfg::LFG_LOCKSTATUS_TOO_LOW_GEAR_SCORE;
        };

        if (group)
        {
            for (GroupReference const* member = group->GetFirstMember(); member; member = member->next())
                if (Player const* source = member->GetSource())
                    lockIfMissing(source);
        }
        else
            lockIfMissing(player);

        if (result.lockmap.empty())
            return true;

        player->GetSession()->SendLfgJoinResult(result);
        return false;
    }
};
}

void AddSC_AscensionLfgRandomDungeonRequirements()
{
    new lfg_random_dungeon_requirements_join();
}
