/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "AscensionReaperTalents.h"
#include "AccountMgr.h"
#include "AscensionCoATalentState.h"
#include "AscensionItemScaling.h"
#include "AscensionNativeItemScaling.h"
#include "AscensionQuestLog.h"
#include "AscensionSpecialization.h"
#include "AscensionWisdomball.h"
#include "AscensionWildcard.h"
#include "AscensionWildcardStarterData.h"
#include "AsyncCallbackProcessor.h"
#include "Bag.h"
#include "CharacterCache.h"
#include "CharmInfo.h"
#include "Chat.h"
#include "ClientDBC.h"
#include "CoACreatureScaling.h"
#include "Config.h"
#include "Creature.h"
#include "CreatureAI.h"
#include "AscensionCreaturePreset.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "DynamicObject.h"
#include "GameObject.h"
#include "GameTime.h"
#include "GitRevision.h"
#include "GossipDef.h"
#include "Group.h"
#include "GroupMgr.h"
#include "Item.h"
#include "LFGMgr.h"
#include "LFGPackets.h"
#include "ItemPackets.h"
#include "InstancePackets.h"
#include "NPCPackets.h"
#include "Log.h"
#include "LocalLevelScaling.h"
#include "LootMgr.h"
#include "Map.h"
#include "MapMgr.h"
#include "MoveSpline.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Opcodes.h"
#include "Pet.h"
#include "PetPackets.h"
#include "Player.h"
#include "QuestDef.h"
#include "QueryCallback.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "StringFormat.h"
#include "TemporarySummon.h"
#include "Timer.h"
#include "TypeContainerVisitor.h"
#include "UpdateData.h"
#include "UpdateFields.h"
#include "World.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include "WhoListCacheMgr.h"

#include "CoAGameplayClock.h"
#include "CoAGameplayIsolation.h"
#include "CoASpellbook.h"
#include <boost/bind/placeholders.hpp>
#include <boost/property_tree/json_parser.hpp>
#include <algorithm>
#include <array>
#include <bit>
#include <chrono>
#include <cmath>
#include <cstring>
#include <ctime>
#include <filesystem>
#include <fstream>
#include <future>
#include <list>
#include <limits>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <unordered_map>
#include <unordered_set>
#include <stdexcept>
#include <utility>
#include <vector>

namespace
{
using Tree = boost::property_tree::ptree;
using Clock = std::chrono::steady_clock;
using CoAGameplay::LaneActivity;
using CoAGameplay::StepRequest;

std::set<ObjectGuid> NoRegenerationActors;

class CoAGameplayTestRegeneration final : public PlayerScript
{
public:
    CoAGameplayTestRegeneration() : PlayerScript("CoAGameplayTestRegeneration",
        {PLAYERHOOK_ON_CAN_REGENERATE}) { }

    bool OnPlayerCanRegenerate(Player* player, int32) override
    {
        return !NoRegenerationActors.contains(player->GetGUID());
    }
};
constexpr uint32 MaximumActors = 8;
constexpr uint16 LevelScalingOpcode = 0x0667;
constexpr uint16 ApplyAppearancesOpcode = 0x0697;
constexpr uint16 KnownEntriesUploadOpcode = 0x0727;
constexpr uint16 KnownEntriesOpcode = 0x0726;
constexpr uint16 UpdateEntriesResultOpcode = 0x072C;
constexpr uint32 TalentRequestWindowMs = 2000;
constexpr std::size_t QuestQueryFlagsOffset = 80;
constexpr std::size_t QuestQueryFirstChoiceItemOffset = 136;

void Require(bool condition, std::string const& message)
{
    if (!condition)
        throw std::runtime_error(message);
}

std::list<GameObject*> OwnedGameObjects(Player* player, uint32 entry)
{
    Require(sObjectMgr->GetGameObjectTemplate(entry) != nullptr, "Unknown gameobject entry");
    std::list<GameObject*> objects;
    player->GetGameObjectListWithEntryInGrid(objects, entry, 100.0f);
    objects.remove_if([player](GameObject* object)
    {
        return !object->IsInWorld() || object->GetOwnerGUID() != player->GetGUID() || !player->InSamePhase(object);
    });
    return objects;
}

void WriteResult(std::string const& path, Tree const& result)
{
    Require(!path.empty() && !std::filesystem::exists(path), "Output path must be new");
    std::string temporary = path + ".tmp";
    boost::property_tree::write_json(temporary, result);
    std::filesystem::rename(temporary, path);
}

bool WriteCaseResult(std::string const& path, Tree const& result)
{
    try
    {
        WriteResult(path, result);
        return true;
    }
    catch (std::exception const& error)
    {
        LOG_ERROR("coa.gameplay_test", "Could not write gameplay result: {}", error.what());
        return false;
    }
}

uint64 Elapsed(Clock::time_point start)
{
    return std::chrono::duration_cast<std::chrono::milliseconds>(Clock::now() - start).count();
}

uint64 GameElapsed(TimePoint start)
{
    return uint64(std::max<Milliseconds::rep>(0,
        std::chrono::duration_cast<Milliseconds>(GameTime::Now() - start).count()));
}

bool IsRunId(std::string const& id)
{
    return id.size() == 12 && id.find_first_not_of("0123456789abcdef") == std::string::npos;
}

constexpr uint64 RunnerPatienceMs = 600000;
constexpr uint64 TeardownRecheckMs = 50;
constexpr uint64 RealBackstopFactor = 3;
constexpr uint32 DefaultStartHour = 10;
constexpr uint32 HoursPerDay = 24;
constexpr int32 DaysToFindAnHour = 3;
constexpr char const* RealClock = "real";
constexpr char const* SimulatedClock = "simulated";

std::tm RealmLocalTime(Seconds time)
{
    return Acore::Time::TimeBreakdown(time_t(time.count()));
}

std::string RealmLocalText(Seconds time)
{
    std::tm const local = RealmLocalTime(time);
    return Acore::StringFormat("{:04}-{:02}-{:02} {:02}:{:02}:{:02}", local.tm_year + 1900, local.tm_mon + 1,
        local.tm_mday, local.tm_hour, local.tm_min, local.tm_sec);
}

SystemTimePoint NextRealmLocalHour(SystemTimePoint from, uint32 hour)
{
    std::tm const today = RealmLocalTime(std::chrono::floor<Seconds>(from.time_since_epoch()));
    for (int32 day = 0; day < DaysToFindAnHour; ++day)
    {
        std::tm start = today;
        start.tm_mday += day;
        start.tm_hour = int32(hour);
        start.tm_min = 0;
        start.tm_sec = 0;
        start.tm_isdst = -1;
        time_t const startTime = std::mktime(&start);
        Require(startTime != time_t(-1), "Could not convert a realm-local hour to a timestamp");
        SystemTimePoint const point = std::chrono::system_clock::from_time_t(startTime);
        if (point >= from)
            return point;
    }
    throw std::runtime_error("Could not find the next realm-local hour");
}

bool InFirstMinuteOfHour(Seconds time, uint32 hour)
{
    std::tm const local = RealmLocalTime(time);
    return uint32(local.tm_hour) == hour && local.tm_min == 0;
}

void RequireRealmLocalHour(uint32 hour)
{
    std::tm const local = RealmLocalTime(GameTime::GetGameTime());
    Require(uint32(local.tm_hour) == hour, Acore::StringFormat("Case needs realm-local hour {:02}:00-{:02}:59, but "
        "realm-local time is {:02}:{:02}; run it on a worldserver whose TZ puts local time in that hour", hour, hour,
        local.tm_hour, local.tm_min));
}

struct CaseAccounts
{
    std::vector<std::string> accounts;
    std::vector<std::string> characters;
    bool namesReusable = false;
};

struct CaseOutcome
{
    std::string resultPath;
    Tree report;
    CaseAccounts accounts;
};

class ProcCounter
{
public:
    static void Begin()
    {
        _counts.clear();
        _casts.clear();
        _enabled = true;
    }

    static void Record(ObjectGuid unit, uint32 spell)
    {
        if (_enabled)
            ++_counts[{ unit, spell }];
    }

    static uint32 Count(ObjectGuid unit, uint32 spell)
    {
        auto itr = _counts.find({ unit, spell });
        return itr == _counts.end() ? 0 : itr->second;
    }

    static void RecordCast(ObjectGuid unit, uint32 spell)
    {
        if (_enabled)
            ++_casts[{ unit, spell }];
    }

    static uint32 CastCount(ObjectGuid unit, uint32 spell)
    {
        auto itr = _casts.find({ unit, spell });
        return itr == _casts.end() ? 0 : itr->second;
    }

    static void Forget(std::set<ObjectGuid> const& units)
    {
        auto const owned = [&units](auto const& entry) { return units.contains(entry.first.first); };
        std::erase_if(_counts, owned);
        std::erase_if(_casts, owned);
    }

private:
    static bool _enabled;
    static std::map<std::pair<ObjectGuid, uint32>, uint32> _counts;
    static std::map<std::pair<ObjectGuid, uint32>, uint32> _casts;
};

bool ProcCounter::_enabled = false;
std::map<std::pair<ObjectGuid, uint32>, uint32> ProcCounter::_counts;
std::map<std::pair<ObjectGuid, uint32>, uint32> ProcCounter::_casts;

enum class ActorStage
{
    Account,
    Creating,
    Enumerating,
    Enumerated,
    LoggingIn,
    InWorld,
    Transfer,
    Ready
};

struct SpellCastEvent
{
    ObjectGuid caster;
    uint32 spell = 0;
};

struct SpellDamageEvent
{
    ObjectGuid caster;
    ObjectGuid target;
    uint32 spell = 0;
    uint32 damage = 0;
    bool critical = false;
};

struct SpellHealEvent
{
    ObjectGuid caster;
    ObjectGuid target;
    uint32 spell = 0;
    uint32 heal = 0;
    uint32 overheal = 0;
    bool critical = false;
};

struct SpellEnergizeEvent
{
    ObjectGuid caster;
    ObjectGuid target;
    uint32 spell = 0;
    uint32 power = 0;
    uint32 amount = 0;
};

struct Actor
{
    Tree definition;
    std::string account;
    std::string name;
    std::map<std::string, uint32> whoClasses;
    std::map<uint32, uint32> learnedAlerts;
    std::map<uint32, uint32> buySucceeded;
    std::map<uint32, uint32> buyFailed;
    std::set<uint32> announced;
    std::map<uint32, uint32> notifyRows;
    std::map<uint32, uint32> notifiedAt;
    uint32 notifyRowTotal = 0;
    uint32 buysNotNotified = 0;
    uint32 packetOrdinal = 0;
    uint32 buysGranted = 0;
    uint32 buysUnannounced = 0;
    uint32 buysMisannounced = 0;
    uint32 supersededPackets = 0;
    std::map<uint32, uint32> supersededFor;
    std::set<uint32> clientSpells;
    std::map<uint32, uint32> clientSpellbookCopies;
    std::map<uint32, bool> clientNotable;
    std::map<uint32, uint32> loudSupersedes;
    std::map<uint32, bool> clientSpellHidden;
    std::map<uint32, std::array<std::string, 2>> clientSpellRows;
    std::map<uint32, uint32> chatLines;
    std::map<uint32, bool> clientQuiet;
    std::map<uint32, bool> clientNoPlace;
    std::map<uint32, std::vector<uint32>> entryRows;
    std::set<uint32> indexedEntries;
    uint32 clientEntryMaximum = 0;
    std::map<uint32, uint32> placingLearns;
    std::map<uint32, uint32> clientSpellRank;
    std::map<uint32, uint32> placingSupersedes;
    std::map<uint32, uint32> buttonKeepingRemovals;
    std::vector<std::pair<uint32, uint32>> announcements;
    uint32 lastBuyOrdinal = 0;
    uint32 lastBuyCues = 0;
    std::vector<uint32> lastBuyCueIds;
    uint32 buysSilent = 0;
    uint32 buysMulti = 0;
    uint32 trainerWindows = 0;
    uint32 trainerWindowRows = 0;
    std::map<uint32, uint8> trainerWindowState;
    std::map<uint32, uint32> trainerWindowAbility;
    uint32 vendorWindows = 0;
    uint32 vendorItems = 0;
    std::map<uint32, uint32> vendorPrice;
    std::map<uint32, uint32> vendorExtendedCost;
    uint32 vendorPriceSum = 0;
    uint32 whoResponses = 0;
    uint32 lootReceived = 0;
    std::array<uint32, 2> meleeAttacksByHand{};
    std::array<uint32, 2> meleeDamageByHand{};
    std::array<uint64, 2> meleeDamageTotalByHand{};
    uint64 castPushbackMs = 0;
    std::vector<SpellCastEvent> spellCasts;
    std::vector<SpellDamageEvent> spellDamage;
    std::vector<SpellHealEvent> spellHeals;
    std::vector<SpellEnergizeEvent> spellEnergizes;
    Tree castFailures;
    std::map<uint32, uint8> castFailureReason;
    uint32 bankShows = 0;
    uint32 systemMessages = 0;
    std::vector<std::string> systemMessageTexts;
    std::vector<std::pair<ObjectGuid, std::string>> whispers;
    uint32 notifications = 0;
    std::vector<std::string> notificationTexts;
    uint32 challengeStartResponses = 0;
    uint32 challengeStartLastCode = 0;
    std::map<uint64, std::map<uint16, uint32>> unitValues;
    std::map<uint32, uint32> creatureQueryRank;
    std::map<uint32, uint32> clientCastTimeMs;
    std::map<uint32, uint32> clientAttributes;
    std::map<uint32, uint32> questQueryFlags;
    std::map<uint32, uint32> questQueryFirstChoiceItem;
    std::map<uint32, uint32> questOfferXP;
    uint32 lastQuestWindow = 0;
    uint32 lastStableResult = 0;
    uint32 lfgProposalId = 0;
    std::map<uint16, uint32> extensionPackets;
    std::map<uint16, std::vector<std::string>> extensionPayloads;
    std::map<std::pair<uint16, uint32>, std::string> selectedPacketRows;
    std::map<std::pair<uint16, uint32>, uint32> selectedPacketRowCounts;
    std::string observerError;
    std::unique_ptr<WorldSession> session;
    uint32 accountId = 0;
    ObjectGuid guid;
    ActorStage stage = ActorStage::Account;
    std::vector<std::pair<ActorStage, Clock::time_point>> reached;
    bool generatedName = false;
};

char const* StageName(ActorStage stage)
{
    switch (stage)
    {
        case ActorStage::Account: return "account";
        case ActorStage::Creating: return "creating";
        case ActorStage::Enumerating: return "enumerating";
        case ActorStage::Enumerated: return "enumerated";
        case ActorStage::LoggingIn: return "logging_in";
        case ActorStage::InWorld: return "in_world";
        case ActorStage::Transfer: return "transfer";
        case ActorStage::Ready: return "ready";
    }
    return "unknown";
}

void Reach(Actor& actor, ActorStage stage)
{
    actor.stage = stage;
    actor.reached.emplace_back(stage, Clock::now());
}

struct Target
{
    uint32 map;
    uint32 instance;
    ObjectGuid guid;
};

void ObserveSpellCasts(Actor& actor, WorldPacket const& packet)
{
    if (packet.GetOpcode() != SMSG_SPELL_GO)
        return;
    WorldPacket response(packet);
    ObjectGuid itemOrCaster;
    SpellCastEvent event;
    response >> itemOrCaster.ReadAsPacked() >> event.caster.ReadAsPacked();
    response.read_skip<uint8>();
    response >> event.spell;
    actor.spellCasts.push_back(event);
}

void ObserveSpellDamage(Actor& actor, WorldPacket const& packet)
{
    if (packet.GetOpcode() != SMSG_SPELLNONMELEEDAMAGELOG && packet.GetOpcode() != SMSG_PERIODICAURALOG)
        return;

    WorldPacket response(packet);
    SpellDamageEvent event;
    response >> event.target.ReadAsPacked() >> event.caster.ReadAsPacked() >> event.spell;
    if (packet.GetOpcode() == SMSG_SPELLNONMELEEDAMAGELOG)
    {
        response >> event.damage;
        response.read_skip<uint32>();
        response.read_skip<uint8>();
        response.read_skip<uint32>();
        response.read_skip<uint32>();
        response.read_skip<uint8>();
        response.read_skip<uint8>();
        response.read_skip<uint32>();
        uint32 hitInfo;
        response >> hitInfo;
        event.critical = (hitInfo & SPELL_HIT_TYPE_CRIT) != 0;
    }
    else
    {
        uint32 count, aura;
        response >> count >> aura;
        Require(count == 1, "Expected one native periodic aura event");
        if (aura != SPELL_AURA_PERIODIC_DAMAGE && aura != SPELL_AURA_PERIODIC_DAMAGE_PERCENT)
            return;
        response >> event.damage;
        response.read_skip<uint32>();
        response.read_skip<uint32>();
        response.read_skip<uint32>();
        response.read_skip<uint32>();
        uint8 critical;
        response >> critical;
        event.critical = critical != 0;
    }
    if (event.damage)
        actor.spellDamage.push_back(event);
}

void ObserveSpellHealing(Actor& actor, WorldPacket const& packet)
{
    if (packet.GetOpcode() != SMSG_SPELLHEALLOG && packet.GetOpcode() != SMSG_PERIODICAURALOG)
        return;

    WorldPacket response(packet);
    SpellHealEvent event;
    response >> event.target.ReadAsPacked() >> event.caster.ReadAsPacked() >> event.spell;
    if (packet.GetOpcode() == SMSG_PERIODICAURALOG)
    {
        uint32 count, aura;
        response >> count >> aura;
        Require(count == 1, "Expected one native periodic aura event");
        if (aura != SPELL_AURA_PERIODIC_HEAL && aura != SPELL_AURA_OBS_MOD_HEALTH)
            return;
    }
    response >> event.heal >> event.overheal;
    response.read_skip<uint32>();
    uint8 critical;
    response >> critical;
    event.critical = critical != 0;
    Require(event.overheal <= event.heal, "Native overhealing exceeds healing");
    if (event.heal)
        actor.spellHeals.push_back(event);
}

void ObserveSpellEnergize(Actor& actor, WorldPacket const& packet)
{
    if (packet.GetOpcode() != SMSG_SPELLENERGIZELOG && packet.GetOpcode() != SMSG_PERIODICAURALOG)
        return;
    WorldPacket response(packet);
    SpellEnergizeEvent event;
    response >> event.target.ReadAsPacked() >> event.caster.ReadAsPacked() >> event.spell;
    if (packet.GetOpcode() == SMSG_PERIODICAURALOG)
    {
        uint32 count, aura;
        response >> count >> aura;
        Require(count == 1, "Expected one native periodic aura event");
        if (aura != SPELL_AURA_OBS_MOD_POWER && aura != SPELL_AURA_PERIODIC_ENERGIZE)
            return;
    }
    response >> event.power >> event.amount;
    Require(event.power < MAX_POWERS, "Invalid native energize power");
    actor.spellEnergizes.push_back(event);
}

void ObserveUnitValues(Actor& actor, WorldPacket const& packet)
{
    if (packet.GetOpcode() != SMSG_UPDATE_OBJECT)
        return;
    WorldPacket response(packet);
    uint32 count;
    response >> count;
    for (uint32 block = 0; block < count; ++block)
    {
        uint8 type;
        response >> type;
        if (type == UPDATETYPE_OUT_OF_RANGE_OBJECTS)
        {
            uint32 removed;
            response >> removed;
            for (uint32 index = 0; index < removed; ++index)
            {
                ObjectGuid guid;
                response >> guid.ReadAsPacked();
                actor.unitValues.erase(guid.GetRawValue());
            }
            continue;
        }
        if (type != UPDATETYPE_VALUES)
            return;
        ObjectGuid guid;
        uint8 blocks;
        response >> guid.ReadAsPacked() >> blocks;
        std::vector<uint32> masks(blocks);
        for (uint32& mask : masks)
            response >> mask;
        for (uint16 index = 0; index < uint16(blocks) * 32; ++index)
            if (masks[index / 32] & (1u << (index % 32)))
            {
                uint32 value;
                response >> value;
                actor.unitValues[guid.GetRawValue()][index] = value;
            }
    }
}

void ObserveExtensionPacket(Actor& actor, WorldPacket const& packet)
{
    if (packet.size() >= sizeof(uint32))
    {
        auto selected = actor.selectedPacketRows.find({ packet.GetOpcode(), packet.read<uint32>(0) });
        if (selected != actor.selectedPacketRows.end())
        {
            selected->second.assign(reinterpret_cast<char const*>(packet.contents()), packet.size());
            ++actor.selectedPacketRowCounts[selected->first];
        }
    }
    constexpr uint16 FirstExtensionOpcode = 0x520;
    constexpr std::size_t MaxPayloadsPerOpcode = 256;
    if (packet.GetOpcode() < FirstExtensionOpcode && packet.GetOpcode() != SMSG_MOVE_SET_CAN_FLY &&
        packet.GetOpcode() != SMSG_MOVE_UNSET_CAN_FLY && packet.GetOpcode() != SMSG_CONVERT_RUNE &&
        packet.GetOpcode() != SMSG_ADD_RUNE_POWER && packet.GetOpcode() != SMSG_LEARNED_SPELL &&
        packet.GetOpcode() != SMSG_SUPERCEDED_SPELL && packet.GetOpcode() != SMSG_REMOVED_SPELL &&
        packet.GetOpcode() != SMSG_ITEM_QUERY_SINGLE_RESPONSE && packet.GetOpcode() != SMSG_MOVE_KNOCK_BACK &&
        packet.GetOpcode() != SMSG_DUEL_REQUESTED && packet.GetOpcode() != SMSG_DUEL_COUNTDOWN &&
        packet.GetOpcode() != SMSG_DUEL_COMPLETE && packet.GetOpcode() != SMSG_FRIEND_STATUS)
        return;

    ++actor.extensionPackets[packet.GetOpcode()];
    std::vector<std::string>& payloads = actor.extensionPayloads[packet.GetOpcode()];
    if (payloads.size() < MaxPayloadsPerOpcode)
        payloads.emplace_back(packet.empty() ? std::string()
            : std::string(reinterpret_cast<char const*>(packet.contents()), packet.size()));
}

uint32 NativeAdvancementMaximum()
{
    static uint32 const maximum = []
    {
        uint32 highest = 0;
        ClientDBC table;
        if (table.Load(sWorld->GetDataPath() + "dbc/CharacterAdvancement.dbc", 1))
            for (uint32 index = 0; index < table.GetRecordCount(); ++index)
                highest = std::max(highest, table.GetRecord(index).GetUInt32(0));
        return highest;
    }();
    return maximum;
}

std::unordered_map<uint32, uint32> const& NativeCustomAttributes()
{
    static std::unordered_map<uint32, uint32> const attributes = []
    {
        std::unordered_map<uint32, uint32> fourthDwords;
        ClientDBC table;
        if (table.Load(sWorld->GetDataPath() + "dbc/SpellCustomAttr.dbc", 11))
            for (uint32 index = 0; index < table.GetRecordCount(); ++index)
            {
                ClientDBC::Record const row = table.GetRecord(index);
                fourthDwords[row.GetUInt32(1)] = row.GetUInt32(5);
            }
        return fourthDwords;
    }();
    return attributes;
}

void ObservePacket(Actor& actor, WorldPacket const& packet)
{
    ObserveExtensionPacket(actor, packet);
    if (packet.GetOpcode() == SMSG_STABLE_RESULT && packet.size() == sizeof(uint8))
        actor.lastStableResult = packet.read<uint8>(0);
    constexpr std::size_t LfgProposalIdOffset = sizeof(uint32) + sizeof(uint8);
    if (packet.GetOpcode() == SMSG_LFG_PROPOSAL_UPDATE && packet.size() >= LfgProposalIdOffset + sizeof(uint32))
        actor.lfgProposalId = packet.read<uint32>(LfgProposalIdOffset);
    ObserveSpellCasts(actor, packet);
    ObserveSpellDamage(actor, packet);
    ObserveSpellHealing(actor, packet);
    ObserveSpellEnergize(actor, packet);
    if (packet.GetOpcode() == SMSG_SPELL_DELAYED)
    {
        WorldPacket response(packet);
        ObjectGuid caster;
        uint32 delay;
        response >> caster.ReadAsPacked() >> delay;
        if (caster == actor.guid)
            actor.castPushbackMs += delay;
    }
    if (packet.GetOpcode() == SMSG_CAST_FAILED || packet.GetOpcode() == SMSG_PET_CAST_FAILED)
    {
        WorldPacket response(packet);
        uint8 count, reason;
        uint32 spell;
        response >> count >> spell >> reason;
        Tree failure;
        failure.put("cast_count", uint32(count));
        failure.put("spell", spell);
        failure.put("reason", uint32(reason));
        actor.castFailures.push_back({"", failure});
        actor.castFailureReason[spell] = reason;
    }

    if (packet.GetOpcode() == SMSG_MESSAGECHAT)
    {
        ++actor.systemMessages;
        WorldPacket chat(packet);
        uint8 chatType = 0;
        chat >> chatType;
        if (chatType == CHAT_MSG_SYSTEM || chatType == CHAT_MSG_WHISPER)
        {
            int32 language;
            uint32 flags;
            uint32 length;
            ObjectGuid sender, receiver;
            chat >> language >> sender >> flags >> receiver >> length;
            std::string text;
            if (length > 1)
            {
                text.resize(length - 1);
                chat.read(reinterpret_cast<uint8*>(text.data()), text.size());
            }
            if (chatType == CHAT_MSG_SYSTEM)
                actor.systemMessageTexts.push_back(text);
            else
                actor.whispers.emplace_back(sender, text);
        }
    }
    if (packet.GetOpcode() == SMSG_NOTIFICATION)
    {
        ++actor.notifications;
        WorldPacket notice(packet);
        std::string text;
        notice >> text;
        actor.notificationTexts.push_back(text);
    }
    if (packet.GetOpcode() == SMSG_COA_CHALLENGE_START_RESPONSE)
    {
        ++actor.challengeStartResponses;
        WorldPacket response(packet);
        uint32 challengeId = 0, level = 0, code = 0;
        response >> challengeId >> level >> code;
        actor.challengeStartLastCode = code;
    }
    if (packet.GetOpcode() == SMSG_SHOW_BANK)
        ++actor.bankShows;
    if (packet.GetOpcode() == SMSG_QUEST_QUERY_RESPONSE && packet.size() >= QuestQueryFlagsOffset + sizeof(uint32))
        actor.questQueryFlags[packet.read<uint32>(0)] = packet.read<uint32>(QuestQueryFlagsOffset);
    if (packet.GetOpcode() == SMSG_QUEST_QUERY_RESPONSE
        && packet.size() >= QuestQueryFirstChoiceItemOffset + sizeof(uint32))
        actor.questQueryFirstChoiceItem[packet.read<uint32>(0)] = packet.read<uint32>(QuestQueryFirstChoiceItemOffset);
    if (packet.GetOpcode() == SMSG_CREATURE_QUERY_RESPONSE)
    {
        WorldPacket response(packet);
        uint32 entry = 0;
        response >> entry;
        if (!(entry & 0x80000000))
        {
            std::string name, subName, iconName;
            uint8 unusedName = 0;
            uint32 typeFlags = 0, type = 0, family = 0, rank = 0;
            response >> name >> unusedName >> unusedName >> unusedName >> subName >> iconName;
            response >> typeFlags >> type >> family >> rank;
            actor.creatureQueryRank[entry] = rank;
        }
    }
    ObserveUnitValues(actor, packet);
    if (packet.GetOpcode() == SMSG_ATTACKERSTATEUPDATE)
    {
        WorldPacket response(packet);
        uint32 hitInfo;
        uint32 damage;
        ObjectGuid attacker, victim;
        response >> hitInfo >> attacker.ReadAsPacked() >> victim.ReadAsPacked() >> damage;
        if (attacker == actor.guid)
        {
            uint8 hand = hitInfo & HITINFO_OFFHAND ? OFF_ATTACK : BASE_ATTACK;
            ++actor.meleeAttacksByHand[hand];
            if (damage)
            {
                ++actor.meleeDamageByHand[hand];
                actor.meleeDamageTotalByHand[hand] += damage;
            }
        }
    }

    ++actor.packetOrdinal;

    if (packet.GetOpcode() == CoASpellbook::SMSG_PATCH_SPELL &&
        packet.size() >= (CoASpellbook::SMSG_PATCH_SPELL_CAST_TIME_INDEX_DWORD + 1) * sizeof(uint32))
    {
        uint32 const streamedSpell = packet.read<uint32>(0);
        uint32 const castTimeIndex = packet.read<uint32>(
            CoASpellbook::SMSG_PATCH_SPELL_CAST_TIME_INDEX_DWORD * sizeof(uint32));
        if (SpellCastTimesEntry const* entry = sSpellCastTimesStore.LookupEntry(castTimeIndex))
            actor.clientCastTimeMs[streamedSpell] = entry->CastTime > 0 ? uint32(entry->CastTime) : 0;
        actor.clientAttributes[streamedSpell] = packet.read<uint32>(4 * sizeof(uint32));
    }

    if (packet.GetOpcode() == CoASpellbook::SMSG_PATCH_SPELL_CUSTOM_ATTR)
    {
        WorldPacket row(packet);
        uint32 rowId = 0;
        uint32 marked = 0;
        uint32 firstAttributes = 0;
        uint32 secondAttributes = 0;
        uint32 thirdAttributes = 0;
        uint32 fourthAttributes = 0;
        row >> rowId >> marked >> firstAttributes >> secondAttributes >> thirdAttributes >> fourthAttributes;
        actor.clientNotable[marked] = (thirdAttributes & 0x400) != 0;
        actor.clientQuiet[marked] = (fourthAttributes & 0x40000) != 0;
        actor.clientNoPlace[marked] = (fourthAttributes & 0x1000000) != 0;
        ++actor.notifyRows[marked];
        ++actor.notifyRowTotal;
        actor.notifiedAt.emplace(marked, actor.packetOrdinal);
    }

    constexpr uint16 SmsgPatchSpell = 0x092A;
    constexpr std::size_t SpellAttributesOffset = 4 * sizeof(uint32);
    if (packet.GetOpcode() == SmsgPatchSpell && packet.size() >= SpellAttributesOffset + sizeof(uint32))
    {
        uint32 const spell = packet.read<uint32>(0);
        actor.clientSpellHidden[spell] = (packet.read<uint32>(SpellAttributesOffset) &
            (SPELL_ATTR0_IS_TRADESKILL | SPELL_ATTR0_DO_NOT_DISPLAY)) != 0;
        auto& rows = actor.clientSpellRows[spell];
        rows[0] = std::move(rows[1]);
        rows[1].assign(reinterpret_cast<char const*>(packet.contents()), packet.size());
        constexpr std::size_t SpellRecordBytes = 170 * sizeof(uint32);
        constexpr uint32 RankString = 2;
        std::size_t offset = SpellRecordBytes;
        for (uint32 index = 0; index <= RankString && offset + sizeof(uint32) <= packet.size(); ++index)
        {
            uint32 const length = packet.read<uint32>(offset);
            offset += sizeof(uint32);
            if (index == RankString && offset + length <= packet.size())
            {
                uint32 rank = 0;
                for (std::size_t at = offset; at < offset + length; ++at)
                {
                    char const character = char(packet.contents()[at]);
                    if (character >= '0' && character <= '9')
                        rank = rank * 10 + uint32(character - '0');
                    else if (rank)
                        break;
                }
                actor.clientSpellRank[spell] = rank;
            }
            offset += length;
        }
    }
    constexpr uint16 SmsgPatchCharacterAdvancement = 0x064A;
    constexpr std::size_t AdvancementEntrySpells = 9;
    if (packet.GetOpcode() == SmsgPatchCharacterAdvancement && packet.size() >= sizeof(uint32))
    {
        WorldPacket row(packet);
        uint32 id = 0;
        std::string name;
        row >> id >> name;
        for (uint32 skipped = 0; skipped < 3; ++skipped)
            row.read_skip<uint32>();
        std::vector<uint32> spells(AdvancementEntrySpells);
        for (uint32& spell : spells)
            row >> spell;
        if (!actor.clientEntryMaximum)
            actor.clientEntryMaximum = NativeAdvancementMaximum();
        if (actor.entryRows.emplace(id, spells).second)
        {
            actor.indexedEntries.clear();
            if (id > actor.clientEntryMaximum)
            {
                actor.entryRows.erase(actor.clientEntryMaximum);
                actor.clientEntryMaximum = id;
            }
        }
        else
        {
            actor.entryRows[id] = spells;
            actor.indexedEntries.insert(id);
        }
    }
    auto const flagged = [](std::map<uint32, bool> const& flags, uint32 spell)
    {
        auto const found = flags.find(spell);
        return found != flags.end() && found->second;
    };
    auto const learnFlag = [](std::map<uint32, bool> const& pushed, uint32 spell, uint32 nativeBit)
    {
        if (auto const found = pushed.find(spell); found != pushed.end())
            return found->second;
        auto const native = NativeCustomAttributes().find(spell);
        return native != NativeCustomAttributes().end() && (native->second & nativeBit) != 0;
    };
    auto const isEntry = [&actor](uint32 spell)
    {
        uint32 const first = sSpellMgr->GetFirstSpellInChain(spell);
        for (uint32 id : actor.indexedEntries)
            for (uint32 listed : actor.entryRows.at(id))
                if (listed && (listed == spell || listed == first))
                    return true;
        return false;
    };

    if (packet.GetOpcode() == SMSG_QUESTGIVER_OFFER_REWARD ||
        packet.GetOpcode() == SMSG_QUESTGIVER_REQUEST_ITEMS ||
        packet.GetOpcode() == SMSG_QUESTGIVER_QUEST_DETAILS)
        actor.lastQuestWindow = packet.GetOpcode();

    if (packet.GetOpcode() == SMSG_QUESTGIVER_OFFER_REWARD)
    {
        WorldPacket offer(packet);
        ObjectGuid giver;
        uint32 quest;
        std::string title;
        std::string text;
        uint8 enableNext;
        uint32 flags;
        uint32 suggestedPlayers;
        uint32 emotes;
        offer >> giver >> quest >> title >> text >> enableNext >> flags >> suggestedPlayers >> emotes;
        offer.read_skip(std::size_t(emotes) * 2 * sizeof(uint32));
        uint32 choices;
        offer >> choices;
        offer.read_skip(std::size_t(choices) * 3 * sizeof(uint32));
        uint32 items;
        offer >> items;
        offer.read_skip(std::size_t(items) * 3 * sizeof(uint32));
        uint32 money;
        uint32 xp;
        offer >> money >> xp;
        actor.questOfferXP[quest] = xp;
    }

    if (packet.GetOpcode() == SMSG_INITIAL_SPELLS)
    {
        WorldPacket list(packet);
        uint8 talentSpec = 0;
        uint16 count = 0;
        list >> talentSpec >> count;
        actor.clientSpells.clear();
        actor.clientSpellbookCopies.clear();
        for (uint16 index = 0; index < count; ++index)
        {
            uint32 spell = 0;
            uint16 slot = 0;
            list >> spell >> slot;
            actor.clientSpells.insert(spell);
            ++actor.clientSpellbookCopies[spell];
        }
    }

    if (packet.GetOpcode() == SMSG_REMOVED_SPELL && packet.size() >= sizeof(uint32))
    {
        uint32 const removed = packet.read<uint32>(0);
        actor.clientSpells.erase(removed);
        actor.clientSpellbookCopies.erase(removed);
        if (!flagged(actor.clientSpellHidden, removed))
            ++actor.chatLines[removed];
        if (packet.size() > sizeof(uint32) && packet.read<uint8>(sizeof(uint32)) == 0)
            ++actor.buttonKeepingRemovals[removed];
    }

    if (packet.GetOpcode() == SMSG_SEND_UNLEARN_SPELLS)
    {
        WorldPacket list(packet);
        uint32 count = 0;
        list >> count;
        for (uint32 index = 0; index < count; ++index)
        {
            uint32 spell = 0;
            list >> spell;
            actor.clientSpells.erase(spell);
            actor.clientSpellbookCopies.erase(spell);
        }
    }

    if (packet.GetOpcode() == SMSG_SUPERCEDED_SPELL)
    {
        ++actor.supersededPackets;
        WorldPacket swap(packet);
        uint32 previous = 0;
        uint32 replacement = 0;
        swap >> previous >> replacement;
        ++actor.supersededFor[replacement];
        actor.clientSpells.erase(previous);
        actor.clientSpellbookCopies.erase(previous);
        actor.clientSpells.insert(replacement);
        ++actor.clientSpellbookCopies[replacement];
        auto const notable = actor.clientNotable.find(replacement);
        if (notable == actor.clientNotable.end() || notable->second)
            ++actor.loudSupersedes[replacement];
        if (!isEntry(previous) && !isEntry(replacement) && !flagged(actor.clientSpellHidden, replacement))
            ++actor.chatLines[replacement];
        if (auto const rank = actor.clientSpellRank.find(replacement);
            rank == actor.clientSpellRank.end() || rank->second <= 1)
            ++actor.placingSupersedes[replacement];
        actor.announcements.emplace_back(actor.packetOrdinal, replacement);
    }

    if (packet.GetOpcode() == SMSG_LEARNED_SPELL)
    {
        WorldPacket announcement(packet);
        uint32 announced = 0;
        announcement >> announced;
        ++actor.learnedAlerts[announced];
        bool const hidden = flagged(actor.clientSpellHidden, announced);
        if (!learnFlag(actor.clientQuiet, announced, 0x40000) && !isEntry(announced) && !hidden)
            ++actor.chatLines[announced];
        if (!learnFlag(actor.clientNoPlace, announced, 0x1000000) && !hidden)
            ++actor.placingLearns[announced];
        actor.announced.insert(announced);
        actor.clientSpells.insert(announced);
        ++actor.clientSpellbookCopies[announced];
        actor.announcements.emplace_back(actor.packetOrdinal, announced);
    }

    if (packet.GetOpcode() == SMSG_TRAINER_BUY_SUCCEEDED ||
        packet.GetOpcode() == SMSG_TRAINER_BUY_FAILED)
    {
        WorldPacket answer(packet);
        ObjectGuid trainer;
        uint32 bought = 0;
        answer >> trainer >> bought;
        if (packet.GetOpcode() == SMSG_TRAINER_BUY_SUCCEEDED)
        {
            ++actor.buySucceeded[bought];
            ++actor.buysGranted;
            auto const notified = actor.notifiedAt.find(bought);
            if (notified == actor.notifiedAt.end() || notified->second > actor.packetOrdinal)
                ++actor.buysNotNotified;
            if (!actor.announced.count(bought))
                ++actor.buysUnannounced;
            if (actor.learnedAlerts[bought] > 1)
                ++actor.buysMisannounced;
            actor.lastBuyCueIds.clear();
            for (std::pair<uint32, uint32> const& entry : actor.announcements)
                if (entry.first > actor.lastBuyOrdinal)
                    actor.lastBuyCueIds.push_back(entry.second);

            uint32 const sinceBuy = uint32(actor.lastBuyCueIds.size());
            actor.lastBuyCues = sinceBuy;
            if (!sinceBuy)
                ++actor.buysSilent;
            else if (sinceBuy > 1)
                ++actor.buysMulti;
            actor.lastBuyOrdinal = actor.packetOrdinal;
        }
        else
            ++actor.buyFailed[bought];
    }

    if (packet.GetOpcode() == SMSG_TRAINER_LIST)
    {
        WorldPacket window(packet);
        ObjectGuid trainer;
        int32 type = 0;
        int32 rows = 0;
        window >> trainer >> type >> rows;
        ++actor.trainerWindows;
        actor.trainerWindowRows = rows > 0 ? uint32(rows) : 0;
        actor.trainerWindowState.clear();
        actor.trainerWindowAbility.clear();
        for (int32 i = 0; i < rows; ++i)
        {
            int32 rowSpell = 0;
            uint8 state = 0;
            int32 price = 0;
            uint32 pointCost0 = 0;
            uint32 pointCost1 = 0;
            uint8 requiredLevel = 0;
            uint32 skillLine = 0;
            uint32 skillRank = 0;
            uint32 ability1 = 0;
            uint32 ability2 = 0;
            uint32 ability3 = 0;
            window >> rowSpell >> state >> price >> pointCost0 >> pointCost1 >> requiredLevel
                   >> skillLine >> skillRank >> ability1 >> ability2 >> ability3;
            if (rowSpell > 0)
            {
                actor.trainerWindowState[uint32(rowSpell)] = state;
                actor.trainerWindowAbility[uint32(rowSpell)] = ability1;
            }
        }
    }

    if (packet.GetOpcode() == SMSG_LIST_INVENTORY)
    {
        WorldPacket shelves(packet);
        ObjectGuid vendor;
        uint8 rows = 0;
        shelves >> vendor >> rows;
        ++actor.vendorWindows;
        actor.vendorItems = rows;
        actor.vendorPrice.clear();
        actor.vendorExtendedCost.clear();
        actor.vendorPriceSum = 0;
        for (uint8 i = 0; i < rows; ++i)
        {
            uint32 slot = 0;
            uint32 shelfItem = 0;
            uint32 displayId = 0;
            int32 leftInStock = 0;
            uint32 price = 0;
            uint32 durability = 0;
            uint32 buyCount = 0;
            uint32 extendedCost = 0;
            shelves >> slot >> shelfItem >> displayId >> leftInStock >> price
                    >> durability >> buyCount >> extendedCost;
            if (shelfItem != 0)
            {
                actor.vendorPrice[shelfItem] = price;
                actor.vendorExtendedCost[shelfItem] = extendedCost;
                actor.vendorPriceSum += price;
            }
        }
    }

    if (packet.GetOpcode() != SMSG_WHO)
        return;
    WorldPacket response(packet);
    uint32 displayed, matches;
    response >> displayed >> matches;
    Require(displayed <= matches, "Invalid Who response counts");
    actor.whoClasses.clear();
    for (uint32 index = 0; index < displayed; ++index)
    {
        std::string name, guild;
        uint32 level, playerClass, race, zone;
        uint8 gender;
        response >> name >> guild >> level >> playerClass >> race >> gender >> zone;
        actor.whoClasses.emplace(name, playerClass);
    }
    Require(response.rpos() == response.size(), "Unexpected Who response fields");
    ++actor.whoResponses;
}

class GameplayCase
{
public:
    GameplayCase(std::string runId, std::string resultPath, uint32 phase = CoAGameplay::LanePhase(0),
        CoAGameplay::NameAllocator* names = nullptr) : _phase(phase), _runId(std::move(runId)),
        _resultPath(std::move(resultPath)), _names(names), _admitted(Clock::now()) { }

    void PlaceInBatch(std::string const& batchId, uint32 sequence, std::string const& clock, uint32 lane)
    {
        _report.put("schema", 1);
        _report.put("run_id", _runId);
        _report.put("batch_id", batchId);
        _report.put("sequence", sequence);
        _report.put("clock", clock);
        _report.put("lane", lane);
        _report.put("phase_mask", _phase);
        StartGameClock();
        _measured = true;
    }

    void Load(std::string const& scenarioFile)
    {
        boost::property_tree::read_json(scenarioFile, _scenario);
        Require(_scenario.get<uint32>("schema") == 1, "Unsupported scenario schema");
        _timeout = _scenario.get<uint32>("timeout_ms", 90000);
        Require(_timeout > 0 && _timeout <= 600000, "Invalid scenario timeout");
        if (_scenario.get<bool>("creature_scaling", false))
            _creatureScaling.emplace();
        _report.put("schema", 1);
        _report.put("run_id", _runId);
        _report.put("scenario", _scenario.get<std::string>("name"));
        _report.put("server_version", GitRevision::GetFullVersion());
        _report.put("execution", "socketless-session-handlers");
        _report.put("data_dir", sWorld->GetDataPath());
        _steps = _scenario.get_child("steps");
        Require(!_steps.empty() && _steps.size() <= 10000, "Scenario needs 1..10000 steps");
        _nextStep = _steps.begin();

        auto const& players = _scenario.get_child("players");
        Require(!players.empty() && players.size() <= MaximumActors, "Scenario needs 1..8 players");
        uint32 index = 0;
        for (auto const& entry : players)
        {
            std::string id = entry.second.get<std::string>("id");
            Require(!id.empty() && !_actors.count(id), "Duplicate or empty player id");
            auto& actor = _actors[id];
            actor.definition = entry.second;
            for (auto const& step : _steps)
                if (step.second.get<std::string>("actor", "") == id)
                    if (auto row = step.second.get_optional<uint32>("row"))
                        actor.selectedPacketRows.try_emplace(
                            std::pair{ uint16(step.second.get<uint32>("opcode")), *row });
            auto const accountOf = entry.second.get_optional<std::string>("account_of");
            if (accountOf)
            {
                auto const owner = _actors.find(*accountOf);
                Require(owner != _actors.end() && owner->first != id && !owner->second.account.empty(),
                    "account_of must reference an earlier player");
                actor.account = owner->second.account;
            }
            else
                actor.account = "CT" + _runId + std::to_string(index);
            actor.name = FixtureName(entry.second, index++);
            actor.generatedName = _names && !entry.second.get_optional<std::string>("name");
            Require(normalizePlayerName(actor.name), "Invalid fixture character name");
            for (auto const& [otherId, other] : _actors)
                Require(otherId == id || other.name != actor.name, "Duplicate fixture character name");
            if (!accountOf)
            {
                Require(AccountMgr::GetId(actor.account) == 0, "Test account already exists");
                Require(sAccountMgr->CreateAccount(actor.account, _runId) == AOR_OK, "Account creation failed");
            }
            LookUpAccount(id);
        }
    }

    void RestartClock()
    {
        _admitted = Clock::now();
        _admittedGame.reset();
    }

    bool Tick(uint32 diff)
    {
        ++_ticks;
        if (AnyActorInWorld())
            _maxStepMs = std::max(_maxStepMs, diff);
        if (!_admittedGame)
            StartGameClock();
        RaiseObserverErrors();
        try
        {
            bool const completed = Progress();
            RaiseObserverErrors();
            return completed;
        }
        catch (std::exception const&)
        {
            RaiseObserverErrors();
            throw;
        }
    }

    uint32 VisiblePhases() const
    {
        uint32 phases = _phase;
        for (auto const& [id, actor] : _actors)
            if (Player const* player = actor.session ? actor.session->GetPlayer() : nullptr)
                phases |= player->GetPhaseMask();
        return phases;
    }

    StepRequest StepNeed() const
    {
        StepRequest request;
        request.databaseQuiet = DatabaseQuiet();
        if (!_readyAt)
        {
            if (AnyActorInWorld())
                request.activity = LaneActivity::Stepping;
            return request;
        }
        request.activity = LaneActivity::Stepping;
        if (!_stepStarted || _nextStep == _steps.end())
            return request;
        Tree const& step = _nextStep->second;
        bool const waiting = step.get<std::string>("action", "") == "wait";
        uint64 const window = waiting ? step.get<uint32>("ms", 0) : step.get<uint32>("within_ms", 0);
        uint64 const elapsed = GameElapsed(_stepTime);
        request.activity = waiting ? LaneActivity::Waiting : LaneActivity::Polling;
        request.remaining = Milliseconds(Milliseconds::rep(window > elapsed ? window - elapsed : 0));
        return request;
    }

    void Conclude(bool passed, std::string const& message)
    {
        if (!passed)
        {
            LOG_ERROR("coa.gameplay_test", "Scenario failed at step {}: {}", _completed, message);
            Tree actors;
            for (auto const& [id, actor] : _actors)
                if (Player* player = actor.session ? actor.session->GetPlayer() : nullptr)
                {
                    Tree state = DescribeUnit(player);
                    Tree combat;
                    for (auto const& [guid, reference] : player->GetCombatManager().GetPvECombatRefs())
                        combat.push_back({ "", DescribeUnit(reference->GetOther(player)) });
                    for (auto const& [guid, reference] : player->GetCombatManager().GetPvPCombatRefs())
                        combat.push_back({ "", DescribeUnit(reference->GetOther(player)) });
                    state.put_child("combat_targets", combat);
                    Tree controlled;
                    for (Unit* unit : player->m_Controlled)
                        controlled.push_back({ "", DescribeUnit(unit) });
                    state.put_child("controlled_units", controlled);
                    actors.put_child(id, state);
                }
            _report.put_child("failure_actors", actors);
        }
        Tree failures;
        for (auto const& [id, actor] : _actors)
            for (auto const& entry : actor.castFailures)
            {
                Tree failure = entry.second;
                failure.put("actor", id);
                failures.push_back({"", failure});
            }
        if (!failures.empty())
            _report.put_child("cast_failures", failures);
        _report.put("status", passed ? "passed" : "failed");
        _report.put("message", message);
        _report.put("elapsed_ms", TimeoutElapsed());
        _report.put("assertions", _assertions);
        _report.put("completed_steps", _completed);
        _report.put_child("steps", _records);
        if (_measured)
            RecordTiming();
    }

    bool Dismiss(bool leaveGroups)
    {
        std::set<ObjectGuid> units;
        RemoveFixtureDescendants(units);
        for (auto const& [id, target] : _targets)
        {
            if (Map* map = sMapMgr->FindMap(target.map, target.instance))
                if (Creature* creature = map->GetCreature(target.guid))
                    creature->DespawnOrUnsummon();
            units.insert(target.guid);
        }
        bool ungrouped = true;
        for (auto& [id, actor] : _actors)
            if (Player* player = actor.session ? actor.session->GetPlayer() : nullptr)
            {
                if (leaveGroups)
                    ungrouped = LeaveGroups(player) && ungrouped;
                actor.session->LogoutPlayer(false);
            }
        for (auto& [id, actor] : _actors)
        {
            actor.session.reset();
            if (actor.guid.IsEmpty())
                continue;
            NoRegenerationActors.erase(actor.guid);
            units.insert(actor.guid);
        }
        ProcCounter::Forget(units);
        return ungrouped;
    }

    bool Write()
    {
        return WriteCaseResult(_resultPath, _report);
    }

    CaseOutcome Outcome() const
    {
        CaseOutcome outcome{ _resultPath, _report, {} };
        for (auto const& [id, actor] : _actors)
        {
            if (!actor.account.empty())
                outcome.accounts.accounts.push_back(actor.account);
            if (!actor.name.empty())
                outcome.accounts.characters.push_back(actor.name);
            outcome.accounts.namesReusable = outcome.accounts.namesReusable || !actor.generatedName;
        }
        return outcome;
    }

private:
    struct FixtureSummonCollector
    {
        std::vector<Creature*> summons;

        void Visit(std::unordered_map<ObjectGuid, Creature*>& creatures)
        {
            for (auto const& [guid, creature] : creatures)
                if (creature->IsSummon())
                    summons.push_back(creature);
        }

        template<class T>
        void Visit(std::unordered_map<ObjectGuid, T*>&) { }
    };

    void RemoveFixtureDescendants(std::set<ObjectGuid>& units)
    {
        std::map<Map*, std::set<ObjectGuid>> fixtureRoots;
        for (auto const& [id, target] : _targets)
            if (Map* map = sMapMgr->FindMap(target.map, target.instance))
                fixtureRoots[map].insert(target.guid);
        for (auto& [map, parents] : fixtureRoots)
        {
            FixtureSummonCollector collector;
            TypeContainerVisitor<FixtureSummonCollector, MapStoredObjectTypesContainer> visitor(collector);
            visitor.Visit(map->GetObjectsStore());
            std::vector<Creature*> descendants;
            bool added;
            do
            {
                added = false;
                for (Creature* creature : collector.summons)
                    if (parents.count(creature->GetSummonerGUID()) && parents.insert(creature->GetGUID()).second)
                    {
                        descendants.push_back(creature);
                        units.insert(creature->GetGUID());
                        added = true;
                    }
            } while (added);
            for (auto creature = descendants.rbegin(); creature != descendants.rend(); ++creature)
                (*creature)->DespawnOrUnsummon();
        }
    }

    static Tree DescribeUnit(Unit const* unit)
    {
        Tree state;
        state.put("guid", unit->GetGUID().ToString());
        state.put("entry", unit->GetEntry());
        state.put("phase_mask", unit->GetPhaseMask());
        state.put("map", unit->GetMapId());
        state.put("instance", unit->GetInstanceId());
        state.put("x", unit->GetPositionX());
        state.put("y", unit->GetPositionY());
        state.put("z", unit->GetPositionZ());
        state.put("health", unit->GetHealth());
        state.put("combat", unit->IsInCombat());
        state.put("casting", unit->IsNonMeleeSpellCast(false));
        state.put("casting_state", unit->HasUnitState(UNIT_STATE_CASTING));
        state.put("owner", unit->GetOwnerGUID().ToString());
        state.put("victim", unit->GetVictim() ? unit->GetVictim()->GetGUID().ToString() : "");
        state.put("moving", unit->isMoving());
        state.put("spline_remaining_ms", unit->movespline->Finalized() ? 0 :
            std::max(0, unit->movespline->timeElapsed()));
        if (Creature const* creature = unit->ToCreature())
            state.put("summoner", creature->GetSummonerGUID().ToString());
        return state;
    }

    static bool LeaveGroups(Player* player)
    {
        for (uint8 nesting = 0; nesting < 2; ++nesting)
            if (Group* group = player->GetGroup())
                group->Disband();
        return !player->GetGroup() && !player->GetOriginalGroup();
    }

    std::string FixtureName(Tree const& definition, uint32 index)
    {
        char const legacy = char('a' + index);
        if (auto name = definition.get_optional<std::string>("name"))
            return *name;
        if (!_names)
            return "Harness" + std::string(1, legacy);
        return _legacyNames[legacy] = _names->Next();
    }

    std::string CommandText(Tree const& step) const
    {
        std::string const command = step.get<std::string>("command");
        return _legacyNames.empty() ? command : CoAGameplay::SubstituteLegacyNames(command, _legacyNames);
    }

    void LookUpAccount(std::string const& id)
    {
        std::string const query = Acore::StringFormat("SELECT id FROM account WHERE username = '{}'",
            _actors.at(id).account);
        _queries.AddCallback(LoginDatabase.AsyncQuery(query).WithCallback([this, id](QueryResult result)
        {
            if (result)
            {
                _actors.at(id).accountId = result->Fetch()[0].Get<uint32>();
                _actors.at(id).reached.emplace_back(ActorStage::Account, Clock::now());
            }
            else
                LookUpAccount(id);
        }));
    }

    void StartGameClock()
    {
        _admittedGame = GameTime::Now();
        _report.put("realm_local_start", RealmLocalText(GameTime::GetGameTime()));
    }

    void RaiseObserverErrors() const
    {
        for (auto const& [id, actor] : _actors)
            Require(actor.observerError.empty(), actor.observerError);
    }

    void CheckTimeout() const
    {
        Require(TimeoutElapsed() < _timeout, "Scenario timed out during setup or execution");
        Require(Elapsed(_admitted) < RealBackstopFactor * _timeout,
            "Scenario exceeded three times its timeout in real time");
    }

    uint64 TimeoutElapsed() const
    {
        return _readyAt ? _setupRealMs + GameElapsed(*_readyAt) : Elapsed(_admitted);
    }

    void RecordTiming()
    {
        uint64 const real = Elapsed(_admitted);
        _report.put("game_elapsed_ms", _admittedGame ? GameElapsed(*_admittedGame) : 0);
        _report.put("real_elapsed_ms", real);
        _report.put("setup_real_ms", _readyAt ? _setupRealMs : real);
        _report.put("ticks", _ticks);
        _report.put("max_step_ms", _maxStepMs);
        Tree stages;
        for (auto const& [id, actor] : _actors)
        {
            Tree reached;
            for (auto const& [stage, at] : actor.reached)
                reached.put(StageName(stage),
                    std::chrono::duration_cast<std::chrono::milliseconds>(at - _admitted).count());
            stages.put_child(id, reached);
        }
        _report.put_child("setup_stages", stages);
    }

    bool DatabaseQuiet() const
    {
        return _queries.Empty() && std::ranges::none_of(_actors, [](auto const& entry)
        {
            return entry.second.session && entry.second.session->HasPendingAsyncCallbacks();
        });
    }

    bool AnyActorInWorld() const
    {
        return std::ranges::any_of(_actors, [](auto const& entry)
        {
            return entry.second.stage >= ActorStage::InWorld;
        });
    }

    bool AllActorsAt(ActorStage stage) const
    {
        return std::ranges::all_of(_actors, [stage](auto const& entry) { return entry.second.stage == stage; });
    }

    bool Progress()
    {
        CheckTimeout();
        _queries.ProcessReadyCallbacks();
        if (!Prepared())
            return false;
        if (!_targetsCreated)
            CreateTargets();
        if (!TargetsSettled())
            return false;
        if (_nextStep == _steps.end())
        {
            Require(_assertions > 0, "Scenario completed without assertions");
            return true;
        }
        RunStep(_nextStep->second);
        return false;
    }

    bool Prepared()
    {
        for (auto& [id, actor] : _actors)
            PumpActor(id, actor);
        if (_readyAt)
            return true;
        if (AllActorsAt(ActorStage::Enumerated))
            for (auto& [id, actor] : _actors)
                LogIn(actor);
        if (AllActorsAt(ActorStage::InWorld))
            for (auto& [id, actor] : _actors)
                Normalize(id, actor);
        if (!AllActorsAt(ActorStage::Ready))
            return false;
        _readyAt = GameTime::Now();
        _setupRealMs = Elapsed(_admitted);
        return true;
    }

    void PumpActor(std::string const& id, Actor& actor)
    {
        if (actor.stage == ActorStage::Account)
        {
            if (!actor.accountId)
                return;
            OpenSession(actor);
        }

        if (!actor.session->GetPlayer() || !actor.session->GetPlayer()->IsInWorld())
        {
            MapSessionFilter filter(actor.session.get());
            actor.session->Update(0, filter);
        }
        Require(!actor.session->IsKicked(), "Test session was kicked: " + id);
        if (actor.stage == ActorStage::Creating)
        {
            actor.guid = sCharacterCache->GetCharacterGuidByName(actor.name);
            if (!actor.guid)
                return;
            auto* statement = CharacterDatabase.GetPreparedStatement(CHAR_SEL_ENUM);
            statement->SetData(0, PET_SAVE_AS_CURRENT);
            statement->SetData(1, actor.session->GetAccountId());
            Reach(actor, ActorStage::Enumerating);
            _queries.AddCallback(CharacterDatabase.AsyncQuery(statement).WithPreparedCallback(
                [this, id](PreparedQueryResult result)
                {
                    Require(bool(result), "Created character missing from enumeration");
                    auto& current = _actors.at(id);
                    current.session->HandleCharEnum(result);
                    Reach(current, ActorStage::Enumerated);
                }));
        }

        Player* player = actor.session->GetPlayer();
        if (!player)
        {
            Require(actor.stage != ActorStage::Ready, "Test player logged out: " + id);
            return;
        }

        if (actor.stage == ActorStage::LoggingIn)
        {
            if (actor.session->PlayerLoading() || !player->IsInWorld())
                return;
            player->SetPhaseMask(_phase, true);
            Reach(actor, ActorStage::InWorld);
        }
        CompleteTransfer(actor);
    }

    static void OpenSession(Actor& actor)
    {
        uint32 const expansion = actor.definition.get<uint32>("expansion", EXPANSION_WRATH_OF_THE_LICH_KING);
        Require(expansion <= EXPANSION_WRATH_OF_THE_LICH_KING, "Player expansion must be 0..2");
        actor.session = std::make_unique<WorldSession>(actor.accountId, std::string(actor.account), 0, nullptr,
            SEC_PLAYER, uint8(expansion), 0, LOCALE_enUS, 0, false, false, 0,
            actor.definition.get<bool>("bot", false));
        actor.session->SetAscensionCompatEnabled(actor.definition.get<bool>("ascension_client", false));
        actor.session->SetSocketlessPacketObserver([&actor](WorldPacket const& packet)
        {
            try
            {
                ObservePacket(actor, packet);
            }
            catch (std::exception const& error)
            {
                if (actor.observerError.empty())
                    actor.observerError = error.what();
            }
        });
        actor.session->InitializeSession();
        WorldPacket create(CMSG_CHAR_CREATE, 32);
        uint32 race = actor.definition.get<uint32>("race");
        uint32 playerClass = actor.definition.get<uint32>("class");
        Require(race > 0 && race <= 255 && playerClass > 0 && playerClass <= 255,
            "Race/class must fit the character creation packet");
        create << actor.definition.get<std::string>("name", actor.name) << uint8(race) << uint8(playerClass);
        for (uint8 i = 0; i < 7; ++i)
            create << uint8(0);
        actor.session->HandleCharCreateOpcode(create);
        Reach(actor, ActorStage::Creating);
    }

    static void LogIn(Actor& actor)
    {
        WorldPacket login(CMSG_PLAYER_LOGIN, 8);
        login << actor.guid;
        actor.session->HandlePlayerLoginOpcode(login);
        Reach(actor, ActorStage::LoggingIn);
    }

    void Normalize(std::string const& id, Actor& actor)
    {
        Player* player = actor.session->GetPlayer();
        Require(player && player->IsInWorld(), "Test player left the world: " + id);
        uint32 level = actor.definition.get<uint32>("level", 80);
        Require(level > 0 && level <= uint32(sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL)),
            "Invalid player level");
        player->GiveLevel(uint8(level));
        Require(player->GetLevel() == level, "Fixture level change rejected");
        if (auto hitRating = actor.definition.get_optional<int32>("spell_hit_rating"))
            player->ApplyRatingMod(CR_HIT_SPELL, *hitRating, true);
        if (auto critRating = actor.definition.get_optional<int32>("spell_crit_rating"))
            player->ApplyRatingMod(CR_CRIT_SPELL, *critRating, true);
        if (auto critRating = actor.definition.get_optional<int32>("melee_crit_rating"))
            player->ApplyRatingMod(CR_CRIT_MELEE, *critRating, true);
        if (auto critRating = actor.definition.get_optional<int32>("ranged_crit_rating"))
            player->ApplyRatingMod(CR_CRIT_RANGED, *critRating, true);
        if (auto hitRating = actor.definition.get_optional<int32>("ranged_hit_rating"))
            player->ApplyRatingMod(CR_HIT_RANGED, *hitRating, true);
        if (auto hitRating = actor.definition.get_optional<int32>("melee_hit_rating"))
            player->ApplyRatingMod(CR_HIT_MELEE, *hitRating, true);
        if (auto expertise = actor.definition.get_optional<int32>("expertise_rating"))
            player->ApplyRatingMod(CR_EXPERTISE, *expertise, true);
        if (!actor.definition.get<bool>("allow_regeneration", true))
            NoRegenerationActors.insert(player->GetGUID());
        player->SetHealth(player->GetMaxHealth());
        for (uint8 power = 0; power < MAX_POWERS; ++power)
            player->SetPower(Powers(power), player->GetMaxPower(Powers(power)));
        Reach(actor, ActorStage::Transfer);
        if (auto location = _scenario.get_child_optional("location"))
            Require(player->TeleportTo(location->get<uint32>("map"), location->get<float>("x"),
                location->get<float>("y"), location->get<float>("z"), location->get<float>("o", 0),
                location->get<bool>("ignore_access", false) ? TELE_TO_GM_MODE : 0),
                "Fixture teleport failed");
        CompleteTransfer(actor);
    }

    static void CompleteTransfer(Actor& actor)
    {
        Player* player = actor.session->GetPlayer();
        if (player && player->IsBeingTeleportedFar())
            actor.session->HandleMoveWorldportAck();
        player = actor.session->GetPlayer();
        if (player && player->IsInWorld() && player->IsBeingTeleportedNear())
        {
            WorldPacket ack(MSG_MOVE_TELEPORT_ACK, 20);
            ack << player->GetPackGUID() << uint32(0) << uint32(0);
            actor.session->HandleMoveTeleportAck(ack);
        }
        if (actor.stage == ActorStage::Transfer && player && player->IsInWorld()
            && !player->IsBeingTeleported())
            Reach(actor, ActorStage::Ready);
    }

    Player* GetPlayer(std::string const& id)
    {
        auto itr = _actors.find(id);
        Require(itr != _actors.end(), "Unknown player: " + id);
        Player* player = ObjectAccessor::FindPlayer(itr->second.guid);
        Require(player && player->FindMap() && !player->IsBeingTeleported(), "Player unavailable: " + id);
        return player;
    }

    Unit* GetUnit(std::string const& id)
    {
        if (_actors.count(id))
            return GetPlayer(id);
        auto itr = _targets.find(id);
        Require(itr != _targets.end(), "Unknown actor: " + id);
        Map* map = sMapMgr->FindMap(itr->second.map, itr->second.instance);
        Creature* creature = map ? map->GetCreature(itr->second.guid) : nullptr;
        Require(creature != nullptr, "Creature disappeared: " + id);
        return creature;
    }

    static bool IsLivingSummonOf(Player* player, Creature* creature)
    {
        ObjectGuid const owner = player->GetGUID();
        return creature->IsAlive() && (creature->GetOwnerGUID() == owner || creature->GetCreatorGUID() == owner ||
                (creature->ToTempSummon() && creature->ToTempSummon()->GetSummonerGUID() == owner))
            && player->InSamePhase(creature);
    }

    Creature* GetOwnedCreature(Player* player, uint32 entry)
    {
        std::list<Creature*> creatures;
        player->GetCreatureListWithEntryInGrid(creatures, entry, 100.0f);
        for (Creature* creature : creatures)
            if (creature->IsAlive() && creature->GetOwnerGUID() == player->GetGUID()
                && player->InSamePhase(creature))
                return creature;

        return nullptr;
    }

    static AscensionWildcard::Slot WildcardSlot(Player const* player, uint32 slot)
    {
        std::vector<AscensionWildcard::Slot> const slots = AscensionWildcard::Slots(player);
        Require(slot < slots.size() && slots[slot].EntryId, "The actor has no Wildcard entry in that slot");
        return slots[slot];
    }

    static uint32 WildcardSpell(AscensionWildcard::Slot const& slot)
    {
        auto const& entries = AscensionWildcard::LoadedTables().Entries;
        auto const entry = std::find_if(entries.begin(), entries.end(),
            [&slot](AscensionWildcard::Entry const& candidate) { return candidate.EntryId == slot.EntryId; });
        return entry != entries.end() && slot.Rank <= entry->RankSpells.size() ? entry->RankSpells[slot.Rank - 1] : 0;
    }

    static uint32 LowestCollectedCard(Player const* player, uint32 type)
    {
        auto const& tables = AscensionWildcard::LoadedTables();
        std::vector<AscensionWildcard::Slot> const slots = AscensionWildcard::Slots(player);
        AscensionWildcard::CardCollection const collection = AscensionWildcard::Collection(player);
        uint32 lowest = 0;
        uint32 lowestLevel = std::numeric_limits<uint32>::max();
        for (uint32 card : collection.Collected)
        {
            auto const info = tables.Cards.find(card);
            if (info == tables.Cards.end() || info->second.Type != type)
                continue;
            uint32 const entryId = info->second.EntryId;
            auto const entry = std::find_if(tables.Entries.begin(), tables.Entries.end(),
                [entryId](AscensionWildcard::Entry const& candidate) { return candidate.EntryId == entryId; });
            bool const known = std::any_of(slots.begin(), slots.end(),
                [entryId](AscensionWildcard::Slot const& slot) { return slot.EntryId == entryId; });
            if (entry == tables.Entries.end() || known || entry->MinLevel > lowestLevel ||
                (entry->MinLevel == lowestLevel && card > lowest))
                continue;
            lowest = card;
            lowestLevel = entry->MinLevel;
        }
        Require(lowest != 0, "The actor has collected no usable skill card of that type");
        return lowest;
    }

    static std::string BuybackGuid(Player* player, uint32 entry)
    {
        for (uint32 slot = BUYBACK_SLOT_START; slot < BUYBACK_SLOT_END; ++slot)
            if (Item* item = player->GetItemFromBuyBackSlot(slot); item && item->GetEntry() == entry)
                return item->GetGUID().ToString();

        throw std::runtime_error("No bought-back item of entry " + std::to_string(entry));
    }

    double SentQuestLogField(Player const* player, Tree const& step, uint32 firstField) const
    {
        uint16 const slot = player->FindQuestSlot(step.get<uint32>("quest"));
        Require(slot < MAX_QUEST_LOG_SIZE, "The quest is not in the quest log");
        auto const& payloads = _actors.at(step.get<std::string>("actor")).extensionPayloads;
        auto const updates = payloads.find(AscensionQuestLog::UpdateObjectAddonOpcode);
        if (updates == payloads.end())
            return -1;

        for (auto update = updates->second.rbegin(); update != updates->second.rend(); ++update)
        {
            if (update->size() != 16)
                continue;

            ByteBuffer fields;
            fields.append(reinterpret_cast<uint8 const*>(update->data()), update->size());
            if (fields.read<uint64>() == player->GetGUID().GetRawValue() && fields.read<uint32>() == firstField + slot)
                return fields.read<uint32>();
        }
        return -1;
    }

    double ListedInstanceBinds(Tree const& step) const
    {
        auto const& payloads = _actors.at(step.get<std::string>("actor")).extensionPayloads;
        auto const answers = payloads.find(uint16(SMSG_QUERY_INSTANCE_BINDS_RESULT));
        Require(answers != payloads.end() && !answers->second.empty(), "No instance bind answer was received");
        std::string const& answer = answers->second.back();
        std::size_t const end = answer.find('\0');
        Require(end != std::string::npos, "The instance bind answer has no result string");
        if (answer.compare(0, end, "QUERY_INSTANCE_BINDS_OK"))
            return -1;

        ByteBuffer binds;
        binds.append(reinterpret_cast<uint8 const*>(answer.data()) + end + 1, answer.size() - end - 1);
        uint32 const count = binds.read<uint32>();
        Require(binds.size() == sizeof(uint32) + std::size_t(count) * 3 * sizeof(uint32),
            "The instance bind answer does not hold its count of binds");
        auto const map = step.get_optional<uint32>("id");
        uint32 listed = 0;
        for (uint32 index = 0; index < count; ++index)
        {
            binds.read_skip<uint32>();
            uint32 const bindMap = binds.read<uint32>();
            binds.read_skip<uint32>();
            listed += !map || bindMap == *map;
        }
        return listed;
    }

    static uint32 StabledPetNumber(Player* player, uint32 slot)
    {
        PetStable const* stable = player->GetPetStable();
        Require(stable && slot < stable->StabledPets.size() && stable->StabledPets[slot],
            "No stabled pet in stable slot " + std::to_string(slot));
        return stable->StabledPets[slot]->PetNumber;
    }

    WorldObject* GetQuestGiver(Player* player, Tree const& step)
    {
        if (auto const entry = step.get_optional<uint32>("gameobject"))
        {
            std::list<GameObject*> objects;
            player->GetGameObjectListWithEntryInGrid(objects, *entry, 20.0f);
            for (GameObject* object : objects)
                if (object->IsInWorld() && player->InSamePhase(object))
                    return object;

            return nullptr;
        }

        return GetGiver(player, step.get<uint32>("entry"));
    }

    Creature* GetGiver(Player* player, uint32 entry)
    {
        if (Creature* owned = GetOwnedCreature(player, entry))
            return owned;

        std::list<Creature*> creatures;
        player->GetCreatureListWithEntryInGrid(creatures, entry, 30.0f);
        for (Creature* creature : creatures)
            if (creature->IsAlive() && player->InSamePhase(creature))
                return creature;

        return nullptr;
    }

    bool TargetsSettled() const
    {
        return std::ranges::none_of(_targets, [](auto const& entry)
        {
            Target const& target = entry.second;
            Map* map = sMapMgr->FindMap(target.map, target.instance);
            Creature* creature = map ? map->GetCreature(target.guid) : nullptr;
            return creature && creature->IsInEvadeMode();
        });
    }

    void CreateTargets()
    {
        if (auto creatures = _scenario.get_child_optional("creatures"))
        {
            Require(creatures->size() <= MaximumActors, "Too many creatures");
            for (auto const& entry : *creatures)
            {
                Tree const& definition = entry.second;
                std::string id = definition.get<std::string>("id");
                std::string owner = definition.get<std::string>("owner");
                Require(!_actors.count(id) && !_targets.count(id), "Duplicate actor id");
                Player* player = GetPlayer(owner);
                Position position = player->GetPosition();
                position.m_positionX += definition.get<float>("distance", 3);
                TempSummon* creature = player->SummonCreature(definition.get<uint32>("entry"), position);
                Require(creature != nullptr, "Could not summon fixture creature: " + id);
                _targets.emplace(id, Target{ creature->GetMapId(), creature->GetInstanceId(), creature->GetGUID() });
                creature->SetPhaseMask(_phase, true);
                creature->SetReactState(REACT_PASSIVE);
                creature->SetRegeneratingHealth(false);
                creature->SetFaction(definition.get<uint32>("faction", 14));
                creature->SetLevel(uint8(definition.get<uint32>("level", 80)));
                uint32 const health = definition.get<uint32>("health", 100000);
                creature->SetStatFlatModifier(UNIT_MOD_HEALTH, BASE_VALUE, float(health));
                creature->SetMaxHealth(health);
                creature->SetHealth(creature->GetMaxHealth());
                creature->ResetPlayerDamageReq();
                creature->CombatStop(true, true);
                if (CreatureAI* ai = creature->AI(); ai && ai->IsEngaged())
                    ai->EnterEvadeMode();
                uint32 const reaction = definition.get<uint32>("reaction", REACT_PASSIVE);
                Require(reaction <= REACT_AGGRESSIVE, "Fixture reaction outside valid range");
                creature->SetReactState(ReactStates(reaction));
                if (definition.get<bool>("stationary", false))
                {
                    creature->SetUnitFlag(UNIT_FLAG_DISABLE_MOVE);
                    creature->StopMoving();
                    creature->GetMotionMaster()->MoveIdle();
                }
                if (auto bonus = definition.get_optional<float>("spell_hit_bonus"))
                    creature->m_modSpellHitChance = *bonus;
            }
        }
        _targetsCreated = true;
    }

    double Measure(Tree const& step)
    {
        Unit* unit = GetUnit(step.get<std::string>("actor"));
        std::string metric = step.get<std::string>("metric");
        if (metric == "spell_hit_chance")
            return unit->m_modSpellHitChance;
        uint32 spell = step.get<uint32>("spell", 0);
        if (metric == "victim")
            return unit->GetVictim() == GetUnit(step.get<std::string>("target")) ? 1.0 : 0.0;
        if (metric == "player_name")
            return unit->GetName() == step.get<std::string>("name") ? 1.0 : 0.0;
        if (metric == "race")
            return unit->getRace();
        if (metric == "name_lookup")
        {
            std::string name = step.get<std::string>("name");
            return normalizePlayerName(name) && ObjectAccessor::FindPlayerByName(name) == unit &&
                sCharacterCache->GetCharacterGuidByName(name) == unit->GetGUID() ? 1.0 : 0.0;
        }
        if (metric == "health")
            return unit->GetHealth();
        if (metric == "health_pct")
            return unit->GetHealthPct();
        if (metric == "max_health")
            return unit->GetMaxHealth();
        if (metric == "mana_regen" || metric == "mana_regen_interrupted")
        {
            Require(unit->IsPlayer(), "Mana regeneration rate needs a player");
            uint16 field = metric == "mana_regen" ? UNIT_FIELD_POWER_REGEN_FLAT_MODIFIER :
                UNIT_FIELD_POWER_REGEN_INTERRUPTED_FLAT_MODIFIER;
            return unit->GetFloatValue(field + AsUnderlyingType(POWER_MANA));
        }
        if (metric == "sent_mana_regen" || metric == "sent_mana_regen_interrupted")
        {
            Require(unit->IsPlayer(), "Sent mana regeneration rate needs a player");
            Actor& actor = _actors.at(step.get<std::string>("actor"));
            uint16 field = metric == "sent_mana_regen" ? UNIT_FIELD_POWER_REGEN_FLAT_MODIFIER :
                UNIT_FIELD_POWER_REGEN_INTERRUPTED_FLAT_MODIFIER;
            auto itr = actor.unitValues.find(unit->GetGUID().GetRawValue());
            if (itr == actor.unitValues.end() || !itr->second.count(field))
                return -1;
            return std::bit_cast<float>(itr->second.at(field));
        }
        if (metric == "resting")
        {
            Require(unit->IsPlayer(), "Resting state needs a player");
            return unit->ToPlayer()->HasPlayerFlag(PLAYER_FLAGS_RESTING);
        }
        if (metric == "creature_type")
            return unit->GetCreatureType();
        if (metric == "display_id")
            return unit->GetDisplayId();
        if (metric == "mount_display_id")
            return unit->GetMountID();
        if (metric == "unit_scale")
            return double(unit->GetObjectScale());
        if (metric == "combat_reach")
            return double(unit->GetCombatReach());
        if (metric == "power" || metric == "max_power" || metric == "pet_power" || metric == "pet_max_power")
        {
            if (metric == "pet_power" || metric == "pet_max_power")
            {
                Require(unit->IsPlayer(), "Pet power query needs a player");
                unit = unit->ToPlayer()->GetPet();
                Require(unit != nullptr, "Pet power query needs a current pet");
            }
            uint32 power = step.get<uint32>("power", POWER_MANA);
            Require(power < MAX_POWERS, "Invalid power index");
            return metric == "power" || metric == "pet_power" ?
                unit->GetPower(Powers(power)) : unit->GetMaxPower(Powers(power));
        }
        if (metric == "respawn_remaining")
        {
            Creature* creature = unit->ToCreature();
            Require(creature != nullptr, "Respawn metric needs a creature");
            return std::max<time_t>(0, creature->GetRespawnTime() - GameTime::GetGameTime().count());
        }
        if (metric == "alive")
            return unit->IsAlive();
        if (metric == "map_id")
            return unit->GetMapId();
        if (metric == "position_x")
            return unit->GetPositionX();
        if (metric == "position_y")
            return unit->GetPositionY();
        if (metric == "position_z")
            return unit->GetPositionZ();
        if (metric == "combat")
            return unit->IsInCombat();
        if (metric == "channel_object_entry")
        {
            ObjectGuid const channelObject = unit->GetGuidValue(UNIT_FIELD_CHANNEL_OBJECT);
            return channelObject.IsEmpty() || channelObject == unit->GetGUID() ? 0.0 : double(channelObject.GetEntry());
        }
        if (metric == "casting")
            return unit->IsNonMeleeSpellCast(false);
        if (metric == "moving")
            return unit->isMoving();
        if (metric == "spline_remaining_ms")
            return unit->movespline->Finalized() ? 0 : std::max(0, unit->movespline->timeElapsed());
        if (metric == "spline_speed")
            return unit->movespline->Finalized() ? 0.0 : unit->movespline->Velocity();
        if (metric == "water_walk")
            return unit->HasWaterWalkAura();
        if (metric == "in_water")
            return unit->IsInWater();
        if (metric == "terrain_in_water")
            return unit->GetMap()->IsInWater(unit->GetPhaseMask(), unit->GetPositionX(), unit->GetPositionY(),
                unit->GetPositionZ(), unit->GetCollisionHeight());
        if (metric == "ground_height")
            return unit->GetMap()->GetHeight(unit->GetPhaseMask(), unit->GetPositionX(), unit->GetPositionY(),
                MAX_HEIGHT);
        if (metric == "forced_forward")
            return unit->HasUnitFlag2(UNIT_FLAG2_FORCE_MOVEMENT);
        if (metric == "cast_pushback_ms")
        {
            Require(unit->IsPlayer(), "Cast pushback observation needs a player");
            return double(_actors.at(step.get<std::string>("actor")).castPushbackMs);
        }
        if (metric == "distance_2d")
            return unit->GetExactDist2d(GetUnit(step.get<std::string>("target")));
        if (metric == "point_distance_2d")
            return unit->GetExactDist2d(step.get<float>("x"), step.get<float>("y"));
        if (metric == "cast_remaining_ms")
        {
            for (CurrentSpellTypes type : {CURRENT_GENERIC_SPELL, CURRENT_CHANNELED_SPELL})
                if (Spell* current = unit->GetCurrentSpell(type))
                    if (current->GetSpellInfo()->Id == spell && current->getState() != SPELL_STATE_FINISHED)
                        return std::max(0, current->GetCastTimeRemaining());
            return 0;
        }
        if (metric == "xp" || metric == "next_level_xp" || metric == "skill_value" || metric == "skill_maximum")
        {
            Player* player = unit->ToPlayer();
            Require(player != nullptr, "XP/skill metric needs a player");
            if (metric == "skill_value")
                return player->GetPureSkillValue(step.get<uint32>("skill"));
            if (metric == "skill_maximum")
                return player->GetPureMaxSkillValue(step.get<uint32>("skill"));
            return player->GetUInt32Value(metric == "xp" ? PLAYER_XP : PLAYER_NEXT_LEVEL_XP);
        }
        if (metric == "level")
            return unit->GetLevel();
        if (metric == "lfg_dungeon_disabled")
        {
            lfg::LFGDungeonData const* dungeon = sLFGMgr->GetLFGDungeon(step.get<uint32>("dungeon"));
            Require(dungeon != nullptr, "LFG disable metric needs a known dungeon");
            return sLFGMgr->IsDungeonDisabled(dungeon->map, Difficulty(dungeon->difficulty)) ? 1 : 0;
        }
        if (metric == "lfg_state")
        {
            Require(unit->IsPlayer(), "LFG state needs a player");
            return double(sLFGMgr->GetState(unit->GetGUID()));
        }
        if (metric == "view_level")
            return GetUnit(step.get<std::string>("target"))->getLevelForTarget(unit);
        if (metric == "sent_level" || metric == "sent_max_health")
        {
            Actor& actor = _actors.at(step.get<std::string>("actor"));
            uint64 guid = GetUnit(step.get<std::string>("target"))->GetGUID().GetRawValue();
            uint16 field = metric == "sent_level" ? UNIT_FIELD_LEVEL : UNIT_FIELD_MAXHEALTH;
            auto itr = actor.unitValues.find(guid);
            if (itr == actor.unitValues.end() || !itr->second.count(field))
                return 0;
            return itr->second.at(field);
        }
        if (metric == "quest_query_scaled")
        {
            Actor& actor = _actors.at(step.get<std::string>("actor"));
            auto itr = actor.questQueryFlags.find(step.get<uint32>("quest"));
            if (itr == actor.questQueryFlags.end())
                return -1;
            return (itr->second & AscensionQuestLog::ScaledQuestFlag) ? 1 : 0;
        }
        if (metric == "quest_query_reward_choice")
        {
            Actor& actor = _actors.at(step.get<std::string>("actor"));
            auto itr = actor.questQueryFirstChoiceItem.find(step.get<uint32>("quest"));
            return itr == actor.questQueryFirstChoiceItem.end() ? -1 : int64(itr->second);
        }
        if (metric == "creature_query_rank")
        {
            Actor& actor = _actors.at(step.get<std::string>("actor"));
            auto itr = actor.creatureQueryRank.find(step.get<uint32>("entry"));
            return itr == actor.creatureQueryRank.end() ? -1 : int64(itr->second);
        }
        if (metric == "client_cast_time_ms")
        {
            Actor& actor = _actors.at(step.get<std::string>("actor"));
            auto itr = actor.clientCastTimeMs.find(step.get<uint32>("spell"));
            return itr == actor.clientCastTimeMs.end() ? -1 : int64(itr->second);
        }
        if (metric == "client_attributes")
        {
            Actor& actor = _actors.at(step.get<std::string>("actor"));
            auto itr = actor.clientAttributes.find(step.get<uint32>("spell"));
            return itr == actor.clientAttributes.end() ? -1 : int64(itr->second);
        }
        if (metric == "quest_offer_sent_xp")
        {
            Actor const& actor = _actors.at(step.get<std::string>("actor"));
            auto const found = actor.questOfferXP.find(step.get<uint32>("quest"));
            return found == actor.questOfferXP.end() ? -1 : int64(found->second);
        }
        if (metric == "quest_level" || metric == "quest_xp")
        {
            Player* player = unit->ToPlayer();
            Quest const* quest = sObjectMgr->GetQuestTemplate(step.get<uint32>("quest"));
            Require(player && quest, "Quest metric needs a player and an existing quest");
            return metric == "quest_level" ? player->GetQuestLevel(quest) : player->CalculateQuestRewardXP(quest);
        }
        if (metric == "stat")
        {
            uint32 stat = step.get<uint32>("stat");
            Require(stat < MAX_STATS, "Invalid stat index");
            return unit->GetStat(Stats(stat));
        }
        if (metric == "attack_power" || metric == "ranged_attack_power")
            return unit->GetTotalAttackPowerValue(metric == "attack_power" ? BASE_ATTACK : RANGED_ATTACK);
        if (metric == "armor")
            return unit->GetArmor();
        if (metric == "weapon_damage_min")
        {
            uint32 hand = step.get<uint32>("hand", BASE_ATTACK);
            Require(hand < MAX_ATTACK, "Invalid weapon damage hand");
            uint16 field = hand == BASE_ATTACK ? UNIT_FIELD_MINDAMAGE :
                (hand == OFF_ATTACK ? UNIT_FIELD_MINOFFHANDDAMAGE : UNIT_FIELD_MINRANGEDDAMAGE);
            return unit->GetFloatValue(field);
        }
        if (metric == "resistance")
        {
            uint32 school = step.get<uint32>("school");
            Require(school > SPELL_SCHOOL_NORMAL && school < MAX_SPELL_SCHOOL, "Invalid resistance school");
            return unit->GetResistance(SpellSchools(school));
        }
        if (metric == "attack_time_ms" || metric == "pet_attack_time_ms")
        {
            if (metric == "pet_attack_time_ms")
            {
                Require(unit->IsPlayer(), "Pet attack time needs a player");
                unit = unit->ToPlayer()->GetPet();
                Require(unit != nullptr, "Pet attack time needs a current pet");
            }
            uint32 hand = step.get<uint32>("hand", BASE_ATTACK);
            Require(hand < MAX_ATTACK, "Invalid attack hand");
            return unit->GetFloatValue(static_cast<uint16>(UNIT_FIELD_BASEATTACKTIME) + hand);
        }
        if (metric == "run_speed_rate")
            return unit->GetSpeedRate(MOVE_RUN);
        if (metric == "spell_hit_bonus_taken")
        {
            SpellInfo const* info = sSpellMgr->GetSpellInfo(spell);
            Require(info != nullptr, "Incoming hit modifier needs a known spell");
            return unit->GetTotalAuraModifierByMiscMask(SPELL_AURA_MOD_ATTACKER_SPELL_HIT_CHANCE,
                info->GetSchoolMask());
        }
        if (metric == "rooted")
            return unit->HasUnitState(UNIT_STATE_ROOT);
        if (metric == "stunned")
            return unit->HasUnitState(UNIT_STATE_STUNNED);
        if (metric == "stealth_detection")
            return unit->m_stealthDetect.GetValue(STEALTH_GENERAL);
        if (metric == "can_detect")
            return unit->CanSeeOrDetect(GetUnit(step.get<std::string>("target")));
        if (metric == "spell_healing_taken")
        {
            SpellInfo const* info = sSpellMgr->GetSpellInfo(spell);
            Require(info != nullptr, "Incoming healing needs a known spell");
            return unit->SpellHealingBonusTaken(GetUnit(step.get<std::string>("target")), info, 1000,
                step.get<bool>("periodic", false) ? DOT : HEAL);
        }
        if (metric == "spell_go_count")
        {
            Require(unit->IsPlayer(), "Cast packets need a player observer");
            auto const entry = step.get_optional<uint32>("entry");
            Require(!entry || !step.get<bool>("pet", false), "Cast query selects either a pet or a creature entry");
            ObjectGuid caster;
            if (!entry)
            {
                Unit* source = step.get<bool>("pet", false) ? static_cast<Unit*>(unit->ToPlayer()->GetPet()) : unit;
                Require(source != nullptr, "Cast query needs a present pet");
                caster = source->GetGUID();
            }
            uint32 count = 0;
            for (SpellCastEvent const& event : _actors.at(step.get<std::string>("actor")).spellCasts)
                if (event.spell == spell && (entry ? event.caster.IsCreature() && event.caster.GetEntry() == *entry
                                                   : event.caster == caster))
                    ++count;
            return count;
        }
        if (metric == "distance")
            return unit->GetExactDist2d(GetUnit(step.get<std::string>("target")));
        if (metric == "spell_cast_count")
        {
            Require(sSpellMgr->GetSpellInfo(spell) != nullptr, "Unknown spell in metric");
            return ProcCounter::CastCount(unit->GetGUID(), spell);
        }
        if (metric == "spell_proc_count")
        {
            Require(sSpellMgr->GetSpellInfo(spell) != nullptr, "Unknown spell in metric");
            return ProcCounter::Count(unit->GetGUID(), spell);
        }
        if (metric == "owned_creature_spell_proc_count")
        {
            Creature* creature = GetOwnedCreature(unit->ToPlayer(), step.get<uint32>("entry"));
            Require(creature != nullptr, "Proc observation needs a present owned creature");
            Require(sSpellMgr->GetSpellInfo(spell) != nullptr, "Unknown owned creature proc spell");
            return ProcCounter::Count(creature->GetGUID(), spell);
        }
        if (metric == "combo_points")
            return unit->ToPlayer()->GetComboPoints();
        if (metric == "game_mode_mask")
            return sScriptMgr->OnPlayerGetGameModeMask(unit->ToPlayer()).value_or(0);
        if (metric == "spell_proc_chance")
        {
            SpellProcEntry const* entry = sSpellMgr->GetSpellProcEntry(spell);
            Require(entry != nullptr, "Spell has no proc entry");
            return entry->Chance;
        }
        if (metric == "aura_proc_rate")
        {
            Aura* aura = unit->GetAura(spell);
            Require(aura != nullptr, "aura_proc_rate needs the aura on the actor");
            AuraApplication* application = aura->GetApplicationOfTarget(unit->GetGUID());
            Unit* other = GetUnit(step.get<std::string>("target"));
            bool const incoming = step.get<bool>("incoming", false);
            Unit* actor = incoming ? other : unit;
            Unit* victim = incoming ? unit : other;
            uint32 const triggerSpell = step.get<uint32>("trigger_spell", 0);
            SpellInfo const* trigger = triggerSpell ? sSpellMgr->GetSpellInfo(triggerSpell) : nullptr;
            Require(!triggerSpell || trigger != nullptr, "Unknown trigger_spell");
            uint32 const typeMask = step.get<uint32>("type_mask");
            uint32 const trials = step.get<uint32>("trials", 40000);
            Require(trials != 0, "aura_proc_rate needs trials");
            bool const heal = step.get<bool>("heal", false);
            SpellSchoolMask const school = trigger ? trigger->GetSchoolMask() : SPELL_SCHOOL_MASK_NORMAL;
            DamageEffectType const damageType = (typeMask & PERIODIC_PROC_FLAG_MASK) ? DOT
                : trigger ? SPELL_DIRECT_DAMAGE : DIRECT_DAMAGE;
            DamageInfo damage(actor, victim, 1000, trigger, school, damageType);
            HealInfo healing(actor, victim, 1000, trigger, school);
            healing.SetEffectiveHeal(1000);
            ProcEventInfo event(actor, victim, victim, typeMask,
                step.get<uint32>("spell_type_mask", heal ? PROC_SPELL_TYPE_HEAL : PROC_SPELL_TYPE_DAMAGE),
                step.get<uint32>("phase_mask", PROC_SPELL_PHASE_HIT), step.get<uint32>("hit_mask", PROC_HIT_NORMAL),
                nullptr, heal ? nullptr : &damage, heal ? &healing : nullptr);
            TimePoint const now = GameTime::SteadyNow();
            uint32 procs = 0;
            for (uint32 trial = 0; trial < trials; ++trial)
                procs += aura->GetProcEffectMask(application, event, now) != 0;
            return 100.0 * procs / trials;
        }
        if (metric == "spell_damage_taken" || metric == "melee_damage_taken")
        {
            Unit* attacker = GetUnit(step.get<std::string>("target"));
            SpellInfo const* info = spell ? sSpellMgr->GetSpellInfo(spell) : nullptr;
            Require(!spell || info != nullptr, "Unknown spell for incoming damage calculation");
            if (metric == "melee_damage_taken")
                return unit->MeleeDamageBonusTaken(attacker, 1000, BASE_ATTACK, info,
                    info ? info->GetSchoolMask() : SPELL_SCHOOL_MASK_NORMAL);
            Require(info != nullptr, "Incoming spell damage needs a spell");
            return unit->SpellDamageBonusTaken(attacker, info, 1000, SPELL_DIRECT_DAMAGE);
        }
        if (metric.rfind("aura", 0) == 0)
        {
            Require(metric == "aura" || metric == "aura_stacks" || metric == "aura_charges"
                || metric == "aura_duration_ms" || metric == "aura_amount" || metric == "aura_positive"
                || metric == "aura_visible"
                || metric == "aura_amplitude_ms" || metric == "aura_crit_chance" || metric == "aura_script_value",
                "Unknown aura metric");
            Require(sSpellMgr->GetSpellInfo(spell) != nullptr, "Unknown aura spell");
            ObjectGuid caster;
            if (auto id = step.get_optional<std::string>("caster"))
                caster = GetUnit(*id)->GetGUID();
            Aura* aura = unit->GetAura(spell, caster);
            if (metric == "aura")
                return aura != nullptr;
            if (!aura)
                return 0;
            if (metric == "aura_positive" || metric == "aura_visible")
            {
                AuraApplication const* application = aura->GetApplicationOfTarget(unit->GetGUID());
                return application && (metric == "aura_visible" ? application->GetSlot() < MAX_AURAS
                    : application->IsPositive());
            }
            if (metric == "aura_stacks")
                return aura->GetStackAmount();
            if (metric == "aura_charges")
                return aura->GetCharges();
            if (metric == "aura_duration_ms")
                return aura->GetDuration();
            if (metric == "aura_script_value")
                return double(aura->GetScriptValue(step.get<uint32>("key")));
            uint32 effect = step.get<uint32>("effect", 0);
            Require(effect < MAX_SPELL_EFFECTS && aura->GetEffect(effect), "Aura effect does not exist");
            if (metric == "aura_amplitude_ms")
                return aura->GetEffect(effect)->GetAmplitude();
            if (metric == "aura_crit_chance")
                return aura->GetEffect(effect)->GetCritChance();
            return aura->GetEffect(effect)->GetAmount();
        }
        Player* player = unit->ToPlayer();
        Require(player != nullptr, "Metric requires a player: " + metric);
        if (metric == "knows_spell" || metric == "cooldown_ms" || metric == "spell_charges" ||
            metric == "spell_active" || metric == "global_cooldown_ms" || metric == "has_talent" ||
            metric == "spellbook_offers_spell" || metric == "spellbook_covers_spell" ||
            metric == "trainer_window_state" || metric == "trainer_window_ability" ||
            metric == "temporary_spell_replacement" || metric == "client_knows_spell" ||
            metric == "client_spellbook_copies")
            Require(sSpellMgr->GetSpellInfo(spell) != nullptr, "Unknown spell in metric");
        if (metric == "knows_spell")
            return player->HasSpell(spell);
        if (metric == "client_knows_spell")
            return _actors.at(step.get<std::string>("actor")).clientSpells.count(spell) ? 1.0 : 0.0;
        if (metric == "client_spellbook_copies")
        {
            auto const& copies = _actors.at(step.get<std::string>("actor")).clientSpellbookCopies;
            auto const found = copies.find(spell);
            return found == copies.end() ? 0.0 : double(found->second);
        }
        if (metric == "spell_active")
        {
            auto known = player->GetSpellMap().find(spell);
            return known != player->GetSpellMap().end() && known->second->State != PLAYERSPELL_REMOVED
                && known->second->Active;
        }
        if (metric == "action_button" || metric == "action_button_packed")
        {
            uint8 button = uint8(step.get<uint32>("button"));
            ActionButton const* action = player->GetActionButton(button);
            if (metric == "action_button_packed")
                return action ? action->packedData : 0;
            return action && action->GetType() == ACTION_BUTTON_SPELL ? action->GetAction() : 0;
        }
        if (metric == "persisted_action_button")
        {
            ActionButton const* action = player->GetActionButton(uint8(step.get<uint32>("button")));
            return action && action->GetType() == ACTION_BUTTON_SPELL ?
                player->GetSavedActionButtonSpell(action->GetAction()) : 0;
        }
        if (metric == "action_bar_unknown_spells")
        {
            uint32 unknown = 0;
            for (uint8 button = 0; button < MAX_ACTION_BUTTONS; ++button)
                if (ActionButton const* action = player->GetActionButton(button);
                    action && action->GetType() == ACTION_BUTTON_SPELL && !player->HasSpell(action->GetAction()))
                    ++unknown;
            return unknown;
        }
        if (metric == "temporary_spell_replacement")
            return player->GetTemporarySpellReplacement(spell);
        if (metric == "spellbook_rows" || metric == "spellbook_offers_spell" || metric == "spellbook_covers_spell")
            Require(CoASpellbook::Available(), "Spellbook metrics require mod-spellbook");
        if (metric == "spellbook_rows")
            return CoASpellbook::RowCount(player);
        if (metric == "spellbook_offers_spell")
            return CoASpellbook::OffersSpell(player, spell);
        if (metric == "spellbook_covers_spell")
            return CoASpellbook::CoversSpell(player, spell);
        if (metric == "spellbook_buys_granted" || metric == "spellbook_unannounced_buys" ||
            metric == "spellbook_misannounced_buys" || metric == "spellbook_notify_rows" ||
            metric == "spellbook_unnotified_buys" || metric == "spellbook_notified_spells")
        {
            Actor const& actor = _actors.at(step.get<std::string>("actor"));
            if (metric == "spellbook_buys_granted")
                return double(actor.buysGranted);
            if (metric == "spellbook_notify_rows")
                return double(actor.notifyRowTotal);
            if (metric == "spellbook_notified_spells")
                return double(actor.notifyRows.size());
            if (metric == "spellbook_unnotified_buys")
                return double(actor.buysNotNotified);
            return double(metric == "spellbook_unannounced_buys" ? actor.buysUnannounced
                                                                : actor.buysMisannounced);
        }
        if (metric == "spellbook_buy_succeeded" || metric == "spellbook_buy_failed")
        {
            auto const& counts = metric == "spellbook_buy_succeeded"
                ? _actors.at(step.get<std::string>("actor")).buySucceeded
                : _actors.at(step.get<std::string>("actor")).buyFailed;
            auto const found = counts.find(spell);
            return found == counts.end() ? 0.0 : double(found->second);
        }
        if (metric == "spellbook_learned_alerts")
        {
            auto const& alerts = _actors.at(step.get<std::string>("actor")).learnedAlerts;
            auto const found = alerts.find(spell);
            return found == alerts.end() ? 0.0 : double(found->second);
        }
        if (metric == "spellbook_superseded_packets")
            return double(_actors.at(step.get<std::string>("actor")).supersededPackets);
        if (metric == "spellbook_silent_buys" || metric == "spellbook_multi_announced_buys")
        {
            Actor const& actor = _actors.at(step.get<std::string>("actor"));
            return double(metric == "spellbook_silent_buys" ? actor.buysSilent : actor.buysMulti);
        }
        if (metric == "spellbook_superseded_for")
        {
            auto const& swaps = _actors.at(step.get<std::string>("actor")).supersededFor;
            auto const found = swaps.find(spell);
            return found == swaps.end() ? 0.0 : double(found->second);
        }
        if (metric == "spellbook_loud_supersedes_for")
        {
            auto const& loud = _actors.at(step.get<std::string>("actor")).loudSupersedes;
            auto const found = loud.find(spell);
            return found == loud.end() ? 0.0 : double(found->second);
        }
        if (metric == "client_chat_lines_for")
        {
            auto const& lines = _actors.at(step.get<std::string>("actor")).chatLines;
            auto const found = lines.find(spell);
            return found == lines.end() ? 0.0 : double(found->second);
        }
        if (metric == "client_placing_supersedes_for")
        {
            auto const& placing = _actors.at(step.get<std::string>("actor")).placingSupersedes;
            auto const found = placing.find(spell);
            return found == placing.end() ? 0.0 : double(found->second);
        }
        if (metric == "client_spell_rank_for")
        {
            auto const& ranks = _actors.at(step.get<std::string>("actor")).clientSpellRank;
            auto const found = ranks.find(spell);
            return found == ranks.end() ? -1.0 : double(found->second);
        }
        if (metric == "client_placing_learns_for")
        {
            auto const& placing = _actors.at(step.get<std::string>("actor")).placingLearns;
            auto const found = placing.find(spell);
            return found == placing.end() ? 0.0 : double(found->second);
        }
        if (metric == "client_removals_keeping_buttons_for")
        {
            auto const& kept = _actors.at(step.get<std::string>("actor")).buttonKeepingRemovals;
            auto const found = kept.find(spell);
            return found == kept.end() ? 0.0 : double(found->second);
        }
        if (metric == "client_spell_row_restored")
        {
            auto const& rows = _actors.at(step.get<std::string>("actor")).clientSpellRows;
            auto const found = rows.find(spell);
            if (found == rows.end() || found->second[0].size() != found->second[1].size() ||
                found->second[0].size() < 5 * sizeof(uint32))
                return 0.0;
            std::string hidden = found->second[0];
            std::string const& restored = found->second[1];
            constexpr std::size_t AttributesOffset = 4 * sizeof(uint32);
            uint32 attributes = 0;
            std::memcpy(&attributes, hidden.data() + AttributesOffset, sizeof(attributes));
            if (!(attributes & SPELL_ATTR0_DO_NOT_DISPLAY))
                return 0.0;
            attributes &= ~uint32(SPELL_ATTR0_DO_NOT_DISPLAY);
            std::memcpy(hidden.data() + AttributesOffset, &attributes, sizeof(attributes));
            return hidden == restored ? 1.0 : 0.0;
        }
        if (metric == "spellbook_client_notable")
        {
            auto const& notable = _actors.at(step.get<std::string>("actor")).clientNotable;
            auto const found = notable.find(spell);
            return found == notable.end() ? -1.0 : double(found->second);
        }
        if (metric == "spellbook_cues_in_last_buy")
            return double(_actors.at(step.get<std::string>("actor")).lastBuyCues);
        if (metric == "spellbook_last_buy_cued")
        {
            auto const& cued = _actors.at(step.get<std::string>("actor")).lastBuyCueIds;
            return std::find(cued.begin(), cued.end(), spell) == cued.end() ? 0.0 : 1.0;
        }
        if (metric == "trainer_list_packets")
            return double(_actors.at(step.get<std::string>("actor")).trainerWindows);
        if (metric == "trainer_window_rows")
            return double(_actors.at(step.get<std::string>("actor")).trainerWindowRows);
        if (metric == "trainer_window_state")
        {
            auto const& window = _actors.at(step.get<std::string>("actor")).trainerWindowState;
            auto const found = window.find(spell);
            return found == window.end() ? -1.0 : double(found->second);
        }
        if (metric == "trainer_window_ability")
        {
            auto const& window = _actors.at(step.get<std::string>("actor")).trainerWindowAbility;
            auto const found = window.find(spell);
            return found == window.end() ? -1.0 : double(found->second);
        }
        if (metric == "vendor_list_packets")
            return double(_actors.at(step.get<std::string>("actor")).vendorWindows);
        if (metric == "vendor_items")
            return double(_actors.at(step.get<std::string>("actor")).vendorItems);
        if (metric == "vendor_price_sum")
            return double(_actors.at(step.get<std::string>("actor")).vendorPriceSum);
        if (metric == "vendor_price")
        {
            auto const& prices = _actors.at(step.get<std::string>("actor")).vendorPrice;
            auto const found = prices.find(step.get<uint32>("item", 0));
            return found == prices.end() ? -1.0 : double(found->second);
        }
        if (metric == "vendor_extended_cost")
        {
            auto const& costs = _actors.at(step.get<std::string>("actor")).vendorExtendedCost;
            auto const found = costs.find(step.get<uint32>("item", 0));
            return found == costs.end() ? -1.0 : double(found->second);
        }
        if (metric == "quest_rewarded")
        {
            uint32 quest = step.get<uint32>("quest");
            Require(sObjectMgr->GetQuestTemplate(quest) != nullptr, "Unknown quest template");
            return player->IsQuestRewarded(quest);
        }
        if (metric == "gossip_options")
            return player->PlayerTalkClass->GetGossipMenu().GetMenuItemCount();
        if (metric == "gossip_option_text")
        {
            GossipMenuItemContainer const& options = player->PlayerTalkClass->GetGossipMenu().GetMenuItems();
            uint32 const index = step.get<uint32>("index");
            if (index >= options.size())
                return 0;
            return std::next(options.begin(), index)->second.Message == step.get<std::string>("text");
        }
        if (metric == "loot_received")
            return _actors.at(step.get<std::string>("actor")).lootReceived;
        if (metric == "nearby_gameobject_count" || metric == "nearby_gameobject_quest_active")
        {
            bool const questActiveOnly = metric == "nearby_gameobject_quest_active";
            std::list<GameObject*> objects;
            player->GetGameObjectListWithEntryInGrid(objects, step.get<uint32>("entry"), 20.0f);
            objects.remove_if([player, questActiveOnly](GameObject* object)
            {
                return !object->IsInWorld() || !player->InSamePhase(object) ||
                    (questActiveOnly && !object->ActivateToQuest(player));
            });
            return objects.size();
        }
        if (metric == "nearby_gameobject_state")
        {
            GameObject* object = player->FindNearestGameObject(step.get<uint32>("entry"), 20.0f);
            return object ? uint32(object->GetGoState()) : 99;
        }
        if (metric == "loot_bloodforged")
        {
            Loot* window = nullptr;
            ObjectGuid const lootGuid = player->GetLootGUID();
            if (lootGuid.IsCreature())
                if (Creature* creature = player->GetMap()->GetCreature(lootGuid))
                    window = &creature->loot;
            if (!window)
                return 0;
            uint32 count = 0;
            for (LootItem const& item : window->items)
                if (ItemTemplate const* itemTemplate = sObjectMgr->GetItemTemplate(item.itemid))
                    if (!item.is_looted && itemTemplate->Name1.rfind("Bloodforged", 0) == 0)
                        ++count;
            return count;
        }
        if (metric == "equipped_gear_loot_rate")
        {
            uint32 const entry = step.get<uint32>("entry");
            uint32 const wanted = step.get<uint32>("item", 0);
            Creature creature;
            Require(creature.Create(player->GetMap()->GenerateLowGuid<HighGuid::Unit>(), player->GetMap(),
                player->GetPhaseMask(), entry, 0, player->GetPositionX(), player->GetPositionY(),
                player->GetPositionZ(), player->GetOrientation()), "Cannot create equipped gear loot fixture");
            Require(!creature.IsSummon(), "Equipped gear loot fixture must be an ordinary creature");
            std::set<uint32> displays;
            for (uint32 slot = 0; slot < MAX_EQUIPMENT_ITEMS; ++slot)
                if (ItemTemplate const* weapon = sObjectMgr->GetItemTemplate(creature.GetVirtualItemId(slot)))
                    displays.insert(weapon->DisplayInfoID);
            if (CreatureDisplayPreset const* preset = sAscensionPresets->GetPreset(entry, creature.GetDisplayId()))
                displays.insert(preset->items.begin(), preset->items.end());
            else if (CreatureDisplayInfoEntry const* model = sCreatureDisplayInfoStore.LookupEntry(
                creature.GetDisplayId()))
                if (CreatureDisplayInfoExtraEntry const* extra = sCreatureDisplayInfoExtraStore.LookupEntry(
                    model->ExtendedDisplayInfoID))
                    displays.insert(std::begin(extra->NPCItemDisplay), std::end(extra->NPCItemDisplay));

            uint32 hits = 0;
            constexpr uint32 rolls = 5000;
            for (uint32 roll = 0; roll < rolls; ++roll)
            {
                Loot loot;
                loot.FillLoot(0, LootTemplates_Creature, player, false, true, LOOT_MODE_DEFAULT, &creature);
                Require(loot.items.size() <= 1, "Equipped gear loot exceeded its per-kill budget");
                for (LootItem const& item : loot.items)
                {
                    ItemTemplate const* gear = sObjectMgr->GetItemTemplate(item.itemid);
                    Require(gear && gear->DisplayInfoID && displays.contains(gear->DisplayInfoID),
                        "Equipped gear loot does not match a visible item");
                    Require(gear->RequiredLevel <= creature.GetLevel() && gear->Quality <= ITEM_QUALITY_UNCOMMON,
                        "Equipped gear loot exceeded its level or quality limit");
                    Require(gear->Bonding == NO_BIND || gear->Bonding == BIND_WHEN_EQUIPPED,
                        "Equipped gear loot used a restricted reward");
                    Require(loot.unlootedCount == 1, "Equipped gear loot did not grant native loot ownership");
                    hits += !wanted || item.itemid == wanted;
                }
            }
            return 100.0 * hits / rolls;
        }
        if (metric == "creature_loot_quality_rate")
        {
            uint32 const lootId = step.get<uint32>("entry");
            uint32 const quality = step.get<uint32>("quality", ITEM_QUALITY_RARE);
            uint32 const rolls = step.get<uint32>("rolls", 10000);
            Require(LootTemplates_Creature.HaveLootFor(lootId), "Unknown creature loot template");
            Require(rolls != 0, "creature_loot_quality_rate needs rolls");
            uint32 hits = 0;
            for (uint32 roll = 0; roll < rolls; ++roll)
            {
                Loot loot;
                loot.FillLoot(lootId, LootTemplates_Creature, player, true, true);
                hits += std::any_of(loot.items.begin(), loot.items.end(), [quality](LootItem const& item)
                {
                    ItemTemplate const* itemTemplate = sObjectMgr->GetItemTemplate(item.itemid);
                    return itemTemplate && itemTemplate->Quality >= quality;
                });
            }
            return 100.0 * hits / rolls;
        }
        if (metric == "map_id")
            return player->GetMapId();
        if (metric == "map_difficulty")
            return player->GetMap()->GetSpawnMode();
        if (metric == "nearby_creature_max_health")
        {
            Creature* creature = player->FindNearestCreature(step.get<uint32>("entry"), 60.0f, true);
            Require(creature != nullptr, "Creature health metric needs a living nearby creature");
            return creature->GetMaxHealth();
        }
        if (metric == "nearby_creature_template")
        {
            std::list<Creature*> creatures;
            player->GetCreatureListWithEntryInGrid(creatures, step.get<uint32>("entry"), 60.0f);
            Require(creatures.size() == 1, "Creature template metric needs exactly one nearby creature");
            return creatures.front()->GetCreatureTemplate()->Entry;
        }
        if (metric == "nearby_creature_count")
        {
            std::list<Creature*> creatures;
            player->GetCreatureListWithEntryInGrid(creatures, step.get<uint32>("entry"), 60.0f);
            return std::count_if(creatures.begin(), creatures.end(),
                [](Creature* creature) { return creature->IsInWorld() && creature->IsAlive(); });
        }
        if (metric == "carried_money")
            return player->GetMoney();
        if (metric == "loot_count" || metric == "loot_entry" || metric == "loot_gold" ||
            metric == "loot_required_level" || metric == "loot_item_level" || metric == "loot_base_entry" ||
            metric == "loot_item_armor" || metric == "loot_gear_item_level")
        {
            Loot* window = nullptr;
            ObjectGuid const lootGuid = player->GetLootGUID();
            if (lootGuid.IsItem())
            {
                if (Item* container = player->GetItemByGuid(lootGuid))
                    window = &container->loot;
            }
            else if (lootGuid.IsGameObject())
            {
                if (GameObject* object = player->GetMap()->GetGameObject(lootGuid))
                    window = &object->loot;
            }
            else if (lootGuid.IsCreature())
            {
                if (Creature* creature = player->GetMap()->GetCreature(lootGuid))
                    window = &creature->loot;
            }
            if (!window)
                return 0;
            if (metric == "loot_gold")
                return window->gold;
            uint32 count = 0;
            auto const wanted = step.get_optional<uint32>("item");
            for (LootItem const& item : window->items)
                if (!item.is_looted
                    && (!wanted || item.itemid == *wanted || ItemScaling::BaseEntry(item.itemid) == *wanted))
                {
                    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(item.itemid);
                    if (!proto || (step.get_optional<uint32>("quality") &&
                        proto->Quality != step.get<uint32>("quality")))
                        continue;
                    if (metric == "loot_gear_item_level")
                    {
                        if (proto->Class == ITEM_CLASS_WEAPON || proto->Class == ITEM_CLASS_ARMOR)
                            return proto->ItemLevel;
                        continue;
                    }
                    if (metric == "loot_entry")
                        return item.itemid;
                    if (metric == "loot_base_entry")
                        return ItemScaling::BaseEntry(item.itemid);
                    if (metric == "loot_required_level")
                        return proto->RequiredLevel;
                    if (metric == "loot_item_level")
                        return proto->ItemLevel;
                    if (metric == "loot_item_armor")
                        return proto->Armor;
                    ++count;
                }
            return count;
        }
        if (metric == "who_count" || metric == "who_class")
        {
            Actor const& actor = _actors.at(step.get<std::string>("actor"));
            Require(actor.whoResponses != 0, "No native Who response received");
            if (metric == "who_count")
                return actor.whoClasses.size();
            auto found = actor.whoClasses.find(_actors.at(step.get<std::string>("target")).name);
            return found == actor.whoClasses.end() ? 0 : found->second;
        }
        if (metric == "cast_speed_multiplier")
            return player->GetFloatValue(UNIT_MOD_CAST_SPEED);
        if (metric == "spell_crit_chance")
        {
            uint32 school = step.get<uint32>("school", SPELL_SCHOOL_SHADOW);
            Require(school < MAX_SPELL_SCHOOL, "Invalid spell school");
            return player->GetFloatValue(PLAYER_SPELL_CRIT_PERCENTAGE1 + school);
        }
        if (metric == "melee_crit_chance")
            return player->GetFloatValue(PLAYER_CRIT_PERCENTAGE);
        if (metric == "ranged_taken_crit_chance")
            return player->GetUnitCriticalChance(RANGED_ATTACK, GetUnit(step.get<std::string>("target")));
        if (metric == "dodge_chance")
            return player->GetFloatValue(PLAYER_DODGE_PERCENTAGE);
        if (metric == "parry_chance")
            return player->GetFloatValue(PLAYER_PARRY_PERCENTAGE);
        if (metric == "block_chance")
            return player->GetFloatValue(PLAYER_BLOCK_PERCENTAGE);
        if (metric == "block_value")
            return player->GetShieldBlockValue();
        if (metric == "critical_block_chance")
            return player->GetTotalAuraModifier(SPELL_AURA_MOD_BLOCK_CRIT_CHANCE);
        if (metric == "melee_attack_count" || metric == "melee_damage_count" ||
            metric == "melee_damage_total")
        {
            Actor const& actor = _actors.at(step.get<std::string>("actor"));
            if (metric == "melee_damage_total")
            {
                if (auto hand = step.get_optional<uint32>("hand"))
                {
                    Require(*hand < 2, "Melee hand must be main hand or off hand");
                    return double(actor.meleeDamageTotalByHand[*hand]);
                }
                return double(actor.meleeDamageTotalByHand[BASE_ATTACK] + actor.meleeDamageTotalByHand[OFF_ATTACK]);
            }
            auto const& counts = metric == "melee_attack_count" ? actor.meleeAttacksByHand : actor.meleeDamageByHand;
            if (auto hand = step.get_optional<uint32>("hand"))
            {
                Require(*hand < 2, "Melee hand must be main hand or off hand");
                return counts[*hand];
            }
            return counts[BASE_ATTACK] + counts[OFF_ATTACK];
        }
        if (metric == "spell_damage_count" || metric == "spell_damage_total")
        {
            ObjectGuid caster = step.get<bool>("pet", false) ? player->GetPetGUID() : player->GetGUID();
            if (auto entry = step.get_optional<uint32>("entry"))
            {
                Require(!step.get<bool>("pet", false), "Spell damage query selects a pet or a creature entry");
                Creature* creature = GetOwnedCreature(player, *entry);
                Require(creature != nullptr, "Spell damage observation needs a present owned creature");
                caster = creature->GetGUID();
            }
            ObjectGuid target;
            if (auto id = step.get_optional<std::string>("target"))
                target = GetUnit(*id)->GetGUID();
            auto critical = step.get_optional<bool>("critical");
            uint64 value = 0;
            for (SpellDamageEvent const& event : _actors.at(step.get<std::string>("actor")).spellDamage)
                if (caster && event.caster == caster && event.spell == spell &&
                    (!target || event.target == target) && (!critical || event.critical == *critical))
                    value += metric == "spell_damage_count" ? 1 : event.damage;
            return double(value);
        }
        if (metric == "spell_heal_count" || metric == "spell_heal_total" || metric == "spell_effective_heal_total")
        {
            ObjectGuid caster = step.get<bool>("pet", false) ? player->GetPetGUID() : player->GetGUID();
            ObjectGuid target;
            if (auto id = step.get_optional<std::string>("target"))
            {
                Unit* victim = GetUnit(*id);
                if (step.get<bool>("target_pet", false))
                {
                    Player* owner = victim->ToPlayer();
                    Require(owner && owner->GetPet(), "Healing target needs a current pet");
                    victim = owner->GetPet();
                }
                target = victim->GetGUID();
            }
            auto critical = step.get_optional<bool>("critical");
            uint64 value = 0;
            for (SpellHealEvent const& event : _actors.at(step.get<std::string>("actor")).spellHeals)
                if (caster && event.caster == caster && event.spell == spell &&
                    (!target || event.target == target) && (!critical || event.critical == *critical))
                    value += metric == "spell_heal_count" ? 1 :
                        event.heal - (metric == "spell_effective_heal_total" ? event.overheal : 0);
            return double(value);
        }
        if (metric == "spell_energize_count" || metric == "spell_energize_total")
        {
            ObjectGuid caster = step.get<bool>("pet", false) ? player->GetPetGUID() : player->GetGUID();
            ObjectGuid target;
            if (auto id = step.get_optional<std::string>("target"))
            {
                Unit* victim = GetUnit(*id);
                if (step.get<bool>("target_pet", false))
                {
                    Player* owner = victim->ToPlayer();
                    Require(owner && owner->GetPet(), "Energize target needs a current pet");
                    victim = owner->GetPet();
                }
                target = victim->GetGUID();
            }
            auto power = step.get_optional<uint32>("power");
            uint64 value = 0;
            for (SpellEnergizeEvent const& event : _actors.at(step.get<std::string>("actor")).spellEnergizes)
                if (caster && event.caster == caster && event.spell == spell &&
                    (!target || event.target == target) && (!power || event.power == *power))
                    value += metric == "spell_energize_count" ? 1 : event.amount;
            return double(value);
        }
        if (metric == "aoe_damage_taken")
        {
            uint32 school = step.get<uint32>("school");
            Require(school < MAX_SPELL_SCHOOL, "Invalid area damage school");
            return player->CalculateAOEDamageReduction(1000, 1u << school, false);
        }
        if (metric == "reputation_gain")
        {
            uint32 faction = step.get<uint32>("id");
            Require(sFactionStore.LookupEntry(faction) != nullptr, "Unknown reputation faction");
            return player->CalculateReputationGain(REPUTATION_SOURCE_SPELL, player->GetLevel(), 1000, int32(faction));
        }
        if (metric == "spell_immune" || metric == "spell_effect_immune")
        {
            SpellInfo const* info = sSpellMgr->GetSpellInfo(spell);
            Require(info != nullptr, "Unknown immunity probe spell");
            Unit* caster = GetUnit(step.get<std::string>("target"));
            if (metric == "spell_immune")
                return player->IsImmunedToSpell(info, caster);
            uint32 effect = step.get<uint32>("effect", EFFECT_0);
            Require(effect < MAX_SPELL_EFFECTS && info->Effects[effect].IsEffect(), "Invalid immunity probe effect");
            return player->IsImmunedToSpellEffect(info, effect, caster);
        }
        if (metric == "expertise")
            return player->GetUInt32Value(PLAYER_EXPERTISE);
        if (metric == "spell_uses_armor")
        {
            SpellInfo const* info = sSpellMgr->GetSpellInfo(spell);
            Require(info != nullptr, "Unknown spell in armor eligibility probe");
            uint32 effect = step.get<uint32>("effect", EFFECT_0);
            Require(effect < MAX_SPELL_EFFECTS && info->Effects[effect].IsEffect(), "Invalid armor probe effect");
            return Unit::IsDamageReducedByArmor(info->GetSchoolMask(), info, uint8(effect));
        }
        if (metric == "melee_hit_chance")
            return player->m_modMeleeHitChance;

        if (metric == "spell_power")
        {
            uint32 school = step.get<uint32>("school");
            Require(school > SPELL_SCHOOL_NORMAL && school < MAX_SPELL_SCHOOL, "Invalid spell power school");
            return player->SpellBaseDamageBonusDone(SpellSchoolMask(1 << school));
        }
        if (metric == "combat_rating")
        {
            uint32 rating = step.get<uint32>("rating");
            Require(rating < MAX_COMBAT_RATING, "Invalid combat rating");
            return player->GetUInt32Value(static_cast<uint16>(PLAYER_FIELD_COMBAT_RATING_1) + rating);
        }
        if (metric.rfind("script_", 0) == 0)
        {
            Unit* attacker = GetUnit(step.get<std::string>("target"));
            SpellInfo const* info = sSpellMgr->GetSpellInfo(spell);
            if (metric == "script_melee_damage_taken")
            {
                uint32 damage = 1000;
                sScriptMgr->ModifyMeleeDamage(player, attacker, damage);
                return damage;
            }
            Require(info != nullptr, "Unknown spell for scripted damage taken");
            if (metric == "script_spell_damage_taken")
            {
                int32 damage = 1000;
                sScriptMgr->ModifySpellDamageTaken(player, attacker, damage, info);
                return damage;
            }
            if (metric == "script_heal_received")
            {
                uint32 heal = 1000;
                sScriptMgr->ModifyHealReceived(player, attacker, heal, info);
                return heal;
            }
            Require(metric == "script_periodic_damage_taken", "Unknown scripted damage metric");
            uint32 damage = 1000;
            sScriptMgr->ModifyPeriodicDamageAurasTick(player, attacker, damage, info);
            return damage;
        }
        if (metric == "spell_done_crit_chance" || metric == "spell_taken_crit_chance" ||
            metric == "spell_done_crit_chance_scripted" ||
            metric == "melee_spell_damage_done" || metric == "spell_critical_damage" ||
            metric == "armor_reduced_damage")
        {
            Unit* target = GetUnit(step.get<std::string>("target"));
            SpellInfo const* info = sSpellMgr->GetSpellInfo(spell);
            Require(info != nullptr, "Unknown spell in metric");
            if (metric == "spell_done_crit_chance")
                return player->SpellDoneCritChance(target, info, info->GetSchoolMask(), BASE_ATTACK, false);
            if (metric == "spell_taken_crit_chance")
            {
                float chance = player->SpellDoneCritChance(target, info, info->GetSchoolMask(), BASE_ATTACK, false);
                return target->SpellTakenCritChance(player, info, info->GetSchoolMask(), chance, BASE_ATTACK, false);
            }
            if (metric == "spell_done_crit_chance_scripted")
            {
                float chance = player->SpellDoneCritChance(target, info, info->GetSchoolMask(), BASE_ATTACK, false);
                Spell* probe = new Spell(player, info, TRIGGERED_NONE);
                sScriptMgr->OnSpellCritChance(probe, target, chance);
                delete probe;
                return chance;
            }
            if (metric == "spell_critical_damage")
                return Unit::SpellCriticalDamageBonus(player, info, 1000, target);
            if (metric == "armor_reduced_damage")
            {
                Unit* attacker = step.get<bool>("pet", false) ? static_cast<Unit*>(player->GetPet()) : player;
                Require(attacker != nullptr, "Armor probe needs a current pet");
                return Unit::CalcArmorReducedDamage(attacker, target, 1000, info);
            }
            return player->MeleeDamageBonusDone(target, 1000, BASE_ATTACK, info, info->GetSchoolMask());
        }
        if (metric == "spell_modifier" || metric == "spell_cast_time_ms" || metric == "spell_max_range"
            || metric == "spell_max_stacks" || metric == "spell_healing_done" || metric == "spell_effect_value"
            || metric == "spell_family_flags")
        {
            SpellInfo const* info = sSpellMgr->GetSpellInfo(spell);
            Require(info != nullptr, "Unknown spell in metric");
            if (metric == "spell_family_flags")
            {
                uint32 const index = step.get<uint32>("index", 0);
                Require(index < 3, "Invalid spell family flag word");
                return info->SpellFamilyFlags[index];
            }
            if (metric == "spell_modifier")
            {
                uint32 op = step.get<uint32>("op");
                Require(op < MAX_SPELLMOD, "Invalid spell modifier operation");
                float value = step.get<float>("base");
                player->ApplySpellMod(spell, SpellModOp(op), value);
                return value;
            }
            if (metric == "spell_effect_value")
            {
                uint32 effect = step.get<uint32>("effect", EFFECT_0);
                Require(effect < MAX_SPELL_EFFECTS && info->Effects[effect].IsEffect(), "Spell effect does not exist");
                Unit* caster = step.get<bool>("pet", false) ? static_cast<Unit*>(player->GetPet()) : player;
                Require(caster != nullptr, "Spell effect query needs a present pet");
                auto const removeModifier = [player](SpellModifier* modifier)
                {
                    player->AddSpellMod(modifier, false);
                };
                std::unique_ptr<SpellModifier, decltype(removeModifier)> modifier(nullptr, removeModifier);
                if (auto flat = step.get_optional<int32>("flat_coefficient_modifier"))
                {
                    Require(caster == player, "Coefficient modifier fixture requires the player caster");
                    Require(info->SpellFamilyFlags != flag96(), "Coefficient modifier fixture needs a spell mask");
                    modifier.reset(new SpellModifier());
                    modifier->op = SPELLMOD_BONUS_MULTIPLIER;
                    modifier->type = SPELLMOD_FLAT;
                    modifier->value = *flat;
                    modifier->mask = info->SpellFamilyFlags;
                    modifier->spellId = spell;
                    modifier->targetSpellId = spell;
                    player->AddSpellMod(modifier.get(), true);
                }
                return info->Effects[effect].CalcValue(caster);
            }
            if (metric == "spell_cast_time_ms")
                return info->CalcCastTime(player);
            if (metric == "spell_max_range")
                return info->GetMaxRange(info->IsPositive(), player);
            if (metric == "spell_max_stacks")
                return info->CalcMaxAuraStacks(player);
            if (metric == "spell_healing_done")
                return player->SpellHealingBonusDone(GetUnit(step.get<std::string>("target")), info, 1000,
                    step.get<bool>("periodic", false) ? DOT : HEAL,
                    uint8(step.get<uint32>("effect", EFFECT_0)));
        }
        if (metric == "spell_damage_done" || metric == "melee_damage_done")
        {
            Unit* target = GetUnit(step.get<std::string>("target"));
            if (metric == "melee_damage_done")
                return player->MeleeDamageBonusDone(target, 1000, BASE_ATTACK, nullptr);

            SpellInfo const* info = sSpellMgr->GetSpellInfo(spell);
            Require(info != nullptr, "Unknown spell for damage calculation");
            Unit* caster = step.get<bool>("pet", false) ? static_cast<Unit*>(player->GetPet()) : player;
            Require(caster != nullptr, "Spell damage query needs a present pet");
            return caster->SpellDamageBonusDone(target, info, step.get<uint32>("base", 1000),
                step.get<bool>("periodic", false) ? DOT : SPELL_DIRECT_DAMAGE,
                uint8(step.get<uint32>("effect", EFFECT_0)));
        }
        if (metric == "spell_power_cost")
        {
            SpellInfo const* info = sSpellMgr->GetSpellInfo(spell);
            Require(info != nullptr, "Unknown spell for power cost");
            return info->CalcPowerCost(player, info->GetSchoolMask());
        }
        if (metric == "has_talent")
        {
            Require(GetTalentSpellPos(spell) != nullptr, "Metric needs a talent rank's spell ID");
            return player->HasTalent(spell, player->GetActiveSpec());
        }
        if (metric == "talent_points")
            return player->GetFreeTalentPoints();
        if (metric == "bank_bag_slots")
            return player->GetBankBagSlotCount();
        if (metric == "taxi_node")
            return player->m_taxi.IsTaximaskNodeKnown(step.get<uint32>("entry"));
        if (metric == "in_flight")
            return player->IsInFlight();
        if (metric == "stabled_pet_count")
        {
            PetStable const* stable = player->GetPetStable();
            return stable ? std::count_if(stable->StabledPets.begin(), stable->StabledPets.end(),
                [](Optional<PetStable::PetInfo> const& pet) { return pet.has_value(); }) : 0;
        }
        if (metric == "instance_binds_listed")
            return ListedInstanceBinds(step);
        if (metric == "stable_result")
            return _actors.at(step.get<std::string>("actor")).lastStableResult;
        if (metric == "pet_rows")
        {
            auto const slot = step.get_optional<uint32>("slot");
            QueryResult const result = slot
                ? CharacterDatabase.Query("SELECT COUNT(*) FROM character_pet WHERE owner = {} AND slot = {}",
                    player->GetGUID().GetCounter(), *slot)
                : CharacterDatabase.Query("SELECT COUNT(*) FROM character_pet WHERE owner = {}",
                    player->GetGUID().GetCounter());
            return result ? result->Fetch()[0].Get<uint64>() : 0;
        }
        if (metric == "taxi_destination")
            return player->m_taxi.empty() ? 0 : player->m_taxi.GetPath().back();
        if (metric == "private_instance")
            return player->GetMap()->IsScriptedPrivateInstance();
        if (metric == "controls_self")
            return player->m_mover == player;
        if (metric == "viewpoint_entry" || metric == "seer_entry")
        {
            WorldObject* object = metric == "viewpoint_entry" ? player->GetViewpoint() : player->GetSeer();
            return object ? object->GetEntry() : 0;
        }
        if (metric == "at_homebind")
            return player->GetMapId() == player->m_homebindMapId &&
                player->GetExactDist(player->m_homebindX, player->m_homebindY, player->m_homebindZ) <= 5.0f;
        if (metric == "owned_gameobject_count" || metric == "gameobject_remaining_ms" ||
            metric == "gameobject_display" || metric == "gameobject_scale")
        {
            std::list<GameObject*> objects = OwnedGameObjects(player, step.get<uint32>("entry"));
            if (metric == "owned_gameobject_count")
                return objects.size();
            if (objects.empty())
                return 0;
            Require(objects.size() == 1, "Gameobject metric needs exactly one owned object");
            if (metric == "gameobject_display")
                return objects.front()->GetDisplayId();
            if (metric == "gameobject_scale")
                return objects.front()->GetObjectScale();
            time_t expiry = objects.front()->GetRespawnTime();
            return expiry ? std::max<time_t>(0, expiry - GameTime::GetGameTime().count()) * IN_MILLISECONDS : -1;
        }
        if (metric == "dynamic_object" || metric == "dynamic_object_duration_ms")
        {
            Require(sSpellMgr->GetSpellInfo(spell) != nullptr, "Unknown ground-effect spell");
            DynamicObject* object = player->GetDynObject(spell);
            if (metric == "dynamic_object")
                return object && object->IsInWorld();
            return object ? object->GetDuration() : 0;
        }
        if (metric == "charm_entry" || metric == "charm_aura_stacks")
        {
            Unit* charm = player->GetCharm();
            if (metric == "charm_entry")
                return charm ? charm->GetEntry() : 0;
            Require(sSpellMgr->GetSpellInfo(spell) != nullptr, "Unknown charm aura spell");
            ObjectGuid caster;
            if (auto id = step.get_optional<std::string>("caster"))
                caster = GetUnit(*id)->GetGUID();
            Aura* aura = charm ? charm->GetAura(spell, caster) : nullptr;
            return aura ? aura->GetStackAmount() : 0;
        }
        if (metric == "owned_creature_count")
        {
            uint32 entry = step.get<uint32>("entry");
            Require(!spell || sSpellMgr->GetSpellInfo(spell) != nullptr, "Unknown owned creature aura spell");
            ObjectGuid caster;
            if (auto id = step.get_optional<std::string>("caster"))
                caster = GetUnit(*id)->GetGUID();
            std::list<Creature*> creatures;
            player->GetCreatureListWithEntryInGrid(creatures, entry, 100.0f);
            float const minDistance = step.get<float>("min_distance", 0.0f);
            bool const ownerDisplay = step.get<bool>("owner_display", false);
            auto const rangedWeaponSubclass = step.get_optional<uint32>("ranged_weapon_subclass");
            Require(!rangedWeaponSubclass || *rangedWeaponSubclass < MAX_ITEM_SUBCLASS_WEAPON,
                "Invalid ranged weapon subclass");
            return std::count_if(creatures.begin(), creatures.end(),
                [player, spell, caster, minDistance, ownerDisplay, rangedWeaponSubclass](Creature* creature)
            {
                if (rangedWeaponSubclass)
                {
                    ItemTemplate const* weapon = sObjectMgr->GetItemTemplate(
                        creature->GetUInt32Value(UNIT_VIRTUAL_ITEM_SLOT_ID + 2));
                    if (!weapon || weapon->Class != ITEM_CLASS_WEAPON || weapon->SubClass != *rangedWeaponSubclass)
                        return false;
                }
                return IsLivingSummonOf(player, creature) && (!spell || creature->GetAura(spell, caster))
                    && player->GetExactDist2d(creature) >= minDistance
                    && (!ownerDisplay || creature->GetDisplayId() == player->GetDisplayId());
            });
        }
        if (metric == "owned_creature_spacing")
        {
            uint32 entry = step.get<uint32>("entry");
            Require(sObjectMgr->GetCreatureTemplate(entry) != nullptr, "Unknown creature entry in metric");
            std::list<Creature*> creatures;
            player->GetCreatureListWithEntryInGrid(creatures, entry, 100.0f);
            creatures.remove_if([player](Creature* creature) { return !IsLivingSummonOf(player, creature); });
            if (creatures.size() < 2)
                return 0.0;
            float spacing = std::numeric_limits<float>::max();
            for (auto first = creatures.begin(); first != creatures.end(); ++first)
                for (auto second = std::next(first); second != creatures.end(); ++second)
                    spacing = std::min(spacing, (*first)->GetExactDist2d(*second));
            return spacing;
        }
        if (metric == "owned_creature_scale" || metric == "owned_creature_visible" ||
            metric == "owned_creature_display")
        {
            uint32 entry = step.get<uint32>("entry");
            Require(sObjectMgr->GetCreatureTemplate(entry) != nullptr, "Unknown creature entry in metric");
            if (Creature* creature = GetOwnedCreature(player, entry))
            {
                if (metric == "owned_creature_display")
                    return creature->GetDisplayId();
                return metric == "owned_creature_visible" ? double(creature->IsVisible()) :
                    double(creature->GetObjectScale());
            }
            return 0.0;
        }
        if (metric == "owned_creature_spell_hit_chance")
        {
            Creature* creature = GetOwnedCreature(player, step.get<uint32>("entry"));
            Require(creature != nullptr, "Spell hit observation needs a present owned creature");
            return creature->m_modSpellHitChance;
        }
        if (metric == "owned_creature_attackable")
        {
            Creature* creature = GetOwnedCreature(player, step.get<uint32>("entry"));
            Require(creature != nullptr, "Attack observation needs a present owned creature");
            return GetUnit(step.get<std::string>("target"))->IsValidAttackTarget(creature);
        }
        if (metric == "owned_creature_victim")
        {
            Creature* creature = GetOwnedCreature(player, step.get<uint32>("entry"));
            Require(creature != nullptr, "Victim observation needs a present owned creature");
            return creature->GetVictim() == GetUnit(step.get<std::string>("target"));
        }
        if (metric == "owned_creature_weapon_damage_min")
        {
            uint32 entry = step.get<uint32>("entry");
            Require(sObjectMgr->GetCreatureTemplate(entry) != nullptr, "Unknown creature entry in metric");
            std::list<Creature*> creatures;
            player->GetCreatureListWithEntryInGrid(creatures, entry, 100.0f);
            double lowest = 0.0;
            bool found = false;
            for (Creature* creature : creatures)
            {
                if (!creature->IsAlive() || creature->GetOwnerGUID() != player->GetGUID() ||
                    !player->InSamePhase(creature))
                    continue;
                double const damage = double(creature->GetFloatValue(UNIT_FIELD_MINDAMAGE));
                lowest = found ? std::min(lowest, damage) : damage;
                found = true;
            }
            return lowest;
        }
        if (metric == "bank_shows")
            return double(_actors.at(step.get<std::string>("actor")).bankShows);
        if (metric == "system_messages")
            return double(_actors.at(step.get<std::string>("actor")).systemMessages);
        if (metric == "challenge_start_responses")
            return double(_actors.at(step.get<std::string>("actor")).challengeStartResponses);
        if (metric == "challenge_start_code")
            return double(_actors.at(step.get<std::string>("actor")).challengeStartLastCode);
        if (metric == "system_message_contains")
        {
            std::string const needle = step.get<std::string>("text");
            auto const& lines = _actors.at(step.get<std::string>("actor")).systemMessageTexts;
            return std::any_of(lines.begin(), lines.end(), [&needle](std::string const& line)
                { return line.find(needle) != std::string::npos; }) ? 1.0 : 0.0;
        }
        if (metric == "whispers_received")
        {
            ObjectGuid const from = GetPlayer(step.get<std::string>("from"))->GetGUID();
            std::string const text = step.get<std::string>("text");
            auto const& whispers = _actors.at(step.get<std::string>("actor")).whispers;
            return double(std::count_if(whispers.begin(), whispers.end(), [&](auto const& whisper)
                { return whisper.first == from && whisper.second == text; }));
        }
        if (metric == "notifications")
            return double(_actors.at(step.get<std::string>("actor")).notifications);
        if (metric == "notification_contains")
        {
            std::string const needle = step.get<std::string>("text");
            auto const& lines = _actors.at(step.get<std::string>("actor")).notificationTexts;
            return std::any_of(lines.begin(), lines.end(), [&needle](std::string const& line)
                { return line.find(needle) != std::string::npos; }) ? 1.0 : 0.0;
        }
        if (metric == "mail_pool_item_count")
        {
            uint32 cache = step.get<uint32>("cache");
            std::string table = step.get<std::string>("table", "prestigious");
            Require(table == "callboard" || table == "prestigious", "Unknown cache reward table");
            static std::unordered_map<std::string, std::unordered_set<uint32>> pools;
            std::string const key = table + ":" + std::to_string(cache);
            auto found = pools.find(key);
            if (found == pools.end())
            {
                std::unordered_set<uint32> ids;
                std::string query = "SELECT `RewardItemId` FROM `ascension_" + table +
                    "_cache_reward` WHERE `CacheItemId` = " + std::to_string(cache);
                if (QueryResult result = WorldDatabase.Query(query.c_str()))
                    do
                    {
                        ids.insert(result->Fetch()[0].Get<uint32>());
                    } while (result->NextRow());
                Require(!ids.empty(), "The cache has no reward pool to check against");
                found = pools.emplace(key, std::move(ids)).first;
            }

            uint32 count = 0;
            for (Mail* mail : player->GetMails())
                for (MailItemInfo const& entry : mail->items)
                    if (found->second.count(entry.item_template))
                        ++count;
            return double(count);
        }
        if (metric == "cast_failure")
        {
            auto const& reasons = _actors.at(step.get<std::string>("actor")).castFailureReason;
            auto const found = reasons.find(spell);
            return found == reasons.end() ? 0.0 : double(found->second);
        }
        if (metric == "pet_autocast_enabled")
        {
            Pet* pet = player->GetPet();
            Require(pet != nullptr, "Pet autocast observation needs a current pet");
            for (uint8 index = 0; index < pet->GetPetAutoSpellSize(); ++index)
                if (pet->GetPetAutoSpellOnPos(index) == spell)
                    return 1;
            return 0;
        }
        if (metric == "pet_loading")
        {
            Pet const* pet = player->GetPet();
            Require(pet != nullptr, "Pet loading observation needs a present pet");
            return pet->isBeingLoaded();
        }
        if (metric == "pet_casting")
        {
            Pet* pet = player->GetPet();
            Require(pet != nullptr, "Pet cast observation needs a present pet");
            return pet->HasUnitState(UNIT_STATE_CASTING) || pet->IsNonMeleeSpellCast(false);
        }
        if (metric == "pet_entry" || metric == "pet_aura_stacks" || metric == "pet_aura_amount" ||
            metric == "pet_aura_amplitude_ms" || metric == "pet_aura_duration_ms" || metric == "pet_max_health" ||
            metric == "pet_health" ||
            metric == "pet_attack_power" || metric == "pet_run_speed_rate" || metric == "pet_is_banker" ||
            metric == "pet_display" || metric == "pet_native_display" || metric == "pet_scale" ||
            metric == "pet_knows_spell" ||
            metric == "pet_distance" || metric == "pet_spell_bar_count")
        {
            Creature* pet = player->GetGuardianPet();
            if (!pet)
                pet = player->GetCompanionPet();
            if (!pet && player->GetCritterGUID())
                pet = ObjectAccessor::GetCreatureOrPetOrVehicle(*player, player->GetCritterGUID());
            if (metric == "pet_entry")
                return pet ? pet->GetEntry() : 0;
            if (metric == "pet_is_banker")
                return pet && pet->HasNpcFlag(UNIT_NPC_FLAG_BANKER);
            if (metric == "pet_display")
                return pet ? pet->GetDisplayId() : 0;
            if (metric == "pet_native_display")
                return pet ? pet->GetNativeDisplayId() : 0;
            if (metric == "pet_scale")
                return pet ? double(pet->GetObjectScale()) : 0.0;
            if (metric == "pet_spell_bar_count")
            {
                Require(pet && pet->GetCharmInfo(), "Metric needs a controllable pet");
                uint32 count = 0;
                for (uint8 index = 0; index < MAX_UNIT_ACTION_BAR_INDEX; ++index)
                {
                    UnitActionBarEntry const* entry = pet->GetCharmInfo()->GetActionBarEntry(index);
                    if (entry->IsActionBarForSpell() && entry->GetAction())
                        ++count;
                }
                return count;
            }
            if (metric == "pet_knows_spell")
                return pet && pet->IsPet() && pet->ToPet()->HasSpell(spell);
            if (!pet && (metric == "pet_aura_stacks" || metric == "pet_aura_amount" ||
                metric == "pet_aura_amplitude_ms" || metric == "pet_aura_duration_ms"))
                return 0;
            Require(pet != nullptr, "Metric needs a current pet");
            if (metric == "pet_distance")
                return player->GetExactDist2d(pet);
            if (metric == "pet_max_health")
                return pet->GetMaxHealth();
            if (metric == "pet_health")
                return pet->GetHealth();
            if (metric == "pet_attack_power")
                return pet->GetTotalAttackPowerValue(BASE_ATTACK);
            if (metric == "pet_run_speed_rate")
                return pet->GetSpeedRate(MOVE_RUN);
            Require(sSpellMgr->GetSpellInfo(spell) != nullptr, "Unknown pet aura spell");
            ObjectGuid caster;
            if (auto id = step.get_optional<std::string>("caster"))
                caster = GetUnit(*id)->GetGUID();
            Aura* aura = pet ? pet->GetAura(spell, caster) : nullptr;
            if ((metric == "pet_aura_amount" || metric == "pet_aura_amplitude_ms") && aura)
            {
                uint32 effect = step.get<uint32>("effect", 0);
                Require(effect < MAX_SPELL_EFFECTS && aura->GetEffect(effect), "Pet aura effect does not exist");
                return metric == "pet_aura_amount" ? aura->GetEffect(effect)->GetAmount() :
                    aura->GetEffect(effect)->GetAmplitude();
            }
            if (metric == "pet_aura_duration_ms")
                return aura ? aura->GetDuration() : 0;
            return aura ? aura->GetStackAmount() : 0;
        }
        if (metric == "cooldown_ms")
            return player->GetSpellCooldownDelay(spell);
        if (metric == "spell_charges")
            return player->GetSpellCharges(sSpellMgr->GetSpellInfo(spell)).Available;
        if (metric == "global_cooldown_ms")
            return player->GetGlobalCooldownMgr().GetGlobalCooldown(sSpellMgr->GetSpellInfo(spell));
        if (metric == "equipped_item")
        {
            uint32 slot = step.get<uint32>("slot");
            Require(slot < EQUIPMENT_SLOT_END, "Equipment observation needs a slot from 0 through 18");
            Item const* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, uint8(slot));
            return item ? item->GetEntry() : 0;
        }
        if (metric == "item_count")
        {
            uint32 item = step.get<uint32>("item");
            Require(sObjectMgr->GetItemTemplate(item) != nullptr, "Unknown item in metric");
            return player->GetItemCount(item);
        }
        if (metric == "token_count")
        {
            uint32 item = step.get<uint32>("item");
            Require(sObjectMgr->GetItemTemplate(item) != nullptr, "Unknown item in metric");
            uint32 count = 0;
            for (uint8 slot = CURRENCYTOKEN_SLOT_START; slot < CURRENCYTOKEN_SLOT_END; ++slot)
                if (Item* token = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
                    if (token->GetEntry() == item)
                        count += token->GetCount();
            return count;
        }
        if (metric == "item_sell_price")
        {
            uint32 item = step.get<uint32>("item");
            ItemTemplate const* proto = sObjectMgr->GetItemTemplate(item);
            Require(proto != nullptr, "Unknown item in metric");
            return proto->SellPrice;
        }
        if (metric == "creature_model_scale" || metric == "creature_model_display")
        {
            uint32 entry = step.get<uint32>("entry");
            CreatureTemplate const* proto = sObjectMgr->GetCreatureTemplate(entry);
            Require(proto != nullptr, "Unknown creature template in metric");
            CreatureModel const* model = ObjectMgr::ChooseDisplayId(proto);
            Require(model != nullptr, "Creature template has no model");
            return metric == "creature_model_scale" ? double(model->DisplayScale)
                                                     : double(model->CreatureDisplayID);
        }
        if (metric == "pool_variant_count" || metric == "carried_variant_item_count")
        {
            auto isVariant = [](ItemTemplate const* proto)
            {
                std::string const& text = proto->Description;
                std::string tag;
                if (text.size() > 2 && text[0] == '@')
                {
                    size_t end = text.find('@', 1);
                    if (end != std::string::npos)
                        tag = text.substr(1, end - 1);
                }
                if (tag == "Heroic Dungeon" || tag == "Mythic Dungeon")
                    return false;
                if (proto->HasFlag(ITEM_FLAG_HEROIC_TOOLTIP))
                    return true;
                return tag.rfind("Heroic", 0) == 0 || tag.rfind("Mythic", 0) == 0 ||
                    tag.rfind("Ascended", 0) == 0;
            };
            if (metric == "carried_variant_item_count")
            {
                uint32 count = 0;
                for (uint8 slot = EQUIPMENT_SLOT_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
                    if (Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
                        if (ItemTemplate const* proto = item->GetTemplate())
                            if (isVariant(proto))
                                count += item->GetCount();
                for (uint8 bag = INVENTORY_SLOT_BAG_START; bag < INVENTORY_SLOT_BAG_END; ++bag)
                    if (Bag* container = player->GetBagByPos(bag))
                        for (uint32 slot = 0; slot < container->GetBagSize(); ++slot)
                            if (Item* item = container->GetItemByPos(uint8(slot)))
                                if (ItemTemplate const* proto = item->GetTemplate())
                                    if (isVariant(proto))
                                        count += item->GetCount();
                return double(count);
            }

            uint32 cache = step.get<uint32>("cache");
            std::string table = step.get<std::string>("table", "prestigious");
            Require(table == "callboard" || table == "prestigious", "Unknown cache reward table");
            uint32 variants = 0;
            std::string query = "SELECT i.Flags, i.description FROM ascension_" + table +
                "_cache_reward p JOIN item_template i ON i.entry = p.RewardItemId"
                " WHERE p.CacheItemId = " + std::to_string(cache);
            if (QueryResult result = WorldDatabase.Query(query.c_str()))
                do
                {
                    Field* fields = result->Fetch();
                    uint32 flags = fields[0].Get<uint32>();
                    std::string text = fields[1].Get<std::string>();
                    std::string tag;
                    if (text.size() > 2 && text[0] == '@')
                    {
                        size_t end = text.find('@', 1);
                        if (end != std::string::npos)
                            tag = text.substr(1, end - 1);
                    }
                    if (tag == "Heroic Dungeon" || tag == "Mythic Dungeon")
                        continue;
                    if ((flags & ITEM_FLAG_HEROIC_TOOLTIP) != 0 || tag.rfind("Heroic", 0) == 0 ||
                        tag.rfind("Mythic", 0) == 0 || tag.rfind("Ascended", 0) == 0)
                        ++variants;
                } while (result->NextRow());
            else
                Require(false, "The cache has no reward pool to check against");
            return double(variants);
        }
        if (metric == "pool_retired_item_count")
        {
            uint32 cache = step.get<uint32>("cache");
            std::string table = step.get<std::string>("table", "prestigious");
            Require(table == "callboard" || table == "prestigious", "Unknown cache reward table");
            uint32 retired = 0;
            std::string query = "SELECT i.description FROM ascension_" + table +
                "_cache_reward p JOIN item_template i ON i.entry = p.RewardItemId"
                " WHERE p.CacheItemId = " + std::to_string(cache);
            if (QueryResult result = WorldDatabase.Query(query.c_str()))
                do
                {
                    if (result->Fetch()[0].Get<std::string>().find("deprecated") != std::string::npos)
                        ++retired;
                } while (result->NextRow());
            else
                Require(false, "The cache has no reward pool to check against");
            return double(retired);
        }
        if (metric == "pool_row_count" || metric == "pool_item_present")
        {
            uint32 cache = step.get<uint32>("cache");
            std::string table = step.get<std::string>("table", "prestigious");
            Require(table == "callboard" || table == "prestigious" || table == "fire_lord",
                "Unknown cache reward table");
            Require(table != "fire_lord" || cache == 2400040, "The fire_lord table holds Cache of the Fire Lord only");
            uint32 wanted = step.get<uint32>("item", 0);
            std::string query = table == "fire_lord" ?
                std::string("SELECT `ItemEntry` FROM `coa_mc_fire_lord_cache_pool`") :
                "SELECT `RewardItemId` FROM `ascension_" + table + "_cache_reward` WHERE `CacheItemId` = " +
                    std::to_string(cache);
            uint32 rows = 0;
            bool present = false;
            if (QueryResult result = WorldDatabase.Query(query.c_str()))
                do
                {
                    ++rows;
                    if (wanted && result->Fetch()[0].Get<uint32>() == wanted)
                        present = true;
                } while (result->NextRow());
            else
                Require(false, "The cache has no reward pool to check against");
            Require(rows > 0, "The cache has an empty reward pool");
            if (metric == "pool_row_count")
                return double(rows);
            Require(wanted != 0, "pool_item_present needs an item to look for");
            return present ? 1.0 : 0.0;
        }
        if (metric == "free_inventory_slots")
            return double(player->GetFreeInventorySpace());
        if (metric == "has_achievement")
            return player->HasAchieved(step.get<uint32>("achievement")) ? 1.0 : 0.0;
        if (metric == "has_title")
        {
            CharTitlesEntry const* title = sCharTitlesStore.LookupEntry(step.get<uint32>("title"));
            Require(title != nullptr, "has_title needs a title from CharTitles.dbc");
            return player->HasTitle(title) ? 1.0 : 0.0;
        }
        if (metric == "mail_count" || metric == "mail_item_count" || metric == "mail_has_item")
        {
            uint32 mails = 0, items = 0;
            uint32 wanted = step.get<uint32>("item", 0);
            bool found = false;
            for (Mail* mail : player->GetMails())
            {
                ++mails;
                for (MailItemInfo const& entry : mail->items)
                {
                    ++items;
                    if (wanted && entry.item_template == wanted)
                        found = true;
                }
            }
            if (metric == "mail_count")
                return double(mails);
            if (metric == "mail_item_count")
                return double(items);
            Require(wanted != 0, "mail_has_item needs the item to look for");
            return found ? 1.0 : 0.0;
        }
        if (metric == "cache_token_count" || metric == "cache_token_stage" ||
            metric == "cache_token_present")
        {
            uint32 cache = step.get<uint32>("cache");
            uint32 wanted = step.get<uint32>("item", 0);
            std::string query = "SELECT `RewardItemId`, `TokenStage` FROM "
                "`ascension_cache_content_token` WHERE `CacheItemId` = " + std::to_string(cache);
            uint32 rows = 0;
            uint32 highest = 0;
            bool present = false;
            if (QueryResult result = WorldDatabase.Query(query.c_str()))
                do
                {
                    Field* fields = result->Fetch();
                    ++rows;
                    uint32 stage = uint32(fields[1].Get<uint8>());
                    if (stage > highest)
                        highest = stage;
                    if (wanted && fields[0].Get<uint32>() == wanted)
                        present = true;
                } while (result->NextRow());
            if (metric == "cache_token_count")
                return double(rows);
            if (metric == "cache_token_stage")
                return double(highest);
            Require(wanted != 0, "cache_token_present needs a token to look for");
            return present ? 1.0 : 0.0;
        }
        if (metric == "carried_item_count" || metric == "carried_pool_item_count")
        {
            static std::unordered_map<std::string, std::unordered_set<uint32>> pools;
            std::unordered_set<uint32> const* pool = nullptr;
            if (metric == "carried_pool_item_count")
            {
                uint32 cache = step.get<uint32>("cache");
                std::string table = step.get<std::string>("table", "prestigious");
                Require(table == "callboard" || table == "prestigious" || table == "loot",
                    "Unknown cache reward table");
                std::string key = table + ":" + std::to_string(cache);
                auto found = pools.find(key);
                if (found == pools.end())
                {
                    std::unordered_set<uint32> ids;
                    std::string const entry = std::to_string(cache);
                    std::string query = table == "loot"
                        ? "SELECT `Item` FROM `item_loot_template` WHERE `Reference` = 0 AND `Entry` = " + entry +
                            " UNION SELECT `r`.`Item` FROM `reference_loot_template` `r` JOIN `item_loot_template` `i`"
                            " ON `r`.`Entry` = `i`.`Reference` WHERE `r`.`Reference` = 0 AND `i`.`Entry` = " + entry
                        : "SELECT `RewardItemId` FROM `ascension_" + table + "_cache_reward` WHERE `CacheItemId` = " +
                            entry;
                    if (QueryResult result = WorldDatabase.Query(query.c_str()))
                        do
                        {
                            ids.insert(result->Fetch()[0].Get<uint32>());
                        } while (result->NextRow());
                    Require(!ids.empty(), "The cache has no reward pool to check against");
                    found = pools.emplace(key, std::move(ids)).first;
                }
                pool = &found->second;
            }
            auto excluded = step.get_optional<uint32>("exclude");
            uint32 const minRequiredLevel = step.get<uint32>("min_required_level", 0);
            uint32 const maxRequiredLevel = step.get<uint32>("max_required_level", STRONG_MAX_LEVEL);
            auto dominantStat = step.get_optional<uint32>("dominant_stat");
            auto offStat = step.get_optional<uint32>("off_stat");
            auto strongestAttributes = [](ItemTemplate const* proto)
            {
                std::array<int32, ITEM_MOD_SPIRIT + 1> attributes{};
                for (uint32 index = 0; index < proto->StatsCount && index < MAX_ITEM_PROTO_STATS; ++index)
                {
                    uint32 const type = proto->ItemStat[index].ItemStatType;
                    if (type >= ITEM_MOD_AGILITY && type <= ITEM_MOD_SPIRIT && proto->ItemStat[index].ItemStatValue > 0)
                        attributes[type] += proto->ItemStat[index].ItemStatValue;
                }
                int32 const strongest = *std::max_element(attributes.begin(), attributes.end());
                std::unordered_set<uint32> stats;
                for (uint32 type = ITEM_MOD_AGILITY; strongest > 0 && type <= ITEM_MOD_SPIRIT; ++type)
                    if (attributes[type] == strongest)
                        stats.insert(type);
                return stats;
            };
            uint32 count = 0;
            auto countItem = [pool, &count, &excluded, minRequiredLevel, maxRequiredLevel, &dominantStat, &offStat,
                &strongestAttributes](Item* item)
            {
                if (excluded && item->GetEntry() == *excluded)
                    return;
                uint32 const requiredLevel = item->GetTemplate()->RequiredLevel;
                if (requiredLevel < minRequiredLevel || requiredLevel > maxRequiredLevel)
                    return;
                ItemTemplate const* base = sObjectMgr->GetItemTemplate(ItemScaling::BaseEntry(item->GetEntry()));
                std::unordered_set<uint32> const strongest = strongestAttributes(base ? base : item->GetTemplate());
                if (dominantStat && !strongest.count(*dominantStat))
                    return;
                if (offStat && (strongest.empty() || strongest.count(*offStat)))
                    return;
                if (!pool || pool->count(ItemScaling::BaseEntry(item->GetEntry())))
                    count += item->GetCount();
            };
            for (uint8 slot = EQUIPMENT_SLOT_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
                if (Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
                    countItem(item);
            for (uint8 bag = INVENTORY_SLOT_BAG_START; bag < INVENTORY_SLOT_BAG_END; ++bag)
                if (Bag* container = player->GetBagByPos(bag))
                    for (uint32 slot = 0; slot < container->GetBagSize(); ++slot)
                        if (Item* item = container->GetItemByPos(uint8(slot)))
                            countItem(item);
            return count;
        }
        if (metric == "carried_item_level" || metric == "carried_item_required_level" ||
            metric == "carried_item_armor" || metric == "carried_item_scaling_level")
        {
            uint32 const baseEntry = step.get<uint32>("item");
            Require(sObjectMgr->GetItemTemplate(baseEntry) != nullptr, "Unknown item in metric");
            uint32 highest = 0;
            auto inspect = [&](Item* item)
            {
                if (ItemScaling::BaseEntry(item->GetEntry()) != baseEntry)
                    return;
                ItemTemplate const* proto = LocalLevelScaling::InstanceTemplateFor(item, item->GetTemplate());
                uint32 value = proto->ItemLevel;
                if (metric == "carried_item_required_level")
                    value = proto->RequiredLevel;
                else if (metric == "carried_item_armor")
                    value = proto->Armor;
                else if (metric == "carried_item_scaling_level")
                    value = NativeItemScaling::InstanceLevel(item);
                highest = std::max(highest, value);
            };
            for (uint8 slot = EQUIPMENT_SLOT_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
                if (Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
                    inspect(item);
            for (uint8 bag = INVENTORY_SLOT_BAG_START; bag < INVENTORY_SLOT_BAG_END; ++bag)
                if (Bag* container = player->GetBagByPos(bag))
                    for (uint32 slot = 0; slot < container->GetBagSize(); ++slot)
                        if (Item* item = container->GetItemByPos(uint8(slot)))
                            inspect(item);
            return highest;
        }
        if (metric == "quest_status" || metric == "quest_takeable")
        {
            uint32 quest = step.get<uint32>("quest");
            Quest const* questTemplate = sObjectMgr->GetQuestTemplate(quest);
            Require(questTemplate != nullptr, "Unknown quest in metric");
            return metric == "quest_status" ? double(player->GetQuestStatus(quest))
                : double(player->CanTakeQuest(questTemplate, false));
        }
        if (metric == "quest_objective_count")
        {
            uint16 slot = player->FindQuestSlot(step.get<uint32>("quest"));
            Require(slot < MAX_QUEST_LOG_SIZE, "Quest is not in the quest log");
            uint32 index = step.get<uint32>("index", 0);
            Require(index < QUEST_OBJECTIVES_COUNT, "Invalid quest objective index");
            return double(player->GetQuestSlotCounter(slot, index));
        }
        if (metric == "dialog_status")
        {
            uint32 entry = step.get<uint32>("entry");
            Require(sObjectMgr->GetCreatureTemplate(entry) != nullptr, "Unknown creature entry in metric");
            Creature* giver = GetGiver(player, entry);
            return giver ? double(player->GetQuestDialogStatus(giver)) : 0.0;
        }
        if (metric == "ball_offer_count" || metric == "ball_offers_quest")
        {
            Require(AscensionWisdomball::UsableBall(player) != nullptr, "No wisdomball is within reach of the player");
            std::vector<uint32> const offered = AscensionWisdomball::OfferedQuests(player);
            if (metric == "ball_offer_count")
                return double(offered.size());
            uint32 quest = step.get<uint32>("quest");
            Require(sObjectMgr->GetQuestTemplate(quest) != nullptr, "Unknown quest in metric");
            return std::count(offered.begin(), offered.end(), quest) ? 1.0 : 0.0;
        }
        if (metric == "ball_carried_count" || metric == "ball_carried_quest"
            || metric == "ball_turn_in_count" || metric == "ball_turn_in_quest")
        {
            Require(AscensionWisdomball::UsableBall(player) != nullptr, "No wisdomball is within reach of the player");
            bool const handIn = metric.rfind("ball_turn_in", 0) == 0;
            std::vector<uint32> const listed = handIn ? AscensionWisdomball::TurnInQuests(player)
                : AscensionWisdomball::CarriedQuests(player);
            if (metric == "ball_carried_count" || metric == "ball_turn_in_count")
                return double(listed.size());
            uint32 quest = step.get<uint32>("quest");
            Require(sObjectMgr->GetQuestTemplate(quest) != nullptr, "Unknown quest in metric");
            return std::count(listed.begin(), listed.end(), quest) ? 1.0 : 0.0;
        }
        if (metric == "gossip_text")
        {
            uint32 id = step.get<uint32>("id");
            return sObjectMgr->GetGossipText(id) != nullptr ? 1.0 : 0.0;
        }
        if (metric == "quest_menu_items")
            return player->PlayerTalkClass->GetQuestMenu().GetMenuItemCount();
        if (metric == "quest_menu_has")
            return player->PlayerTalkClass->GetQuestMenu().HasItem(step.get<uint32>("quest")) ? 1.0 : 0.0;
        if (metric == "player_setting")
        {
            PlayerSettingVector const* values = player->FindPlayerSettings(step.get<std::string>("source"));
            uint32 const index = step.get<uint32>("index");
            return values && index < values->size() ? double((*values)[index].value) : 0.0;
        }
        if (metric == "wildcard_starter_spells_known")
        {
            auto const& starters = AscensionWildcardStarterData::OtherAbilities;
            return double(std::count_if(starters.begin(), starters.end(),
                [player](auto const& starter) { return player->HasSpell(starter.SpellId); }));
        }
        if (metric == "wildcard_spells_known")
        {
            std::vector<AscensionWildcard::Slot> const slots = AscensionWildcard::Slots(player);
            return double(std::count_if(slots.begin(), slots.end(), [player](AscensionWildcard::Slot const& slot)
            {
                uint32 const spellId = slot.EntryId ? WildcardSpell(slot) : 0;
                return spellId && player->HasSpell(spellId);
            }));
        }
        if (metric == "wildcard_cards_pending")
            return double(AscensionWildcard::Collection(player).Pending.size());
        if (metric == "wildcard_cards_collected")
            return double(AscensionWildcard::Collection(player).Collected.size());
        if (metric == "wildcard_bonus_pack_progress")
            return double(AscensionWildcard::Collection(player).BonusProgress);
        if (metric == "wildcard_roll_cards_set" || metric == "wildcard_roll_cards_used")
        {
            AscensionWildcard::RollCardSlots const cards = AscensionWildcard::RollCards(player);
            bool const used = metric == "wildcard_roll_cards_used";
            return double(std::count_if(cards.begin(), cards.end(), [used](AscensionWildcard::CardSlot const& slot)
                { return slot.Card && (!used || slot.Used); }));
        }
        if (metric == "player_class")
            return player->getClass();
        if (metric == "cached_class")
        {
            CharacterCacheEntry const* cached = sCharacterCache->GetCharacterCacheByGuid(player->GetGUID());
            return cached ? cached->Class : 0;
        }
        if (metric == "at_login_flag")
            return player->HasAtLoginFlag(AtLoginFlags(step.get<uint32>("id"))) ? 1.0 : 0.0;
        if (metric == "server_packets")
        {
            Actor const& actor = _actors.at(step.get<std::string>("actor"));
            if (auto row = step.get_optional<uint32>("row"))
            {
                auto const found = actor.selectedPacketRowCounts.find({ uint16(step.get<uint32>("opcode")), *row });
                return found == actor.selectedPacketRowCounts.end() ? 0.0 : double(found->second);
            }
            auto const& packets = actor.extensionPackets;
            auto const found = packets.find(uint16(step.get<uint32>("opcode")));
            return found == packets.end() ? 0.0 : double(found->second);
        }
        if (metric == "known_entry_rank")
        {
            Actor const& actor = _actors.at(step.get<std::string>("actor"));
            auto const found = actor.extensionPayloads.find(KnownEntriesOpcode);
            if (found == actor.extensionPayloads.end() || found->second.empty())
                return -1;
            std::string const& payload = found->second.back();
            std::vector<AscensionCoATalentState::KnownEntry> known;
            if (!AscensionCoATalentState::ParseKnownEntriesUpload(
                reinterpret_cast<uint8 const*>(payload.data()), payload.size(), known))
                return -1;
            uint32 const entryId = step.get<uint32>("entry");
            auto const selected = std::find_if(known.begin(), known.end(), [entryId](auto const& entry)
            {
                return entry.EntryId == entryId;
            });
            return selected == known.end() ? 0 : selected->Rank;
        }
        if (metric == "server_packet_u8" || metric == "server_packet_u32" || metric == "server_packet_float")
        {
            Actor const& actor = _actors.at(step.get<std::string>("actor"));
            uint16 const opcode = uint16(step.get<uint32>("opcode"));
            std::string const* payload = nullptr;
            if (auto row = step.get_optional<uint32>("row"))
            {
                auto const found = actor.selectedPacketRows.find({ opcode, *row });
                if (found != actor.selectedPacketRows.end())
                    payload = &found->second;
            }
            else
            {
                auto const found = actor.extensionPayloads.find(opcode);
                if (found != actor.extensionPayloads.end() && !found->second.empty())
                    payload = &found->second.back();
            }
            uint32 const index = step.get<uint32>("index", 0);
            if (!payload || payload->empty())
                return -1;
            std::size_t offset = step.get<uint32>("offset", 0);
            for (uint32 strings = step.get<uint32>("skip_strings", 0); strings; --strings)
            {
                offset = payload->find('\0', offset);
                if (offset == std::string::npos)
                    return -1;
                ++offset;
            }
            std::size_t const fieldSize = metric == "server_packet_u8" ? sizeof(uint8) : sizeof(uint32);
            offset += std::size_t(index) * fieldSize;
            if (metric == "server_packet_float" && step.get<bool>("from_end", false))
            {
                std::size_t const tail = (std::size_t(index) + 1) * sizeof(uint32);
                if (tail > payload->size())
                    return -1;
                offset = payload->size() - tail;
            }
            if (offset > payload->size() || payload->size() - offset < fieldSize)
                return -1;
            uint32 value = 0;
            for (std::size_t byte = 0; byte < fieldSize; ++byte)
                value |= uint32(uint8((*payload)[offset + byte])) << (byte * 8);
            if (metric == "server_packet_float")
            {
                float const number = std::bit_cast<float>(value);
                return std::isfinite(number) ? double(number) : -1;
            }
            return value;
        }
        if (metric == "quest_log_sent_level" || metric == "quest_log_sent_xp")
            return SentQuestLogField(player, step, metric == "quest_log_sent_level"
                ? AscensionQuestLog::LevelField : AscensionQuestLog::RewardXPField);
        if (metric == "server_packet_contains")
        {
            Actor const& actor = _actors.at(step.get<std::string>("actor"));
            uint16 const opcode = uint16(step.get<uint32>("opcode"));
            std::string const needle = step.get<std::string>("text");
            if (auto row = step.get_optional<uint32>("row"))
            {
                auto const found = actor.selectedPacketRows.find({ opcode, *row });
                return found != actor.selectedPacketRows.end() && found->second.find(needle) != std::string::npos;
            }
            auto const found = actor.extensionPayloads.find(opcode);
            bool const contains = found != actor.extensionPayloads.end() && std::any_of(found->second.begin(),
                found->second.end(), [&needle](std::string const& payload)
                { return payload.find(needle) != std::string::npos; });
            return contains ? 1.0 : 0.0;
        }
        throw std::runtime_error("Unknown metric: " + metric);
    }

    void RunStep(Tree const& step)
    {
        if (!_stepStarted)
        {
            _stepStarted = true;
            _stepTime = GameTime::Now();
        }
        std::string action = step.get<std::string>("action");
        Tree record;
        record.put("index", _completed);
        record.put("action", action);
        record.put("label", step.get<std::string>("label", action));
        if (action == "wait")
        {
            if (GameElapsed(_stepTime) < step.get<uint32>("ms"))
                return;
        }
        else if (action == "client_packet")
        {
            Player* player = GetPlayer(step.get<std::string>("actor"));
            if (auto spell = step.get_optional<uint32>("cast_before"))
            {
                Require(player->HasActiveSpell(*spell), "Packet prerequisite spell is not active");
                SpellCastTargets targets;
                targets.SetUnitTarget(player);
                WorldPacket cast(CMSG_CAST_SPELL, 64);
                cast << uint8(++_castCount) << *spell << uint8(0);
                targets.Write(cast);
                player->GetSession()->HandleCastSpellOpcode(cast);
            }
            if (auto loading = step.get_optional<bool>("pet_loading_before"))
            {
                Pet* pet = player->GetPet();
                Require(pet != nullptr, "Packet loading observation needs a present pet");
                record.put("pet_loading_before", pet->isBeingLoaded());
                Require(pet->isBeingLoaded() == *loading, "Unexpected pet loading state before packet");
            }
            WorldPacket request(uint16(step.get<uint32>("opcode")), 64);
            if (auto const fields = step.get_child_optional("fields"))
                for (auto const& [position, field] : *fields)
                    for (auto const& [kind, value] : field)
                    {
                        if (kind == "u8")
                            request << uint8(value.get_value<uint32>());
                        else if (kind == "u32")
                            request << value.get_value<uint32>();
                        else if (kind == "u64")
                            request << value.get_value<uint64>();
                        else if (kind == "string")
                            request << value.get_value<std::string>();
                        else if (kind == "buyback_guid")
                            request << BuybackGuid(player, value.get_value<uint32>());
                        else if (kind == "stabled_pet")
                            request << StabledPetNumber(player, value.get_value<uint32>());
                        else if (kind == "actor_guid")
                            request << GetUnit(value.get_value<std::string>())->GetGUID().GetRawValue();
                        else if (kind == "duel_arbiter")
                        {
                            ObjectGuid const arbiter = GetPlayer(value.get_value<std::string>())
                                ->GetGuidValue(PLAYER_DUEL_ARBITER);
                            Require(!arbiter.IsEmpty(), "Packet duel arbiter requires a pending duel");
                            request << arbiter.GetRawValue();
                        }
                        else if (kind == "pet_guid")
                        {
                            Pet* pet = GetPlayer(value.get_value<std::string>())->GetPet();
                            Require(pet != nullptr, "Packet pet GUID requires a summoned pet");
                            request << pet->GetGUID().GetRawValue();
                        }
                        else if (kind == "packed_actor_guid")
                            request << GetUnit(value.get_value<std::string>())->GetGUID().WriteAsPacked();
                        else if (kind == "wildcard_entry")
                            request << WildcardSlot(player, value.get_value<uint32>()).EntryId;
                        else if (kind == "wildcard_lowest_card")
                            request << LowestCollectedCard(player, value.get_value<uint32>());
                        else if (kind == "wildcard_pending_cards")
                        {
                            std::vector<AscensionWildcard::PendingCard> cards =
                                AscensionWildcard::Collection(player).Pending;
                            cards.resize(std::min<std::size_t>(cards.size(), value.get_value<uint32>()));
                            request << uint32(cards.size());
                            for (AscensionWildcard::PendingCard const& pending : cards)
                                request << AscensionWildcard::PendingCardName(pending.Id) << pending.Card << uint32(1);
                        }
                        else
                            throw std::runtime_error("Unknown packet field type: " + kind);
                    }

            bool const early = step.get<bool>("early", true);
            bool const consumed = early ? ReceiveEarly(player, request)
                : !sScriptMgr->CanPacketReceive(player->GetSession(), request);
            record.put(early ? "consumed_early" : "consumed", consumed);
            char const* const hook = early ? "early packet hook" : "packet hook";
            Require(consumed == step.get<bool>("consumed", true), consumed
                ? Acore::StringFormat("The packet was consumed by the {}", hook)
                : Acore::StringFormat("No {} consumed the packet", hook));
            if (early && !consumed)
                if (char const* handler = DeliverToSession(player, request))
                    record.put("core_handler", handler);
        }
        else if (action == "specialization" || action == "advancement_rank")
        {
            Player* player = GetPlayer(step.get<std::string>("actor"));
            bool const specialization = action == "specialization";
            uint32& results = _actors.at(step.get<std::string>("actor")).extensionPackets[UpdateEntriesResultOpcode];
            if (!_talentRequestSent)
            {
                _talentRequestSent = true;
                _talentResultsBefore = results;
                auto const current = GetAscensionKnownTalentEntries(player);
                WorldPacket upload = KnownEntriesUpload(specialization
                    ? AscensionCoATalentState::SpecializationSwitch(player->getClass(), SpellbookOf(player),
                        step.get<uint32>("id"), &current)
                    : KnownEntriesWithRank(player, step.get<uint32>("entry"), step.get<uint32>("rank")));
                Require(ReceiveEarly(player, upload), "No early packet hook consumed the known-entries upload");
                return;
            }
            bool const applied = specialization
                ? GetAscensionActiveSpecialization(player) == step.get<uint32>("id")
                : GetAscensionTalentRank(player, step.get<uint32>("entry")) == step.get<uint32>("rank");
            if (step.get<bool>("refused", false))
            {
                bool const answered = results > _talentResultsBefore;
                if (!answered && GameElapsed(_stepTime) < TalentRequestWindowMs)
                    return;
                Require(answered && !applied, "The server did not refuse the upload");
            }
            else
            {
                if (!applied && GameElapsed(_stepTime) < TalentRequestWindowMs)
                    return;
                Require(applied, specialization ? "The server did not activate the uploaded specialization"
                    : "The server did not apply the uploaded talent rank");
            }
        }
        else if (action == "apply_appearances")
        {
            Player* player = GetPlayer(step.get<std::string>("actor"));
            std::map<uint32, uint32> selection;
            for (auto const& [category, appearance] : step.get_child("selection"))
                selection[uint32(std::stoul(category))] = appearance.get_value<uint32>();
            uint32 const count = selection.empty() ? 1 : selection.rbegin()->first + 1;
            WorldPacket request(ApplyAppearancesOpcode, sizeof(uint32) * (count + 1));
            request << count;
            for (uint32 category = 0; category < count; ++category)
                request << (selection.contains(category) ? selection[category] : 0u);
            Require(ReceiveEarly(player, request), "No early packet hook consumed the appearance request");
        }
        else if (action == "level_scaling_packet")
        {
            Player* player = GetPlayer(step.get<std::string>("actor"));
            bool const before = LocalLevelScaling::ScalingChoiceEnabled(player);
            WorldSession* session = player->GetSession();
            uint32 value = step.get<uint32>("value");
            bool const consumed = std::async(std::launch::async, [session, value]
            {
                WorldPacket request(LevelScalingOpcode, sizeof(uint32));
                request << value;
                return !sScriptMgr->CanPacketReceiveEarly(session, request);
            }).get();
            Require(consumed, "Scaling packet was not consumed");
            Require(LocalLevelScaling::ScalingChoiceEnabled(player) == before,
                "Early packet hook changed player state before the player update");
        }
        else if (action == "snapshot" || action == "assert")
        {
            double actual = Measure(step);
            if (auto relative = step.get_optional<std::string>("relative_to"))
            {
                Require(_snapshots.count(*relative) != 0, "Unknown snapshot: " + *relative);
                actual -= _snapshots.at(*relative);
            }
            if (auto ratio = step.get_optional<std::string>("ratio_to"))
            {
                Require(_snapshots.count(*ratio) && _snapshots.at(*ratio) != 0, "Missing or zero ratio snapshot");
                actual /= _snapshots.at(*ratio);
            }
            record.put("actual", actual);
            record.put("actor", step.get<std::string>("actor"));
            record.put("metric", step.get<std::string>("metric"));
            if (action == "snapshot")
                _snapshots[step.get<std::string>("save_as")] = actual;
            else
            {
                auto equals = step.get_optional<double>("equals");
                auto minimum = step.get_optional<double>("min");
                auto maximum = step.get_optional<double>("max");
                Require(bool(equals) || bool(minimum) || bool(maximum), "Assertion needs an expected value");
                bool passed = std::isfinite(actual) && (!equals || actual == *equals)
                    && (!minimum || actual >= *minimum) && (!maximum || actual <= *maximum);
                if (equals)
                    record.put("expected_equals", *equals);
                if (minimum)
                    record.put("expected_min", *minimum);
                if (maximum)
                    record.put("expected_max", *maximum);
                if (!passed && GameElapsed(_stepTime) < step.get<uint32>("within_ms", 0))
                    return;
                record.put("status", passed ? "passed" : "failed");
                record.put("elapsed_ms", GameElapsed(_stepTime));
                _records.push_back({ "", record });
                ++_assertions;
                Require(passed, "Assertion failed: " + record.get<std::string>("label"));
                Advance();
                return;
            }
        }
        else if (action == "relog")
        {
            Actor& actor = _actors.at(step.get<std::string>("actor"));
            if (!_relogging)
            {
                Player* player = GetPlayer(step.get<std::string>("actor"));
                auto const race = step.get_optional<uint32>("race");
                if (race)
                    Require(*race > 0 && *race <= 255 && sObjectMgr->GetPlayerInfo(uint8(*race), player->getClass()),
                        "Relog race needs an available race/class combination");
                CharacterDatabaseTransaction transaction = CharacterDatabase.BeginTransaction();
                player->SaveToDB(transaction, false, true);
                if (race)
                {
                    CharacterDatabasePreparedStatement* change =
                        CharacterDatabase.GetPreparedStatement(CHAR_UPD_CHAR_RACE);
                    change->SetData(0, uint8(*race));
                    change->SetData(1, player->GetGUID().GetCounter());
                    transaction->Append(change);
                }
                _relogSave.emplace(CharacterDatabase.AsyncCommitTransaction(transaction));
                _relogging = true;
                return;
            }
            if (_relogSave)
            {
                if (_relogSave->m_future.wait_for(std::chrono::seconds(0)) != std::future_status::ready)
                    return;
                Require(_relogSave->m_future.get(), "Relog save transaction failed");
                _relogSave.reset();
                actor.session->LogoutPlayer(false);
                if (auto race = step.get_optional<uint32>("race"))
                {
                    CharacterCacheEntry const* cached = sCharacterCache->GetCharacterCacheByGuid(actor.guid);
                    Require(cached != nullptr, "Relog race needs a cached character");
                    sCharacterCache->UpdateCharacterData(actor.guid, cached->Name, cached->Sex, uint8(*race));
                }
                LogIn(actor);
                return;
            }
            if (actor.stage != ActorStage::InWorld && actor.stage != ActorStage::Ready)
                return;
            Require(actor.session->GetPlayer() && actor.session->GetPlayer()->IsInWorld(),
                "Relogged character did not enter the world");
            Reach(actor, ActorStage::Ready);
        }
        else if (action == "login_hooks" && !QueuedCharacterWorkDone())
            return;
        else
            Act(step, record);
        record.put("status", "completed");
        record.put("elapsed_ms", GameElapsed(_stepTime));
        _records.push_back({ "", record });
        Advance();
    }

    bool QueuedCharacterWorkDone()
    {
        if (_characterQueueReached)
            return true;
        if (!_characterQueueMarked)
        {
            _characterQueueMarked = true;
            _queries.AddCallback(CharacterDatabase.AsyncQuery("SELECT 1").WithCallback(
                [this](QueryResult) { _characterQueueReached = true; }));
        }
        return false;
    }

    void Act(Tree const& step, Tree& record)
    {
        std::string action = step.get<std::string>("action");
        if (action == "console")
        {
            std::string output;
            CliHandler handler(&output, [](void* context, std::string_view text)
            {
                static_cast<std::string*>(context)->append(text);
            });
            bool handled = handler.ParseCommands(CommandText(step));
            record.put("output", output);
            Require(handled && !handler.HasSentErrorMessage(), "Console command failed: " + output);
            return;
        }
        std::string id = step.get<std::string>("actor");
        if (action == "attack_owned_creature")
        {
            Creature* attacker = GetUnit(id)->ToCreature();
            Player* owner = GetPlayer(step.get<std::string>("target"));
            Require(attacker && attacker->AI(), "Owned-creature attack needs a creature AI");
            std::list<Creature*> creatures;
            owner->GetCreatureListWithEntryInGrid(creatures, step.get<uint32>("entry"), 100.0f);
            creatures.remove_if([owner, attacker](Creature* creature)
            {
                return !creature->IsAlive() || creature->GetOwnerGUID() != owner->GetGUID() ||
                    !owner->InSamePhase(creature) || !attacker->IsValidAttackTarget(creature);
            });
            Require(!creatures.empty(), "No valid owned creature for the attacker");
            creatures.sort([attacker](Creature* first, Creature* second)
            {
                return attacker->GetExactDist2d(first) < attacker->GetExactDist2d(second);
            });
            attacker->AI()->AttackStart(creatures.front());
            record.put("target_entry", creatures.front()->GetEntry());
            return;
        }
        if (action == "set_health" && !_actors.count(id))
        {
            Unit* creature = GetUnit(id);
            uint32 health = step.get<uint32>("value");
            Require(health > 0 && health <= creature->GetMaxHealth(), "Health fixture outside valid range");
            creature->SetHealth(health);
            return;
        }
        if (action == "cast" && !_actors.count(id))
        {
            Unit* creature = GetUnit(id);
            uint32 spell = step.get<uint32>("spell");
            Require(sSpellMgr->GetSpellInfo(spell) != nullptr, "Unknown spell: " + std::to_string(spell));
            Unit* target = step.get_optional<std::string>("target")
                ? GetUnit(step.get<std::string>("target")) : creature;
            SpellCastResult result = creature->CastSpell(target, spell, TRIGGERED_FULL_MASK);
            record.put("cast_result", uint32(result));
            Require(result == SPELL_CAST_OK, "Creature cast failed: " + std::to_string(result));
            return;
        }
        Player* player = GetPlayer(id);
        if (action == "mapless_loot_hook")
        {
            std::string const storeName = step.get<std::string>("store");
            Require(storeName == "mail" || storeName == "gameobject", "Unsupported mapless loot store");
            LootStore const& store = storeName == "mail" ? LootTemplates_Mail : LootTemplates_Gameobject;
            class MaplessLootPlayer : public Player
            {
            public:
                explicit MaplessLootPlayer(WorldSession* session) : Player(session)
                {
                    Object::_Create(ObjectGuid::Empty);
                }
            };
            MaplessLootPlayer mapless(player->GetSession());
            Require(!mapless.FindMap(), "The mapless loot fixture already has a map");
            Loot loot;
            sScriptMgr->OnAfterLootTemplateProcess(&loot, nullptr, store, &mapless, true, true, LOOT_MODE_DEFAULT);
            Require(loot.items.empty(), "The mapless loot hook generated an item");
            record.put("loot_items", loot.items.size());
            return;
        }
        if (auto const found = _actors.find(id); found != _actors.end())
            found->second.lastBuyOrdinal = found->second.packetOrdinal;
        uint32 spell = step.get<uint32>("spell", 0);
        if (action == "learn" || action == "unlearn" || action == "cast" || action == "cast_charm")
            Require(sSpellMgr->GetSpellInfo(spell) != nullptr, "Unknown spell: " + std::to_string(spell));
        if (action == "set_moving")
        {
            if (step.get<bool>("enabled"))
                player->AddUnitMovementFlag(MOVEMENTFLAG_FORWARD);
            else
                player->RemoveUnitMovementFlag(MOVEMENTFLAG_FORWARD);
        }
        else if (action == "stop_attack")
        {
            WorldPacket packet(CMSG_ATTACKSTOP, 0);
            player->GetSession()->HandleAttackStopOpcode(packet);
        }
        else if (action == "pvp")
        {
            bool enabled = step.get<bool>("enabled");
            WorldPacket packet(CMSG_TOGGLE_PVP, 1);
            packet << enabled;
            player->GetSession()->HandleTogglePvP(packet);
            Require(!enabled || player->IsPvP(), "Native PvP enable request did not flag the player");
            record.put("pvp_active", player->IsPvP());
        }
        else if (action == "group")
        {
            Player* member = GetPlayer(step.get<std::string>("target"));
            Require(member != player && !member->GetGroup(), "Group fixture requires an ungrouped other player");
            Group* group = player->GetGroup();
            if (!group)
            {
                group = new Group();
                if (!group->Create(player))
                {
                    delete group;
                    throw std::runtime_error("Could not create fixture group");
                }
                sGroupMgr->AddGroup(group);
            }
            if (group->IsFull() && !group->isRaidGroup())
                group->ConvertToRaid();
            Require(group->AddMember(member), "Could not join fixture group");
            if (auto method = step.get_optional<uint32>("loot_method"))
            {
                group->SetLootMethod(LootMethod(*method));
                group->SendUpdate();
            }
        }
        else if (action == "lfg_dungeon")
        {
            Group* group = player->GetGroup();
            Require(group != nullptr && !group->isLFGGroup(), "LFG dungeon fixture needs an ordinary group");
            lfg::LFGDungeonData const* dungeon = sLFGMgr->GetLFGDungeon(step.get<uint32>("dungeon"));
            Require(dungeon != nullptr, "Unknown LFG dungeon");
            group->ConvertToLFG();
            group->SetDungeonDifficulty(Difficulty(dungeon->difficulty));
            sLFGMgr->SetDungeon(group->GetGUID(), dungeon->Entry());
        }
        else if (action == "lfg_teleport")
        {
            bool out = step.get<bool>("out", false);
            WorldPacket packet(CMSG_LFG_TELEPORT, 1);
            packet << out;
            player->GetSession()->HandleLfgTeleportOpcode(packet);
            record.put("result", "teleport requested");
        }
        else if (action == "lfg_join")
        {
            std::vector<uint32> slots;
            for (auto const& [unused, dungeon] : step.get_child("dungeons"))
                slots.push_back(dungeon.get_value<uint32>());
            WorldPacket packet(CMSG_LFG_JOIN);
            packet << uint32(step.get<uint32>("roles")) << uint8(0) << uint8(0) << uint8(slots.size());
            for (uint32 slot : slots)
                packet << slot;
            packet << uint8(3) << uint8(0) << uint8(0) << uint8(0) << std::string();
            WorldPackets::LFG::LFGJoin join(std::move(packet));
            join.Read();
            player->GetSession()->HandleLfgJoinOpcode(join);
            record.put("lfg_state", uint32(sLFGMgr->GetState(player->GetGUID())));
        }
        else if (action == "lfg_set_roles")
        {
            WorldPacket packet(CMSG_LFG_SET_ROLES, 1);
            packet << uint8(step.get<uint32>("roles"));
            player->GetSession()->HandleLfgSetRolesOpcode(packet);
        }
        else if (action == "lfg_accept")
        {
            uint32 const proposal = _actors.at(id).lfgProposalId;
            Require(proposal != 0, "No Dungeon Finder proposal was offered");
            WorldPacket packet(CMSG_LFG_PROPOSAL_RESULT, 5);
            packet << proposal << true;
            player->GetSession()->HandleLfgProposalResultOpcode(packet);
            record.put("proposal", proposal);
        }
        else if (action == "lfg_final_credit")
        {
            Map* map = player->GetMap();
            Group const* group = player->GetGroup();
            Require(map != nullptr && map->IsDungeon(), "Final encounter credit needs a dungeon map");
            Require(group != nullptr && group->isLFGGroup(), "Final encounter credit needs a Dungeon Finder group");
            uint32 const dungeon = sLFGMgr->GetDungeon(group->GetGUID());
            Difficulty const difficulty = IsSharedDifficultyMap(map->GetId())
                ? Difficulty(map->GetDifficulty() % 2) : map->GetDifficulty();
            DungeonEncounterList const* encounters = sObjectMgr->GetDungeonEncounterList(map->GetId(), difficulty);
            Require(encounters != nullptr, "The dungeon has no encounters");
            auto const finalEncounter = std::find_if(encounters->begin(), encounters->end(),
                [dungeon](DungeonEncounter const* encounter) { return encounter->lastEncounterDungeon == dungeon; });
            Require(finalEncounter != encounters->end(),
                "No final encounter for Dungeon Finder dungeon " + std::to_string(dungeon));
            map->UpdateEncounterState((*finalEncounter)->creditType, (*finalEncounter)->creditEntry, nullptr);
            record.put("dungeon", dungeon);
            record.put("entry", (*finalEncounter)->creditEntry);
        }
        else if (action == "encounter_credit")
        {
            Map* map = player->GetMap();
            Require(map != nullptr && map->IsDungeon(), "Encounter credit needs a dungeon map");
            map->UpdateEncounterState(ENCOUNTER_CREDIT_KILL_CREATURE, step.get<uint32>("entry"), nullptr);
            record.put("result", "encounter credited");
        }
        else if (action == "leave_group")
        {
            Require(player->GetGroup() != nullptr, "Leave request needs a group");
            WorldPacket packet(CMSG_GROUP_DISBAND, 0);
            player->GetSession()->HandleGroupDisbandOpcode(packet);
            Require(!player->GetGroup(), "Native leave request kept the player grouped");
        }
        else if (action == "die")
        {
            Require(player->IsAlive(), "Death fixture needs a living player");
            Unit::DealDamage(player, player, player->GetHealth(), nullptr, SELF_DAMAGE, SPELL_SCHOOL_MASK_NORMAL,
                nullptr, false);
            bool const revived = step.get<bool>("revived", false);
            Require(player->IsAlive() == revived, revived ? "The death was not followed by a resurrection"
                : "Self damage did not kill the player");
        }
        else if (action == "whisper")
        {
            WorldPacket packet(CMSG_MESSAGECHAT, 64);
            packet << uint32(CHAT_MSG_WHISPER) << step.get<uint32>("language", LANG_COMMON)
                << step.get<std::string>("to") << step.get<std::string>("text");
            player->GetSession()->HandleMessagechatOpcode(packet);
            record.put("result", "whisper sent; verify delivery with assertions");
        }
        else if (action == "release_spirit")
        {
            Require(!player->IsAlive() && !player->HasPlayerFlag(PLAYER_FLAGS_GHOST),
                "Release needs an unreleased body");
            WorldPacket packet(CMSG_REPOP_REQUEST, 1);
            packet << uint8(0);
            player->GetSession()->HandleRepopRequestOpcode(packet);
            Require(player->IsAlive() || player->HasPlayerFlag(PLAYER_FLAGS_GHOST),
                "Native release request left the body unreleased");
        }
        else if (action == "command")
        {
            ChatHandler handler(player->GetSession());
            bool handled = handler.ParseCommands(CommandText(step));
            Require(handled && !handler.HasSentErrorMessage(), "Player command failed");
            record.put("result", "submitted; verify effects with assertions");
        }
        else if (action == "prepare_quest" || action == "reward_quest")
        {
            Quest const* quest = sObjectMgr->GetQuestTemplate(step.get<uint32>("quest"));
            Require(quest != nullptr, "Unknown quest template");
            if (action == "prepare_quest")
            {
                Require(!player->IsActiveQuest(quest->GetQuestId()) && player->CanAddQuest(quest, false),
                    "Cannot prepare quest fixture");
                player->AddQuestAndCheckCompletion(quest, nullptr);
                for (uint8 index = 0; index < QUEST_ITEM_OBJECTIVES_COUNT; ++index)
                    if (quest->RequiredItemId[index] && quest->RequiredItemCount[index])
                    {
                        uint32 held = player->GetItemCount(quest->RequiredItemId[index]);
                        if (held < quest->RequiredItemCount[index])
                            Require(player->AddItem(quest->RequiredItemId[index], quest->RequiredItemCount[index] - held),
                                "Cannot grant quest objective item");
                    }
                if (step.get<bool>("complete", true))
                    player->CompleteQuest(quest->GetQuestId());
            }
            else
            {
                uint32 choice = step.get<uint32>("choice", 0);
                Require(choice < QUEST_REWARD_CHOICES_COUNT && player->CanRewardQuest(quest, choice, false),
                    "Quest reward eligibility rejected");
                player->RewardQuest(quest, choice, player);
            }
        }
        else if (action == "restore_quest_spells")
            player->learnQuestRewardedSpells();
        else if (action == "login_hooks")
            sScriptMgr->OnPlayerLogin(player);
        else if (action == "open_item")
        {
            Item* item = player->GetItemByEntry(step.get<uint32>("item"));
            Require(item != nullptr, "Item must be granted before opening");
            WorldPacket request(CMSG_OPEN_ITEM, 2);
            request << item->GetBagSlot() << item->GetSlot();
            if (sScriptMgr->CanPacketReceive(player->GetSession(), request))
                player->GetSession()->HandleOpenItemOpcode(request);
        }
        else if (action == "set_phase")
            player->SetPhaseMask(step.get<uint32>("value", _phase), true);
        else if (action == "set_money")
            player->SetMoney(step.get<uint32>("value"));
        else if (action == "use_nearby_gameobject")
        {
            std::list<GameObject*> objects;
            player->GetGameObjectListWithEntryInGrid(objects, step.get<uint32>("entry"), 20.0f);
            objects.remove_if([player](GameObject* object)
            {
                return !object->IsInWorld() || !player->InSamePhase(object);
            });
            Require(objects.size() == 1, "Nearby gameobject use needs exactly one object");
            WorldPacket packet(CMSG_GAMEOBJ_USE, 8);
            packet << objects.front()->GetGUID();
            if (sScriptMgr->CanPacketReceive(player->GetSession(), packet))
                player->GetSession()->HandleGameObjectUseOpcode(packet);
        }
        else if (action == "attack_nearby" || action == "loot_nearby")
        {
            std::list<Creature*> creatures;
            player->GetCreatureListWithEntryInGrid(creatures, step.get<uint32>("entry"), 40.0f);
            size_t found = creatures.size();
            creatures.remove_if([player, &action](Creature* creature)
            {
                return !creature->IsInWorld() || (action == "attack_nearby") != creature->IsAlive();
            });
            Require(!creatures.empty(), "No matching nearby creature among " + std::to_string(found));
            WorldPacket packet(action == "attack_nearby" ? CMSG_ATTACKSWING : CMSG_LOOT, 8);
            packet << creatures.front()->GetGUID();
            if (action == "attack_nearby")
            {
                Require(player->IsValidAttackTarget(creatures.front()), "Invalid melee attack target");
                if (step.get<bool>("kill", false))
                {
                    Unit::DealDamage(player, creatures.front(), creatures.front()->GetMaxHealth() * 100u, nullptr, DIRECT_DAMAGE,
                        SPELL_SCHOOL_MASK_NORMAL);
                    Require(!creatures.front()->IsAlive(),
                        "Killing blow did not kill, health left " + std::to_string(creatures.front()->GetHealth()));
                }
                else if (auto damagePct = step.get_optional<int32>("damage_pct"))
                {
                    Require(*damagePct > 0 && *damagePct < 100, "Damage share outside (0, 100)");
                    Unit::DealDamage(player, creatures.front(), creatures.front()->CountPctFromMaxHealth(*damagePct),
                        nullptr, DIRECT_DAMAGE, SPELL_SCHOOL_MASK_NORMAL);
                }
                else
                    player->GetSession()->HandleAttackSwingOpcode(packet);
            }
            else
            {
                player->UpdatePosition(creatures.front()->GetPositionX(), creatures.front()->GetPositionY(),
                    creatures.front()->GetPositionZ(), player->GetOrientation(), true);
                if (sScriptMgr->CanPacketReceive(player->GetSession(), packet))
                    player->GetSession()->HandleLootOpcode(packet);
            }
        }
        else if (action == "loot_creature")
        {
            Unit* target = GetUnit(step.get<std::string>("target"));
            WorldPacket packet(CMSG_LOOT, 8);
            packet << target->GetGUID();
            if (sScriptMgr->CanPacketReceive(player->GetSession(), packet))
                player->GetSession()->HandleLootOpcode(packet);
        }
        else if (action == "loot_slot")
        {
            uint32 slot = step.get<uint32>("slot", 0);
            if (auto entry = step.get_optional<uint32>("item"))
            {
                Loot* source = nullptr;
                if (Creature* creature = player->GetMap()->GetCreature(player->GetLootGUID()))
                    source = &creature->loot;
                else if (GameObject* chest = player->GetMap()->GetGameObject(player->GetLootGUID()))
                    source = &chest->loot;
                Require(source != nullptr, "Item-selected loot needs an open creature corpse or chest");
                Loot& loot = *source;
                slot = loot.GetMaxSlotInLootFor(player);
                for (uint32 candidate = 0; candidate < loot.GetMaxSlotInLootFor(player); ++candidate)
                    if (LootItem* item = loot.LootItemInSlot(candidate, player))
                        if (item->itemid == *entry || ItemScaling::BaseEntry(item->itemid) == *entry)
                        {
                            slot = candidate;
                            break;
                        }
                Require(slot < loot.GetMaxSlotInLootFor(player), "Requested item is not in this player's loot");
            }
            WorldPacket packet(CMSG_AUTOSTORE_LOOT_ITEM, 1);
            packet << uint8(slot);
            if (sScriptMgr->CanPacketReceive(player->GetSession(), packet))
                player->GetSession()->HandleAutostoreLootItemOpcode(packet);
        }
        else if (action == "loot_money")
        {
            WorldPacket packet(CMSG_LOOT_MONEY, 0);
            if (sScriptMgr->CanPacketReceive(player->GetSession(), packet))
                player->GetSession()->HandleLootMoneyOpcode(packet);
        }
        else if (action == "close_loot")
        {
            WorldPacket request(CMSG_LOOT_RELEASE, 8);
            request << player->GetLootGUID();
            player->GetSession()->HandleLootReleaseOpcode(request);
        }
        else if (action == "collect_loot")
        {
            Item* container = player->GetItemByGuid(player->GetLootGUID());
            Require(container && !container->loot.items.empty(), "No open item loot");
            LootItem const& loot = container->loot.items.front();
            Require(!loot.is_looted && loot.count, "First loot slot is unavailable");
            uint32 entry = loot.itemid;
            uint32 expected = loot.count;
            uint32 before = player->GetItemCount(entry);
            WorldPacket request(CMSG_AUTOSTORE_LOOT_ITEM, 1);
            request << uint8(0);
            player->GetSession()->HandleAutostoreLootItemOpcode(request);
            uint32 after = player->GetItemCount(entry);
            Require(after == before + expected, "Loot did not reach the player's inventory");
            _actors.at(id).lootReceived = after - before;
            record.put("item", entry);
            record.put("received", after - before);
        }
        else if (action == "area_trigger")
        {
            WorldPacket packet(CMSG_AREATRIGGER, 4);
            packet << step.get<uint32>("id");
            player->GetSession()->HandleAreaTriggerOpcode(packet);
        }
        else if (action == "banker_activate")
        {
            ObjectGuid guid;
            if (auto target = step.get_optional<std::string>("target"))
                guid = GetUnit(*target)->GetGUID();
            else if (auto owner = step.get_optional<std::string>("owner"))
            {
                Creature* owned = GetOwnedCreature(GetPlayer(*owner), step.get<uint32>("entry"));
                Require(owned != nullptr, "That actor has no creature of that entry out");
                guid = owned->GetGUID();
            }
            else
            {
                Creature* companion = player->GetGuardianPet();
                if (!companion)
                    companion = player->GetCompanionPet();
                if (!companion && player->GetCritterGUID())
                    companion = ObjectAccessor::GetCreatureOrPetOrVehicle(*player, player->GetCritterGUID());
                Require(companion != nullptr, "Banker activate needs a target or a summoned companion");
                guid = companion->GetGUID();
            }
            if (Creature* clicked = ObjectAccessor::GetCreatureOrPetOrVehicle(*player, guid))
                if (!clicked->IsWithinDistInMap(player, INTERACTION_DISTANCE))
                    player->UpdatePosition(clicked->GetPositionX(), clicked->GetPositionY(),
                                           clicked->GetPositionZ(), player->GetOrientation(), true);

            WorldPacket packet(CMSG_BANKER_ACTIVATE, 8);
            packet << guid;
            player->GetSession()->HandleBankerActivateOpcode(packet);
        }
        else if (action == "personal_bank_open" || action == "personal_bank_swap")
        {
            GameObject* vault = player->FindNearestGameObject(step.get<uint32>("entry"), 20.0f);
            Require(vault != nullptr, "No bank object of that entry within 20 yards");
            if (action == "personal_bank_open")
            {
                WorldPacket packet(CMSG_GUILD_BANKER_ACTIVATE, 9);
                packet << vault->GetGUID() << uint8(1);
                sScriptMgr->CanPacketReceive(player->GetSession(), packet);
            }
            else
            {
                uint8 const bankSlot = uint8(step.get<uint32>("slot", 0));
                int32 const count = step.get<int32>("count", 0);
                std::string const direction = step.get<std::string>("direction");
                Require(direction == "deposit" || direction == "withdraw",
                        "Personal bank swap direction must be deposit or withdraw");
                WorldPacket packet(CMSG_GUILD_BANK_SWAP_ITEMS, 32);
                packet << vault->GetGUID() << uint8(0) << uint8(0) << bankSlot;
                if (direction == "deposit")
                {
                    Item* item = player->GetItemByEntry(step.get<uint32>("item"));
                    Require(item != nullptr, "The player carries no item of that entry");
                    packet << uint32(item->GetEntry()) << uint8(0) << uint8(item->GetBagSlot())
                           << uint8(item->GetSlot()) << uint8(0) << count;
                }
                else if (auto inventorySlot = step.get_optional<uint8>("inventory_slot"))
                    packet << uint32(0) << uint8(0) << uint8(INVENTORY_SLOT_BAG_0)
                           << *inventorySlot << uint8(1) << count;
                else
                    packet << uint32(0) << uint8(1) << int32(0) << uint8(0) << count;
                sScriptMgr->CanPacketReceive(player->GetSession(), packet);
            }
            record.put("result", "submitted; verify the answer with assertions");
        }
        else if (action == "binder_activate")
        {
            Unit* innkeeper = GetUnit(step.get<std::string>("target"));
            if (!innkeeper->IsWithinDistInMap(player, INTERACTION_DISTANCE))
                player->UpdatePosition(innkeeper->GetPositionX(), innkeeper->GetPositionY(),
                                       innkeeper->GetPositionZ(), player->GetOrientation(), true);
            WorldPacket packet(CMSG_BINDER_ACTIVATE, 8);
            packet << innkeeper->GetGUID();
            player->GetSession()->HandleBinderActivateOpcode(packet);
        }
        else if (action == "destroy_item")
        {
            Item* item = player->GetItemByEntry(step.get<uint32>("item"));
            Require(item != nullptr, "The player carries no item of that entry");
            WorldPacket packet(CMSG_DESTROYITEM, 6);
            packet << uint8(item->GetBagSlot()) << uint8(item->GetSlot()) << uint8(0)
                   << uint8(0) << uint8(0) << uint8(0);
            WorldPackets::Item::DestroyItem request(std::move(packet));
            request.Read();
            player->GetSession()->HandleDestroyItemOpcode(request);
        }
        else if (action == "start_challenge")
        {
            WorldPacket packet(CMSG_COA_START_CHALLENGE, 8);
            packet << uint32(step.get<uint32>("challenge")) << uint32(step.get<uint32>("level"));
            sScriptMgr->CanPacketReceive(player->GetSession(), packet);
            record.put("result", "submitted; verify the answer with assertions");
        }
        else if (action == "stop_challenge")
        {
            WorldPacket packet(CMSG_COA_STOP_CHALLENGE, 4);
            packet << uint32(step.get<uint32>("challenge"));
            sScriptMgr->CanPacketReceive(player->GetSession(), packet);
            record.put("result", "submitted; verify the answer with assertions");
        }
        else if (action == "gossip_hello")
        {
            ObjectGuid guid = step.get_optional<std::string>("target") ?
                GetUnit(step.get<std::string>("target"))->GetGUID() : player->GetCritterGUID();
            Require(!guid.IsEmpty(), "Gossip needs a target or summoned companion");
            player->PlayerTalkClass->ClearMenus();
            WorldPacket packet(CMSG_GOSSIP_HELLO, 8);
            packet << guid;
            player->GetSession()->HandleGossipHelloOpcode(packet);
        }
        else if (action == "gossip_select")
        {
            auto const& menu = player->PlayerTalkClass->GetGossipMenu();
            WorldPacket packet(CMSG_GOSSIP_SELECT_OPTION, 16);
            packet << menu.GetSenderGUID() << menu.GetMenuId() << step.get<uint32>("option");
            if (auto const code = step.get_optional<std::string>("code"))
                packet << *code;
            else if (auto const codeActor = step.get_optional<std::string>("code_actor"))
                packet << _actors.at(*codeActor).name;
            player->GetSession()->HandleGossipSelectOptionOpcode(packet);
        }
        else if (action == "sell_item")
        {
            Creature* vendor = GetGiver(player, step.get<uint32>("entry"));
            Require(vendor != nullptr, "No vendor of that entry is within reach of the player");
            Item* item = player->GetItemByEntry(step.get<uint32>("item"));
            Require(item != nullptr, "The player carries no item of that entry");
            WorldPacket packet(CMSG_SELL_ITEM, 20);
            packet << vendor->GetGUID() << item->GetGUID() << uint32(step.get<uint32>("count", 0));
            WorldPackets::Item::SellItem request(std::move(packet));
            request.Read();
            player->GetSession()->HandleSellItemOpcode(request);
        }
        else if (action == "who")
        {
            sWhoListCacheMgr->Update();
            WorldPacket request(CMSG_WHO, 32);
            std::string name;
            if (auto target = step.get_optional<std::string>("target"))
                name = _actors.at(*target).name;
            request << uint32(1) << uint32(255) << name << std::string();
            request << step.get<uint32>("race_mask", UINT32_MAX) << step.get<uint32>("class_mask", UINT32_MAX);
            request << uint32(0) << uint32(0);
            uint32 before = _actors.at(step.get<std::string>("actor")).whoResponses;
            player->GetSession()->HandleWhoOpcode(request);
            Require(_actors.at(step.get<std::string>("actor")).whoResponses == before + 1,
                "Who request did not produce a native response");
        }
        else if (action == "summon")
        {
            std::string id = step.get<std::string>("as");
            Require(!_actors.count(id) && !_targets.count(id), "Duplicate actor id");
            Position position = player->GetPosition();
            position.m_positionX += step.get<float>("distance", 5);
            TempSummon* creature = player->SummonCreature(step.get<uint32>("entry"), position, TEMPSUMMON_MANUAL_DESPAWN);
            Require(creature != nullptr, "Could not summon creature: " + id);
            creature->SetPhaseMask(player->GetPhaseMask(), true);
            _targets.emplace(id, Target{ creature->GetMapId(), creature->GetInstanceId(), creature->GetGUID() });
            record.put("result", creature->GetCreatureTemplate()->Entry);
        }
        else if (action == "attack")
        {
            Unit* target = GetUnit(step.get<std::string>("target"));
            Require(player->IsValidAttackTarget(target), "Invalid melee attack target");
            if (step.get<bool>("pet", false))
            {
                Pet* pet = player->GetPet();
                Require(pet != nullptr, "Pet attack requires a current pet");
                WorldPacket packet(CMSG_PET_ACTION, 20);
                packet << pet->GetGUID() << uint32(COMMAND_ATTACK | (uint32(ACT_COMMAND) << 24)) << target->GetGUID();
                player->GetSession()->HandlePetAction(packet);
            }
            else
            {
                WorldPacket packet(CMSG_ATTACKSWING, 8);
                packet << target->GetGUID();
                player->GetSession()->HandleAttackSwingOpcode(packet);
            }
        }
        else if (action == "cancel_aura")
        {
            Require(sSpellMgr->GetSpellInfo(spell) != nullptr, "Unknown aura cancellation spell");
            WorldPacket packet(CMSG_CANCEL_AURA, 4);
            packet << spell;
            player->GetSession()->HandleCancelAuraOpcode(packet);
        }
        else if (action == "cancel_mount")
        {
            WorldPacket packet(CMSG_CANCEL_MOUNT_AURA, 0);
            player->GetSession()->HandleCancelMountAuraOpcode(packet);
        }
        else if (action == "set_aura")
        {
            Unit* recipient = player;
            if (step.get<bool>("pet", false))
                recipient = player->GetGuardianPet();
            if (auto entry = step.get_optional<uint32>("owned_entry"))
                recipient = GetOwnedCreature(player, *entry);
            Require(recipient != nullptr, "Aura fixture requires its selected player, pet or owned creature");
            SpellInfo const* info = sSpellMgr->GetSpellInfo(spell);
            Require(info != nullptr, "Unknown fixture aura");
            uint32 stacks = step.get<uint32>("stacks");
            Require(stacks <= std::max<uint32>(1, info->CalcMaxAuraStacks(recipient)),
                "Fixture aura exceeds its stack limit");
            if (!stacks)
                recipient->RemoveAurasDueToSpell(spell);
            else
            {
                Aura* aura = recipient->GetAura(spell);
                if (!aura)
                    aura = recipient->AddAura(spell, recipient);
                Require(aura != nullptr, "Could not apply fixture aura");
                aura->SetStackAmount(uint8(stacks));
            }
        }
        else if (action == "money")
        {
            int32 const copper = step.get<int32>("copper");
            Require(copper > 0, "Money fixture needs a positive copper amount");
            player->ModifyMoney(copper);
            Require(player->GetMoney() >= uint32(copper), "Money fixture failed");
        }
        else if (action == "grant_resource")
        {
            int32 amount = int32(step.get<int32>("amount", 1));
            Require(HandleAscensionReaperResource(player, spell, amount),
                "Resource spell does not belong to this class");
        }
        else if (action == "set_action_button")
        {
            uint8 button = uint8(step.get<uint32>("button"));
            uint32 const barSpell = step.get_optional<uint32>("wildcard_slot")
                ? WildcardSpell(WildcardSlot(player, step.get<uint32>("wildcard_slot"))) : spell;
            Require(player->addActionButton(button, barSpell, ACTION_BUTTON_SPELL) != nullptr,
                "Action button could not be set");
        }
        else if (action == "learn")
        {
            player->learnSpell(spell);
            Require(player->HasSpell(spell), "Spell learning failed");
        }
        else if (action == "unlearn")
            player->removeSpell(spell, step.get<bool>("all_specs", false) ? SPEC_MASK_ALL :
                player->GetActiveSpecMask(), false);
        else if (action == "pet_autocast")
        {
            Pet* pet = player->GetPet();
            Require(pet != nullptr, "Pet autocast request needs a current pet");
            WorldPacket packet(CMSG_PET_SPELL_AUTOCAST, 13);
            packet << pet->GetGUID() << spell << step.get<bool>("enabled");
            WorldPackets::Pet::PetSpellAutocast request(std::move(packet));
            request.Read();
            player->GetSession()->HandlePetSpellAutocastOpcode(request);
        }
        else if (action == "trainer_buy")
        {
            Unit* trainer = step.get_optional<std::string>("target")
                ? GetUnit(step.get<std::string>("target")) : nullptr;
            ObjectGuid guid = trainer ? trainer->GetGUID() : player->GetCritterGUID();
            Require(!guid.IsEmpty(), "Trainer purchase needs a trainer");
            Require(spell != 0, "Trainer purchase needs a spell");

            WorldPacket packet(CMSG_TRAINER_BUY_SPELL, 12);
            packet << guid << int32(spell);
            if (sScriptMgr->CanPacketReceive(player->GetSession(), packet))
            {
                WorldPacket purchase(packet);
                WorldPackets::NPC::TrainerBuySpell request(std::move(purchase));
                request.Read();
                player->GetSession()->HandleTrainerBuySpellOpcode(request);
            }
        }
        else if (action == "talent")
        {
            uint32 rank = step.get<uint32>("rank");
            auto* talent = sTalentStore.LookupEntry(step.get<uint32>("talent"));
            Require(talent && rank < MAX_TALENT_RANK && talent->RankID[rank], "Invalid talent/rank");
            player->LearnTalent(talent->TalentID, rank, step.get<bool>("command", false));
            Require(player->HasTalent(talent->RankID[rank], player->GetActiveSpec()), "Talent learning rejected");
        }
        else if (action == "reset_talents")
        {
            player->resetTalents(true);
            Require(player->GetFreeTalentPoints() == player->CalculateTalentsPoints(), "Talent reset rejected");
        }
        else if (action == "cast" || action == "cast_charm" || action == "use_item")
        {
            _actors.at(step.get<std::string>("actor")).castFailureReason.erase(spell);
            SpellCastTargets targets;
            Unit* caster = action != "cast_charm" ? player :
                step.get<bool>("pet", false) ? static_cast<Unit*>(player->GetPet()) : player->GetCharm();
            Require(caster != nullptr, "Player has no charmed unit or pet");
            Unit* target = step.get_optional<std::string>("target") ? GetUnit(step.get<std::string>("target")) : caster;
            if (step.get<bool>("target_pet", false))
            {
                target = player->GetPet();
                Require(target != nullptr, "Cast at a pet needs a current pet");
            }
            if (auto targetItem = step.get_optional<uint32>("target_item"))
            {
                Item* item = player->GetItemByEntry(*targetItem);
                Require(item != nullptr, "Target item is missing");
                targets.SetItemTarget(item);
            }
            else if (auto targetObject = step.get_optional<uint32>("target_gameobject"))
            {
                GameObject* object = player->FindNearestGameObject(*targetObject, 20.0f);
                Require(object != nullptr, "Target gameobject is not nearby");
                targets.SetGOTarget(object);
            }
            else
                targets.SetUnitTarget(target);
            if (auto destination = step.get_child_optional("destination"))
                targets.SetDst(destination->get<float>("x"), destination->get<float>("y"),
                    destination->get<float>("z"), caster->GetOrientation());
            record.put("spell_active", caster->IsPlayer() ? caster->ToPlayer()->HasActiveSpell(spell) :
                caster->HasSpell(spell));
            record.put("line_of_sight", caster->IsWithinLOSInMap(target));
            record.put("target_visible", caster->CanSeeOrDetect(target));
            record.put("target_friendly", caster->IsFriendlyTo(target));
            record.put("caster_faction", caster->GetFaction());
            record.put("target_faction", target->GetFaction());
            if (SpellInfo const* info = sSpellMgr->GetSpellInfo(spell))
                record.put("target_check", uint32(info->CheckTarget(caster, target, false)));
            WorldPacket packet(action == "cast" ? CMSG_CAST_SPELL :
                action == "cast_charm" ? CMSG_PET_CAST_SPELL : CMSG_USE_ITEM, 64);
            if (action == "cast" || action == "cast_charm")
            {
                if (action == "cast_charm")
                    packet << caster->GetGUID();
                packet << uint8(++_castCount) << spell << uint8(0);
            }
            else
            {
                Item* item = player->GetItemByEntry(step.get<uint32>("item"));
                Require(item != nullptr, "Item is missing");
                packet << item->GetBagSlot() << item->GetSlot() << uint8(++_castCount) << spell;
                packet << item->GetGUID() << uint32(0) << uint8(0);
            }
            targets.Write(packet);
            if (action == "cast")
                player->GetSession()->HandleCastSpellOpcode(packet);
            else if (action == "cast_charm")
                player->GetSession()->HandlePetCastSpellOpcode(packet);
            else
                player->GetSession()->HandleUseItemOpcode(packet);
            record.put("result", "submitted; verify effects with assertions");
        }
        else if (action == "use_gameobject")
        {
            std::list<GameObject*> objects = OwnedGameObjects(player, step.get<uint32>("entry"));
            Require(objects.size() == 1, "Gameobject use needs exactly one owned object");
            WorldPacket packet(CMSG_GAMEOBJ_USE, 8);
            packet << objects.front()->GetGUID();
            player->GetSession()->HandleGameObjectUseOpcode(packet);
            record.put("result", "submitted; verify effects with assertions");
        }
        else if (action == "summon_gameobject")
        {
            uint32 const entry = step.get<uint32>("entry");
            Require(OwnedGameObjects(player, entry).empty(), "The player already owns this gameobject");
            float const distance = step.get<float>("distance", 2.0f);
            float const angle = player->GetOrientation();
            GameObject* object = player->SummonGameObject(entry, player->GetPositionX() + distance * std::cos(angle),
                player->GetPositionY() + distance * std::sin(angle), player->GetPositionZ(), angle, 0.0f, 0.0f, 0.0f,
                0.0f, step.get<uint32>("duration_s", 300));
            Require(object != nullptr, "Gameobject summon failed");
        }
        else if (action == "loot_gameobject")
        {
            std::list<GameObject*> objects = OwnedGameObjects(player, step.get<uint32>("entry"));
            Require(objects.size() == 1, "Gameobject loot needs exactly one owned object");
            Require(objects.front()->GetGoType() == GAMEOBJECT_TYPE_CHEST, "Gameobject loot needs a chest");
            player->SendLoot(objects.front()->GetGUID(), LOOT_SKINNING);
            Require(player->GetLootGUID() == objects.front()->GetGUID(), "The chest did not open its loot");
        }
        else if (action == "add_item")
            Require(player->AddItem(step.get<uint32>("item"), step.get<uint32>("count", 1)), "Item grant failed");
        else if (action == "fill_bags")
        {
            uint32 const target = step.get<uint32>("slots", 0);
            uint32 filled = 0;
            for (auto const& stored : *sObjectMgr->GetItemTemplateStore())
            {
                if (player->GetFreeInventorySpace() <= target)
                    break;

                ItemTemplate const& proto = stored.second;
                if (proto.Class != ITEM_CLASS_ARMOR || proto.GetMaxStackSize() > 1 ||
                    proto.MaxCount > 0 || proto.ItemLevel < 1 || player->GetItemCount(stored.first))
                    continue;

                if (player->AddItem(stored.first, 1))
                    ++filled;
            }
            Require(player->GetFreeInventorySpace() <= target,
                "The bags could not be filled for the full inventory fixture");
            LOG_DEBUG("coa", "gameplay test filled {} bag slots for {}",
                filled, player->GetGUID().ToString());
        }
        else if (action == "equip")
        {
            Item* item = player->GetItemByEntry(step.get<uint32>("item"));
            Require(item != nullptr, "Item must be granted before equipping");
            uint32 slot = step.get<uint32>("slot");
            Require(slot < INVENTORY_SLOT_BAG_END, "Invalid equipment slot");
            WorldPacket packet(CMSG_AUTOEQUIP_ITEM_SLOT, 9);
            packet << item->GetGUID() << uint8(slot);
            WorldPackets::Item::AutoEquipItemSlot request(std::move(packet));
            request.Read();
            Require(request.ItemGuid == item->GetGUID() && request.DestinationSlot == slot,
                "Equipment packet did not round-trip");
            player->GetSession()->HandleAutoEquipItemSlotOpcode(request);
            if (step.get<bool>("rejected", false))
            {
                Require(player->GetItemByPos(INVENTORY_SLOT_BAG_0, uint8(slot)) != item,
                    "Equipment change was expected to be rejected");
                uint16 destination = 0;
                record.put("result", std::to_string(player->CanEquipItem(uint8(slot), destination, item, true)));
            }
            else if (player->GetItemByPos(INVENTORY_SLOT_BAG_0, uint8(slot)) != item)
            {
                uint16 destination = 0;
                InventoryResult equip = player->CanEquipItem(uint8(slot), destination, item, true);
                InventoryResult unequip = player->CanUnequipItem(uint16(INVENTORY_SLOT_BAG_0 << 8) | slot, true);
                throw std::runtime_error("Equipment change rejected: equip error " + std::to_string(equip)
                    + ", unequip error " + std::to_string(unequip) + ", combat "
                    + std::to_string(player->IsInCombat()) + ", casting "
                    + std::to_string(player->IsNonMeleeSpellCast(false)));
            }
        }
        else if (action == "set_skill")
        {
            uint32 const skill = step.get<uint32>("skill");
            Require(sSkillLineStore.LookupEntry(skill) != nullptr, "Unknown fixture skill");
            player->SetSkill(skill, 1, step.get<uint16>("value"), step.get<uint16>("maximum"));
        }
        else if (action == "gather_skill")
        {
            uint32 const skill = step.get<uint32>("skill");
            player->UpdateGatherSkill(skill, player->GetPureSkillValue(skill), step.get<uint32>("required"));
        }
        else if (action == "set_xp_enabled")
        {
            if (step.get<bool>("enabled"))
                player->RemovePlayerFlag(PLAYER_FLAGS_NO_XP_GAIN);
            else
                player->SetPlayerFlag(PLAYER_FLAGS_NO_XP_GAIN);
        }
        else if (action == "set_level")
        {
            uint32 const level = step.get<uint32>("value");
            Require(level >= 1 && level <= 80, "Invalid fixture level");
            player->GiveLevel(uint8(level));
        }
        else if (action == "reset_cooldown")
        {
            uint32 spell = step.get<uint32>("spell");
            Require(sSpellMgr->GetSpellInfo(spell) != nullptr, "Unknown cooldown fixture spell");
            player->RemoveSpellCooldown(spell, true);
        }
        else if (action == "restore_charges")
        {
            uint32 spell = step.get<uint32>("spell");
            SpellInfo const* info = sSpellMgr->GetSpellInfo(spell);
            Require(info && info->MaxCharges, "Charge fixture needs a spell with native charges");
            player->RestoreSpellCharge(spell, info->MaxCharges);
        }
        else if (action == "set_health")
        {
            Unit* target = player;
            if (step.get<bool>("pet", false))
            {
                target = player->GetPet();
                Require(target != nullptr, "Health fixture needs a current pet");
            }
            uint32 health = step.get<uint32>("value");
            if (auto maximum = step.get_optional<uint32>("maximum"))
            {
                Require(*maximum > 0 && *maximum <= INT32_MAX && health <= *maximum,
                    "Invalid maximum health fixture");
                target->SetMaxHealth(*maximum);
            }
            Require(health > 0 && health <= target->GetMaxHealth(), "Health fixture outside valid range");
            target->SetHealth(health);
        }
        else if (action == "set_power")
        {
            Unit* target = player;
            if (step.get<bool>("pet", false))
            {
                target = player->GetPet();
                Require(target != nullptr, "Power fixture needs a current pet");
            }
            uint32 power = step.get<uint32>("power", POWER_MANA);
            Require(power < MAX_POWERS, "Invalid power index");
            uint32 value = step.get<uint32>("value");
            Require(value <= target->GetMaxPower(Powers(power)), "Power fixture exceeds maximum");
            target->SetPower(Powers(power), value);
        }
        else if (action == "ascension_dungeon_difficulty_packet")
        {
            uint32 const difficulty = step.get<uint32>("value");
            Require(difficulty < MAX_DUNGEON_DIFFICULTY, "Invalid dungeon difficulty");
            WorldPacket packet(CMSG_COA_SET_DUNGEON_DIFFICULTY, 1);
            packet << uint8(difficulty);
            Require(!sScriptMgr->CanPacketReceiveEarly(player->GetSession(), packet),
                "Ascension dungeon difficulty request was not consumed");
            WorldSessionFilter filter(player->GetSession());
            player->GetSession()->Update(0, filter);
        }
        else if (action == "dungeon_difficulty_packet")
        {
            uint32 const difficulty = step.get<uint32>("value");
            Require(difficulty < MAX_DUNGEON_DIFFICULTY, "Invalid dungeon difficulty");
            WorldPacket packet(MSG_SET_DUNGEON_DIFFICULTY, 4);
            packet << difficulty;
            if (sScriptMgr->CanPacketReceive(player->GetSession(), packet))
            {
                WorldPackets::Instance::SetDungeonDifficultyClient request(std::move(packet));
                request.Read();
                player->GetSession()->HandleSetDungeonDifficultyOpcode(request);
            }
        }
        else if (action == "teleport")
        {
            uint32 map = step.get<uint32>("map");
            float x = step.get<float>("x");
            float y = step.get<float>("y");
            float z = step.get<float>("z");
            float o = step.get<float>("o", 0.0f);
            Require(sMapStore.LookupEntry(map) != nullptr, "Unknown map to teleport to");
            player->TeleportTo(map, x, y, z, o);
            record.put("result", "teleport sent");
        }
        else if (action == "teleport_to_spawn")
        {
            ObjectGuid::LowType const spawnId = step.get<ObjectGuid::LowType>("guid");
            CreatureData const* spawn = sObjectMgr->GetCreatureData(spawnId);
            Require(spawn != nullptr, "Unknown creature spawn to teleport to");
            Position destination(spawn->posX, spawn->posY, spawn->posZ, spawn->orientation);
            if (spawn->mapid == player->GetMapId())
            {
                auto const spawned = player->GetMap()->GetCreatureBySpawnIdStore().equal_range(spawnId);
                if (spawned.first != spawned.second && spawned.first->second->IsInWorld())
                    destination = spawned.first->second->GetPosition();
            }
            player->TeleportTo(spawn->mapid, destination.GetPositionX(), destination.GetPositionY(),
                destination.GetPositionZ(), destination.GetOrientation());
            record.put("result", "teleport sent");
        }
        else if (action == "discover_taxi_node")
        {
            uint32 const node = step.get<uint32>("entry");
            Require(sTaxiNodesStore.LookupEntry(node) != nullptr, "Unknown taxi node");
            player->m_taxi.SetTaximaskNode(node);
        }
        else if (action == "quest_accept" || action == "quest_turn_in")
        {
            uint32 quest = step.get<uint32>("quest");
            Require(sObjectMgr->GetQuestTemplate(quest) != nullptr, "Unknown quest");

            WorldObject* giver = GetQuestGiver(player, step);
            Require(giver != nullptr, "No giver of that entry is within reach of the player");

            if (action == "quest_turn_in")
            {
                WorldPacket request(CMSG_QUESTGIVER_REQUEST_REWARD, 16);
                request << giver->GetGUID() << quest;
                _actors.at(id).lastQuestWindow = 0;
                bool const openToCore = sScriptMgr->CanPacketReceive(player->GetSession(), request);
                record.put("request_handled_by_script", !openToCore);
                if (openToCore)
                    player->GetSession()->HandleQuestgiverRequestRewardOpcode(request);

                if (!openToCore)
                {
                    uint32 const window = _actors.at(id).lastQuestWindow;
                    record.put("window_after_claim", window == SMSG_QUESTGIVER_OFFER_REWARD
                        ? "SMSG_QUESTGIVER_OFFER_REWARD" : "not the reward window");
                    Require(window == SMSG_QUESTGIVER_OFFER_REWARD,
                        "Claiming the reward did not open the reward window");
                }

                WorldPacket choose(CMSG_QUESTGIVER_CHOOSE_REWARD, 16);
                choose << giver->GetGUID() << quest << step.get<uint32>("reward", 0);
                bool const chooseToCore = sScriptMgr->CanPacketReceive(player->GetSession(), choose);
                record.put("reward_handled_by_script", !chooseToCore);
                if (chooseToCore)
                    player->GetSession()->HandleQuestgiverChooseRewardOpcode(choose);
            }
            else
            {
                WorldPacket packet(CMSG_QUESTGIVER_ACCEPT_QUEST, 16);
                packet << giver->GetGUID() << quest << uint32(0);
                bool const openToCore = sScriptMgr->CanPacketReceive(player->GetSession(), packet);
                record.put("accept_handled_by_script", !openToCore);
                if (openToCore)
                    player->GetSession()->HandleQuestgiverAcceptQuestOpcode(packet);
            }

            record.put("result", "dispatched as the server's packet loop does");
        }
        else if (action == "quest_open")
        {
            uint32 quest = step.get<uint32>("quest");
            Require(sObjectMgr->GetQuestTemplate(quest) != nullptr, "Unknown quest");

            Creature* giver = GetGiver(player, step.get<uint32>("entry"));
            Require(giver != nullptr, "No giver of that entry is within reach of the player");

            WorldPacket packet(CMSG_QUESTGIVER_QUERY_QUEST, 16);
            packet << giver->GetGUID() << quest << uint8(0);
            bool const openToCore = sScriptMgr->CanPacketReceive(player->GetSession(), packet);
            record.put("query_handled_by_script", !openToCore);
            Require(!openToCore, "A click on a listed name reached the core instead of the giver's script");
        }
        else if (action == "quest_click")
        {
            uint32 quest = step.get<uint32>("quest");
            Require(sObjectMgr->GetQuestTemplate(quest) != nullptr, "Unknown quest");

            Creature* giver = GetGiver(player, step.get<uint32>("entry"));
            Require(giver != nullptr, "No giver of that entry is within reach of the player");

            WorldPacket packet(CMSG_QUESTGIVER_COMPLETE_QUEST, 16);
            packet << giver->GetGUID() << quest;
            _actors.at(id).lastQuestWindow = 0;
            bool const clickToCore = sScriptMgr->CanPacketReceive(player->GetSession(), packet);
            record.put("click_handled_by_script", !clickToCore);
            Require(!clickToCore, "A click on a carried name reached the core instead of the giver's script");

            uint32 const window = _actors.at(id).lastQuestWindow;
            record.put("window_after_click", window == SMSG_QUESTGIVER_OFFER_REWARD ? "SMSG_QUESTGIVER_OFFER_REWARD"
                : window == SMSG_QUESTGIVER_REQUEST_ITEMS ? "SMSG_QUESTGIVER_REQUEST_ITEMS" : "no window");
            Require(window == SMSG_QUESTGIVER_OFFER_REWARD || window == SMSG_QUESTGIVER_REQUEST_ITEMS,
                "A click on a carried name was answered with no quest window");
        }
        else if (action == "quest_complete")
        {
            uint32 quest = step.get<uint32>("quest");
            Require(sObjectMgr->GetQuestTemplate(quest) != nullptr, "Unknown quest");
            player->CompleteQuest(quest);
            record.put("result", "quest marked complete as a fixture");
        }
        else
            throw std::runtime_error("Unknown action: " + action);
    }

    static AscensionCoATalentState::HasSpell SpellbookOf(Player const* player)
    {
        return [player](uint32 spellId) { return player->HasSpell(spellId); };
    }

    static std::vector<AscensionCoATalentState::KnownEntry> KnownEntriesWithRank(Player const* player, uint32 entryId,
        uint32 rank)
    {
        std::vector<AscensionCoATalentState::KnownEntry> known = GetAscensionKnownTalentEntries(player);
        std::erase_if(known, [entryId](AscensionCoATalentState::KnownEntry const& item)
        {
            return item.EntryId == entryId;
        });
        if (rank)
            known.push_back({ entryId, rank });
        return known;
    }

    static WorldPacket KnownEntriesUpload(std::vector<AscensionCoATalentState::KnownEntry> const& known)
    {
        std::vector<uint8> const body = AscensionCoATalentState::KnownEntriesPayload(known);
        WorldPacket upload(KnownEntriesUploadOpcode, body.size());
        upload.append(body.data(), body.size());
        return upload;
    }

    static bool ReceiveEarly(Player* player, WorldPacket const& packet)
    {
        WorldSession* session = player->GetSession();
        return std::async(std::launch::async, [session, &packet]
        {
            return !sScriptMgr->CanPacketReceiveEarly(session, packet);
        }).get();
    }

    static char const* DeliverToSession(Player* player, WorldPacket& packet)
    {
        if (packet.GetOpcode() >= NUM_OPCODE_HANDLERS)
            return nullptr;

        ClientOpcodeHandler const* handler = opcodeTable[static_cast<OpcodeClient>(packet.GetOpcode())];
        if (!handler || handler->Status != STATUS_LOGGEDIN || !player->IsInWorld())
            return nullptr;

        packet.rpos(0);
        handler->Call(player->GetSession(), packet);
        return handler->Name;
    }

    void Advance()
    {
        ++_nextStep;
        ++_completed;
        _stepStarted = false;
        _talentRequestSent = false;
        _characterQueueMarked = false;
        _characterQueueReached = false;
        _relogging = false;
        _relogSave.reset();
    }

    bool _relogging = false;
    std::optional<TransactionCallback> _relogSave;
    bool _targetsCreated = false;
    bool _stepStarted = false;
    bool _talentRequestSent = false;
    uint32 _talentResultsBefore = 0;
    bool _characterQueueMarked = false;
    bool _characterQueueReached = false;
    bool _measured = false;
    uint8 _castCount = 0;
    uint32 _timeout = 90000;
    uint32 _assertions = 0;
    uint32 _completed = 0;
    uint32 _ticks = 0;
    uint32 _maxStepMs = 0;
    uint32 _phase;
    uint64 _setupRealMs = 0;
    std::string _runId;
    std::string _resultPath;
    CoAGameplay::NameAllocator* _names;
    std::map<char, std::string> _legacyNames;
    Clock::time_point _admitted;
    std::optional<TimePoint> _admittedGame;
    std::optional<TimePoint> _readyAt;
    TimePoint _stepTime;
    Tree _scenario;
    Tree _steps;
    Tree::const_iterator _nextStep;
    Tree _report;
    Tree _records;
    std::map<std::string, Actor> _actors;
    std::map<std::string, Target> _targets;
    std::map<std::string, double> _snapshots;
    QueryCallbackProcessor _queries;
    std::optional<CreatureScaling::TestOverride> _creatureScaling;
};

enum class TeardownStage
{
    Idle,
    Settling,
    Clearing
};

struct QueuedCase
{
    uint32 sequence = 0;
    bool stop = false;
    bool exclusive = false;
    bool realPace = false;
    std::optional<uint32> hour;
    std::string runId;
    std::string scenarioFile;
    std::string resultFile;
};

struct Lane
{
    uint32 index = 0;
    uint32 phase = 0;
    uint32 sequence = 0;
    bool exclusive = false;
    bool realPace = false;
    TeardownStage stage = TeardownStage::Idle;
    Clock::time_point teardownStarted;
    Clock::time_point lastDeletion;
    std::unique_ptr<GameplayCase> gameplayCase;
    CaseOutcome outcome;
    std::vector<uint32> deletedAccounts;

    bool Idle() const
    {
        return !gameplayCase && stage == TeardownStage::Idle;
    }
};

class CoAGameplayTest final : public WorldScript
{
public:
    CoAGameplayTest() : WorldScript("CoAGameplayTest", { WORLDHOOK_ON_STARTUP,
        WORLDHOOK_ON_UPDATE, WORLDHOOK_ON_SHUTDOWN }) { }

    void OnStartup() override
    {
        if (!sConfigMgr->GetOption<bool>("CoAGameplayTest.Enable", false))
            return;

        _enabled = true;
        _started = Clock::now();
        ProcCounter::Begin();
        _caseDirectory = sConfigMgr->GetOption<std::string>("CoAGameplayTest.CaseDirectory", "", false);
        if (_caseDirectory.empty())
            StartSingle();
        else
            StartQueue();
    }

    void OnUpdate(uint32 diff) override
    {
        if (!_enabled || _finished)
            return;

        if (_caseDirectory.empty())
            UpdateSingle(diff);
        else
            UpdateQueue(diff);
    }

    void OnShutdown() override
    {
        if (!_enabled)
            return;

        if (_caseDirectory.empty())
        {
            if (!_finished)
                Finish(false, InterruptedMessage);
            return;
        }

        bool interrupted = false;
        for (Lane& lane : _lanes)
        {
            if (lane.gameplayCase)
                AbandonCase(lane);
            else if (lane.stage != TeardownStage::Idle && !_aborted)
                FailOutcome(lane, "Server shut down before the case teardown completed");
            else
                continue;
            interrupted = true;
        }
        if (interrupted)
            World::StopNow(ERROR_EXIT_CODE);
    }

private:
    static constexpr char const* InterruptedMessage = "Server shut down before the scenario completed";

    void CheckIsolation()
    {
        std::string worldId = sConfigMgr->GetOption<std::string>("CoAGameplayTest.WorldDatabaseId", _runId);
        Require(IsRunId(worldId), "WorldDatabaseId must be twelve lowercase hexadecimal characters");
        for (auto const& [key, suffix] : std::map<std::string, std::string>{
            { "LoginDatabaseInfo", "auth" }, { "CharacterDatabaseInfo", "characters" },
            { "WorldDatabaseInfo", "world" } })
        {
            std::string connection = sConfigMgr->GetOption<std::string>(key, "");
            auto first = connection.find(';');
            auto last = connection.rfind(';');
            Require(first != std::string::npos && last != first, "Invalid database connection");
            std::string host = connection.substr(0, first);
            Require(host == "127.0.0.1" || host == "localhost" || host == "::1", "Test DB must be local");
            std::string databaseId = suffix == "world" ? worldId : _runId;
            Require(connection.substr(last + 1) == "coa_test_" + databaseId + "_" + suffix,
                "Harness requires its own named test databases");
        }
        Require(sConfigMgr->GetOption<std::string>("BindIP", "") == "127.0.0.1", "BindIP must be loopback");
        Require(sConfigMgr->GetOption<uint32>("MapUpdate.Threads", 1) == 0, "Map workers must be disabled");
    }

    void ReadRunId()
    {
        _runId = sConfigMgr->GetOption<std::string>("CoAGameplayTest.RunId", "");
        Require(IsRunId(_runId), "RunId must be twelve lowercase hexadecimal characters");
        CheckIsolation();
    }

    void ReadStartFile()
    {
        _startFile = sConfigMgr->GetOption<std::string>("CoAGameplayTest.StartFile", "");
        Require(_startFile.empty() || !std::filesystem::exists(_startFile), "Start file already exists");
    }

    static std::string ConfiguredClock()
    {
        return sConfigMgr->GetOption<std::string>("CoAGameplayTest.Clock", RealClock, false);
    }

    static uint32 ConfiguredLanes()
    {
        return sConfigMgr->GetOption<uint32>("CoAGameplayTest.Lanes", 1, false);
    }

    static Milliseconds ConfiguredStep(std::string const& name, Milliseconds fallback)
    {
        uint32 const value = sConfigMgr->GetOption<uint32>("CoAGameplayTest." + name, uint32(fallback.count()), false);
        Require(value >= CoAGameplay::MinimumStep.count() && value <= CoAGameplay::MaximumStep.count(),
            name + " must be between 1 and 2000 ms");
        return Milliseconds(value);
    }

    void ReadClock()
    {
        _clock = ConfiguredClock();
        Require(_clock == RealClock || _clock == SimulatedClock, "Clock must be real or simulated");
        uint32 const lanes = ConfiguredLanes();
        Require(lanes >= 1 && lanes <= CoAGameplay::MaxLanes, "Lanes must be between 1 and 15");
        Require(lanes == 1 || _clock == SimulatedClock, "Several lanes need the simulated clock");
        _policy.step = ConfiguredStep("StepMs", _policy.step);
        _freezeUnseenWorld = sConfigMgr->GetOption<bool>("CoAGameplayTest.FreezeUnseenWorld", true, false);
        _policy.activeWaitCap = ConfiguredStep("ActiveWaitCapMs", _policy.activeWaitCap);
        _policy.pollCap = ConfiguredStep("PollCapMs", _policy.pollCap);
        _lanes = std::vector<Lane>(lanes);
        for (uint32 index = 0; index < lanes; ++index)
        {
            _lanes[index].index = index;
            _lanes[index].phase = CoAGameplay::LanePhase(index);
        }
        _simulated = _clock == SimulatedClock;
        if (!_simulated)
            return;
        _startHour = sConfigMgr->GetOption<uint32>("CoAGameplayTest.StartHour", DefaultStartHour, false);
        Require(_startHour < HoursPerDay, "StartHour must be between 0 and 23");
        SystemTimePoint const start = NextRealmLocalHour(std::chrono::system_clock::now(), _startHour);
        GameTime::EnableSimulation();
        GameTime::SetSimulatedSystemAnchor(start);
        LOG_INFO("coa.gameplay_test", "Simulated realm-local time starts at {}",
            RealmLocalText(std::chrono::floor<Seconds>(start.time_since_epoch())));
    }

    static std::string CharacterDatabaseIsolation()
    {
        QueryResult const result = CharacterDatabase.Query("SELECT @@SESSION.transaction_isolation");
        Require(result != nullptr, "Could not read the character database transaction isolation");
        return result->Fetch()[0].Get<std::string>();
    }

    void WriteReady()
    {
        Tree ready;
        ready.put("run_id", _runId);
        ready.put("status", "ready");
        ready.put("waiting_for_start", !_startFile.empty());
        if (!_caseDirectory.empty())
        {
            ready.put("mode", "queue");
            ready.put("clock", _clock);
            ready.put("lanes", uint32(_lanes.size()));
            if (_simulated)
                ready.put("start_hour", _startHour);
            ready.put("character_db_workers",
                sConfigMgr->GetOption<uint32>("CharacterDatabase.WorkerThreads", 1, false));
            ready.put("character_db_isolation", CharacterDatabaseIsolation());
        }
        WriteResult(sConfigMgr->GetOption<std::string>("CoAGameplayTest.ReadyFile", ""), ready);
    }

    bool Released()
    {
        Require(Elapsed(_started) < RunnerPatienceMs, "Runner did not release the startup barrier");
        std::ifstream startStream(_startFile);
        if (!startStream.is_open())
            return false;
        Tree start;
        boost::property_tree::read_json(startStream, start);
        Require(start.get<std::string>("run_id") == _runId, "Start file belongs to another run");
        _startFile.clear();
        _started = Clock::now();
        return true;
    }

    void StartSingle()
    {
        std::string resultPath;
        try
        {
            ReadRunId();
            Require(ConfiguredClock() == RealClock && ConfiguredLanes() == 1,
                "A single scenario runs on the real clock in one lane");
            resultPath = sConfigMgr->GetOption<std::string>("CoAGameplayTest.ResultFile", "");
            Require(!std::filesystem::exists(resultPath), "Result file already exists");
            ReadStartFile();
            _case = std::make_unique<GameplayCase>(_runId, resultPath);
            _case->Load(sConfigMgr->GetOption<std::string>("CoAGameplayTest.ScenarioFile", ""));
            WriteReady();
            LOG_INFO("coa.gameplay_test", "Gameplay harness ready: {}", _runId);
        }
        catch (std::exception const& error)
        {
            if (!_case)
                _case = std::make_unique<GameplayCase>(_runId, resultPath);
            Finish(false, error.what());
        }
    }

    void UpdateSingle(uint32 diff)
    {
        try
        {
            if (!_startFile.empty())
            {
                if (!Released())
                    return;
                _case->RestartClock();
            }
            if (_case->Tick(diff))
                Finish(true, "All assertions passed");
        }
        catch (std::exception const& error)
        {
            Finish(false, error.what());
        }
    }

    void Finish(bool passed, std::string const& message)
    {
        if (_finished)
            return;
        _finished = true;
        _case->Conclude(passed, message);
        _case->Dismiss(false);
        passed = _case->Write() && passed;
        LOG_INFO("coa.gameplay_test", "Gameplay test {}: {}", passed ? "passed" : "failed", message);
        World::StopNow(passed ? SHUTDOWN_EXIT_CODE : ERROR_EXIT_CODE);
    }

    void StartQueue()
    {
        try
        {
            ReadRunId();
            Require(sConfigMgr->GetOption<std::string>("CoAGameplayTest.ScenarioFile", "").empty()
                && sConfigMgr->GetOption<std::string>("CoAGameplayTest.ResultFile", "").empty(),
                "Queue mode takes scenario and result files from its cases");
            Require(sConfigMgr->GetOption<uint32>("LoginDatabase.WorkerThreads", 1) == 1,
                "Queue mode needs one asynchronous login database worker");
            Require(!sConfigMgr->GetOption<bool>("Cluster.Enabled", false),
                "Queue mode needs cluster mode disabled to disband fixture groups");
            Require(std::filesystem::is_directory(_caseDirectory), "Case directory does not exist");
            ReadStartFile();
            ReadClock();
            WriteReady();
            _idleSince = Clock::now();
            LOG_INFO("coa.gameplay_test", "Gameplay queue ready: {} ({} clock, {} lanes)", _runId, _clock,
                _lanes.size());
        }
        catch (std::exception const& error)
        {
            Abort(error.what());
        }
    }

    void UpdateQueue(uint32 diff)
    {
        try
        {
            if (!_startFile.empty())
            {
                if (!Released())
                    return;
                _idleSince = Clock::now();
            }
            for (Lane& lane : _lanes)
            {
                UpdateLane(lane, diff);
                if (_finished)
                    return;
            }
            Admit();
            if (_finished)
                return;
            if (!AllLanesIdle())
                _idleSince = Clock::now();
            RequestWorldStep();
        }
        catch (std::exception const& error)
        {
            Abort(error.what());
        }
    }

    void Abort(std::string const& message)
    {
        _finished = true;
        _aborted = true;
        LOG_ERROR("coa.gameplay_test", "Gameplay queue stopped: {}", message);
        World::StopNow(ERROR_EXIT_CODE);
    }

    bool AllLanesIdle() const
    {
        return std::ranges::all_of(_lanes, [](Lane const& lane) { return lane.Idle(); });
    }

    Lane* FreeLane(bool exclusive)
    {
        if (std::ranges::any_of(_lanes, [](Lane const& lane) { return lane.exclusive && !lane.Idle(); }))
            return nullptr;
        if (exclusive && !AllLanesIdle())
            return nullptr;
        auto const free = std::ranges::find_if(_lanes, [](Lane const& lane) { return lane.Idle(); });
        return free == _lanes.end() ? nullptr : &*free;
    }

    void Admit()
    {
        while (_next || ReadNextCase())
        {
            if (_next->stop)
            {
                if (AllLanesIdle())
                    Stop(_next->sequence);
                return;
            }
            Lane* lane = FreeLane(_next->exclusive);
            if (!lane || !ReachHour(_next->hour))
                return;
            QueuedCase const next = std::move(*_next);
            _next.reset();
            StartCase(*lane, next);
            if (_finished)
                return;
        }
    }

    bool ReachHour(std::optional<uint32> hour)
    {
        if (!_simulated)
            return true;
        Seconds const gameTime = GameTime::GetGameTime();
        if (hour)
            _awayFromStartHour = true;
        else if (!_awayFromStartHour || uint32(RealmLocalTime(gameTime).tm_hour) == _startHour)
        {
            _awayFromStartHour = false;
            return true;
        }
        uint32 const target = hour.value_or(_startHour);
        if (InFirstMinuteOfHour(gameTime, target))
            return true;
        if (!AllLanesIdle())
            return false;
        SystemTimePoint const now = GameTime::GetSystemTime();
        GameTime::AdvanceSimulation(std::chrono::ceil<Milliseconds>(NextRealmLocalHour(now, target) - now));
        return false;
    }

    void Stop(uint32 sequence)
    {
        _finished = true;
        LOG_INFO("coa.gameplay_test", "Gameplay queue stopped after {} cases", sequence);
        World::StopNow(SHUTDOWN_EXIT_CODE);
    }

    bool ReadNextCase()
    {
        std::filesystem::path const path = std::filesystem::path(_caseDirectory) /
            Acore::StringFormat("case-{:06}.json", _sequence);
        if (!std::filesystem::exists(path))
        {
            if (AllLanesIdle())
                Require(Elapsed(_idleSince) < RunnerPatienceMs, "Runner did not provide the next case");
            return false;
        }

        Tree record;
        boost::property_tree::read_json(path.string(), record);
        Require(record.get<uint32>("schema") == 1, "Unsupported case schema");
        Require(record.get<std::string>("batch_id") == _runId, "Case belongs to another batch");
        Require(record.get<uint32>("sequence") == _sequence, "Case is out of sequence");
        QueuedCase next;
        next.sequence = _sequence;
        if (record.count("stop"))
        {
            Require(record.get<bool>("stop") && !record.count("run_id") && !record.count("scenario_file")
                && !record.count("result_file") && !record.count("exclusive") && !record.count("pace")
                && !record.count("hour"), "Malformed stop case");
            next.stop = true;
        }
        else
        {
            next.runId = record.get<std::string>("run_id");
            Require(IsRunId(next.runId) && next.runId != _runId && _runIds.insert(next.runId).second,
                "Case run id must be twelve lowercase hexadecimal characters not used before");
            next.scenarioFile = record.get<std::string>("scenario_file");
            next.resultFile = record.get<std::string>("result_file");
            Require(!next.scenarioFile.empty(), "Case needs a scenario file");
            Require(!next.resultFile.empty() && !std::filesystem::exists(next.resultFile),
                "Case result file must be new");
            if (record.count("exclusive"))
            {
                auto const exclusive = record.get_optional<bool>("exclusive");
                Require(exclusive.is_initialized(), "Case exclusive must be a boolean");
                next.exclusive = *exclusive;
            }
            if (auto pace = record.get_optional<std::string>("pace"))
            {
                Require(*pace == RealClock, "Case pace must be real");
                next.realPace = true;
            }
            if (record.count("hour"))
            {
                auto const hour = record.get_optional<uint32>("hour");
                Require(hour && *hour < HoursPerDay, "Case hour must be an integer from 0 to 23");
                next.hour = *hour;
                next.exclusive = true;
            }
        }
        _next = std::move(next);
        ++_sequence;
        return true;
    }

    void StartCase(Lane& lane, QueuedCase const& next)
    {
        lane.sequence = next.sequence;
        lane.exclusive = next.exclusive;
        lane.realPace = next.realPace;
        lane.outcome = CaseOutcome{};
        lane.gameplayCase = std::make_unique<GameplayCase>(next.runId, next.resultFile, lane.phase,
            _lanes.size() > 1 ? &_names : nullptr);
        lane.gameplayCase->PlaceInBatch(_runId, next.sequence, _clock, lane.index);
        LOG_INFO("coa.gameplay_test", "Gameplay case {} started in lane {}: {}", next.sequence, lane.index,
            next.runId);
        std::string failure;
        try
        {
            lane.gameplayCase->Load(next.scenarioFile);
            if (next.hour)
                RequireRealmLocalHour(*next.hour);
            return;
        }
        catch (std::exception const& error)
        {
            failure = error.what();
        }
        EndCase(lane, false, failure);
    }

    void UpdateLane(Lane& lane, uint32 diff)
    {
        if (lane.gameplayCase)
        {
            RunCase(lane, diff);
            return;
        }
        if (lane.stage == TeardownStage::Idle)
            return;
        try
        {
            Settle(lane);
        }
        catch (std::exception const& error)
        {
            FailTeardown(lane, error.what());
        }
    }

    void RunCase(Lane& lane, uint32 diff)
    {
        bool completed = false;
        try
        {
            completed = lane.gameplayCase->Tick(diff);
        }
        catch (std::exception const& error)
        {
            EndCase(lane, false, error.what());
            return;
        }
        if (completed)
            EndCase(lane, true, "All assertions passed");
    }

    void EndCase(Lane& lane, bool passed, std::string const& message)
    {
        try
        {
            CompleteCase(lane, passed, message);
        }
        catch (std::exception const& error)
        {
            FailTeardown(lane, error.what());
        }
    }

    void CompleteCase(Lane& lane, bool passed, std::string const& message)
    {
        lane.gameplayCase->Conclude(passed, message);
        LOG_INFO("coa.gameplay_test", "Gameplay case {} {} in lane {}: {}", lane.sequence,
            passed ? "passed" : "failed", lane.index, message);
        lane.outcome = lane.gameplayCase->Outcome();
        lane.deletedAccounts.clear();
        lane.teardownStarted = Clock::now();
        lane.stage = TeardownStage::Settling;
        bool ungrouped = false;
        try
        {
            ungrouped = lane.gameplayCase->Dismiss(true);
        }
        catch (std::exception const&)
        {
            StrandCaseWithoutSecondLogout(lane);
            throw;
        }
        lane.gameplayCase.reset();
        Require(ungrouped, "A fixture group survived teardown");
        if (!lane.outcome.accounts.namesReusable)
        {
            ReleaseLane(lane);
            return;
        }
        DeleteAccounts(lane);
        lane.lastDeletion = Clock::now();
        lane.stage = TeardownStage::Clearing;
    }

    void AbandonCase(Lane& lane)
    {
        try
        {
            if (!_aborted)
            {
                lane.gameplayCase->Conclude(false, InterruptedMessage);
                lane.gameplayCase->Write();
            }
            lane.gameplayCase->Dismiss(false);
            lane.gameplayCase.reset();
        }
        catch (std::exception const& error)
        {
            LOG_ERROR("coa.gameplay_test", "Could not abandon gameplay case {}: {}", lane.sequence, error.what());
            StrandCaseWithoutSecondLogout(lane);
        }
    }

    static void StrandCaseWithoutSecondLogout(Lane& lane)
    {
        static_cast<void>(lane.gameplayCase.release());
    }

    void FailOutcome(Lane& lane, std::string const& failure)
    {
        lane.stage = TeardownStage::Idle;
        std::string const message = lane.outcome.report.get<std::string>("status", "") == "passed" ? failure
            : lane.outcome.report.get<std::string>("message", "") + "; " + failure;
        lane.outcome.report.put("status", "failed");
        lane.outcome.report.put("message", message);
        WriteCaseResult(lane.outcome.resultPath, lane.outcome.report);
        LOG_ERROR("coa.gameplay_test", "Gameplay case {} ({}) failed: {}", lane.sequence,
            lane.outcome.report.get<std::string>("run_id", ""), message);
    }

    void FailTeardown(Lane& lane, std::string const& reason)
    {
        FailOutcome(lane, "Teardown failed: " + reason);
        Abort("Teardown of case " + std::to_string(lane.sequence) + " failed: " + reason);
    }

    static void Settle(Lane& lane)
    {
        Require(Elapsed(lane.teardownStarted) < RunnerPatienceMs, "Case teardown did not finish");
        if (Elapsed(lane.lastDeletion) < TeardownRecheckMs)
            return;
        if (TeardownComplete(lane))
        {
            ReleaseLane(lane);
            return;
        }
        DeleteAccounts(lane);
        lane.lastDeletion = Clock::now();
    }

    static void ReleaseLane(Lane& lane)
    {
        lane.stage = TeardownStage::Idle;
        Require(WriteCaseResult(lane.outcome.resultPath, lane.outcome.report),
            "Could not write the result of case " + std::to_string(lane.sequence));
    }

    static void DeleteAccounts(Lane& lane)
    {
        for (std::string const& account : lane.outcome.accounts.accounts)
            if (uint32 const id = AccountMgr::GetId(account);
                id && std::ranges::find(lane.deletedAccounts, id) == lane.deletedAccounts.end())
            {
                Require(AccountMgr::DeleteAccount(id) == AOR_OK, "Could not delete case account " + account);
                lane.deletedAccounts.push_back(id);
            }
        for (std::string name : lane.outcome.accounts.characters)
        {
            CharacterDatabase.EscapeString(name);
            if (QueryResult result = CharacterDatabase.Query("SELECT guid FROM characters WHERE name = '{}'", name))
                Player::DeleteFromDB(result->Fetch()[0].Get<uint32>(), 0, false, true);
        }
    }

    static bool TeardownComplete(Lane const& lane)
    {
        for (std::string const& account : lane.outcome.accounts.accounts)
            if (AccountMgr::GetId(account))
                return false;
        for (uint32 const id : lane.deletedAccounts)
        {
            std::string name;
            if (AccountMgr::GetName(id, name) || AccountMgr::GetCharactersCount(id))
                return false;
        }
        for (std::string const& name : lane.outcome.accounts.characters)
        {
            if (sCharacterCache->GetCharacterGuidByName(name))
                return false;
            CharacterDatabasePreparedStatement* statement = CharacterDatabase.GetPreparedStatement(CHAR_SEL_CHECK_NAME);
            statement->SetData(0, name);
            if (CharacterDatabase.Query(statement))
                return false;
        }
        return true;
    }

    void RequestWorldStep() const
    {
        if (!_simulated)
            return;
        std::vector<StepRequest> requests;
        uint32 phases = 0;
        if (_freezeUnseenWorld)
        {
            phases = CoAGameplay::LanePhases(uint32(_lanes.size()));
            for (Lane const& lane : _lanes)
                if (lane.gameplayCase)
                    phases |= lane.gameplayCase->VisiblePhases();
        }
        Map::SetSimulatedUpdatePhases(phases);
        for (Lane const& lane : _lanes)
        {
            if (!lane.gameplayCase)
                continue;
            if (lane.realPace)
                return;
            requests.push_back(lane.gameplayCase->StepNeed());
        }
        if (std::optional<Milliseconds> const step = CoAGameplay::ChooseStep(requests, _policy))
            GameTime::RequestStep(*step);
    }

    bool _enabled = false;
    bool _finished = false;
    bool _aborted = false;
    bool _simulated = false;
    bool _awayFromStartHour = false;
    bool _freezeUnseenWorld = true;
    uint32 _sequence = 0;
    uint32 _startHour = DefaultStartHour;
    std::string _runId;
    std::string _startFile;
    std::string _caseDirectory;
    std::string _clock = RealClock;
    Clock::time_point _started;
    Clock::time_point _idleSince;
    CoAGameplay::ClockPolicy _policy;
    CoAGameplay::NameAllocator _names;
    std::unique_ptr<GameplayCase> _case;
    std::vector<Lane> _lanes;
    std::optional<QueuedCase> _next;
    std::unordered_set<std::string> _runIds;
};

class CoAGameplayTestProcCounter final : public AllSpellScript
{
public:
    CoAGameplayTestProcCounter() : AllSpellScript("CoAGameplayTestProcCounter", { ALLSPELLHOOK_ON_CAST }) { }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        if (!caster || !spell)
            return;
        if (info)
            ProcCounter::RecordCast(caster->GetGUID(), info->Id);
        if (SpellInfo const* triggeredBy = spell->GetTriggeredByAuraSpellInfo())
            ProcCounter::Record(caster->GetGUID(), triggeredBy->Id);
    }
};
}

void AddCoAGameplayTestScripts()
{
    new CoAGameplayTest();
    new CoAGameplayTestRegeneration();
    new CoAGameplayTestProcCounter();
}
