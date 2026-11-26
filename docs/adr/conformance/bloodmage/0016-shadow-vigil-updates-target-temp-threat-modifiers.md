# 0016. Owner ruling Q-bm-17: Shadow Vigil updates target temporary threat modifiers in Bloodmage C++

- Status: accepted (owner ruling Bloodmage Q-bm-17 / O-10, 2026-11-26; provisional number)
- Date: 2026-11-26

## Context

Server `Spell.dbc` (`SpellFamilyName = 26`):

- Shadow Vigil `806182`: `"Envelop an ally in darkness, temporarily reducing all threat for $d. While active, the
  target's stealth detection is significantly increased."`
- `Effect[0]`: `SPELL_AURA_MOD_TOTAL_THREAT` (`103`), `BasePoints = -90000001`, `DieSides = 1` (`-90,000,000`),
  `TargetA = 21` (`TARGET_UNIT_TARGET_ALLY`), `DurationIndex = 31` (`8000 ms`).

In `AuraEffect::HandleAuraModTotalThreat` (`SpellAuraEffects.cpp:3767-3780`), the core calls
`caster->GetThreatMgr().UpdateMyTempModifiers()` instead of `target->GetThreatMgr().UpdateMyTempModifiers()`. When
Shadow Vigil is cast on an ally, the ally's temporary threat modifier on hostile creatures never updates.

The owner ruled (`Q-bm-17` `bloodmage_only`, `O-10`): fix Shadow Vigil strictly in Bloodmage C++ without modifying
`SpellAuraEffects.cpp`.

## Options

- Bind `aura_ascension_bloodmage_shadow_vigil` (`AuraScript`) to `806182` calling
  `target->GetThreatMgr().UpdateMyTempModifiers()` on `AfterEffectApply` and `AfterEffectRemove` (`EFFECT_0`,
  `SPELL_AURA_MOD_TOTAL_THREAT`, `AURA_EFFECT_HANDLE_CHANGE_AMOUNT_MASK`) when `target && target->IsAlive() &&
  target->IsPlayer()`. Chosen: avoids `ENGINE_FILES` edits and works regardless of the ally's class (unlike
  `bloodmage_talent_events`, which filters `CLASS_SON_OF_ARUGAL`).
- Fix `SpellAuraEffects.cpp:3778`. Rejected by `Q-bm-17` (`bloodmage_only`).

## Decision

1. Add `aura_ascension_bloodmage_shadow_vigil` in `src/server/coa/AscensionBloodmageTalents.cpp` and register it in
   `AddSC_AscensionBloodmageTalents()`.
2. Bind `806182` to `'aura_ascension_bloodmage_shadow_vigil'` in
   `data/sql/updates/pending_db_world/rev_20261127_02_bloodmage_talents_scripts_procs.sql`.

## Consequences

- Casting Shadow Vigil `806182` on any player ally immediately suppresses their threat via `UpdateMyTempModifiers()` and
  restores it when the 8-second aura ends.
- Zero edits to shared `SpellAuraEffects.cpp`.
- Build and gameplay verification run in the coordinator's post-merge verification pass for Lots 1–3.
