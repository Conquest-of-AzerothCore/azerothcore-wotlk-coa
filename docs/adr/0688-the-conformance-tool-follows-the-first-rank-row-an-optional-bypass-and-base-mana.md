# 0688. The conformance tool follows the first rank's bonus row, an optional gate bypass and the base mana

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15
- Builds on: ADR 0679, ADR 0686

## Context

Three gaps of the conformance tool held Witch Hunter claims back (mentor D-82, approved under O-12):

1. Stake 680537 has a `spell_bonus_data` row (`ap_bonus` 0.675); its ranks 681347-681352 have none. The engine falls
   back to the row of the rank's first spell in its chain (`SpellMgr::GetSpellBonusData`, SpellMgr.cpp:1010-1016, via
   `GetFirstSpellInChain`), so the server adds 0.675 x AP to every rank. `bonus_data.bonus_terms` and
   `compare.modelled_bonus` looked up the rank's own row only, so r2-r7 read about 190 above the model and alerted.
2. `behaviours.cast_gate_spec` required `bypass_spell`, `bypass_name` and `bypass_quote`. Stake's "Only usable on
   enemies at or below 35% health." has no bypass of its own to cast.
3. Rank hit scenarios set the power before a cast only for a plain `ManaCost`. Stake costs 12% of base mana (206 at
   level 60); the 681350 `hit_mean` kept 34 usable hits of 333 casts (299 x SPELL_FAILED_NO_POWER).

## Options

- (1) Keep the own-row lookup and write ledger exceptions; or read the chain from `spell_ranks` SQL; or read the
  `SpellRank.dbc` chains, which `SpellMgr::LoadSpellRanks` loads first and lets win over the table
  (SpellMgr.cpp:1390-1400).
- (2) Give Stake an unrelated bypass spell; or make the three bypass fields optional together.
- (3) A harness step that fills the power to its maximum (harness C++, G-39); or a class-file `base_mana` read from the
  world data, set with the existing `set_power` step.

## Decision

- (1) `bonus_data.client_first_ranks(data, known_spells)` reads `SpellRank.dbc` (WDBC, four uint32 fields) as
  `SpellMgr::LoadClientSpellRankChains` keeps it: ranks in order from 1, every spell present in `Spell.dbc`, at least
  two ranks; each spell maps to the chain's rank-1 spell. `bonus_row(table, spell, first_rank)` returns the rank's own
  row, else the first rank's row. `bonus_terms` takes an optional `first_rank`; `compare.DbcTooltips.first_rank` reads
  the chains of its DBC set once (none when the file is absent). `BonusTerms.spell` records the read rank; an inherited
  row names "the first rank of <spell>" with SpellMgr.cpp:1010-1016 in the explanation and `first_rank_of` in
  `detail['bonus_data']`. Chains that exist only in `spell_ranks` or in talent ranks are not modelled (no fallback,
  the previous behaviour).
- (2) `CastGateSpec.bypass_*` default to `None`; `cast_gate_spec` refuses a partial set. Without a bypass the scenario
  runs the refused attempt at full health, the health fixture and the allowed attempt, and yields the `blocked` and
  `allowed` expectations only. With a bypass the scenario is unchanged.
- (3) `hits.base_mana_steps(class_file, facts)`: when the class file has `base_mana` and the rank's cost is a
  percentage of base mana (power 0), every cast of a rank hit scenario is preceded by `set_power` to `base_mana.value`;
  a cost (ManaCost + percentage of the recorded base mana) above it is refused. No harness C++ change. The Witch Hunter
  class file records 1720 (`player_class_stats` class 15 level 60 BaseMana, read in the test world databases;
  `CoA.ClassLevelSixtyStats.Enable` is unset, default 0).

## Consequences

- Witch Hunter counted pair 20261115-135058 / -135217 (worldserver a21e26f0237e): Stake 681350 `cast_gate blocked` ok
  111 / 111, `cast_gate allowed` ok 0 / 0 (ledger clause "Only usable on enemies at or below 35% health." now lists
  both labels). Stake `effect_value e0 #0` with the inherited row: r2-r4 (681347-681349) tolerated 590.4 / 590.9,
  683.8 / 687.2, 767.6 / 769.9 (their level part, 18 / 18 / 12, is in the reads and not in `$m1`), r5-r7
  (681350-681352) ok; 680537 tolerated as before. The 681350 `hit_mean` now has 333 usable hits and alerts:
  834.2 / 830.4 against the hit model's 757.3 (751.2-763.5), which applies the reference armor although the tooltip
  says "ignoring enemy armor" (tooltip mean 829.85); its label is not added to the ledger.
- Finished classes: no Templar (19) or Necromancer (23) class spell or rank is a `SpellRank.dbc` rank without its own
  row whose first rank has a row with terms (data read over `classes.class_spells`), so (1) changes none of their
  verdicts; (2) leaves the Titanstrike entry's scenario as it was; (3) applies only to a class file with
  `base_mana`. The snapshot check of the source stage covers their scenarios.
- Tests: `test_bonus_data.FirstRankTest` (chain order, a skipped out-of-order, missing-spell or one-rank chain, a
  refused layout, the own row winning, the inherited text and detail); `test_compare` (an inherited row is ok;
  mutants: without the chain, with another first rank, or with the first rank's row stripped of its AP coefficient,
  the same reads alert); `test_behaviours.CastGateScenarioTests` (the two-attempt shape, a partial bypass refused;
  mutants: an unenforced gate or a stuck gate alerts); `test_hits.BaseManaStepsTest` (the step, no step without
  `base_mana`, for a flat cost or another power, a refused cost above it, and a set_power before every Stake cast).
