// The announcement half of the book.
//
// A purchase learns the spell server side either way; whether the client *shows* anything is
// its own decision, and it decides from the row its SpellCustomAttr table holds for the spell.
// This pushes that row with the bit its learn handler tests, so a purchase always gets the
// "New Spell Learned" toast and its sound, whatever the table said before.
#ifndef SPELLBOOK_NOTIFY_H
#define SPELLBOOK_NOTIFY_H

#include <cstdint>
#include <vector>

class Player;

namespace SpellbookNotify
{
    /// Whether the push is switched on (Spellbook.Notify.Enable).
    bool Enabled();

    /// Marks one spell worth announcing, for as long as the client is running. Idempotent, and
    /// silent about spells a book does not offer (there is no row to push for those).
    void Push(Player *player, std::uint32_t spellId);

    /// The same for a list, in order. The bulk "learn everything" action uses it per spell, so
    /// each learn arrives announced exactly as a single purchase is.
    void Push(Player *player, std::vector<std::uint32_t> const &spellIds);

    /// Takes the notable bit off one spell's row, so the client does not announce it, until Push
    /// puts it back. A temporary spell replacement that ends tells the client it "learned" the
    /// spell it hands back; wrapped in Mute and Push, that notice stays silent while a genuine
    /// learn of the same spell is still announced.
    void Mute(Player *player, std::uint32_t spellId);

    /// Sends one spell's row with the client's quiet-learn and no-placement bits set and the notable bit
    /// cleared, so the next SMSG_LEARNED_SPELL for it prints no chat line, shows no toast and places no
    /// button. A spell
    /// with no row in the book data or the client's table borrows one spare row id.
    void Quiet(Player *player, std::uint32_t spellId);

    /// Reads Spellbook.Notify.Enable; called once at startup and on every config reload.
    void LoadConfig();

    /// Puts back the row Quiet replaced, so a later genuine learn of the spell is announced as usual.
    void Unquiet(Player *player, std::uint32_t spellId);
}

#endif
