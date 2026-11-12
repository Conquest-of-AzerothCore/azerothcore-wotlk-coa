# Class spell sets

## Spell set of a class

- `CharacterAdvancementClassTypes.dbc` maps a class to its ClassType rows (`ClassID` matches and `CustomClass` is 1).
  ClassType is not ClassID: Templar is ClassID 19 and ClassType 21. Non-custom types, such as the shared ClassType 12,
  are never read for a CoA class.
- Every non-zero `RankSpell[0..4]` of the `CharacterAdvancement.dbc` rows of those types is one spell id (Templar: 172).
- `ranks` is the spell id followed by the spells that `src/server/coa/AscensionSpellProgressionData.h` chains to it
  (`{ClassId, FirstSpellId, SpellId, RequiredLevel}`); `max_rank` is the last rank whose required level is at most
  `level`. `required_level` is the `CharacterAdvancement` required level of the entry that holds the spell.
- A spell the header does not chain takes its ranks from `Spell.dbc` when it is the `EffectTriggerSpell[i]` of the
  base spell of a header chain and every rank of that chain triggers its own distinct spell through the same index
  `i`, none of them in the header: the triggered spells are its ranks, each at the required level of the rank that
  triggers it ([ADR 0094](../../../../docs/adr/0094-conformance-triggered-rank-chains-come-from-the-dbc.md)). The
  rule is the same for every class (`classes.triggered_chains`), and `passives.progression_ranks` reads the same
  chains.
- `passive` is attribute bit 0x40 of the `Spell.dbc` record.
- `class_spells(..., extra_spells=())` adds base spells that `CharacterAdvancement` lacks (ADR 0016), with ranks
  from the same header and `required_level` the `Spell.dbc` `BaseLevel` of the base spell. A listed spell already in
  the set, listed twice or missing from `Spell.dbc` is an error. `generate` passes the class file's `extra_spells`;
  passive reference spells keep the `CharacterAdvancement` set.

### Extra class spells

A class file's `extra_spells` entry is `{"spell", "name", "citation"}`: the base spell id, its name and the citation of
one Ascension combat log event of the owner's private Ascension combat log archive where a player casts a rank of it
or holds its aura ([ADR 0016](../../../docs/adr/0016-conformance-class-spells-beyond-character-advancement.md) D2).
The citation is `<date> <time>, spell <logged id> <name>, Ascension combat log, private archive`, without character
names or raw lines, because the archive is private; the full lines stay in the gitignored
`.agents/plans/class-conformance-2/templar/extra-spells-evidence.md`. The log does not store a class, so the event
must come from a player who also casts a `CharacterAdvancement` active of the class in those logs.
`test_classes.py` checks the citation form, that the logged spell has the entry's name and is a rank of its chain
(Temple Guardian excepted, below), and that no spell is listed twice.

The candidates are the 34 Templar entries of `AscensionCompatData::ClassSpells`
(`src/server/coa/AscensionCustomClassData.h`, ClassId 19), none of them in `CharacterAdvancement`. Searched on
2026-11-06 by spell id, every rank of the progression header, and by name. 22 are confirmed and listed in
`classes/templar.json`: Righteous Lunge, Chastise, Gift of Zeal, Benediction, Libram of Consecration, Condemn,
Tranquil Circle, Harmonic Disposition, Testament of Faith, Holy Cleave, Beckon, Rebuke, Light's Hope, Spiritual
Ascension (a resurrection by its rank 500758), Tithe, Temple Guardian, Testament of Resolve, Libram of Grace,
Titanstrike, Crusader's Presence, Righteous Custodian and Shoot (a ranged hit; it needs a ranged weapon, so its hit
is `unmodelled`). Temple Guardian is logged at Rank 6 803796 (`Spell.dbc` `Rank[enUS]`, level 60), while the header
chains 801165 to Rank 2 803792 only, so the run judges Rank 2.

Righteous Tempest 805410 (`AscensionTemplarAbilities.cpp`'s `RighteousTempest()`, ranks 805410/570200-570205) is a
23rd `extra_spells` entry, logged at Rank 7 570205 (level 60); it is not one of the 34 `ClassSpells` candidates above
(round 3, 2026-11-08), so ADR 0016's citation mechanism applies to it independently of that candidate list. Its chain
is the one its cast ranks trigger: `EffectTriggerSpell[0]` of 805409 is 805410 and of 807269 to 807274 is 570200 to
570205, at levels 20 to 60. No player learns these tick spells, so the server header carries no rows for them
(removed 2026-11-10, owner ruling).

Not confirmed, left out: Dodge 81, Block 107, Dual Wield 674, Auto Attack 6603, Resilient Constitution 552011,
Divine Stand 807729, Detect Evil 562226, Gift of Fervor 572629, Shackle The Unrepentant 560963, Greater Gift of Fervor
572630 and Greater Gift of Zeal 680306 (no log line), and Throw 2764 (cast only by players who cast no Templar
active).
