# 0007. Owner ruling Q-bm-22: Fleshcraft applies Sated (532125) and suppresses stray DBC effects

- Status: accepted (owner ruling Bloodmage Q-bm-22 / O-10, 2026-11-26; provisional number)
- Date: 2026-11-26

## Context

Fleshcraft `801952` (server `Spell.dbc`, `Description[enUS]`): "Mend blood and bone, healing an ally for $s1% of their
maximum health and applies Sated." Sated `532125` (`Description[enUS]`): "Cannot be affected by Fleshcraft for $d."
(`DurationIndex = 25`, `180000 ms` = `3 min`).

Effective `Spell.dbc` and pre-fix server state (`ev1.md`, `batch4/bm-re4-2`):

- `801952` has `ExcludeTargetAuraSpell = 0`, `Effect[0] = SPELL_EFFECT_HEAL_PCT (136)` (`50%`), stray
  `Effect[1] = SPELL_EFFECT_ENERGIZE_PCT (137)` (`BasePoints = -1`), and stray `Effect[2] = SPELL_EFFECT_APPLY_AURA`
  `SPELL_AURA_HASTE_SPELLS (216)` (`+30%` spell haste).
- `spell_ascension_bloodmage_empowered` (`src/server/coa/AscensionBloodmageVitality.cpp`, bound to `801952` in
  `rev_20260914_13_pooled_vitality.sql:16`) only added the Empowered `+25%` heal and never applied `532125`.
- Pre-fix conformance checks `applies_sated` and `sated_blocks_recast` alerted because `532125` was never applied and
  re-casting `801952` on a Sated target succeeded.

Live evidence (`ev1.md`): `40/40` exact 1:1 pairing between `801952` casts and `532125` Sated applies across 20 logs
(`179.95–180.87 s` duration), `0` recasts on an already-Sated target, and `0` `801952` energize or spell-haste aura
events. Tooltip video archive `q742IyqxrV0` (`t=7:20`) confirms `3 min`.

The project owner ruled (`Q-bm-22 align_live_both`, `O-10`, 2026-11-26) to apply `532125` Sated (`3 min`), block
re-casting `801952` on Sated targets, and suppress stray `E1`/`E2`.

## Options

- Patch `801952` and `532125` in `bloodmage_vitality_contracts::OnLoadSpellCustomAttr` (`ExcludeTargetAuraSpell = 532125`,
  clear `E1`/`E2`, register `801952` in `Ascension::ClientSpellPatches`, mark `532125` negative with
  `SPELL_ATTR0_CU_NEGATIVE`) and cast `532125` from `spell_ascension_bloodmage_empowered::ModifyHit`
  (`src/server/coa/AscensionBloodmageVitality.cpp`). Chosen: reuses the existing `801952` `SpellScript` registration
  (zero new SQL script bindings), ensures `GetCaster()` owns the `532125` aura so Flesh Foundry `504412` can reduce its
  duration, enforces target exclusion natively in `SpellInfo::CheckTarget` (`SpellInfo.cpp:2185`), and prevents stray
  haste/energize effects.
- Leave `801952` `E1`/`E2` active and only add `532125`. Rejected: contradicts live logs (`0` haste/energize events)
  and owner ruling `Q-bm-22`.

## Decision

1. In `bloodmage_vitality_contracts::OnLoadSpellCustomAttr` (`src/server/coa/AscensionBloodmageVitality.cpp`):
   - For `801952`, set `ExcludeTargetAuraSpell = 532125`, clear `Effects[EFFECT_1].Effect = SPELL_EFFECT_NONE`,
     `Effects[EFFECT_2].Effect = SPELL_EFFECT_NONE`, `Effects[EFFECT_2].ApplyAuraName = SPELL_AURA_NONE`, and register
     `801952` in `Ascension::ClientSpellPatches`.
   - For `532125`, set `info->AttributesCu |= SPELL_ATTR0_CU_NEGATIVE`.
2. In `spell_ascension_bloodmage_empowered::ModifyHit`, when `GetSpellInfo()->Id == 801952` and `GetHitUnit()` is
   alive without `532125`, cast `532125` on the hit target with `TRIGGERED_FULL_MASK`.

## Consequences

- Casting `801952` Fleshcraft heals the target (including Empowered `+25%` caster max health), applies `532125` Sated
  (`3 min`) as a negative aura, blocks re-casting `801952` while `532125` is active, and no longer applies stray `+30%`
  spell haste or `0%` Rage energize.
- Post-fix build and runtime verification of `801952` and `704633` Flesh Foundry regressions run after the fix-wave
  merge build (`O-8`).
