# 0910. A per-shot ramp is judged shot by shot against the first

- Status: accepted
- Date: 2026-11-16
- Builds on: ADR 0581

## Context

Witch Hunter claims 279.0 and 280.0, Arbalest Mastery 706240 "Each subsequent shot of a Witchbane cast deals
$706241s1% more damage, up to a maximum of ${$706241u*$706241m1}%.": 706241 has `EffectBasePoints[0]` 14 + 1 (15% per
stack) and `StackAmount` 10, and the class script adds one stack per Witchbane shot 704342. The ledger cited the
`706241e0` effect value, a readback (data), and the stack count read by `metric_delta` (`arbalest_cap`). No kind read
the amount of each shot (tool gap T19, owner O-33, mentor D-309 and D-311). `hit_ratio` pools the shots of a cast into
one mean, so a ramp and a flat bonus of the same mean cannot be told apart.

## Options

1. A per-event amount read in the harness: harness C++ beyond reading (G-39 note first) for one claim.
2. Waits until the hit count reaches each shot, then reads: a shot that misses or is excluded stalls the wait and
   shifts every later index.
3. A kind module `shot_ramp` (ADR 0581) reading the existing damage total and count between shot landings on a fixed
   grid.

## Decision

Option 3. `kinds/shot_ramp.py` casts the channel `casts` times, one cast every `shots_per_cast` periods
(`EffectAmplitude[0]` of the cast spell), so every shot of a sequence sits on one grid; the reads (damage total and
count of non-critical, unblocked shots, and the count of every shot) fall half a period after each landing (travel
`dummy_distance / Speed`). Each window must hold exactly one shot, or the label is `unmeasured`. A shot that is critical
or blocked is left out. After the last shot of each sequence the `stack_spell` stacks on the caster are read: 0 after
the control and `cap` after every treatment sequence, or the label alerts. One control sequence runs before the entry's
spell is learned and must be flat; then `sequences` treatment sequences, `reset_ms` apart so the stacks drop. Shot n
(from 0) of a treatment sequence must be the mean treatment first shot times `1 + s x min(n, cap)` (`s` =
`EffectBasePoints[0]` + 1 of `stack_spell`, over 100; `cap` = its `StackAmount`) within the rounding, 1 + the multiplier
points, which holds a rounded or a floored amount (deterministic reads, G-19 "to the rounding"), and the first shot must
equal the control's. Every stack count 0 to `cap`, and one shot beyond it, needs a plain shot over the sequences, or the
label is `unmeasured`; so is a first shot too small for the band to tell `s` from `s - 0.05` (D-198). Two labels share
the scenario: `<suffix>` measures the mean per-stack step and `<suffix>_max` the plateau bonus (shot over first shot
minus 1, the stated maximum) over the first shot.

## Consequences

- Tests: `kinds/test_shot_ramp.py`. The stated ramp passes; a 10% per stack mutant, an uncapped ramp, a ramping control,
  a changed first shot and stacks read short of the cap alert; a stack count excluded in every sequence, a lost or
  doubled window and an unlearned talent read `unmeasured`.
- Residual (D-197): with misses removed by the class ratings and crits by the target fixture, only a block (5% for a
  creature, `Unit::GetUnitBlockChance`) excludes a shot; with four sequences a stack count is uncovered with
  0.05^4 per count, about 6.9e-5 per run over 11 counts (unmeasured, never ok).
- The grid needs each gap between chained shots under the stack duration; the entry states it from the DBC.
- The kind is new: no existing entry changes, and the Templar and Necromancer digests are unchanged. First user:
  Witch Hunter 706240 `witchbane_ramp`.
- Number provisional (guide 14.4).
