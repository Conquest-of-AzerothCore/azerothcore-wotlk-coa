# 0022. Prose passives that change an existing harness metric get a `metric_delta` builder, judged by exact equality

- Status: accepted
- Date: 2026-11-07

## Context

Round 2 picked up Tyr's Guard 560649 ("Testament of Hope now summons an additional copy of yourself") and
Spiritual Abdicator 803219 ("Your Testament of Hope now reduces damage taken by an additional 5% per copy"),
both plain prose with no `$s`/`$w` token, so `passives.py`'s token-based pipeline cannot classify them
(`passives.py:509-510`: `classify` always raises `NotModelled` with no own or shared token).

Neither existing `behaviours.py` builder fits either spell's shape:

- `target_count_scenario` (`behaviour_count`) counts how many of several *nearby dummy creatures* a damage
  spell hits - wrong shape (we need the number of *summoned copies* the caster owns, not targets struck).
- `aura_spread_scenario` (also `behaviour_count`, `kind: "spread"`, ADR 0021) counts an aura spreading onto
  *other dummies* - wrong shape again (both spells' claims are about the caster's own state).
- `healing_ratio_scenario` (`behaviour_ratio`) multiplies named spells' `spell_healing_done` - wrong metric
  family (we need `owned_creature_count` and `aura_amount`, not healing).
- `shield_break_trigger_scenario` (`behaviour_trigger`) proves a scripted "always fires" cast - wrong claim
  shape entirely (both spells state a changed value, not a new trigger).

Both spells' expected values, however, are already fully covered by harness metrics other entries use
elsewhere in this same package: `owned_creature_count` (Testament of Hope's own regression scenario,
`templar-8358-testament-of-hope-copies.json`, already asserts it for entry 50250) and `aura_amount`
(the same scenario asserts it for spell 704409 effect 1). No new C++ metric is needed.

## Considered options

1. Add a third `count`-shaped field set to `TargetCountSpec`/`AuraSpreadSpec` that can target the caster's own
   state instead of a dummy. Rejected: neither dataclass's fixture model (dummy creatures at measured
   distances) has any use for this shape, and bending it would make both harder to read for their actual
   purpose.
2. Add a new, additive `MetricDeltaSpec` dataclass and `metric_delta_scenario` builder, dispatched by its own
   `entry['kind'] == 'metric_delta'` tag, generalising the with/without shape to *any* existing metric and
   field set rather than a fixed one. A new `behaviour_metric_delta` check, judged by its own rule. Chosen.

## Decision

- `behaviours.py` gains `MetricDeltaSpec` (`spell`, `name`, `quote`, `expected`, `trigger_spell`, `metric`,
  `fields`, `before_expected`, `wait_ms`, `expire_ms`), `metric_delta_scenario(class_file, spec)` and
  `metric_delta_spec(entry)`, dispatched from `behaviour_scenario` on `entry['kind'] == 'metric_delta'`. A new
  `BEHAVIOUR_METRIC_DELTA = 'behaviour_metric_delta'` check joins `BEHAVIOUR_CHECKS`/`KINDS`.
- The builder learns `trigger_spell` once up front, exactly like `aura_spread_scenario` already does for its
  own actives (ADR 0021): Testament of Hope 1397742 is not granted to the reference character automatically at
  this level either (confirmed empirically: without the explicit `learn`, both the "before" and "after"
  measurements read 0, not the DBC baseline).
- It then casts `trigger_spell`, waits `wait_ms`, measures `metric` with `fields` ("before"), `learn`s the
  passive, waits `expire_ms` (long enough for the first cast's effect to fully expire - Testament of Hope's
  copies live 20 seconds, `SpellDuration.dbc` id 18 - so it cannot contaminate the second reading), casts
  `trigger_spell` again and measures again ("after"). Both expected numbers (`before_expected`, `expected`)
  are literal DBC/tooltip-derived values, never server-chosen: the server mechanism (a stock `SpellMod` for
  560649, `templar_scaling::ModifySpellEffectBaseValue` for 803219) only explains *how* the value should
  change, never *what* it should be.
- `compare.py` gains `behaviour_metric_delta_verdict`, judging by **exact equality** (`FLOAT_EPSILON`), not the
  shared delta-scale tolerance (`compare.delta_status`/`delta_margin`) the other behaviour checks use. The
  shared margin's absolute floor of 1 unit, applied here, would make an `after` value off by exactly 1 (e.g.
  560649 not applying, `after` staying at the `before` value of 2 against an expected 3) read as `ok`: this
  check exists specifically to catch that off-by-one, so the shared tolerance cannot be reused. Both metrics
  are deterministic integer reads with no combat-roll variance (unlike `melee_damage_taken`/
  `spell_damage_taken`, which do need a tolerance band for the live combat-roll pipeline), so exact equality is
  sound, not merely convenient.
- The judge also checks `before == before_expected`, not only the delta: an implementation whose baseline
  measurement is wrong is caught even if the after value happens to match the expected final number.

## Consequences

- Tyr's Guard 560649 and Spiritual Abdicator 803219 both get an `ok` `behaviour_metric_delta` verdict in the
  scenarios this round generated and ran (`owned_creature_count` 2 -> 3; `aura_amount` -10 -> -15, both exact).
- A fourth "which metric, which field, which active spell" shape now exists alongside `count`/`ratio`/`spread`/
  `trigger`; a future passive whose claim is a before/after read of any other existing metric reuses this
  builder with new `metric`/`fields` rather than adding a fifth.
- `behaviour_metric_delta` is the first behaviour check judged by exact equality instead of the shared
  delta-scale tolerance; a reader of `verdicts.json` should not assume every behaviour check tolerates the
  same floor.
