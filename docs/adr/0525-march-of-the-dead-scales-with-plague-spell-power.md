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

- Regression (class file): `explosion_sp` (+132 Frost 24666: the hit stays the spell power 0 value, 691) and a
  matching arm `explosion_sp_all` (QA Test +100 SP 10062, every school: +0.75 x 100 per hit, 766); `explosion` (spell
  power 0) is the base, the uncast trials the control. The tooltip's $SP is the lowest school spell power, so a
  one-school fixture cannot raise the expectation: a Shadow-only +78 (33819) read 749 per hit (691 + 58.5), which the
  check judges against 691.
