# 0550. A pulse's target cap is judged per pulse

- Status: accepted
- Date: 2026-11-13

## Context

Animate: Bone Wraith 805032: "striking up to $801411i nearby enemies" (claim 257.2, Bonestorm 801411, MaxAffectedTargets
5). A fixed_count entry with more dummies than the cap counts every dummy ever hit over one Command, and the Wraith's
ten pulses hit all 7 dummies between them, so the union over a Command cannot judge a per-pulse cap (design 1). The
mentor approved design 2, a per-pulse read.

## Decision

- Behaviour kind `pulse_targets` (module `cast_period.py`, hooked into `behaviour_scenario`, the metric_delta judge and
  the P5 label rows): a real setup cast raises the creature, then the trigger cast at the primary dummy. `dummies`
  dummies stand inside `radius` of the caster and one 5 yd beyond. Every `poll_ms` the game time and each dummy's hits
  of `hit_spell` from the creature (`spell_damage_count` with `caster_entry`) are read. The dummies struck between two
  reads are one pulse's targets.
- Verdict: no read window may strike more than the stated cap, at least one must reach it, and the far dummy is never
  struck. A dummy struck twice between two reads alerts; fewer than 3 windows with hits is unmeasured.

## Consequences

- 805032 `bonestorm_cap`: 7 dummies, 50 ms polls over 6000 ms. Pair c2-bone-1 read at most 5 per window in both runs.
  A pulse whose hits land across two reads shows as 4 + 1 or 3 + 2; that can only under-count, never over-count.
- Tests: `PulseTargetsTests` (test_cast_period.py), with a 6-target pulse and a struck far dummy that must alert.
  Templar `generate --class 19` and `--stack` byte-identical (no Templar entry has the kind).
