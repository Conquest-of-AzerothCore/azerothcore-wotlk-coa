# 0679. A rolled value read adds the spell_bonus_data terms

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15
- Builds on: ADR 0192

## Context

Fiery Judgement 803369 effect 0 shows `${$m1+0+$AP*0.55+$spfi*1}`. The `spell_effect_value` read is one
`SpellEffectInfo::CalcValue` roll (912..1033), while the 0.55 AP and 1.0 SP come from its `spell_bonus_data` row and
are added later by `Unit::SpellDamageBonusDone` (`Unit.cpp:9879-9885` AP, `:9903-9914` SP). The judge compared the
bare roll with the full formula: an alert that measures the read's scope, not the engine. Witch Hunter count of record
final04 has 8 such rolled verdicts (503662 e1, 680537, 802140, 803366-803369, 805365 through 807762).

The world database is not built from `data/sql/base`: `DBUpdater::Populate` imports the package named by
`data/coa-world/baseline.json` (`DBUpdater.cpp:504-506`), whose `spell_bonus_data` has 2,917 rows, then the updater
applies the `updates_include` directories (`UpdateFetcher.cpp:129-155`: archive, custom, updates, pending) and every
`modules/<module>/data/sql/<directory naming world>` (`:157-187`), recursively, in file-name order, released and
archived files before pending, custom and module ones (`:394-406`), skipping a file whose recorded hash matches
(`:304-370`).

## Options

- Read the world database after the run: compare runs offline, after the run's database is gone.
- Read `data/sql/base` and the update directories (the first design): misses the package, which holds the rows.
- Replay the package and the updater's directories from the build's commit.

## Decision

`bonus_data.py` replays `spell_bonus_data` from the package (the base dump when no manifest exists), then the
updater's directories in its order, skipping files the package's `updates` table records with the file's hash
(native or without carriage returns) or under a renamed name. A statement other than a keyed DELETE, a plain or
IGNORE INSERT or a dump's table reset, a duplicate file name, or a module world file naming the table (whether the
module is built cannot be read offline) makes the table unreadable. No module SQL names the table today.

`judge_roll` models a read only when the token carries a power term and the effect owner's row has terms: for a
`SCHOOL_DAMAGE` or `HEALTH_LEECH` effect each read becomes read + `ap_bonus` x AP + `direct_bonus` x SP of the
spell's single school, with the SQL literal and the recorded stats as the tooltip reads them: the engine's float
column and its int32 truncation of each term would put an exact read up to 2 below or a few millionths above the
formula range and alert it; RAP replaces AP for a ranged weapon spell outside the melee damage class. The
case is `not_measured` for an unreadable table, a periodic term, another effect type, a level penalty
(`CalculateLevelPenalty` below 1) on a non-zero spell power, a family spell carrying a coefficient modifier on the
spell whose stat is not zero (spell power: spellmod 24, private index 41 or its `OVERRIDE_CLASS_SCRIPTS` conversion
20041; attack power: 32, 42, 45, 20032, 20042, 20045), or no single recorded spell power. A modifier or a penalty on a
zero stat changes a zero term and is modelled. A token without a power term, or a row of zeros, keeps today's
verdict.

## Consequences

- Tests: `test_bonus_data.py` (replay order, applied and changed files, REPLACE, UPDATE and unkeyed DELETE, module
  files, duplicate names, the package) and `test_compare.py` (bare reads plus the row's terms `ok`, the row without
  its AP coefficient `alert`, a zero row equal to no row, periodic, level-penalty and modifier cases and an
  unreadable table `not_measured`).
- Templar and Necromancer: no `effect_value` verdict of their last records has a power token and an owner row with
  terms, so their verdicts stay; generation is unchanged and their snapshots stay byte-identical.
- Model limits: `UseRangedAttackPowerForDamage` set by class code, the victim's attack power bonus auras and class
  hooks that change the coefficients are not read; a wrong attack power or a missing term reads as an alert.
