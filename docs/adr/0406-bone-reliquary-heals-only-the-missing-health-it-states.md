# 0406. Bone Reliquary heals only the missing health it states

- Status: accepted
- Date: 2026-11-13

## Context

Bone Reliquary 803767 (the use spell of item 11521, made by Create Bone Reliquary 803771) states "Restores $s1% of
your missing health" ($s1 = 30). The Necromancer dummy handler heals that amount (ModifyHealth, AscensionNecromancer
Abilities.cpp:408-409), and AscensionNecromancerContracts.cpp turned 803767's Effect[0] SPELL_EFFECT_HEAL_PCT into a
dummy. That block sat after `if (info->SpellFamilyName != 29) return;`, and 803767 is family 27, so the stock heal of
30% of the maximum health also landed: 5000 of 10000 health read 9500 and 2000 read 7400 (pair 20261113-015053 /
-015124 and two diagnostics, build 160818c095bf). Live logs show 9 heals of 803767 at 228 to 1145, which a heal of 30%
of a level-60 caster's maximum would exceed.

## Decision

- The 803767 block runs by id before the family return; Frozen Reliquary 803773 keeps its old place (mentor ruling of
  2026-11-13: 803773 stays an observation until its own claim measures it).

## Consequences

- Bone Reliquary heals 30% of the missing health only: 5000 -> 6500 and 2000 -> 4400 of 10000, read by the
  conformance entries `803771 behaviour_metric_delta restore` and `restore_low` with a no-cast control.
- Frozen Reliquary 803773 is unchanged.
