#include "CoATbcGemRequirementsData.h"
#include <cassert>
#include <cstdint>
#include <map>
#include <set>

using uint32 = std::uint32_t;
struct ItemTemplate { uint32 GemProperties, RequiredLevel; };
struct GemPropertiesEntry { uint32 spellitemenchantement; };
struct SpellItemEnchantmentEntry
{
    uint32 GemID, requiredLevel;
    uint32 stat = 12, spell = 39958, condition = 123, skill = 755;
    bool operator==(SpellItemEnchantmentEntry const&) const = default;
};
template <class Row>
struct Store
{
    std::map<uint32, Row> rows;
    Row const* LookupEntry(uint32 id) const
    {
        auto row = rows.find(id);
        return row == rows.end() ? nullptr : &row->second;
    }
};
Store<GemPropertiesEntry> sGemPropertiesStore;
Store<SpellItemEnchantmentEntry> sSpellItemEnchantmentStore;
struct ObjectMgr
{
    std::map<uint32, ItemTemplate> items;
    ItemTemplate const* GetItemTemplate(uint32 id) const
    {
        auto item = items.find(id);
        return item == items.end() ? nullptr : &item->second;
    }
} objects;
auto* sObjectMgr = &objects;
std::set<uint32> Gems;
#define LOG_ERROR(...) (void)0
#define LOG_INFO(...) (void)0
// ACTUAL_LOAD

struct Fixture { uint32 gem, property, enchantment, minimum; };
constexpr Fixture OriginalRequirements[] = {
// ACTUAL_FIXTURE
};

int main()
{
    LoadRequirements();
    assert(Gems.empty());
    auto const row = TbcGemRequirements::Mappings.front();
    objects.items[row.gem] = {row.property, 70};
    sGemPropertiesStore.rows[row.property] = {row.enchantment};
    sSpellItemEnchantmentStore.rows[row.enchantment] = {row.gem, 70};
    LoadRequirements();
    assert(Gems.empty());
    assert(sSpellItemEnchantmentStore.rows[row.enchantment].requiredLevel == 70);
    objects.items[row.gem].RequiredLevel = 60;
    auto expected = sSpellItemEnchantmentStore.rows[row.enchantment];
    expected.requiredLevel = 60;
    LoadRequirements();
    assert(Gems.size() == 1);
    assert(sSpellItemEnchantmentStore.rows[row.enchantment] == expected);
    LoadRequirements();
    assert(sSpellItemEnchantmentStore.rows[row.enchantment] == expected);
    sSpellItemEnchantmentStore.rows[row.enchantment].requiredLevel = 55;
    LoadRequirements();
    assert(sSpellItemEnchantmentStore.rows[row.enchantment].requiredLevel == 55);
    sGemPropertiesStore.rows[row.property].spellitemenchantement = row.enchantment + 1;
    sSpellItemEnchantmentStore.rows[row.enchantment].requiredLevel = 70;
    LoadRequirements();
    assert(Gems.empty());
    assert(sSpellItemEnchantmentStore.rows[row.enchantment].requiredLevel == 70);
    sGemPropertiesStore.rows[row.property].spellitemenchantement = row.enchantment;
    sSpellItemEnchantmentStore.rows[row.enchantment].GemID = 0;
    LoadRequirements();
    assert(Gems.empty());
    assert(sSpellItemEnchantmentStore.rows[row.enchantment].requiredLevel == 70);
    objects.items.clear();
    sGemPropertiesStore.rows.clear();
    sSpellItemEnchantmentStore.rows.clear();
    for (auto const& original : OriginalRequirements)
    {
        objects.items[original.gem] = {original.property, 60};
        sGemPropertiesStore.rows[original.property] = {original.enchantment};
        sSpellItemEnchantmentStore.rows[original.enchantment] = {original.gem, original.minimum};
    }
    sSpellItemEnchantmentStore.rows[999999] = {999999, 80};
    LoadRequirements();
    assert(TbcGemRequirements::Mappings.size() == 231 && Gems.size() == 231);
    uint32 changed = 0;
    for (auto const& original : OriginalRequirements)
    {
        auto const& actual = sSpellItemEnchantmentStore.rows[original.enchantment];
        auto expected = SpellItemEnchantmentEntry{original.gem, original.minimum > 60 ? 60 : original.minimum};
        assert(actual == expected);
        changed += original.minimum > 60;
    }
    assert(changed == 165);
    assert(sSpellItemEnchantmentStore.rows[999999].requiredLevel == 80);

    constexpr Fixture Spheres[] = {{22459, 342, 2948, 70}, {22460, 341, 2947, 70}};
    for (auto const& sphere : Spheres)
    {
        objects.items[sphere.gem] = {sphere.property, sphere.minimum};
        sGemPropertiesStore.rows[sphere.property] = {sphere.enchantment};
        sSpellItemEnchantmentStore.rows[sphere.enchantment] = {sphere.gem, sphere.minimum};
    }
    LoadRequirements();
    assert(Gems.size() == 231);
    for (auto const& sphere : Spheres)
    {
        assert(sSpellItemEnchantmentStore.rows[sphere.enchantment].requiredLevel == 70);
        objects.items[sphere.gem].RequiredLevel = 60;
    }
    LoadRequirements();
    assert(Gems.size() == 233);
    for (auto const& sphere : Spheres)
    {
        auto const expected = SpellItemEnchantmentEntry{sphere.gem, 60};
        assert(Gems.count(sphere.gem));
        assert(sSpellItemEnchantmentStore.rows[sphere.enchantment] == expected);
    }
}
