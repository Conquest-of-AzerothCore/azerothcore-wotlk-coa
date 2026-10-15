#include "DungeonLoot.h"
#include <algorithm>
#include <cstdlib>
#include <iostream>
#include <vector>

using uint8 = std::uint8_t;
using uint32 = std::uint32_t;
constexpr uint32 MAX_NR_QUEST_ITEMS = 32;
constexpr uint32 MAX_NR_LOOT_ITEMS = 18;
constexpr uint32 ITEM_FLAG_MULTI_DROP = 1;
#define LOG_DEBUG(...) do { } while (false)

void Require(bool value)
{
    if (!value)
    {
        std::cerr << "Dungeon loot regression failed\n";
        std::exit(1);
    }
}

uint32 urand(uint32 low, uint32 high)
{
    Require(low == high);
    return low;
}

struct ItemTemplate
{
    uint32 stackSize;
    uint32 StartQuest = 0;
    uint32 GetMaxStackSize() const { return stackSize; }
    bool HasFlag(uint32) const { return false; }
};

struct ObjectManager
{
    std::unordered_map<uint32, ItemTemplate> items;
    ItemTemplate const* GetItemTemplate(uint32 item) const
    {
        auto const found = items.find(item);
        return found == items.end() ? nullptr : &found->second;
    }
} objectManager;
auto* sObjectMgr = &objectManager;

struct Player;
struct GroupReference
{
    GroupReference* next() { return nullptr; }
    Player* GetSource() { return nullptr; }
};
struct Group
{
    GroupReference* GetFirstMember() { return nullptr; }
};
struct Creature
{
    bool IsSharedQuestItem(uint32 item) const { return item == 5193; }
} testCreature;
struct Map
{
    Creature* GetCreature(uint32) { return &testCreature; }
} testMap;
struct Player
{
    Group* GetGroup() { return nullptr; }
    Map* GetMap() { return &testMap; }
} testPlayer;

namespace ObjectAccessor
{
    Player* FindPlayer(uint32) { return &testPlayer; }
}

struct LootStoreItem
{
    uint32 itemid;
    uint32 mincount;
    uint32 maxcount;
    bool needs_quest;
    std::vector<int> conditions;
};

struct LootItem
{
    uint32 itemid;
    uint32 count = 0;
    std::size_t itemIndex = 0;
    bool needs_quest = false;
    bool freeforall = false;
    bool follow_loot_rules = true;
    std::vector<int> conditions;
    explicit LootItem(LootStoreItem const& item) : itemid(item.itemid), needs_quest(item.needs_quest), conditions(item.conditions) { }
    bool AllowedForPlayer(Player*, uint32) const { return true; }
};

struct Loot
{
    uint8 dungeonDifficulty = 0;
    bool sharedQuestLoot = false;
    uint32 lootOwnerGUID = 1;
    uint32 sourceWorldObjectGUID = 2;
    uint32 unlootedCount = 0;
    std::vector<LootItem> items;
    std::vector<LootItem> quest_items;
    void AddItem(LootStoreItem const& original);
};

DungeonLoot::Variants dungeonLootVariants{{5193, {1555193, 1655193}}, {6220, {1556220, 0}}};

// ACTUAL_ADD_ITEM

int main()
{
    objectManager.items = {{5193, {20}}, {1555193, {2}}, {1655193, {3}}, {6220, {1}}, {3637, {1}}};
    LootStoreItem const row{5193, 6, 6, false, {17, 29}};
    Loot heroic;
    heroic.dungeonDifficulty = 1;
    heroic.AddItem(row);
    Require(heroic.items.size() == 3);
    for (auto const& item : heroic.items)
        Require(item.itemid == 1555193 && item.count == 2 && item.conditions == row.conditions);
    Require(row.itemid == 5193 && row.mincount == 6 && row.maxcount == 6);

    Loot mythic;
    mythic.dungeonDifficulty = 2;
    mythic.AddItem({5193, 6, 6, false, {}});
    Require(mythic.items.size() == 2 && mythic.unlootedCount == 2);
    for (auto const& item : mythic.items)
        Require(item.itemid == 1655193 && item.count == 3);
    mythic.AddItem({6220, 1, 1, false, {}});
    Require(mythic.items.back().itemid == 6220);
    mythic.AddItem({3637, 1, 1, true, {}});
    Require(mythic.quest_items.size() == 1 && mythic.quest_items[0].itemid == 3637);
    mythic.AddItem({5193, 1, 1, true, {}});
    Require(mythic.quest_items.back().itemid == 5193);

    Loot shared;
    shared.dungeonDifficulty = 2;
    shared.sharedQuestLoot = true;
    shared.AddItem({5193, 1, 1, false, {}});
    Require(shared.items.size() == 1 && shared.items[0].itemid == 1655193 && shared.quest_items.empty());

    Loot normal;
    normal.AddItem(row);
    Require(normal.items.size() == 1 && normal.items[0].itemid == 5193 && normal.items[0].count == 6);
    for (uint32 map : {33u, 34u, 36u, 43u, 47u, 48u, 70u, 90u, 109u, 129u, 189u,
                      209u, 229u, 230u, 289u, 329u, 349u, 389u, 429u})
    {
        Require(DungeonLoot::Difficulty(map, 1, true) == 1);
        Require(DungeonLoot::Difficulty(map, 2, true) == 2);
        Require(DungeonLoot::Difficulty(map, 0, true) == 0);
        Require(DungeonLoot::Difficulty(map, 3, true) == 0);
        Require(DungeonLoot::Difficulty(map, 2, false) == 0);
    }
    for (uint32 map : {0u, 1u, 409u, 531u, 574u})
        Require(DungeonLoot::Difficulty(map, 2, true) == 0);
    Require(DungeonLoot::Resolve(dungeonLootVariants, 5193, 255, false) == 5193);
    Require(DungeonLoot::Resolve(dungeonLootVariants, 99999, 1, false) == 99999);
    return 0;
}
