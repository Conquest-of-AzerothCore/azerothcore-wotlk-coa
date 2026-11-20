# 0682. A weapon skill rank is capped at the spell's own MaxLevel

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

`tooltip.spell_rank` reads the level part of a level-scaled token from a skill rank
([ADR 0014](0014-level-scaled-tooltip-values-use-the-skill-rank.md)). For a spell with a weapon requirement
`tooltip.rank_spell` ranks it on the weapon skill spell of the wielded subclass (5011 Crossbows, 266 Guns), and the
cap that followed used that weapon skill spell's `MaxLevel`, which is 0 for all 20 weapon skill spells of the
installed DBC. The rank therefore stayed at 5 x level: the Witch Hunter Quickdraw ranks 804193 and 806846-806850,
read with a gun or crossbow, expected the level 60 value of every rank (804193 `effect_value e1 #1` 98.3 expected,
65.71 measured). The server caps the level at the calculated spell's own `MaxLevel` when it is above 0 and the caster
is above it (`SpellEffectInfo::CalcValue`, `SpellInfo.cpp:489-492`), whatever the weapon.

## Options

- Rank on the spell's own line when the weapon skill spell has no `MaxLevel` (mentor D-46): drops the weapon branch for
  every class and moves 102 Templar expectations on 29 ranks; stopped.
- Cap the rank at 5 x the spell's own `MaxLevel` only where the server's cap binds (mentor D-54).

## Decision

- After the existing cap, `spell_rank` lowers the rank to 5 x the spell's own `MaxLevel` when that `MaxLevel` is above
  0 and below the caster's level. The cap never raises a rank, so a rank 0 read (a weapon skill spell without an
  ability row for the class) keeps no level part.

## Consequences

- Templar (19, "all" and "stack") and Necromancer (23) generate byte-identical scenarios.
- Witch Hunter (15): the six Quickdraw value scenarios 804193 and 806846-806850 change; with the reference ranged
  attack power 237 their `effect_value e1 #1` reads 65.8, 82.8, 106.0, 144.6, 169.2 and 200.4.
- Not changed: Noctis Blade 680615 (`MaxLevel` 80, above the caster) ranks on Two-Handed Swords 202, which has no Witch
  Hunter ability row, so it reads rank 0 and no level part (265 expected, 281 measured). The cap does not bind there;
  that read is the rank 0 rule of the weapon branch, shared with the Templar staff ranks on Staves 227.
- Seeded tests in `test_tooltip.py`: the cap below the player level, no cap at or under the rank's `MaxLevel`, a max
  rank, a lower skill kept, the rank 0 path unchanged, and a seeded uncapped server value that alerts.
