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

uint32 CategoryFromInventoryType(uint32 inventoryType)
{
    switch (inventoryType)
    {
        case INVTYPE_HEAD:
            return 1;
        case INVTYPE_SHOULDERS:
            return 2;
        case INVTYPE_CLOAK:
            return 3;
        case INVTYPE_CHEST:
        case INVTYPE_ROBE:
            return 4;
        case INVTYPE_TABARD:
            return 5;
        case INVTYPE_BODY:
            return 6;
        case INVTYPE_WRISTS:
            return 7;
        case INVTYPE_HANDS:
            return 8;
        case INVTYPE_WAIST:
            return 9;
        case INVTYPE_LEGS:
            return 10;
        case INVTYPE_FEET:
            return 11;
        case INVTYPE_RANGED:
        case INVTYPE_RANGEDRIGHT:
        case INVTYPE_THROWN:
            return 12;
        case INVTYPE_WEAPON:
        case INVTYPE_2HWEAPON:
        case INVTYPE_WEAPONMAINHAND:
            return 13;
        case INVTYPE_WEAPONOFFHAND:
        case INVTYPE_SHIELD:
        case INVTYPE_HOLDABLE:
            return 14;
        default:
            return 0;
    }
}
}
