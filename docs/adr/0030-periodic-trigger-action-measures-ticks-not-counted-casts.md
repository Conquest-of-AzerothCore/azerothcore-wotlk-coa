# 0030. A `periodic` trigger action measures amplitude ticks, not a counted player action

- Status: accepted
- Date: 2026-11-08

## Context

`round3/trigger-lot-5-spec.md` (part A) found two Templar passives, Light's Ward 300529 and Light's Chosen
301310, whose `SPELL_AURA_PERIODIC_TRIGGER_SPELL` effect (23) is not gated by `ProcFlags` at all (that gate,
`SpellMgr.cpp:2512`, only skips the proc-event path) and is not routed away by `AscensionTemplarContracts.cpp`
for either id: the effect runs unmodified through the generic engine's own amplitude timer, recasting its
`EffectTriggerSpell` every 2000 ms (300529) or 5000 ms (301310) while the passive is active, with no player
cast and no attack in between.

`triggers.py`'s existing `trigger['action']` values, `cast` and `attack`, both describe a player-repeated
action: `attempt_interval` returns a cast or swing interval, `attempt_steps` casts or attacks that many times,
and `counts()` measures a trial count (casts or swings) alongside the observed event count, so the judge
(`compare.judge_trigger`) can compute `events / trials` against `per_trigger`. A periodic tick has no such
trial to count: the only quantity is the number of ticks that elapsed, which is known exactly at scenario-build
time from `attempts x amplitude_ms`, not something the harness measures during the run.

## Considered options

1. Model a periodic trigger as a `cast` of its own trigger spell, spaced at the amplitude. Rejected: there is no
   real cast to make (the only "cast" is the trigger spell itself being recast by the aura, which is also the
   value being observed), so this would either need a fake no-op cast of some other spell, or collapse trials
   and events onto the same measurement, masking a missing tick with a tautological ratio of 1.
2. Add a `periodic` action whose only datum is `amplitude_ms`, with `attempt_interval` returning it directly, no
   cast/attack during the wait, and the judge comparing events to the statically known `part_attempts` instead
   of a measured trial count. Chosen: this is what the DBC field actually says ("recast this trigger spell
   every `amplitude_ms`"), needs no server-side instrumentation, and keeps the "a check must be able to fail"
   property — a server that stopped generating the tick reads 0 events against a nonzero known attempt count,
   still an `alert`, not a tautological `ok`.

## Decision

- `triggers.py` gains `PERIODIC = 'periodic'` and `PERIODIC_TRIAL_METRICS = {'spell_cast_count'}` (a schema-only
  placeholder metric, never measured for this action). `checked_entry` requires a positive `amplitude_ms` on a
  `periodic` trigger instead of a `spell`/`target`. `attempt_interval` returns `amplitude_ms` directly.
  `attempt_steps` becomes a single `wait` of `attempts x amplitude_ms`, no cast and no attack. `counts()` omits
  the trial-count measurement step entirely for this action (only the events count is taken). `trigger_rule`
  states "periodic ticks every `<amplitude_ms>` ms" in place of a trial metric and spell.
- `compare.py`'s `judge_trigger` sums `part_attempts` across every counted part directly, from the expectation's
  own model (known at generation time), as the trial count for a `periodic` action, instead of subtracting a
  measured `baseline_trials` from a measured `trials` label the way a cast or attack trigger does — a periodic
  part's `part_attempts` is already main-phase-only (the baseline wait before the learn ticks zero times, so it
  contributes nothing to subtract). Subtracting `baseline_attempts` here anyway was a bug caught by a live
  gameplay run: it undercounted every multi-part periodic entry by exactly its baseline size. The events and the
  baseline's `without` count are still read from the run as usual. `per_trigger` is still required and the
  tolerance rule is otherwise unchanged: `|events - trials x per_trigger| <= 1` (plus `periodic_initial_tick`'s
  addition below) over the project's standard trial minimum, no event in the baseline.
- `attempt_steps` does not append the generic `drain` wait for a `periodic` action: every other action's drain
  lets an in-flight effect from the *last* attempt resolve while no *new* attempt starts, which is harmless to
  its count, but a periodic aura keeps ticking on its own clock regardless of what the harness does next, so an
  extra 3000 ms wait before the events measurement reliably let one more tick land when the amplitude was under
  3000 ms (caught the same way, on a live run: Light's Ward's 2000 ms amplitude read extra events, Light's
  Chosen's 5000 ms amplitude did not).
- `periodic_initial_tick` (an entry field, not a new mechanism) adds one event per counted part to the expected
  total, for an aura whose own `Spell.dbc` `AttributesEx5` carries `SPELL_ATTR5_EXTRA_INITIAL_PERIOD` (0x200):
  that attribute makes the periodic effect tick immediately on apply, in addition to its regular amplitude
  cadence, and because every part here re-learns the passive from scratch (a fresh apply), every counted part
  gets its own extra tick. Caught the same way: Light's Ward (`AttributesEx5` 512, bit set) measured exactly one
  extra event per part on a real run; Light's Chosen (`AttributesEx5` 0) measured none.
- An entry using this action has no `trigger.spell` and skips the cast-centric schema checks (`target`,
  `trigger_spell_text` substring of the trigger spell's own name/tooltip); `trigger_text`/`per_trigger_text` may
  be empty strings when the tooltip gives the tick no words of its own (confirmed for both current users: the
  tick is never named in either passive's `Description[enUS]`).

## Consequences

- Light's Ward 300529 and Light's Chosen 301310 get a `triggers` entry without inventing a player action that
  does not exist; a third periodic-trigger passive reuses the same action with its own `amplitude_ms`.
- `test_triggers.py` gains direct unit coverage of `attempt_interval`, `attempt_steps` and `counts()` for this
  action, plus two full-scenario builds (`test_periodic_entry_builds_a_valid_scenario`) proving `run.validate`
  accepts the generated scenario and that no `creatures` fixture is added (neither entry targets anything).
- This does not cover a trigger that recasts a *different* spell than the one actually measured, or one whose
  magnitude is a duration delta rather than a discrete event count (Blessing of Aggramar 300502, Holy Combatant
  500011): those still need the `aura_refresh` check family the same spec proposes, not built this round.
