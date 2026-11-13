# 0193. Judge a flat swing bonus at a stated caster level

- Status: accepted
- Date: 2026-11-12

## Context

Holy Constitution 706323 states "Increases your damage dealt versus Undead by ${$m1+0}, scaling with level". Its
Effect[0] is SPELL_AURA_MOD_DAMAGE_DONE_CREATURE (59), Undead, 5 plus 1.5 per level from SpellLevel 28 to MaxLevel 60.
The mentor's level policy allows a lower player level when the claim is about level: levels 50 and 60, a same-level
Undead target, the same gear, the expected value computed from the tooltip formula at each level, and a statement
whether the scaling can be separated from base-stat growth. `hit_ratio` judged a percent bonus at the class level
only; the stock engine adds aura 59 only to melee (`MeleeDamageBonusDone`).

A first run read +42.3 at 60 and +32.1 at 50 against 53 and 38: every Templar damage dealt to a creature is
multiplied by the class tuning aura 887007 (aura 341), which reads -20% at 60 and -16% at 50.

## Considered options

1. A ratio of the two levels' swing means. Rejected: the base damage grows with level too.
2. A readback of 706323's amount. Already data (38 and 53 read); not an applied hit.
3. A swing difference with and without the aura at each level, expected from the tooltip at that level and scaled by
   the multiplier auras measured in the arm. Chosen.

## Decision

- `hit_ratio` takes `level` (caster and target at that level, at most the class level; skills follow it),
  `target_entry`, `refresh` (the arms' auras set again before every swing), `expected_token` (a tooltip token read at
  that level, which must not depend on stats) and `scale_auras` ([spell, effect] whose percent amounts, read in each
  arm, multiply the expected value).
- With `expected_token` the judge compares the difference of the non-critical, non-glancing per-hit means (Welch, 99%)
  with the scaled value inside the band of `bonus.bonus_band`: the larger of 5% of it and 2.
- The two arms must read the same scaling auras.
- Holy Constitution's entries carry Brute Force 54678 in both arms (SPELL_AURA_MOD_TARGET_RESISTANCE -50000,
  physical), so the target's armor clamps to 0 and the flat bonus reaches the damage unreduced.

## Consequences

- Claim 233 is behaviour proven on one counted pair: +42.45 and +42.53 against 53 x 0.80 = 42.4 at level 60, +31.61
  and +32.35 against 38 x 0.84 = 31.92 at level 50.
- Base-stat growth does not enter the difference. The class tuning does, and is read, not assumed; the tooltip states
  the amount before the tuning, as every other damage claim is judged before global multipliers.
- The band for a flat amount reuses the percent-bonus rule's numbers (5%, 2); a mentor confirmation is asked for.
- No existing scenario changes: every new field defaults to the earlier behaviour.
- Tests: `test_behaviours.LevelFlatHitRatioTests`.
