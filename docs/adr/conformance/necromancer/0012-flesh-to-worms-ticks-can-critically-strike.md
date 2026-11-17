# 0012. Flesh to Worms's ticks can critically strike

- Status: accepted
- Date: 2026-11-13

## Context

Every Flesh to Worms rank (500338, 501855-501861) carries "@ext:Periodic damage dealt by this can critically strike.:ext@"
in its server DBC Description (Spell.dbc of /srv/coa/server-data/dbc; no project SQL overrides the text). The live
combat logs of 2026-08-10 show 31 of 192 ticks critical; the sidekick snapshot carries the same sentence. On our
server no tick crits: with the caster's spell crit rating forced (FORCED_CRIT_RATING, harness player fixture), 0 of 12
ticks were critical (run 20261113-030439, entries periodic_crit and periodic_ticks, 12 ticks 1500 ms apart under
Mutation 500342), while a direct Lichfrost 501978 under the same forcing crit (direct_crit_control). Stock
`AuraEffect::CalcPeriodicCritChance` (SpellAuraEffects.cpp:1180-1209) gives a periodic aura a crit chance only when
the caster holds a SPELL_AURA_ABILITY_PERIODIC_CRIT aura affecting it. Fix note FN-c4-1, mentor-approved (G-37).

## Decision

`necromancer_scaling::OnAuraApply` (AscensionNecromancerContracts.cpp, UnitScript::OnAuraApply, called on a new aura
and on a refresh) sets the crit chance of Effect[0] of a Flesh to Worms aura, by explicit id (the eight ranks whose
own description carries the sentence), to the caster's spell crit chance for the aura's school against the target:
`SpellDoneCritChance(nullptr, info, school, BASE_ATTACK, true)`, then `SpellTakenCritChance` when above 0, clamped at
0. It is Necromancer code of the same shape as Blade of Faith's (ADR 0243), with no call into Templar or Venomancer
code; `CalcPeriodicCritChance` is untouched.

## Consequences

- Flesh to Worms ticks roll crits at the caster's spell crit chance; a crit uses the engine's spell crit bonus.
- Regression: periodic_crit (every one of the 12 ticks critical at forced crit), periodic_ticks (12 ticks in all),
  direct_crit_control (the forcing reaches a direct spell), with the no-cast control in each.
- Other "@ext" sentences of other spells are not changed here.
