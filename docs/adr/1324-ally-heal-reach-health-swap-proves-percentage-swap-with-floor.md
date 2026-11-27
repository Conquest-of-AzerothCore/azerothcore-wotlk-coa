# 1324. `ally_heal_reach` `health_swap` judge proves percentage health swaps with floor raising

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-26
- Rulings: Bloodmage (class 20) Bucket 2 tool plan (`705734` Transfusion `row#338–#339`)

## Context

Bloodmage's `705734` (*Transfusion*) swaps health percentages between the caster and a grouped ally and raises the lower
of the two health percentages to `$s1%` (`40%`, `Effect[0]`, `EffectBasePoints = 39`, `EffectDieSides = 1`) if below that
amount (`AscensionBloodmageVitality.cpp:152-177`).

`kinds/ally_heal_reach.py` already provides grouped ally placement, `caster_health` and per-ally `[health, maximum]`
fixtures with regeneration disabled, start/end `health` and `max_health` measurements, and `health_share`
(ADR 1100). However, `health_share` asserts that all `levelled` units converge to a shared average within `tolerance`;
it cannot express an asymmetric exchange of health percentages or a floor applied exclusively to the lower percentage.

## Options

- Add a separate standalone kind for health swaps: rejected, because `ally_heal_reach` already owns grouped ally
  fixtures, health/max_health phase reads, `apart` bystander controls, and optional `gate_spell` control phases.
- Extend `kinds/ally_heal_reach.py` with a `'health_swap'` judge reusing `levelled` (exactly two distinct units),
  `apart`, `tolerance`, and opt-in `floor_pct` / `floor_from_effect` / `floor_effect` fields. Chosen.

## Decision

Extend `apps/coa-gameplay-test/conformance/kinds/ally_heal_reach.py`
([doc](../../apps/coa-gameplay-test/conformance/docs/kinds/ally_heal_reach.md)):

- Add `'health_swap'` to `JUDGES_BY_NAME` and `VERDICTS`, mapping its observed metric to `HEALTH_METRIC` (`'health'`,
  `EVENT` in `coverage.METRIC_EVIDENCE`).
- Add optional `ReachCheck` fields `floor_pct: float = 0.0`, `floor_from_effect: bool = False`, and
  `floor_effect: int = 0`. When `floor_from_effect` is `True`, resolve the floor from `records.single_value(check.spell,
  check.floor_effect)` (`0..100`).
- Validate for `health_swap` that `levelled` has exactly two distinct known units disjoint from `apart`, every named
  unit carries a health fixture, `tolerance > 0`, `floor_pct` and `floor_from_effect` are mutually exclusive, and the
  two units start separated by more than `SPREAD_FLOOR * tolerance`.
- In `health_swap_verdict`, compute `lower = min(s0, s1)`, `raised = max(lower, floor)`, and
  `expected = {u0: s1 if s1 > lower else raised, u1: s0 if s0 > lower else raised}`, matching both the tooltip wording
  ("Increases the lower health percentage of the two") and `AscensionBloodmageVitality.cpp:166-169`. Require both
  swapped units to end within `tolerance` of `expected`, `apart` units to remain unchanged within `tolerance`, and (when
  `gate_spell` is present) all named units to remain unchanged in `control`.
- When `judge != 'health_swap'`, generated scenarios, models, and expectations are byte-identical.

## Consequences

- Pure Python extension; zero C++ harness changes and zero diff on finished-class snapshots (`templar (19)` and
  `necromancer (23)`).
- Giving the two swapped units distinct `maximum` health fixtures (`100000` vs `50000`) proves true percentage swapping
  and alerts on flat HP swap, averaging (`health_share`), missing floor, or over-raising the higher unit.
- Unit tests in `kinds/test_ally_heal_reach.py` cover DBC floor resolution, floor-raise, pure-swap, both-below-floor,
  gated control leakage, flat/average/no-floor mutants, close-start `unmeasured`, and schema refusals.
