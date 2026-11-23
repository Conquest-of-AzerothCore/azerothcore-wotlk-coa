# 0736. A fixed count can read a knockback

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 116.0 (Repulse 680273, "... and knocking all affected targets back.") has its knockback half
unread: the ability script knocks every damaged target back from the caster (`AscensionWitchHunterAbilities.cpp:333`),
and `fixed_count` reads only a pull (ADR 0186), each dummy ending closer. Gap design H5 (c13 gap designs), mentor
ruling D-201.

## Options

- `push_reads`, the mirror of `pull_reads`: the same distance reads, judged as each dummy inside the area ending at
  least 1 yd farther and the one beyond it staying.
- A per-dummy displacement read in a new kind: it would repeat the dummy layout and the count.

## Decision

`push_reads`, with its own model key `push`, so a `pull` model and its judge stay byte-identical. The two reads are
exclusive and both need the far dummy. The fit risk named by the design (stationary dummies carry
`UNIT_FLAG_DISABLE_MOVE`) does not stop it: `MotionMaster::MoveKnockbackFrom` launches the spline without that check;
the pair records it.

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`).
- Seeded tests: the reads frame the cast and no pull model is written; a dummy that does not open by 1 yd, one that
  closes, or a far dummy that moves alerts; the mutant that judges the push as a pull alerts on a real push; pull and
  push together, or a push without the far dummy, are refused.
- Witch Hunter: `680273 knockback behaviour_fixed_count` (three dummies in front inside 20 yd, one beyond).
