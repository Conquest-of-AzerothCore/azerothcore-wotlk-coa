# 1185. A proc trigger that lands no hit is judged on the hits it adds

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22
- Supplements [ADR 0684](0684-a-proc-trial-can-be-a-landed-hit-of-several-trigger-spells.md)

## Context

Radiant Flame 806060 deals no damage of its own: its Effect[0] aura 227 ticks every 1000 ms through 807058. The Sun
Cleric handler rolls Fire from the Heavens 300369 and Spears of Glory 804629 on each 807058 damage event
(`AscensionSunClericEvents.cpp:115`). With `trigger_spells` [806060, 807058] the scenarios read the 807058 ticks
(`<aura> proc trials spell_damage_count 807058`), but `compare.judge_proc` decided "no usable trial" on the trigger's
own hits, which are always zero, so every part was unmeasured: 804629 read 5692 events over 38314 ticks in 55 parts
(14.86%, indicative), and 300369 never counted. A direct 807058 trigger is refused as "not cast at an enemy"
(target type 77). Mentor D-48 and D-49.

## Options

- Judge the guard on every reading's trials for every entry: changes the verdict of any finished-class entry whose
  trigger hits read zero, without a statement that they must.
- Let a cast trigger name another spell as the trial spell: a second route next to `trigger_spells`, which already
  reads the added hits and their baseline.
- An opt-in `trigger_lands_no_hit` field on a `trigger_spells` entry.

## Decision

- A `trigger_spells` entry may set `trigger_lands_no_hit`, a source text that must cite the code line (`File.cpp:N`)
  where the handler rolls once per landed hit of the added spell. An entry whose handler rolls per cast or per aura
  application must not use it. Refused: no `trigger_spells`, or no code line in the text.
- The model carries `trigger_lands_no_hit: true`; the scenario contract adds the source and the rule text names the
  added spells as the trials. Steps are those of the `trigger_spells` entry.
- `compare.judge_proc`, flag set: a trial is one landed hit of an added spell, the baseline arm's hits of each taken
  out as before; the "no usable trial" guard reads the first reading's trials (trigger plus added) instead of the
  trigger's hits alone. Sizing and the residual are unchanged.
- False passes excluded: any landed hit of the trigger itself in a counted part alerts (hits the handler does not roll
  would inflate the trials and pull a too-high rate onto the tooltip); a baseline arm whose trials (trigger plus
  added) read zero is `insufficient_trials`, not a vacuous "no event"; a proc in the baseline arm alerts as before.

## Consequences

- Seeded tests in `test_procs.py` (`TriggerLandsNoHitCompareTest`): 15% over the added hits alone with the baseline
  taken out is ok, a seeded 20% mutant alerts, the unflagged entry stays unmeasured, a trigger hit alerts, an empty
  baseline is not judged, a baseline proc alerts. Scenario tests: the refused shapes, the flagged Witch Hunter entry
  generating the same steps as the unflagged one, and a Spears of Glory entry over Radiant Flame ticks.
- Entries without the field generate the same steps, model and contract: Templar, Necromancer and Witch Hunter stay
  byte-identical.
- 300369 and 804629 ride `trigger_spells` [806060, 807058] with the flag; the class file edit belongs to the Sun
  Cleric author.
