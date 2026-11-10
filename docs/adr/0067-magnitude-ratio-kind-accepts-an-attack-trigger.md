# 0067. The `magnitude_ratio` trigger kind accepts a probabilistic `attack` trigger, judged per-event

- Status: accepted
- Date: 2026-11-09

## Context

ADR 0051 built the `magnitude_ratio` kind for "now deals/heals X% of the damage dealt" clauses, but only for a
trigger that is itself a spell cast, and flagged Retribution 707391 ("Melee damage dealt now has a $h% chance to
strike 2 additional times for $s1% of the damage dealt as Holy Damage") as a follow-up: its trigger is a plain
main-hand melee swing, not a cast, so `checked_magnitude_entry` rejected it (`trigger['action'] != 'cast'`) and
`magnitude_ratio_scenario` had no branch that could schedule repeated auto attacks instead of repeated casts.
`$s1` is `EffectBasePoints[0]` 29 + `EffectDieSides[0]` 1 = 30 (`EffectTriggerSpell[0..2]` all name the
extra-strike copy 525028, `SchoolMask` 2 Holy, `ProcChance` 20); the chance-to-trigger half of the clause is
already proven by the sibling `proc_rate` entry in `procs.py` (`707391 proc_rate ok`, measured ~0.187 vs 0.2),
leaving only the magnitude half unproven, the same gap ADR 0051 closed for Deliverance/Uther's Legacy.

Unlike Deliverance (every swing forced to crit, so the bonus fires on 100% of trigger attempts) and Uther's
Legacy (the heal fires on every Condemn hit), Retribution's trigger fires on only ~20% of swings, each firing
2 extra strikes. A first implementation reused ADR 0051's formula unchanged (`ratio = sum(observe_total) /
sum(trigger_total)`) with `expected_ratio = 0.3`: a real two-part gameplay run (274 main-hand swings, stamp
`20261109-225738`) measured `0.1066`, an `alert` — far outside tolerance. This was not a server defect: working
through the arithmetic, `sum(trigger_total)` sums *every* swing's damage (proc'd or not), while
`sum(observe_total)` only has damage from the ~20%×2 = 40% of swings that actually proc'd, so the sum-ratio
formula measures `expected_ratio × proc_chance × strikes_per_proc` (`0.3 × 0.2 × 2 = 0.12`, close to the
`0.1066` actually measured) instead of `expected_ratio` alone. ADR 0051's own convergence argument ("the server
computes the triggered amount as a deterministic function of that same hit's own damage") silently assumed every
trigger attempt produces exactly one triggered event; it does not hold for a probabilistic trigger, and no
flat-tolerance fix to `expected_ratio` (multiplying in the DBC `ProcChance`) would be sound either, since that
reintroduces the proc-rate's own binomial sampling noise into a check meant to isolate `$s1` alone, and would
silently absorb a real defect in `events_per_proc` (a still-unproven, separate clause) into the same number.

## Considered options

1. A separate kind (e.g. `melee_magnitude_ratio`) duplicating `magnitude_ratio`'s scenario/compare logic for an
   attack trigger. Rejected: the only structural difference between a `cast` and an `attack` trigger is how its
   own side accumulates damage and how its scenario produces hits; duplicating `judge_trigger_magnitude`, the
   tolerance constants and every unit test for that would violate the "tool code stays class-agnostic" /
   reuse-over-duplication expectation for a difference this small, and does nothing about the dilution bug below.
2. Multiply the DBC `ProcChance` and `events_per_proc` into `expected_ratio` and keep summing raw totals.
   Rejected (see Context): conflates three independent DBC facts into one number, re-adds the proc rate's own
   binomial noise to a tight 5%-of-expected tolerance band sized for a deterministic ratio, and could mask a
   defect in `events_per_proc` as an in-tolerance magnitude.
3. Normalise each side by its *own* event count before taking the ratio — `ratio = (observe_total /
   observe_count) / (trigger_total / trigger_count)`, i.e. the triggered spell's own mean damage-per-cast over
   the trigger side's own mean damage-per-swing. Chosen: this is exactly `$s1` regardless of how many of the
   `trigger_count` swings actually proc'd, because `observe_count` already only counts swings that did (law of
   large numbers: the mean damage of the subset of swings that proc'd converges to the same mean as all swings,
   since proccing is independent of a swing's own damage). It needs one new reading per side
   (`spell_damage_count`/`spell_heal_count` of the observed spell — both already exist,
   `CoAGameplayTest.cpp:4513,4582`) and is a strict generalisation of ADR 0051's formula: for a trigger that
   fires on 100% of attempts with exactly one triggered event each (Deliverance, Uther's Legacy),
   `trigger_count == observe_count` and the two counts cancel, reproducing the old sum-ratio exactly — so no
   previously-`ok` verdict changes.

## Decision

- `triggers.py`'s `MAGNITUDE_TRIGGER_METRICS` (a single set) becomes `MAGNITUDE_TRIGGER_METRICS_BY_ACTION`, a
  dict keyed by trigger action (`'cast': {'spell_damage_total'}`, `'attack': {'melee_damage_total'}`).
  `checked_magnitude_entry` now accepts either action: a `cast` trigger keeps its existing target-in-
  `TRIGGER_TARGETS` check; an `attack` trigger must not name a spell (`trigger.get('spell', 0) != 0` is rejected,
  mirroring the existing plain `{"action": "attack", "spell": 0}` convention), either action's `trigger_metric`
  must match its own entry in `MAGNITUDE_TRIGGER_METRICS_BY_ACTION`, and (matching the generic `checked_entry`
  rule) a `trial_attempts_factor` other than 1 needs a `trial_attempts_reason`.
- `magnitude_measurement_labels` gains an `observe_count` reading; `magnitude_ratio_scenario` records it
  (`spell_damage_count` or `spell_heal_count` of `observe_spell`, matched to `observe_metric` by the new
  `MAGNITUDE_OBSERVE_COUNT_METRICS` map) alongside the existing `observe_total`. The scenario also branches on
  `trigger['action']`: a `cast` trigger keeps ADR 0051's steps unchanged; an `attack` trigger learns only the
  aura (no trigger spell to learn), then emits `attack`/`wait`/`stop_attack` against the scenario's target
  creature for the part's scheduled attempts — the same shape the plain `trigger_count` kind's own `ATTACK`
  branch (`trigger_scenario`/`attempt_steps`) already uses — and reads `melee_damage_total`/`melee_damage_count`
  of the main hand instead of the trigger spell's own totals.
- `compare.py`'s `judge_trigger_magnitude` sums `trigger_total`/`trigger_count`/`observe_total`/`observe_count`
  separately across parts, then judges `ratio = (observe_total / observe_count) / (trigger_total /
  trigger_count)` against `expected_ratio` with the same `max(0.01, 5% of expected)` band ADR 0051 set.
  `insufficient_trials` is now judged on `observe_count` (the actual number of magnitude samples feeding the
  ratio) rather than `trigger_count` (the number of attempts, which may wildly exceed the useful sample count
  for a low-probability trigger); the two were previously the same number for every existing entry, so this is
  not a behaviour change for them.
- `magnitude_trigger_rule` and the compare explanation describe an `attack` trigger's source as "main-hand melee
  attacks" instead of a spell id (there is no trigger spell id to print), and describe both sides as per-event
  means rather than raw sums.
- A new class-file entry for Retribution 707391 (`kind: "magnitude_ratio"`, `trigger: {"action": "attack",
  "spell": 0}`, `trigger_metric: "melee_damage_total"`, `observe_spell: 525028`,
  `observe_metric: "spell_damage_total"`, `expected_ratio: 0.3`, `trial_attempts_factor: 2` — a ~20%-chance,
  2-strikes-per-proc trigger yields only ~0.4 observed strikes per scheduled swing, so the unscaled schedule
  would under-sample `observe_count`) proves this clause; it carries no `effect` field since no other
  `triggers.py` entry shares aura 707391 (the clause's chance-to-trigger half is proven separately by
  `procs.py`'s own `707391 proc_rate` entry, a different check name, so there is no key collision).

## Consequences

- ADR 0051's two existing entries (Deliverance, Uther's Legacy) are reproduced bit-for-bit by the generalised
  formula, confirmed by their unchanged `ok` verdicts.
- Retribution 707391 gains a real, correctly-normalised measurement of "for $s1% of the damage dealt as Holy
  Damage" no longer entangled with the separately-proven `ProcChance`: a first attempt without the per-event
  normalisation measured `0.1066` (the dilution this ADR fixes), and the corrected formula measures a
  consistent `~0.263` across three independent runs against the DBC's `0.3` — an `alert`, not yet explained.
  `docs/trigger-entries.md`'s Retribution paragraph records everything ruled out this round (`spell_bonus_data`,
  `EffectRealPointsPerLevel`, dummy resistance, the generic engine's percent-event handler) and what remains
  unproven. This clause is **not closed**: the check is sound and the discrepancy is reproducible, but its cause
  is not yet found, so no server fix is proposed here (AGENTS.md: reproduce and prove before fixing). The entry
  stays in `templar.json` because the alert itself is the correct, honest output of a working check.
- `test_triggers.py` gains `CheckedMagnitudeEntryTest` (accepts both actions, rejects an attack trigger naming a
  spell, rejects either action paired with the other's metric, rejects an unknown action, rejects an unexplained
  `trial_attempts_factor`) and an attack-trigger section of `MagnitudeTriggerCompareTest`: an in-tolerance case
  where only a fifth of the trigger-side events actually proc'd (demonstrating the per-event normalisation
  against the dilution a naive sum-ratio would show), a seeded far-from-tolerance ratio, and an
  `insufficient_trials` case driven by a low `observe_count` despite a very large `trigger_count`. The existing
  `TemplarTriggerEntriesTest` generic loops are extended to recognise an attack-trigger magnitude entry instead
  of misreading it as the plain `trigger_count` kind's `attack` shape.
- Sacred Defense 705306 ("strike back for X% of the damage dealt") still is not covered: its gap is a
  `taken_hit` striker fixture dealing too little damage for the ratio to clear integer-truncation noise, not the
  trigger-action gap this ADR closes. A `taken_hit` trigger action for `magnitude_ratio` remains a separate,
  unbuilt extension if that fixture is rebuilt around a harder-hitting striker.
