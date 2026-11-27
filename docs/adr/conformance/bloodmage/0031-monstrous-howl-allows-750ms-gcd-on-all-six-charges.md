# 0031. Owner ruling Q-bm-9: Monstrous Howl lowers Bloodfang Bite GCD to 750 ms across all six charges

- Status: accepted (owner ruling Bloodmage Q-bm-9 / O-10, 2026-11-26)
- Date: 2026-11-26

## Context

From server `Spell.dbc` (`/srv/coa/server-data/dbc`, `Description[enUS]`):
- Monstrous Howl `804811`: "Enrage for $d, causing the next 6 |cffffffffBloodfang Bites|r to have a $s1% reduced global cooldown and cost and to trigger |cffffffffCall of the Darkwing|r.@s:801958:0@" (`DurationIndex = 1` = `10000 ms`; `Effect[0]` aura `108 SPELL_AURA_ADD_PCT_MODIFIER`, `MiscValue = 21 SPELLMOD_GLOBAL_COOLDOWN`, `BasePoints = -51, DieSides = 1` -> `-50%`, `EffectSpellClassMask = [0, 8388608, 0]`).
- Bloodfang Bite ranks (`800156, 501695..501697, 503613..503615, 572549..572551`) and Crimson Maw (`803388`) share `SpellFamilyName = 26`, `SpellFamilyFlags = [0, 8388608, 0]`, `StartRecoveryCategory = 133`, `StartRecoveryTime = 1500`.
- `rev_20260920_43_bloodmage_monstrous_howl_proc.sql` configures `804811` with `SpellPhaseMask = 1` (`PROC_SPELL_PHASE_CAST`) and `Charges = 6`.

In `Spell::TriggerGlobalCooldown` (`src/server/game/Spells/Spell.cpp:9265-9282`), `ApplySpellMod(SPELLMOD_GLOBAL_COOLDOWN)` computes `750 ms`, then lines `9275-9276` clamp `gcd` back up to `MIN_GCD = 1000 ms` before invoking `sScriptMgr->OnSpellGlobalCooldown(this, gcd)` at line `9281`. Conformance check `804811 bite_gcd_ready_alert` (`bloodmage.json [1045]`) reproduced the refusal of a follow-up GCD-133 cast (`500123`) at `775 ms` (`0` vs expected `1`), while `[1046] bite_gcd_1000ms_confirm` proved it succeeded at `1030 ms`.

Furthermore, for instant spells (`m_casttime == 0`), `Spell::prepare` (`Spell.cpp:3797-3801`) runs `cast(true)` before `TriggerGlobalCooldown()`. Inside `cast(true)`, `sScriptMgr->OnSpellBeforeEffects` (`Spell.cpp:4056`) runs before `Unit::ProcSkillsAndAuras(..., PROC_SPELL_PHASE_CAST)` (`Spell.cpp:4120`). On the 6th charge of `804811`, `ProcSkillsAndAuras` drops the last charge and removes `804811` before `TriggerGlobalCooldown()` runs, so an `OnSpellGlobalCooldown`-only aura lookup would miss the 6th charge.

The owner ruled (`Q-bm-9` / `O-10`, 2026-11-26): `allow_750ms` — allow the `750 ms` GCD on Bloodfang Bite charges via a Bloodmage `OnSpellGlobalCooldown` hook.

## Options

- Subscribe both `ALLSPELLHOOK_ON_BEFORE_EFFECTS` and `ALLSPELLHOOK_ON_GLOBAL_COOLDOWN` on `bloodmage_secondary_casts` in `src/server/coa/AscensionBloodmageSecondary.cpp`. Snapshot `CalculatePct(1500, 100 + howl->GetAmount())` (`750 ms`) into `spell->SetScriptValue(SPELL_MONSTROUS_HOWL, ...)` in `OnSpellBeforeEffects` before charge 6 is consumed, then apply `duration = std::min(duration, int32(saved))` in `OnSpellGlobalCooldown`. Chosen: handles all 6 charges including the final charge with zero shared `Spell.cpp` edits.
- Check `player->HasAura(804811)` only in `OnSpellGlobalCooldown`. Rejected: fails on the 6th charge because `PROC_SPELL_PHASE_CAST` removes `804811` inside `cast(true)` before `TriggerGlobalCooldown()`.
- Relax `MIN_GCD` in `src/server/game/Spells/Spell.cpp`. Rejected: shared engine change affecting all classes.

## Decision

In `src/server/coa/AscensionBloodmageSecondary.cpp`:
- Add `SPELL_MONSTROUS_HOWL = 804811` to `BloodmageSecondarySpells`.
- Subscribe `ALLSPELLHOOK_ON_BEFORE_EFFECTS` and `ALLSPELLHOOK_ON_GLOBAL_COOLDOWN` on `bloodmage_secondary_casts`.
- In `OnSpellBeforeEffects`, for untriggered Bloodmage family-26 casts with `StartRecoveryTime == 1500`, look up `player->GetAuraEffect(SPELL_MONSTROUS_HOWL, EFFECT_0, player->GetGUID())`; if `howl && howl->IsAffectedOnSpell(info)`, store `std::max(CalculatePct(int32(info->StartRecoveryTime), 100 + howl->GetAmount()), 0)` via `spell->SetScriptValue(SPELL_MONSTROUS_HOWL, ...)`.
- In `OnSpellGlobalCooldown`, if `Bloodmage(spell)` and `spell->GetScriptValue(SPELL_MONSTROUS_HOWL)` is nonzero, clamp `duration = std::min(duration, int32(saved))`.

No SQL, DBC, shared engine, or other-class files are changed.

## Consequences

- All 6 Bloodfang Bite (and Crimson Maw `803388`) charges under Monstrous Howl (`804811`) receive a `750 ms` GCD instead of being clamped to `1000 ms`, while unbuffed casts and unrelated abilities keep the normal `[1000, 1500]` ms GCD clamp.
- Verification targets (executed in the coordinator's merged fix-wave build per `O-8`): `804811 bite_gcd_held` (`[1044]`), `804811 bite_gcd_ready_alert` (`[1045]`), and `804811 bite_gcd_1000ms_confirm` (`[1046]`).
