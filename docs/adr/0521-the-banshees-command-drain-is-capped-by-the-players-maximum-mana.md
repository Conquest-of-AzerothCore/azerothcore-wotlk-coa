# 0521. The Banshee's Command drain is capped by the player's maximum mana

- Status: accepted
- Date: 2026-11-13

## Context

Raise: Banshee 504861: "Command: Drains $504862m1% of your target's mana (up to a maximum of ${$504862m1*2}% of their
own maximum mana) and deals Frost damage equal to the mana drained." Command: Banshee 504864 reads "of your own maximum
mana". `npc_ascension_necromancer::DoAction`, case 500650, capped the drain at 20% of the Banshee's own maximum mana
(154 on the reference). The owner ruled (Q-a1-4, option (b)) that the player's maximum mana caps it; the mentor
approved fix note FN-own-2.

## Decision

- The cap reads `player->GetMaxPower(POWER_MANA) / 5` (the owner of the Banshee). The 10% of the target's maximum and
  the 505225 copy stay.

## Consequences

- Regression (class file): `drain` (an enemy player with 2803 maximum mana: 280, no cap binds) and a cap-binding arm
  `drain_cap` at Magus Zabraxis 16829 (7302 maximum mana from creature_template ManaModifier 3 x
  creature_classlevelstats basemana 2434 at level 60): expected 569 (20% of the player's 2848), against 730 for the
  target's cap and 154 for the Banshee's. `drain_cap_target` and `drain_cap_player` read both maxima in the same run.
  Control: no Banshee, no hit.
- The expected value depends on the player's maximum mana; the arm reads it.
