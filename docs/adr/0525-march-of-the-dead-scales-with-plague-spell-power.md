# 0525. March of the Dead scales with Plague spell power

- Status: accepted
- Date: 2026-11-13

## Context

March of the Dead 707007's walkers hit with 707010 (Spell.dbc SchoolMask 40, Shadow and Nature). The
NecromancerCoefficients row read Frost spell power (school 16): +132 Frost added 99 to each hit. The owner ruled
(Q-b3b-6, option (b)) the spell's own schools; the mentor approved fix note FN-own-10.

## Decision

- AscensionNecromancerData.h row 707010: school 16 -> 40, like 504022 and 801514.

## Consequences

- Regression (class file): `explosion_sp` (+132 Frost 24666: the hit stays the spell power 0 value) and a matching
  arm `explosion_sp_shadow` (Increase Shadow Dam 78 33819: +0.75 x 78 per hit); `explosion` (spell power 0) is the
  base, the uncast trials the control.
