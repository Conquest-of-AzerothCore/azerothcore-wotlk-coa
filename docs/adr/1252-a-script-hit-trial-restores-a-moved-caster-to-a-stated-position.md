# 1252. A script hit trial restores a moved caster to a stated position

- Status: accepted (number provisional, assigned at merge)
- Date: 2026-11-23
- Decided by: mentor D-56, controller go 2026-11-23 (Felsworn 14, tool group fw-t4, Fel Torpedo 500610 "Torpedo
  forward ... deal ${$500761m1+$500761ppl1+$AP*.35} Shadowflame Damage to enemies in your path.")

## Context

Fel Torpedo 500610 triggers Chaos Rush Jump 802028 (CHARGE_DEST, TARGET_DEST_CASTER_FRONT, 10 yd) and its damage
500761 hits enemies within 3 yd of the caster. A `script_hit` entry places the dummy once, 2 yd ahead of the caster,
and never moves the caster back: after the first trial the dummy is 8 yd behind and later trials miss (Felsworn fix
note F3, 2 hits in 6 trials). The harness has a relative `relocate` (dx, dy, dz) and an absolute `teleport`
(map, x, y, z, o); the dash's real length is not a fixed relative step.

## Options

- A relative `relocate` of -10 yd after each cast: assumes the dash length exactly and leaves the facing as it is.
- Move the dummy each trial: the dummy is a stationary fixture and the dash direction follows the caster's facing.
- An opt-in `trial_position` that starts the scenario there and teleports the caster back before every trial, with
  an asserted position read.

## Decision

`trial_position` (`{"map", "x", "y", "z", optional "o"}`) sets the scenario `location` to that position and adds, at
the start of every trial of both arms and before the trial's auras and casts, the existing `teleport` action to it,
two SETUP asserts of the caster's `position_x` and `position_y` within 0.5 yd (`within_ms` 2000), and reads of the
dummy's `position_x` and `position_y`. It needs casts and the dummy receiver. The judge, the tolerance, the
expectation record and the evidence tables are unchanged. Python only, no harness C++.

## Consequences

- Test: `ScriptHitRelocateTests` (test_script_hit_relocate.py, run through test_hits.py): an entry without the field
  has no location, teleport or position read; every trial of both arms is restored and read before its auras and
  casts; a caster left at the end of a 10 yd dash fails the position assert; the expectation is the same with and
  without the field; malformed positions and a non-dummy receiver are refused.
- Only entries that set the field change; finished-class scenario digests are unchanged.
- The teleport is a fixture between trials, not part of the claim; a near teleport may end effects that break on
  teleport, which the trial's auras are set after.
- Documented in `apps/coa-gameplay-test/conformance/docs/behaviour-scenarios.md` (Script-cast hits).
