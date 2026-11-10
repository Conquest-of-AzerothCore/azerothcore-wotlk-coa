# 0094. Conformance takes triggered rank chains from the DBC, not from server progression rows

- Status: accepted
- Date: 2026-11-10
- Supersedes, for spells the progression header does not chain: "ranks come from
  `src/server/coa/AscensionSpellProgressionData.h`" in ADR 0011 (Expected values) and ADR 0016 D1

## Context

Righteous Tempest is cast as 805409 (ranks 807269 to 807274 in the progression header, levels 20 to 60). Its damage
is a tick spell no player learns: 805410, and 570200 to 570205 for the later ranks. The conformance tool lists 805410
as an `extra_spells` entry (ADR 0016), and needed its rank chain to judge rank 570205 at level 60 and to collapse
Argent Knight 300512's same-name targets to that rank (ADR 0017 D1). Commit 5d26c92335 gave it that chain by adding
six rows `{ 19, 805410, 570200..570205, level }` to the server header, a table the server reads to teach, list and
sell ranks (`AscensionCompat.cpp`, `AscensionClassMechanics.cpp`, `AscensionThunderkeg.cpp`, `mod-spellbook`,
`mod-coa-change-potions`). The rows existed only for the tool.

The server `Spell.dbc` already states the chain: `EffectTriggerSpell[0]` of 805409 is 805410 and of 807269 to 807274
is 570200 to 570205. Across the 457 chains of the header, eight have a base spell and ranks that each trigger a
distinct spell through one effect index, in five classes.

The owner ruled on 2026-11-10 (decision page 2): remove the six rows from the server header and let the tool take the
chain from the DBC, for every class.

## Options

1. Keep the rows. The server table carries data for a spell no player learns, and every reader of the table sees it.
2. Name 805410's chain in the Templar class file. A class-specific list of what the DBC already states.
3. Derive the chain from `Spell.dbc` triggers of a header chain, for every class. Chosen.

## Decision

`classes.triggered_chains(dbc, chains)` reads `EffectTriggerSpell[0..2]` of every base spell and rank of the header
chains. When, for one index, the base spell and every rank trigger a spell, all distinct and none of them a spell of
the header, the triggered spells form a chain: the first triggered spell is its base, the others its ranks, each at
the required level of the header rank that triggers it. `classes.progression_chains(dbc, header, class_id)` returns
the header chains plus these, a header chain winning on a shared base. `class_spells` (per class) and
`passives.progression_ranks` (all classes) both read it. The six Righteous Tempest rows are removed from
`AscensionSpellProgressionData.h` (2716 to 2710 rows).

## Consequences

- Righteous Tempest 805410 keeps ranks 805410, 570200 to 570205 and max rank 570205 at level 60, and Argent Knight's
  target still collapses to 570205. `conformance.py generate --class 19` writes byte-identical scenarios (1224) before
  and after the change.
- The seven other derived chains (Smash 570724, God-King's Might 805785, Assaulted 803109, Trueshot 562319, Justice
  524857 and 572040, Mending Mist 803538) are none of them `CharacterAdvancement` spells, so they change a class's
  spell set only when a class file lists them in `extra_spells`; they do resolve same-name passive targets of those
  classes to the level's rank.
- The server readers of the table no longer see 805410 or 570200 to 570205 as a chain; none of them names those ids.
- Unit tests: `test_classes.py` fixture tests for a derived chain and for a chain broken by a rank that triggers
  nothing; the Templar tests keep 805410's rank max 570205 and 7 ranks, and `test_passives.py` keeps the 570205
  collapse.
