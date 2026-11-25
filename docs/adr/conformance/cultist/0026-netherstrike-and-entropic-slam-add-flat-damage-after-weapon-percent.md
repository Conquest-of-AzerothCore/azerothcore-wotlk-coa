# 0026. Owner ruling Q-cu-13: Netherstrike and Entropic Slam add flat damage after weapon percent

- Status: accepted (owner ruling Cultist Q-cu-13 / O-15, 2026-11-25)
- Date: 2026-11-25

## Context

From server `Spell.dbc` (`/srv/coa/server-data/dbc`, `Description[enUS]`):
- Netherstrike `578263` (Rank 6 lvl 60; rank chain root `806222`, ranks `806222, 806825, 806826, 806827, 806828, 578263`):
  "Strike an enemy quickly for $s2% Weapon Damage plus ${$m1+0} Shadow damage, purging $s3 beneficial magic effect from them." (`125% Weapon Damage plus 441 Shadow damage`).
- Entropic Slam `572846` (Rank 6 lvl 52; rank chain root `804152`, ranks `804152, 555351, 555352, 555353, 555354, 572846`):
  "Crush enemies in front of you, dealing $s2% Weapon Damage plus ${$m1+0} as Shadow damage and draining 40 Insanity." (`130% Weapon Damage plus 98 as Shadow damage`).

In `Spell.dbc`, all six ranks of both spells define `Effect[0] = 121` (`SPELL_EFFECT_NORMALIZED_WEAPON_DMG`, adding `fixed_bonus`) before `Effect[1] = 31` (`SPELL_EFFECT_WEAPON_PERCENT_DAMAGE`, `125%` / `130%`). In `Spell::EffectWeaponDmg` (`src/server/game/Spells/SpellEffects.cpp:4725-4748`), unless `m_spellInfo->AscensionFlatAfterWeaponPercent` is true, the effect loop adds `fixed_bonus` at `Effect[0]` and then multiplies the sum by `weaponDamagePercentMod` at `Effect[1]`, producing `1.25 * (W + 441)` and `1.30 * (W + 98)` instead of `1.25 * W + 441` and `1.30 * W + 98`.

Pre-fix conformance runs measured this excess in both arms:
- `578263` (`prove-fix1`, `20261125-002716` / `20261125-002829`): `damage_base` measured `903` / `897` against tooltip `[744..797]` (`770.5 +- 26.5`); `damage_ap` measured `7499` / `7478` against `[7344..7397]` (`7370.5 +- 26.5`).
- `572846` (`prove-fixes2`, `20261125-020708` / `20261125-020745`): `damage_ap_8x` 8-hit sum measured `58309` / `58344` against tooltip `[57953..58233]` (mean `7288.6` / `7293.0` vs `7261.6`).

The owner ruled (Cultist `Q-cu-13`, `O-15`, 2026-11-25): `fix` — flat Shadow damage is added after multiplying weapon damage by the weapon percentage.

## Options

- Set `info->AscensionFlatAfterWeaponPercent = true` in `AscensionCultist::ApplyContracts` (`src/server/coa/AscensionCultistContracts.cpp`) for `Any(info, {806222, 804152})`, matching the existing per-class contract pattern (`AscensionSunClericContracts.cpp:238`, `AscensionTemplarContracts.cpp:189`, `AscensionXorothContracts.cpp:88`). Chosen.
- Reorder effects in `Spell.dbc` or change shared `SpellEffects.cpp`. Rejected (out of class-contract bounds and risks other classes).

## Decision

In `AscensionCultist::ApplyContracts` (`src/server/coa/AscensionCultistContracts.cpp:88-89`), set `info->AscensionFlatAfterWeaponPercent = true` when `Any(info, {806222, 804152})`. No shared engine, SQL, DBC, or other-class changes.

## Consequences

- All six ranks of Netherstrike (`806222, 806825..806828, 578263`) and all six ranks of Entropic Slam (`804152, 555351..555354, 572846`) multiply normalized weapon damage by `$s2%` first and then add the flat Shadow damage `${$m1+0}`.
- No other spell or class is reached.
- Counted pair (`20261125-091222` / `20261125-091256`, build `85a3e5d9fb40`, 18/18 ok, 0 flips):
  - `578263 behaviour_metric_delta damage_base`: `787` / `779` (control `0`, expected `770.5 +- 26.5`).
  - `578263 behaviour_metric_delta damage_ap`: `7349` / `7346` (control `0`, expected `7370.5 +- 26.5`).
  - `572846 behaviour_metric_delta damage_ap_8x`: `58021` / `58024` (control `0`, expected `[57953..58233]`).
  - Sibling and reached-spell checks unchanged (`578263` `insanity`, `purge`, `cast_gate`; `572846` `cone`, `drain_40`, `drain_60_to_20`, `gate_59`; `680600` `hammer_damage` `+24.93%` / `+25.00%`, `slam_damage` `+24.91%` / `+24.96%`; `681106` `crit_20` `2.101` / `2.101`, `crit_50` `2.250` / `2.243`, `crit_0` `1.997` / `2.003`, `mod_50` `50` / `50`).
