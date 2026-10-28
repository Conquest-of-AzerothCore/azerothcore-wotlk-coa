/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionCrowsCachePolicy.h"
#include "Chat.h"
#include "Config.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "Errors.h"
#include "GameObject.h"
#include "GameTime.h"
#include "Item.h"
#include "ItemScript.h"
#include "Map.h"
#include "MapMgr.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Opcodes.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "TemporarySummon.h"
#include "World.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <algorithm>
#include <map>
#include <memory>
#include <mutex>
#include <vector>

namespace CrowsCache
{
using namespace Acore::ChatCommands;
struct Event
{
    uint32 id = 0;
    Phase phase = Phase::Warning;
    uint32 carrier = 0;
    uint32 item = 0;
    uint32 map = 1;
    Position position;
    uint64 deadline = 0;
    uint8 announcements = 0;
    ObjectGuid crow;
    ObjectGuid chest;
};

struct Reward
{
    uint32 item = 0;
    uint32 count = 1;
};

std::recursive_mutex mutex;
std::map<uint32, Event> events;
std::vector<Reward> gear;
std::vector<Reward> materials;
bool enabled = false;
bool randomLocation = true;
uint32 nextId = 1;
uint32 interval = 10800;
uint32 warning = 1800;
uint64 nextStart = 0;
Position location(-7831.0f, -3465.0f, 56.87f, 0.0f);
Position silithus(-7203.1616f, 372.38562f, 25.355282f, 4.4326873f);
Position needles(-5805.1646f, -3899.4047f, -95.3205f, 3.215081f);
Position barrens(-763.6296f, -3191.6892f, 91.666626f, 2.3004022f);

uint64 Now()
{
    return uint64(GameTime::GetGameTime().count());
}

void Commit(CharacterDatabaseTransaction transaction)
{
    auto result = CharacterDatabase.AsyncCommitTransaction(transaction);
    if (!result.m_future.get())
        ABORT("Crow's Cache transaction failed");
}

void Save(Event const& event, Player* player = nullptr, bool remove = false)
{
    auto transaction = CharacterDatabase.BeginTransaction();
    if (player)
        player->SaveInventoryAndGoldToDB(transaction);
    auto* statement = CharacterDatabase.GetPreparedStatement(remove ? CHAR_DEL_CROWS_CACHE : CHAR_REP_CROWS_CACHE);
    statement->SetData(0, event.id);
    if (!remove)
    {
        statement->SetData(1, uint8(event.phase));
        statement->SetData(2, event.carrier);
        statement->SetData(3, event.item);
        statement->SetData(4, uint16(event.map));
        statement->SetData(5, event.position.GetPositionX());
        statement->SetData(6, event.position.GetPositionY());
        statement->SetData(7, event.position.GetPositionZ());
        statement->SetData(8, event.position.GetOrientation());
        statement->SetData(9, event.deadline);
        statement->SetData(10, event.announcements);
    }
    transaction->Append(statement);
    Commit(transaction);
}

void SaveSchedule()
{
    Event schedule;
    schedule.phase = Phase::Schedule;
    schedule.deadline = nextStart;
    Save(schedule);
}

void SendMarker(Player* player, std::string const& message)
{
    WorldPacket packet;
    ChatHandler::BuildChatPacket(packet, CHAT_MSG_WHISPER, LANG_ADDON, player, player, "COACrows\t" + message);
    player->SendDirectMessage(&packet);
}

bool VisibleMarker(Event const& event)
{
    return event.phase == Phase::Warning || event.phase == Phase::Available;
}

std::string Marker(Event const& event)
{
    return Acore::StringFormat("P;{};{};{};{}", event.id, event.map,
        event.position.GetPositionX(), event.position.GetPositionY());
}

void BroadcastMarker(std::string const& message)
{
    std::shared_lock lock(*HashMapHolder<Player>::GetLock());
    for (auto const& [guid, player] : ObjectAccessor::GetPlayers())
        if (player->IsInWorld())
            SendMarker(player, message);
}

void BroadcastAnnouncement(std::string const& message)
{
    std::shared_lock lock(*HashMapHolder<Player>::GetLock());
    for (auto const& [guid, player] : ObjectAccessor::GetPlayers())
        if (player->IsInWorld())
            ChatHandler(player->GetSession()).SendSysMessage(message.c_str());
}

void SendMarkers(Player* player)
{
    SendMarker(player, "B");
    if (enabled)
        for (auto const& [id, event] : events)
            if (VisibleMarker(event))
                SendMarker(player, Marker(event));
    SendMarker(player, "E");
}

unsigned EventZone(Event const& event)
{
    return sMapMgr->GetZoneId(PHASEMASK_NORMAL, WorldLocation(event.map, event.position));
}

char const* LocationName(Event const& event)
{
    switch (EventZone(event))
    {
        case Silithus: return "Southwind Village, Silithus";
        case ThousandNeedles: return "Weazel's Crater, Thousand Needles";
        case Barrens: return "the Barrens";
        default: return "Abyssal Sands, Tanaris";
    }
}

char const* DeliveryTown(Event const& event)
{
    switch (EventZone(event))
    {
        case Silithus: return "Cenarion Hold";
        case Barrens: return "Ratchet";
        default: return "Gadgetzan";
    }
}

void Announce(Event& event, uint64 now)
{
    if (event.deadline <= now)
        return;
    unsigned index = DueWarning(event.announcements, uint32(event.deadline - now));
    if (index == WarningCount)
        return;
    event.announcements |= uint8((1u << (index + 1)) - 1);
    Save(event);
    BroadcastAnnouncement(Acore::StringFormat(
        "Crow's Cache is materializing in {} in {} minute{}!",
        LocationName(event), WarningSeconds[index] / 60, index == 3 ? "" : "s").c_str());
}

bool Carries(Player const* player)
{
    return std::any_of(events.begin(), events.end(), [player](auto const& row)
    {
        return row.second.phase == Phase::Carried && row.second.carrier == player->GetGUID().GetCounter()
            && player->GetItemByGuid(ObjectGuid::Create<HighGuid::Item>(row.second.item));
    });
}

void UpdateCarrier(Player* player)
{
    if (CarrySlow(Carries(player), player->GetAreaId()))
    {
        if (!player->HasAura(Spite))
        {
            player->RemoveAurasByType(SPELL_AURA_MOD_STEALTH);
            player->RemoveAurasByType(SPELL_AURA_MOD_INVISIBILITY);
            player->CastSpell(player, Spite, true);
        }
    }
    else if (player->HasAura(Spite))
        player->RemoveAurasDueToSpell(Spite);
}

bool Eligible(Player const* player)
{
    return Eligible(player->GetLevel(), player->HasAura(HighRisk), player->IsAlive());
}

Event* Find(GameObject const* object)
{
    for (auto& [id, event] : events)
        if (event.chest == object->GetGUID())
            return &event;
    return nullptr;
}

void RemoveObjects(Map* map, Event& event)
{
    if (Creature* crow = map->GetCreature(event.crow))
        crow->DespawnOrUnsummon();
    if (GameObject* chest = map->GetGameObject(event.chest))
        chest->Delete();
    event.crow.Clear();
    event.chest.Clear();
}

void Spawn(Map* map, Event& event)
{
    if (event.map != map->GetId() || event.phase == Phase::Carried)
        return;
    bool nearby = false;
    for (auto const& reference : map->GetPlayers())
        if (Player* player = reference.GetSource())
            if (player->GetExactDist(&event.position) < 500)
                nearby = true;
    if (!nearby)
        return;
    if (!event.crow && !event.chest)
    {
        float height = map->GetHeight(1, event.position.GetPositionX(), event.position.GetPositionY(),
            event.position.GetPositionZ() + 100, true, 200);
        if (height > INVALID_HEIGHT)
            event.position.m_positionZ = height;
    }
    if (event.phase == Phase::Warning)
    {
        if (event.deadline > Now() + 300)
            return;
        if (map->GetCreature(event.crow))
            return;
        Position above = event.position;
        above.m_positionZ += 3.0f;
        if (TempSummon* crow = map->SummonCreature(CrowEntry, above))
        {
            crow->SetUnitFlag(UNIT_FLAG_NON_ATTACKABLE | UNIT_FLAG_NOT_SELECTABLE);
            crow->SetReactState(REACT_PASSIVE);
            crow->SetCanFly(true);
            crow->SetDisableGravity(true);
            crow->SetHover(true);
            event.crow = crow->GetGUID();
        }
        return;
    }
    if (map->GetGameObject(event.chest))
        return;
    auto object = std::make_unique<GameObject>();
    auto const& p = event.position;
    uint32 entry = event.phase == Phase::Dropped ? DropEntry : ChestEntry;
    if (!object->Create(map->GenerateLowGuid<HighGuid::GameObject>(), entry, map, 1,
        p.GetPositionX(), p.GetPositionY(), p.GetPositionZ(), p.GetOrientation(),
        G3D::Quat(0, 0, 0, 1), 255, GO_STATE_READY))
        return;
    object->SetSpawnedByDefault(false);
    object->SetRespawnTime(0);
    if (map->AddToMap(object.get()))
    {
        event.chest = object->GetGUID();
        object.release();
    }
}

bool Claim(Player* player, GameObject* object, bool completedCast)
{
    std::lock_guard lock(mutex);
    Event* event = Find(object);
    if (!event || !Eligible(player) || !CanClaim(event->phase, completedCast)
        || player->GetExactDist(object) > 5.0f || !player->InSamePhase(object))
        return false;
    ItemPosCountVec destination;
    InventoryResult error = player->CanStoreNewItem(NULL_BAG, NULL_SLOT, destination, CacheItem, 1);
    if (error != EQUIP_ERR_OK)
    {
        player->SendEquipError(error, nullptr, nullptr, CacheItem);
        return false;
    }
    Item* cache = player->StoreNewItem(destination, CacheItem, true);
    if (!cache)
        return false;
    player->SendNewItem(cache, 1, true, false);
    if (event->phase == Phase::Available)
        event->deadline = Now() + 86400;
    cache->SetUInt32Value(ITEM_FIELD_DURATION, uint32(event->deadline > Now() ? event->deadline - Now() : 1));
    BroadcastMarker(Acore::StringFormat("D;{}", event->id));
    event->phase = Phase::Carried;
    event->carrier = player->GetGUID().GetCounter();
    event->item = cache->GetGUID().GetCounter();
    Save(*event, player);
    RemoveObjects(player->GetMap(), *event);
    UpdateCarrier(player);
    ChatHandler(player->GetSession()).PSendSysMessage("Crow's Cache claimed. Carry it to {} to open it.",
        DeliveryTown(*event));
    return true;
}

void Drop(Player* player)
{
    std::lock_guard lock(mutex);
    for (auto& [id, event] : events)
    {
        if (event.phase != Phase::Carried || event.carrier != player->GetGUID().GetCounter())
            continue;
        Item* cache = player->GetItemByGuid(ObjectGuid::Create<HighGuid::Item>(event.item));
        if (!cache)
            continue;
        player->DestroyItem(cache->GetBagSlot(), cache->GetSlot(), true);
        event.phase = Phase::Dropped;
        event.carrier = 0;
        event.item = 0;
        event.map = player->GetMapId();
        event.position.Relocate(player);
        Save(event, player);
        Spawn(player->GetMap(), event);
    }
    UpdateCarrier(player);
}

bool Open(Player* player, Item* cache)
{
    std::lock_guard lock(mutex);
    auto found = std::find_if(events.begin(), events.end(), [player, cache](auto const& row)
    {
        return row.second.phase == Phase::Carried && row.second.carrier == player->GetGUID().GetCounter()
            && row.second.item == cache->GetGUID().GetCounter();
    });
    if (!CanOpen(found != events.end(), Eligible(player), player->GetAreaId(), player->IsInCombat()))
    {
        ChatHandler(player->GetSession()).SendSysMessage(
            "You must be level 60, in High-Risk mode and out of combat in Gadgetzan, Cenarion Hold or Ratchet to open a claimed Crow's Cache.");
        return false;
    }
    if (gear.size() < RewardCount || materials.empty())
        return false;
    std::vector<Reward> rewards;
    auto pool = gear;
    for (unsigned i = 0; i < RewardCount; ++i)
    {
        unsigned index = urand(0, uint32(pool.size() - 1));
        rewards.push_back(pool[index]);
        pool.erase(pool.begin() + index);
    }
    rewards.insert(rewards.end(), materials.begin(), materials.end());
    std::vector<std::unique_ptr<Item>> pending;
    std::vector<Item*> pointers;
    for (Reward const& reward : rewards)
    {
        pending.emplace_back(Item::CreateItem(reward.item, reward.count, player));
        if (!pending.back())
            return false;
        pointers.push_back(pending.back().get());
    }
    uint32 limited = 0;
    InventoryResult error = player->CanStoreItems(pointers.data(), int(pointers.size()), &limited);
    if (error != EQUIP_ERR_OK)
    {
        player->SendEquipError(error, cache, nullptr, limited);
        return false;
    }
    std::vector<std::pair<ObjectGuid, uint32>> stored;
    for (auto& item : pending)
    {
        ItemPosCountVec destination;
        error = player->CanStoreItem(NULL_BAG, NULL_SLOT, destination, item.get(), false);
        if (error != EQUIP_ERR_OK)
        {
            for (auto const& [guid, count] : stored)
                if (Item* undo = player->GetItemByGuid(guid))
                {
                    if (undo->GetCount() > count)
                    {
                        undo->SetCount(undo->GetCount() - count);
                        undo->SetState(ITEM_CHANGED, player);
                    }
                    else
                        player->DestroyItem(undo->GetBagSlot(), undo->GetSlot(), true);
                }
            return false;
        }
        uint32 count = item->GetCount();
        Item* result = player->StoreItem(destination, item.release(), true);
        stored.emplace_back(result->GetGUID(), count);
        player->SendNewItem(result, count, true, false);
    }
    player->DestroyItem(cache->GetBagSlot(), cache->GetSlot(), true);
    Save(found->second, player, true);
    events.erase(found);
    UpdateCarrier(player);
    ChatHandler(player->GetSession()).SendSysMessage(
        "Crow's Cache opened: five top-tier Heroic Bloodforged raid items and High-Risk materials.");
    return true;
}

void Begin(uint32 seconds, Position const& point)
{
    Event event;
    event.id = nextId++;
    event.position = point;
    event.deadline = Now() + seconds;
    event.announcements = uint8(PassedWarnings(seconds));
    Save(event);
    auto [found, inserted] = events.emplace(event.id, event);
    Announce(found->second, Now());
    BroadcastMarker(Marker(found->second));
    if (std::none_of(std::begin(WarningSeconds), std::end(WarningSeconds), [seconds](unsigned value)
        { return value == seconds; }))
        BroadcastAnnouncement(Acore::StringFormat(
            "Crow's Cache is materializing in {} in {} seconds!", LocationName(found->second), seconds).c_str());
}

void UpdateEvents()
{
    if (!enabled)
        return;
    std::lock_guard lock(mutex);
    uint64 now = Now();
    uint64 scheduled = NextAppearance(nextStart, now, interval);
    if (scheduled != nextStart)
    {
        nextStart = scheduled;
        SaveSchedule();
    }
    if (now + warning >= nextStart)
    {
        Position const* locations[] = {&location, &silithus, &needles, &barrens};
        Begin(uint32(nextStart - now), *locations[randomLocation ? urand(0, 3) : 0]);
        nextStart += interval;
        SaveSchedule();
    }
    for (auto it = events.begin(); it != events.end();)
    {
        Event& event = it->second;
        Map* map = sMapMgr->FindBaseNonInstanceMap(event.map);
        if (event.phase == Phase::Warning && now >= event.deadline)
        {
            if (map)
                RemoveObjects(map, event);
            event.phase = Phase::Available;
            event.deadline = 0;
            Save(event);
            if (map)
                for (auto const& reference : map->GetPlayers())
                    if (Player* player = reference.GetSource())
                        if (player->IsAlive() && player->GetExactDist(&event.position) < 30)
                            player->KnockbackFrom(event.position.GetPositionX(), event.position.GetPositionY(), 15, 6);
            BroadcastAnnouncement(Acore::StringFormat(
                "Crow's Cache has appeared in {}! High-Risk level-60 players can claim it.", LocationName(event)));
        }
        else if ((event.phase == Phase::Carried || event.phase == Phase::Dropped) && event.deadline <= now)
        {
            if (map)
                RemoveObjects(map, event);
            Save(event, nullptr, true);
            it = events.erase(it);
            continue;
        }
        else if (event.phase == Phase::Warning)
            Announce(event, now);
        ++it;
    }
}

class Configuration final : public WorldScript
{
public:
    Configuration() : WorldScript("crows_cache_configuration", {WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_UPDATE}) { }
    void OnUpdate(uint32) override { UpdateEvents(); }
    void OnStartup() override
    {
        std::lock_guard lock(mutex);
        enabled = sConfigMgr->GetOption<bool>("CrowsCache.Enable", false);
        randomLocation = sConfigMgr->GetOption<bool>("CrowsCache.RandomLocation", true);
        silithus.Relocate(sConfigMgr->GetOption<float>("CrowsCache.Silithus.X", -7203.1616f),
            sConfigMgr->GetOption<float>("CrowsCache.Silithus.Y", 372.38562f),
            sConfigMgr->GetOption<float>("CrowsCache.Silithus.Z", 25.355282f),
            sConfigMgr->GetOption<float>("CrowsCache.Silithus.O", 4.4326873f));
        needles.Relocate(sConfigMgr->GetOption<float>("CrowsCache.Needles.X", -5805.1646f),
            sConfigMgr->GetOption<float>("CrowsCache.Needles.Y", -3899.4047f),
            sConfigMgr->GetOption<float>("CrowsCache.Needles.Z", -95.3205f),
            sConfigMgr->GetOption<float>("CrowsCache.Needles.O", 3.215081f));
        barrens.Relocate(sConfigMgr->GetOption<float>("CrowsCache.Barrens.X", -763.6296f),
            sConfigMgr->GetOption<float>("CrowsCache.Barrens.Y", -3191.6892f),
            sConfigMgr->GetOption<float>("CrowsCache.Barrens.Z", 91.666626f),
            sConfigMgr->GetOption<float>("CrowsCache.Barrens.O", 2.3004022f));
        warning = std::clamp<uint32>(sConfigMgr->GetOption<uint32>("CrowsCache.WarningSeconds", 1800), 1, 1800);
        interval = std::max<uint32>(warning + 60,
            sConfigMgr->GetOption<uint32>("CrowsCache.IntervalSeconds", 10800));
        location.Relocate(sConfigMgr->GetOption<float>("CrowsCache.X", -7831.0f),
            sConfigMgr->GetOption<float>("CrowsCache.Y", -3465.0f),
            sConfigMgr->GetOption<float>("CrowsCache.Z", 56.87f), 0.0f);
        if (!enabled)
            return;
        auto* rewardStatement = WorldDatabase.GetPreparedStatement(WORLD_SEL_CROWS_CACHE_REWARDS);
        if (PreparedQueryResult result = WorldDatabase.Query(rewardStatement))
            do
            {
                Field* f = result->Fetch();
                uint32 entry = f[1].Get<uint32>();
                if (!sObjectMgr->GetItemTemplate(entry))
                    continue;
                (f[0].Get<uint8>() == 0 ? gear : materials).push_back({entry, f[2].Get<uint32>()});
            } while (result->NextRow());
        if (gear.size() < RewardCount || materials.empty())
        {
            enabled = false;
            LOG_ERROR("coa", "Crow's Cache disabled: reward pool is incomplete");
            return;
        }
        auto* statement = CharacterDatabase.GetPreparedStatement(CHAR_SEL_CROWS_CACHE);
        if (PreparedQueryResult result = CharacterDatabase.Query(statement))
            do
            {
                Field* f = result->Fetch();
                Event event;
                event.id = f[0].Get<uint32>();
                event.phase = Phase(f[1].Get<uint8>());
                event.carrier = f[2].Get<uint32>();
                event.item = f[3].Get<uint32>();
                event.map = f[4].Get<uint16>();
                event.position.Relocate(f[5].Get<float>(), f[6].Get<float>(), f[7].Get<float>(), f[8].Get<float>());
                event.deadline = f[9].Get<uint64>();
                event.announcements = f[10].Get<uint8>();
                if (!event.id)
                    nextStart = event.deadline;
                else
                {
                    nextId = std::max(nextId, event.id + 1);
                    events.emplace(event.id, event);
                }
            } while (result->NextRow());
        if (!nextStart)
        {
            nextStart = Now() + interval;
            SaveSchedule();
        }
        LOG_INFO("coa", "Crow's Cache enabled: {} raid rewards, {} material rewards, {} restored events",
            gear.size(), materials.size(), events.size());
    }
};

class Maps final : public AllMapScript
{
public:
    Maps() : AllMapScript("crows_cache_maps", {ALLMAPHOOK_ON_MAP_UPDATE}) { }
    void OnMapUpdate(Map* map, uint32) override
    {
        if (!enabled || map->Instanceable())
            return;
        std::lock_guard lock(mutex);
        for (auto& [id, event] : events)
            Spawn(map, event);
        for (auto const& reference : map->GetPlayers())
            if (Player* player = reference.GetSource())
                UpdateCarrier(player);
    }
};

class Players final : public PlayerScript
{
public:
    Players() : PlayerScript("crows_cache_players", {PLAYERHOOK_ON_PLAYER_JUST_DIED, PLAYERHOOK_ON_LOGIN,
        PLAYERHOOK_ON_UPDATE_AREA, PLAYERHOOK_CAN_INIT_TRADE, PLAYERHOOK_CAN_SEND_MAIL,
        PLAYERHOOK_CAN_PLAYER_USE_PRIVATE_CHAT}) { }
    void OnPlayerJustDied(Player* player) override { Drop(player); }
    void OnPlayerLogin(Player* player) override
    {
        std::lock_guard lock(mutex);
        UpdateCarrier(player);
        SendMarkers(player);
        for (uint32 entry : {ChestEntry, DropEntry})
        {
            WorldPacket query(CMSG_GAMEOBJECT_QUERY, 12);
            query << entry << ObjectGuid::Empty;
            player->GetSession()->HandleGameObjectQueryOpcode(query);
        }
    }
    void OnPlayerUpdateArea(Player* player, uint32, uint32) override
    {
        std::lock_guard lock(mutex);
        UpdateCarrier(player);
    }
    bool OnPlayerCanUseChat(Player* player, uint32 type, uint32 language, std::string& message, Player* receiver) override
    {
        if (type != CHAT_MSG_WHISPER || language != LANG_ADDON || receiver != player
            || message != "COACrows\tSYNC")
            return true;
        std::lock_guard lock(mutex);
        SendMarkers(player);
        return false;
    }
    bool OnPlayerCanInitTrade(Player* player, Player* target) override
    {
        return !player->HasAura(Spite) && !target->HasAura(Spite);
    }
    bool OnPlayerCanSendMail(Player*, ObjectGuid, ObjectGuid, std::string&, std::string&, uint32, uint32, Item* item) override
    {
        return !item || item->GetEntry() != CacheItem;
    }
};

class Chest final : public GameObjectScript
{
public:
    Chest() : GameObjectScript("crows_cache_chest") { }
    bool OnGossipHello(Player* player, GameObject* object) override
    {
        if (!enabled)
            return true;
        if (!Eligible(player))
        {
            ChatHandler(player->GetSession()).SendSysMessage("Only living level-60 High-Risk players can claim Crow's Cache.");
            return true;
        }
        if (object->GetEntry() == DropEntry)
            Claim(player, object, false);
        else
            player->CastSpell(object, OpenSpell, false);
        return true;
    }
};

class Opening final : public SpellScript
{
    PrepareSpellScript(Opening);
    void Handle(SpellEffIndex effect)
    {
        GameObject* object = GetHitGObj();
        if (!object || object->GetEntry() != ChestEntry)
            return;
        PreventHitDefaultEffect(effect);
        if (Player* player = GetCaster()->ToPlayer())
            Claim(player, object, true);
    }
    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(Opening::Handle, EFFECT_0, SPELL_EFFECT_OPEN_LOCK);
    }
};

class Casts final : public AllSpellScript
{
public:
    Casts() : AllSpellScript("crows_cache_casts", {ALLSPELLHOOK_ON_SPELL_CHECK_CAST}) { }
    void OnSpellCheckCast(Spell* spell, bool, SpellCastResult& result) override
    {
        Unit* caster = spell->GetCaster();
        if (!caster || !caster->IsPlayer())
            return;
        Player* player = caster->ToPlayer();
        if (spell->GetSpellInfo()->Id == OpenSpell)
        {
            GameObject* object = spell->m_targets.GetGOTarget();
            if (object && object->GetEntry() == ChestEntry)
            {
                std::lock_guard lock(mutex);
                Event* event = Find(object);
                if (!enabled || !Eligible(player) || !event || event->phase != Phase::Available
                    || player->GetExactDist(object) > 5.0f)
                    result = SPELL_FAILED_BAD_TARGETS;
            }
        }
        if (!player->HasAura(Spite))
            return;
        for (SpellEffectInfo const& effect : spell->GetSpellInfo()->GetEffects())
            if (effect.Effect == SPELL_EFFECT_TELEPORT_UNITS || effect.Effect == SPELL_EFFECT_TELEPORT_UNITS_FACE_CASTER
                || effect.ApplyAuraName == SPELL_AURA_MOD_STEALTH || effect.ApplyAuraName == SPELL_AURA_MOD_INVISIBILITY)
                result = SPELL_FAILED_NOT_HERE;
    }
};

class Damage final : public UnitScript
{
public:
    Damage() : UnitScript("crows_cache_damage", true, {UNITHOOK_ON_DAMAGE}) { }
    void OnDamage(Unit*, Unit* victim, uint32& damage) override
    {
        if (!InterruptOpening(false, damage))
            return;
        Spell* spell = victim->GetCurrentSpell(CURRENT_GENERIC_SPELL);
        if (!spell || spell->GetSpellInfo()->Id != OpenSpell)
            return;
        GameObject* object = spell->m_targets.GetGOTarget();
        if (object && object->GetEntry() == ChestEntry)
            victim->InterruptNonMeleeSpells(false, OpenSpell);
    }
};

class Cache final : public ItemScript
{
public:
    Cache() : ItemScript("item_crows_cache") { }
    bool OnUse(Player* player, Item* item, SpellCastTargets const&) override
    {
        Open(player, item);
        return true;
    }
};

class Packets final : public ServerScript
{
public:
    Packets() : ServerScript("crows_cache_packets", {SERVERHOOK_CAN_PACKET_RECEIVE}) { }
    bool CanPacketReceive(WorldSession* session, WorldPacket const& packet) override
    {
        Player* player = session ? session->GetPlayer() : nullptr;
        if (!player || !player->IsInWorld())
            return true;
        if (packet.GetOpcode() == CMSG_OPEN_ITEM && packet.size() >= 2)
        {
            Item* item = player->GetItemByPos(packet.read<uint8>(0), packet.read<uint8>(1));
            if (item && item->GetEntry() == CacheItem)
            {
                Open(player, item);
                return false;
            }
        }
        if (packet.GetOpcode() == CMSG_AUTOBANK_ITEM || packet.GetOpcode() == CMSG_AUTOSTORE_BANK_ITEM)
        {
            std::lock_guard lock(mutex);
            if (Carries(player))
            {
                ChatHandler(session).SendSysMessage("Open your Crow's Cache before using the bank.");
                return false;
            }
        }
        return true;
    }
};

class Commands final : public CommandScript
{
public:
    Commands() : CommandScript("crows_cache_commands") { }
    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable children =
        {
            {"start", Start, SEC_GAMEMASTER, Console::Yes},
            {"here", Here, SEC_GAMEMASTER, Console::No},
            {"silithus", StartSilithus, SEC_GAMEMASTER, Console::Yes},
            {"needles", StartNeedles, SEC_GAMEMASTER, Console::Yes},
            {"barrens", StartBarrens, SEC_GAMEMASTER, Console::Yes},
            {"visit", Visit, SEC_GAMEMASTER, Console::No},
            {"status", Status, SEC_GAMEMASTER, Console::Yes},
            {"schedule", Schedule, SEC_GAMEMASTER, Console::Yes},
            {"cancel", Cancel, SEC_GAMEMASTER, Console::Yes}
        };
        static ChatCommandTable commands = {{"crows", children}};
        return commands;
    }
    static bool Start(ChatHandler* handler, Optional<uint32> seconds)
    {
        std::lock_guard lock(mutex);
        if (!enabled)
        {
            handler->SendSysMessage("Crow's Cache is disabled or has no valid reward pool.");
            return false;
        }
        Begin(std::clamp<uint32>(seconds.value_or(warning), 1, 3600), location);
        handler->SendSysMessage("Crow's Cache warning started. Use .crows visit to reach it.");
        return true;
    }
    static bool StartSilithus(ChatHandler* handler, Optional<uint32> seconds)
    {
        std::lock_guard lock(mutex);
        if (!enabled)
            return false;
        Begin(std::clamp<uint32>(seconds.value_or(warning), 1, 3600), silithus);
        handler->SendSysMessage("Silithus Crow's Cache warning started. Use .crows visit to reach it.");
        return true;
    }
    static bool StartNeedles(ChatHandler* handler, Optional<uint32> seconds)
    {
        std::lock_guard lock(mutex);
        if (!enabled)
            return false;
        Begin(std::clamp<uint32>(seconds.value_or(warning), 1, 3600), needles);
        handler->SendSysMessage("Crow's Cache warning started. Use .crows visit to reach it.");
        return true;
    }
    static bool StartBarrens(ChatHandler* handler, Optional<uint32> seconds)
    {
        std::lock_guard lock(mutex);
        if (!enabled)
            return false;
        Begin(std::clamp<uint32>(seconds.value_or(warning), 1, 3600), barrens);
        handler->SendSysMessage("Crow's Cache warning started. Use .crows visit to reach it.");
        return true;
    }
    static bool Here(ChatHandler* handler, Optional<uint32> seconds)
    {
        Player* player = handler->GetPlayer();
        if (!player || player->GetMapId() != 1
            || (player->GetZoneId() != Tanaris && player->GetZoneId() != Silithus
                && player->GetZoneId() != ThousandNeedles && player->GetZoneId() != Barrens) || !enabled)
            return false;
        std::lock_guard lock(mutex);
        Begin(std::clamp<uint32>(seconds.value_or(warning), 1, 3600), *player);
        handler->SendSysMessage("Crow's Cache warning started at your current position.");
        return true;
    }
    static bool Visit(ChatHandler* handler)
    {
        std::lock_guard lock(mutex);
        Player* player = handler->GetPlayer();
        if (!player || Carries(player))
            return false;
        if (events.empty())
            return player->TeleportTo(1, location.GetPositionX(), location.GetPositionY(), location.GetPositionZ(), 0);
        Event const& event = events.rbegin()->second;
        return player->TeleportTo(event.map, event.position.GetPositionX() + 3,
            event.position.GetPositionY(), event.position.GetPositionZ(), 0);
    }
    static bool Schedule(ChatHandler* handler, Optional<uint32> seconds)
    {
        std::lock_guard lock(mutex);
        if (!enabled)
            return false;
        nextStart = Now() + std::clamp<uint32>(seconds.value_or(interval), 1, 31536000);
        SaveSchedule();
        handler->SendSysMessage("The next automatic Crow's Cache appearance has been scheduled.");
        return true;
    }
    static bool Cancel(ChatHandler* handler)
    {
        std::lock_guard lock(mutex);
        for (auto it = events.begin(); it != events.end();)
        {
            Event& event = it->second;
            if (!VisibleMarker(event))
            {
                ++it;
                continue;
            }
            if (Map* map = sMapMgr->FindBaseNonInstanceMap(event.map))
                RemoveObjects(map, event);
            Save(event, nullptr, true);
            BroadcastMarker(Acore::StringFormat("D;{}", event.id));
            it = events.erase(it);
        }
        handler->SendSysMessage("Unclaimed Crow's Cache test events cancelled. Carried and dropped caches are preserved.");
        return true;
    }
    static bool Status(ChatHandler* handler)
    {
        std::lock_guard lock(mutex);
        handler->PSendSysMessage("Crow's Cache: enabled={}, raid pool={}, active events={}, next automatic chest in {} seconds.",
            enabled, gear.size(), events.size(), nextStart > Now() ? nextStart - Now() : 0);
        for (auto const& [id, event] : events)
            handler->PSendSysMessage("Event {}: phase={}, carrier={}, map={}, position=({}, {}, {}).",
                id, unsigned(event.phase), event.carrier, event.map, event.position.GetPositionX(),
                event.position.GetPositionY(), event.position.GetPositionZ());
        return true;
    }
};
}

void AddSC_AscensionCrowsCache()
{
    new CrowsCache::Configuration();
    new CrowsCache::Maps();
    new CrowsCache::Players();
    new CrowsCache::Chest();
    RegisterSpellScript(CrowsCache::Opening);
    new CrowsCache::Casts();
    new CrowsCache::Damage();
    new CrowsCache::Cache();
    new CrowsCache::Packets();
    new CrowsCache::Commands();
}
