# 0421. Bonefreeze takes the damage interrupt outside the family contracts

- Status: accepted
- Date: 2026-11-13

## Context

Command: Bonefreeze 504489: "Command your Skeletal Mages to freeze enemies at target location for $504845d (8 sec vs
players). Damage taken may end the effect." The Skeletal Mage casts Bonefreeze 504845 on every enemy within 8 yd of
the target. 504845 is SpellFamilyName 21, and `ApplyContracts` returns for every family other than 29
(AscensionNecromancerContracts.cpp, before the per-spell blocks), so the 504845 / 704860 block that adds
AURA_INTERRUPT_FLAG_TAKE_DAMAGE never ran for 504845. The client row has AuraInterruptFlags 0. Measured on build
1f17eb215ef3 (pairs prove-3 to prove-5, B3 side b): the Mage hits the frozen dummy twice within 6000 ms and the freeze
holds until its 40000 ms expire. Fix note F-b3b-1, approved by the mentor for the interrupt flag only.

## Considered options

1. Move the whole 504845 / 704860 block before the family return. Rejected: its root rewrite, TargetA change and
   Effect[1] drop would turn the area freeze into a single-target root, and no clause backs that.
2. Add only the interrupt flag for 504845 before the family return. Chosen.

## Decision

`ApplyContracts` adds AURA_INTERRUPT_FLAG_TAKE_DAMAGE to 504845 before the family check. The rest of the block stays
dead for 504845 and is recorded as an owner observation; 704860 Necrotic Chain (family 29) keeps the whole block.

## Consequences

- Any damage now ends a Bonefreeze (Unit::DealDamage -> RemoveAurasWithInterruptFlags), including the commanding
  Mage's own attacks on its target.
- Regression (class file): the Mage's hits end the freeze on the target (`damage_ends`, `damage_lands`), the dummies
  around it that take no damage stay frozen 38500 ms (`area_held`), and every dummy in the 8 yd area is frozen
  (`area`). The "8 sec vs players" cap (OnCalcMaxDuration, keyed by id) is untouched.
