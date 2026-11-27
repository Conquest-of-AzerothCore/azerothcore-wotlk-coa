# 0004. Owner ruling Q-bm-5: grant native Parry (3127) to Bloodmage

- Status: accepted (owner ruling Bloodmage Q-bm-5 / O-10, 2026-11-26; provisional number)
- Date: 2026-11-26

## Context

Blood Pact `801955` (server `Spell.dbc`, `Description[enUS]`): "Invoke a blood pact, exchanging health for enhanced
reflexes, increasing your chance to dodge and reducing the chance for ranged attacks to hit you by $s3%... for $d.
While active you can dodge or parry while casting."

Effective server state on base commit `7d38e2194b`:

- `Unit::CanDefendDuringCast` (`src/server/game/Entities/Unit/Unit.cpp:5136-5141`) already exempts Bloodmage
  (`CLASS_SON_OF_ARUGAL` with aura `801955`), and `Unit::MeleeSpellHitResult` (`Unit.cpp:3921-3924`) checks it for
  parrying while casting.
- However, `Unit::GetUnitParryChance` (`Unit.cpp:4325-4335`) returns `0.0f` unless `player->CanParry()` is true, and
  Bloodmage (class `20`, classmask `524288`) received no Parry spell in `AscensionCompatData::ClassSpells`
  (`src/server/coa/AscensionCustomClassData.h:337-375`), `AscensionLiveBaseline::Spells`
  (`src/server/coa/AscensionLiveBaselineData.h:141-155`), `playercreateinfo_spell_custom`, or class trainer `900020`
  (`trainer_spell` in `rev_20260923_05_coa_class_trainer_core.sql:1453-1540`).
- Pre-fix conformance measurement (`batch4/bm-re2-2/review.md`): `801955 behaviour_metric_delta cast_parry` alerted in
  both runs (`3 -> 3` hits landed vs expected `3 -> 0`), while `cast_dodge` passed (`3 -> 0`).

Live evidence (`ev1.md`): `47` native parries occurred across `4` Bloodmages in the 186-log combat archive (`Redfury`
`25`, `Fairgraves` `16`, `Graf` `5`, `Buttblood` `1`), including `2` parries during active `801955` in `log 41`
(`2026-06-06`). Tooltip video archive `q742IyqxrV0` (`t=7:22`) matches the `Spell.dbc` wording verbatim.

The project owner ruled (`Q-bm-5 grant_parry`, `O-10`, 2026-11-26) to grant native Parry (`3127`, `Effect[0] =
SPELL_EFFECT_PARRY (22)`, `BaseLevel = 1`, `MaxLevel = 0`) to Bloodmage.

## Options

- Grant Parry `3127` consistently across all four class-grant sources: `AscensionCompatData::ClassSpells`,
  `AscensionLiveBaseline::Spells`, `playercreateinfo_spell_custom` (`racemask = 0, classmask = 524288`), and
  `trainer_spell` (`TrainerId = 900020`, `ReqLevel = 1`). Chosen: keeps character creation, automatic progression
  reconciliation (`AscensionCompat.cpp:954-1039`), trainer learning (`ObjectMgr.cpp:10252`), and fresh-character baseline
  checks (`AscensionFreshCharacterCheck.cpp:427-447`) completely consistent, and matches the owner's chosen spell ID
  `3127` (`Spell::EffectParry` calls `SetCanParry(true)` identically to `3124`).
- Grant `3127` only conditionally while `801955` is active. Rejected: contradicts live logs showing native Bloodmage
  parries outside Blood Pact and contradicts ruling `Q-bm-5`.
- Insert into legacy `npc_trainer` instead of `trainer_spell`. Rejected: AzerothCore loads class trainer lists from
  `trainer_spell` (`src/server/game/Globals/ObjectMgr.cpp:10252`), matching `rev_20260923_05_coa_class_trainer_core.sql`.

## Decision

1. Add `{20, 1, 3127}` to `AscensionCompatData::ClassSpells` (`src/server/coa/AscensionCustomClassData.h`, array size
   `850 -> 851`).
2. Add `{20, 0, 3127}` to `AscensionLiveBaseline::Spells` (`src/server/coa/AscensionLiveBaselineData.h`, array size
   `317 -> 318`).
3. Add idempotent `DELETE`/`INSERT` rows for `playercreateinfo_spell_custom` (`0, 524288, 3127`) and `trainer_spell`
   (`900020, 3127, 2, 0, 0, 0, 0, 0, 1`) in
   `data/sql/updates/pending_db_world/rev_20261127_01_bloodmage_core_and_bonuses.sql`.

## Consequences

- Bloodmage characters start with `3127` Parry (`CanParry() == true`), allowing native melee parries and parrying while
  casting during `801955` Blood Pact.
- `AscensionLiveBaseline::Spells` matches `playercreateinfo_spell_custom` so fresh-character baseline checks see zero
  missing or unexplained extra spells.
- Post-fix build and runtime verification of `801955 cast_parry`, `bloodmage-blood-pact-defend-during-cast.json`, and
  fresh-character checks run after the fix-wave merge build (`O-8`).
