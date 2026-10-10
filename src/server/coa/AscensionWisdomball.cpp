/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWisdomball.h"

#include "Chat.h"
#include "Creature.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "GossipDef.h"
#include "Log.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "ObjectGuid.h"
#include "ObjectMgr.h"
#include "PassiveAI.h"
#include "Player.h"
#include "QuestDef.h"
#include "ScriptedGossip.h"
#include "ScriptMgr.h"
#include "Timer.h"
#include <algorithm>
#include <list>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

namespace
{
constexpr uint32 SenderMore = 79027;

constexpr uint32 GreetingTextId = 790250;

constexpr uint8 QuestIconAvailable = 2;
constexpr uint8 QuestIconActive = 4;

constexpr uint32 PageSize = 30;

constexpr float InteractionRange = 30.0f;

constexpr uint32 StatusCheckIntervalMs = 2000;

constexpr uint32 QuestsCompletedWithoutPlayerAction[] = { 5722, 5724, 7498, 7499, 7500, 7501, 7502, 7503, 7504, 7505, 7506, 7507, 7508, 8948 };

constexpr uint32 RazorfenKraulMapId = 47;
constexpr uint32 RazorfenKraulOverworldQuestSortAreaId = 1717;

constexpr uint32 GnomereganMapId = 90;
constexpr uint32 GnomereganQuestSortAreaId = 133;

struct DungeonQuests
{
    std::vector<uint32> starters;
};

enum class MenuKind : uint8
{
    Available,
    Carried
};

struct MenuEntry
{
    uint32 quest;
    MenuKind kind;
};

struct StatusState
{
    uint32 nextCheckMs = 0;
    ObjectGuid ball;
    uint32 mapId = 0;
    uint8 status = 0;
    bool known = false;
};

std::mutex _questLock;
std::unordered_map<uint32, DungeonQuests> _questsByMap;

std::mutex _dungeonQuestLock;
bool _dungeonQuestsLoaded = false;
std::vector<uint32> _dungeonQuests;

std::mutex _statusLock;
std::unordered_map<uint32, StatusState> _statusByPlayer;

void ReadQuestIds(std::vector<uint32>& out, std::string const& query)
{
    QueryResult result = WorldDatabase.Query(query.c_str());
    if (!result)
        return;

    do
    {
        out.push_back(result->Fetch()[0].Get<uint32>());
    } while (result->NextRow());
}

void SortUnique(std::vector<uint32>& ids)
{
    std::sort(ids.begin(), ids.end());
    ids.erase(std::unique(ids.begin(), ids.end()), ids.end());
}

std::string IdList(std::vector<uint32> const& ids)
{
    std::string list = std::to_string(ids.front());
    for (size_t i = 1; i < ids.size(); ++i)
        list += "," + std::to_string(ids[i]);

    return list;
}

std::vector<uint32> ExtraQuestSortAreas(uint32 mapId)
{
    std::vector<uint32> areas;

    if (mapId == RazorfenKraulMapId)
        areas.push_back(RazorfenKraulOverworldQuestSortAreaId);

    if (mapId == GnomereganMapId)
        areas.push_back(GnomereganQuestSortAreaId);

    return areas;
}

std::vector<uint32> AreasOfMap(uint32 mapId)
{
    std::vector<uint32> areas;

    for (uint32 i = 0; i < sAreaTableStore.GetNumRows(); ++i)
        if (AreaTableEntry const* area = sAreaTableStore.LookupEntry(i))
            if (area->mapid == mapId)
                areas.push_back(area->ID);

    for (uint32 extra : ExtraQuestSortAreas(mapId))
        areas.push_back(extra);

    return areas;
}

DungeonQuests LoadDungeonQuests(uint32 mapId)
{
    DungeonQuests quests;
    std::string const map = std::to_string(mapId);

    ReadQuestIds(quests.starters,
        "SELECT DISTINCT qs.quest FROM creature c JOIN creature_queststarter qs ON qs.id = c.id WHERE c.map = " + map);
    ReadQuestIds(quests.starters,
        "SELECT DISTINCT qs.quest FROM gameobject g JOIN gameobject_queststarter qs ON qs.id = g.id WHERE g.map = " + map);

    std::vector<uint32> const areas = AreasOfMap(mapId);
    if (!areas.empty())
        ReadQuestIds(quests.starters, "SELECT ID FROM quest_template WHERE QuestSortID IN (" + IdList(areas) + ")");

    SortUnique(quests.starters);
    return quests;
}

DungeonQuests QuestsForMap(uint32 mapId)
{
    {
        std::lock_guard<std::mutex> lock(_questLock);
        auto const itr = _questsByMap.find(mapId);
        if (itr != _questsByMap.end())
            return itr->second;
    }

    DungeonQuests loaded = LoadDungeonQuests(mapId);

    std::lock_guard<std::mutex> lock(_questLock);
    auto const itr = _questsByMap.find(mapId);
    if (itr != _questsByMap.end())
        return itr->second;

    _questsByMap.emplace(mapId, loaded);
    return loaded;
}

bool Contains(std::vector<uint32> const& ids, uint32 questId)
{
    return std::binary_search(ids.begin(), ids.end(), questId);
}

bool CompletesWithoutPlayerAction(uint32 questId)
{
    for (uint32 excluded : QuestsCompletedWithoutPlayerAction)
        if (excluded == questId)
            return true;

    return false;
}

std::vector<uint32> DungeonMaps()
{
    std::vector<uint32> maps;

    for (uint32 i = 0; i < sMapStore.GetNumRows(); ++i)
        if (MapEntry const* map = sMapStore.LookupEntry(i))
            if (map->IsDungeon())
                maps.push_back(map->MapID);

    SortUnique(maps);
    return maps;
}

std::vector<uint32> LoadAllDungeonQuests()
{
    std::vector<uint32> ids;

    std::vector<uint32> const maps = DungeonMaps();
    if (maps.empty())
        return ids;

    std::string const mapList = IdList(maps);

    std::vector<uint32> areas;
    for (uint32 i = 0; i < sAreaTableStore.GetNumRows(); ++i)
        if (AreaTableEntry const* area = sAreaTableStore.LookupEntry(i))
            if (std::binary_search(maps.begin(), maps.end(), area->mapid))
                areas.push_back(area->ID);

    for (uint32 map : maps)
        for (uint32 extra : ExtraQuestSortAreas(map))
            areas.push_back(extra);

    if (!areas.empty())
        ReadQuestIds(ids, "SELECT ID FROM quest_template WHERE QuestSortID IN (" + IdList(areas) + ")");

    ReadQuestIds(ids,
        "SELECT DISTINCT qs.quest FROM creature c JOIN creature_queststarter qs ON qs.id = c.id WHERE c.map IN (" + mapList + ")");
    ReadQuestIds(ids,
        "SELECT DISTINCT qe.quest FROM creature c JOIN creature_questender qe ON qe.id = c.id WHERE c.map IN (" + mapList + ")");
    ReadQuestIds(ids,
        "SELECT DISTINCT qs.quest FROM gameobject g JOIN gameobject_queststarter qs ON qs.id = g.id WHERE g.map IN (" + mapList + ")");
    ReadQuestIds(ids,
        "SELECT DISTINCT qe.quest FROM gameobject g JOIN gameobject_questender qe ON qe.id = g.id WHERE g.map IN (" + mapList + ")");

    SortUnique(ids);
    return ids;
}

std::vector<uint32> const& AllDungeonQuests()
{
    std::lock_guard<std::mutex> lock(_dungeonQuestLock);
    if (!_dungeonQuestsLoaded)
    {
        _dungeonQuests = LoadAllDungeonQuests();
        _dungeonQuestsLoaded = true;
    }

    return _dungeonQuests;
}

bool InDungeon(Player* player)
{
    Map* map = player->GetMap();
    return map && (map->IsDungeon() || map->IsRaid());
}

bool IsPlaceholder(Quest const* quest)
{
    if (!quest)
        return true;

    std::string const& title = quest->GetTitle();
    return title.empty() || title.front() == '<';
}

std::vector<uint32> CarriedDungeonQuests(Player* player)
{
    std::vector<uint32> carried;
    std::vector<uint32> const& dungeons = AllDungeonQuests();

    for (auto const& status : player->getQuestStatusMap())
    {
        if (status.second.Status != QUEST_STATUS_INCOMPLETE && status.second.Status != QUEST_STATUS_COMPLETE)
            continue;

        if (!Contains(dungeons, status.first))
            continue;

        if (IsPlaceholder(sObjectMgr->GetQuestTemplate(status.first)))
            continue;

        carried.push_back(status.first);
    }

    std::sort(carried.begin(), carried.end());
    return carried;
}

bool CanOffer(Player* player, uint32 questId)
{
    Quest const* quest = sObjectMgr->GetQuestTemplate(questId);
    if (!quest || IsPlaceholder(quest))
        return false;

    if (CompletesWithoutPlayerAction(questId))
        return false;

    if (player->GetQuestStatus(questId) != QUEST_STATUS_NONE)
        return false;

    if (player->IsQuestRewarded(questId) && !quest->IsRepeatable())
        return false;

    if (!player->SatisfyQuestRace(quest, false))
        return false;

    if (!player->SatisfyQuestClass(quest, false))
        return false;

    if (!player->SatisfyQuestExclusiveGroup(quest, false))
        return false;

    return true;
}

void SendCarriedWindow(Player* player, Creature* ball, Quest const* quest, bool closeOnCancel)
{
    player->PlayerTalkClass->SendQuestGiverRequestItems(quest, ball->GetGUID(),
        player->CanRewardQuest(quest, false), closeOnCancel);
}

std::vector<MenuEntry> PlayerEntries(Player* player)
{
    std::vector<MenuEntry> entries;

    if (InDungeon(player))
        for (uint32 questId : QuestsForMap(player->GetMapId()).starters)
            if (CanOffer(player, questId))
                entries.push_back({ questId, MenuKind::Available });

    std::vector<MenuEntry> ready;
    std::vector<MenuEntry> ongoing;

    for (uint32 questId : CarriedDungeonQuests(player))
        (player->GetQuestStatus(questId) == QUEST_STATUS_COMPLETE ? ready : ongoing)
            .push_back({ questId, MenuKind::Carried });

    entries.insert(entries.end(), ready.begin(), ready.end());
    entries.insert(entries.end(), ongoing.begin(), ongoing.end());
    return entries;
}

bool Listed(Player* player, uint32 questId)
{
    for (MenuEntry const& entry : PlayerEntries(player))
        if (entry.quest == questId)
            return true;

    return false;
}

void SendPage(Player* player, Creature* ball, uint32 page)
{
    std::vector<MenuEntry> const entries = PlayerEntries(player);

    ClearGossipMenuFor(player);

    size_t const first = size_t(page) * PageSize;
    size_t const last = std::min(first + PageSize, entries.size());

    for (size_t i = first; i < last; ++i)
        player->PlayerTalkClass->GetQuestMenu().AddMenuItem(entries[i].quest,
            entries[i].kind == MenuKind::Available ? QuestIconAvailable : QuestIconActive);

    if (last < entries.size())
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "More quests...", SenderMore, page + 1);

    SendGossipMenuFor(player, GreetingTextId, ball->GetGUID());
}

bool CanUseBall(Player* player, Creature const* ball)
{
    if (!player || !AscensionWisdomball::IsWisdomball(ball) || !ball->IsAlive())
        return false;

    if (ball->GetMapId() != player->GetMapId())
        return false;

    if (!player->IsWithinDistInMap(ball, InteractionRange))
        return false;

    return player->InSamePhase(ball);
}

Creature* UsableBallAt(Player* player, ObjectGuid guid)
{
    Creature* ball = ObjectAccessor::GetCreatureOrPetOrVehicle(*player, guid);
    return CanUseBall(player, ball) ? ball : nullptr;
}

void PushStatus(Player* player, Creature* ball, uint8 status)
{
    player->PlayerTalkClass->SendQuestGiverStatus(status, ball->GetGUID());

    std::lock_guard<std::mutex> lock(_statusLock);
    StatusState& state = _statusByPlayer[player->GetGUID().GetCounter()];
    state.ball = ball->GetGUID();
    state.mapId = player->GetMapId();
    state.status = status;
    state.known = true;
}

class npc_wondrous_wisdomball_ai : public PassiveAI
{
public:
    explicit npc_wondrous_wisdomball_ai(Creature* creature) : PassiveAI(creature) { }
};

class npc_wondrous_wisdomball : public CreatureScript
{
public:
    npc_wondrous_wisdomball() : CreatureScript("npc_wondrous_wisdomball") { }

    CreatureAI* GetAI(Creature* creature) const override
    {
        return new npc_wondrous_wisdomball_ai(creature);
    }

    uint32 GetDialogStatus(Player* player, Creature* creature) override
    {
        if (!player)
            return DIALOG_STATUS_NONE;

        return AscensionWisdomball::DialogStatus(player, creature);
    }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        if (!AscensionWisdomball::IsWisdomball(creature))
            return false;

        SendPage(player, creature, 0);
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 sender, uint32 action) override
    {
        if (!AscensionWisdomball::IsWisdomball(creature))
            return false;

        if (sender != SenderMore)
            return false;

        SendPage(player, creature, action);
        return true;
    }
};

class wisdomball_player_script : public PlayerScript
{
public:
    wisdomball_player_script() : PlayerScript("wisdomball_player_script") { }

    void OnPlayerUpdate(Player* player, uint32) override
    {
        if (!player->HasSpell(AscensionWisdomball::SummonSpell))
            return;

        uint32 const now = getMSTime();
        {
            std::lock_guard<std::mutex> lock(_statusLock);
            StatusState& state = _statusByPlayer[player->GetGUID().GetCounter()];
            if (now < state.nextCheckMs)
                return;

            state.nextCheckMs = now + StatusCheckIntervalMs;
        }

        Creature* ball = AscensionWisdomball::ActiveBall(player);
        uint8 const status = ball ? AscensionWisdomball::DialogStatus(player, ball) : uint8(DIALOG_STATUS_NONE);
        ObjectGuid const ballGuid = ball ? ball->GetGUID() : ObjectGuid::Empty;
        uint32 const mapId = player->GetMapId();

        bool changed = false;
        {
            std::lock_guard<std::mutex> lock(_statusLock);
            StatusState& state = _statusByPlayer[player->GetGUID().GetCounter()];
            changed = !state.known || state.ball != ballGuid || state.mapId != mapId || state.status != status;
            state.ball = ballGuid;
            state.mapId = mapId;
            state.status = status;
            state.known = true;
        }

        if (changed && ball)
            player->PlayerTalkClass->SendQuestGiverStatus(status, ballGuid);
    }

    void OnPlayerMapChanged(Player* player) override
    {
        AscensionWisdomball::Forget(player);
    }

    void OnPlayerLogout(Player* player) override
    {
        AscensionWisdomball::Forget(player);
    }

    void OnPlayerCompleteQuest(Player* player, Quest const*) override
    {
        AscensionWisdomball::Forget(player);
    }
};

class wisdomball_packet_script : public ServerScript
{
public:
    wisdomball_packet_script()
        : ServerScript("wisdomball_packet_script", { SERVERHOOK_CAN_PACKET_RECEIVE })
    {
    }

    bool CanPacketReceive(WorldSession* session, WorldPacket const& packet) override
    {
        if (packet.GetOpcode() != CMSG_QUESTGIVER_QUERY_QUEST &&
            packet.GetOpcode() != CMSG_QUESTGIVER_COMPLETE_QUEST &&
            packet.GetOpcode() != CMSG_QUESTGIVER_ACCEPT_QUEST &&
            packet.GetOpcode() != CMSG_QUESTGIVER_REQUEST_REWARD &&
            packet.GetOpcode() != CMSG_QUESTGIVER_CHOOSE_REWARD)
            return true;

        Player* player = session ? session->GetPlayer() : nullptr;
        if (!player)
            return true;

        return !AscensionWisdomball::HandlePacket(player, packet);
    }
};
}

namespace AscensionWisdomball
{
bool IsWisdomball(Creature const* creature)
{
    return creature && creature->GetEntry() == CreatureEntry;
}

Creature* ActiveBall(Player* player)
{
    std::list<Creature*> creatures;
    player->GetCreatureListWithEntryInGrid(creatures, CreatureEntry, InteractionRange);

    for (Creature* creature : creatures)
        if (creature->IsAlive() && creature->GetOwnerGUID() == player->GetGUID() && player->InSamePhase(creature))
            return creature;

    return nullptr;
}

Creature* UsableBall(Player* player)
{
    std::list<Creature*> creatures;
    player->GetCreatureListWithEntryInGrid(creatures, CreatureEntry, InteractionRange);

    for (Creature* creature : creatures)
        if (CanUseBall(player, creature))
            return creature;

    return nullptr;
}

std::vector<uint32> OfferedQuests(Player* player)
{
    std::vector<uint32> offered;
    for (MenuEntry const& entry : PlayerEntries(player))
        if (entry.kind == MenuKind::Available)
            offered.push_back(entry.quest);

    return offered;
}

std::vector<uint32> CarriedQuests(Player* player)
{
    std::vector<uint32> carried;
    for (MenuEntry const& entry : PlayerEntries(player))
        if (entry.kind == MenuKind::Carried)
            carried.push_back(entry.quest);

    return carried;
}

std::vector<uint32> TurnInQuests(Player* player)
{
    std::vector<uint32> ready;
    for (uint32 questId : CarriedDungeonQuests(player))
        if (player->GetQuestStatus(questId) == QUEST_STATUS_COMPLETE)
            ready.push_back(questId);

    return ready;
}

uint8 DialogStatus(Player* player, Creature* ball)
{
    if (!player || !IsWisdomball(ball))
        return DIALOG_STATUS_NONE;

    bool handIn = false;
    bool takeable = false;

    for (MenuEntry const& entry : PlayerEntries(player))
    {
        if (entry.kind == MenuKind::Available)
            takeable = true;
        else if (player->GetQuestStatus(entry.quest) == QUEST_STATUS_COMPLETE)
            handIn = true;
    }

    if (handIn)
        return DIALOG_STATUS_REWARD;

    if (takeable)
        return DIALOG_STATUS_AVAILABLE;

    return DIALOG_STATUS_NONE;
}

bool Accept(Player* player, Creature* ball, Quest const* quest)
{
    if (!player || !IsWisdomball(ball) || !quest)
        return false;

    if (!CanUseBall(player, ball))
        return false;

    uint32 const questId = quest->GetQuestId();

    if (!InDungeon(player) || !Contains(QuestsForMap(player->GetMapId()).starters, questId) || !CanOffer(player, questId))
        return false;

    if (!player->CanAddQuest(quest, true))
        return false;

    LOG_DEBUG("scripts", "Wisdomball: {} takes quest {} in map {} from the ball",
        player->GetName(), questId, player->GetMapId());

    player->AddQuestAndCheckCompletion(quest, ball);
    PushStatus(player, ball, DialogStatus(player, ball));
    return true;
}

bool HandlePacket(Player* player, WorldPacket const& packet)
{
    switch (packet.GetOpcode())
    {
        case CMSG_QUESTGIVER_ACCEPT_QUEST:
        {
            WorldPacket copy(packet);
            ObjectGuid guid;
            uint32 questId = 0;
            uint8 unk = 0;
            copy >> guid >> questId >> unk;

            Creature* ball = UsableBallAt(player, guid);
            if (!ball)
                return false;

            if (Quest const* quest = sObjectMgr->GetQuestTemplate(questId))
                Accept(player, ball, quest);

            player->PlayerTalkClass->SendCloseGossip();
            return true;
        }
        case CMSG_QUESTGIVER_QUERY_QUEST:
        {
            WorldPacket copy(packet);
            ObjectGuid guid;
            uint32 questId = 0;
            uint8 unk = 0;
            copy >> guid >> questId >> unk;

            Creature* ball = UsableBallAt(player, guid);
            if (!ball)
                return false;

            Quest const* quest = sObjectMgr->GetQuestTemplate(questId);
            if (!quest || !Listed(player, questId))
            {
                player->PlayerTalkClass->SendCloseGossip();
                return true;
            }

            if (player->GetQuestStatus(questId) == QUEST_STATUS_NONE)
            {
                player->PlayerTalkClass->SendQuestGiverQuestDetails(quest, ball->GetGUID(), true);
            }
            else
            {
                SendCarriedWindow(player, ball, quest, true);
            }

            return true;
        }
        case CMSG_QUESTGIVER_COMPLETE_QUEST:
        {
            WorldPacket copy(packet);
            ObjectGuid guid;
            uint32 questId = 0;
            copy >> guid >> questId;

            Creature* ball = UsableBallAt(player, guid);
            if (!ball)
                return false;

            Quest const* quest = sObjectMgr->GetQuestTemplate(questId);
            if (!quest || !Listed(player, questId))
            {
                player->PlayerTalkClass->SendCloseGossip();
                return true;
            }

            if (player->GetQuestStatus(questId) == QUEST_STATUS_NONE)
            {
                player->PlayerTalkClass->SendQuestGiverQuestDetails(quest, ball->GetGUID(), true);
            }
            else
            {
                SendCarriedWindow(player, ball, quest, false);
            }

            return true;
        }
        case CMSG_QUESTGIVER_REQUEST_REWARD:
        {
            WorldPacket copy(packet);
            ObjectGuid guid;
            uint32 questId = 0;
            copy >> guid >> questId;

            Creature* ball = UsableBallAt(player, guid);
            if (!ball)
                return false;

            Quest const* quest = sObjectMgr->GetQuestTemplate(questId);
            if (!quest || !Listed(player, questId))
            {
                player->PlayerTalkClass->SendCloseGossip();
                return true;
            }

            if (player->CanCompleteQuest(questId))
                player->CompleteQuest(questId);

            if (player->GetQuestStatus(questId) == QUEST_STATUS_COMPLETE)
                player->PlayerTalkClass->SendQuestGiverOfferReward(quest, ball->GetGUID(), true);
            else
                SendCarriedWindow(player, ball, quest, false);

            return true;
        }
        case CMSG_QUESTGIVER_CHOOSE_REWARD:
        {
            WorldPacket copy(packet);
            ObjectGuid guid;
            uint32 questId = 0;
            uint32 reward = 0;
            copy >> guid >> questId >> reward;

            Creature* ball = UsableBallAt(player, guid);
            if (!ball)
                return false;

            if (reward >= QUEST_REWARD_CHOICES_COUNT)
                return true;

            Quest const* quest = sObjectMgr->GetQuestTemplate(questId);
            if (!quest)
                return true;

            if (player->GetQuestStatus(questId) != QUEST_STATUS_COMPLETE &&
                !quest->IsAutoComplete() && quest->GetQuestMethod())
                return true;

            if (player->CanRewardQuest(quest, reward, true))
            {
                player->RewardQuest(quest, reward, ball);
                PushStatus(player, ball, DialogStatus(player, ball));
            }

            return true;
        }
        default:
            return false;
    }
}

void Forget(Player* player)
{
    if (!player)
        return;

    std::lock_guard<std::mutex> lock(_statusLock);
    _statusByPlayer.erase(player->GetGUID().GetCounter());
}
}

void AddSC_AscensionWisdomball()
{
    new npc_wondrous_wisdomball();
    new wisdomball_player_script();
    new wisdomball_packet_script();
}
