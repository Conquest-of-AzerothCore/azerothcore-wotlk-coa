# 0605. A follow side is read as a bearing from the owner's facing

- Status: accepted
- Date: 2026-11-13

## Context

Claim 269.1, Animate: Frost Wyrm 805428 "that flies behind the Necromancer": the Wyrm 50177 follows at angle pi
(AscensionNecromancerSummons.cpp:609-622), other followers at PET_FOLLOW_ANGLE plus their slot. The ledger asked for
a G-39 note first; the note (c6-g39-notes.md, section 269.1) found that existing reads suffice: a scenario caster
faces +X and fixtures spawn along +X, and `owned_creature_distance_2d` reads exact 2D distances to any unit.
Fixture distances cannot be negative (`run.py` validates 0 to 100), so a dummy behind the caster is not available.

## Options

- Two dummies, one in front and one behind: needs a negative fixture distance or a new placement field.
- One dummy in front and the caster itself as the second reference: three distances fix the bearing.

## Decision

Kind `follow_bearing` (kinds/follow_bearing.py): the bearing from the caster's facing is
`acos((r^2 + d^2 - D^2) / (2 r d))` with r the minion-caster, d the caster-dummy and D the minion-dummy distance. The
follower must stand at 135 degrees or more, the control (a stock follower read alone, before the follower is raised)
under 135. A control behind the caster cannot discriminate and is unmeasured. The dummy is friendly (faction 35).

## Consequences

- Pilot 20261113-173649: the Wyrm read 180.0 degrees, the Ghoul control 90.0 degrees.
- It assumes nothing turns the server-side caster; the control at exactly 90 degrees in the pilot confirms the
  facing.
- Templar has no entry of this kind; the shared tables are unchanged.
