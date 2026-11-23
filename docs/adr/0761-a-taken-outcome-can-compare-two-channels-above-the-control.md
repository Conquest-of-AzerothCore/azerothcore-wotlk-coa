# 0761. A taken outcome can compare two channels above the control

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 380.0 (Twilight Frenzy 805751, "Can dodge and parry and move while active.") states no rate,
so the `taken_outcome` difference judge would need an expected 0 inside a 2-point band, which D-178 refuses. The
engine zeroes a melee swing's dodge and parry while the victim casts or channels unless CanDefendDuringChannel or
CanDefendDuringCast allows it (`Unit.cpp:3413-3416`, `3446-3449`, `5077-5094`). Design H6 of c14-tool2; mentor D-240
and D-247 (a Witch Hunter control channel; dodge and parry judged apart).

## Options

- `arm_casts` with a named avoidance fixture and the `above_control` judge.
- Expected 0 with the difference judge: refused by D-178.
- Evocation 12051 as the control channel: D-247 prefers a Witch Hunter channel when one exists.

## Decision

`taken_outcome` takes `arm_casts` (`{"control": [spell, target, cycle ms], "treatment": [...]}`, the cycle optional,
default `refresh_ms`; the target the caster, an attacker or the dummy, placed at the spell's range) and
`caster_avoidance` (`{"dodge": %, "parry": %}`), with `stacks` 1 and `expected_points` at least 2. Every cycle of an
arm sets the avoidance and casts the arm's spell; the counts start 200 ms after the first cast; a
`casting` read at each cycle's end must be 1. The `above_control` judge passes when the 99% Newcombe interval of the
share difference lies at or above `expected_points` and alerts when it lies below. `label_suffix` names the label.

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical.
- Seeded tests: 380 of 400 against 0 of 400 passes; 0 of 400 against 0 of 400 alerts (the mutant); 8 of 100 against 0 is
  `measured`; a dropped channel (casting 0) is unmeasured; malformed arm casts are refused.
- Witch Hunter: 805751 `channel_dodge` and `channel_parry`, Witchbane 574320 (an ordinary channel, no
  ALLOW_ACTION_DURING_CHANNEL, no pushback flag) at the dummy every 2000 ms in the control (at an attacker 3 yd away it
  fails with SPELL_FAILED_TOO_CLOSE), Twilight Frenzy on the caster every 600 ms in the treatment, 150000 ms per arm.
  Observation, not changed: the Frenzy channel and aura end 800 to 1000 ms after the cast in the harness (DurationIndex
  28 = 5000 ms), with or without attackers; Witchbane's channel lasts its 3000 ms. The server removes 805751's
  ALLOW_ACTION_DURING_CHANNEL (`AscensionWitchHunterCompletion.cpp:183-184`) and no rule lets it defend: code reading
  predicts an alert, which is reported, not fixed (D-247).