# 1266. Taken total ratio reads damage plus absorbed per strike

- Status: proposed
- Date: 2026-11-24
- Related: [Felsworn ADR 0019](conformance/felsworn/0019-hateforged-barrier-reduces-physical-damage-while-it-holds.md)
- Decided by: controller go of 2026-11-24 (option B, Felsworn mentor decision D-81).

## Context

Hateforged Barrier 707527: "While the barrier holds, you take $s2% reduced Physical Damage." The reduction is
Effect[1] of the absorb aura itself. A `taken_hit` `damage_ratio` entry reads the logged damage, which is taken
after the absorb: with 40 Void Zone strikes per trial the first strike broke the barrier and removed the 10% with it,
so the mean per strike read -2.43% with the reduction against -2.18% without it (fw-vb4b). The `absorb` judge compares
absorbed amounts exactly and the `reduction: "formula"` arm judges logged damage, so no existing judge reads the hit
before the absorb.

## Options

- A new kind module that reads each strike as damage plus resisted plus absorbed, from the same spell logs, and
  judges it against a control arm. Additive file, no shared module changes, no new evidence row
  (`spell_damage_with_resist_total` is already an event metric).
- A `damage_ratio` entry with a strike much larger than the barrier. Rejected: its expectation blends the absorb
  into the ratio.
- Readbacks of `spell_damage_taken`. Rejected as the proof: they compute the multiplier without a hit (data evidence).

## Decision

`kinds/taken_total_ratio.py` (doc `docs/kinds/taken_total_ratio.md`): five arms, one strike per trial, non-critical
logs only. The treatment total must lie in the integer band of the DBC factor applied to the control total, with part
of it absorbed; a magic strike under the barrier and a Physical strike after the barrier breaks must equal their
controls; the magic arm's absorbed amount must lie within the tooltip formula (base points and die sides of the absorb
effect plus Stamina times its coefficient). Checks are `behaviour_hit_ratio` labels, judged by the module.

## Consequences

- The kind is discovered by the `kinds` package; no shared file changes. Finished classes do not use it, so their
  generated scenarios are unchanged.
- Unit test `kinds/test_taken_total_ratio.py`, including the mutant without the reduction (a treatment total equal to
  the control alerts).
