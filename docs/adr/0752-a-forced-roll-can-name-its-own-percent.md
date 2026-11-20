# 0752. A forced roll can name its own percent

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim "Can only occur once every 5 sec." (Expert Killer 804404, ledger 366.0) is judged by the timing
pair `804404 behaviour_metric_delta icd_hold` and `icd_reopen`: 30 Tormentor 800162 casts at one fixed gap (4875 ms,
5100 ms) count the Slinging Bolts 500161 casts. The `forced_roll` option forces the proc with a fixed
SPELLMOD_CHANCE_OF_SUCCESS +1000% mutant (ADR 0588), and the server applies it as a percent modifier
(`SPELLMOD_PCT`, CoAGameplayTest.cpp `AddSpellModMutant`; `Aura::CalcProcChance`, SpellAuras.cpp:2383): 804404's
8% becomes 88%, so the event counts are binomial and both arms carry a residual (4e-7 per run at 88%). The c13
Boltslinger author found that only a forced percent of 1150 or more reaches 100% and that no entry could ask for it.
Mentor decision D-211 (c14 tool batch item 16).

## Options

- A per-entry `forced_percent` in the dict form of `forced_roll`, default the current +1000%.
- Raising `FORCED_CHANCE_PERCENT` for every entry: changes the scenarios of every forced roll, Templar and Necromancer
  included (D-195).
- Sizing more casts per arm: the binomial tail only shrinks, and every cast lengthens the scenario.

## Decision

The first option. `forced_roll` takes `{"talent": ID, "forced_percent": P}` (with or without `release_after_setup`),
P a whole percent in (0, 10000]; the mutant, the contract sentence and the model name P. Without it the mutant stays
+1000% and the model and scenario are byte-identical. The `cost_gate` and `internal_cooldown_gate`
forced rolls, `forced_chance` and the forcing kinds (`aura_expiry`, `spawn_fuse`, `summon_lifetime`, `summon_chase`)
keep the fixed +1000% (no user needs another percent).

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`); a seeded test
  checks that neither finished class file names a percent.
- The runner's `spell_mod_mutant` cap (`run.MAX_MUTANT_PERCENT`, README) rises from 1000 to 10000, since the
  server accepts any percent of at least -100 (CoAGameplayTest.cpp `AddSpellModMutant`); its runner test follows.
- Seeded tests: the entry percent reaches the mutant, the contract and the model; without it the default 1000 stays
  and the int and dict forms generate the same scenario; zero, negative, fractional, boolean, string and over-cap
  percents are refused. No new judge check, so no mutant test.
- Witch Hunter: `icd_hold` and `icd_reopen` force 804404 with 1200 (8% x 13 = 104%): a 5000 ms cooldown gives exactly
  15 events at 4875 ms and 30 at 5100 ms, so the false alert and the false pass against a 4500 or 5500 ms cooldown
  are 0; the bounds (at most 15, at least 16) are unchanged.
