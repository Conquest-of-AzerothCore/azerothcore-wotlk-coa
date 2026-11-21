# 0546. Pooled summon lifetimes and repeated pushback casts

- Status: accepted
- Date: 2026-11-13

## Context

Two game-time judges of this cycle could not reach a verdict. Unholy Erosion 807700 has ProcChance 3 and the scenario
schema caps the forcing mutant at +1000%, so one forced tick summons with 33% (ADR 0544 left it out). Lich Essence's
pushback (ADR 0543 amendment) is bracketed by four cast ends whose polls are one world tick apart (8-10 ms of game time:
the 1 ms wait step takes a tick, the reads take none), and the bracket crossed the band edge in every run. The
controller ruled: a bracket crossing the band edge gives no verdict; tighten the poll or add samples; and run the
Unholy Erosion lifetime as a pooled proof (G-20 step 2).

## Decision

- A `summon_lifetime` entry may set `parts`: each part is one scenario; the pooled judge leaves out a part whose spawn
  window never shows the creature (its tick rolled no summon; its control and released reads must still be 0),
  judges every other part with the single-part judge, and is `ok` only if at least one part summoned and every
  summoned part is `ok`. Unholy Erosion runs 40 parts: P(no summon) = 0.67^40 = 1.1e-7.
- A `pushback_reduction` entry may set `repeats`: each of its casts is repeated, and the judge takes the mean bracket
  middle per kind of cast, its standard error from the repeats, and a 99% interval of the reduction by propagation;
  `ok` inside the band, `alert` outside, `measured` across an edge. Lich Essence repeats 10 times, with 21-poll windows
  so the scenario stays under 10000 steps. A hit cast whose strike did not land on the caster is invalid and left out
  of the mean; each kind needs at least half its casts (and two) valid. Icebound Champion repeats 4 times (its 20 s
  hold four casts after the summon) after pair p5 read one Champion-phase strike that never landed on the caster.
  Entries without `repeats` keep the bracket judge.
- No harness C++ change; Templar generation unchanged.

## Consequences

- 289.1 and 240.0 count only after a counted pair passes them.
- Tests: `SummonLifetimePooledTests`, `PushbackSampledTests` (test_behaviours.py).
