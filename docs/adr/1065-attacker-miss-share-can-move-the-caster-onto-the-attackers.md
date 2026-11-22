# 1065. attacker_miss_share can move the caster onto the attackers

- Status: accepted (number provisional, assigned at merge)
- Date: 2026-11-23
- Decided by: mentor D-273 (Sun Cleric 27, 804632 attacker_miss), tool approved within delegation D-213

## Context

The 804632 `attacker_miss` entry casts Horusath Blast 500154 at `attacker1` 81 times per part. In the pair 20261122-232212 /
-232544 all 81 casts of part 2 were refused with reason 134 (`SPELL_FAILED_UNIT_NOT_INFRONT`) in run 2 only, so the ready
read was 0 and the part was `unmeasured`. The server turns a creature caster toward its target (Spell.cpp:3937) but never a
player; Spell.cpp:7351-7352 refuses a player's cast when the target is outside the 180 degree front arc, unless the target
is within its boundary radius (`Unit::IsWithinBoundaryRadius`, Unit.cpp:954-962, at least 2 yd). The scenario places the
attackers 3 yd along +x and the harness has no facing step.

## Options

- Leave the flake: an `unmeasured` counted part is a regression.
- A harness facing step: C++, needs a G-39 note.
- The existing harness `relocate` step, once, onto the attackers.

## Decision

The `attacker_miss_share` entry field `relocate_onto_attackers` (true or absent) adds one `relocate` step (`dx` =
`STRIKER_DISTANCE`) after the engage wait and before the first control read, so both arms are counted from the same
position and every cast is inside the attackers' boundary radius. A refused cast still leaves the ready read at 0 and the
part `unmeasured`. Python only, opt-in, default off.

## Consequences

- Tests: `test_relocate_onto_the_attackers_moves_the_caster_once_before_the_first_read` and
  `test_relocate_onto_the_attackers_is_true_or_absent` (kinds/test_attacker_miss_share.py); without the option the steps
  are identical.
- Finished-class scenario digests (15, 19, 19 `--stack`, 23) are unchanged.
- Sun Cleric: 804632 `attacker_miss` sets it; the counted pair must show the part measured on both runs.
