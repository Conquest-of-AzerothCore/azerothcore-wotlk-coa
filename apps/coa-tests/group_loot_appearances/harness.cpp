#include <algorithm>
#include <array>
#include <compare>
#include <cstdint>
#include <iostream>
#include <map>
#include <memory>
#include <mutex>
#include <set>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

using uint8 = std::uint8_t;
using uint16 = std::uint16_t;
using uint32 = std::uint32_t;
using int32 = std::int32_t;

namespace ItemScaling
{
std::unordered_map<uint32, uint32> Bases;
uint32 BaseEntry(uint32 entry)
{
    auto const base = Bases.find(entry);
    return base == Bases.end() ? entry : base->second;
}
}

// ACTUAL_CONSTANTS
// ACTUAL_GROUP_HOOKS
// ACTUAL_ROLL_VOTES
// ACTUAL_PROGRESS_EVENTS
// ACTUAL_APPEARANCE_INFO
// ACTUAL_COLLECTION_STATE

constexpr uint32 ITEM_QUALITY_UNCOMMON = 2;
constexpr uint32 ITEM_QUALITY_RARE = 3;
constexpr uint32 ITEM_QUALITY_EPIC = 4;
constexpr uint32 ITEM_QUALITY_LEGENDARY = 5;
constexpr uint32 ITEM_FLAG2_CAN_ONLY_ROLL_GREED = 1;
constexpr uint8 ROLL_FLAG_TYPE_NEED = 2;
constexpr uint8 ROLL_FLAG_TYPE_DISENCHANT = 8;
constexpr uint8 ROLL_PASS = 0;
constexpr uint8 EQUIP_ERR_OK = 0;
constexpr uint16 SMSG_LOOT_START_ROLL = 100;
constexpr uint16 SMSG_LOOT_ROLL = 101;
constexpr uint8 NEED_BEFORE_GREED = 1;
constexpr uint8 GROUP_LOOT = 2;

struct ObjectGuid
{
    uint32 Counter = 0;
    uint32 GetCounter() const { return Counter; }
    bool IsEmpty() const { return !Counter; }
    auto operator<=>(ObjectGuid const&) const = default;

    template<auto>
    static ObjectGuid Create(uint32 counter) { return {counter}; }
};

enum class HighGuid { Item };

struct WorldPacket
{
    uint16 Opcode;
    std::vector<uint32> Values;

    WorldPacket(uint16 opcode, std::size_t) : Opcode(opcode) { }
    template<class T>
    WorldPacket& operator<<(T value)
    {
        Values.push_back(uint32(value));
        return *this;
    }
    WorldPacket& operator<<(ObjectGuid value) { return *this << value.Counter; }
};

struct TraceEvent
{
    uint32 PlayerId;
    uint16 Opcode;
};

std::vector<TraceEvent> Trace;

struct WorldSession
{
    uint32 PlayerId = 0;
    bool Bot = false;
    std::vector<WorldPacket> Packets;

    bool IsBot() const { return Bot; }
    void SendPacket(WorldPacket const* packet)
    {
        Packets.push_back(*packet);
        Trace.push_back({PlayerId, packet->Opcode});
    }
};

struct ItemTemplate
{
    uint32 Quality = ITEM_QUALITY_RARE;
    int32 MaxCount = 0;
    uint32 DisenchantID = 0;
    uint32 RequiredDisenchantSkill = 0;
    uint32 Flags2 = 0;
    uint32 Bonding = 0;

    bool HasFlag2(uint32 flag) const { return Flags2 & flag; }
};

struct WorldObject;

struct Player
{
    uint32 Id;
    WorldSession Session;
    bool HasSession = true;
    bool NearLoot = true;
    bool NearGroup = true;
    bool AutoPass = false;
    bool CanNeed = true;
    uint32 ItemCount = 0;
    std::vector<uint32> Inventory;

    explicit Player(uint32 id) : Id(id) { Session.PlayerId = id; }
    ObjectGuid GetGUID() const { return {Id}; }
    WorldSession* GetSession() { return HasSession ? &Session : nullptr; }
    bool IsAtLootRewardDistance(WorldObject const*) const { return NearLoot; }
    bool IsAtGroupRewardDistance(WorldObject const*) const { return NearGroup; }
    bool GetPassOnGroupLoot() const { return AutoPass; }
    uint32 GetItemCount(uint32, bool) const { return ItemCount; }
    uint8 CanRollForItemInLFG(ItemTemplate const*, WorldObject const*) const { return CanNeed ? 0 : 1; }
    void SendDirectMessage(WorldPacket const* packet) { Session.SendPacket(packet); }
};

struct ObjectAccessor
{
    static inline std::map<ObjectGuid, Player*> Players;
    static Player* FindConnectedPlayer(ObjectGuid guid)
    {
        auto player = Players.find(guid);
        return player != Players.end() ? player->second : nullptr;
    }
    static Player* FindPlayer(ObjectGuid guid) { return FindConnectedPlayer(guid); }
};

struct LootItem
{
    uint32 itemid = 110;
    bool freeforall = false;
    bool follow_loot_rules = true;
    bool is_blocked = false;
    bool is_underthreshold = false;
    std::set<uint32> Denied;
    ObjectGuid ExpectedSource{500};

    bool AllowedForPlayer(Player const* player, ObjectGuid source) const
    {
        return source == ExpectedSource && !Denied.contains(player->Id);
    }
};

struct Creature;
struct GameObject;

struct WorldObject
{
    std::set<ObjectGuid> AllowedLooters;
    uint32 MapId = 1;
    virtual ~WorldObject() = default;
    virtual Creature* ToCreature() { return nullptr; }
    virtual GameObject* ToGameObject() { return nullptr; }
    uint32 GetMapId() const { return MapId; }
    auto const& GetAllowedLooters() const { return AllowedLooters; }
    bool HasAllowedLooter(ObjectGuid guid) const { return AllowedLooters.contains(guid); }
};

struct Creature : WorldObject
{
    uint32 m_groupLootTimer = 0;
    uint32 lootingGroupLowGUID = 0;
    Creature* ToCreature() override { return this; }
};

struct GameObject : WorldObject
{
    uint32 m_groupLootTimer = 0;
    uint32 lootingGroupLowGUID = 0;
    GameObject* ToGameObject() override { return this; }
};

struct Map
{
    Creature* Source;
    uint32 GetId() const { return 1; }
    Creature* GetCreature(ObjectGuid) const { return Source; }
};

struct Loot
{
    std::vector<LootItem> items;
    std::vector<LootItem> quest_items;
    ObjectGuid sourceWorldObjectGUID{500};
    GameObject* sourceGameObject = nullptr;
};

struct Roll
{
    using PlayerVote = std::map<ObjectGuid, RollVote>;
    ObjectGuid itemGUID;
    uint32 itemid;
    uint8 itemSlot = 0;
    uint32 itemRandomSuffix = 0;
    uint32 itemRandomPropId = 0;
    uint32 itemCount = 1;
    uint8 rollVoteMask = ROLL_FLAG_TYPE_NEED;
    uint32 totalPlayersRolling = 0;
    uint32 totalPass = 0;
    PlayerVote playerVote;
    mutable std::map<ObjectGuid, uint32> previewLevels;
    Loot* Source = nullptr;

    Roll(ObjectGuid guid, LootItem const& item) : itemGUID(guid), itemid(item.itemid) { }
    void setLoot(Loot* loot) { Source = loot; }
    Loot* getLoot() const { return Source; }
};

namespace LocalLevelScaling
{
uint32 RollPreviewLevel(Player const*) { return 0; }
}

struct GroupReference
{
    Player* Source;
    GroupReference* Next = nullptr;
    Player* GetSource() const { return Source; }
    GroupReference* next() const { return Next; }
};

struct Group
{
    uint32 m_lootThreshold = ITEM_QUALITY_UNCOMMON;
    uint32 m_maxEnchantingLevel = 0;
    uint8 LootMethod = GROUP_LOOT;
    std::vector<GroupReference> Members;
    std::vector<Roll*> RollId;

    ~Group() { for (auto roll : RollId) delete roll; }
    GroupReference* GetFirstMember() { return Members.empty() ? nullptr : &Members.front(); }
    ObjectGuid GetGUID() const { return {900}; }
    uint8 GetLootMethod() const { return LootMethod; }
    void AddMembers(std::vector<Player*> const& players)
    {
        for (auto player : players)
            Members.push_back({player});
        for (std::size_t index = 1; index < Members.size(); ++index)
            Members[index - 1].Next = &Members[index];
    }

    void GroupLoot(Loot*, WorldObject*);
    void NeedBeforeGreed(Loot*, WorldObject*);
    void SendLootStartRoll(uint32, uint32, Roll const&);
    void SendLootStartRollToPlayer(uint32, uint32, Player*, bool, Roll const&);
    void SendLootRoll(ObjectGuid, ObjectGuid, uint8, uint8, Roll const&, bool = false);
    void SendPendingRollsToPlayer(Player*, Map*);
};

struct Generator
{
    uint32 Next = 1000;
    uint32 Generate() { return ++Next; }
};

struct ObjectMgr
{
    std::unordered_map<uint32, ItemTemplate> Items;
    Generator ItemGenerator;

    ItemTemplate const* GetItemTemplate(uint32 itemId) const
    {
        auto item = Items.find(itemId);
        return item != Items.end() ? &item->second : nullptr;
    }
    template<auto>
    Generator& GetGenerator() { return ItemGenerator; }
} objectMgr;

auto sObjectMgr = &objectMgr;

enum class AscensionCompatConfig { ENABLED };

struct Config
{
    bool Enabled = true;
    template<class T>
    T GetConfigValue(AscensionCompatConfig) const { return Enabled; }
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

struct GroupScript
{
    std::vector<uint16> Hooks;
    GroupScript(char const*, std::vector<uint16> hooks) : Hooks(std::move(hooks)) { }
    virtual ~GroupScript() = default;
    virtual void OnLootRollStart(Group*, Roll const&, Loot const&, LootItem const&) { }
    bool Enabled(GroupHook hook) const
    {
        return std::find(Hooks.begin(), Hooks.end(), hook) != Hooks.end();
    }
};

struct ProgressEvent
{
    uint32 PlayerId;
    CoAProgressEvent Event;
    uint32 Value;
};

struct ScriptMgr
{
    std::vector<GroupScript*> Scripts;
    std::vector<ProgressEvent> Progress;
    void OnGroupLootRollStart(Group*, Roll const&, Loot const&, LootItem const&);
    void OnPlayerCoAProgress(Player* player, CoAProgressEvent event, uint32 value)
    {
        Progress.push_back({player->Id, event, value});
    }
} scripts;

auto sScriptMgr = &scripts;

#define CALL_ENABLED_HOOKS(Type, Hook, Call) \
    for (GroupScript* script : Scripts) \
        if (script->Enabled(Hook)) \
            Call
#define ASSERT(condition) do { if (!(condition)) throw std::runtime_error("production assertion"); } while (false)

// ACTUAL_ROLL_DISPATCH

class AscensionCollectionService
{
public:
    std::unordered_map<uint32, AppearanceInfo> _appearances;
    std::unordered_map<uint32, uint32> _itemAppearances;
    std::unordered_map<uint32, std::shared_ptr<PlayerCollectionState>> _playerStates;
    std::mutex _stateMutex;

    // ACTUAL_INSTANCE
    // ACTUAL_GET_STATE
    // ACTUAL_ROLL_STARTED
    // ACTUAL_EQUIPMENT_APPEARANCE
    // ACTUAL_COLLECT_APPEARANCE
    // ACTUAL_SEND_ADDED
};

struct AscensionCompatGroupScript : GroupScript
{
    // ACTUAL_SCRIPT_CONSTRUCTOR
    // ACTUAL_SCRIPT_ROLL
};

// ACTUAL_CAN_ROLL
// ACTUAL_GROUP_LOOT
// ACTUAL_NEED_BEFORE_GREED
// ACTUAL_SEND_START
// ACTUAL_SEND_PLAYER_START
// ACTUAL_SEND_PASS
// ACTUAL_SEND_PENDING

void Require(bool condition, std::string const& message)
{
    if (!condition)
        throw std::runtime_error(message);
}

struct RollObserver : GroupScript
{
    uint32 Calls = 0;
    explicit RollObserver() : GroupScript("observer", {GROUPHOOK_ON_LOOT_ROLL_START}) { }
    void OnLootRollStart(Group*, Roll const& roll, Loot const& loot, LootItem const& item) override
    {
        ++Calls;
        Require(roll.getLoot() == &loot && item.is_blocked && roll.totalPlayersRolling > 0,
            "collection hook must receive a fully initialized, blocked loot roll");
    }
};

void Appearance(uint32 itemId = 110, uint32 appearanceId = 210, uint32 category = 1)
{
    auto& service = AscensionCollectionService::Instance();
    service._itemAppearances[itemId] = appearanceId;
    service._appearances[appearanceId] = {itemId, category};
}

void Reset(std::vector<Player*> const& players, RollObserver& observer)
{
    auto& service = AscensionCollectionService::Instance();
    service._appearances.clear();
    service._itemAppearances.clear();
    service._playerStates.clear();
    ItemScaling::Bases.clear();
    CharacterDatabase.Writes.clear();
    scripts.Progress.clear();
    objectMgr.Items.clear();
    ObjectAccessor::Players.clear();
    Trace.clear();
    observer.Calls = 0;
    ascensionCompatConfig.Enabled = true;
    for (auto player : players)
    {
        player->Session.Packets.clear();
        player->Session.Bot = false;
        player->HasSession = true;
        player->NearLoot = player->NearGroup = true;
        player->AutoPass = false;
        player->ItemCount = 0;
        player->CanNeed = true;
        player->Inventory.clear();
        ObjectAccessor::Players[player->GetGUID()] = player;
        auto state = std::make_shared<PlayerCollectionState>();
        state->AccountId = 100 + player->Id;
        service._playerStates[player->Id] = state;
    }
    objectMgr.Items[110] = {};
    Appearance();
}

auto State(Player const& player)
{
    return AscensionCollectionService::Instance().GetState(&player);
}

void AssertCollections(std::vector<Player*> const& players, std::set<uint32> const& expected,
    uint32 appearanceId = 210, bool requirePackets = true)
{
    std::set<uint32> persisted;
    for (auto const& write : CharacterDatabase.Writes)
    {
        Require(write.Appearance && write.Values.size() == 3, "roll collection must persist only appearances");
        Require(expected.contains(write.Values[0] - 100) && write.Values[1] == appearanceId,
            "roll collection must persist each eligible human account");
        Require(persisted.insert(write.Values[0] - 100).second, "duplicate account appearance write");
        Require(AscensionCollectionService::Instance()._itemAppearances.at(write.Values[2]) == appearanceId,
            "persistent appearance source must match the rolled item");
    }
    Require(persisted == expected, "every eligible human must receive appearance persistence");
    for (auto player : players)
    {
        auto state = State(*player);
        bool const shouldCollect = expected.contains(player->Id);
        Require(!state || state->CollectedAppearances.contains(appearanceId) == shouldCollect,
            "expected roll-start appearance collection for player " + std::to_string(player->Id));
        Require(!state || state->OwnedVanityItems.empty(), "roll appearance unlock cannot grant vanity ownership");
        Require(player->Inventory.empty(), "roll appearance unlock cannot grant physical items");
        auto const packets = std::count_if(player->Session.Packets.begin(), player->Session.Packets.end(),
            [appearanceId](auto const& packet)
            {
                return packet.Opcode == SMSG_APPEARANCE_ADDED && packet.Values[0] == appearanceId;
            });
        Require(packets == (shouldCollect && requirePackets ? 1 : 0), "one appearance notification per human");
    }
    std::set<uint32> progressed;
    for (auto const& progress : scripts.Progress)
    {
        Require(progress.Event == CoAProgressEvent::AppearanceCollected && progress.Value == appearanceId,
            "roll appearance unlock reports only equipment progress");
        progressed.insert(progress.PlayerId);
    }
    Require(progressed == expected, "every eligible human must receive equipment appearance progress");
}

void FourRollPaths(RollObserver& observer)
{
    for (bool needBeforeGreed : {false, true})
        for (bool quest : {false, true})
            for (bool gameObject : {false, true})
            {
                Player loser(1), passer(2), bot(3), denied(4), far(5), offline(6), missingSession(7), capped(8);
                std::vector<Player*> const players{&loser, &passer, &bot, &denied, &far, &offline,
                    &missingSession, &capped};
                Reset(players, observer);
                passer.AutoPass = true;
                bot.Session.Bot = true;
                far.NearLoot = far.NearGroup = false;
                missingSession.HasSession = false;
                ObjectAccessor::Players.erase(offline.GetGUID());
                capped.ItemCount = 1;
                objectMgr.Items[110].MaxCount = 1;
                objectMgr.Items[110].Bonding = gameObject ? 1 : 2;
                Loot loot;
                LootItem item;
                item.Denied.insert(denied.Id);
                (quest ? loot.quest_items : loot.items).push_back(item);
                Creature creature;
                GameObject container;
                WorldObject* source = gameObject ? static_cast<WorldObject*>(&container) : &creature;
                if (gameObject)
                    loot.sourceGameObject = &container;
                Group group;
                group.LootMethod = needBeforeGreed ? NEED_BEFORE_GREED : GROUP_LOOT;
                group.AddMembers(players);
                if (needBeforeGreed)
                    group.NeedBeforeGreed(&loot, source);
                else
                    group.GroupLoot(&loot, source);
                Require(State(loser)->CollectedAppearances.contains(210),
                    "expected losing human to collect the appearance as the loot roll starts");
                AssertCollections(players, {1, 2, 8});
                Require(observer.Calls == 1 && group.RollId.size() == 1,
                    "one collection hook per newly initialized regular or quest roll");
                auto firstLoot = std::find_if(Trace.begin(), Trace.end(), [](auto const& event)
                    { return event.Opcode == SMSG_LOOT_START_ROLL || event.Opcode == SMSG_LOOT_ROLL; });
                Require(firstLoot != Trace.end(), "actual roll/pass packets must be sent");
                Require(std::count_if(Trace.begin(), firstLoot, [](auto const& event)
                    { return event.Opcode == SMSG_APPEARANCE_ADDED; }) == 3,
                    "all appearance notifications must precede the first roll-start or pass packet");
                Require(group.RollId.front()->playerVote.at(capped.GetGUID()) == PASS,
                    "quantity-capped human must still collect when automatically passing");
                if (!quest || needBeforeGreed)
                    Require(group.RollId.front()->playerVote.at(passer.GetGUID()) == PASS,
                        "configured autopass human remains a roll participant");
                Require((gameObject ? container.m_groupLootTimer : creature.m_groupLootTimer) == 60000,
                    "appearance collection preserves the loot timer");
                auto writes = CharacterDatabase.Writes.size();
                auto progress = scripts.Progress.size();
                Map map{&creature};
                group.SendPendingRollsToPlayer(&loser, &map);
                Require(observer.Calls == 1 && CharacterDatabase.Writes.size() == writes &&
                    scripts.Progress.size() == progress, "reconnect roll-packet replay cannot repeat collection hooks");
            }
}

void SelectionBoundaries(RollObserver& observer)
{
    Player human(1), peer(2);
    std::vector<Player*> const players{&human, &peer};
    for (uint32 quality : {0u, 1u, ITEM_QUALITY_UNCOMMON, ITEM_QUALITY_RARE, ITEM_QUALITY_EPIC,
             ITEM_QUALITY_LEGENDARY})
    {
        Reset(players, observer);
        objectMgr.Items[110].Quality = quality;
        Loot loot;
        loot.items.push_back({});
        Creature creature;
        Group group;
        group.m_lootThreshold = std::min(quality, ITEM_QUALITY_UNCOMMON);
        group.AddMembers(players);
        group.GroupLoot(&loot, &creature);
        AssertCollections(players, quality < ITEM_QUALITY_EPIC ? std::set<uint32>{1, 2} : std::set<uint32>{});
    }
    for (uint32 category : {0u, 15u, 56u, 69u})
    {
        Reset(players, observer);
        Appearance(110, 210, category);
        Loot loot;
        loot.items.push_back({});
        Creature creature;
        Group group;
        group.AddMembers(players);
        group.NeedBeforeGreed(&loot, &creature);
        AssertCollections(players, {});
    }
    for (uint32 boundary = 0; boundary < 5; ++boundary)
    {
        Reset(players, observer);
        Loot loot;
        loot.items.push_back({});
        if (boundary == 0)
            objectMgr.Items[110].Quality = 1;
        else if (boundary == 1)
            loot.items[0].freeforall = true;
        else if (boundary == 2)
        {
            loot.quest_items.push_back(loot.items[0]);
            loot.items.clear();
            loot.quest_items[0].follow_loot_rules = false;
        }
        else if (boundary == 3)
            human.NearLoot = peer.NearLoot = false;
        else
            loot.items[0].Denied = {1, 2};
        Creature creature;
        Group group;
        group.AddMembers(players);
        group.GroupLoot(&loot, &creature);
        Require(observer.Calls == 0 && group.RollId.empty(),
            "no collection event for under-threshold, free-for-all, ignored quest, distant, or all-pass loot");
        AssertCollections(players, {});
    }
}

void EligibilityAndData(RollObserver& observer)
{
    Player human(1), peer(2);
    std::vector<Player*> const players{&human, &peer};
    for (uint32 boundary = 0; boundary < 13; ++boundary)
    {
        Reset(players, observer);
        Loot loot;
        LootItem item;
        Roll roll({1000}, item);
        roll.playerVote = {{{1}, NOT_EMITED_YET}, {{2}, PASS}};
        auto& service = AscensionCollectionService::Instance();
        if (boundary == 0)
            service._playerStates.clear();
        else if (boundary == 1)
            ascensionCompatConfig.Enabled = false;
        else if (boundary == 2)
            objectMgr.Items.clear();
        else if (boundary == 3)
            service._itemAppearances.clear();
        else if (boundary == 4)
            service._itemAppearances[110] = 0;
        else if (boundary == 5)
            service._appearances.clear();
        else if (boundary == 6)
            roll.playerVote = {{{1}, NOT_VALID}, {{2}, NOT_VALID}};
        else if (boundary == 7)
            human.HasSession = peer.HasSession = false;
        else if (boundary == 8)
            human.Session.Bot = peer.Session.Bot = true;
        else if (boundary == 9)
            ObjectAccessor::Players.clear();
        else if (boundary == 10)
            item.Denied = {1, 2};
        else if (boundary == 11)
            loot.sourceWorldObjectGUID = {501};
        else
            objectMgr.Items[110].Quality = ITEM_QUALITY_EPIC;
        AscensionCompatGroupScript script;
        script.OnLootRollStart(nullptr, roll, loot, item);
        AssertCollections(players, {});
    }
    Reset(players, observer);
    Loot loot;
    loot.items.push_back({});
    human.NearLoot = human.NearGroup = false;
    Creature creature;
    creature.AllowedLooters.insert(human.GetGUID());
    Group group;
    group.AddMembers(players);
    group.GroupLoot(&loot, &creature);
    AssertCollections(players, {1, 2});
    Require(group.RollId.size() == 1 && group.RollId.front()->playerVote.contains(human.GetGUID()),
        "explicitly allowed looter remains eligible outside reward distance");
}

void DeduplicationAndProgress(RollObserver& observer)
{
    Player human(1), peer(2);
    std::vector<Player*> const players{&human, &peer};
    Reset(players, observer);
    Appearance(111, 210, 14);
    objectMgr.Items[111] = {};
    Loot loot;
    loot.items.push_back({});
    loot.items.push_back({});
    loot.items.back().itemid = 111;
    Creature creature;
    Group group;
    group.AddMembers(players);
    group.NeedBeforeGreed(&loot, &creature);
    AssertCollections(players, {1, 2});
    Require(observer.Calls == 2 && scripts.Progress.size() == 4,
        "shared appearances deduplicate persistence and notifications while reporting each item's progress");
    auto writes = CharacterDatabase.Writes.size();
    auto packets = human.Session.Packets.size();
    scripts.OnGroupLootRollStart(&group, *group.RollId.front(), loot, loot.items.front());
    Require(CharacterDatabase.Writes.size() == writes && human.Session.Packets.size() == packets &&
        scripts.Progress.size() == 6, "precollected appearances retain progress without duplicate writes or packets");
}

void ScaledAppearances(RollObserver& observer)
{
    Player human(1);
    constexpr uint32 scaled = 900000000;
    for (bool directMapping : {false, true})
    {
        Reset({&human}, observer);
        ItemScaling::Bases[scaled] = 110;
        objectMgr.Items[scaled] = {};
        auto& service = AscensionCollectionService::Instance();
        uint32 const expected = directMapping ? 211 : 210;
        if (directMapping)
        {
            service._itemAppearances[scaled] = expected;
            service._appearances[expected] = {110, 1};
        }
        Loot loot;
        loot.items.push_back({});
        loot.items.front().itemid = scaled;
        Creature creature;
        Group group;
        group.AddMembers({&human});
        group.GroupLoot(&loot, &creature);
        Require(State(human)->CollectedAppearances.contains(expected),
            "scaled gear must collect its source look while preserving a direct mapping");
        Require(CharacterDatabase.Writes.size() == 1 &&
            CharacterDatabase.Writes.front().Values == std::vector<uint32>{101, expected, scaled},
            "scaled gear must persist the obtained item as its collection source");
        Require(std::count_if(human.Session.Packets.begin(), human.Session.Packets.end(),
            [expected](WorldPacket const& packet)
            { return packet.Opcode == SMSG_APPEARANCE_ADDED && packet.Values[0] == expected; }) == 1,
            "scaled gear must notify the collector once");
        Require(scripts.Progress.size() == 1 && scripts.Progress.front().Value == expected,
            "scaled gear must retain equipment appearance progress");
    }
}

int main()
{
    try
    {
        AscensionCompatGroupScript script;
        RollObserver observer;
        scripts.Scripts = {&script, &observer};
        FourRollPaths(observer);
        Require(script.Enabled(GROUPHOOK_ON_LOOT_ROLL_START), "appearance roll-start hook must be registered");
        SelectionBoundaries(observer);
        EligibilityAndData(observer);
        DeduplicationAndProgress(observer);
        ScaledAppearances(observer);
        std::cout << "PASS: real group/need-before-greed regular and quest roll paths; "
            "creature and gameobject sources; "
            "roll-start dispatch and registration; losing/passing/capped humans; bot and eligibility filters; "
            "appearance notifications before roll/pass packets; uncommon/rare and epic boundaries; "
            "BOP/BOE; absent data/state and compatibility gating; no inventory/vanity grants; "
            "account persistence, deduplication, progress and reconnect packet replay\n";
    }
    catch (std::exception const& error)
    {
        std::cerr << "FAIL: " << error.what() << '\n';
        return 1;
    }
}
