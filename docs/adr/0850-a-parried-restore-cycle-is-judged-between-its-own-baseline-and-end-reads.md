# 0850. A parried restore cycle is judged between its own baseline and end reads

- Status: proposed
- Date: 2026-11-16
- Amends: [ADR 0801](0801-a-parried-swing-restore-is-judged-per-cycle-at-a-set-state.md),
  [ADR 0820](0820-an-excluded-parried-restore-cycle-that-parried-is-not-ok.md)

## Context

ADR 0801 judges each cycle on the change of its cumulative counts since the previous cycle's end reads. The read
sequence spans game ticks. Run 20261116-135038 (Dark Riposte 503659, 50.0) read a parry during cycle 19's end reads:
after its counts and health, before its Rage (Rage 240 against a set 200). Cycle 20's change then counted the parry
and its events (heal 30000, Rage 40), while cycle 20's set steps had already overwritten the gain, so cycle 20 read
"events, no gain" and ADR 0820 alerted both labels on a read-ordering artifact (compare of that run at b021e7f381:
`excluded treatment cycles [20] held 1 parried swings`).

## Options

- Keep the judge and widen its tolerance: a real failed restore then reads the same as the artifact.
- Drop a cycle whose counts moved outside its window without saying so: a swing outside the window goes silent.
- Read each cycle's counts and events again after its set steps, judge only the events between that baseline and the
  cycle's end reads, and count and report what lands in the read and set gap.

## Decision

Each cycle reads swings, parried swings, heals, healed, energizes and energized (`base_*`) after its set steps and
its health, Rage and maxima reads; each arm also reads them once after its last cycle (`end`). A cycle's window is the
change from its baseline to its end reads; the health (Rage) baseline is the read taken after the set steps. The gap
before each cycle (from the previous end reads, or the arm start, to the baseline) and the gap after the last cycle
are counted, and the verdict row states the swings, parried swings and judged parried swings they held. A gap swing
adds to its cycle's swing count, so a gap swing and a window swing in one cycle leave the verdict unmeasured as two
swings did. A parried gap swing passes only when the gap's events number its parried swings and total parried swings
times the restore at a set state it can have started from: the next cycle's set state, or the previous cycle's when
that window took no swing. Otherwise the gap names it and the verdict alerts, as ADR 0820 does for an excluded cycle:
its restore cannot be told from a failed one. Control gap events count as control events.

A read sequence is not atomic either. Run 20261116-140210 read a parry during cycle 6's baseline: its swing, parried
and heal counts after the baseline, its healed, energize and energized totals before it (set health 400000, end
health 430000). When a segment holds events but no swing and the next segment holds the swing, both sides of that
read sequence are one swing: the counts move into the cycle (a split baseline: the swing came after the set reads, so
it started from the set state; a split end: its gain is in the end health and Rage read after the counts). The
verdict row names every split cycle (`['6 baseline']`); the moved counts are judged like any window.

## Consequences

- The scenario gains six reads per cycle and six per arm; the waits and the timeout do not change.
- Tests (`kinds/test_parried_restore.py`): the run 20261116-135038 layout (a parry before cycle 4's baseline, the
  previous cycle's Rage read after its gain) passes and is reported, and the same events counted in cycle 4's window
  alert; a gap swing without a parry and a trailing parry are reported; a gap parry restoring 0%, 4.5% or 5.5%
  alerts; mutant with s1 off (4 or 6) alerts on the gap; a gap swing and a window swing in one cycle are unmeasured;
  a control gap event alerts; a swing split across the baseline reads (run 20261116-140210's cycle 6) or the end
  reads passes and is named; a split swing restoring 5.5% alerts, and the mutant without the mending alerts.
- The judge took the split rule after the first run of its pair showed the split; a fresh pair on the final judge
  is the counted one.
- Only the Witch Hunter class file uses the kind: the Templar and Necromancer digests do not move.
- Number provisional: shared ADRs are numbered at merge.
