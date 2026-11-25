# 1264. Move under aura judges a blocked move with its moving control

- Status: proposed
- Date: 2026-11-23
- Related: [ADR 1198](1198-ratio-only-arms-single-landing-durations-and-no-cast-dispel-arms.md)
  (the `move_under_aura` kind),
  [ADR 0120](0120-two-proof-statuses-computed-by-clause-coverage.md) (the closed evidence tables).
- Decided by: mentor D-74 (four conditions), controller go of 2026-11-23.

## Context

Felsworn Illidan's Guile 806109 says "during that time you cannot attack, move or cast spells". The attack and cast
parts are measured; the `move` part had no label, because `move_under_aura` only expected a move under the aura.

## Options

- A harness relocate or teleport under the aura. Rejected (D-74): it is not the mechanism the sentence names.
- A `rooted` or `stunned` state read. It reads a unit state, not the refused move, and says nothing when the server
  blocks the move another way.
- An opt-in `expect: "blocked"` on `move_under_aura`: the same own-movement packets as the control, judged for no
  displacement.

## Decision

`expect: "blocked"` (default `"moved"`, so earlier entries generate byte-identical scenarios). The aura comes from the
real cast of `spell`; the control phase makes the same attempt without the aura and must move the full step, or the
verdict is `unmeasured`; under the held aura the position must stay within 0.1 yd; the verdict names the attempt
(own forward movement through the movement handler). The derived metric `move_under_aura_blocked` is a new `event`
row of the module's `METRIC_EVIDENCE` (mentor D-74), added in its own commit.

## Consequences

A sentence about the caster moving can be proved or alerted on. A sentence about the caster being moved by others
(knockback, pull) is outside this option and needs that enemy mechanism (D-74 condition 2).
