#include <algorithm>
#include <array>
#include <cassert>
#include <cstdint>
#include <initializer_list>
#include <list>
#include <map>
#include <vector>
using uint8 = std::uint8_t;
using uint32 = std::uint32_t;
enum
{
    ITEM_CLASS_CONSUMABLE = 0, ITEM_CLASS_ARMOR = 4, ITEM_CLASS_TRADE_GOODS = 7,
    ITEM_SUBCLASS_FOOD = 5, ITEM_SUBCLASS_POTION = 1, EQUIP_ERR_OK = 0, EQUIP_ERR_NONE = 59, LOOT_CORPSE = 1,
    GLOBALHOOK_ON_BEFORE_LOOT_EQUAL_CHANCED = 1
};
struct ItemTemplate
{
    uint32 id, Class, SubClass, quality, RequiredLevel, ItemLevel;
    bool IsPotion() const { return Class == 0 && SubClass == 1; }
    uint32 GetSkill() const { return Class == 4 ? SubClass : 0; }
};
struct Manager
{
    std::map<uint32, ItemTemplate> items;
    ItemTemplate const* GetItemTemplate(uint32 id) const
    {
        auto it = items.find(id);
        return it == items.end() ? nullptr : &it->second;
    }
} manager;
auto sObjectMgr = &manager;
struct Item
{
    uint32 entry = 1397885, guid = 7;
    uint32 GetEntry() const { return entry; }
    uint32 GetGUID() const { return guid; }
};
struct Player
{
    Item item;
    uint32 level = 1, armorSkill = 1, opened = 0, acknowledgements = 0;
    bool alive = true, combat = false;
    uint32 GetLevel() const { return level; }
    bool IsAlive() const { return alive; }
    bool IsInCombat() const { return combat; }
    Item const* GetItemByGuid(uint32 guid) const { return guid == item.guid ? &item : nullptr; }
    int CanUseItem(ItemTemplate const* value) const { return value->RequiredLevel > level ? 1 : EQUIP_ERR_OK; }
    uint32 GetSkillValue(uint32 skill) const { return skill == armorSkill ? 300 : 0; }
    void SendLoot(uint32 guid, int kind) { assert(guid == item.guid && kind == LOOT_CORPSE); ++opened; }
    void SendEquipError(int error, Item* value, Item*)
    { assert(error == EQUIP_ERR_NONE && value == &item); ++acknowledgements; }
};
struct LootStoreItem { uint32 itemid, reference = 0; };
struct LootStore {} LootTemplates_Item, otherStore;
struct Loot
{
    uint32 containerGUID = 7;
    std::vector<uint32> awarded;
    void AddItem(LootStoreItem const& item) { awarded.push_back(item.itemid); }
};
struct SpellCastTargets {};
struct ItemScript
{
    explicit ItemScript(char const*) { }
    virtual bool OnUse(Player*, Item*, SpellCastTargets const&) { return false; }
};
struct GlobalScript
{
    GlobalScript(char const*, std::initializer_list<int>) { }
    virtual bool OnBeforeLootEqualChanced(Player const*, std::list<LootStoreItem*>, Loot&, LootStore const&)
    { return true; }
};
uint32 firstRoll = 0, secondRoll = 0, rolls = 0;
uint32 urand(uint32 low, uint32 high)
{
    assert(low <= high);
    return low + ((rolls++ % 2 ? secondRoll : firstRoll) % (high - low + 1));
}
