# 0082. Bonefreeze breaks on the stock damage cap

- Status: accepted
- Date: 2026-11-18
- Supersedes: [0011](0011-bonefreeze-takes-the-damage-interrupt-outside-the-family-contracts.md)

## Context

Issue #12435. Command: Bonefreeze 504489: "Command your Skeletal Mages to freeze enemies at target location for
$504845d (8 sec vs players). Damage taken may end the effect." ADR 0011 added AURA_INTERRUPT_FLAG_TAKE_DAMAGE to
Bonefreeze 504845, so one point of damage from any source ended the freeze (Unit::DealDamage ->
RemoveAurasWithInterruptFlags), including the commanding Skeletal Mage's own Frost 801513 hits on its target.

The stock "may end" rule of a breakable crowd control is a cumulative damage cap. 504845 has two SPELL_AURA_MOD_ROOT
effects and ProcFlags 567976 (0x8AAA8), no AuraInterruptFlags and no `spell_proc` row:

- AuraEffect::CalculateAmount (SpellAuraEffects.cpp, the MOD_CONFUSE/FEAR/STUN/ROOT/TRANSFORM case) gives each root
  the amount `creature_classlevelstats` BaseHealth(caster level, CLASS_WARRIOR, expansion 2) / 4.75 when the spell has
  ProcFlags and a caster.
- HandleBreakableCCAuraProc subtracts each proccing hit's damage and removes the aura at 0 or below.
- LoadSpellProcs (World.cpp, after LoadSpellInfoCustomAttributes, which runs `ApplyContracts` through
  OnLoadSpellCustomAttr) generates the proc entry from `spellInfo->ProcFlags`, so a contract on ProcFlags reaches it.

0x8AAA8 lacks PROC_FLAG_TAKEN_SPELL_MAGIC_DMG_CLASS_NEG (0x20000): without it no harmful magic spell, the Mage's Frost
included, would erode the cap. Stock Frost Nova 122 / 42917 carries 0xA22A8, which includes it.

Cap on the reference character (level 60; the Mage takes its owner's level, `Scale`, AscensionNecromancerSummons.cpp):
`creature_classlevelstats` level 60 class 1 is basehp0 3052, basehp1 4979, basehp2 1
(data/sql/base/db_world/creature_classlevelstats.sql; no update changes its health). LoadCreatureClassLevelStats
replaces a base health of 1 with the highest lower expansion, so BaseHealth[2] = 4979 and the cap is
int32(4979 / 4.75) = 1048 per root.

## Owner rulings (2026-11-18)

- Use the stock cumulative damage cap.
- All damage counts: add PROC_FLAG_TAKEN_SPELL_MAGIC_DMG_CLASS_NEG to 504845 (Frost Nova parity).

## Considered options

1. Keep the interrupt flag. Rejected: the commanding Mage breaks its own freeze, and "may end" names no "any damage".
2. Drop the flag and keep the DBC ProcFlags. Rejected by the owner: harmful magic spells would never end the freeze.
3. Drop the flag and add the magic-negative proc flag. Chosen.

## Decision

`ApplyContracts` adds PROC_FLAG_TAKEN_SPELL_MAGIC_DMG_CLASS_NEG to 504845's ProcFlags instead of the interrupt flag.
The dead family-29 block no longer names 504845 (it would have added the interrupt flag, made the freeze single-target
and dropped Effect[1]); 704860 Necrotic Chain keeps that block unchanged.

## Consequences

- A Bonefreeze holds until the damage it takes adds up to 1048 at level 60 (each root holds its own cap; both receive
  every proccing hit). Melee, ranged, magic and periodic damage all count.
- The commanding Mage's 801513 (about 51 per hit at level 60 without spell power) no longer ends the freeze at once.
- Regression (class file): `damage_holds` (the Mage's hits land and the target is still frozen 6000 ms after the
  Command) and `threshold` (one Lichfrost 501978, 569 to 597, leaves the freeze on; one Lichfrost doubled by 13055 set
  to +100%, 1138 to 1194, ends it). `damage_ends` is removed: it encoded ADR 0011.
- The `area` entry keeps its Pacify precondition; it no longer needs it for the freeze to survive the first splash.
