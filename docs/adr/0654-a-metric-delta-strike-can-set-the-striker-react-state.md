# 0654. A metric delta strike can set the striker's react state

- Status: accepted
- Date: 2026-11-14

## Context

A behaviour `metric_delta` `strike` spawns a defensive striker (reaction 1) 3 yd from the caster. On Ghoul Mastery
503740 the Command makes the Ghoul cast Command: Ghouls 801514 (an area of enemies within 10 yd of the Ghoul), which
damages the striker. A defensive striker then melees the Ghoul before the scripted strike and can daze it from behind
(Dazed 1604, -50% run speed), so the control reads 0.57143 instead of 1.14286. Diagnostic 20261114-080834 (240 copies
mixed with 720 generated scenarios): striker damaged, in combat and swinging right after the Command in 240/240, 1604
on the Ghoul in 5/240. ADR 0653 made such a control unmeasured; it did not remove the cause.

## Options

- Place the striker out of the area: the striker must stand in melee range for its Hamstring (a creature cast out of
  range fails with 97), and no step moves a fixture creature.
- Send the Ghoul with Grave March 500991, which casts no entry ability: in diagnostic 20261114-081623 the Ghoul did
  not attack the dummy in 29/240 copies and one strike failed out of range.
- Change the react state for the whole scenario: the harness already reads a fixture's `reaction`.
- Switch the react state at the strike: needs a new harness step.

## Decision

A `metric_delta` `strike` may set `reaction` (0 passive, 1 defensive, 2 aggressive) for its striker. Unset keeps 1. A
passive striker swings only through its scripted casts. Diagnostic 20261114-082317 (passive copies, same mix): still hit
and in combat in 240/240, 0 swings, no 1604, control 1.14286 in 240/240, Hamstring landed in 240/240.

## Consequences

- Test: `OwnedCreatureStrikeTests` (test_behaviours.py).
- Only entries that set the field change; the Templar scenarios are unchanged.
