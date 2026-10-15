/*
 * Worldforged upgrades: the Guardian of Time and his two custom stores.
 *
 * A Worldforged item can be traded up: hand in the base item plus Runes of
 * Ascension and get the next rank back. The window this ran in is not an
 * ordinary vendor frame. Ascension's client ships its own `RPGItemStore`,
 * driven by a small protocol of its own, and that protocol is what this module
 * speaks. No client patch is involved: the frame, the two store ids and the
 * currency it displays are all already in the client.
 *
 * What the client brings, and where it is written down:
 *
 *   Interface/SharedXML/Enum.lua      Enum.CustomStores.RPGWeaponStore = 8,
 *                                     RPGArmorStore = 9
 *   Interface/FrameXML/HeirloomStore  RPGItemStoreMixin, item 375250 as the
 *                                     visible currency
 *   Interface/FrameXML/CustomVendor   the list, the filter, the purchase
 *                                     confirmation, and the field order of one
 *                                     store record
 *
 * The item pairs come from ItemAddon.dbc: column f40 of an upgraded variant
 * holds the id of its base item. 1738 first-rank upgrades survive that way and
 * every row of both sides already exists in item_template.
 *
 * The prices do not survive. They are computed in the SQL generator and kept in
 * a column of their own, so a real capture can replace them without touching
 * any code.
 *
 * Above the first rank an item climbs five more tiers, each one sitting at a
 * fixed id offset from the first-rank item. Every tier past the first opens for
 * the whole account once one of its characters has defeated a raid's last boss:
 * Hakkar, Ragnaros, Onyxia, Nefarian and C'Thun, in that order. The kills are
 * kept in the characters database (`worldforged_account_unlock`), and kills made
 * before that table existed are read back from the achievement statistics.
 */

#ifndef MOD_WORLDFORGED_UPGRADES_H
#define MOD_WORLDFORGED_UPGRADES_H

#include "Define.h"

#include <cstdint>
#include <unordered_map>
#include <vector>

namespace Worldforged
{
    // Seen under this entry in the creature caches of Area 52, Bronzebeard,
    // Darkmoon, Vol'jin and Rexxar, and in Creature.dbc, always with the same
    // name, subtitle and model.
    constexpr uint32 GUARDIAN_ENTRY = 9780012;

    // "Rune of Ascension". The store window reads this one directly, so it
    // cannot be swapped for another currency without a client change.
    constexpr uint32 CURRENCY_ITEM = 375250;

    // The client's own store numbering, from Enum.CustomStores.
    constexpr uint32 STORE_WEAPONS = 8;
    constexpr uint32 STORE_ARMOUR = 9;

    // Opcode names are the client's own, taken from the handler table in
    // Extensions.dll rather than guessed.
    constexpr uint16 CMSG_QUERY_CUSTOM_STORE = 0x06B9;
    constexpr uint16 SMSG_QUERY_CUSTOM_STORE_RESULT = 0x06BA;
    constexpr uint16 CMSG_PURCHASE_CUSTOM_STORE_ITEM = 0x06BB;
    constexpr uint16 SMSG_PURCHASE_CUSTOM_STORE_ITEM_RESULT = 0x06BC;
    constexpr uint16 SMSG_OPEN_CUSTOM_STORE = 0x073E;

    // One row of a store answer. The client reads a fixed 64 bytes per entry;
    // the layout is written down at BuildStoreRecord().
    constexpr uint32 RECORD_SIZE = 64;

    // The strings the client compares against. Anything else is shown to the
    // player as an error, so failure messages may be plain text.
    constexpr char const* RESULT_QUERY_OK = "QUERY_CUSTOM_STORE_OK";
    constexpr char const* RESULT_PURCHASE_OK = "PURCHASE_CUSTOM_STORE_ITEM_OK";

    struct Recipe
    {
        uint32 key = 0;          ///< what the client sends back when buying
        uint32 store = 0;
        uint32 baseItem = 0;
        uint32 targetItem = 0;
        uint32 cost = 0;         ///< Runes of Ascension
        uint32 unlockCreature = 0; ///< raid boss the account must have defeated; 0 is always open
    };

    /// All recipes, by their key. Filled once at startup.
    std::unordered_map<uint32, Recipe> const& Recipes();

    /// The recipes of one store, in the order they were loaded.
    std::vector<Recipe const*> const& RecipesOfStore(uint32 store);

    void LoadRecipes();

    /// Whether some character of the account has defeated this boss.
    bool IsUnlocked(uint32 accountId, uint32 creature);

    /// Whether a recipe waits on this creature's death.
    bool IsUnlockCreature(uint32 creature);
}

#endif
