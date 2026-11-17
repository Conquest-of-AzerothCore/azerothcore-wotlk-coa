# 0021. Slayer's Mark's ranged attacker bonus reaches the WitchCoefficients rap rows

- Status: accepted
- Date: 2026-11-16

## Context

Slayer's Mark 804068 reads (server Spell.dbc Description): "Mark an enemy, increasing the attack power of all attackers
against that target by 150 ...". Clause 351.1, ranged side. The 150 is built by the class code: Slayer's Mark Periodic
804073 is rewritten to SPELL_AURA_MELEE_ATTACK_POWER_ATTACKER_BONUS and SPELL_AURA_RANGED_ATTACK_POWER_ATTACKER_BONUS on
the marked enemy (`AscensionWitchHunterCompletion.cpp`).

The f-n351 fix note (pair 20261116-205210 / -205246, build 7c002cabe0) measured Boltslinger 500159 at +0% with the mark
(99% interval 0..0 in both runs) against +63.29% expected, while stock Auto Shot 75 gained +25.6% / +30.4% in the same
runs. Cause: every WitchCoefficients row has its effect's `BonusMultiplier` set to 0 and a `spell_bonus_data` row of
zeros, so the stock AP term of `Unit::SpellDamageBonusDone`, which adds the victim's attacker bonus, contributes
nothing; the class's replacement term in `witch_hunter_scaling::ModifySpellEffectBaseValue` adds
`RAP x c.rap` from the caster alone, with no victim.

Mentor D-362 asked for a route without SQL and without an engine file; D-366 approved it with two rules: (1) include a
row only where its tooltip formula has an explicit RAP coefficient term, weapon-damage parts already get the stock
flat bonus and are not touched; (2) the Quickdraw entry `804068 ap_ranged_hit` takes the stock arithmetic as its
expected value and is not counted.

## Options

- `spell_script_names` rows and an `OnEffectLaunchTarget` script per spell (the Ranger Skullpiercer precedent):
  needs SQL.
- A victim argument on `ModifySpellEffectBaseValue`: a shared engine hook used by 11 CoA files.
- `UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN`: no effect index, and after the done and taken percent modifiers.
- The three class-code routes of the fix note (chosen).

## Decision

Witch Hunter code only; no SQL, no engine file. The term added is `uint32(victim bonus x c.rap)` for a row selected by
`AscensionWitchHunter::VictimRangedAttackerBonus` (rows with `c.rap > 0`, minus the rows whose tooltip has no RAP term),
passed through the spell's own done modifiers as the difference `SpellDamageBonusDone(raw) - SpellDamageBonusDone(0)`
(so no flat done term is counted twice) and, for direct hits, the taken modifiers the same way:

1. Direct rows (effect 2 SCHOOL_DAMAGE): `witch_hunter_casts::OnSpellCalculatedTarget`, before the class's percent
   multipliers (Brand, Arbalest Mastery, Silver Bullets, Silver Bolts), into `damageBeforeTakenMods` and `damage`.
   Armor and the critical doubling then apply as to the rest of the hit.
2. Periodic damage rows (aura 3): `witch_hunter_scaling` subscribes to `UNITHOOK_ON_AFTER_AURA_EFFECT_CALCULATE_AMOUNT`
   and adds the term after the stock done snapshot, with the aura's `GetPctMods()`; the stack multiply and the per-tick
   taken modifiers follow, as for the stock `ap_dot_bonus` term. A mark cast after the DoT reaches it only on
   recalculation or reapplication, as stock.
3. Periodic trigger rows (aura 227, Witchbane): route 1 on the triggered shot 704342, matched through
   `GetTriggeredByAuraSpellInfo()` (an aura 227 Effect[0] whose trigger spell is the shot), read at each shot.

Rows, by their tooltip (Spell.dbc server set, the parent card where the row's own text is empty):

- Included: Boltslinger 500159 (92091 `${$RAP*0.2}`), Caltrops 504447 (503679 `$RAP*.25`), Quickdraw 804193 and
  806846-806851 e1 (`$RAP*0.2`), Twilight Frenzy 805753 (805751 `$RAP*.1`), Heartseeking Bolt 805754 (`$RAP*0.5`) and
  807279-807284 (`$RAP*0.4`), Tormentor 501344-501355 and 800162 (`$RAP*.295`), Feast of Talons 500564 (`$RAP*.13`),
  Witchbane 520211-520213, 574319, 574320, 578297, 800165 (`$RAP*0.15`).
- Left out, no RAP term in the tooltip: Track 500181 e2 (`${$m3+$ppl3}`), Shadow Claw 800697 (`${$m1+$ppl1}`).
- Left out, weapon damage: Sixfold Shot 807527 e1 is effect 121 NORMALIZED_WEAPON_DMG; its rap term sits inside the
  weapon damage, which already receives the stock flat `int32(150 / 14 x 2.8) = 30` of `MeleeDamageBonusDone`.
- The weapon parts of Quickdraw, Heartseeking Bolt and Twilight Frenzy (effect 31) are not touched; they keep the stock
  flat bonus.

The term uses the row's `c.rap`, the coefficient the attacker term already uses. Where the tooltip states another
coefficient (Feast of Talons .13 against 0.1; Heartseeking Bolt 807279-807284 0.4 against 0.5) the difference is an
observation, not changed here.

Area reduction: route 1 adds the term after `Spell::DoAllEffectOnLaunchTarget`'s area reduction and chain multipliers.
The fix note named Track 500181 e2 as the one area row; Track is left out by rule (1). None of the included direct rows
is an area or chain effect in the DBC (TargetA 6, ChainTarget at most 1), so no included row skips a reduction today.

## Consequences

- Stock order is kept: the term is multiplied by the done and taken percent modifiers like the rest of the AP term.
  The added term is truncated once (`uint32`), separately from the attacker term, so a hit can differ by one point from
  a single combined truncation. Witchbane's aura amount takes SPELLMOD_DOT (`aura_ascension_witch_hunter_lifecycle`);
  the added term rides on the shot 704342 and takes that shot's modifiers instead.
- Every source of SPELL_AURA_RANGED_ATTACK_POWER_ATTACKER_BONUS on a target now raises the included rows of a Witch
  Hunter, as stock does for its own AP-coefficient spells. Only a Witch Hunter caster and the listed Witch Hunter
  spell ids are read; other classes' spells are not touched.
- Out of scope, observations: the melee `c.ap` rows skip SPELL_AURA_MELEE_ATTACK_POWER_ATTACKER_BONUS the same way (by
  code reading, not measured); neither path adds the caster's SPELL_AURA_MOD_RANGED/MELEE_ATTACK_POWER_VERSUS.
- Regression in `classes/witch_hunter.json` (clause 351.1): `804068 behaviour_hit_ratio ap_ranged_shot` (direct,
  Boltslinger, deciding), `ap_ranged_trigger` (aura 227, Witchbane), `ap_ranged_weapon` (weapon, Sixfold Shot, stock
  flat only), `804068 behaviour_metric_delta ap_ranged_dot` (aura 3, Tormentor, against `501349 bolt_dot_total`), with
  `ap_ranged_auto_shot` (stock Auto Shot) as the unchanged contrast. `ap_ranged_hit` (Quickdraw) expects 1.1299, the
  stock arithmetic (1.0550 before the fix); its 1.9 to 2.5 point shortfall stays an open observation and the label
  is not counted.

## Amendment 1 (2026-11-16): Sixfold Shot 807527 is included (mentor D-371)

review19 (I-1) found that the Decision above left Sixfold Shot 807527 e1 out on a stock analogue, against rule (1) of
D-366: its own tooltip reads "each dealing $s1% Ranged Weapon Damage plus ${$m2+0+$RAP*0.25} Physical Damage", an
explicit RAP coefficient term. D-371 rules it in. This amendment supersedes the bullet "Left out, weapon damage:
Sixfold Shot 807527 e1" and the `ap_ranged_weapon` expectation of the Consequences; the rest of the Decision stands.

- Route 1 now also takes a SPELL_EFFECT_NORMALIZED_WEAPON_DMG effect that has a row. 807527 e1 is the only such row
  among the 41. The term `uint32(victim bonus x c.rap)` (150 x 0.25 = 37) goes through the weapon path's own
  modifiers, as the rap term already does inside `Spell::EffectWeaponDmg`: the ranged weapon total percent
  (`UNIT_MOD_DAMAGE_RANGED`, `TOTAL_PCT`), then the marginal share of `MeleeDamageBonusDone` and of
  `MeleeDamageBonusTaken` (`f(2x) - f(x)`, since both return 0 for a zero amount; the stock flat of 30 the mark
  already adds is not counted twice). School-damage rows keep the spell-path shares.
- The stock flat `int32(150 / 14 x 2.8) = 30` stays; the weapon part ($s1%) is not touched.
- Regression `804068 behaviour_hit_ratio ap_ranged_weapon` now expects 1.2407: per shot at the reference ranged attack
  power 237, 39 + 47.4 + 133 + 59 = 278.4 without the mark, 278.4 + 30 + 37 = 345.4 with it (1.1078 before, the flat
  alone).

All 41 WitchCoefficients rows with `rap > 0` (`AscensionWitchHunterCoefficients.h`), checked against the server
Spell.dbc Description (`/srv/coa/server-data/dbc`; the parent card where the row's own text has no formula):

| Row | Effect | Tooltip read | RAP term in the tooltip | Included |
|---|---|---|---|---|
| Boltslinger 500159 e0 | 2 SCHOOL_DAMAGE | 92091 (parent card) | `$RAP*0.2` | yes |
| Track 500181 e2 | 2 SCHOOL_DAMAGE | 500181 | none (`${$m3+$ppl3}`) | no |
| Feast of Talons 500564 e0 | 6 APPLY_AURA 3 | 500564 | `$RAP*.13` | yes |
| Tormentor 501344 e0 | 6 APPLY_AURA 3 | 501344 | `$RAP*.295` | yes |
| Tormentor 501345 e0 | 6 APPLY_AURA 3 | 501345 | `$RAP*.295` | yes |
| Tormentor 501346 e0 | 6 APPLY_AURA 3 | 501346 | `$RAP*.295` | yes |
| Tormentor 501347 e0 | 6 APPLY_AURA 3 | 501347 | `$RAP*.295` | yes |
| Tormentor 501348 e0 | 6 APPLY_AURA 3 | 501348 | `$RAP*.295` | yes |
| Tormentor 501349 e0 | 6 APPLY_AURA 3 | 501349 | `$RAP*.295` | yes |
| Tormentor 501350 e0 | 6 APPLY_AURA 3 | 501350 | `$RAP*.295` | yes |
| Tormentor 501351 e0 | 6 APPLY_AURA 3 | 501351 | `$RAP*.295` | yes |
| Tormentor 501352 e0 | 6 APPLY_AURA 3 | 501352 | `$RAP*.295` | yes |
| Tormentor 501353 e0 | 6 APPLY_AURA 3 | 501353 | `$RAP*.295` | yes |
| Tormentor 501354 e0 | 6 APPLY_AURA 3 | 501354 | `$RAP*.295` | yes |
| Tormentor 501355 e0 | 6 APPLY_AURA 3 | 501355 | `$RAP*.295` | yes |
| Caltrops 504447 e0 | 2 SCHOOL_DAMAGE | 503679 (parent card) | `$RAP*.25` | yes |
| Witchbane 520211 e0 | 6 APPLY_AURA 227 | 520211 | `$RAP*0.15` | yes |
| Witchbane 520212 e0 | 6 APPLY_AURA 227 | 520212 | `$RAP*0.15` | yes |
| Witchbane 520213 e0 | 6 APPLY_AURA 227 | 520213 | `$RAP*0.15` | yes |
| Witchbane 574319 e0 | 6 APPLY_AURA 227 | 574319 | `$RAP*0.15` | yes |
| Witchbane 574320 e0 | 6 APPLY_AURA 227 | 574320 | `$RAP*0.15` | yes |
| Witchbane 578297 e0 | 6 APPLY_AURA 227 | 578297 | `$RAP*0.15` | yes |
| Tormentor 800162 e0 | 6 APPLY_AURA 3 | 800162 | `$RAP*.295` | yes |
| Witchbane 800165 e0 | 6 APPLY_AURA 227 | 800165 | `$RAP*0.15` | yes |
| Shadow Claw 800697 e0 | 6 APPLY_AURA 3 | 800697 | none (`${$m1+$ppl1}`) | no |
| Quickdraw 804193 e1 | 2 SCHOOL_DAMAGE | 804193 | `$RAP*0.2` | yes |
| Twilight Frenzy 805753 e0 | 2 SCHOOL_DAMAGE | 805751 (parent card) | `$RAP*.1` | yes |
| Heartseeking Bolt 805754 e0 | 2 SCHOOL_DAMAGE | 805754 | `$RAP*0.5` | yes |
| Quickdraw 806846 e1 | 2 SCHOOL_DAMAGE | 806846 | `$RAP*0.2` | yes |
| Quickdraw 806847 e1 | 2 SCHOOL_DAMAGE | 806847 | `$RAP*0.2` | yes |
| Quickdraw 806848 e1 | 2 SCHOOL_DAMAGE | 806848 | `$RAP*0.2` | yes |
| Quickdraw 806849 e1 | 2 SCHOOL_DAMAGE | 806849 | `$RAP*0.2` | yes |
| Quickdraw 806850 e1 | 2 SCHOOL_DAMAGE | 806850 | `$RAP*0.2` | yes |
| Quickdraw 806851 e1 | 2 SCHOOL_DAMAGE | 806851 | `$RAP*0.2` | yes |
| Heartseeking Bolt 807279 e0 | 2 SCHOOL_DAMAGE | 807279 | `$RAP*0.4` | yes |
| Heartseeking Bolt 807280 e0 | 2 SCHOOL_DAMAGE | 807280 | `$RAP*0.4` | yes |
| Heartseeking Bolt 807281 e0 | 2 SCHOOL_DAMAGE | 807281 | `$RAP*0.4` | yes |
| Heartseeking Bolt 807282 e0 | 2 SCHOOL_DAMAGE | 807282 | `$RAP*0.4` | yes |
| Heartseeking Bolt 807283 e0 | 2 SCHOOL_DAMAGE | 807283 | `$RAP*0.4` | yes |
| Heartseeking Bolt 807284 e0 | 2 SCHOOL_DAMAGE | 807284 | `$RAP*0.4` | yes |
| Sixfold Shot 807527 e1 | 121 NORMALIZED_WEAPON_DMG | 807527 | `$RAP*0.25` | yes |

39 rows included, 2 left out (no RAP term).

## Amendment 2: modifier path of the Sixfold row (mentor D-374)

The row's existing caster term (RAP x c.rap) enters 807527 Effect[1] through the effect base value
(AscensionWitchHunterCompletion.cpp:543-556, `ModifySpellEffectBaseValue`). For a NORMALIZED_WEAPON_DMG effect that value is
the spell's `fixed_bonus` (SpellEffects.cpp:4677), scaled by the ranged TOTAL_PCT weapon modifier (:4706) and added to the
weapon damage (:4740) before the melee damage bonus done/taken of the hit. The debuff term takes the same path: ranged
TOTAL_PCT, then the marginal MeleeDamageBonusDone/Taken shares. Same path as built; nothing moves.

## Owner ruling (O-35, 2026-11-17)

The owner validated this change as built (owner ruling O-35, relayed by mentor D-390). It replaces the earlier
"mentor ruling, no owner id" status of this decision.
