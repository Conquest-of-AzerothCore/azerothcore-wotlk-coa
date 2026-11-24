# 0005. Cruelty keeps its DBC points against Demons

- Status: accepted (mentor D-36, 2026-11-23)
- Date: 2026-11-23

## Context

Cruelty rank 2 520249 (server Spell.dbc, Description[enUS]): "Increases your critical strike chance by $s1% and an
additional $s2% against Demons." Rank 1 705109 carries the same sentence.

Server DBC set, Effect[1] of each rank (Effect[0] of both is aura 290 `SPELL_AURA_MOD_CRIT_PCT`, BasePoints 1 and 3,
DieSides 1: +2 and +4):

| Id | Aura | MiscValue | MiscValueB | BasePoints (DieSides 1) | `$s2` |
|---|---|---|---|---|---|
| 705109 | 169 `SPELL_AURA_MOD_CRIT_PERCENT_VERSUS` | 4 | 0 | 2 | 3 |
| 520249 | 112 `SPELL_AURA_OVERRIDE_CLASS_SCRIPTS` | 20008 | 4 | 5 | 6 |

Neither Effect[1] works as the DBC gives it: the stock engine reads aura 169 as critical damage, and selector 20008
has no aura 112 handler. `AscensionFelswornContracts.cpp` (since `46bf8121e5`) therefore moves Effect[1] of both
ranks to aura 112 with selector `ASCENSION_CREATURE_GLOBAL_CRIT` and MiscValueB 4 (Demon), which
`Unit::GetAscensionConditionalCombatModifier` adds to the critical strike chance against a Demon. The same block also
wrote `BasePoints = id == 705109 ? 2 : 4`: the DBC value for rank 1, and 4 over the DBC 5 for rank 2. No commit
message or document gives a reason for the 4.

Conformance pair C (2026-11-23, server `59f001ac20fb`, Spell.dbc `d3dd6072`) read 520249 at +9 against an Imp
(expected 10: 4 + 6) in both runs, with the non-Demon control at +4 and the general control at +4: rank 2 gave 5
against Demons where its tooltip says 6. The bindmysoul and coabuildhub snapshots render rank 1 as 2% and 3%, equal
to the DBC; neither lists rank 2. The Ascension logs hold no event for either passive.

## Options

- Delete the BasePoints line only: both ranks keep the aura and selector move and their own DBC base points.
- Delete the whole block and let the older rules of `AscensionConditionalCombatData.h` do the move. Rejected for this
  fix: it makes a class fix depend on a shared table and its BasePoints guards.

## Decision

Delete the BasePoints line, keyed to 705109 and 520249, the two ranks of Cruelty (SpellFamilyName 20). No shared
file changes.

## Consequences

- 520249: +4 critical strike chance against every target and +6 more against Demons (+10 against a Demon).
- 705109: unchanged, +2 and +3 more against Demons; the deleted write gave it its own DBC value.
- Other readers of `ASCENSION_CREATURE_GLOBAL_CRIT` (Felsworn 704607, the Necromancer and Xoroth contracts, the
  table rules of other classes) are not touched: only the base points of 520249 change.
- Regressions: the `metric_delta` entries `520249 crit_demon` (+10 against Imp 416) with the controls
  `520249 crit_other_type` (+4 against the stock dummy) and `520249 crit_all` (+4), and the rank 1 guard
  `705109 crit_demon` (+5) and `705109 crit_other_type` (+2). Each reads the computed chance
  (`Unit::GetUnitCriticalChance`), not a roll, so no residual chance of a false result.
- No client text change: the tooltip already shows 6.

## Observation

`AscensionConditionalCombatData.h` keeps rules for 520249 (aura 112, selector 20008 to 21003, condition 4, guard
BasePoints 5) and 705109 (aura 169, selector 4 to 21003, condition 4, guard BasePoints 2). They are dead while the
Felsworn contracts run first: by then 520249's selector and 705109's aura no longer match the rules' old values, so
`ApplyAscensionConditionalCombatContracts` skips both. Removing either copy is a cleanup outside this fix.
