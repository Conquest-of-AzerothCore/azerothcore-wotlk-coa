# 0017. Owner ruling Q-bm-22: Aortic Aegis fans cast-rank Blood Veil to the target's subgroup

- Status: accepted (owner ruling Bloodmage Q-bm-22 / O-10, 2026-11-26; provisional number)
- Date: 2026-11-26

## Context

Server `Spell.dbc` (`SpellFamilyName = 26`):

- Aortic Aegis `806274`: `"Your Blood Veil now applies to the party members of the target."` (`Effect[0]` aura `42`,
  `TriggerSpell = 806275`; `spell_proc` in `rev_20260920_58_bloodmage_aortic_aegis_proc.sql` has `AttributesMask = 0` so
  triggered Blood Veil casts cannot re-proc `806274`).
- Default trigger `806275` uses `TargetA = 33` (caster party instead of target's party), `RadiusIndex = 11` (`45 yd`),
  and hardcodes `TriggerSpell = 504263` (Blood Veil Rank 1) instead of the cast rank (`504263, 572277, 572278, 572279`).
- Live combat logs (`ev4.md`) recorded `191` Aortic Aegis casts fanning Rank 4 `572279` to the target's subgroup.

The owner ruled (`Q-bm-22` `align_live_both`, `O-10`): propagate cast-rank Blood Veil to the target's party members.

## Options

- Add `aura_ascension_bloodmage_aortic_aegis` bound to `806274` (`DoCheckProc` verifying `IsBloodVeilRank` and
  `OnEffectProc` calling `PreventDefaultAction()` then iterating `targetPlayer->GetGroup()` members in
  `targetPlayer->GetSubGroup()` within `45.0f` yd and casting `castInfo->Id` triggered). Chosen: handles both caster's
  own subgroup and cross-subgroup raid targets while preserving cast rank and avoiding proc loops (`AttributesMask = 0`).
- Patch `806275` DBC targeting only. Rejected: `806275` still hardcodes Rank 1 `504263` and cannot mirror the cast rank.

## Decision

1. Add `aura_ascension_bloodmage_aortic_aegis` in `src/server/coa/AscensionBloodmageTalents.cpp` and register it in
   `AddSC_AscensionBloodmageTalents()`.
2. Bind `806274` to `'aura_ascension_bloodmage_aortic_aegis'` in
   `data/sql/updates/pending_db_world/rev_20261127_02_bloodmage_talents_scripts_procs.sql`.

## Consequences

- Casting any Blood Veil rank (`504263, 572277..572279`) with Aortic Aegis `806274` applies that exact rank to alive
  subgroup members of the shielded target within `45 yd`.
- Triggered fan-out casts do not re-proc `806274` because `spell_proc` keeps `AttributesMask = 0`.
- Build and gameplay verification run in the coordinator's post-merge verification pass for Lots 1–3.
