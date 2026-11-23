# 0032. A `duration_refresh` behaviour kind, and `metric_delta`'s `target`/`disable_regeneration` fields

- Status: accepted
- Date: 2026-11-09

## Context

Round 4's trigger-lot r4-1 investigation (`trigger-lot-r4-1-spec.md`) found two Templar passives whose tooltip
claim is genuinely open, after correcting six false positives the dispatch's grep-based premise caught (the
`passives.py` per-effect default label, not evidence a dedicated check is missing):

- Blessing of Aggramar 300502 ("Casting an Oath Breaker with 10 stacks of your Oath Chain now refreshes the
  duration of Blade of Faith on all nearby enemies") refreshes an *existing* aura's remaining duration back to
  its own maximum when a named breaker spell is cast at a stack-gated condition. No existing `behaviours.py` kind
  fits: `duration_scenario` (`behaviour_duration`) forces one melee crit to read a *decrease* against a running
  debt mechanism (Sacred Oath's shape); `mechanic_duration_scenario` (`behaviour_duration_ratio`) compares two
  *fresh* applications of a stock vehicle spell, never a refresh of one aura already applied.
- Warrior of Tyr 301253 ("Periodic damage dealt now generates 10 Energy") is a power gain through
  `AscensionCustomResourceData.h`'s `NativePowerGainRules` (a generic, class-agnostic native-resource-rule table,
  unrelated to the `ProcFlags`/`spell_proc` path `AscensionTemplarEvents.cpp` implements, which a prior
  investigation searched exhaustively and correctly found nothing in). `metric_delta_scenario` (ADR 0022) already
  fits the shape — a before/after read of an existing harness metric (`power`) around a named active cast — but
  two of its fixed assumptions do not hold for this spell: the trigger spell (Condemn 567541) needs a hostile
  target, not the caster (`metric_delta_scenario` hardcoded `target: CASTER`), and Energy is a resource that
  regenerates on its own, which an exploratory run showed makes the check's absolute-value baseline
  nondeterministic (see Consequences).

## Considered options

For 300502:

1. Stretch `duration_scenario` to cover a refresh instead of a reduction. Rejected: its whole fixture (a debt
   aura that must carry a nonzero debt amount before the forced crit, a striker creature) exists specifically to
   exercise `ReduceDebt`'s own early-removal branch for Sacred Oath's distinct mechanism; none of it applies to
   a stack-gated duration reset.
2. Stretch `mechanic_duration_scenario` to measure a refresh instead of two independent fresh applications.
   Rejected: its two reads are deliberately separated by a diminishing-returns reset window specific to stock
   mechanic-duration mods; a refresh needs the *same* application read twice, with a breaker cast in between.
3. Add a new, additive `DurationRefreshSpec`/`duration_refresh_scenario`, dispatched by its own
   `entry['kind'] == 'duration_refresh'` tag, with its own `behaviour_duration_refresh` check. Chosen.

For 301253's two `metric_delta` gaps:

1. Add a new `kind` just for this spell. Rejected: the shape (before/after read of an existing metric around a
   named active cast) is still exactly `metric_delta`'s; only two fixed assumptions needed relaxing, not the
   builder itself.
2. Add `target`/`disable_regeneration` as optional fields on `MetricDeltaSpec`, defaulting to the prior fixed
   behaviour (`target: CASTER`, regeneration left alone) so every existing entry is unaffected. Chosen.

## Decision

- `behaviours.py` gains `DurationRefreshSpec` (`spell`, `name`, `quote`, `target_aura`, `gating_aura`,
  `gating_stacks`, `apply_spell`, `breaker_spell`, `decay_ms`, `refresh_margin_ms`), `duration_refresh_scenario`
  and `duration_refresh_spec`, dispatched from `behaviour_scenario` on `entry['kind'] == 'duration_refresh'`. A
  new `BEHAVIOUR_DURATION_REFRESH = 'behaviour_duration_refresh'` check joins `BEHAVIOUR_CHECKS`/`KINDS`.
  - The scenario runs two phases (`without`/`with` the passive learned, not the stack threshold the dispatch's
    own prerequisite round3 spec and the already-existing issue scenario
    `templar-blessing-of-aggramar-blade-refresh-7806.json` already prove separately): cast `apply_spell` at the
    creature fixture, wait `decay_ms` for a partial decay, measure `aura_duration_ms` ("before"), set
    `gating_aura` to `gating_stacks` (held fixed in both phases, since only the passive's presence is the axis
    under test), cast `breaker_spell`, measure again ("after"). `full_duration_ms` is read once from
    `records.duration_ms(target_aura)` at generation time, never hardcoded.
  - The scenario arms itself with `armed_for(class_file, records, breaker_spell)` before building `base_steps`:
    an exploratory `coa-verify --ram` run of the straightforward shape (reference weapon throughout) measured
    every breaker cast failing `SPELL_FAILED_EQUIPPED_ITEM_CLASS` (29), because Righteous Upheaval 501562's
    `EquippedItemSubClassMask` (41105) excludes the Templar reference Walking Stick's subclass (10) — the same
    exclusion the hit-scenario machinery already documents for Vindication 573324. Blade of Faith 803872 accepts
    both the reference and the alternate weapon's subclass (confirmed by DBC read), so one armed weapon serves
    the whole scenario.
  - `compare.py` gains `behaviour_duration_refresh_verdict`: `ok` only when the without-phase's `after <= before`
    (any increase without the passive is always an alert — the breaker's own gating condition should never fire)
    **and** the with-phase's `after >= full_duration - refresh_margin_ms` (a reading that stays merely decayed is
    always an alert); `alert` otherwise. No tolerance-margin scale, because the claim is binary, not a ratio or a
    delta of a known magnitude.
- `MetricDeltaSpec` gains two additive fields, both defaulting to the prior fixed behaviour:
  - `target: str = CASTER` — `"dummy"` casts the trigger spell at the stock creature fixture instead (added to
    `scenario['creatures']` only when set), for a trigger spell that needs a hostile target, such as a
    periodic-damage spell.
  - `disable_regeneration: bool = False` — `true` sets `allow_regeneration: false` on the player fixture (an
    existing harness field, already used by the issue scenario
    `templar-5163-warrior-of-tyr-energy-generation.json` for the same reason). An exploratory run of Warrior of
    Tyr's scenario without it measured Energy at 33 before the learn and 43 after (the +10 delta already
    correct, matching Energy's standard ~10/sec real-time regen over the 3300 ms wait, confirmed by the
    difference matching that rate) — the delta the tooltip claims was never wrong, but the check's required
    exact-equality baseline (`before == before_expected`, ADR 0022) cannot be satisfied by a live regen read that
    is not itself a DBC-derived constant.

## Consequences

- Blessing of Aggramar 300502 and Warrior of Tyr 301253 both measured `ok` in the scenarios this item generated
  and ran (`coa-verify --ram`, exploratory native execution, 2026-11-09): 300502's without-phase continued
  decaying (25991 ms -> 25979 ms) while its with-phase returned to exactly 30000 ms (its own full duration);
  301253 read 0 Energy before the learn and 10 after, exact.
- A sixth "which existing-aura refresh" shape now exists alongside `count`/`ratio`/`spread`/`trigger`/
  `metric_delta`/`health_ratio`; a future passive whose claim is "casting X refreshes Y's remaining duration"
  reuses this builder with new `target_aura`/`gating_aura`/`apply_spell`/`breaker_spell` rather than adding a
  seventh.
- `metric_delta`'s `target`/`disable_regeneration` fields are available to any future entry whose trigger spell
  needs a hostile target or whose metric is a regenerating resource; every existing entry's generated scenario is
  byte-for-byte unchanged (both default to the prior behaviour).
- 301339 (Holy Tempest) and 500011 (Holy Combatant) remain open P5-family gaps from the same round3 lot; neither
  needed in this item, and neither is this ADR's `duration_refresh` module a fit for either (301339 needs a
  second creature fixture for a spread target, not a duration refresh).
