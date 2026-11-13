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

- Regression (class file), every arm at a creature with 823764 on the caster (unresisted copy), control without a
  Banshee (no hit):
  - `drain_share` at Mylentha Riverbend 11795 (2434 maximum mana, ManaModifier 1 x basemana 2434): 10% = 243, no cap
    binds; `drain_share_target` reads the 2434.
  - `drain_cap` at Magus Zabraxis 16829 (7302 maximum mana, ManaModifier 3 x basemana 2434) with Mental Acuity 4270
    (+330 mana) on the player: expected 635 (20% of the player's 3178), against 730 for the target's cap and 594 for
    the Banshee's (its mana is level x 30 + Intellect x 5 x 2 Life Force in `Scale()`, 2970 read). Both
    alternatives lie outside the G-19 band of 635. `drain_cap_target` and `drain_cap_player` read both maxima.
- At an enemy player (`drain`, 2803 maximum mana) the hit stays 154 for a drain of 280 (the player's mana falls by
  about 280 less regeneration): damage dealt to a player is reduced by a separate rule, so the 154 measured before
  this change was not the Banshee's cap. The factor 0.55 is not identified (Resilient Constitution's default 50%
  would give 140).
- The expected value depends on the player's maximum mana; the arm reads it.
