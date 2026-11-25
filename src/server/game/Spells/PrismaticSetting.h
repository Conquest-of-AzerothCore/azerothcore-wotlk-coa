#ifndef AC_PRISMATIC_SETTING_H
#define AC_PRISMATIC_SETTING_H

#include "Item.h"
#include "ItemTemplate.h"

namespace PrismaticSetting
{
constexpr uint32 Spell = 8700101;
constexpr uint32 CraftSpell = 8700102;
constexpr uint32 CraftSkill = 450;
constexpr uint32 Enchantment = 3848;

inline bool IsEligible(ItemTemplate const& item)
{
    switch (item.InventoryType)
    {
        case INVTYPE_HEAD:
        case INVTYPE_SHOULDERS:
        case INVTYPE_CLOAK:
        case INVTYPE_CHEST:
        case INVTYPE_ROBE:
        case INVTYPE_WRISTS:
        case INVTYPE_HANDS:
        case INVTYPE_LEGS:
        case INVTYPE_FEET:
        case INVTYPE_WEAPON:
        case INVTYPE_2HWEAPON:
        case INVTYPE_WEAPONMAINHAND:
        case INVTYPE_WEAPONOFFHAND:
        case INVTYPE_SHIELD:
        case INVTYPE_RANGED:
            return true;
        case INVTYPE_RANGEDRIGHT:
            return item.Class == ITEM_CLASS_WEAPON && item.SubClass != ITEM_SUBCLASS_WEAPON_WAND;
        default:
            return false;
    }
}

inline bool IsApplied(Item const& item)
{
    return item.GetEnchantmentId(PERM_ENCHANTMENT_SLOT) == Enchantment &&
        item.GetEnchantmentId(PRISMATIC_ENCHANTMENT_SLOT) == Enchantment;
}

inline uint8 AddedSocket(ItemTemplate const& item)
{
    uint8 index = 0;
    while (index < MAX_ITEM_PROTO_SOCKETS && item.Socket[index].Color)
        ++index;
    return index;
}
}

#endif
