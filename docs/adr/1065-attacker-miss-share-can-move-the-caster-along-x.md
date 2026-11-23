# 1065. attacker_miss_share can move the caster along x before counting

- Status: accepted (number provisional, assigned at merge)
- Date: 2026-11-23
- Decided by: mentor D-273 (Sun Cleric 27, 804632 attacker_miss), tool approved within delegation D-213

## Context

The 804632 `attacker_miss` entry casts Horusath Blast 500154 at `attacker1` 81 times per part. In the pair 20261122-232212 /
-232544 all 81 casts of part 2 were refused with reason 134 (`SPELL_FAILED_UNIT_NOT_INFRONT`) in run 2 only, so the ready
read was 0 and the part was `unmeasured`. The server turns a creature caster toward its target (Spell.cpp:3937) but never a
player; Spell.cpp:7351-7352 refuses a player's cast when the target is outside the 180 degree front arc, unless the target
is within its boundary radius (`Unit::IsWithinBoundaryRadius`, Unit.cpp:954-962, at least 2 yd). The harness has no facing
step and the player faces +x.

Measured with `position_x`, `position_y`, `position_o` and `distance` reads in short copies of the generated scenarios
(fix-d266/diag-1..3 in the class plan folder): the five attackers settle on a 3.0 yd circle around the caster, attacker1 at
-40 to +73 degrees from the +x facing (0 of 32 casts refused); an attacker can therefore fall behind the 90 degree limit.
A first design that moved the caster +3 yd, onto the spawn point, put attacker1 at 105 to 110 degrees, accepted only under
2 yd: 4 of 24 copies were refused and two parts of the pair were still unmeasured.

## Options

- Leave the flake: an `unmeasured` counted part is a regression.
- A harness facing step: C++, needs a G-39 note.
- The existing harness `relocate` step with a distance chosen from the measured geometry.

## Decision

The `attacker_miss_share` entry field `relocate_dx` (a nonzero number of yards, absolute value under the attackers' 3 yd)
adds one `relocate` step after the engage wait and before the first control read, so both arms are counted from the same
position. Sun Cleric uses -1: the front arc then covers attackers up to 109 degrees (cos >= -1/3) and the farthest attacker is
at most sqrt(10 + 6 cos) = 4.0 yd away, inside the 5 yd minimum melee range, so the swings continue. 96 of 96 short copies
were accepted (angle at most 59 degrees, distance 3.39 to 4.00 yd). A refused cast still leaves the ready read at 0 and the
part `unmeasured`. Python only, opt-in, default off.

## Consequences

- Tests: `test_relocate_dx_moves_the_caster_once_before_the_first_read` and
  `test_relocate_dx_is_a_nonzero_distance_under_the_attackers_distance` (kinds/test_attacker_miss_share.py); without the
  option the steps are identical.
- Finished-class scenario digests (15, 19, 19 `--stack`, 23) are unchanged.
- Sun Cleric: 804632 `attacker_miss` sets `relocate_dx: -1`; the counted pair must show the part measured on both runs.

## Addendum (2026-11-23, mentor D-319): -1.8 yd and the invalid-setup reason

The Sun Cleric class-end pair (20261123-105051 / -112044) refused all 81 casts of 500154 in part 6 of run 2 (reason 134,
`SPELL_FAILED_UNIT_NOT_INFRONT`), about 1 refusal in 160 parts at -1. A diagnostic of 16 full-length copies of that part
(20261123-115905), with position reads after the relocate, at every cycle end and before the first cast, found the caster's
orientation at 0 throughout and attacker1 fixed after settle (-59.4 to +62.2 degrees). A refusal therefore needs either a rare
settle beyond 109.5 degrees or an overlap with the lane predecessor. The cause is not proven.

- Sun Cleric 804632 now sets `relocate_dx: -1.8`. The front arc then covers attackers up to 126.9 degrees (cos >= -0.6), and
  the farthest attacker is at most 4.8 yd away, inside the 5 yd minimum melee range (Unit.cpp:933-937). This widens the
  margin; it is not a fix, and 40 reruns cannot show a 1-in-160 event gone.
- When a part is unmeasured because an aura read is wrong, the judge appends the refused casts and their cast results
  ("invalid setup: N casts of S refused, ..."). The status stays `unmeasured`. A run without refusals keeps the same text.
- The scenario contract states the covered angle and says that the relocate is a margin, not a proof.
- No existing harness step turns a player toward a unit. A "face unit" harness step is the proper fix for this kind of setup;
  it is the owner's (G-39 list).
