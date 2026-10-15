// Class trainer rows taken from the realm's own NPCTrainer.dbc.
//
// A row is a service that table teaches, whose skill line is one of the class's own
// tab names in the harvested original window, and which no other source sells. It is
// only kept as the continuation of an ability that class really sells - same name, or
// the same tier series (Cure * Leather, * Key, * Form) - at a level above every rank it
// sells, with the same effect signature, and never an earlier generation of a rank the
// class already has.
//
// Extracted table, not hand-written: see README.md for the trainer data it is built from.
#ifndef SPELLBOOK_TRAINER_DATA_H
#define SPELLBOOK_TRAINER_DATA_H

#include <array>
#include <cstdint>

namespace SpellbookTrainerData
{
struct Offer
{
    std::uint8_t ClassId;
    std::uint8_t RequiredLevel;
    std::uint32_t FirstSpellId;   // the rank this one upgrades, 0 when it is a first rank
    std::uint32_t SpellId;
};

inline constexpr std::array<Offer, 27> Offers =
{{
    { 12, 65, 300886, 300887 },   // Brutal Shout
    { 13, 68, 572336, 572337 },   // Malefic Wrath
    { 13, 68, 707676, 707677 },   // Power Wuju
    { 20, 66, 504134, 504135 },   // Crimson Tide
    { 20, 72, 504135, 504136 },   // Crimson Tide
    { 20, 72, 572403, 707340 },   // Sanguinary Offering
    { 21, 46, 807959, 808075 },   // Heartwood Key
    { 21, 62, 804794, 804795 },   // Cure Knothide Leather
    { 21, 72, 804794, 804796 },   // Cure Borean Leather
    { 22, 70, 802829, 802830 },   // Chromie's Wisdom
    { 24, 62, 572890, 572891 },   // Firefall
    { 24, 70, 572891, 572161 },   // Firefall
    { 24, 70, 707645, 707646 },   // Phoenix Rebirth
    { 24, 80, 707646, 707647 },   // Phoenix Rebirth
    { 26, 62, 575051, 575052 },   // Silverstream
    { 26, 68, 573345, 573346 },   // Arcane Protection
    { 26, 76, 573346, 573347 },   // Arcane Protection
    { 27, 65, 300865, 300866 },   // Devotion of Grace
    { 27, 68, 575043, 575044 },   // Devotion of Radiance
    { 28, 61, 803663, 803664 },   // Mana Module
    { 28, 66, 802691, 575027 },   // Emergency Heal
    { 29, 60, 520307, 805141 },   // Wasp Form
    { 29, 70, 520848, 520849 },   // Prayer Beads
    { 29, 80, 520849, 520850 },   // Prayer Beads
    { 32, 70, 807838, 807839 },   // Runic Tattoos: Frost
    { 32, 76, 803752, 803753 },   // Runic Tattoos: Fire
    { 32, 76, 803762, 803763 },   // Runic Tattoos: Arcane
}};
}

#endif
