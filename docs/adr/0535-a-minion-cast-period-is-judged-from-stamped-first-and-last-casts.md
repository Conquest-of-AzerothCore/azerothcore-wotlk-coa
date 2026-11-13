# 0535. A minion's cast period is judged from its stamped first and last casts

- Status: accepted
- Date: 2026-11-13

## Context

Animate: Plaguefather 805048, owner ruling Q-a1-8: the Plaguefather casts Bone Toss 704706 on its target every 1 s
(ADR 0531). A count of casts in one game-time window bounded the period only to 923-1105 ms, because the first cast's
phase was not stamped, and the Plaguefather lives 15 s, so the window cannot grow. The mentor ruled that such a bracket
is not a verdict and asked for a judge of period = (last stamped cast - first stamped cast) / (n - 1) in game time
(Python only, G-39).

## Decision

- A behaviour kind `cast_period` (module `cast_period.py`, hooked into `behaviour_scenario` and the metric_delta judge):
  a real setup cast raises the creature; uncommanded for `control_ms` (at least two periods) it must cast nothing
  (control); then the trigger cast (a Command) and, every `poll_ms` (at most half the period) over `window_ms`, the
  game time (`game_time_ms`) and the creature's casts (`owned_creature_spell_cast_count`, ADR 0485) are read.
- The verdict brackets the first cast and the last cast each between two stamped reads and judges the period bracket
  [(last read before the last cast's read - first cast's read) / (n - 1), (last cast's read - read before the first
  cast) / (n - 1)] inside the expected period +- the G-19 band. A cast in the control, two casts between two reads or
  a falling count alert; fewer than 3 casts is unmeasured.

## Consequences

- 805048 `bone_toss_period` uses it: 100 ms polls over 9500 ms after the Command give about 9 intervals, a bracket of
  about 200 / 9 ms inside 950-1050 ms; the live 1.24 s, a 3000 ms pulse and no Bone Toss alert or stay unmeasured.
- Tests: `test_cast_period.py` (seeded series; a 1240 ms, 900 ms and 3000 ms period and a control cast must alert),
  registered in the conformance suite. Templar `generate --class 19` and `--stack` unchanged (no Templar entry has the
  kind).

## Addendum (cycle 2, same module): per-pulse targets and stamped aura windows

- `pulse_targets`: a creature's area pulses (Bonestorm 801411 of the Bone Wraith, claim 257.2) are read every
  `poll_ms` of wait with game-time stamps, as each dummy's hits from that creature; the dummies struck between two
  reads are one pulse's targets. No pulse may strike more than the stated cap, one must reach it, the far dummy never;
  a dummy struck twice between reads alerts, fewer than 3 pulses is unmeasured. The union of a whole Command (the
  fixed_count design) is not a per-pulse cap.
- `aura_window`: a cast's aura on the dummy (Ice Barrage 501997's channel, Deathly Chill 805424, claim 267.1) is
  polled with game-time stamps over a start and an end window given in game time (each wait step's measured 9 ms
  overhead is allowed for), without the talent (control) and with it learned; the duration from the first read with
  the aura to the first without is judged against the stated value +- the G-19 band in both phases. Regeneration is
  off, so Runic Power does not decay during the 2000 ms control cast.
- Tests: `PulseTargetsTests` and `AuraWindowTests` (test_cast_period.py), each with a mutant that must alert. Templar
  `generate --class 19` and `--stack` byte-identical.
