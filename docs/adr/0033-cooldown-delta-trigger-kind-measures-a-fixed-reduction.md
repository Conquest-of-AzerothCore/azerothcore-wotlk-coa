# 0033. A `cooldown_delta` trigger kind measures a fixed cooldown reduction, not a counted event

- Status: accepted
- Date: 2026-11-09

## Context

`round4/trigger-lot-r4-7-spec.md` found Lorescribe 804927's second `SPELL_AURA_PROC_TRIGGER_SPELL` effect
(`EffectTriggerSpell[1]` 806106): on every Oath Breaker cast while 804927 is known,
`AscensionTemplarAbilities.cpp`'s `OnSpellCast` reads `Amount(806106)` as a magnitude and subtracts it from
every known Libram rank's native cooldown (`ReduceLibrams`). 806106 itself is never cast; its `EffectBasePoints`
is read only as a number. The tooltip states this directly ("now reduce the cooldown of Librams by
`$/1000;806106s1` sec"), matching the already-`ok` value check on 806106's own `EffectBasePoints[0]`
(`804927 effect_value 806106e0 #0`, -4000).

`triggers.py`'s existing shape (`trial_metric`, `observe_metric` one of `spell_cast_count`/`spell_energize_count`/
`aura_apply_count`, `per_trigger`) can only express "N discrete events happened for M trials of a repeated
action". A cooldown reduction has no discrete event to count on the observed side: `cooldown_ms` is an
existing, already-used, no-combat metric (`CoAGameplayTest.cpp`, `player->GetSpellCooldownDelay`), but reading
it once per trigger needs a before/after pair around the trigger cast, not a cumulative count.

## Considered options

1. Leave the effect `unmodelled`, the same disposition as Lorescribe's own dead effect 0. Rejected: the effect
   is reachable and deterministic (`ProcChance` 100, no roll), and the tooltip states exactly one number for
   it; an `unmodelled` verdict here would hide a checkable claim, not describe an unreachable one.
2. Repurpose `aura_apply_count`/`spell_cast_count` against some proxy spell. Rejected: 806106 is never cast and
   no other spell is cast either; there is no discrete event anywhere in this mechanism to stand in as a proxy
   without inventing one that is not in the tooltip or the code.
3. Add a `kind: "cooldown_delta"` entry with its own narrower shape (`observe_spell` the rank whose cooldown is
   read, `observe_metric` always `cooldown_ms`, `expected_delta_ms` a positive magnitude in place of
   `trial_metric`/`per_trigger`) and its own scenario/judge pair, reusing the existing `trigger_plan`/
   `TRIGGER_TRIALS`/`BASELINE_ATTEMPTS` sizing unchanged. Chosen: this matches what the DBC and the code actually
   do (read a magnitude, subtract it from a native cooldown), needs no new C++ metric (`cooldown_ms` already
   exists), and keeps "a check must be able to fail": an absent effect reads as a 0 ms delta, which can never
   fall inside `expected_delta_ms`'s tolerance band by accident.

## Decision

- `triggers.py` gains `COOLDOWN_DELTA_KIND = 'cooldown_delta'` and `COOLDOWN_CHECK = 'trigger_cooldown_delta'`.
  `checked_entry` branches to a new `checked_cooldown_entry` for `entry.get('kind') == COOLDOWN_DELTA_KIND`
  before touching any of the standard shape's required fields (`trial_metric`, `per_trigger`, …); the standard
  branch is otherwise untouched. `checked_cooldown_entry` requires `trigger['action'] == 'cast'`, a target in
  the usual `TRIGGER_TARGETS`, `observe_metric == 'cooldown_ms'` and a positive `expected_delta_ms`.
- `attempt_interval` gains one line: for this kind, it adds `cast_interval` of `observe_spell` on top of the
  existing trigger-spell interval (the per-trial loop casts both the observed rank and the trigger), leaving
  every existing (kind-less) entry's interval exactly as computed before.
- A new `cooldown_trigger_scenario(class_file, entry, part)` mirrors `trigger_scenario`'s structure (learn the
  trigger spell and the observed rank, an optional baseline part before the passive's own `learn`, `trigger_plan`
  sizing and part-splitting reused unchanged) but its per-trial body is: reset the observed rank's cooldown,
  cast it once (filling it back to its native `RecoveryTime`), measure `cooldown_ms`, cast the trigger once,
  measure `cooldown_ms` again. Each trial is independent (the observed rank is always freshly reset first), so
  per-trial cost never grows with trial count and no cumulative-cooldown floor can be hit. `conformance.py`'s
  `add_trigger` dispatches to this function instead of `trigger_scenario` when `entry.get('kind')` is this kind;
  it is otherwise unchanged.
- `compare.py` gains `judge_trigger_cooldown`, dispatched (by `expectation.check`) alongside `judge_trigger` from
  the same `trigger_parts` grouping. It reads each trial's before/after pair (labelled by `cooldown_trial_label`,
  one unique label per trial index so repeated measurements do not overwrite each other within one scenario),
  sums baseline and measured deltas across parts the same way `judge_trigger` sums counts, and judges: any
  nonzero baseline delta is an `alert`; with the passive learned, every trial's delta must fall within
  `max(1, 0.5% of expected_delta_ms)` of `expected_delta_ms` (the same tolerance formula `effect_value`/
  `passive_delta` already use, via `margin_of`) or the whole check is an `alert`; fewer than `TRIGGER_TRIALS`
  usable trials is `insufficient_trials`; a mean within tolerance but no baseline trial is `unmeasured`, the
  same demotion rule `judge_trigger` already applies.
- A class-file entry sharing an `aura` with another entry for a different effect (Lorescribe's dead effect 0
  and its cooldown-delta effect 1) disambiguates its generated scenario key with an optional `effect` field;
  `conformance.py`'s `add_trigger` includes it in the key only when present, so every other (single-effect)
  entry's key is unchanged.

## Consequences

- Lorescribe 804927 gets a `trigger_cooldown_delta` check for its real, reachable effect instead of leaving it
  `unmodelled`; its dead effect 0 (`EffectTriggerSpell[0]` 806089, no code path anywhere) is recorded as a
  `status: "unmodelled"` entry, the same shape as Keeping the Oath 92109 and Zealotry 92108.
- `test_triggers.py` gains direct unit coverage of `checked_cooldown_entry`, `attempt_interval`'s new branch,
  `cooldown_trial_steps` and `cooldown_trigger_scenario`'s generated steps, plus a `compare.py` suite proving the
  absent-effect-gives-alert property for both the nonzero-baseline and the zero-measured-delta cases.
- This kind only covers a trigger that reads a cooldown-reduction magnitude without ever casting the trigger
  spell. A trigger whose magnitude is a duration delta (refreshing or extending an aura) is a different,
  unbuilt shape (Blessing of Aggramar 300502, Holy Combatant 500011; see ADR 0030's consequences).
