#include <array>
#include <cassert>
#include <cstdint>
#include <map>
#include <optional>
#include <unordered_set>
#include <vector>

using uint32 = std::uint32_t;
using ItemPatchRow = std::array<uint32, 8>;
struct ItemTemplate
{
    uint32 ItemId, Class, SubClass;
    int SoundOverrideSubclass, Material;
    uint32 DisplayInfoID, InventoryType, Sheath;
};
struct ObjectMgr
{
    std::map<uint32, ItemTemplate> items;
    ItemTemplate const* GetItemTemplate(uint32 id) const
    {
        auto found = items.find(id);
        return found == items.end() ? nullptr : &found->second;
    }
} objects;
auto* sObjectMgr = &objects;
namespace DungeonRescale
{
std::unordered_set<uint32> owned;
bool OwnsItem(uint32 id) { return owned.contains(id); }
}
namespace Ascension
{
struct ClientItemPatches
{
    std::unordered_set<uint32> registered;
    static ClientItemPatches& Instance() { static ClientItemPatches instance; return instance; }
    bool Contains(uint32 id) const { return registered.contains(id); }
};
}
namespace ItemScaling
{
using ClientItemRow = ItemPatchRow;
// ACTUAL_ROW
struct Registry
{
    std::map<uint32, ItemTemplate> items;
    static Registry& Instance() { static Registry instance; return instance; }
    ItemTemplate const* Template(uint32 id) const
    {
        auto found = items.find(id);
        return found == items.end() ? nullptr : &found->second;
    }
};
// ACTUAL_CLIENT
}
struct PreparedPatchRows
{
    std::unordered_set<uint32> SqlItemIds;
    std::map<uint32, std::size_t> ItemRowIndexById;
    std::vector<ItemPatchRow> Items;
};
// ACTUAL_FIND

int main()
{
    PreparedPatchRows rows;
    rows.SqlItemIds = {10000082, 10010082, 10020082, 9000000};
    assert(!FindItemRow(rows, 10000082));
    for (uint32 id : {10000082u, 10010082u, 10020082u})
    {
        objects.items.emplace(id, ItemTemplate{id, 4, 1, -1, 7, 13164, 6, 0});
        DungeonRescale::owned.insert(id);
        auto row = FindItemRow(rows, id);
        assert(row && (*row == ItemPatchRow{id, 4, 1, uint32(-1), 7, 13164, 6, 0}));
    }
    objects.items.emplace(9000000, ItemTemplate{9000000, 4, 1, -1, 7, 42, 6, 0});
    assert(!FindItemRow(rows, 9000000));
    Ascension::ClientItemPatches::Instance().registered.insert(9000000);
    rows.Items.push_back({9000000, 4, 1, uint32(-1), 7, 42, 6, 0});
    rows.ItemRowIndexById.emplace(9000000, 0);
    assert(FindItemRow(rows, 9000000) == rows.Items.front());
    rows.Items.push_back({10221840, 4, 1, uint32(-1), 7, 145, 9, 0});
    rows.ItemRowIndexById.emplace(10221840, rows.Items.size() - 1);
    objects.items.emplace(10221840, ItemTemplate{10221840, 4, 1, -1, 7, 145, 9, 0});
    DungeonRescale::owned.insert(10221840);
    auto mythicVariant = FindItemRow(rows, 10221840);
    assert(mythicVariant && (*mythicVariant)[5] == 145);
    DungeonRescale::owned.insert(10000999);
    assert(!FindItemRow(rows, 10000999));
    ItemScaling::Registry::Instance().items.emplace(27000001,
        ItemTemplate{27000001, 2, 10, -1, 2, 55, 17, 2});
    auto dynamic = FindItemRow(rows, 27000001);
    assert(dynamic && (*dynamic)[5] == 55);
}
