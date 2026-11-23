# Phase since (`metric_delta` `phase_since`, ADR 1130)

`phase_since: true` makes each judged reading count only its own phase. Right before each phase's trigger cast the
scenario snapshots the judged read (and, with [`ratio_to_metric`](ratio_to_metric.md), its ratio base) and the
reading is judged relative to that snapshot (the harness `relative_to`): the before reading covers the control
phase alone and the after and expired readings the treatment phase alone. A cumulative event total (a damage or heal
total) of the control phase then does not enter the treatment reading, so a ratio of two totals compares one cast's
events with one cast's events. Both phases must cast the trigger, and no setup cast may repeat it (the trigger cast
marks the phase). It cannot difference a summed or windowed reading. Absent, the scenario is unchanged.

Named point: `fixtures` (the snapshots and the relative reads; it runs after `ratio_to_metric` has added the bases).

Witch Doctor: Puppeteer's Threads 92084 `stored_share` (the released 572837 hit over the Malefic Wrath hit that fed
it, 0 without the passive and 0.15 with it), Frenzied Spirits 560748 `heal_three` and `heal_one` (the Spirit Heal
560747 over the Wrath hit under the buff), Hex of Death 706557 `heal_cut` (a fixed heal the dummy casts on itself,
1500 against 1200).
