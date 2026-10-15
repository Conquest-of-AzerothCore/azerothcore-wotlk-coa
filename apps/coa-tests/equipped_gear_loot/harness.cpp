#include <algorithm>
#include <array>
#include <atomic>
#include <cassert>
#include <cmath>
#include <initializer_list>
#include <map>
#include <string>
#include <tuple>
#include <type_traits>
#include <unordered_map>
#include <unordered_set>
#include <vector>

using uint8 = uint8_t;
using uint16 = uint16_t;
using uint64 = uint64_t;
using ObjectGuid = uint64;
constexpr uint32 CLASS_MAGE = 8;
constexpr uint32 MAX_EQUIPMENT_ITEMS = 3;
constexpr uint16 LOOT_MODE_DEFAULT = 1;
constexpr uint32 MAX_NR_LOOT_ITEMS = 16;
constexpr uint32 MAX_NR_QUEST_ITEMS = 32;
constexpr uint16 WORLDHOOK_ON_AFTER_CONFIG_LOAD = 1;
constexpr uint16 WORLDHOOK_ON_STARTUP = 2;

#define LOG_INFO(...) ((void)0)
#define LOG_ERROR(...) ((void)0)
#define LOG_DEBUG(...) ((void)0)

struct ItemTemplate
{
    std::string Name1 = "Captured wearable gear";
    uint32 Class = ITEM_CLASS_ARMOR, SubClass = 1, DisplayInfoID = 0, Quality = ITEM_QUALITY_UNCOMMON;
    uint32 InventoryType = INVTYPE_CHEST, ItemLevel = 20, RequiredLevel = 15, Bonding = BIND_WHEN_EQUIPPED;
    uint32 StartQuest = 0, RequiredSkill = 0, RequiredSpell = 0, RequiredHonorRank = 0;
    uint32 RequiredReputationFaction = 0, Flags = 0;
    int32 RandomProperty = 0, RandomSuffix = 0;
    std::array<_ItemStat, 10> ItemStat{};
    bool HasFlag(ItemFlags flag) const { return (Flags & flag) != 0; }
    uint32 GetMaxStackSize() const { return 1; }
};

struct ObjectMgr
{
    std::unordered_map<uint32, ItemTemplate> items;
    ItemTemplate const* GetItemTemplate(uint32 entry) const
    {
        auto found = items.find(entry);
        return found == items.end() ? nullptr : &found->second;
    }
    auto const* GetItemTemplateStore() const { return &items; }
} objectMgr;
auto* sObjectMgr = &objectMgr;

struct Creature;
struct WorldObject
{
    virtual ~WorldObject() = default;
    virtual Creature* ToCreature() { return nullptr; }
};
struct CreatureTemplate { uint32 unit_class = 1; };
struct Creature : WorldObject
{
    CreatureTemplate data;
    uint32 entry = 1, display = 1, level = 20;
    std::array<uint32, 3> weapons{};
    bool pet = false, summon = false, controlled = false, disabled = false, boss = false;
    bool sharedQuest = false;
    std::vector<uint64> sharedParticipants;
    bool IsPet() const { return pet; }
    bool IsSummon() const { return summon; }
    uint64 GetCharmerOrOwnerGUID() const { return controlled; }
    bool IsLootRewardDisabled() const { return disabled; }
    bool IsDungeonBoss() const { return boss; }
    uint32 GetLevel() const { return level; }
    uint32 GetEntry() const { return entry; }
    uint32 GetDisplayId() const { return display; }
    uint64 GetGUID() const { return 42; }
    uint32 GetVirtualItemId(uint32 slot) const { return weapons.at(slot); }
    bool IsSharedQuestTarget() const { return sharedQuest; }
    bool IsSharedQuestItem(uint32) const { return false; }
    auto const& GetSharedQuestParticipants() const { return sharedParticipants; }
    CreatureTemplate const* GetCreatureTemplate() const { return &data; }
    Creature* ToCreature() override { return this; }
};

struct Map
{
    std::map<uint64, Creature*> creatures;
    Creature* GetCreature(uint64 guid) const
    {
        auto found = creatures.find(guid);
        return found == creatures.end() ? nullptr : found->second;
    }
} fixtureMap;

struct CreatureDisplayInfoEntry { uint32 ExtendedDisplayInfoID = 0; };
template<class T> struct Store
{
    std::map<uint32, T> rows;
    T const* LookupEntry(uint32 entry) const
    {
        auto found = rows.find(entry);
        return found == rows.end() ? nullptr : &found->second;
    }
};
Store<CreatureDisplayInfoEntry> sCreatureDisplayInfoStore;
Store<CreatureDisplayInfoExtraEntry> sCreatureDisplayInfoExtraStore;
struct CreatureDisplayPreset { std::array<uint32, 11> items{}; };
struct Presets
{
    std::map<std::pair<uint32, uint32>, CreatureDisplayPreset> rows;
    std::map<uint64, CreatureDisplayPreset> overrides;
    CreatureDisplayPreset const* GetActivePresetOverride(uint64 guid) const
    {
        auto found = overrides.find(guid);
        return found == overrides.end() ? nullptr : &found->second;
    }
    CreatureDisplayPreset const* GetPreset(uint32 entry, uint32 display) const
    {
        auto found = rows.find({entry, display});
        return found == rows.end() ? nullptr : &found->second;
    }
} presets;
auto* sAscensionPresets = &presets;

struct Config
{
    bool coa = true, enabled = true;
    float chance = 100;
    template<class T> T GetOption(std::string const& name, T) const
    {
        if constexpr (std::is_same_v<T, bool>)
            return name == "CoA.Enable" ? coa : enabled;
        else
            return chance;
    }
} config;
auto* sConfigMgr = &config;
struct WorldScript
{
    WorldScript(char const*, std::vector<uint16>) { }
    virtual ~WorldScript() = default;
    virtual void OnAfterConfigLoad(bool) { }
    virtual void OnStartup() { }
};
uint32 choice = 0;
bool chanceResult = true;
float lastChance = 0;
bool roll_chance_f(float percent)
{
    lastChance = percent;
    return percent > 0 && chanceResult;
}
uint32 urand(uint32 min, uint32 max) { return min + choice % (max - min + 1); }

struct Player;
struct GroupReference
{
    Player* player = nullptr;
    GroupReference* following = nullptr;
    Player* GetSource() const { return player; }
    GroupReference* next() const { return following; }
};
struct Group
{
    GroupReference* first = nullptr;
    GroupReference* GetFirstMember() const { return first; }
    uint32 GetLootThreshold() const { return ITEM_QUALITY_UNCOMMON; }
};
struct Player : WorldObject
{
    uint64 guid = 1;
    Group* group = nullptr;
    bool near = true;
    uint64 GetGUID() const { return guid; }
    Group* GetGroup() const { return group; }
    Map* GetMap() const { return &fixtureMap; }
    bool IsAtLootRewardDistance(WorldObject const*) const { return near; }
};
namespace ObjectAccessor
{
std::map<uint64, Player*> players;
Player* FindPlayer(uint64 guid)
{
    auto found = players.find(guid);
    return found == players.end() ? nullptr : found->second;
}
}

struct LootStoreItem
{
    uint32 itemid;
    bool needs_quest;
    uint32 mincount, maxcount;
    std::vector<uint32> conditions;
    LootStoreItem(uint32 entry, int32, float, bool quest, uint16, uint8, int32 min, uint8 max)
        : itemid(entry), needs_quest(quest), mincount(min), maxcount(max) { }
};
struct LootItem
{
    uint32 itemid = 0, itemIndex = 0, count = 0;
    bool is_underthreshold = false, needs_quest = false, freeforall = false, follow_loot_rules = false;
    std::vector<uint32> conditions;
    explicit LootItem(LootStoreItem const& item) : itemid(item.itemid) { }
    bool AllowedForPlayer(Player const*, uint64) const { return true; }
};
struct LootStore;
struct Loot
{
    std::vector<LootItem> items, quest_items;
    uint32 unlootedCount = 0;
    bool sharedQuestLoot = false;
    uint64 lootOwnerGUID = 0, sourceWorldObjectGUID = 1, roundRobinPlayer = 0;
    std::vector<uint64> rights;
    std::map<uint64, uint32> PlayerQuestItems;
    void AddItem(LootStoreItem const&);
    bool FillLoot(uint32, LootStore const&, Player*, bool, bool, uint16, WorldObject*);
    void FillQuestLoot(Player* player) { PlayerQuestItems.emplace(player->GetGUID(), 1); }
    void FillNotNormalLootFor(Player* player)
    {
        rights.push_back(player->GetGUID());
        FillQuestLoot(player);
    }
};
struct LootTemplate
{
    uint32 existing = 0;
    void Process(Loot& loot, LootStore const&, uint16, Player*, uint8, bool) const
    {
        if (existing)
            loot.AddItem(LootStoreItem(existing, 0, 100, false, 1, 0, 1, 1));
    }
};
struct LootStore
{
    LootTemplate const* data = nullptr;
    LootTemplate const* GetLootFor(uint32) const { return data; }
    char const* GetName() const { return "bounded_loot_store"; }
} LootTemplates_Creature, LootTemplates_Item, LootTemplates_Skinning;
struct ScriptMgr
{
    uint32 calls = 0;
    void OnAfterLootTemplateProcess(Loot*, LootTemplate const* tab, LootStore const&, Player*, bool, bool, uint16)
    {
        assert(tab);
        ++calls;
    }
} scriptMgr;
auto* sScriptMgr = &scriptMgr;
