# 1048. A combat rating bonus is read and a flat chance rate can carry player ratings

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 1012 (flat_chance_rate)

## Context

Viper Ward 707329: "Chance increased based on your ranged critical strike rating." The Viper Ward rolls
`ProcChance of 712374 + GetRatingBonusValue(CR_CRIT_RANGED)` per attack (`AscensionWitchDoctorSummons.cpp:486-488`).
`viper_rate` reads the 50% base at rating 0, which does not prove the increase. A treatment at a set rating needs the
rating on the caster in a `flat_chance_rate` scenario, which has no rating fixture, and a read of the rating bonus so
that the arm is shown to carry the stated percentage (cycle 10 author P, tool note P-T5). `combat_rating` reads the raw
rating value only.

## Decision

- Harness read `combat_rating_bonus` (with `rating`, 0..24, a player): `Player::GetRatingBonusValue`, the rating
  converted to percentage points at the player's level and class. `coverage.METRIC_EVIDENCE` row (state) with the
  rating promise words.
- `flat_chance_rate` gains `player_ratings` (rating fields of the player fixture, set on the caster for both arms of
  every part) and `rating_bonus` (`rating`, `expected_pct`, `tolerance`): one `combat_rating_bonus` read per part after
  the learns; a missing read or one off the stated points makes the verdict `unmeasured`.
- Witch Doctor entry `707329 viper_rating_rate`: the `viper_rate` layout at 280 ranged critical strike rating. The bonus
  is derived from the DBC rating tables (gtCombatRatings 14.0 per point at level 60, class scalar 1.0), 20 points, so
  the stated chance is 70%, sized flip-proof (40 cycles x 17 trials x 12 parts = 8160 against 7985).

## Consequences

- Without the new fields a `flat_chance_rate` scenario is unchanged; generated scenarios of classes 19 (with and without
  `--stack`) and 23 are byte-identical. Class 13 gains 12 part scenarios.
- Catalog scenario `witch-doctor-harness-combat-rating-bonus.json` reads the bonus with and without a rating.
- Seeded tests in `kinds/test_flat_chance_rate.py`.
