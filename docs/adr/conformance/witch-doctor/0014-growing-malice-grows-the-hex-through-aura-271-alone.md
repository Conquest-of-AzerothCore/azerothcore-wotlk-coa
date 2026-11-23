# 0014. Growing Malice grows the Hex through aura 271 alone

- Status: accepted
- Date: 2026-11-20

## Context

Written 2026-11-21, after the fix, as a catch-up for guide section 7.

Growing Malice 706551: "Each tick of Hex of Malice increases the damage of the next tick on the enemy by $582257s1%,
stacking $582257u times" (3%, 10 stacks). Each periodic Hex tick procs 582257, whose effect 0 is aura 271
SPELL_AURA_MOD_DAMAGE_FROM_CASTER (3% per stack, the Hex class mask), so `Unit::SpellDamageBonusTaken` already scales
every later tick. The proc also rescaled the Hex tick amount by (100 + 3 s') / (100 + 3 s), counting the growth
twice: eight ticks summed to 1531 in both final06 runs against about 1402 from the tooltip (cycle 8 lead). The
mentor accepted the final06 growth verdict as superseded by this fix (M-61).

## Decision

- The rescale is removed; the handler only casts 582257 while the doctor owns a Hex with a periodic effect.

## Consequences

- Regression: catalog `witch-doctor-growing-malice-counts-once`: the control arm without the talent reads 8 ticks of
  159 (1272); with it, 7 stacks of 582257 after the seventh tick and 8 ticks summing to 1402. It passed in
  20261121-050156.
