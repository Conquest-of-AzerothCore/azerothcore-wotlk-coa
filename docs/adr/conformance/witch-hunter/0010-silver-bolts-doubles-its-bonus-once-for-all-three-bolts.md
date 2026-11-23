# 0010. Silver Bolts doubles its bonus once for all three bolts

- Status: accepted
- Date: 2026-11-15

## Context

Silver Bolts 804026 reads "Damage dealt by Heartseeking Bolt, Shadowblast, and Damnation is increased by $s1%, doubled
against Undead or Demons or enemies affected by Shadow Trap." ($s1 = 15). Mentor D-163: 1.15 on a plain target and
1.30 ("doubled" = 30%) on an Undead, Demon or Shadow Trapped target, for all three spells.

Effect[0] is aura 112 with MiscValue 20014 (ASCENSION_CLASSMASK_CREATURE_DAMAGE), MiscValueB 36 (Demon 4 | Undead 32)
and class mask (65536, 2048, 16), which covers the three spells. Effect[2] is aura 108 SPELLMOD_DAMAGE 15 with class
mask (65536, 2048, 0): Damnation and Heartseeking Bolt, not Shadowblast (SpellFamilyFlags[2] 16).

The class code turned Effect[0] into SPELL_AURA_MOD_DAMAGE_DONE_VERSUS (`ConvertCreatureTypeDamage`), a separate factor
that the engine multiplies with the SPELLMOD_DAMAGE bonus, and `witch_hunter_silver_bolts_shadow_trap` multiplied the
damage taken by a Shadow Trapped target by Effect[2] again. The counted pair 20261115-204501 / 20261115-204542 read
Heartseeking Bolt and Damnation at 1.322 on Undead or Shadow Trapped targets (1.15 x 1.15), and Shadowblast at 1.00 on a
plain target and 1.15 on an Undead or trapped one. This is the mechanism ADR 0003 removed for Silver Bullets.

## Options

- Keep Effect[2] native, make Effect[0] a dummy aura and apply the doubled share once in the class's hit hook as
  (100 + $s1 + $s1) / (100 + $s1); add Shadowblast's bit to Effect[2]'s mask at load, guarded on the DBC value.
- Keep the conversion and the trap hook and divide out the product: depends on where the engine applies the factor.
- Edit the Spell.dbc mask for Shadowblast: a data change outside the class code (mentor D-168 asks for class code).

## Decision

The first option, following ADR 0003. `ApplyContracts` (`AscensionWitchHunterCompletion.cpp`) sets Effect[0] of 804026
to SPELL_AURA_DUMMY through `KeepCreatureTypeDamageForScript`, and adds word 2 bit 16 to Effect[2]'s class mask only
while that effect is still SPELLMOD_DAMAGE with the DBC mask (65536, 2048, 0); corrected data leaves the rewrite
inactive. `SilverBoltsDoubledShare` (`AscensionWitchHunterAbilities.cpp`) multiplies a hit of a spell Effect[0]'s mask
covers by (100 + effect 2 + effect 0) / (100 + effect 2) once, when the target's creature type is in Effect[0]'s
MiscValueB or the target carries Shadow Trapped 681177. `OnSpellCalculatedTarget` applies it after the Heartseeking
Bolt bounty (504478), so the bounty part of a bolt is doubled too. The Shadow Trap UnitScript and
`ConvertCreatureTypeDamage` are removed.

## Consequences

- Counted pair 20261115-205944 / 20261115-210219 (worldserver 9a5f0c2d42be), `804026 behaviour_hit_ratio`, all ok:
  Heartseeking Bolt plain +14.96 / +14.99, Undead +29.94 / +29.99, trapped +29.87 / +29.95; Damnation +14.98 / +14.98,
  +29.95 / +29.95, +29.95 / +29.95; Shadowblast +14.95 / +14.97, +29.96 / +29.95, +29.93 / +29.94; Undead and trapped
  +29.94 / +29.98; with two Bounty Hunter stacks on an Undead target +30.00 / +30.06 (the bounty is about 36% of
  the control hit, so a share that skipped it would read about +24.6); Darkslayer control +0.01 / +0.00 on all three
  targets. Silver Bullets 574149 / 574163 stay at +9.74 / +19.94 and +19.88 / +40.02 (run a).
- Expected: 1.15 on a plain target and 1.30 on an Undead, Demon or Shadow Trapped target for Heartseeking Bolt,
  Damnation and Shadowblast; an Undead and trapped target stays at 1.30. Darkslayer 804179, outside the masks, stays
  at 1.00.
- Gameplay change: Heartseeking Bolt and Damnation drop from x1.3225 to x1.30 on Undead, Demon or trapped targets.
  Shadowblast rises from x1.00 to x1.15 on a plain target and from x1.15 to x1.30 on the others.
- The deterministic `melee_spell_damage_done` metric no longer includes the doubled share, which only a real hit
  reaches; the Silver Bolts scenario asserts the native 1.15 there and the counted conformance entries measure 1.30.
- Witch Hunter code only; no core, DBC or SQL change.

## Amendment (2026-11-16, owner O-30, mentor D-354): the bounty part

Witch Hunter ADR 0020 moves the Bounty Hunter 805773 bonus out of the Heartseeking Bolt hit into its own Holy hit,
Collect Bounty 504687 (family 21 flags (0x4000000, 0, 0)), which neither Silver Bolts mask covers. The doubled share no
longer covers the bounty: the sentence of the Decision "so the bounty part of a bolt is doubled too" and the two-stack
Undead reading of the Consequences describe the state before ADR 0020. `804026 behaviour_hit_ratio
heartseeking_bounty_undead` stays at 1.30 on the bolt alone; `804026 behaviour_hit_ratio bounty_hit_undead` reads
504687 at 1.0 with and without the talent (mentor D-354 b: no shared bounty).
