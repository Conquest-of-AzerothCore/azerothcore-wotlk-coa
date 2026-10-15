// Rank upgrades this realm's generated progression data never resolved, recovered
// from the client's own rank ladders (coa-datamine's ability identity layer: live
// talent nodes, the CAD table, NPCTrainer and SpellRank).
//
// Only upgrades of abilities a book already sells are here: every entry's first rank
// is a row the window already offers, and RequiredLevel is the rank's Spell.dbc
// BaseLevel - the same rule spellbook.cpp uses for a chain's first rank.
//
// Extracted table, not hand-written: see README.md for the ladders it is built from.
// The one exception is the Ranger's Waterskin ladder (802810-802817), added by hand:
// its first rank, Crude Waterskin 802808, comes with the Bushcraft skill at creation
// rather than from a book, and no source above teaches the ranks above it. Rank
// numbers are Exiles DB's "Rank N" headings; levels follow the same BaseLevel rule.
#ifndef SPELLBOOK_RANK_DATA_H
#define SPELLBOOK_RANK_DATA_H

#include <array>
#include <cstdint>

namespace SpellbookRankData
{
struct Rank
{
    std::uint8_t ClassId;
    std::uint8_t RequiredLevel;
    std::uint8_t RankNumber;
    std::uint32_t RequiredSpellId;   // the highest rank the book already offers below it
    std::uint32_t SpellId;
};

inline constexpr std::array<Rank, 41> Ranks =
{{
    { 14, 65, 6, 501329, 501330 },   // DEMONHUNTER - Illidari Intuition rank 6
    { 14, 65, 7, 501329, 501331 },   // DEMONHUNTER - Illidari Intuition rank 7
    { 14, 70, 8, 501329, 501332 },   // DEMONHUNTER - Illidari Intuition rank 8
    { 14, 77, 9, 501329, 501333 },   // DEMONHUNTER - Illidari Intuition rank 9
    { 14, 80, 10, 501329, 501334 },   // DEMONHUNTER - Illidari Intuition rank 10
    { 14, 74, 12, 501329, 501336 },   // DEMONHUNTER - Illidari Intuition rank 12
    { 15, 28, 3, 802013, 501384 },   // WITCHHUNTER - Vicious Mockery rank 3
    { 15, 41, 4, 802013, 501385 },   // WITCHHUNTER - Vicious Mockery rank 4
    { 15, 54, 5, 802013, 501386 },   // WITCHHUNTER - Vicious Mockery rank 5
    { 15, 68, 6, 802013, 501387 },   // WITCHHUNTER - Vicious Mockery rank 6
    { 16, 66, 8, 501455, 501456 },   // STORMBRINGER - Aeroblast rank 8
    { 16, 74, 9, 501455, 501457 },   // STORMBRINGER - Aeroblast rank 9
    { 16, 80, 10, 501455, 501458 },   // STORMBRINGER - Aeroblast rank 10
    { 16, 64, 10, 503359, 503360 },   // STORMBRINGER - Torrential Wrath rank 10
    { 20, 51, 6, 501682, 501684 },   // SONOFARUGAL - Night Hunter's Howl rank 6
    { 20, 61, 7, 501682, 501685 },   // SONOFARUGAL - Night Hunter's Howl rank 7
    { 20, 71, 8, 501682, 501686 },   // SONOFARUGAL - Night Hunter's Howl rank 8
    { 21, 48, 8, 503454, 503455 },   // RANGER - Snapseed rank 8
    { 21, 54, 9, 503454, 503456 },   // RANGER - Snapseed rank 9
    { 21, 61, 10, 503454, 503457 },   // RANGER - Snapseed rank 10
    { 21, 68, 11, 503454, 503458 },   // RANGER - Snapseed rank 11
    { 21, 74, 12, 503454, 503459 },   // RANGER - Snapseed rank 12
    { 21, 14, 2, 802808, 802810 },   // RANGER - Rough Waterskin rank 2
    { 21, 22, 3, 802810, 802812 },   // RANGER - Doublestitched Waterskin rank 3
    { 21, 30, 4, 802812, 802813 },   // RANGER - Hardened Waterskin rank 4
    { 21, 38, 5, 802813, 802814 },   // RANGER - Refined Waterskin rank 5
    { 21, 44, 6, 802814, 802815 },   // RANGER - Expert Waterskin rank 6
    { 21, 50, 7, 802815, 802816 },   // RANGER - Superior Waterskin rank 7
    { 21, 56, 8, 802816, 802817 },   // RANGER - Masterwork Waterskin rank 8
    { 29, 62, 10, 503172, 503173 },   // PROPHET - Claw Strike rank 10
    { 29, 68, 11, 503172, 503174 },   // PROPHET - Claw Strike rank 11
    { 29, 74, 12, 503172, 503175 },   // PROPHET - Claw Strike rank 12
    { 29, 80, 13, 503172, 503176 },   // PROPHET - Claw Strike rank 13
    { 30, 66, 8, 502994, 502995 },   // REAPER - Deathwind rank 8
    { 30, 69, 9, 502994, 502996 },   // REAPER - Deathwind rank 9
    { 30, 72, 10, 502994, 502997 },   // REAPER - Deathwind rank 10
    { 30, 75, 11, 502994, 502998 },   // REAPER - Deathwind rank 11
    { 30, 78, 12, 502994, 502999 },   // REAPER - Deathwind rank 12
    { 31, 66, 9, 503264, 503265 },   // WILDWALKER - Seismic Crash rank 9
    { 31, 73, 10, 503264, 503266 },   // WILDWALKER - Seismic Crash rank 10
    { 32, 80, 10, 502630, 502631 },   // SPIRITMAGE - Smolder rank 10
}};
}

#endif
