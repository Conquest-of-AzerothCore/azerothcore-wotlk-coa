#include <algorithm>
#include <array>
#include <cstdint>
#include <iostream>
#include <map>
#include <memory>
#include <mutex>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

using uint8 = std::uint8_t;
using uint16 = std::uint16_t;
using uint32 = std::uint32_t;

namespace ItemScaling
{
uint32 BaseEntry(uint32 entry) { return entry; }
}

// ACTUAL_CONSTANTS
// ACTUAL_PLAYER_HOOKS
// ACTUAL_PROGRESS_EVENTS
// ACTUAL_APPEARANCE_INFO
// ACTUAL_COLLECTION_STATE

constexpr uint8 QUEST_REWARD_CHOICES_COUNT = 6;
constexpr uint8 QUEST_REWARDS_COUNT = 4;

struct Quest
{
    uint32 RewardChoiceItemId[QUEST_REWARD_CHOICES_COUNT]{};
    uint32 RewardChoiceItemCount[QUEST_REWARD_CHOICES_COUNT]{};
    uint32 RewardItemId[QUEST_REWARDS_COUNT]{};
    uint32 RewardItemIdCount[QUEST_REWARDS_COUNT]{};
};

struct WorldPacket
{
    uint16 Opcode;
    std::vector<uint32> Values;

    WorldPacket(uint16 opcode, std::size_t) : Opcode(opcode) { }
    WorldPacket& operator<<(uint32 value)
    {
        Values.push_back(value);
        return *this;
    }
};

struct WorldSession
{
    std::vector<WorldPacket> Packets;
    void SendPacket(WorldPacket const* packet) { Packets.push_back(*packet); }
};

struct ObjectGuid
{
    uint32 Counter;
    uint32 GetCounter() const { return Counter; }
};

struct Player
{
    uint32 Id = 42;
    WorldSession Session;
    std::vector<uint32> Inventory;
    uint32 BankSpellCalls = 0;
    uint32 VanityStoreCalls = 0;

    ObjectGuid GetGUID() const { return {Id}; }
    WorldSession* GetSession() { return &Session; }
    bool IsInWorld() const { return true; }
};

struct Item
{
    uint32 Entry;
    uint32 GetEntry() const { return Entry; }
};

enum class AscensionCompatConfig
{
    ENABLED,
    UNLOCK_ALL_VANITY
};

struct Config
{
    bool Enabled = true;
    bool UnlockAllVanity = false;

    template<class T>
    T GetConfigValue(AscensionCompatConfig key) const
    {
        return key == AscensionCompatConfig::ENABLED ? Enabled : UnlockAllVanity;
    }
} ascensionCompatConfig;

struct DatabaseWrite
{
    bool Appearance;
    std::vector<uint32> Values;
};

struct Database
{
    std::vector<DatabaseWrite> Writes;

    template<class... Args>
    void Execute(char const* query, Args... values)
    {
        Writes.push_back({std::string(query).find("account_appearance_collection") != std::string::npos,
            {uint32(values)...}});
    }
} CharacterDatabase;

struct PlayerScript
{
    std::vector<uint16> Hooks;
    PlayerScript(char const*, std::vector<uint16> hooks) : Hooks(std::move(hooks)) { }
    virtual ~PlayerScript() = default;
    virtual void OnPlayerCompleteQuest(Player*, Quest const*) { }
    bool Enabled(PlayerHook hook) const
    {
        return std::find(Hooks.begin(), Hooks.end(), hook) != Hooks.end();
    }
};

struct ProgressEvent
{
    CoAProgressEvent Event;
    uint32 Value;
};

struct ScriptMgr
{
    std::vector<PlayerScript*> Scripts;
    std::vector<ProgressEvent> Progress;
    void OnPlayerCompleteQuest(Player*, Quest const*);
    void OnPlayerCoAProgress(Player*, CoAProgressEvent event, uint32 value)
    {
        Progress.push_back({event, value});
    }
} scripts;

auto sScriptMgr = &scripts;

#define CALL_ENABLED_HOOKS(Type, Hook, Call) \
    for (PlayerScript* script : Scripts) \
        if (script->Enabled(Hook)) \
            Call
#define LOG_INFO(...) do { } while (false)

// ACTUAL_COMPLETE_DISPATCH

class AscensionCollectionService
{
public:
    std::unordered_map<uint32, AppearanceInfo> _appearances;
    std::unordered_map<uint32, uint32> _itemAppearances;
    std::unordered_set<uint32> _vanityItems;
    std::unordered_set<uint32> BankItems;
    std::unordered_map<uint32, std::shared_ptr<PlayerCollectionState>> _playerStates;
    std::mutex _stateMutex;

    bool IsBankVanityItem(uint32 itemId) const { return BankItems.contains(itemId); }
    void LearnOwnedBankSpells(Player* player, PlayerCollectionState&, bool) { ++player->BankSpellCalls; }
    void SendOwnedVanityStoreRecords(Player* player, PlayerCollectionState&) { ++player->VanityStoreCalls; }

    // ACTUAL_INSTANCE
    // ACTUAL_GET_STATE
    // ACTUAL_ITEM_OBTAINED
    // ACTUAL_QUEST_REWARDED
    // ACTUAL_EQUIPMENT_APPEARANCE
    // ACTUAL_COLLECT_APPEARANCE
    // ACTUAL_COLLECT_ITEM
    // ACTUAL_SEND_ADDED
};

struct AscensionCompatPlayerScript : PlayerScript
{
    // ACTUAL_SCRIPT_CONSTRUCTOR
    // ACTUAL_SCRIPT_COMPLETE
};

void Require(bool condition, std::string const& message)
{
    if (!condition)
        throw std::runtime_error(message);
}

std::shared_ptr<PlayerCollectionState> Reset(Player& player)
{
    auto& service = AscensionCollectionService::Instance();
    service._appearances.clear();
    service._itemAppearances.clear();
    service._vanityItems.clear();
    service.BankItems.clear();
    service._playerStates.clear();
    CharacterDatabase.Writes.clear();
    scripts.Progress.clear();
    player.Session.Packets.clear();
    player.Inventory.clear();
    player.BankSpellCalls = 0;
    player.VanityStoreCalls = 0;
    ascensionCompatConfig.Enabled = true;
    ascensionCompatConfig.UnlockAllVanity = false;
    auto state = std::make_shared<PlayerCollectionState>();
    state->AccountId = 123;
    service._playerStates[player.Id] = state;
    return state;
}

void Appearance(uint32 itemId, uint32 appearanceId, uint32 primary, uint32 secondary = 0, uint32 tertiary = 0)
{
    auto& service = AscensionCollectionService::Instance();
    service._itemAppearances[itemId] = appearanceId;
    service._appearances[appearanceId] = {itemId, primary, secondary, tertiary};
}

void AwardItem(Player& player, uint32 itemId)
{
    player.Inventory.push_back(itemId);
    Item item{itemId};
    AscensionCollectionService::Instance().OnItemObtained(&player, &item);
}

void AssertAppearanceWrites(Player& player, std::unordered_set<uint32> const& expected)
{
    std::unordered_set<uint32> persisted;
    for (auto const& write : CharacterDatabase.Writes)
    {
        Require(write.Appearance, "quest appearance unlock must not persist unchosen vanity ownership");
        Require(write.Values.size() == 3 && write.Values[0] == 123, "appearance persistence account/source fields");
        Require(expected.contains(write.Values[1]), "unexpected persisted appearance");
        Require(persisted.insert(write.Values[1]).second, "duplicate appearance persistence");
        auto const& mapping = AscensionCollectionService::Instance()._itemAppearances;
        Require(mapping.at(write.Values[2]) == write.Values[1], "persisted source item must map to appearance");
    }
    Require(persisted == expected, "all new appearances must persist");
    std::unordered_set<uint32> notified;
    for (auto const& packet : player.Session.Packets)
    {
        Require(packet.Opcode == SMSG_APPEARANCE_ADDED && packet.Values.size() == 2,
            "quest appearance unlock must send only appearance notifications");
        Require(notified.insert(packet.Values[0]).second, "duplicate client appearance notification");
        Require(AscensionCollectionService::Instance()._itemAppearances.at(packet.Values[1]) == packet.Values[0],
            "appearance notification source item");
    }
    Require(notified == expected, "all new appearances must notify the client");
    std::unordered_set<uint32> progressed;
    for (auto const& progress : scripts.Progress)
    {
        Require(progress.Event == CoAProgressEvent::AppearanceCollected && expected.contains(progress.Value),
            "quest appearance progress must include only equipment appearances");
        progressed.insert(progress.Value);
    }
    Require(progressed == expected, "all reward equipment appearances must report collection progress");
}

void AllRewards(Player& player)
{
    auto state = Reset(player);
    Quest quest;
    for (uint32 index = 0; index < QUEST_REWARD_CHOICES_COUNT; ++index)
    {
        quest.RewardChoiceItemId[index] = 110 + index;
        quest.RewardChoiceItemCount[index] = 1;
        Appearance(110 + index, 210 + index, index == 1 ? 0 : index == 2 ? 15 : 1,
            index == 1 ? 14 : 0, index == 2 ? 2 : 0);
    }
    for (uint32 index = 0; index < QUEST_REWARDS_COUNT; ++index)
    {
        quest.RewardItemId[index] = 120 + index;
        quest.RewardItemIdCount[index] = 1;
        Appearance(120 + index, 220 + index, 14);
        AwardItem(player, 120 + index);
    }
    AwardItem(player, 110);
    auto inventory = player.Inventory;
    scripts.OnPlayerCompleteQuest(&player, &quest);
    std::unordered_set<uint32> const expected{210, 211, 212, 213, 214, 215, 220, 221, 222, 223};
    Require(state->CollectedAppearances == expected,
        "expected all ten quest reward appearances after choosing one item; collected " +
            std::to_string(state->CollectedAppearances.size()));
    Require(player.Inventory == inventory && state->OwnedVanityItems.empty(), "appearance unlock cannot grant items");
    AssertAppearanceWrites(player, expected);
    auto writes = CharacterDatabase.Writes.size();
    auto packets = player.Session.Packets.size();
    scripts.OnPlayerCompleteQuest(&player, &quest);
    Require(CharacterDatabase.Writes.size() == writes && player.Session.Packets.size() == packets,
        "repeated rewards must not duplicate persistent/client appearance adds");
}

void SparseRewards(Player& player)
{
    auto state = Reset(player);
    auto& service = AscensionCollectionService::Instance();
    Quest quest{{110, 0, 131, 132, 133, 134}, {0, 1, 1, 1, 1, 2}, {135, 136, 137, 0}, {1, 0, 1, 1}};
    Appearance(110, 210, 1);
    service._itemAppearances[132] = 0;
    service._itemAppearances[133] = 999;
    Appearance(134, 234, 1);
    Appearance(135, 234, 1);
    Appearance(136, 236, 1);
    Appearance(137, 237, 15, 3);
    scripts.OnPlayerCompleteQuest(&player, &quest);
    std::unordered_set<uint32> const expected{234, 237};
    Require(state->CollectedAppearances == expected, "sparse rewards must skip zero counts and missing mappings");
    AssertAppearanceWrites(player, expected);
    Require(player.Inventory.empty(), "sparse appearance rewards must not create physical items");
}

void VanityBoundaries(Player& player)
{
    auto state = Reset(player);
    auto& service = AscensionCollectionService::Instance();
    Appearance(700, 500, 15);
    Appearance(701, 501, 14);
    Appearance(702, 502, 0);
    Appearance(703, 503, 69);
    service._vanityItems = {700, 701, 703};
    service.BankItems = {702};
    Quest quest{{700, 701, 702, 703, 0, 0}, {1, 1, 1, 1, 0, 0}, {}, {}};
    scripts.OnPlayerCompleteQuest(&player, &quest);
    Require(state->CollectedAppearances == std::unordered_set<uint32>{501}, "only gear appearance categories unlock");
    Require(state->OwnedVanityItems.empty() && !player.BankSpellCalls && !player.VanityStoreCalls,
        "unchosen vanity/bank rewards must not unlock ownership or spells");
    AssertAppearanceWrites(player, {501});
    AwardItem(player, 700);
    Require(state->CollectedAppearances.contains(500) && state->OwnedVanityItems.contains(700),
        "physically obtained vanity items retain existing collection behavior");
    AwardItem(player, 702);
    Require(state->OwnedVanityItems.contains(702) && player.BankSpellCalls == 1,
        "physically obtained bank items retain existing ownership behavior");
    Require(!player.VanityStoreCalls,
        "acquiring a bank item must not push vanity rows into the client's custom store list");
}

void MissingStateAndDisabled(Player& player)
{
    auto state = Reset(player);
    Appearance(110, 210, 1);
    Quest quest{{110, 0, 0, 0, 0, 0}, {1, 0, 0, 0, 0, 0}, {}, {}};
    scripts.OnPlayerCompleteQuest(&player, nullptr);
    auto& service = AscensionCollectionService::Instance();
    service._playerStates.clear();
    scripts.OnPlayerCompleteQuest(&player, &quest);
    service._playerStates[player.Id] = state;
    ascensionCompatConfig.Enabled = false;
    scripts.OnPlayerCompleteQuest(&player, &quest);
    Require(state->CollectedAppearances.empty() && CharacterDatabase.Writes.empty() && player.Session.Packets.empty() &&
        scripts.Progress.empty(), "missing quest/state and disabled compatibility must leave collections untouched");
}

void PrecollectedProgress(Player& player)
{
    auto state = Reset(player);
    Appearance(110, 210, 1);
    state->CollectedAppearances.insert(210);
    Quest quest{{110, 0, 0, 0, 0, 0}, {1, 0, 0, 0, 0, 0}, {}, {}};
    scripts.OnPlayerCompleteQuest(&player, &quest);
    Require(state->CollectedAppearances == std::unordered_set<uint32>{210} && CharacterDatabase.Writes.empty() &&
        player.Session.Packets.empty(), "precollected appearances must not duplicate persistence or notifications");
    Require(scripts.Progress.size() == 1 && scripts.Progress[0].Event == CoAProgressEvent::AppearanceCollected &&
        scripts.Progress[0].Value == 210, "precollected quest appearance must still report equipment progress");
}

int main()
{
    try
    {
        Player player;
        AscensionCompatPlayerScript script;
        scripts.Scripts.push_back(&script);
        AllRewards(player);
        Require(script.Enabled(PLAYERHOOK_ON_PLAYER_COMPLETE_QUEST), "quest completion hook must be registered");
        SparseRewards(player);
        VanityBoundaries(player);
        MissingStateAndDisabled(player);
        PrecollectedProgress(player);
        std::cout << "PASS: all quest reward appearance slots; real hook registration and dispatch; "
            "account persistence; "
            "client notifications; equipment progress; sparse and shared mappings; repeat rewards; vanity boundaries; "
            "missing state and compatibility gating; precollected equipment progress\n";
    }
    catch (std::exception const& error)
    {
        std::cerr << "FAIL: " << error.what() << '\n';
        return 1;
    }
}
