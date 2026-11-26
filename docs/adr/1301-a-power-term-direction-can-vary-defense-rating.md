# 1301. A power term direction can vary defense rating

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Rulings: Cultist orchestrator D-38, D-39
- Follows [ADR 1192](1192-a-power-term-direction-judges-only-the-direction-with-welch-student-t-quantiles.md) and
  [ADR 1269](1269-a-power-term-direction-can-vary-agility-or-maximum-health-and-sample-a-barrier.md)

## Context

Cultist (class 25) talent Void Strikes 680609 (row 251) states:

> "Damage dealt by Blade of the Empire and Entropic Slam is now increased based on your defense rating."

`AscensionCultistAuras.cpp:235-239` refreshes helper aura 567529 (`SPELL_AURA_ADD_FLAT_MODIFIER`, `MiscValue = 3`
`SPELLMOD_EFFECT1`, class mask matching Entropic Slam 572846 and Blade of the Empire 502122) on every 2500 ms tick of
680609 to `player->GetUInt32Value(PLAYER_FIELD_COMBAT_RATING_1 + CR_DEFENSE_SKILL)`.

The tooltip states no numeric coefficient, so under D-38 only direction may be judged. `kinds/power_term_direction.py`
supported `attack_power`, `agility` and `max_health`, but not `defense_rating`, even though `CoAGameplayTest.cpp:5605`
already reads `combat_rating` index `1` (`CR_DEFENSE_SKILL`) and permanent `Spell.dbc` fixtures such as Increased
Defense 24774 (`aura 189`, `EffectMiscValue[0] = 2`, `+180` defense rating) already exist. In addition, periodic
refresh passives like 680609 need a settle wait after toggling the power aura or learning the talent, and charge-based
spells like Blade of the Empire 502122 need charges restored between casts.

## Decision

Extend `kinds/power_term_direction.py`
([doc](../../apps/coa-gameplay-test/conformance/docs/kinds/power_term_direction.md)) opt-in:

- Add `'defense_rating': 'defense rating'` to `POWER_METRICS`.
- Read `combat_rating` with `rating=1` (`CR_DEFENSE_SKILL`) before and after each arm alongside `attack_power` (as
  `agility` and `max_health` do: any move of defense rating inside an arm or any change in attack power across all
  eight reads voids the run as `unmeasured`).
- Validate in `check_power_aura` that `power_aura` carries `SPELL_AURA_MOD_RATING` (aura 189) with bit `1 << 1` (`2`,
  `CR_DEFENSE_SKILL`) set in `EffectMiscValue`.
- Add two opt-in fields defaulting to no-op (`power_settle_ms: int = 0` to wait after toggling `power_aura` or learning
  `talent`, and `restore_charges: bool = False` to emit `restore_charges` before each cast of a charge-based
  `cast_spell`). When omitted, existing scenarios, models and verdicts remain byte-identical.

## Evidence class

`power_term_direction` judges live `spell_damage_total` (an `EVENT` metric in `coverage.METRIC_EVIDENCE`) across four
arms (`control low`, `control high`, `learned high`, `learned low`) with Welch Student-t quantiles and no expected
figure — genuine `behaviour` evidence without altering `coverage.py`.

## Consequences

- Purely opt-in; finished classes regenerate byte-identical.
- Closes Cultist Void Strikes 680609 row 251 on both Blade of the Empire 502122 and Entropic Slam 572846 using
  Increased Defense 24774 (`+180` defense rating), `power_settle_ms: 3000` (above 680609's 2500 ms tick period), and
  `restore_charges: true` for 502122.
- Seeded tests in `kinds/test_power_term_direction.py` cover `ok`, mutants (flat term, control growth, drifted defense
  rating, moved attack power), `unmeasured`, `power_settle_ms`, `restore_charges`, and refusals (non-defense power aura,
  negative `power_settle_ms`, non-boolean `restore_charges`).
