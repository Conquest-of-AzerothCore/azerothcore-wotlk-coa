# 1231. A metric_delta vehicle must apply its aura before a window reading is judged

- Status: proposed (provisional number)
- Date: 2026-11-23

## Context

Sun Cleric ledger 426 and 434, Valkyr's Grip 807507 and 807873 "reduces the duration of disarm effects by $s2%.":
the window arms read Disarm 8379 held just before the reduced end and gone just after it. Disarm 8379 is DmgClass 2
melee (Effect[0] 6 APPLY_AURA, EffectImplicitTargetA 6, aura 67 MOD_DISARM, installed DBC), so the striker's cast can
miss or be dodged or parried; round B4 read no aura after about 4 of about 40 first strikes. A held reading then fails
for a reason that is not the effect, and a gone reading cannot tell a strike that never landed from an early end. No
existing option voids it: `strike_landed` (ADR 0625) counts damage logs, which a pure aura spell does not write, and
needs an owned creature.

## Options

- More strikes: a second Disarm refreshes the first and moves the window.
- Read the aura right after the strike: one more step inside the timed interval moves every later reading by a world
  tick (the harness runs one step per tick).
- Count the vehicle's aura applications on the unit it lands on, outside every timed interval.

## Decision

A `metric_delta` option module `vehicle_landed` (`true`; the entry's `strike` must hit the caster, where its aura
lands) reads `aura_apply_count` of the strike spell on the caster at the scenario start, right after the before
reading, and after the last treatment reading (the expired reading when there is one). Each phase needs as many
applications as it has vehicle casts, else the trial is `unmeasured`; otherwise the verdict is unchanged. The reads sit
outside every interval between a strike and a timed reading, so no game-time stamp or reading moves.

`{"max_step_ms": N}` in place of `true` (mentor D-271) adds a bound: a reading whose bracket relies on one world step
of at most N ms is `unmeasured` when the run's recorded `max_step_ms` is missing or above N. The gone arm needs it
(age at most the stamped gap less the trigger-to-strike wait plus one step), and so does a held arm whose strike
follows the trigger (age at least the stamped gap less the trigger-to-strike steps).

## Consequences

- A window arm whose vehicle did not land is unmeasured instead of alert or a false ok.
- No harness change and no new metric: `aura_apply_count` and its evidence row exist. Opt-in; Witch Hunter (15),
  Templar (19, and `--stack`) and Necromancer (23) `generate` are byte-identical to c4ec2c2ccd.
- A strike at an owned creature is refused; extending it needs a read on that creature.
- A gone bound no longer rests only on the step lengths seen in earlier runs: a slower run is void, not judged.
