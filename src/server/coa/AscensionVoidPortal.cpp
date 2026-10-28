/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionVoidPortal.h"
#include "Chat.h"
#include "CreatureData.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "GameObject.h"
#include "GameTime.h"
#include "Item.h"
#include "Log.h"
#include "Map.h"
#include "MapMgr.h"
#include "MapRefMgr.h"
#include "MapReference.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"
#include "SpawnData.h"
#include "StringFormat.h"
#include "WorldSessionMgr.h"

namespace
{
using namespace Ascension::VoidPortal;

constexpr std::uint32_t PortalEntry = 239828;
constexpr std::uint32_t ItemEntry = 121815;
constexpr std::uint32_t MarkerEntry = 23746;
constexpr float ProximityRadius = 20.0f;
constexpr char const* PortalTagColor = "ff8000";
constexpr char const* ItemLinkColor = "a335ee";
constexpr char const* AnnouncementColor = "ffff00";

std::string ItemIcon(ItemTemplate const* proto)
{
    ItemDisplayInfoEntry const* display = sItemDisplayInfoStore.LookupEntry(proto->DisplayInfoID);
    if (!display || !display->inventoryIcon || !*display->inventoryIcon)
        return "";
    return Acore::StringFormat("|TInterface\\Icons\\{}:20:20|t ", display->inventoryIcon);
}

std::string CaptureAnnouncement(ItemTemplate const* proto, std::string const& playerName)
{
    std::string icon = ItemIcon(proto);
    std::string link = Acore::StringFormat("|cff{}|Hitem:{}:0:0:0:0:0:0:0:0:0|h[{}]|h|r",
        ItemLinkColor, proto->ItemId, proto->Name1);
    return Acore::StringFormat("{}|cff{}[Void Portal]|r {}{}|cff{} has been captured by {}!|r",
        icon, PortalTagColor, icon, link, AnnouncementColor, playerName);
}

class VoidPortalManager
{
public:
    static VoidPortalManager& Instance()
    {
        static VoidPortalManager manager;
        return manager;
    }

    void Load()
    {
        std::vector<SpawnGroup> groups;
        QueryResult result = WorldDatabase.Query("SELECT groupId FROM ascension_void_portal_group ORDER BY groupId");
        if (result)
        {
            do
            {
                std::uint32_t groupId = result->Fetch()[0].Get<std::uint32_t>();
                if (std::optional<SpawnGroup> group = BuildGroup(groupId))
                    groups.push_back(std::move(*group));
            } while (result->NextRow());
        }

        if (groups.empty())
            LOG_ERROR("coa", "ASC-VOIDPORTAL no valid spawn groups; the portal stays idle");
        else
            LOG_INFO("coa", "ASC-VOIDPORTAL loaded {} spawn groups", groups.size());

        _selection = Selection(std::move(groups));
    }

    void Update(std::uint32_t diff)
    {
        (void)diff;
        if (_selection.Empty())
            return;

        std::int64_t now = Now();
        if (_pendingTransition)
        {
            _pendingTransition = false;
            ActivateRandomGroup(now);
            return;
        }
        if (_activeGroup == 0)
        {
            ActivateRandomGroup(now);
            return;
        }
        if (now >= _schedule.GroupExpiry())
        {
            ActivateRandomGroup(now);
            return;
        }
        if (now >= _schedule.PointExpiry())
        {
            AdvancePoint(now);
            return;
        }
        if (!_rollDone && AnyPlayerWithin(_activePoint.mapId, _activePoint.x, _activePoint.y,
            _activePoint.z, ProximityRadius))
        {
            bool success = _forcedRoll ? *_forcedRoll : Selection::ProximityRollSucceeds(urand(1, 100));
            _forcedRoll.reset();
            _rollDone = true;
            if (success)
            {
                DespawnPortal();
                ActivateRandomGroup(now);
            }
        }
    }

    bool IsPortal(ObjectGuid guid) const
    {
        return !_portalGuid.IsEmpty() && _portalGuid == guid;
    }

    void CapturePortal()
    {
        DespawnPortal();
        _pendingTransition = true;
    }

    void ForceSpawn(std::uint32_t groupId, std::uint32_t spawnId)
    {
        for (SpawnGroup const& group : _selection.Groups())
        {
            if (group.groupId != groupId)
                continue;
            for (Point const& point : group.points)
            {
                if (point.spawnId != spawnId)
                    continue;
                ActivateGroup(group, point, Now());
                _pendingTransition = false;
                return;
            }
        }
        LOG_ERROR("coa", "ASC-VOIDPORTAL force spawn ignored for group {} point {}", groupId, spawnId);
    }

    void ForceRoll(bool success) { _forcedRoll = success; }
    std::uint32_t ActiveGroup() const { return _activeGroup; }

private:
    std::optional<SpawnGroup> BuildGroup(std::uint32_t groupId)
    {
        SpawnGroupTemplateData const* groupData = sObjectMgr->GetSpawnGroupData(groupId);
        if (!groupData)
        {
            LOG_ERROR("coa", "ASC-VOIDPORTAL group {} is not a spawn group", groupId);
            return std::nullopt;
        }
        if (!(groupData->flags & SPAWNGROUP_FLAG_MANUAL_SPAWN))
        {
            LOG_ERROR("coa", "ASC-VOIDPORTAL group {} is not manual-spawn", groupId);
            return std::nullopt;
        }

        SpawnGroup group{ groupId, {} };
        auto range = sObjectMgr->GetSpawnDataForGroup(groupId);
        for (auto it = range.first; it != range.second; ++it)
        {
            SpawnData const* spawn = it->second;
            if (spawn->type != SPAWN_TYPE_CREATURE)
            {
                LOG_ERROR("coa", "ASC-VOIDPORTAL group {} has a non-creature member", groupId);
                return std::nullopt;
            }

            CreatureData const* creature = sObjectMgr->GetCreatureData(spawn->spawnId);
            if (!creature || creature->id != MarkerEntry)
            {
                LOG_ERROR("coa", "ASC-VOIDPORTAL group {} member {} is not marker {}",
                    groupId, spawn->spawnId, MarkerEntry);
                return std::nullopt;
            }

            Point point{ spawn->spawnId, spawn->mapid, spawn->posX, spawn->posY, spawn->posZ,
                spawn->orientation };
            if (!group.points.empty() && group.points.front().mapId != point.mapId)
            {
                LOG_ERROR("coa", "ASC-VOIDPORTAL group {} spans several maps", groupId);
                return std::nullopt;
            }
            for (Point const& existing : group.points)
                if (existing.x == point.x && existing.y == point.y && existing.z == point.z)
                {
                    LOG_ERROR("coa", "ASC-VOIDPORTAL group {} repeats a point", groupId);
                    return std::nullopt;
                }
            group.points.push_back(point);
        }

        if (group.points.size() < 2 || group.points.size() > 6)
        {
            LOG_ERROR("coa", "ASC-VOIDPORTAL group {} has {} points", groupId, group.points.size());
            return std::nullopt;
        }
        return group;
    }

    void ActivateRandomGroup(std::int64_t now)
    {
        std::optional<std::uint32_t> groupId = _selection.ChooseGroup(_activeGroup, _rng);
        if (!groupId)
            return;
        SpawnGroup const* group = FindGroup(*groupId);
        if (!group)
            return;
        std::optional<Point> point = _selection.ChoosePoint(*group, 0, _rng);
        if (!point)
            return;
        ActivateGroup(*group, *point, now);
    }

    void ActivateGroup(SpawnGroup const& group, Point const& point, std::int64_t now)
    {
        DespawnPortal();
        DeactivateGroup();
        Map* map = EnsureMap(point.mapId);
        if (!map)
        {
            LOG_ERROR("coa", "ASC-VOIDPORTAL cannot create map {}", point.mapId);
            return;
        }

        map->SpawnGroupSpawn(group.groupId, true, true);
        _activeGroup = group.groupId;
        _activePoint = point;
        _schedule.StartGroup(now);
        SpawnPortal(map);
    }

    void AdvancePoint(std::int64_t now)
    {
        SpawnGroup const* group = FindGroup(_activeGroup);
        if (!group)
            return;
        std::optional<Point> point = _selection.ChoosePoint(*group, _activePoint.spawnId, _rng);
        if (!point)
            return;
        Map* map = EnsureMap(point->mapId);
        if (!map)
            return;

        DespawnPortal();
        _activePoint = *point;
        _schedule.StartPoint(now);
        SpawnPortal(map);
    }

    void SpawnPortal(Map* map)
    {
        GameObject* portal = map->SummonGameObject(PortalEntry, _activePoint.x, _activePoint.y,
            _activePoint.z, _activePoint.orientation, 0.0f, 0.0f, 0.0f, 1.0f, 0);
        if (!portal)
        {
            LOG_ERROR("coa", "ASC-VOIDPORTAL cannot summon {} at {},{},{}", PortalEntry,
                _activePoint.x, _activePoint.y, _activePoint.z);
            return;
        }

        _portalGuid = portal->GetGUID();
        _schedule.StartPoint(Now());
        _rollDone = false;
    }

    void DespawnPortal()
    {
        if (_portalGuid.IsEmpty())
            return;
        if (Map* map = sMapMgr->FindMap(_activePoint.mapId, 0))
            if (GameObject* portal = map->GetGameObject(_portalGuid))
                portal->AddObjectToRemoveList();
        _portalGuid.Clear();
    }

    void DeactivateGroup()
    {
        if (!_activeGroup)
            return;
        if (Map* map = sMapMgr->FindMap(_activePoint.mapId, 0))
            map->SpawnGroupDespawn(_activeGroup, true);
    }

    Map* EnsureMap(std::uint16_t mapId)
    {
        if (Map* map = sMapMgr->FindMap(mapId, 0))
            return map;
        return sMapMgr->CreateBaseMap(mapId);
    }

    bool AnyPlayerWithin(std::uint16_t mapId, float x, float y, float z, float radius) const
    {
        Map* map = sMapMgr->FindMap(mapId, 0);
        if (!map)
            return false;
        for (MapReference const& reference : map->GetPlayers())
        {
            Player* player = reference.GetSource();
            if (!player || !player->IsInWorld())
                continue;
            if (!(player->GetPhaseMask() & PHASEMASK_NORMAL))
                continue;
            if (player->IsWithinDist3d(x, y, z, radius))
                return true;
        }
        return false;
    }

    SpawnGroup const* FindGroup(std::uint32_t groupId) const
    {
        for (SpawnGroup const& group : _selection.Groups())
            if (group.groupId == groupId)
                return &group;
        return nullptr;
    }

    static std::int64_t Now() { return GameTime::GetGameTimeMS().count(); }

    Selection _selection{{}};
    Schedule _schedule;
    std::mt19937 _rng{std::random_device{}()};
    std::uint32_t _activeGroup{0};
    Point _activePoint{};
    ObjectGuid _portalGuid;
    std::optional<bool> _forcedRoll;
    bool _rollDone{false};
    bool _pendingTransition{false};
};

class go_void_portal : public GameObjectScript
{
public:
    go_void_portal() : GameObjectScript("go_void_portal") { }

    bool OnGossipHello(Player* player, GameObject* portal) override
    {
        VoidPortalManager& manager = VoidPortalManager::Instance();
        if (!manager.IsPortal(portal->GetGUID()))
            return false;

        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(ItemEntry);
        if (!proto)
        {
            LOG_ERROR("coa", "ASC-VOIDPORTAL item {} is missing", ItemEntry);
            return false;
        }

        if (!player->AddItem(ItemEntry, 1))
            player->SendItemRetrievalMail(ItemEntry, 1);

        WorldPacket data;
        ChatHandler::BuildChatPacket(data, CHAT_MSG_SYSTEM, LANG_UNIVERSAL, nullptr, nullptr,
            CaptureAnnouncement(proto, player->GetName()));
        sWorldSessionMgr->SendGlobalMessage(&data);

        manager.CapturePortal();
        return true;
    }
};

class AscensionVoidPortalWorld : public WorldScript
{
public:
    AscensionVoidPortalWorld() : WorldScript("AscensionVoidPortalWorld",
        { WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_UPDATE }) { }

    void OnStartup() override { VoidPortalManager::Instance().Load(); }
    void OnUpdate(std::uint32_t diff) override { VoidPortalManager::Instance().Update(diff); }
};
}

void AddSC_AscensionVoidPortal()
{
    new go_void_portal();
    new AscensionVoidPortalWorld();
}

namespace Ascension::VoidPortal
{
void ForceSpawnForTest(std::uint32_t groupId, std::uint32_t spawnId)
{
    VoidPortalManager::Instance().ForceSpawn(groupId, spawnId);
}

void ForceProximityRollForTest(bool success)
{
    VoidPortalManager::Instance().ForceRoll(success);
}

std::uint32_t ActiveGroupForTest()
{
    return VoidPortalManager::Instance().ActiveGroup();
}
}
