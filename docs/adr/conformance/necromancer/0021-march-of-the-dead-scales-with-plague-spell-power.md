# 0021. March of the Dead scales with Plague spell power

- Status: accepted
- Date: 2026-11-13

## Context

March of the Dead 707007's walkers hit with 707010 (Spell.dbc SchoolMask 40, Shadow and Nature). The
NecromancerCoefficients row read Frost spell power (school 16): +132 Frost added 99 to each hit. The owner ruled
(Q-b3b-6, option (b)) the spell's own schools; the mentor approved fix note FN-own-10.

## Decision

- AscensionNecromancerData.h row 707010: school 16 -> 40, like 504022 and 801514.

## Consequences

- Regression (class file): `explosion_sp` (+132 Frost 24666: the hit stays the spell power 0 value, 691),
  `explosion_sp_shadow` (+78 Shadow 33819: 691.2 + 0.75 x 78 = 749.7, the engine's 749) and `explosion_sp_all` (+100
  every school 10062: 691.2 + 75 = 766.2, 766); `explosion` (spell power 0) is the base, the uncast trials the control.
- The tool reads the tooltip's $SP as the lowest school spell power, so the Shadow arm carries its 0.75 x 78 term as a
  stated multiplier (749 / 691) on the tool's spell power 0 model. The tooltip's displayed $SP and the server differ for
  a one-school fixture: a text observation, no server change.
