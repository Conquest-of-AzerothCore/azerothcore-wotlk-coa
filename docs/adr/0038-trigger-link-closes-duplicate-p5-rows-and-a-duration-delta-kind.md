# 0038. `trigger_link` closes duplicate P5 rows; a `duration_delta` trigger kind measures a foreign aura's
   duration extension

- Status: accepted
- Date: 2026-11-09

## Context

`classify()` (`passives.py`) labels every `P5`-family passive effect (aura 23, 42, 231, 354 — proc/trigger
auras) `unmodelled: proc or trigger effect without a trigger entry`, unconditionally, before ever reading
`class_file['triggers']`/`['procs']`/`['behaviours']`. Those three lists, and the independent
`trigger_entries()`/`proc_entries()`/`behaviour_entries()` code paths that build scenarios from them, are
consulted only by `conformance.py`'s `generate`, never by `classify()`. Round 3/4's trigger lots had already
built working (or already-diagnosed) entries for 66 of Templar's 67 P5-labelled spells (73 of 76 verdict rows,
round5 `trigger-accounting-spec.md`), but every one of those rows still carried the bare generic reason
alongside the real entry's own, independent, often-correct verdict: two verdicts for the same effect, from two
code paths that never cross-reference each other.

Of the 3 genuinely uncovered rows, Holy Combatant 500011 extends a foreign aura's (Interdict 560116) remaining
duration by a fixed amount per trigger (`AscensionTemplarAbilities.cpp:296-303`) — the direct `aura_duration_ms`
analogue of ADR 0033's `cooldown_delta` kind, which ADR 0033's own consequences already named as "a different,
unbuilt shape". One With The Light 504807's effects 0 and 2 (cooldown reductions on three roots and on Librams)
run in the same `Breaker(info)` block as its already-`unmodelled` effect 1 (a target-fallback harness gap), but
do not depend on target at all; linking them to that entry's own diagnosis would misrepresent them as covered
by a diagnosis that does not address them.

## Considered options

1. Leave the accounting defect alone and hand-author per-spell overrides (`effect_notes`) for all 73 duplicate
   rows. Rejected: 73 near-identical overrides naming another entry's own label and status by hand is exactly
   the kind of generic, mechanical fix `effect_notes` is not for, and every future class's trigger lot would
   need the same manual treatment.
2. Make `classify()` consult `triggers.py`/`procs.py`/`behaviours.py`'s own entry lists directly and build each
   verdict label/status duplicate from scratch. Rejected: `passives.py` already has four precedent-setting
   per-`{spell_id, rank_id, effect}` override lookups (`passive_targets`, `effect_overrides`, `effect_notes`,
   `unmodelled_effects`); a fifth, generic one that reuses the same precedence and the target modules' own
   label functions needs no new override data file and stays consistent with how a P5 effect is already closed
   by `effect_notes` today.
3. Add a `trigger_link(class_file, spell_ids, effect)` helper, checked inside `classify()`'s existing
   `family in FAMILY_REASONS` branch, before the bare `FAMILY_REASONS[family]` fallback, only for the `P5`
   family. Chosen.

## Decision

- `passives.py` gains `trigger_link(class_file, spell_ids, effect)`: collects every `triggers`/`procs` entry
  whose `aura` is in `spell_ids` and every `behaviours` entry whose `spell` is, then prefers the one whose own
  `effect` field equals this effect index (falling back to a single entry with no `effect` field, assumed to
  cover every P5 effect of that spell). `linked_reason(class_file, kind, entry)` builds
  `checked by <kind> entry "<name>" (verdict "<label>[, "<label>"...]", status <status>)`, reusing each target
  module's own label function (`trigger_label`/`cooldown_label`, disambiguated by `observe_spell` when more
  than one `cooldown_delta` entry shares an `aura`; `proc_label`; a new `behaviour_label` table covering the
  `count`/`spread`/`metric_delta`/`duration_refresh`/`amount_delta`/`duration`/`health_ratio` kinds actually
  linked this round, `health_ratio` returning one label per `levels` point). `classify()` calls `trigger_link`
  only for the `P5` family, immediately before the `FAMILY_REASONS[family]` fallback; `effect_unmodelled`
  (checked earlier) still overrides a linked effect that is genuinely unreachable, the same precedence it
  already has over every other path.
- `triggers.py` gains `COOLDOWN_DELTA_KIND`'s sibling, `DURATION_DELTA_KIND = 'duration_delta'` and
  `DURATION_CHECK = 'trigger_duration_delta'`: `checked_duration_entry` (cast only, `aura_duration_ms` only, a
  positive `expected_delta_ms`, a `decay_wait_ms` strictly greater than it), `duration_trial_steps`/
  `duration_trigger_scenario` mirroring `cooldown_trigger_scenario`'s structure but casting and reading the
  observed aura on `trigger['target']` (not the caster) after an explicit `decay_wait_ms` wait, so a
  near-`MaxDuration` aura has room to show a real extension instead of clamping it to 0. `attempt_interval`
  gains the matching branch (adds the observed spell's `cast_interval` plus `decay_wait_ms`).
  `compare.py` gains `judge_trigger_duration`/`duration_trial_windows`, the `cooldown_delta` judge mirrored for
  an increasing metric: a trial's `after - before` is compared against `[expected - window - margin, expected +
  margin]` (window subtracts rather than adds, since the aura also decays naturally across the same elapsed
  time the cooldown case's window adds to), and the baseline band is `[-(window + margin), margin]` instead of
  a flat 0. `conformance.py`'s `add_trigger` dispatches on `entry.get('kind')` through a small
  `{COOLDOWN_DELTA_KIND: ..., DURATION_DELTA_KIND: ...}` map instead of a single ternary.
- `cooldown_label(aura, observe_spell=None)` gains the same optional disambiguator `proc_label` already has for
  `proc_spell`, applied (via a new `shares_cooldown_aura`) only when more than one `cooldown_delta` entry
  shares an `aura` — the first real case of that, One With The Light 504807's own two new effects, surfaced the
  latent gap directly: both entries' labels collided under one key in `compare.py`'s per-label grouping,
  averaging two unrelated cooldowns' trials into one false `alert` (measured this round, stamp
  `20261109-132802`, before the fix).
- 504807's effect 2 gets a `cooldown_delta` entry (`observe_spell` 801461, the same Libram rank its own effect
  1 already observes). Effect 0's three candidate roots (`500694`, `806153`, `801455`) each fail the existing
  `cooldown_trigger_scenario`'s self-cast-with-no-wait shape for a distinct, DBC-confirmed reason (two need a
  hostile/friendly target a self-cast never gets; the third's own GCD collides with the immediately-following
  trigger cast, `SPELL_FAILED_NOT_READY`, measured 162 of 244 trials this round); effect 0 is closed through
  `unmodelled_effects` instead of given a check that would misreport this gap as a broken mechanism.
- Holy Combatant 500011 gets a `duration_delta` entry: cast Argent Blade 807268 at `dummy` while Interdict
  560116 (cast at the same dummy, decayed 1500 ms first) is present; measured this round `ok`, mean 987.12 ms
  against the expected 1000 ms.

## Consequences

- 73 of Templar's 76 P5-labelled verdict rows now point at their own real check's label and status instead of
  repeating the generic reason; the three genuinely uncovered rows are either a working new check (500011,
  504807 effect 2) or a closed, evidence-backed gap (504807 effect 0).
- `trigger_link` runs for every class's P5 family the same way, with no per-class wiring: a future class whose
  trigger lot already covers a P5 effect gets the same duplicate-closing behaviour for free.
- `test_passives.py` gains `TriggerLinkTest` (a minimal P5 fixture proving the link, the no-entry fallback, and
  effect-index precedence); `test_triggers.py` gains `CooldownDeltaLabelDisambiguationTest`,
  `OneWithTheLightCooldownEntryTest` and `HolyCombatantDurationEntryTest`, plus `DURATION_DELTA_KIND` branches
  in the module's existing entry-shape tests (`test_entries_cite_the_dbc`,
  `test_cast_triggers_name_the_words_that_make_the_spell_a_trigger`, `test_every_second_cast_is_the_only_half_rate`,
  `test_every_entry_has_a_scenario_or_a_status`) that previously only knew about `COOLDOWN_DELTA_KIND`.
- `behaviour_label`'s table only covers the kinds this round actually linked; a future link to a
  `ratio`/`leech_ratio`/`duration_ratio`/`trigger`-kind behaviour entry needs its own label added there first,
  by design (an unhandled kind raises rather than guessing a label).
