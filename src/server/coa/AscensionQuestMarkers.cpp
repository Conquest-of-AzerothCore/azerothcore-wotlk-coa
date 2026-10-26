#include "AscensionQuestMarkers.h"
#include "Creature.h"
#include "ObjectMgr.h"
#include "DatabaseEnv.h"
#include "GossipDef.h"
#include "Map.h"
#include "Player.h"
#include "QuestDef.h"
#include "WorldPacket.h"
#include "WorldScript.h"

#include <shared_mutex>
#include <mutex>
#include <unordered_map>
#include <vector>

namespace
{
std::shared_mutex markerLock;

struct MarkerOverride
{
    uint32 QuestId;
    uint32 Style;
};

using MarkerStyles = std::unordered_map<uint32, std::vector<MarkerOverride>>;
MarkerStyles markerStyles;

void LoadMarkerStyles()
{
    MarkerStyles styles;
    WorldDatabasePreparedStatement* statement = WorldDatabase.GetPreparedStatement(WORLD_SEL_ASCENSION_QUEST_MARKER_STYLES);
    if (PreparedQueryResult result = WorldDatabase.Query(statement))
    {
        do
        {
            Field* fields = result->Fetch();
            uint32 const entry = fields[0].Get<uint32>();
            uint32 const questId = fields[1].Get<uint32>();
            uint32 const style = fields[2].Get<uint8>();
            if (style >= 1 && style <= 6)
                styles[entry].push_back({questId, style});
        } while (result->NextRow());
    }
    std::unique_lock guard(markerLock);
    markerStyles.swap(styles);
}

enum class AscensionQuestCategory : int32
{
    Main = -379,
    PvE = -380,
    PvP = -381,
    Profession = -382,
    HighRisk = -383
};

uint32 QuestMetadataStyle(Quest const* quest)
{
    if (!quest)
        return 1;
    if (quest->GetType() == QUEST_TYPE_LEGENDARY || quest->GetZoneOrSort() == -QUEST_SORT_LEGENDARY)
        return 4;
    switch (static_cast<AscensionQuestCategory>(quest->GetZoneOrSort()))
    {
        case AscensionQuestCategory::Main:
        case AscensionQuestCategory::PvE:
        case AscensionQuestCategory::PvP:
        case AscensionQuestCategory::Profession:
        case AscensionQuestCategory::HighRisk:
            return 6;
        default:
            return 1;
    }
}

bool HasMarkerStyles(Creature* creature)
{
    {
        std::shared_lock guard(markerLock);
        if (markerStyles.contains(creature->GetEntry()))
            return true;
    }
    if (!creature->HasNpcFlag(UNIT_NPC_FLAG_QUESTGIVER))
        return false;
    for (auto const bounds : {sObjectMgr->GetCreatureQuestRelationBounds(creature->GetEntry()),
        sObjectMgr->GetCreatureQuestInvolvedRelationBounds(creature->GetEntry())})
        for (auto it = bounds.first; it != bounds.second; ++it)
            if (QuestMetadataStyle(sObjectMgr->GetQuestTemplate(it->second)) != 1)
                return true;
    return false;
}

uint32 OverrideStyle(Player* player, Creature* creature, uint32 status)
{
    std::shared_lock guard(markerLock);
    auto const found = markerStyles.find(creature->GetEntry());
    if (found == markerStyles.end())
        return 0;
    uint32 fallback = 0;
    for (MarkerOverride const& marker : found->second)
    {
        if (!marker.QuestId)
            fallback = marker.Style;
        else if (status > DIALOG_STATUS_UNAVAILABLE &&
            uint32(player->GetQuestDialogStatus(creature, marker.QuestId)) == status)
            return marker.Style;
    }
    return fallback;
}

uint32 MarkerStyle(Player* player, Creature* creature, uint32 status)
{
    if (uint32 const overrideStyle = OverrideStyle(player, creature, status))
        return overrideStyle;
    if (status <= DIALOG_STATUS_UNAVAILABLE ||
        !creature->HasNpcFlag(UNIT_NPC_FLAG_QUESTGIVER) || creature->IsHostileTo(player))
        return 0;
    uint32 chosen = 0;
    for (auto const bounds : {sObjectMgr->GetCreatureQuestRelationBounds(creature->GetEntry()),
        sObjectMgr->GetCreatureQuestInvolvedRelationBounds(creature->GetEntry())})
    {
        for (auto it = bounds.first; it != bounds.second; ++it)
        {
            if (uint32(player->GetQuestDialogStatus(creature, it->second)) != status)
                continue;
            uint32 const style = QuestMetadataStyle(sObjectMgr->GetQuestTemplate(it->second));
            if (chosen && chosen != style)
                return 0;
            chosen = style;
        }
    }
    return chosen == 1 ? 0 : chosen;
}

bool SupportsMarkerStatus(uint32 style, uint32 status)
{
    if (!status || status > 10)
        return false;
    switch (style)
    {
        case 1:
        case 2:
            return true;
        case 3:
        case 4:
            return status == 1 || status == 2 || status == 5 || status == 8 || status == 10;
        case 5:
            return status == 8;
        case 6:
            return status != 9;
        default:
            return false;
    }
}

class AscensionQuestMarkerWorld final : public WorldScript
{
public:
    AscensionQuestMarkerWorld() : WorldScript("AscensionQuestMarkerWorld",
        { WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_AFTER_CONFIG_LOAD }) { }

    void OnStartup() override { LoadMarkerStyles(); }

    void OnAfterConfigLoad(bool reload) override
    {
        if (reload)
            LoadMarkerStyles();
    }
};
}

void AscensionQuestMarkers::Send(Player* player, ObjectGuid guid, uint32 status)
{
    if (!player || !player->IsInWorld())
        return;
    Map* map = player->FindMap();
    Creature* creature = map ? map->GetCreature(guid) : nullptr;
    if (!creature)
        return;
    uint32 const style = MarkerStyle(player, creature, status);
    if (!SupportsMarkerStatus(style, status))
        return;
    WorldPacket packet(0x065C, sizeof(uint64) + 2 * sizeof(uint32));
    packet << guid << style << status;
    player->SendDirectMessage(&packet);
}

void AscensionQuestMarkers::Refresh(Player* player, Creature* creature)
{
    if (!player || !creature || !HasMarkerStyles(creature))
        return;
    uint32 const status = creature->HasNpcFlag(UNIT_NPC_FLAG_QUESTGIVER) && !creature->IsHostileTo(player)
        ? uint32(player->GetQuestDialogStatus(creature)) : uint32(DIALOG_STATUS_NONE);
    if (MarkerStyle(player, creature, status))
        player->PlayerTalkClass->SendQuestGiverStatus(uint8(status), creature->GetGUID());
}

void AscensionQuestMarkers::RefreshVisible(Player* player)
{
    if (!player || !player->IsInWorld())
        return;
    player->DoForAllVisibleWorldObjects([player](WorldObject* object)
    {
        if (Creature* creature = object->ToCreature())
            Refresh(player, creature);
    });
}

void AddSC_AscensionQuestMarkers()
{
    new AscensionQuestMarkerWorld();
}
