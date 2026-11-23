# 1118. One heal is summed over every unit it may reach

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0581 (behaviour kind modules), ADR 1021 (ally_heal_reach)

## Context

Three Witch Doctor claims count or pair heals across units, and no kind could judge them:

- Jungle Booms 705859 "but heals $s2 less targets." (T-b10-3): the Shrooms pulse picks 8 (5 with the talent) of its
  candidates at random, the caster among them; `ally_heal_reach` reads allies only, so the allies' sum is 4 or 5 and
  a cap of 4 or 6 overlaps it.
- Splash Potion 567736 "healing up to $i allies" (T-ally): the cap 8 needs 9 candidates, and a scenario holds 8
  players. `TARGET_CHECK_ALLY` takes any unit the caster may assist; a player may assist a creature with
  `CREATURE_TYPE_FLAG_CAN_ASSIST` (`Unit::_IsValidAssistTarget`).
- Loa's Brew 501205 "Healing a different target with Loa's Brew also heals your previous Loa's Brew target for
  $899904s1% of the amount healed." (T-ratio): the echo is half of one specific rolled heal on another unit;
  `ally_heal_reach` `share` pairs means over all heals of the source.

## Decision

- New kind module `kinds/heal_sum.py` (label `<spell> behaviour_metric_delta <name>`, model metric
  `spell_heal_count` or `spell_heal_total`, both event class): the caster, up to 7 ally players and up to 8 fixture
  creatures are read per window, as `ally_heal_reach` reads its allies (whose helpers it reuses).
- Judge `cap`: the treatment sum equals `expected`, with a gate the control sum equals `control_expected`; every unit
  must take a heal in the named witness phase, else `unmeasured`.
- Judge `pair`: the treatment total on one unit against a share of the effective healing of a source on another, in a
  stated rounding band; no source heal or an overheal of it is `unmeasured`.
- Page `docs/kinds/heal_sum.md`, seeded test `kinds/test_heal_sum.py`, list line in `behaviour-scenarios.md`.

## Consequences

- A new kind only; `ally_heal_reach` is unchanged. Generated scenarios of classes 19 (with and without `--stack`) and
  23 are byte-identical; class 13 gains three scenarios.
- Creature 631 is an assumption about the realm world database (its stock row carries type_flags 0x1000 and no CoA
  SQL touches it); a realm row without the flag makes the splash entry unmeasured, never ok.
