# 0042. Heart Rupturer Sanguine Rupture mask and Taldaram's Torment DoT SP scaling

- Status: accepted
- Date: 2026-11-27

## Context

The Bloodmage (class 20) class-end conformance pair surfaced two real server defects:

1. **Heart Rupturer (`680685`)**:
   - Server `Spell.dbc`: `Effect[0]` (`SPELL_AURA_ADD_PCT_MODIFIER`, `MiscValue = 0` `SPELLMOD_DAMAGE`, `+20%`) carries `EffectSpellClassMask = (0, 0x2001, 0x80004000)` (`Bloodmoon Blast`, `Ravenous Strike`, `Claw Sweep`, `Sanguine Rupture` parent `572907`), omitting `800775` (`Sanguine Rupture` triggered direct Shadow hit carrying `spell_bonus_data` `+0.35 SP`, `SpellFamilyFlags[1] = 0x00200000`).
   - Meanwhile `Effect[1]` (`SPELL_AURA_ADD_PCT_MODIFIER`, `MiscValue = 8` `SPELLMOD_ALL_EFFECTS`, `+20%`) carries `EffectSpellClassMask = (0, 0, 0x80000000)`, matching only `572907`'s forwarded base damage (`~390`) and missing the `+0.35 SP` bonus (`7000` at `+20,000 SP`), causing `680685` to measure `+1.019%` / `+1.063%` instead of `+20%`.
   - Adding `0x00200000` (`SanguineRuptureDamageClassMask1`) to `Effect[0]` while keeping `Effect[1]` active would double-dip `572907`'s base damage (`1.2 * 1.2 = +44%`) at low SP.

2. **Taldaram's Torment (`800772, 802568..802573, 802580`)**:
   - Server `Spell.dbc`: 15 s Shadow Magic DoT (`DmgClass = 1`, `SchoolMask = 32`, `EffectAmplitude[0] = 3000`, 5 ticks, description `"$o1 Shadow damage over $d"` without a formula token) carries `EffectBonusMultiplier = 0.0` and had no `spell_bonus_data` entry, giving `0` SP scaling (`850..880` across 5 ticks even at `+100,000 SP`).
   - Talent `807544` (`The Cup Runneth Over`, remapped to `SPELLMOD_BONUS_MULTIPLIER +20%` in Bloodmage ADR 0023) explicitly increases Taldaram's Torment's spell power scaling by `+20%`, and recorded live combat logs in `~/Projects/coa-log-history` corroborate non-trivial SP scaling above base tick damage (`~173` base non-crit at rank 8 vs `Niklaux` `349..400` in `2026-08-31-18.59.52 WoWCombatLog.txt`, `Graf` `511..677` in `2026-08-22-23.42.54 WoWCombatLog.txt`, and `Buttblood` `513..738` in `2026-08-23-18.39.18 WoWCombatLog.txt`).

## Options

1. **Heart Rupturer (`680685`)**: Add `SanguineRuptureDamageClassMask1` (`0x00200000`) to `680685 Effect[0]` (`SPELLMOD_DAMAGE`) and clear `680685 Effect[1]` (`SPELLMOD_ALL_EFFECTS`) in `bloodmage_talent_contracts::OnLoadSpellCustomAttr` (`src/server/coa/AscensionBloodmageTalents.cpp`), matching Bloodwell Eruption (`560072`) in Bloodmage ADR 0014. Keeping `Effect[1]` active was rejected because it double-dips `572907` base points (`+44%`). Note that the auto-generated non-ledger probe `680685 e1 spell_modifier 572907` reads raw `Spell.dbc` and is expected to alert once `Effect[1]` is cleared, matching `560072 e1`.
2. **Taldaram's Torment (`800772`)**: Add `(800772, 0, 0.2, 0, 0)` to `spell_bonus_data` in `data/sql/updates/pending_db_world/rev_20261127_01_bloodmage_core_and_bonuses.sql`. First rank `800772` applies to all 8 ranks (`800772, 802568..802573, 802580`) via `spell_ranks` lookup in `SpellMgr::GetSpellBonusData`, supplying the standard 15 s 5-tick DoT coefficient (`1.0 / 5 = 0.20` per tick) consistent with live logs and enabling `807544` (`+20%` `SPELLMOD_BONUS_MULTIPLIER`).

## Decision

Implement both fixes inside Bloodmage-scoped C++ (`src/server/coa/AscensionBloodmageTalents.cpp`) and `data/sql/updates/pending_db_world/rev_20261127_01_bloodmage_core_and_bonuses.sql`.

## Consequences

- `680685` Heart Rupturer increases `800775` Sanguine Rupture damage (base + SP) by `+20%` once across all SP levels.
- `800772`..`802580` Taldaram's Torment scales with `0.20` Shadow SP per tick (`1.00` total over 5 ticks), and `807544` The Cup Runneth Over increases that SP scaling by `+20%` (`0.24` per tick).
- Verified via focused 5x Bloodmage conformance reruns and Bloodmage catalog regression scenarios.
