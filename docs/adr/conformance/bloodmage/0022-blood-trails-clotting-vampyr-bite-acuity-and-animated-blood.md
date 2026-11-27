# 0022. Acuity consumption, Trail of Blood gate, Animated Blood heal, Vampyr Bite interrupt, and Clotting gate

- Status: accepted (Bloodmage conformance S-6c / S-9 / S-11 / S-13 / S-14, Q-bm-7 / Q-bm-12, 2026-11-26; provisional number)
- Date: 2026-11-26

## Context

Five Bloodmage talent/ability defects verified against server `Spell.dbc` (`SpellFamilyName = 26`) and existing code:

1. **The Council Assembled / Atherann's Acuity (`504103` / `504105`, S-6c)**: `504105` has `ProcCharges = 0`, so casting
   Valanar's Vengeance (`560315, 561027..561029, 572793..572795`) or Keleseth's Calamity (`560249, 561175..561179`)
   (`SpellFamilyFlags[0] & 0x60000`) failed to consume the `"next"` buff. `EffectSchoolDMG` runs during
   `HandleLaunchPhase` (`Spell.cpp:4058`) before `OnSpellCast` (`Spell.cpp:4203`).
2. **Blood Trails / Trail of Blood (`804858` / `804859`, S-9)**: tooltip gates `804859` on `"Allies in a Cursed Form"`,
   but `804857 -> 804859` had no Cursed Form target check, buffing Mortal Form allies.
3. **Animated Blood (`573357` / `504711` / `592015`, S-11)**: `npc_ascension_animated_blood` casts `589023` triggered,
   while `spell_proc` `504711` had `AttributesMask = 0`, blocking all Blood Strike procs; `504711` also called raw
   `Unit::DealHeal` instead of casting Ascension's `592015` heal (`3,988` live `SPELL_HEAL` events in `ev4.md`).
4. **Vampyr Bite (`801563, 801564, 803581..803587`, S-13, Q-bm-7)**: tooltip states `"being damaged ends the effect"`,
   but all 9 records have `AuraInterruptFlags = 0`.
5. **Clotting / Aortic Assault (`704115` / `806212, 807780..807785`, S-14, Q-bm-12)**: all 7 Aortic Assault ranks carry
   `Effect[2]` triggering Clotting detonation `806214` unconditionally even when `704115` Clotting is not learned.

## Options

- Implement all five in `src/server/coa/AscensionBloodmageTalents.cpp` + `rev_20261127_02_bloodmage_talents_scripts_procs.sql`:
  - Subscribe `ALLSPELLHOOK_ON_CAST` on `bloodmage_nightmare_casts` to remove `504105` on non-triggered casts matching
    `SpellFamilyFlags[0] & 0x60000`.
  - Add `aura_ascension_bloodmage_blood_trail` on `804857` (`OnEffectPeriodic`, `EFFECT_1`, `SPELL_AURA_PERIODIC_TRIGGER_SPELL`)
    calling `PreventDefaultAction()` when `!IsInCursedForm(GetTarget())`. (Failing `OnCheckCast` on the triggered `804859`
    spell instead would make `Spell.cpp:3631-3635` call `SetDuration(0)` on the non-passive periodic `804857` pool aura,
    despawning the entire pool on the first tick any Mortal Form ally stands in it; suppressing at `AuraEffect::PeriodicTick`
    skips only that target while keeping the pool alive for Cursed Form allies.)
  - Update `spell_proc` `504711` to `AttributesMask = 2` and cast `592015` via `CastCustomSpell` in
    `aura_ascension_bloodmage_animated_blood_leech::Proc`.
  - Set `AURA_INTERRUPT_FLAG_TAKE_DAMAGE` (+ `ClientSpellPatches`) on all 9 explicit Vampyr Bite IDs.
  - Add `aura_ascension_bloodmage_aortic_assault` gating `Effect[2]` periodic trigger on `target->HasAura(704115)`.
  Chosen: minimal, class-scoped, zero engine edits.

## Decision

Apply all five fixes in `src/server/coa/AscensionBloodmageTalents.cpp` and register the companion `spell_script_names`
(`804857`, `806212, 807780..807785`) and `spell_proc` (`504711` `AttributesMask = 2`) rows in
`data/sql/updates/pending_db_world/rev_20261127_02_bloodmage_talents_scripts_procs.sql`.

## Consequences

- Acuity boosts the consuming Valanar's Vengeance / Keleseth's Calamity cast and is consumed on cast.
- Trail of Blood applies only to allies in a Cursed Form.
- Animated Blood's triggered Blood Strike heals the owner for 50% of damage dealt via `592015`.
- Vampyr Bite's healing-received buff breaks upon taking damage across all 9 ranks.
- Aortic Assault fires Clotting `806214` only when `704115` is active.
- Build and gameplay verification run in the coordinator's post-merge verification pass for Lots 1–3.
