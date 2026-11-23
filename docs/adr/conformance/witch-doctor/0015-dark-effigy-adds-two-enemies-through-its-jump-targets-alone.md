# 0015. Dark Effigy adds two enemies through its jump targets alone

- Status: accepted
- Date: 2026-11-20

## Context

Written 2026-11-21, after the fix, as a catch-up for guide section 7.

Dark Effigy 707331: "Your Bad Juju and Hexfire now strike 2 additional nearby enemies." Its effect 0 is aura 107
SPELLMOD_JUMP_TARGETS +3 on Hexfire and Bad Juju, applied in `Spell::SelectImplicitChainTargets`: Bad Juju
(EffectChainTarget 0) chains to 0 + 3 = 3 targets, the tooltip's primary and 2 more. Before the fix the script added
up to 2 more from `Nearby(primary, 10)` on top, and Hexfire (EffectChainTarget 1) chained to 1 + 3 = 4 targets.
Mentor ruling M-58 (2026-11-21): follow the tooltip (G-1). Live Hexfire reached 4 enemies (L-TA-1); that stays a
recorded observation.

## Decision

- The script block that added targets is removed.
- `ApplyContracts` gives the Hexfire ranks (damage effect, SpellFamilyFlags word 1 bit 262144) EffectChainTarget 0, so
  the DBC +3 jump targets give primary plus 2.
- Voodoo Bolt and Frenzied Spirits also get jump targets through the DBC mask; that is untested.

## Consequences

- Regression: catalog `witch-doctor-dark-effigy-two-additional-enemies`: before Dark Effigy is learned (control arm)
  both spells strike the primary only; after the fix both strike the primary and two chained enemies, and neither a
  nearer enemy the script used to add nor a fourth chain target. It passed in 20261121-062124.
