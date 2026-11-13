# Chase halts (`behaviour_metric_delta`, `kind: "chase_halt"`, ADRs 0596, 0604)

Two movable dummies (the hooked one at 3 yd, the chaser, the control, at `chaser_yd`) are ordered to attack the
caster's creature `chased_entry` (`attack_owned_creature`) standing beside a stationary dummy `far_yd` out, after
`raises` (`[spell, caster|far, power|null, settle_ms]`); then `spell` is cast at the hooked dummy. From `start_ms` after
the cast, over `window_ms` of stamped game time, each mover's distance to the far dummy is read. The hooked dummy must
cover `expected_ratio` of the chaser's yards (G-19 band in points of percent); a chaser under 3 yd is unmeasured.

The pilot 20261113-150434 read 0.00 yd for the chaser: fixture dummies do not chase after `attack_owned_creature`, so
the kind stays unmeasured until an enemy movement order exists (gap T6, ADR 0596).

`order: "move_point"` (ADR 0604) replaces the attack order: no `chased_entry`; `start_ms` after the hook (the jump
has landed), both movers get the same running harness point move of `move_yd` towards the far dummy (more than 3 yd
and short of the far dummy), and the same reads judge it. The unhooked mover is the control arm. Pilot
20261113-173235: 0.160 yd against 8.022 yd, ratio 0.0199.
