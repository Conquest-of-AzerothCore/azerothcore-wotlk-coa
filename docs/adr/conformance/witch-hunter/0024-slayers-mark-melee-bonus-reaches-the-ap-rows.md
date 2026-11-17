# 0024. Slayer's Mark's melee attacker bonus reaches the WitchCoefficients ap rows

- Status: accepted, amended 2026-11-17 (the two leech rows, see Amendment)
- Date: 2026-11-17

## Context

Slayer's Mark 804068 reads (server Spell.dbc Description): "Mark an enemy, increasing the attack power of all attackers
against that target by 150 ...". Clause 351.1, melee side; the ranged side is
[Witch Hunter ADR 0021](0021-slayers-mark-ranged-bonus-reaches-the-rap-rows.md) (owner ruling O-35). The 150 is
SPELL_AURA_MELEE_ATTACK_POWER_ATTACKER_BONUS on the marked enemy (Slayer's Mark Periodic 804073, rewritten by
`AscensionWitchHunterCompletion.cpp`).

The fu-melee measurement (worldserver 34a52c596dcb, server commit 24dd54b44e; reference attack power 282, spell power 0,
level 60, 0% crit; control arm = the same scenario without the mark) read a gain of 0 on every c.ap family while the
stock white swing gained +34.9% / +34.3% against +35.55%:

| Family / label | Expected | Run A | Run B |
|---|---|---|---|
| Direct: Bola Throw 500093 e1 `ap_melee_bola` | +45.05% | -0.28% | +0.08% |
| Aura 3: Witchblood Fever 684330 `ap_melee_dot` (8 ticks) | 1246.7 | 1128 | 1128 |
| Aura 227: Darkflock 520270 -> 520271 `ap_melee_trigger` | +29.4% | +0.65% | -0.94% |
| School part of Dawn Blade 574342 e0 `ap_melee_weapon` | +21.3% | +10.83% | +7.61% (stock flat alone) |

Pairs 20261117-062439 / -062524 and 20261117-062655 / -062724. Cause, as for the ranged twin: every WitchCoefficients
row has its effect's BonusMultiplier at 0, so the stock attack power term of `Unit::SpellDamageBonusDone`, which reads
the victim's attacker bonus, adds nothing, and `witch_hunter_scaling::ModifySpellEffectBaseValue` adds
`attack power x c.ap` from the caster alone. The ADR 0021 routes read only the ranged aura, through rows with
`c.rap > 0`; no c.ap row has one.

Mentor D-403 approved the fix note (fu-nmelee) with these rules: the 40 c.ap rows whose tooltip has an explicit AP term
and whose effect is an attack on the target; the ADR 0021 routes; WH code only, no SQL, no engine file; the heal and
absorb rows left out; the two leech rows left out as a known remainder; on area rows the added term takes the same
treatment as the row's existing caster attack power term (D-374 principle).

## Options

- `spell_script_names` rows and a hit hook per spell: needs SQL (excluded, D-362).
- A victim argument on `ModifySpellEffectBaseValue`: a shared engine hook.
- `UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN`: no effect index, after the done and taken percent modifiers (rejected in ADR
  0021); it would be the only route for the leech rows.
- The three ADR 0021 routes, made aura-aware (chosen).

## Decision

`AscensionWitchHunter::VictimRangedAttackerBonus` becomes `VictimAttackerBonus`: for the row of (spell, effect) it
returns `uint32(ranged bonus x c.rap)` (unchanged, minus Track 500181 and Shadow Claw 800697) plus
`uint32(melee bonus x c.ap)`, the melee bonus being the victim's total SPELL_AURA_MELEE_ATTACK_POWER_ATTACKER_BONUS,
minus the five rows left out below. No row has both coefficients, so every ranged row reads as before. The term goes
through the existing routes:

1. Direct rows (SCHOOL_DAMAGE): `witch_hunter_casts::OnSpellCalculatedTarget`, through the spell's done and taken
   shares, before the class's percent multipliers; armor and the critical doubling then apply as to the rest of the
   hit.
2. Periodic damage rows (aura 3): `OnAfterAuraEffectCalculateAmount`, added to the amount at the snapshot with the
   aura's percent modifiers. The tick path then applies the taken modifiers and, for an area aura, the stock
   `CalculateAOEDamageReduction` (`SpellAuraEffects.cpp`, periodic damage tick) to the whole amount, the term included.
3. Periodic trigger rows (aura 227, the five Darkflock ranks): route 1 on the triggered shot 520271, matched through
   `GetTriggeredByAuraSpellInfo()` (Effect[0] TriggerSpell 520271), read at each shot with the rank's row.

Area treatment of route 1 (D-374): the term was added after `Spell::DoAllEffectOnLaunchTarget`'s area step. For an
effect that stock treats as area (`IsAreaAuraEffect`, `IsTargetingArea`, or a non-magic chain above 1 target), the
taken share of the term now takes `CalculateAOEDamageReduction` with stock's npc-caster rule
(SPELL_ATTR7_TREAT_AS_NPC_AOE included) and, for a player caster, the more-than-10-targets cap
`x 10 / unique targets`; the done share (`damageBeforeTakenMods`) is not reduced, as in stock. Ten included direct rows
are area effects (Shadowstorm, six Witchblight ranks, Scourge Trap, Dark Peril, Darkslayer's Lantern), and the
Darkflock shot 520271 is a cone (TargetA 54). The chain damage multipliers of stock are not repeated: no included row
has an EffectChainTarget above 1. No ranged row of ADR 0021 is an area or chain effect, so the step leaves them as
they were.

All 45 WitchCoefficients rows with `ap > 0` (`AscensionWitchHunterCoefficients.h`), checked against the server Spell.dbc
Description (`/srv/coa/server-data/dbc`; the parent card where the row's own text has no formula; for Darkflock the
client text the player sees):

| Row | Effect (DBC) | Tooltip read | AP term in the tooltip | c.ap | Included | Route / reason |
|---|---|---|---|---|---|---|
| Bola Throw 500093 e1 | 2 SCHOOL_DAMAGE | 500093 | `$AP*.3` | .30 | yes | 1 |
| Bola Throw 501337 e1 | 2 | 501337 | `$AP*.3` | .30 | yes | 1 |
| Bola Throw 501338 e1 | 2 | 501338 | `$AP*.3` | .30 | yes | 1 |
| Bola Throw 501339 e1 | 2 | 501339 | `$AP*.3` | .30 | yes | 1 |
| Bola Throw 501340 e1 | 2 | 501340 | `$AP*.3` | .30 | yes | 1 |
| Bola Throw 501341 e1 | 2 | 501341 | `$AP*.3` | .30 | yes | 1 |
| Bola Throw 501342 e1 | 2 | 501342 | `$AP*.3` | .30 | yes | 1 |
| Bola Throw 501343 e1 | 2 | 501343 | `$AP*.3` | .30 | yes | 1 |
| Vicious Mockery 501383 e0 | 2 | 802013 (parent) | `$AP*0.35` | .35 | yes | 1 |
| Darkflock 520270 e0 | 6 APPLY_AURA 227 -> 520271 | client text (override) | `$AP*.35` (Spell.dbc `$AP*.25`) | .35 | yes | 3 (cone) |
| Darkflock 520708 e0 | 6 / 227 -> 520271 | client text (override) | `$AP*.35` | .35 | yes | 3 (cone) |
| Darkflock 520709 e0 | 6 / 227 -> 520271 | client text (override) | `$AP*.35` | .35 | yes | 3 (cone) |
| Darkflock 562024 e0 | 6 / 227 -> 520271 | client text (override) | `$AP*.35` | .35 | yes | 3 (cone) |
| Darkflock 562025 e0 | 6 / 227 -> 520271 | client text (override) | `$AP*.35` | .35 | yes | 3 (cone) |
| Shadowstorm 520278 e0 | 2, area | 520278 | `$AP*.1` | .10 | yes | 1 (area) |
| Dawn Blade 574342 e0 | 2 (school part) | 574342 | `$AP*0.15` | .15 | yes | 1 |
| Dawn Blade 574343 e0 | 2 (school part) | 574343 | `$AP*0.15` | .15 | yes | 1 |
| Grasp of the Undying 680483 e0 | 9 HEALTH_LEECH | 707064 / 707860 (parents) | `$AP*.1` | .10 | **no** | known remainder (leech) |
| Witchblight 680494 e0 | 2, area | 680494 | `$AP*.2` | .20 | yes | 1 (area) |
| Knight's Seal 680499 e0 | 6 APPLY_AURA 3 | 680498 (parent) | `$AP*.146` | .146 | yes | 2 |
| Desecrate 680519 e1 | 10 HEAL, self | 680519 | `$AP*0.1` | .10 | **no** | heal, not an attack on the target |
| Chains of Darkness 680522 e1 | 2 | 680521 (parent) | `$AP*.15` | .15 | yes | 1 |
| Noctis Protection 681099 e0 | 6 APPLY_AURA 69 (absorb), self | 681100 (parent) | `$AP*.1` | .10 | **no** | absorb, not an attack on the target |
| Shadow Trapped 681177 e0 | 6 APPLY_AURA 3, area | 680238 / 680376 (Shadow Trap) | `$AP*0.34` | .34 | yes | 2 (area tick) |
| Witchblight 681218 e0 | 2, area | 681218 | `$AP*.2` | .20 | yes | 1 (area) |
| Witchblight 681219 e0 | 2, area | 681219 | `$AP*.2` | .20 | yes | 1 (area) |
| Witchblight 681220 e0 | 2, area | 681220 | `$AP*.2` | .20 | yes | 1 (area) |
| Witchblight 681221 e0 | 2, area | 681221 | `$AP*.2` | .20 | yes | 1 (area) |
| Death Trap 681452 e0 | 6 APPLY_AURA 3, area | 681450 / 681454 / 681563 | `$AP*1` | 1.0 | yes | 2 (area tick) |
| Scourge Trap 681457 e0 | 2, area | 681455 / 681564 | `$AP*1` | 1.0 | yes | 1 (area) |
| Witchblight 681540 e0 | 2, area | 681540 | `$AP*.2` | .20 | yes | 1 (area) |
| Witchblood Fever 684330 e0 | 6 APPLY_AURA 3, area | 684330 | `$AP*.12` | .12 | yes | 2 (area tick) |
| Dark Peril 685020 e1 | 2, area | 685020 | `$AP*.24` | .24 | yes | 1 (area) |
| Vampiric Rage 686020 e0 | 9 HEALTH_LEECH, area | 686020 | `$AP*0.28` | .28 | **no** | known remainder (leech) |
| Dawn Blade 802024 e0 | 2 (school part) | 802024 | `$AP*0.15` | .15 | yes | 1 |
| Gaze of the Black Knight 802138 e2 | 6 APPLY_AURA 69 (absorb), self | 802138 | `$AP*.41` | .41 | **no** | absorb, not an attack on the target |
| Darkslayer's Lantern 802139 e0 | 2, area | 802139 | `$AP*.15` | .15 | yes | 1 (area) |
| Dawn Blade 802248 e0 | 2 (school part) | 802248 | `$AP*0.15` | .15 | yes | 1 |
| Dawn Blade 802249 e0 | 2 (school part) | 802249 | `$AP*0.15` | .15 | yes | 1 |
| Dawn Blade 802250 e0 | 2 (school part) | 802250 | `$AP*0.15` | .15 | yes | 1 |
| Dawn Blade 802251 e0 | 2 (school part) | 802251 | `$AP*0.15` | .15 | yes | 1 |
| Dawn Blade 802252 e0 | 2 (school part) | 802252 | `$AP*0.15` | .15 | yes | 1 |
| Burrow Bolt 802269 e0 | 2 | 802269 | `$AP*.25` | .25 | yes | 1 |
| Purified Bola Throw 803333 e1 | 2 | 803333 | `$AP*.4` | .40 | yes | 1 |
| Brand of the Damned 807683 e0 | 2 | 807682 (parent) | `$AP*1` | 1.0 | yes | 1 |

45 rows: 40 included (31 by route 1, ten of them area rows; 4 by route 2, three of them area auras; 5 by route 3),
3 left out as not an attack on the target (stock reads the attacker bonus only in `SpellDamageBonusDone` and
`MeleeDamageBonusDone`, never in `SpellHealingBonusDone`), 2 left out as a known remainder. No row is left out for
lack of an AP term.

The Darkflock coefficient is the row's .35: server Spell.dbc text `$AP*.25`, client text override
`${$m1+0+$AP*.35+$SP*1.0625}` (`rev_20261029_40_witch_hunter_darkflock_anguish.sql`), rulings D-2 / O-4 (changelog
71840, cited through commit 783f87fc5d); the measured control follows .35.

Known remainder: Grasp of the Undying 680483 and Vampiric Rage 686020 are HEALTH_LEECH effects whose amount is computed
at hit (`EffectHealthLeech`), after `OnSpellCalculatedTarget` at launch, so route 1 never sees them. They take no mark
bonus. A route needs SQL (a spell script hook) or the damage-taken hook rejected in ADR 0021; neither is part of this
decision.

## Consequences

- Every source of SPELL_AURA_MELEE_ATTACK_POWER_ATTACKER_BONUS on a target now raises the 40 included rows of a Witch
  Hunter, as stock does for its own AP-coefficient spells. Only a Witch Hunter caster and the listed Witch Hunter spell
  ids are read; other classes' spells, the engine and the SQL are not touched.
- The term is truncated once (`uint32`), separately from the caster term, so a hit can differ by one point from a
  single combined truncation. On area rows the term takes the area reduction and the target cap like the rest of the
  hit; without an area avoidance aura on the target and with at most 10 targets the result is the same.
- Out of scope, observations: the caster's SPELL_AURA_MOD_MELEE_ATTACK_POWER_VERSUS is not added; the 10-target cap is
  not reachable by the six Witchblight ranks (MaxAffectedTargets 10).
- Regression in `classes/witch_hunter.json` (clause 351.1, melee claim), each with its control arm: `ap_melee_bola`
  (direct, Bola Throw 500093, 1.4505), `ap_melee_trigger` (aura 227, Darkflock 520271, 1.294; its read window is cut to
  5000 ms so that every judged shot falls under the 8000 ms mark), `ap_melee_weapon` (Dawn Blade 574342, stock flat
  plus the school row, 1.2134), `ap_melee_dot` against `ap_melee_dot_control` (aura 3, Witchblood Fever 684330, 1246.7
  against 1102.7), and the area row Witchblight 681220 on three dummies: `ap_melee_area` (the marked dummy, 216 to 232)
  and `ap_melee_area_unmarked` (a dummy struck by the same cast, not marked, 186 to 202) against
  `ap_melee_area_control` (no mark, 186 to 202). `ap_melee_swing` (stock white swing, 1.3555) stays the unchanged
  contrast; the ADR 0021 ranged labels are rerun as a guard. The area entries use the new opt-in metric_delta option
  `area_dummies` (more dummies beside the primary one, ADR 0995, standing approval O-29).
- Reference search (G-11): `~/CoaServer/reference` snapshots (sidekick, bindmysoul, ascension-data coabuildhub) hold only
  the tooltip text of 804068 and say nothing on whether the mark raises the Witch Hunter's own attack-power-scaled
  abilities. The fu-melee and fu-nmelee reports record no coa-history or guide-doc search for this claim; their only
  recorded search (the Darkflock changelog 71840, in `~/CoaServer/reference` and the guide docs) found nothing. Nothing
  found for the melee claim: the decision rests on the tooltip ("all attackers") and rulings O-35 / D-403.
- Fixture 984954 ("Reg's Test Aura") of the `ap_melee_area*` entries holds the spell crit chance at 0 through Effect[1]
  aura 57; its Effect[0] is aura 52 SPELL_AURA_MOD_WEAPON_CRIT_PERCENT (BasePoints 100, MiscValue 127), with no effect
  here: Witchblight 681220 is DmgClass 1 (magic).

## Amendment (2026-11-17): the two leech rows leave the known remainder

Owner order O-42 and mentor D-441 / D-442 / D-443 authorize SQL for Grasp of the Undying 680483 e0 and Vampiric Rage
686020 e0 only. The original text above is kept as the record of the first decision; this section replaces its
"Known remainder" paragraph and the "**no** | known remainder (leech)" rows of the table. With it the table counts 42
included rows and 3 left out (heal and absorbs).

Change:

- `ApRowsWithoutAnAttackOnTheMarkedTarget` (`AscensionWitchHunterCompletion.cpp`) drops 680483 and 686020. The
  three existing routes still never reach them: route 1 matches only SCHOOL_DAMAGE and NORMALIZED_WEAPON_DMG
  (`CarriesAttackerBonus`) and returns on a zero launch damage, route 2 reads only aura 3, route 3 only aura 227.
- Route 4, the leech hit: `spell_ascension_witch_hunter_ability` gets an `OnEffectHitTarget` handler (`LeechMark`,
  `AscensionWitchHunterAbilities.cpp`), registered on `SPELL_EFFECT_ANY` so that its 236 other bound spells log no
  validation error, and acting only on a HEALTH_LEECH effect of a Witch Hunter caster. It adds
  `VictimAttackerBonus(hit unit, spell, effect)` to the effect value through the marginal share of
  `ApplyEffectModifiers` (the step the caster term takes in `SpellEffectInfo::CalcValue`). Among the WitchCoefficients
  rows only 680483 e0 and 686020 e0 are HEALTH_LEECH effects (server Spell.dbc), and among the 236 spells bound to the
  script only 686020 has one, so the handler reaches these two rows and no other.
- SQL: one row, `data/sql/updates/pending_db_world/rev_20261117_03_witch_hunter_grasp_leech_mark.sql`, binds 680483 to
  `spell_ascension_witch_hunter_ability` (686020 was already bound by `rev_20261021_40`). Binding to the existing script
  is the smaller diff (no new script class, no second handler). Its other handlers leave a proc cast of 680483 unchanged:
  680483 has SpellFamilyFlags 64 / 0 / 0, which matches none of the family tests of `Before`, `BeforeHitTarget` and
  `Hit` (only the hit count `_hits` moves), `Launch` acts only on TRIGGER_SPELL_WITH_VALUE, and `After` returns for a
  triggered cast, which every in-game cast is (the 707064 / 707860 proc, `AscensionWitchHunterEvents.cpp`). A direct,
  untriggered cast (the harness's) now runs `After`'s Quickdraw step: it removes 680244 after the cast, as for every
  other Quickdraw spell.

D-374 proof (the added term takes the modifiers of the existing AP term), by code path for a HEALTH_LEECH hit:

1. `Spell::HandleEffects` (`Spell.cpp:5788`) builds `damage = CalculateSpellDamage(i, nullptr)`, that is
   `SpellEffectInfo::CalcValue`: the caster term `AP x c.ap` enters through `ModifySpellEffectBaseValue`
   (`SpellInfo.cpp:523`), then `ApplyEffectModifiers` (`SpellInfo.cpp:531`, SPELLMOD_ALL_EFFECTS / EFFECT1).
2. `CallScriptEffectHandlers` (`Spell.cpp:5790`) runs `LeechMark`: the mark term, passed through the same
   `ApplyEffectModifiers` by its marginal share, is added to `damage` (`SetEffectValue`, `SpellScript.cpp:614-621`).
3. `Spell::EffectHealthLeech` (`SpellEffects.cpp:2649`) passes the whole `damage` as `pdamage` to
   `Unit::SpellDamageBonusDone`, which computes `tmpDamage = (pdamage + DoneTotal) x DoneTotalMod` (`Unit.cpp:9936`) and
   applies SPELLMOD_DAMAGE to `tmpDamage` (`Unit.cpp:9939`). Both terms are inside `pdamage`, so the five SPELLMOD_DAMAGE
   percent modifiers that reach 686020 (300575, 301243, 504713, 680503, 681390) multiply the mark term exactly as they
   multiply the caster term. No branch of the function treats part of `pdamage` apart.
4. `SpellDamageBonusTaken` (`SpellEffects.cpp:2650`), then crit, resist, absorb, Wide Swings (680483) and the leech heal
   in `Spell::DoAllEffectOnTarget` act on the whole amount.

Neither term takes an area reduction or the 10-target cap: the leech amount is built at hit, after the launch area
step. No ranged term is opened: both rows have c.rap 0.

Regression (`classes/witch_hunter.json`, clause 351.1 melee claim), deterministic at attack power 282, spell power 0:
`ap_melee_leech` (Grasp, marked, 62 to 63) against `ap_melee_leech_control` (47 to 48); `ap_melee_leech_area` (Vampiric
Rage, marked dummy, 399 to 400) and `ap_melee_leech_area_unmarked` (area1 of the same cast, 357 to 358) against
`ap_melee_leech_area_control` (357 to 358); `ap_melee_leech_area_talent` (marked, with Shadow Order 680503, SPELLMOD_DAMAGE
+20%: (357 + 42) x 1.2 = 478.8, 478 to 480; a term that skipped the modifier would read 470). The leech heal rows are not
read here.
