#include <array>
#include <cassert>
#include <cstdint>
#include <initializer_list>
#include <set>
#include <vector>
using uint8 = std::uint8_t;
using uint16 = std::uint16_t;
using uint32 = std::uint32_t;
using InventoryResult = int;
using ItemPosCountVec = std::vector<int>;
enum
{
    CLASS_WARRIOR = 1,
    CLASS_HERO = 10,
    CLASS_DEMON_HUNTER = 14,
    CLASS_GUARDIAN = 18,
    CLASS_SUN_CLERIC = 27,
    ITEM_CLASS_WEAPON = 2,
    ITEM_CLASS_ARMOR = 4,
    ITEM_SUBCLASS_WEAPON_AXE2 = 1,
    ITEM_SUBCLASS_WEAPON_MACE2 = 5,
    ITEM_SUBCLASS_WEAPON_SWORD2 = 8,
    ITEM_SUBCLASS_WEAPON_POLEARM = 6,
    ITEM_SUBCLASS_WEAPON_STAFF = 10,
    ITEM_SUBCLASS_WEAPON_FISHING_POLE = 20,
    INVTYPE_2HWEAPON = 17,
    INVTYPE_WEAPON = 13,
    INVTYPE_WEAPONOFFHAND = 22,
    INVTYPE_WEAPONMAINHAND = 21,
    INVTYPE_SHIELD = 14,
    INVTYPE_HOLDABLE = 23,
    INVTYPE_RANGED = 15,
    INVTYPE_RANGEDRIGHT = 26,
    INVTYPE_THROWN = 25,
    EQUIPMENT_SLOT_MAINHAND = 15,
    EQUIPMENT_SLOT_OFFHAND = 16,
    EQUIPMENT_SLOT_RANGED = 17,
    INVENTORY_SLOT_BAG_0 = 255,
    NULL_BAG = 0,
    NULL_SLOT = 255,
    EQUIP_ERR_OK = 0,
    EQUIP_ERR_ITEM_DOESNT_GO_TO_SLOT = 1,
    EQUIP_ERR_CANT_DUAL_WIELD = 2,
    EQUIP_ERR_CANT_EQUIP_WITH_TWOHANDED = 3,
    EQUIP_ERR_ITEM_CANT_BE_EQUIPPED = 4,
    EQUIP_ERR_ITEMS_CANT_BE_SWAPPED = 5,
    EQUIP_ERR_INVENTORY_FULL = 6,
    BASE_ATTACK = 0,
    OFF_ATTACK = 1,
    TRIGGERED_FULL_MASK = 0x0007FFFF
};
struct ItemTemplate
{
    uint32 Class = 2, SubClass = 1, InventoryType = 17;
};
struct Item
{
    ItemTemplate info;
    ItemTemplate const *GetTemplate() const
    {
        return &info;
    }
};
struct Aura
{
    uint32 recalculations = 0;
    void RecalculateAmountOfEffects()
    {
        ++recalculations;
    }
};
struct Player
{
    uint32 cls = 14, level = 10;
    bool m_canTitanGrip = false, dual = true, removed = false, penalty = true;
    std::set<uint32> known = {92089};
    Item fixtureMain, fixtureOff;
    bool hasMain = true, hasOff = true;
    Aura aura;
    uint32 getClass() const
    {
        return cls;
    }
    uint32 GetLevel() const
    {
        return level;
    }
    bool HasActiveSpell(uint32 id) const
    {
        return known.count(id) != 0;
    }
    bool HasSpell(uint32 id) const
    {
        return known.count(id) != 0;
    }
    bool CanDualWield() const
    {
        return dual;
    }
    bool HasBurningCommander() const;
    bool HasValkyrGrip() const;
    bool CanTitanGrip(ItemTemplate const *weapon = nullptr) const;
    bool CanUseTwoHandWithShield(ItemTemplate const *, ItemTemplate const *) const;
    bool IsTwoHandUsed() const;
    bool FindTwoHandSlot(ItemTemplate const *) const;
    uint8 FindSwapSlot(ItemTemplate const *) const;
    InventoryResult CheckEquip(ItemTemplate const *, uint8, bool = true, bool = true);
    void AutoUnequipOffhandIfNeed(bool force = false);
    void UpdateTitansGrip();
    Item *GetItemByPos(uint8, uint8 slot) const
    {
        return slot == 15 ? (hasMain ? const_cast<Item *>(&fixtureMain) : nullptr)
                          : (hasOff ? const_cast<Item *>(&fixtureOff) : nullptr);
    }
    Item const *GetWeaponForAttack(int) const
    {
        return hasMain ? &fixtureMain : nullptr;
    }
    bool HasAura(uint32) const
    {
        return false;
    }
    void CastSpell(Player *, uint32, uint32) {}
    InventoryResult CanUnequipItem(uint16, bool) const
    {
        return EQUIP_ERR_OK;
    }
    InventoryResult CanStoreItem(uint8, uint8, ItemPosCountVec &, Item *, bool) const
    {
        return EQUIP_ERR_OK;
    }
    Aura *GetAura(uint32 id)
    {
        assert(id == 49152);
        return penalty ? &aura : nullptr;
    }
    void RemoveAurasDueToSpell(uint32 id)
    {
        if (id == 49152)
            penalty = false;
    }
};
