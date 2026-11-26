# 0003. Owner ruling O-9: Blood Covenant uses maximum health for cost

- Status: accepted (owner ruling O-9, 2026-11-26; provisional number)
- Date: 2026-11-26

## Context

Blood Covenant `1200012` (server `Spell.dbc`, `SpellFamilyName = 5`, `BaseLevel = 20`, `SpellLevel = 20`,
`MaxLevel = 0`, `PowerType = POWER_HEALTH (-2)`, `ManaCostPercentage = 90`, `Effect[0] = SPELL_EFFECT_TRANS_DOOR`
summoning gameobject `194111`) sacrifices 90% of the caster's health to begin the summoning ritual.

In `SpellInfo::CalcPowerCost` (`src/server/game/Spells/SpellInfo.cpp:3217-3219`), `POWER_HEALTH` percentage costs
unconditionally used `caster->GetCreateHealth()`. For a level-40 Human Bloodmage (`704` base health, `57` Stamina ->
`1094` max health), `1200012` cost `633` instead of `984` (90% of maximum health), disagreeing with the spell's
maximum-health sacrifice expectation while every other Bloodmage `% base health` spell intentionally uses base health.

The project owner ruled (`O-9`, confirmed `opt_in_1200012`, 2026-11-26) to mirror Starcaller's `UsesMaxManaForCost`
opt-in (`SpellInfo.h:361`, `SpellInfo.cpp:3221`) with a default-false `UsesMaxHealthForCost` flag enabled solely for
`1200012`, leaving all other classes and Bloodmage base-health costs untouched.

## Options

- Add `bool UsesMaxHealthForCost = false;` on `SpellInfo` (`src/server/game/Spells/SpellInfo.h`), branch `case
  POWER_HEALTH:` in `SpellInfo::CalcPowerCost` (`src/server/game/Spells/SpellInfo.cpp`) to select
  `caster->GetMaxHealth()` when set, and opt `1200012` in via `bloodmage_vitality_contracts::OnLoadSpellCustomAttr`
  (`src/server/coa/AscensionBloodmageVitality.cpp`). Chosen: exact mirror of `UsesMaxManaForCost`, zero impact on any
  spell that does not opt in, and keeps `1200012` (which carries `SpellFamilyName = 5`) cleanly scoped without needing
  a family-26 gate.
- Switch all `POWER_HEALTH` `ManaCostPercentage` spells to `caster->GetMaxHealth()`. Rejected: breaks every Bloodmage
  ability whose tooltip and tests expect `% of base health`.

## Decision

1. Add `bool UsesMaxHealthForCost = false;` beside `UsesMaxManaForCost` in `src/server/game/Spells/SpellInfo.h`.
2. In `SpellInfo::CalcPowerCost` (`src/server/game/Spells/SpellInfo.cpp`), evaluate
   `UsesMaxHealthForCost ? caster->GetMaxHealth() : caster->GetCreateHealth()` in `case POWER_HEALTH:`.
3. Register `bloodmage_vitality_contracts` (`GlobalScript`, `GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR`) in
   `src/server/coa/AscensionBloodmageVitality.cpp` to set `info->UsesMaxHealthForCost = true` when `info->Id == 1200012`.
4. Update existing regression `apps/coa-gameplay-test/scenarios/bloodmage-blood-covenant-rune-3996.json` (`contract`,
   step 7 `label` and `equals`) from `-633` (90% of `704` base health) to `-984` (90% of `1094` max health).

## Consequences

- `1200012` Blood Covenant deducts `int32(CalculatePct(caster->GetMaxHealth(), 90))` on cast; all other `POWER_HEALTH`
  spells keep `caster->GetCreateHealth()`.
- Because `SpellInfo.h` and `SpellInfo.cpp` are shared `ENGINE_FILES`, finished classes (`templar` 19, `necromancer` 23)
  and Bloodmage scenarios (`bloodmage-blood-covenant-rune-3996.json`, `bloodmage-blood-covenant-summons-party-11165.json`,
  and `bloodmage.json` `1200012`) must be verified after the fix-wave merge build (`O-8`).
