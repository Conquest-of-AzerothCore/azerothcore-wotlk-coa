# 0015. Split long hit scenarios into parts and equip an alternate reference weapon

- Status: accepted
- Date: 2026-11-06

## Context

ADR 0011 judges the mean hit of each active's highest rank from enough casts for a 1% half-width at 99%. A
rolled effect can need more casts than one scenario holds: Righteous Upheaval 572027 needs 335 casts (503
scheduled, 762.5 s with the settle and drain) and Reckoning 572741 needs 722 (1083 scheduled, 1903 s), while a scenario
ends at 600 s. Phase 1 left them `unmodelled`.

The Templar reference weapon is the Walking Stick, a staff. Vindication 573324 (all its ranks) and Righteous
Upheaval rank 1 501562 require a weapon whose subclass is in `EquippedItemSubClassMask` 41105 (one-handed axe,
mace, sword, fist weapon, dagger): with the staff the cast fails, so neither can be measured. The owner answered
Q9: add a second, one-handed reference weapon to the class file.

## Considered options

1. Raise the scenario limit. Rejected: the 600 s limit and its 60 s margin belong to the harness.
2. Fewer casts for long hits. Rejected: it widens the interval of exactly the spells with the largest spread.
3. Split the casts into parts, as proc and trigger scenarios do (design D16), and sum the parts. Chosen.
4. Replace `weapon` with a list of weapons in the class file. Rejected: every reader of `weapon` would change for
   two spells.
5. Keep `weapon` and add `alternate_weapons`, chosen per rank by its equip requirement. Chosen.

## Decision

- D1. `hit_parts` splits the scheduled casts as evenly as possible into the fewest parts whose casts fit
  `PART_BUDGET_MS` (532 s). Each part is a full scenario with the same labels; a hit that fits one scenario keeps
  its key, the parts of a longer one are keyed `conformance-<class>-hit-<rank>-part-<n>`.
- D2. The comparison gives one verdict per hit label: totals and counts summed over the parts with a result, the
  model recomputed per part from that part's measured stats and target and pooled by its hit count.
- D3. A rank whose `EquippedItemClass` is 2 and whose subclass or inventory-type mask excludes `weapon` takes the
  first `alternate_weapons` entry that fits, with that weapon's skill line set and measured like the others. Its
  value scenario, generated tokens, hit scenario and comparison use it. Without one, its hit is `unmodelled` with
  the excluding field.
- D4. The Templar alternate weapon is the Frostmane Club 2259, a white one-handed mace of item level 6 like the
  Walking Stick, without stats or spells (`item_template` and `Item.dbc`, cited in the package README).

## Consequences

- Righteous Upheaval, Reckoning and Vindication get `hit_mean` verdicts; a missing part lowers the summed count
  and can make the verdict `insufficient_trials`, never `ok` on fewer hits than `minimum_hits`.
- A full run of these hits takes about 50 minutes of waits.
- Passive, proc, trigger and stack scenarios still equip `weapon` only.
