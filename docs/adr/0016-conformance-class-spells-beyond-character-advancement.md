# 0016. A class file may add spells outside CharacterAdvancement

- Status: accepted
- Date: 2026-11-06

## Context

ADR 0011 takes a class's spells from the client `CharacterAdvancement.dbc` rows of its custom class types (Templar:
172 spell ids). 34 Templar spells of `AscensionCompatData::ClassSpells` (`src/server/coa/AscensionCustomClassData.h`,
ClassId 19) are absent from that set, among them the abilities that Templar passives name: Righteous Lunge, Chastise,
Condemn, Holy Cleave, Benediction, Temple Guardian and Titanstrike. `coa-obtainable --class 19` reports them as not
acquirable and the live capture equals the 172. The owner answered Q3: Ascension combat logs show Templar players
casting all seven, so they belong to a live Templar's kit. The server listing a spell does not show that live players
have it.

## Considered options

1. Keep `CharacterAdvancement` as the only source. Rejected: abilities live Templars cast stay unjudged.
2. Add every server `ClassSpells` entry of the class. Rejected: server data is a reconstruction, not evidence of the
   live kit.
3. Add only spells listed in the class file, each citing the combat log event that shows a player using it.
   Chosen.

## Decision

- D1. `class_spells(..., extra_spells=())` adds each listed base spell to the `CharacterAdvancement` set, with its
  ranks from `AscensionSpellProgressionData.h` as for the others and `required_level` from the `Spell.dbc`
  `BaseLevel` of the base spell. A listed spell already in the set, listed twice, or missing from `Spell.dbc`, is an
  error.
- D2. The class file's `extra_spells` entries are `{"spell", "name", "citation"}`: the base spell id, its name, and
  the citation of one Ascension combat log event of the owner's private Ascension combat log archive where a player
  casts a rank of it or holds its aura: date, time, logged spell id and name, "Ascension combat log, private
  archive". The archive is private, so committed files carry no raw line and no character name. The player must
  also cast a `CharacterAdvancement` active of the class in the logs, so that the event shows the class using it
  (class is not in the log). Spells without such an event stay out and the package README lists them as not confirmed.
- D3. Only `generate` reads `extra_spells`. Passive reference spells (`active_class_ranks`) keep the
  `CharacterAdvancement` set.

## Consequences

- 22 of the 34 Templar spells, all actives, get value and hit entries (110 entries, 93 scenarios, offline on
  2026-11-06); 12 are listed as not confirmed.
- A log rank that the progression header lacks is judged at the header's highest rank: Temple Guardian is cast at
  Rank 6 803796 in the logs, the header chains 801165 to Rank 2 803792 only.
- Logs are recordings of what the live server did, possibly before later changes; they confirm possession, not values.
