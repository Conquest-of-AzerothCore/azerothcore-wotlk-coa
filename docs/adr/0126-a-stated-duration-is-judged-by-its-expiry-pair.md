# 0126. A stated duration is judged by its expiry pair

- Status: accepted
- Date: 2026-11-11

## Context

The lean method judged every duration clause of a class file by a remaining-time readback: `aura_duration_ms` read
right after the act (`behaviour_cast_applies_aura`) or before and after it (`behaviour_duration`,
`behaviour_duration_ratio`, `behaviour_duration_refresh`, the trigger `duration_delta`). A readback reports the
server's own countdown field, not an observed end (prototype `score.md` §2, mentor: "remaining-time TIMING
readbacks are data"). The prototype's G7 template arm rewrote all 8 duration drafts from readback to expiry
(`build-log.md` §26: duration 0/8/0, "all readback -> expiry"), and the T1 timing operator judged an expiry as
"present at E - m, absent at E + m" (ADR 0104 there). The owner ruled on 2026-11-11 that the lean method carries
"durations judged by the expiry pair" (`owner-rulings-2026-11-10.md`, "Prototype score (G6) rulings").

The harness runs one step per world tick (`CoAGameplayTest.cpp` `Progress` runs one `RunStep`; `Tick` keeps
`max_step_ms` as the largest tick) and records each step's `elapsed_ms` from its first evaluation. The time between
two steps is therefore at most one tick and is not recorded.

## Considered options

1. Keep the readbacks and add tolerances. Rejected: a readback stays a reading of the server's field.
2. Port the prototype's clause timing operator. Rejected: clause specs are not adopted (same ruling).
3. A separate expiry scenario per class-file duration entry, judged by an old-judge kind (`behaviour_expiry`), with
   the readback scenarios unchanged and counted as data. Chosen.

## Decision

- `expiry.py` builds, for each behaviour entry of kind `cast_applies_aura`, `duration_refresh`, `duration_ratio`,
  `duration` and each trigger entry of kind `duration_delta`, one scenario with one arm per stated end: the act is
  labelled, an assert bounds when the effect began, and an `aura` presence reading is placed before and after the
  stated end. Arms without and with the passive give the contrast (a refresh, a ratio or a delta that the passive
  causes). The stated end comes from Spell.dbc (`SpellDuration`) and the class file's tooltip value.
- The judge bounds each reading's time from the effect's start by the recorded `elapsed_ms` (lower) and by
  `elapsed_ms + max_step_ms` per step (upper), plus the act's own window. It is `unmeasured` when the readings do not
  bracket the end with a tick to spare or when a server off by `max(5% of E, 50 ms)` could read the same; `alert` when
  the effect is absent before or present after; `ok` otherwise, stating the end interval it shows.
- Placement: the before reading `max(2.5% of E, (k + 4) x 25 ms + 1)` before the end, the after reading
  `min(that, shift - (k + 7) x 25 ms - 1)` after it, `k` the steps between act and readings; an end with no such pair
  is `unmodelled`.
- Evidence: `behaviour_expiry` is behaviour; `behaviour_cast_applies_aura`, a remaining-time readback, becomes data
  like the other duration readbacks. The Templar ledger cites the expiry label beside the readback on the 8 duration
  clauses.

## Consequences

- Durations shorter than about 4.5 s with no step between act and readings, or shorter with more steps, cannot be
  judged by the pair at 25 ms per step; they stay readback data.
- A duration clause is behaviour-proven only when its expiry pair is `ok`; until then it counts as data or unproven.
- The judge's bounds rest on the harness running one step per tick; a harness that ran several steps per tick would
  only make the bounds wider than needed, not wrong.
