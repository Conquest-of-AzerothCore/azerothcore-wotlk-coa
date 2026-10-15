/*
 * Tiraxis and the Ethereal Bazaar.
 *
 * Tiraxis stood in every Auction House and sold cosmetics for Bazaar Tokens
 * from a stock that changed several times a day. The server that ran him is
 * gone; what survives is the client's own description of him, his item pool,
 * and a capture of the fixed part of his inventory. This module rebuilds the
 * vendor from that.
 *
 * Three things are kept apart, because they behave differently:
 *
 *   The BAZAAR rotates. A timer redraws the stock from a pool of roughly four
 *   thousand vanity items, a fixed number of slots per price band.
 *
 *   CONVENIENCE is fixed. Scrolls, bags, tomes, potions - the same list every
 *   day, straight out of npc_vendor.
 *
 *   LOST CACHES are fixed too. One per vanity category, each holding a random
 *   item that used to be webshop-only and has no other source left.
 *
 * All three hang off one creature and one gossip menu.
 * WorldSession::SendListInventory takes a vendor entry, so a single NPC can
 * open three different lists without three visible NPCs standing around.
 */

#ifndef MOD_ETHEREAL_BAZAAR_H
#define MOD_ETHEREAL_BAZAAR_H

#include "Define.h"

#include <cstdint>
#include <vector>

// The creature the player talks to. The other two entries exist only to carry
// a vendor list; no creature is ever spawned for them.
constexpr uint32 BAZAAR_NPC_TIRAXIS = 900007;
constexpr uint32 BAZAAR_VENDOR_CONVENIENCE = 900008;
constexpr uint32 BAZAAR_VENDOR_LOST_CACHES = 900009;
// The Stones of Retreat get a list of their own: there are 167 of them, and
// mixed into the convenience list the player would hunt for a potion between
// a hundred and sixty place names.
constexpr uint32 BAZAAR_VENDOR_STONES = 900010;
// Heirlooms are gear, not cosmetics. They get their own entry so they do not
// bury the convenience list.
constexpr uint32 BAZAAR_VENDOR_HEIRLOOMS = 900011;
// Keeper's Scrolls, a list of their own on the live server ("Consumables").
constexpr uint32 BAZAAR_VENDOR_CONSUMABLES = 900012;

// Ascension's own "Ethereal Cache of Wares". It is sold from the first row of
// the rotating list and holds one random item out of the whole bazaar pool.
// The entry is theirs, not ours: display 61898 matches the other caches, it
// carries no loot flag, and nothing else in the world references it.
constexpr uint32 BAZAAR_CACHE_OF_WARES = 969029;

// Item 975001, "Bazaar Token". The client already carries ItemExtendedCost
// rows that charge it, which is why the ordinary vendor frame can do this at
// all: no client patch, no custom currency window.
constexpr uint32 BAZAAR_TOKEN_ITEM = 975001;

// Price bands. The rotation draws a fixed number of slots from each, and the
// band a row belongs to is decided once, when the pool is generated.
enum class BazaarBand : uint8
{
    Cheap = 0,      // below 1000 tokens
    Mid = 1,        // 1000 to 1499
    Expensive = 2   // 1500 and up
};

constexpr uint8 BAZAAR_BAND_COUNT = 3;

struct BazaarPoolEntry
{
    uint32 item = 0;
    uint32 extendedCost = 0;   // the ItemExtendedCost row that charges `price`
    uint32 price = 0;          // kept for logging; the client never sees it
    BazaarBand band = BazaarBand::Cheap;
};

class BazaarStock
{
public:
    static BazaarStock* instance();

    // Reads the pool and, if one is stored, the stock of the running rotation.
    void Load();

    // Redraws the stock and writes it to the vendor list of BAZAAR_NPC_TIRAXIS.
    void Rotate();

    // Called from the world update with the tick in milliseconds;
    // rotates once the time is up.
    void Update(uint32 diff);

    [[nodiscard]] std::size_t PoolSize(BazaarBand band) const;
    [[nodiscard]] std::size_t StockSize() const { return _stock.size(); }
    [[nodiscard]] uint64 NextRotation() const { return _nextRotation; }

private:
    void ApplyToVendor() const;
    void ClearVendor() const;
    void SaveStock() const;
    [[nodiscard]] uint32 RollInterval() const;

    std::vector<BazaarPoolEntry> _pool[BAZAAR_BAND_COUNT];
    std::vector<BazaarPoolEntry> _stock;
    uint64 _nextRotation = 0;
    uint32 _sinceCheck = 0;   // Millisekunden seit der letzten Pruefung
};

#define sBazaarStock BazaarStock::instance()

#endif  // MOD_ETHEREAL_BAZAAR_H
