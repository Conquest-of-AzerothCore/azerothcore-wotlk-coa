# 0059. An `internal_cooldown_gate` behaviour kind proves "Can only occur every/once per ..." clauses

- Status: accepted
- Date: 2026-11-10

## Context

Several Templar passive tooltips end in a sentence the existing harness never measures at all: "Can only occur
once every 0.5 sec.", "Can only occur every 15 sec." and "Can only occur once per sec." (Disciplined Blows
680397, Untainted 705298, Scarlet Champion 805415). All three auras are already proven proc entries in
`triggers.py`'s `trigger_count` check (`per_trigger: 1` against a rate), each carrying `internal_cooldown_ms` so
that `attempt_interval` spaces repeated attempts far enough apart to *avoid* ever colliding with the gate. That
spacing choice is exactly why the rate check cannot prove the gate's own numeric window: it is built never to
test it.

Reading `AscensionTemplarEvents.cpp`'s `aura_ascension_templar_event::Check`/`Proc` for all three ids: each
`Check` case requires `!State(player).cooldowns.HasTimeUntilEvent(id)`, and each `Proc` case unconditionally
calls `State(player).cooldowns.ScheduleEvent(id, <500ms|15s|1s>)` on every successful fire. This is a per-player
world-tick timer the CoA scripts own directly, not the engine's native `Aura::IsProcOnCooldown`/
`SpellProcEntry::Cooldown` path (confirmed negatively: the `spell_proc` rows these three auras carry,
`rev_20260909_04_templar_completion.sql`, have no `Cooldown` column set). The three literal durations match the
three tooltip sentences exactly (500 ms, 15000 ms, 1000 ms).

No existing `behaviours.py` kind fits "the gate stays shut for a fixed window after a fire and reopens exactly
once that window has passed": every existing kind measures a magnitude or a rate, never a closed/open timing
boundary either side of a single numeric threshold.

## Considered options

1. Extend `triggers.py`'s existing proc entries with a second check derived from the same scenario run. Rejected:
   the existing scenario deliberately spaces every attempt past the cooldown so the rate check is valid; reusing
   that same run gives zero attempts *inside* the window, so there is nothing to assert "blocked" against.
   Building the gate's own dedicated timing scenario is unavoidable.
2. A new kind, `internal_cooldown_gate`: three casts of `trigger_spell`, the first two spaced at half the
   cooldown (clearly inside the window) and the next two spaced at the remaining half plus a fixed margin
   (clearly past it), reading `observe_spell`'s cumulative `spell_cast_count` after each. Chosen: the gate is
   either open or shut at each boundary, so a plain integer-delta judge (no tolerated band, matching
   `aura_grant`'s precedent) proves it directly from the one quantity the tooltip actually states, the cooldown
   duration itself.

## Decision

- `behaviours.py` gains `BEHAVIOUR_INTERNAL_COOLDOWN_GATE`, `IcdGateSpec` (`spell`, `name`, `quote`,
  `trigger_spell`, `observe_spell`, `internal_cooldown_ms`, optional `target` default `"dummy"`,
  `caster_health_pct`, `restore_charges`, `force_crit`, `reopen_margin_ms` default 500 ms),
  `icd_gate_scenario` and `icd_gate_spec`, wired into `behaviour_scenario`'s dispatch under
  `kind: "internal_cooldown_gate"`.
- The scenario casts `trigger_spell` three times, reusing `hits.cast_steps` for each cast's own cooldown reset,
  mana cost and `required_aura_steps` (plus any `restore_charges`/`caster_health_pct` fixture, reapplied before
  every cast): the first gap is half of `internal_cooldown_ms` (short, inside the window), the second is the
  remaining half plus `reopen_margin_ms` (clearly past it). `observe_spell`'s `spell_cast_count` is read right
  after each cast. No `CoAGameplayTest.cpp` change: `spell_cast_count`, `restore_charges`, `set_health`,
  `relocate` and `group` already exist with every field this kind needs. For an ally-targeted trigger,
  `icd_gate_attempt_fixtures` relocates the caster away from the ally before *every* attempt, not once: 705298's
  own trigger 803792 carries `SPELL_EFFECT_CHARGE`, which pulls the caster to melee range of the ally on each
  successful cast, so a one-time relocate (tried first, round10/judging-work/step9/run1) left the caster inside
  the next cast's own 5-yard `SpellRange.dbc` minimum and produced two real `SPELL_FAILED_TOO_CLOSE` failures,
  not a measurement of the gate.
- `compare.behaviour_internal_cooldown_gate_verdict` first checks the delta between the first and second reading:
  any nonzero delta is an immediate `alert` ("fired again ... before its own ... ms internal cooldown elapsed").
  Only then does it check the delta between the second and third reading: exactly `+1` is `ok`, anything else is
  `alert`. There is no tolerated band — an integer event count at a fixed boundary is either right or wrong.
- `passives.py`'s `BEHAVIOUR_LABELS` P5-link table gains the `internal_cooldown_gate` entry proactively (the same
  defect shape step5 through step8 guarded against for every other behaviour kind).
- `classes/templar.json` gains three `behaviours` entries (680397, 705298, 805415), each citing the
  `AscensionTemplarEvents.cpp` `Check`/`Proc` lines and the `spell_proc` table's own missing `Cooldown` column
  as the reason this is a scripted timer, not the engine's native one.
- `coverage.py` gains clause-level coverage (see the clause-ledger format note in `docs/passive-effects.md`);
  this ADR's own entries are consumed through that ledger rather than through a bespoke report.

## Consequences

- The three "Can only occur ..." clauses are proven end to end (two independent gameplay runs, both all `ok`);
  `classes/templar_clauses.json`'s labels for them, previously `[]`, now point at live verdicts.
- 705306's own "Can only occur once per sec." clause is deliberately left out of this step: its only available
  `taken_hit` fixture's damage already truncates to zero roughly half the time before this gate is even reached
  (documented on its existing `triggers.py` entry), so the same scenario shape would measure that pre-existing
  truncation defect, not the gate. It needs a stronger taken-hit fixture first, independent of this kind.
- The `internal_cooldown_gate` kind generalises to any class's scripted `State(player).cooldowns`-style gate on a
  proc: a new class-file entry naming the trigger/observe spells and the window, no further tool code.
