// Public surface of the spellbook module: what the Books of Ascension would offer a player.
//
// The CoA gameplay test driver reaches it through the CoASpellbook provider this module
// registers, to assert per class that the window covers the spells the class is entitled
// to. It is deliberately tiny - the rows themselves, and whether one spell is among them -
// so it cannot become a second definition of the offer.
#ifndef SPELLBOOK_API_H
#define SPELLBOOK_API_H

#include <cstdint>
#include <vector>
#include "CoASpellbook.h"

class Player;

namespace Spellbook
{
    /// The client's "here are rows of your spell attribute table" opcode. The number comes from
    /// the client's own opcode table in Extensions.dll, where it is registered to the handler
    /// that reads one 44 byte row, and it is the same table CoA reads its ids from. The value
    /// lives in CoASpellbook.h so this module and the CoA test driver that watches for it agree.
    constexpr uint16 SMSG_PATCH_SPELL_CUSTOM_ATTR = CoASpellbook::SMSG_PATCH_SPELL_CUSTOM_ATTR;

    /// How many rows the book would show this player. Zero means no window can be built, which
    /// is the case the book falls back to a gossip option for.
    uint32 RowCount(Player *player);

    /// Whether the book would offer this spell to this player, at any level. A row the
    /// character already holds - or a spell the talent trees grant - is not a row the book
    /// shows, so this is window membership, not entitlement.
    bool OffersSpell(Player *player, uint32 spellId);

    /// Whether this player is entitled to the spell: the book would offer it, or the character
    /// already holds it in this rank or a higher one. This is the statement a coverage test
    /// wants - "the class gets this spell" - because a row that has been bought correctly
    /// leaves the window and must not read as a spell that went missing.
    bool CoversSpell(Player *player, uint32 spellId);

    /// The upgrade ranks this book sells to the player's class above the given level
    /// (SpellbookRankData), which the class ability tables do not list.
    std::vector<uint32> UpgradeRanksAbove(Player *player, uint8 level);
}

#endif
