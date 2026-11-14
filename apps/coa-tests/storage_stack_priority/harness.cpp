#include <algorithm>
#include <cassert>
#include <cstdint>
#include <map>
#include <vector>
using uint8 = std::uint8_t;
using uint32 = std::uint32_t;
#define LOG_DEBUG(...)
enum InventoryResult
{
    EQUIP_ERR_OK, EQUIP_ERR_ITEM_NOT_FOUND, EQUIP_ERR_ITEMS_CANT_BE_SWAPPED,
    EQUIP_ERR_CAN_ONLY_DO_WITH_EMPTY_BAGS, EQUIP_ERR_ALREADY_LOOTED,
    EQUIP_ERR_DONT_OWN_THAT_ITEM, EQUIP_ERR_CANT_CARRY_MORE_OF_THIS,
    EQUIP_ERR_ITEM_DOESNT_GO_INTO_BAG, EQUIP_ERR_NONEMPTY_BAG_OVER_OTHER_BAG,
    EQUIP_ERR_INVENTORY_FULL
};
constexpr unsigned BAG_FAMILY_MASK_KEYS = 1;
constexpr unsigned ITEM_CLASS_CONTAINER = 1, ITEM_SUBCLASS_CONTAINER = 0;
struct ItemTemplate
{
    uint32 Stackable = 20, BagFamily = 0, ContainerSlots = 2;
    uint32 Class = ITEM_CLASS_CONTAINER, SubClass = ITEM_SUBCLASS_CONTAINER;
    uint32 GetMaxStackSize() const { return Stackable; }
    bool IsCurrencyToken() const { return false; }
} proto;
struct Manager
{
    ItemTemplate const* GetItemTemplate(uint32 entry) const { return entry == 1 ? &proto : nullptr; }
} manager;
auto* sObjectMgr = &manager;
struct Item
{
    uint32 count = 0;
    bool matching = true;
    uint32 GetCount() const { return count; }
    uint32 GetGUID() const { return 1; }
    bool IsBag() const { return false; }
    bool IsNotEmptyBag() const { return false; }
    bool IsBindedNotWith(void const*) const { return false; }
    InventoryResult CanBeMergedPartlyWith(ItemTemplate const* p) const
    {
        return matching && count < p->GetMaxStackSize() ? EQUIP_ERR_OK : EQUIP_ERR_INVENTORY_FULL;
    }
};
struct Bag : Item
{
    ItemTemplate bagProto;
    ItemTemplate const* GetTemplate() const { return &bagProto; }
    uint32 GetBagSize() const { return bagProto.ContainerSlots; }
};
bool ItemCanGoIntoBag(ItemTemplate const* item, ItemTemplate const* bag)
{
    return !bag->BagFamily || (item->BagFamily & bag->BagFamily);
}
struct ItemPosCount
{
    uint32 pos, count;
    bool isContainedIn(std::vector<ItemPosCount> const& dest) const
    {
        return std::any_of(dest.begin(), dest.end(), [&](auto const& d) { return pos == d.pos; });
    }
};
using ItemPosCountVec = std::vector<ItemPosCount>;
struct Player
{
    std::map<uint32, Item> items;
    std::map<uint8, Bag> bags;
    uint32 limit = 1000;
    Item* GetItemByPos(uint8 bag, uint8 slot) const
    {
        auto it = items.find((bag << 8) | slot);
        return it == items.end() ? nullptr : const_cast<Item*>(&it->second);
    }
    Bag* GetBagByPos(uint8 bag) const
    {
        auto it = bags.find(bag);
        return it == bags.end() ? nullptr : const_cast<Bag*>(&it->second);
    }
    uint32 GetLootGUID() const { return 0; }
    uint32 GetMaxKeyringSize() const { return KEYRING_SLOT_END - KEYRING_SLOT_START; }
    InventoryResult CanTakeMoreSimilarItems(uint32, uint32 count, Item*, uint32* excess) const
    {
        *excess = count > limit ? count - limit : 0;
        return *excess ? EQUIP_ERR_CANT_CARRY_MORE_OF_THIS : EQUIP_ERR_OK;
    }
    InventoryResult CanStoreItem_InSpecificSlot(uint8, uint8, ItemPosCountVec&, ItemTemplate const*, uint32&, bool, Item*) const;
    InventoryResult CanStoreItem_InBag(uint8, ItemPosCountVec&, ItemTemplate const*, uint32&, bool, bool, Item*, uint8, uint8) const;
    InventoryResult CanStoreItem_InInventorySlots(uint8, uint8, ItemPosCountVec&, ItemTemplate const*, uint32&, bool, Item*, uint8, uint8) const;
    InventoryResult CanStoreItem(uint8, uint8, ItemPosCountVec&, uint32, uint32, Item* = nullptr, bool = false, uint32* = nullptr) const;
};
ACTUAL_METHODS
int main()
{
    uint8 const first = INVENTORY_SLOT_BAG_START, second = first + 1;
    for (uint8 origin : { uint8(INVENTORY_SLOT_BAG_0), first })
    {
        Player player;
        player.bags[first] = Bag{};
        player.bags[second] = Bag{};
        uint8 const start = origin == INVENTORY_SLOT_BAG_0 ? INVENTORY_SLOT_ITEM_START : 0;
        uint32 const position = (origin << 8) | start;
        uint32 const other = (second << 8);
        player.items[position] = Item{19};
        player.items[other] = Item{18};
        ItemPosCountVec dest;
        assert(player.CanStoreItem(origin, start, dest, 1, 3) == EQUIP_ERR_OK);
        assert(dest.size() == 2 && dest[0].pos == position && dest[0].count == 1);
        assert(dest[1].pos == other && dest[1].count == 2);
        dest.clear();
        assert(player.CanStoreItem(origin, start, dest, 1, 5) == EQUIP_ERR_OK);
        assert(dest.size() == 3 && dest[1].pos == other && dest[1].count == 2);
        assert(dest[2].pos == position + 1 && dest[2].count == 2);
        dest.clear();
        assert(player.CanStoreItem(origin, start + 1, dest, 1, 3) == EQUIP_ERR_OK);
        assert(dest.size() == 1 && dest[0].pos == position + 1 && dest[0].count == 3);
        player.limit = 2;
        uint32 excess = 0;
        dest.clear();
        assert(player.CanStoreItem(origin, start, dest, 1, 3, nullptr, false, &excess) == EQUIP_ERR_CANT_CARRY_MORE_OF_THIS);
        assert(excess == 1 && dest.size() == 2 && dest[0].count + dest[1].count == 2);
    }
    Player player;
    player.bags[first].bagProto.BagFamily = BAG_FAMILY_MASK_KEYS;
    ItemPosCountVec dest;
    assert(player.CanStoreItem(first, 0, dest, 1, 1) == EQUIP_ERR_ITEM_DOESNT_GO_INTO_BAG);
    assert(dest.empty());
}
