# 0022. Bane of Chaos ticks can critically strike

- Status: accepted (Felsworn mentor decision D-82, 2026-11-24)
- Date: 2026-11-24

## Context

Bane of Chaos 706420 (Rank 7), server Spell.dbc Description[enUS]: "@ext:Periodic damage dealt by this effect can
critically strike.:ext@". Its Effect[0] is SPELL_AURA_PERIODIC_DAMAGE (3000 ms, 21000 ms), SchoolMask 127 (Chaos),
DmgClass 1 (MAGIC). The archived live logs show its ticks critical: `coa-history spell 706420` reads 682 critical of
1563 SPELL_PERIODIC_DAMAGE events in 2 logs. On our server no tick was critical: under a forced spell crit rating,
0 of 7 ticks in both runs of the Felsworn B9 pair, while a direct Fel Fireball 801312 under the same forcing crit.
Stock `AuraEffect::CalcPeriodicCritChance` (SpellAuraEffects.cpp:1180-1209) gives a periodic aura a crit chance only
when the caster holds a SPELL_AURA_ABILITY_PERIODIC_CRIT aura affecting it, and no Felsworn code set one.

## Decision

`felsworn_scaling::OnAuraApply` (`AscensionFelswornContracts.cpp`, UnitScript::OnAuraApply, called on a new aura and
on a refresh) sets the crit chance of Effect[0] of a Bane of Chaos 706420 aura to the caster's stock spell crit chance
for the aura's school against the target: `SpellDoneCritChance(nullptr, info, school, BASE_ATTACK, true)`, then
`SpellTakenCritChance` when above 0, clamped at 0. It is the shape of Necromancer
[ADR 0012](../necromancer/0012-flesh-to-worms-ticks-can-critically-strike.md), in Felsworn code, keyed to the one id
the decision names; `CalcPeriodicCritChance` is untouched. A critical tick takes the engine's spell critical bonus
(`Unit::SpellCriticalDamageBonus`, DmgClass MAGIC: +50% before crit damage auras).

## Consequences

- Bane of Chaos 706420 ticks roll crits at the chance a direct spell of SchoolMask 127 gets. That mask holds
  Physical, so `Unit::SpellDoneCritChance` gives it a base of 0 (Unit.cpp, MAGIC branch): the spell crit rating does
  not reach it, while SPELL_AURA_ASCENSION_MOD_CRIT_CHANCE (350), SPELLMOD_CRITICAL_CHANCE and the taken-side terms
  do. The engine behaviour is unchanged here and is reported as an observation.
- Ranks 704368 and 706415 to 706419 carry the same sentence and are not changed by this decision.
- Crit procs that accept periodic crits can now fire on Bane of Chaos ticks: Oblivion 572889 (`crit`), Bane of Power
  707902 charges (not on the same target: one Bane per target), and procs outside the class with a critical hit mask
  and periodic proc flags. Malice of Gul'dan 800214 (`crit && !periodic`) and Sculptor of Doom 801235 (`Direct`) do
  not.
- Regressions (`felsworn.json`), with Fel Infusion 560533 Effect[1] (aura 350, MiscValue 127) as the chance fixture:
  706420 `periodic_crit_forced` (critical share at amounts -100 and 100: 0 against 100), `periodic_crit_normal`
  (amounts 0 and 90: 90 points apart, the roll at the stock chance, neither 0 nor 100), `periodic_crit_damage`
  (amounts -100 and 100: mean tick ratio 1.5), and 800214 `periodic_crit_no_felstrike` (amounts -100 and 100 with
  Malice of Gul'dan learned: no Felstrike 802678 in either arm).
- At amount 0 the reference character's ticks crit a little (1 of 42 in an exploratory run): it holds a Chaos crit
  chance of its own whose source was not traced. The forced and damage entries clamp it with the -100 control.
