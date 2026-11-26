# 0027. Owner ruling Felsworn O-33: Fury Unleashed and Glaiving follow their tooltips

- Status: accepted (owner ruling Felsworn O-33 (2026-11-24))
- Date: 2026-11-24

## Context

Fury Unleashed 555738, server DBC text: "Spin your glaives for $d, increasing movement speed by $s2% and dealing
$806095s1% Weapon Damage every $t1 sec with both weapons to all nearby enemies." `$806095s1` reads 200 (806095
Effect[0] SPELL_EFFECT_WEAPON_PERCENT_DAMAGE, BasePoints 199, DieSides 1). The aura's Effect[0] (aura 23, 1000 ms)
triggers 555739, identical to 806095 except Effect[0] BasePoints 149 (150%). Nothing casts 806095; the archived live
logs hold 555739 hits and no 806095 event.

Glaiving 560578, server DBC text: "Increases the damage dealt and reduces the Energy cost of Fury Unleashed by $s1%."
($s1 = 50). Effect[0] is aura 107 SPELL_AURA_ADD_FLAT_MODIFIER, MiscValue 3 = SPELLMOD_EFFECT1
(`SpellDefines.h:79`), class mask 0/0/0x400000 (the hit flag of 555739 and 806095): it adds 50 points to the hit's
weapon percent, 150 to 200, not 50% to its damage.

Measured before (night question N-5; counted pair 20261123-232654 / -232744, build d205a36d82b1, server commit
5039b8347e): the forced critical 555739 hit at attack power 20312 read 10580 and 10570 (150% path; the tooltip's 200%
gives 13992 to 14107); Glaiving added +26.13% and +26.15% per non-critical hit (99% interval +24.8% to +27.5%)
against the stated +50%.

The owner ruled (Felsworn O-33 (2026-11-24)): the server follows the tooltips. Fury Unleashed deals 200%, Glaiving adds a real +50% damage.

## Options

- Trigger 806095 from 555738 instead of 555739: the hit's spell id would change from the one the live logs show.
- Raise 555739 Effect[0] to the value the tooltip names, read from 806095's own record.
- Glaiving: keep the flat SPELLMOD_EFFECT1 and raise its points, a figure no record states; or make Effect[0] a
  percent damage modifier with its own 50.

## Decision

In `ApplyContracts` (`AscensionFelswornContracts.cpp`):

- 555739 Effect[0] takes the BasePoints of 806095 Effect[0] from `sSpellStore` (199, so 200% with DieSides 1). The
  hit keeps its id, school, Effect[1] normalized weapon damage and class flags.
- 560578 Effect[0] becomes aura 108 SPELL_AURA_ADD_PCT_MODIFIER with MiscValue SPELLMOD_DAMAGE, keeping its
  BasePoints (50) and class mask. `Unit::MeleeDamageBonusDone` applies SPELLMOD_DAMAGE to the hit's done damage, so
  the hit deals 1.5 times as much. Effect[1] (the -50% Energy cost) is unchanged.

## Consequences

- With both: 200% weapon damage plus the Effect[1] flat, times 1.5. Balance-relevant by the ruling.
- Keyed to 555739 and 560578 by id. Both are Felsworn spells; no other class file, class code or shared data reads
  them. 806095 is only read, never cast. No engine, SQL, DBC or client text change: the tooltips already state 200%
  and 50%.
- Regressions: `555738 hit_ap` (forced critical hit at +20000 attack power, band 13992 to 14107; 150% reads about
  10.5 thousand and is excluded; the before read has no cast) and `560578 damage` (hit ratio of non-critical 555739
  hits, control arm without Glaiving against the arm with it learned, expected 1.50).
