// Prices for the books of Ascension.
//
// No original price list survives for this content: the harvested trainer window
// recorded a cost of 0 for all 3228 of its services, coa-datamine's NPCTrainer dump
// carries no cost column, and this world DB's trainer_spell prices only stock spells.
// The one price evidence that exists is this realm's own trainer table, whose modal
// price per level is exactly k * level^2 with
//
//     level  1-10  11-20  21-30  31-50  51-60  61-70  71-80
//     k          3     10     11     12     13     20     36
//
// This is that table halved - k = 1.5, 5, 5.5, 6, 6.5, 10, 18 - which keeps the
// shape the realm already charges (level driven, quadratic, same band breaks) and
// puts the dearest rank, a level-60 one, at 2g 34s.
//
// A utility row - a kit, a leather, a key, a form - is half again: those are not
// combat abilities, and the window carries a lot of them.
//
// Extracted table, not hand-written: see README.md for the price table it is built from.
#ifndef SPELLBOOK_COST_DATA_H
#define SPELLBOOK_COST_DATA_H

#include <array>
#include <cstdint>

namespace SpellbookCostData
{
struct Band
{
    std::uint8_t MaxLevel;
    std::uint8_t DoubledK;   // k * 2, so the halving is exact integer arithmetic
};

inline constexpr std::array<Band, 7> Bands = {{
    { 10, 3 },
    { 20, 10 },
    { 30, 11 },
    { 50, 12 },
    { 60, 13 },
    { 70, 20 },
    { 80, 36 },
}};

// Rows that are not combat abilities. Half price.
inline constexpr std::array<std::uint32_t, 43> UtilitySpells = {{
    500981, 504710, 504798, 520307, 561083, 573523, 706940, 800267,
    800270, 800274, 800841, 802601, 802809, 802810, 802811, 802812,
    802813, 802814, 802815, 802816, 802817, 803183, 803212, 803865,
    803866, 803867, 803868, 803869, 804682, 804759, 804790, 804791,
    804792, 804793, 804794, 804795, 804796, 805141, 805301, 807084,
    807958, 807959, 808075,
}};

inline bool IsUtility(std::uint32_t spellId)
{
    for (std::uint32_t id : UtilitySpells)
        if (id == spellId)
            return true;
    return false;
}

/// Copper a row costs at the level the window gates it at.
inline std::uint32_t Price(std::uint8_t level, std::uint32_t spellId)
{
    if (!level)
        return 0;

    std::uint32_t doubledK = Bands.back().DoubledK;
    for (Band const &band : Bands)
        if (level <= band.MaxLevel)
        {
            doubledK = band.DoubledK;
            break;
        }

    std::uint32_t const copper = (doubledK * std::uint32_t(level) * level + 1) / 2;
    return IsUtility(spellId) ? (copper + 1) / 2 : copper;
}
}

#endif
