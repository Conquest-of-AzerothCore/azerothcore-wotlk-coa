# 0003. Silver Bullets adds its Undead share to the Darkslayer bonus

- Status: accepted
- Date: 2026-11-15

## Context

Silver Bullets 574149 / 574163 states "Increases the damage of Darkslayer by $s1%, increased by an additional $s2%
against Undead." ($s1 = $s2 = 10, rank 2 20). Mentor D-85 case (b) and D-93: one tooltip states one total, so a
Darkslayer hit on an Undead target is x1.20 (rank 1) and x1.40 (rank 2).

Both effects carry the Darkslayer class mask (SpellFamilyFlags[2] 32). Effect[0] is aura 108 SPELLMOD_DAMAGE; Effect[1]
is aura 112 with MiscValue 20014 (ASCENSION_CLASSMASK_CREATURE_DAMAGE) and the Undead type mask 32 in MiscValueB. The
class code turned Effect[1] into SPELL_AURA_MOD_DAMAGE_DONE_VERSUS (`ConvertCreatureTypeDamage`), a separate
`DoneTotalMod` factor in `Unit::MeleeDamageBonusDone`, and the engine multiplies it with the SPELLMOD_DAMAGE modifier:
the final07 pair read +43.72% for rank 2 (band 38..42) and +20.91% for rank 1 (1.1 x 1.1).

## Options

- Keep Effect[0] native, make Effect[1] a dummy aura and apply the Undead share in the class's hit hook as
  (100 + $s1 + $s2) / (100 + $s1).
- Rescale Effect[1] to $s2 / (1 + $s1) at load: not an integer (16.67 for rank 2), and it changes the effect value.
- Keep the conversion and divide out the product in the hook: depends on the engine factor staying where it is.
- Make SPELLMOD_DAMAGE additive with `DoneTotalMod`: an engine change for every class.

## Decision

The first option. `KeepCreatureTypeDamageForScript` (`AscensionWitchHunterCompletion.cpp`) sets Effect[1] of both
ranks to SPELL_AURA_DUMMY after the same record guard as the conversion; `SilverBulletsCreatureTypeShare`
(`AscensionWitchHunterAbilities.cpp`) multiplies a hit of a spell the effect's class mask covers, on a target of its
MiscValueB creature type, by (100 + effect 0 + effect 1) / (100 + effect 0) in `OnSpellCalculatedTarget`. Silver Bolts
804026 keeps the conversion.

## Consequences

- Counted pair 20261115-163258 / 20261115-163350 (worldserver 7cbb6fe9bc40): `574163 behaviour_hit_ratio undead` ok
  +39.78 / +39.99 (was +43.72), `574149 ... undead` ok +19.86 / +19.78 (was +20.91); the non-Undead controls
  (Harvest Golem 36) are unchanged: `574163 ... damage` ok +20.10 / +20.15, `574149 ... damage` ok +10.14 / +9.74.
- Gameplay change: a rank 2 Darkslayer hit on an Undead target drops from x1.44 to the stated x1.40 (rank 1 from
  x1.21 to x1.20). Other Darkslayer percent modifiers still multiply with Silver Bullets (engine rule, every class).
- Witch Hunter code only; no core, DBC or SQL change.
