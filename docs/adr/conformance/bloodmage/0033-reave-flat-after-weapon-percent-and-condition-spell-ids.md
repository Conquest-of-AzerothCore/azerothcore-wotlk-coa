# 0033. Owner ruling Q-bm-21: Reave adds flat damage after weapon percent and fixes swapped bonus spell IDs

- Status: accepted (owner ruling Bloodmage Q-bm-21 / O-10, 2026-11-26)
- Date: 2026-11-26

## Context

From server `Spell.dbc` (`/srv/coa/server-data/dbc`, `Description[enUS]`):
- Reave (8 ranks: `800490` Rank 1, `802463..802469` Ranks 2-8; `SpellFamilyName = 26`, `SpellFamilyFlags = [4194304, 0, 0]`): "Lacerate an enemy, dealing $s2% Weapon Damage plus ${$m1+0}. If the enemy is bleeding, below 35% health, or if you are behind them, deal $572280s1% additional Shadow damage for each condition met."
  - Every rank places `Effect[0] = 121` (`SPELL_EFFECT_NORMALIZED_WEAPON_DMG`, flat damage) before `Effect[1] = 31` (`SPELL_EFFECT_WEAPON_PERCENT_DAMAGE`, `125%`).
- Bonus Shadow copy helper spells:
  - `805612` (`TargetAuraState = 18` `AURA_STATE_BLEEDING`) — intended for bleeding targets.
  - `802884` (`TargetAuraState = 13` `AURA_STATE_HEALTHLESS_35_PERCENT`) — intended for `<35%` HP targets.
  - `802883` (`TargetAuraState = 0`) — intended for behind-target attacks.

Two defects existed in `src/server/coa/AscensionBloodmageSecondary.cpp`:
1. `bloodmage_secondary_contracts::OnLoadSpellCustomAttr` did not set `info->AscensionFlatAfterWeaponPercent = true` on Reave ranks, so `Spell::EffectWeaponDmg` (`SpellEffects.cpp:4730`) multiplied flat `Effect[0]` by `1.25x` (`1.25 * (W + flat)` instead of `1.25 * W + flat`), causing `802469 damage_base` (`[505]`) and `802469 damage_ap` (`[506]`) to alert above the tooltip band.
2. `BloodmageSecondarySpells` swapped `SPELL_REAVE_BLEED = 802883` and `SPELL_REAVE_BACK = 805612`. When attacking behind a non-bleeding target, `OnSpellHitResult` cast `805612`, which failed core target validation on `TargetAuraState = 18`, causing `802469 cond_behind` (`[510]`) to deal `0` Shadow damage.

The owner ruled (`Q-bm-21` / `O-10`, 2026-11-26): `fix_both` — enable `AscensionFlatAfterWeaponPercent = true` on the Reave chain and correct the swapped `SPELL_REAVE_BLEED`/`SPELL_REAVE_BACK` constants.

## Options

- Set `SPELL_REAVE_BLEED = 805612` and `SPELL_REAVE_BACK = 802883` in `BloodmageSecondarySpells`, and set `info->AscensionFlatAfterWeaponPercent = true` for all 8 explicit Reave ranks (`800490`, `802463..802469`) inside `bloodmage_secondary_contracts::OnLoadSpellCustomAttr`. Chosen: matches the per-class contract pattern (`AscensionCultistContracts.cpp`, `AscensionSunClericContracts.cpp`) and avoids `RankOf` during `OnLoadSpellCustomAttr` before `spell_ranks` loads.
- Strip `TargetAuraState = 18` from `805612` instead of swapping the IDs. Rejected: leaves `805612` and `802883` inverted relative to their DBC records and live combat-log usage (`805612` `2057` hits > `802883` `1833` hits in `ev2.md`).

## Decision

In `src/server/coa/AscensionBloodmageSecondary.cpp`:
- Fix `SPELL_REAVE_BLEED = 805612` and `SPELL_REAVE_BACK = 802883`.
- In `bloodmage_secondary_contracts::OnLoadSpellCustomAttr`, set `info->AscensionFlatAfterWeaponPercent = true;` for `info->Id == SPELL_REAVE || (info->Id >= 802463 && info->Id <= 802469)`.

No SQL, DBC, shared engine, or other-class files are changed.

## Consequences

- All 8 Reave ranks calculate `1.25 * normalized_weapon_damage + flat_damage`.
- Bleeding triggers `805612` (`TargetAuraState = 18`), `<35%` HP triggers `802884` (`TargetAuraState = 13`), and behind-target triggers `802883` (`TargetAuraState = 0`), allowing behind-target Shadow bonus damage to land on non-bleeding targets.
- Follow-up note for the conformance JSON pass: `bloodmage.json` entries `[507]`, `[508]`, `[510]`, `[511]`, and `[512]` currently name the old swapped IDs (`802883` for bleed, `805612` for behind) and must be aligned when the coordinator updates conformance assertions.
- Verification targets (executed in the coordinator's merged fix-wave build per `O-8`): `802469 damage_base` (`[505]`), `802469 damage_ap` (`[506]`), and the `cond_*` suite (`[507..512]`).
