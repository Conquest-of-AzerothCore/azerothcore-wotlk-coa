#include "Chat.h"
#include "Group.h"
#include "Map.h"
#include "Player.h"
#include "PlayerScript.h"
#include "ScriptMgr.h"

namespace
{
constexpr uint32 MAP_REGRETS_CHASM     = 933;
constexpr uint32 MAP_GUARDIANS_LIBRARY = 4417;
constexpr uint32 MAP_DALARAN_CRATER    = 4418;

bool IsWisdomballMap(uint32 mapId)
{
    return mapId == MAP_REGRETS_CHASM || mapId == MAP_GUARDIANS_LIBRARY || mapId == MAP_DALARAN_CRATER;
}

bool MemberInOtherDungeon(Group* group)
{
    for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
        if (Player* member = ref->GetSource())
            if (member->IsInWorld() && member->GetMap()->IsDungeon() && !IsWisdomballMap(member->GetMapId()))
                return true;

    return false;
}
}

class wisdomball_normal_difficulty : public PlayerScript
{
public:
    wisdomball_normal_difficulty() : PlayerScript("wisdomball_normal_difficulty", { PLAYERHOOK_ON_BEFORE_TELEPORT }) { }

    bool OnPlayerBeforeTeleport(Player* player, uint32 mapId, float /*x*/, float /*y*/, float /*z*/, float /*orientation*/, uint32 /*options*/, Unit* /*target*/) override
    {
        if (!IsWisdomballMap(mapId) || player->GetMapId() == mapId)
            return true;

        Group* group = player->GetGroup();
        if (group && group->GetDungeonDifficulty() != DUNGEON_DIFFICULTY_NORMAL && !MemberInOtherDungeon(group))
            group->SetDungeonDifficulty(DUNGEON_DIFFICULTY_NORMAL);

        if (player->GetDungeonDifficulty() != DUNGEON_DIFFICULTY_NORMAL)
        {
            player->SetDungeonDifficulty(DUNGEON_DIFFICULTY_NORMAL);
            player->SendDungeonDifficulty(group != nullptr);
        }

        return true;
    }
};

void AddSC_wisdomball_normal_difficulty()
{
    new wisdomball_normal_difficulty();
}
