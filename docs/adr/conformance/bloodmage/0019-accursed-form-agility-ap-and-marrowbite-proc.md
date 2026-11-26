# 0019. Accursed Form applies 804699 Agility-to-AP and procs Marrowbite 504553

- Status: accepted (Bloodmage conformance S-15, 2026-11-26; provisional number)
- Date: 2026-11-26

## Context

Server `Spell.dbc` (`SpellFamilyName = 26`):

- Accursed Form `562572`: `"Embrace your demonic curse for $d, entering an improved Cursed Form, increasing your attack
  power by $804699s2% of your Agility and causing your melee attacks to reduce all healing done to the target by
  $504553s1% for $504553d, stacking $504553u times."`
- `804699` (*Cursed Form*, `DurationIndex = 21`): `Effect[0]` periodically triggers `804845` Dark Frenzy every `3000 ms`,
  and `Effect[1]` is `SPELL_AURA_MOD_ATTACK_POWER_OF_STAT_PERCENT` (`268`, `MiscValue = 1` Agility, `BasePoints = 49,
  DieSides = 1` -> `+50%` Agility as AP). `562572` never applied `804699`.
- `562572` `Effect[2]` is `SPELL_AURA_PROC_TRIGGER_SPELL` (`42`, `TriggerSpell = 504553` Marrowbite), but `ProcFlags = 0`
  in `Spell.dbc` and no `spell_proc` row existed, so `504553` never procced on melee swings or melee abilities (`899` live
  procs in `ev3.md`).

## Options

- Clear `804699` `Effects[EFFECT_0]` in `OnLoadSpellCustomAttr` (so `804845` Dark Frenzy stays solely controlled by
  `SyncDarkFrenzy` / talent `704644`), cast/remove `804699` when `562572` applies/removes in `bloodmage_talent_events`
  (and `OnPlayerJustDied`), and insert a `spell_proc` row for `562572` (`ProcFlags = 20`, `SpellTypeMask = 1`,
  `SpellPhaseMask = 2`, `DisableEffectsMask = 3`, `Chance = 100`). Chosen: reuses Ascension's own `804699` and `504553`
  records cleanly.
- Compute Agility-to-AP in a custom `PlayerScript`. Rejected: `804699` already implements aura `268` natively.

## Decision

1. In `src/server/coa/AscensionBloodmageTalents.cpp`:
   - In `bloodmage_talent_contracts::OnLoadSpellCustomAttr`: clear `Effects[EFFECT_0]` (`Effect`, `ApplyAuraName`,
     `Amplitude`) on `804699`.
   - In `bloodmage_talent_events::OnAuraApply`: cast `804699` triggered when `562572` applies.
   - In `bloodmage_talent_events::OnAuraRemove` (before the death return) and `bloodmage_cursed_form_death`: remove
     `804699` when `562572` ends.
2. In `data/sql/updates/pending_db_world/rev_20261127_02_bloodmage_talents_scripts_procs.sql`: add `spell_proc` row
   `(562572, 0, 0, 0, 0, 0, 20, 1, 2, 0, 0, 3, 0, 100, 0, 0)`.

## Consequences

- Entering Accursed Form `562572` increases AP by `50%` of Agility without granting Dark Frenzy `804845`, and melee
  auto-attacks and melee-class abilities apply Marrowbite `504553` (stacking up to 2 times for `-20%` healing taken).
- Build and gameplay verification run in the coordinator's post-merge verification pass for Lots 1–3.
