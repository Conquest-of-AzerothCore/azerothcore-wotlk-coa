# 0082. `cast_in_before` flag on `metric_delta` for an active spell's own cast-time effect

- Status: accepted
- Date: 2026-11-10

## Context

Crusader's Presence 562302's remaining numeric clause, "Increases mounted movement speed by $s1%", needs a
before/after `run_speed_rate` measurement: mounted alone, then mounted with 562302 cast. Every existing
`metric_delta` entry in `classes/templar.json` measures a *passive*'s effect on a separate `trigger_spell`
(for example Whirling Tempest 300504 gates 805409's own speed buff): `trigger_spell` is cast in both the
"before" and "after" phase, and only whether `spec.spell`/`gate_spell` is *known* differs between them, since
the differentiator lives in script logic that reacts to the passive being learned.

562302 is not a passive gating another spell's effect; it is the active spell itself, already gated by the
round's own `cast_condition` entry (requires Mounted). Its own cast applies the measured aura directly
(`Unit.cpp` ~12410-12415: `SPELL_AURA_MOD_MOUNTED_SPEED_NOT_STACK`'s `non_stack_bonus` term), so
`trigger_spell == spec.spell`. Reusing `metric_delta_scenario` unmodified would cast 562302 in *both* phases
(it is cast once up front via the always-present `cast_steps()` call before the "before" measurement), making
the "before" reading already include the effect under test, with no way to observe the ungated baseline.

## Considered options

1. A new behaviour kind (e.g. `cast_metric`) dedicated to "cast an active once, read a metric, compare to an
   absolute expected value". Rejected: this duplicates `metric_delta`'s scenario-building, verdict function
   (`behaviour_metric_delta_verdict` already does an exact before/after comparison, no delta subtraction) and
   `before_label`/`after_label` machinery for no behavioural difference beyond which phase casts the trigger.
2. A second, bespoke scenario function reusing `metric_delta`'s `Expectation`/verdict shape by hand. Rejected:
   would duplicate `cast_steps()`'s mana/aura/setup-cast bookkeeping that already exists and is exercised by
   every other `metric_delta` entry.
3. A `cast_in_before: bool = True` field on `MetricDeltaSpec`, defaulting to the existing always-cast
   behaviour so every current entry is untouched, and `False` skipping the `reset_cooldown`/`cast`/`wait`
   steps (but keeping the `setup_actor_aura` fixture) in the "before" phase only. Chosen: the only change is
   which phase casts `trigger_spell`; `behaviour_metric_delta_verdict`, the `Expectation` model and the
   generic `gate_spell`-learn step between phases are all reused unchanged.

## Decision

- `behaviours.py`'s `MetricDeltaSpec` gains `cast_in_before: bool = True`. `cast_steps()` takes an
  `include_cast` parameter: when `False`, it still applies `spec.setup_actor_aura` (so the baseline state,
  e.g. being mounted, is still present) but returns before the mana/`reset_cooldown`/cast/wait steps.
  `metric_delta_scenario`'s "before" phase call passes `spec.cast_in_before`; the "after" phase call is
  unparameterised (always casts), matching every existing entry's own second-phase behaviour.
  `metric_delta_spec` reads `cast_in_before` from the entry, defaulting to `True`.
- `classes/templar.json` gains one `metric_delta` entry (`variant: "mounted_speed"`, to disambiguate the
  manifest key from 562302's existing `cast_condition` entry) for 562302's "Increases mounted movement speed
  by $s1%": `trigger_spell: 562302`, `setup_actor_aura: 458` (Brown Horse, the same fixture mount the round's
  `cast_condition` entry already proves grants `IsMounted()`), `cast_in_before: false`, `before_expected: 1.60`
  (mount alone), `expected: 2.40` (mount + 562302), both computed from `Unit::UpdateSpeed`'s own formula
  (`speed = max(non_stack_bonus, stack_bonus); AddPct(speed, main_speed_mod)`).
- No server fix: 562302's own three speed-aura effects were already correct stock engine behaviour, unaudited
  by any existing scenario until this entry.

## Consequences

- Any future Templar (or other class, since the tool stays class-agnostic) clause of the shape "cast this
  active, measure a metric that its own cast changes" can reuse `metric_delta` with `cast_in_before: false`
  instead of inventing a new kind, as long as the "after" phase's own `cast_steps()` call (always-cast) fits.
- Existing `metric_delta` entries are unaffected: `cast_in_before` defaults to `True`, so their generated
  scenarios are byte-for-byte unchanged (verified: `MetricDeltaScenarioTests` keeps asserting 2 casts for
  `tyrs_guard_entry`'s unmodified spec).
