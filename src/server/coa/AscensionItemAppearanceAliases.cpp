#include "AscensionItemAppearanceAliases.h"
#include "ItemTemplate.h"
#include "ObjectMgr.h"
#include <algorithm>

namespace AscensionItemAppearanceAliases
{
namespace
{
uint64 Key(ItemTemplate const& item)
{
    uint32 slot = item.InventoryType;
    switch (slot)
    {
        case INVTYPE_ROBE:
            slot = INVTYPE_CHEST;
            break;
        case INVTYPE_WEAPONMAINHAND:
        case INVTYPE_WEAPONOFFHAND:
            slot = INVTYPE_WEAPON;
            break;
        case INVTYPE_RANGEDRIGHT:
            slot = INVTYPE_RANGED;
            break;
        default:
            break;
    }
    return (uint64(item.DisplayInfoID) << 32) | (item.Class << 8) | (item.SubClass << 16) | slot;
}

bool Equipment(ItemTemplate const& item)
{
    return item.DisplayInfoID && item.InventoryType != INVTYPE_NON_EQUIP
        && (item.Class == ITEM_CLASS_ARMOR || item.Class == ITEM_CLASS_WEAPON);
}
}

void AddAliases(std::unordered_map<uint32, uint32>& mappings, std::unordered_map<uint32, uint32> const& sources)
{
    std::unordered_map<uint64, uint32> appearancesByDisplay;
    for (auto const& [appearance, entry] : sources)
    {
        ItemTemplate const* item = sObjectMgr->GetItemTemplate(entry);
        if (!item || !Equipment(*item))
            continue;
        auto const [found, inserted] = appearancesByDisplay.emplace(Key(*item), appearance);
        if (!inserted)
            found->second = std::min(found->second, appearance);
    }

    for (auto const& [entry, item] : *sObjectMgr->GetItemTemplateStore())
    {
        if (!Equipment(item) || mappings.contains(entry))
            continue;
        auto const found = appearancesByDisplay.find(Key(item));
        if (found != appearancesByDisplay.end())
            mappings.emplace(entry, found->second);
    }
}
}
