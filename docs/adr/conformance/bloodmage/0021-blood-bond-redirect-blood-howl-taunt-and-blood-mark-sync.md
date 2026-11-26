# 0021. Blood Bond threat redirect, Blood Howl empty-threat taunt, and Blood Mark aura sync

- Status: accepted (Bloodmage conformance S-16 / S-17 / S-18, 2026-11-26; provisional number)
- Date: 2026-11-26

## Context

Server `Spell.dbc` (`SpellFamilyName = 26`):

- Blood Bond `504627`: `"...and redirect $s3% of their threat generated to you."` `Effect[2]` holds `BasePoints = -11,
  DieSides = 1` (`$s3 = 10`) with `Effect = 0`, so `aura_ascension_bloodmage_blood_bond` never registered threat
  redirection on the bonded ally.
- Blood Mark `707624`: `"Increases the Physical damage taken by enemies within $707375a1 yds of you by $707625s1%."`
  `707624` is a dummy passive while `707625` carries the enemy area aura (`Effect[0] = 129`, aura `87`, `+3%` Physical),
  identical to Dark Mark `705731` / `707375`, which was synced in `bloodmage_talent_events` while `707624` was omitted.
- Blood Howl `800782`: `"Taunts nearby enemies within $a1 yds, forcing them to attack you for $d."` `SpellLevel = 0` with
  no `spell_threat` row and `Effect[0]` `SPELL_AURA_MOD_TAUNT` (`11`). `AuraEffect::HandleModTaunt` calls `TauntUpdate()`,
  which is a no-op when the caster has `0` threat on the target's threat list.

## Options

- Implement all three cleanly in `src/server/coa/AscensionBloodmageTalents.cpp` + SQL bindings:
  - In `aura_ascension_bloodmage_blood_bond`: register `10%` threat redirect via `RegisterRedirectThreat` on
    `AfterEffectApply` and unregister via `UnregisterRedirectThreat` on `AfterEffectRemove`, plus mark `504627` with
    `SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED` (mirroring `AscensionThreatRedirect.cpp:122-123`).
  - Extract `SyncMarkAura` in `bloodmage_talent_events` shared by Dark Mark (`705731 -> 707375`) and Blood Mark
    (`707624 -> 707625`).
  - Add `aura_ascension_bloodmage_blood_howl` bound to `800782` adding `1.0f` threat if `<= 0.0f` before calling
    `TauntUpdate()`.
  Chosen: idiomatic AzerothCore/CoA patterns with zero shared engine edits.

## Decision

1. In `src/server/coa/AscensionBloodmageTalents.cpp`:
   - Mark `504627` with `SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED` (clearing `SPELL_ATTR0_CU_FORCE_AURA_SAVING`) and add
     `ApplyRedirect` / `RemoveRedirect` to `aura_ascension_bloodmage_blood_bond`.
   - Share `SyncMarkAura` between `SPELL_DARK_MARK` / `SPELL_DARK_MARK_AURA` and `SPELL_BLOOD_MARK` /
     `SPELL_BLOOD_MARK_AURA` in `bloodmage_talent_events`.
   - Add and register `aura_ascension_bloodmage_blood_howl`.
2. Bind `800782` to `'aura_ascension_bloodmage_blood_howl'` in
   `data/sql/updates/pending_db_world/rev_20261127_02_bloodmage_talents_scripts_procs.sql`.

## Consequences

- Bonded allies redirect `10%` of threat generated to the Bloodmage for the duration of Blood Bond without stale redirect
  GUIDs across logout.
- Learning/unlearning Blood Mark `707624` applies/removes enemy Physical vulnerability area aura `707625`.
- Blood Howl `800782` forces nearby hostile enemies onto the Bloodmage even when the Bloodmage had zero prior threat.
- Build and gameplay verification run in the coordinator's post-merge verification pass for Lots 1–3.
