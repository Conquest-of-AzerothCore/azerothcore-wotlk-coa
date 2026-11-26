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

## Amendment: owner ruling Felsworn O-35 (2026-11-24)

The owner ruled (Felsworn O-35 (2026-11-24), night question N-8) that under Inner Demon Bane of Chaos 706420 deals its extra damage every 6
seconds, the tooltip's `every $t2 sec` (EffectAmplitude[1] 6000 ms), and that the 2000 ms tuning is removed.

- `ApplyContracts` (`AscensionFelswornContracts.cpp`, block `Named(info, 704368)`) still turns the Ragefire 803717
  trigger effect of every Bane of Chaos rank into a periodic dummy, which the class aura script resolves into Chaos
  802676 while Inner Demon is on, but now keeps the effect's own EffectAmplitude instead of 2000 ms. Every rank,
  704368 and 706415 to 706420, carries 6000 ms there in the server DBC set, so every rank changes from 2 s to 6 s.
  The 2000 ms line came with 46bf8121e5 (2026-09-09) with no stated basis.
- Archived live evidence for ranks 1 to 6 (night question N-8, live check of 2026-11-24, read-only, coa-history): the
  Inner Demon hit Chaos 802676 under ranks 1 to 6 sits near 6 s, interval medians 5.87 to 5.95 s; rank 7 (706420)
  reads a broad spread (1275 intervals, median 2.31 s, one window of 107 hits at a 2.005 s median), which the ruling
  settles for the tooltip's 6 s. The ranks share one contract line and one data shape, so the ruling moves all seven.
- Measured before (Felsworn B2 pair, fw-vb2 report, review fw-rvb2 I-5): a Chaos hit every 2 s (3 hits by 6.6 s,
  2 by 5.4 s). The damage per hit and its spell power term are unchanged by this amendment.
- Re-read of the part 225.0 proof (Malice of Gul'dan 800214, `periodic_crit_no_felstrike`) against the change: that
  entry counts critical ticks of Effect[0] (SPELL_AURA_PERIODIC_DAMAGE, EffectAmplitude 3000 ms), which this
  amendment does not touch, and sets no Inner Demon 804216, so no Chaos 802676 hit occurs in it at either interval.
  Its 0 Felstrike over the critical ticks stands; the decision above (periodic crit chance of Effect[0]) is unchanged.
- Regressions: the existing interval entries of 706420 (`inner_interval_a`, none by 5.4 s; `inner_interval_b`, one by
  6.6 s) and the damage entries (`inner_damage`, `inner_damage_sp`, one hit inside their 6.5 s read) judge the 6 s
  interval; `inner_none` stays the control without Inner Demon.
