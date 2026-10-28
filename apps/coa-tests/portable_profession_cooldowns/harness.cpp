#include "Common.h"
#include "ItemTemplate.h"
#include "SpellAuraDefines.h"
#include "SpellChargeState.h"
#include "SpellDefines.h"
#include "WorldPacket.h"
#include <algorithm>
#include <array>
#include <chrono>
#include <iostream>
#include <map>
#include <memory>
#include <set>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <vector>

uint32 Now = 1000;

namespace GameTime
{
Milliseconds GetGameTimeMS() { return Milliseconds(Now); }
TimePoint GetSystemTime() { return TimePoint(Milliseconds(Now)); }
}

#define getMSTime() Now
#define GetMSTimeDiffToNow(old) (Now - (old))
#define ASSERT(condition, ...) do { if (!(condition)) throw std::runtime_error("buffer assertion"); } while (false)

template<class... Args>
void LogSink(Args&&...) { }

#define LOG_INFO(...) LogSink(__VA_ARGS__)
#define LOG_DEBUG(...) LogSink(__VA_ARGS__)

// ACTUAL_BYTE_BUFFER
// ACTUAL_COOLDOWN_RECORD
// ACTUAL_OVERRIDE_RECORD
// ACTUAL_ATTACK_TYPE

struct Field
{
    uint32 Value;
    template<class T>
    T Get() const { return T(Value); }
};

struct Query
{
    std::vector<std::array<Field, 5>> Rows;
    std::size_t Row = 0;
    Field* Fetch() { return Rows[Row].data(); }
    bool NextRow() { return ++Row < Rows.size(); }
};

using QueryResult = std::shared_ptr<Query>;

struct Database
{
    std::vector<std::array<uint32, 5>> Rows;
    QueryResult Query(char const*)
    {
        if (Rows.empty())
            return nullptr;
        auto result = std::make_shared<struct Query>();
        for (auto const& row : Rows)
        {
            std::array<Field, 5> fields;
            for (uint32 index = 0; index < fields.size(); ++index)
                fields[index].Value = row[index];
            result->Rows.push_back(fields);
        }
        return result;
    }
} WorldDatabase;

struct SpellInfo
{
    uint32 Id = 0;
    uint32 RecoveryTime = 3600000;
    uint32 CategoryRecoveryTime = 0;
    uint32 StartRecoveryTime = 0;
    uint32 StartRecoveryCategory = 0;
    uint32 Category = 0;
    uint32 SpellFamilyName = 0;
    uint32 MaxCharges = 0;
    uint32 DurationIndex = 5;
    uint32 CastingTimeIndex = 7;

    uint32 GetCategory() const { return Category; }
    bool IsAutoRepeatRangedSpell() const { return false; }
    bool IsCooldownStartedOnEvent() const { return false; }
    template<class T>
    bool HasAttribute(T) const { return false; }
};

struct SpellMgr
{
    std::map<uint32, SpellInfo> Spells;
    std::map<uint32, SpellCooldownOverride> mSpellCooldownOverrideMap;
    void LoadSpellCooldownOverrides();
    bool HasSpellCooldownOverride(uint32) const;
    SpellCooldownOverride GetSpellCooldownOverride(uint32) const;
    SpellInfo const* GetSpellInfo(uint32 id) const
    {
        auto spell = Spells.find(id);
        return spell != Spells.end() ? &spell->second : nullptr;
    }
    void ApplyOverride(SpellInfo* spellInfo)
    {
        // ACTUAL_APPLY_OVERRIDE
    }
} spellMgr;

auto sSpellMgr = &spellMgr;

// ACTUAL_LOAD_OVERRIDES
// ACTUAL_HAS_OVERRIDE
// ACTUAL_GET_OVERRIDE

struct ObjectMgr
{
    std::unordered_map<uint32, ItemTemplate> Items;
    ItemTemplate const* GetItemTemplate(uint32 id) const
    {
        auto item = Items.find(id);
        return item != Items.end() ? &item->second : nullptr;
    }
    ItemLocale const* GetItemLocale(uint32) const { return nullptr; }
    static void GetLocaleString(std::vector<std::string> const&, int, std::string&) { }
} objectMgr;

auto sObjectMgr = &objectMgr;

using SpellCategorySet = std::set<std::pair<bool, uint32>>;
using SpellCategoryStore = std::unordered_map<uint32, SpellCategorySet>;
SpellCategoryStore sSpellsByCategoryStore;

struct Spell { };
struct Player;

struct ScriptMgr
{
    void OnPlayerSpellCooldownCalculated(Player*, SpellInfo const*, Spell*, uint32) { }
} scriptMgr;

auto sScriptMgr = &scriptMgr;

struct ArenaSpectator
{
    template<class... Args>
    static void SendCommand_Cooldown(Args&&...) { }
};

constexpr uint32 infinityCooldownDelay = uint32(MONTH) * IN_MILLISECONDS;
constexpr uint8 MAX_ITEM_SPELLS = MAX_ITEM_PROTO_SPELLS;
constexpr uint32 SPECTATOR_COOLDOWN_MIN = 1;
constexpr uint32 SPECTATOR_COOLDOWN_MAX = 3600;
constexpr uint8 SPELL_COOLDOWN_FLAG_NONE = 0;
constexpr uint8 SPELL_ATTR0_CU_FORCE_SEND_CATEGORY_COOLDOWNS = 0;
using PacketCooldowns = std::map<uint32, uint32>;
using SpellCooldowns = std::map<uint32, SpellCooldown>;

struct Player
{
    SpellCooldowns m_spellCooldowns;
    void AddSpellAndCategoryCooldowns(SpellInfo const*, uint32, Spell*, bool = false);
    void _AddSpellCooldown(uint32, uint16, uint32, uint32, bool, bool = false);
    bool HasSpellCooldown(uint32) const;
    uint32 GetSpellCooldownDelay(uint32) const;
    void ConsumeSpellCharge(SpellInfo const*, Spell*) { }
    uint32 GetAttackTime(uint8) const { return 0; }
    template<class T>
    void ApplySpellMod(uint32, T, int32&, Spell*) { }
    template<class T>
    int32 GetTotalAuraModifier(T) const { return 0; }
    bool HasSpell(uint32) const { return false; }
    bool HasActiveSpell(uint32) const { return false; }
    bool NeedSendSpectatorData() const { return false; }
    void* FindMap() const { return nullptr; }
    uint32 GetGUID() const { return 1; }
    void BuildCooldownPacket(WorldPacket&, uint8, uint32, uint32) { }
    void BuildCooldownPacket(WorldPacket&, uint8, PacketCooldowns const&) { }
    void SendDirectMessage(WorldPacket const*) { }
    SpellChargeState GetSpellCharges(SpellInfo const*) const { return {1, 0, 0}; }
};

// ACTUAL_ADD_COOLDOWNS
// ACTUAL_STORE_COOLDOWN
// ACTUAL_HAS_COOLDOWN
// ACTUAL_COOLDOWN_DELAY

class WorldSession
{
public:
    std::vector<WorldPacket> Packets;
    int GetSessionDbLocaleIndex() const { return -1; }
    void SendPacket(WorldPacket const* packet) { Packets.push_back(*packet); }
    void SendItemQuerySingleResponse(uint32);
};

// ACTUAL_ITEM_QUERY

void Require(bool condition, std::string const& message)
{
    if (!condition)
        throw std::runtime_error(message);
}

void QueryCooldown(uint32 expected, int32 categoryRecovery = 0)
{
    WorldSession session;
    session.SendItemQuerySingleResponse(1777064);
    Require(session.Packets.size() == 1 && session.Packets[0].GetOpcode() == SMSG_ITEM_QUERY_SINGLE_RESPONSE,
        "portable sawmill must have a stock item-query response");
    auto packet = session.Packets[0];
    Require(packet.read<uint32>() == 1777064, "item-query response entry");
    packet.rpos(4 * sizeof(uint32));
    while (packet.read<uint8>() != 0) { }
    packet.rpos(packet.rpos() + 3 + 21 * sizeof(uint32));
    Require(packet.read<uint32>() == 0, "item-query fixture has no stat fields");
    packet.rpos(packet.rpos() + (2 + 3 * MAX_ITEM_PROTO_DAMAGES + 7 + 3) * sizeof(uint32));
    Require(packet.read<uint32>() == 9931368, "item-query on-use spell must remain the portable sawmill");
    packet.read<uint32>();
    packet.read<int32>();
    Require(packet.read<uint32>() == expected, "client item-query cooldown must match native resolution");
    Require(packet.read<uint32>() == 0 && packet.read<uint32>() == uint32(categoryRecovery),
        "item-query category and category cooldown preserve the source values");
}

void NativeCooldown(uint32 spellId, uint32 itemId, uint32 expected)
{
    Player player;
    auto info = sSpellMgr->GetSpellInfo(spellId);
    player.AddSpellAndCategoryCooldowns(info, itemId, nullptr);
    Require(player.GetSpellCooldownDelay(spellId) == expected,
        "expected five-minute native cooldown for " + std::to_string(spellId) + "; observed " +
        std::to_string(player.GetSpellCooldownDelay(spellId)));
    Require(player.HasSpellCooldown(spellId), "native cooldown blocks immediate repeat use");
    Require(player.m_spellCooldowns.at(spellId).itemid == itemId &&
        player.m_spellCooldowns.at(spellId).maxduration == expected, "native cooldown stores its item and duration");
    Require(!player.HasSpellCooldown(spellId == 9931368 ? 9931369 : 9931368),
        "category-zero portable sawmills keep independent cooldowns");
    Now += expected - 1;
    Require(player.HasSpellCooldown(spellId) && player.GetSpellCooldownDelay(spellId) == 1,
        "native cooldown remains active one millisecond before expiry");
    ++Now;
    Require(!player.HasSpellCooldown(spellId) && player.GetSpellCooldownDelay(spellId) == 0,
        "native cooldown expires at five minutes");
}

int main()
{
    try
    {
        // ACTUAL_SQL_ROWS
        for (uint32 id : {9931368u, 9931369u, 9931366u, 804707u})
        {
            auto& info = spellMgr.Spells[id];
            info.Id = id;
        }
        spellMgr.Spells[9931366].RecoveryTime = 1800000;
        spellMgr.Spells[804707].RecoveryTime = 1200000;
        spellMgr.LoadSpellCooldownOverrides();
        for (auto& [id, info] : spellMgr.Spells)
            spellMgr.ApplyOverride(&info);
        Require(spellMgr.Spells[9931366].RecoveryTime == 1800000 &&
            spellMgr.Spells[804707].RecoveryTime == 1200000,
            "portable workbench and Tinker Build: Portable Sawmill retain their original cooldowns");
        for (uint32 id : {9931368u, 9931369u})
        {
            auto const& info = spellMgr.Spells[id];
            Require(info.GetCategory() == 0 && info.CategoryRecoveryTime == 0 && info.StartRecoveryTime == 0 &&
                info.StartRecoveryCategory == 0 && info.DurationIndex == 5 && info.CastingTimeIndex == 7,
                "sawmill category, global cooldown, summon lifetime and cast-time indices remain unchanged");
            NativeCooldown(id, 0, 300000);
        }
        auto& item = objectMgr.Items[1777064];
        item.ItemId = 1777064;
        item.Name1 = "Portable Sawmill";
        item.Spells[0].SpellId = 9931368;
        item.Spells[0].SpellCooldown =
            // ACTUAL_ITEM_COOLDOWN
            ;
        item.Spells[0].SpellCategoryCooldown = -1;
        NativeCooldown(9931368, 1777064, 300000);
        QueryCooldown(300000, -1);
        item.Spells[0].SpellCooldown = -1;
        item.Spells[0].SpellCategoryCooldown = -1;
        NativeCooldown(9931368, 1777064, 300000);
        QueryCooldown(300000);
        item.Spells[0].SpellCooldown = 45000;
        item.Spells[0].SpellCategoryCooldown = 0;
        NativeCooldown(9931368, 1777064, 45000);
        QueryCooldown(45000);
        spellMgr.LoadSpellCooldownOverrides();
        Require(spellMgr.mSpellCooldownOverrideMap.size() == WorldDatabase.Rows.size(),
            "reloading cooldown overrides cannot accumulate entries");
        std::cout << "PASS: SQL migration idempotency and guarded item update; real override loader/application; "
            "both sawmill spells resolve to five minutes; native item overrides and fallback; "
            "client item-query parity; expiry boundary; unchanged categories, cast time, lifetime "
            "and unrelated spells\n";
    }
    catch (std::exception const& error)
    {
        std::cerr << "FAIL: " << error.what() << '\n';
        return 1;
    }
}
