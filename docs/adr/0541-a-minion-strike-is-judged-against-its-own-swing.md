# 0541. A minion's command strike is judged against its own swing

- Status: accepted
- Date: 2026-11-13

## Context

Raise: Greater Skeletal Warrior 504901 states "Command: Strikes an enemy in front of it and deals Weapon Damage plus
${$570042m2+($SP*.35)*0.39}". The hit, Command: Skeletal Warriors 570042, is a SPELL_EFFECT_NORMALIZED_WEAPON_DMG of
the Warrior's weapon plus a SCHOOL_DAMAGE term, and no tool modelled a minion's normalized weapon damage (two designs
failed, ledger clause 325, G-25). The owner funded the read (Q-b2b-4 answer (a), asking whether the weapon is the
player's). The live logs answer that: 570042 tracks the Warrior's own swing, not the owner's
(`review/q-b2b-4-weapon-research.md` in the class-conformance plan folder: Command over Warrior swing median 2.12 over
168 groups, 2.00 to 2.20 over the 9 groups where the owner also swung, against 0.44 to 3.03 for the owner's swing).
The mentor ruled the expected value: 570042's non-critical hit over the same Warrior's non-critical swing at level 60,
2.0 to 2.2 live, judged in the G-19 band around 2.1. Why the factor is about 2 is not explained by the tooltip or the
DBC; the ruling records the live ratio as the expectation, not a derivation.

## Decision

- A behaviour kind `minion_swing_ratio` raises the minion with a real cast, starts its attack with one Command, then
  reads after each of `trials` Commands the minion's non-critical unblocked strike hits on the dummy and its plain
  swings, and emits a `behaviour_hit_ratio` expectation: the swing is the control arm, the strike the treatment.
- The hit ratio model takes `ratio_band`: the band is 5% of the stated ratio (10.5 bonus points at 2.1, so 1.995 to
  2.205) instead of 5% of the bonus. `Bonus` gains an optional `fixed_band`; every other judgement keeps its band.
- The minion's minimum weapon damage is recorded once, as context. No harness C++ change: every read exists.
- Entries without the new kind or field generate and judge as before (Templar `generate --class 19` and `--stack`
  byte-identical).

## Consequences

- Necromancer entry 504901 `weapon_ratio`; ledger clause 325's weapon claim gets its label.
- If the build reads outside the band, the result is a fix note with the computation read, not a change here.
- Tests: `MinionSwingRatioTests` (test_behaviours.py).
