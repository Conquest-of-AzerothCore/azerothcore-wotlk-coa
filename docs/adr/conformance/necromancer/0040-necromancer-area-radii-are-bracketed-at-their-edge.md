# 0040. Necromancer area radii are bracketed at their edge

- Status: accepted
- Date: 2026-11-13

## Context

Claims 47.1 (Raise: Skeletal Mage 500331, "within $801513a1 yds", 801513 EffectRadiusIndex 193 = 6 yd) and 187.1
(Harrowing Winds 705745, "within $707575a1 yds of the primary target", 707575 EffectRadiusIndex 29 = 6 yd) had no
edge reading (shared ADR 0592).

## Decision

- Entries `500331 command_radius_edge` (Mage raised in the treatment only, three Command: Undead 504868) and
  `705745 radius_edge` (three Glacial Impacts 704355 with Frost Nova 122 on the primary, 1373 mana, the talent learned
  in the treatment only), kind `radius_edge`, dummies 6.775 and 7.775 yd from the primary.

## Consequences

- Expected from the DBC only: the dummy 0.5 yd inside 6 yd plus its 1.275 yd reach struck, the one 0.5 yd beyond not.
- Claim 325.0 (Corpse Explosion 533239 "to all enemies within $533240A1 yds", 10 yd): entry `533239
  corpse_radius_edge`, a Kobold Vermin 6 corpse (CombatReach 0.875, world DB) killed by Void Zone 92559, dummies 0.5 yd
  inside and beyond 10 + 0.875 + 1.275 yd of it; control: the cast before 533239 is learned. The several-corpse part of
  325.0 stays open.
