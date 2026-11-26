# 1295. Stat arms judges strict monotonic direction over three stat levels with an unrelated-stat control

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Rulings: Cultist orchestrator D-38, D-39
- Follows [ADR 1269](1269-a-power-term-direction-can-vary-agility-or-maximum-health-and-sample-a-barrier.md) and
  [ADR 1284](1284-metric-delta-full-evidence-contrast-apply-after-trigger-and-attack-power-arms.md)

## Context

Two Cultist (class 25) clauses state a stat dependence with no numeric coefficient:

- Tentacle of N'Zoth 572103 (row 207): `"The tentacle gains health based on your Stamina."`
  `AscensionCultistSummons.cpp:128` sets `me->SetMaxHealth(std::max(1u, player->GetMaxHealth() / 3))` inside
  `IsSummonedBy()` at summon time, so changing Stamina after casting does not update an already-summoned tentacle.
  In addition, `coverage.STATE_PROMISES['owned_creature_max_health']` (`coverage.py:496`) required `r'maximum health'`,
  rejecting `"gains health"`.
- Dreadful 680579 (row 246): `"Increases your critical strike rating based on your parry and dodge rating."`
  `AscensionCultist.cpp:295-302` refreshes helper aura `681476` every 500 ms to `CR_DODGE + CR_PARRY` applied to
  `CR_CRIT_MELEE | CR_CRIT_RANGED | CR_CRIT_SPELL` (`combat_rating` 8/9/10).

## Precedent comparison (ADRs 1269 and 1284 vs D-38)

Felsworn ADRs [1269](1269-a-power-term-direction-can-vary-agility-or-maximum-health-and-sample-a-barrier.md)
(`power_term_direction`) and
[1284](1284-metric-delta-full-evidence-contrast-apply-after-trigger-and-attack-power-arms.md) (`attack_power_arms`)
established the shape for direction-only stat checks: read back the fixture stat in every arm, void the trial
(`unmeasured`) if a fixture fails to move or mismatches across arms, and judge strictly positive direction without
asserting a slope or ratio.

Both earlier tools checked only two values of the stat (low and high) with no unrelated-stat control, and
`attack_power_arms` still required placeholder `expected` / `before_expected` fields in `metric_delta`. Cultist
orchestrator decision **D-38** sets a stricter standard for unfigured `"based on"` sentences:

1. Strict monotonicity over **three or more** values of the input stat (`v[0] < v[1] < v[2] < ...`).
2. An **unrelated-stat control** proving the quantity does not move when an unrelated stat is raised.
3. **No slope, no ratio, and impossible to configure with an expected figure.**
4. Active-recast support for values snapshotted at cast time (reviewer condition for Tentacle of N'Zoth 572103).

We follow ADR 1269/1284's fixture-verification shape and adopt D-38's stricter judgement rules.

## Options

- Extend `attack_power_arms`: risks changing Felsworn's committed scenarios and cannot remove its required
  `expected`/`before_expected` fields without altering existing entries.
- Add a dedicated opt-in `metric_delta` option `stat_arms` with `FORBIDS_EXPECTED = True`, two modes (`passive` and
  `active_recast`), `>= 3` stat levels and an unrelated-stat control, plus widen `STATE_PROMISES['owned_creature_max_health']`
  to `r'(?:maximum )?health'`.

## Decision

- Add `metric_delta_options/stat_arms.py` ([doc](../../apps/coa-gameplay-test/conformance/docs/metric_delta_options/stat_arms.md))
  with `FORBIDS_EXPECTED = True`:
  - `metric_delta_options.forbids_expected(entry)` causes `behaviours.metric_delta_spec` to refuse `expected` and
    `before_expected` when `stat_arms` is set (leaving all other `metric_delta` entries untouched). `stat_arms.check`
    also refuses `expected_gain`, `expected_ratio`, `after_at_least`, `after_at_most`, `after_expiry_expected` and
    `phase_power`, and `stat_arms.parse` accepts only the exact key set `{mode, input, arms, unrelated, wait_ms}`,
    making it impossible to configure an expected figure, slope or ratio.
  - `arms` requires at least 2 distinct `(aura, stacks)` fixtures beyond baseline (`>= 3` total values of `input`).
  - `unrelated` requires a distinct `(metric, fields)` and aura from `input` and `arms`.
  - `mode: "passive"` runs the control (unlearned) and learned arms across all `>= 3` stat values plus `unrelated`,
    judging `gain[i] = learned[i] - control[i]`: strictly rising across all levels (`gain[i+1] > gain[i] + tol`,
    `gain[0] >= -tol`) and unchanged under `unrelated` (`abs(gain_unrelated - gain[0]) <= tol`).
  - `mode: "active_recast"` runs the trigger cast block repeatedly after learning the spell — once at baseline, once per
    arm with the fixture aura applied before recasting, and once with the unrelated fixture aura applied before
    recasting — judging strict monotonicity across all `>= 3` output readings and invariance under `unrelated`.
  - Every input and unrelated stat read is verified; any fixture failure or cross-arm stat mismatch voids the trial as
    `unmeasured` rather than alerting.
- Widen `coverage.STATE_PROMISES['owned_creature_max_health']` (`coverage.py:496`) from `r'maximum health'` to
  `r'(?:maximum )?health'`.

## Evidence class

A strictly monotonic read over three or more measured stat values paired with an unrelated-stat control is **behaviour**
evidence (not data readback) for a tooltip sentence that only states `"based on <stat>"`:

- The judged quantity (`owned_creature_max_health` of a live summoned creature, `combat_rating` on the live player) is a
  `STATE` metric in `coverage.METRIC_EVIDENCE` evaluated by live server mechanics under real fixture changes, not read
  back from DBC or aura metadata.
- A single on/off read cannot distinguish stat scaling from a flat bonus, and a two-point read cannot distinguish
  continuous scaling from a threshold step or coincidental stat drift. Three or more strictly rising measured levels rule
  out flat bonuses and single-step thresholds, while the unrelated-stat control rules out non-specific scaling and
  confirms the claimed stat is what drives the change.
- Together with `LEARNED_CONTRAST` and `STATE_PROMISES` (`owned_creature_max_health` matching `"gains health"`,
  `combat_rating` matching `"critical strike rating"`), this proves the full literal claim of the sentence without
  inventing an unstated coefficient.

## Consequences

- Opt-in option and audit-only regex widening: finished classes regenerate byte-identical.
- Closes Tentacle of N'Zoth 572103 row 207 (`active_recast` mode with Stamina `stat 2` and Spirit `stat 4` control) and
  Dreadful 680579 row 246 (`passive` mode for both parry rating `combat_rating 3` and dodge rating `combat_rating 2`,
  with haste rating `combat_rating 17` control). Does not cover weapon-damage-scaled Void Power 574147.
- Seeded tests cover `ok`, `alert` (flat, falling, unrelated stat moving output), `unmeasured` (missing read, broken
  input fixture, unrelated fixture leaking into input stat, cross-arm stat mismatch), refusals (fewer than 3 levels,
  any expected figure/gain/ratio/bound, same input/unrelated stat), and mutants for both modes.
