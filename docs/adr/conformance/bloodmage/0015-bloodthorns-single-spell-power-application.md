# 0015. Owner ruling Q-bm-3: Bloodthorns applies +3.5% Shadow SP once without double-dipping

- Status: accepted (owner ruling Bloodmage Q-bm-3 / O-10, 2026-11-26; provisional number)
- Date: 2026-11-26

## Context

Server `Spell.dbc` (`SpellFamilyName = 26`):

- Bloodthorns ranks 1–10 (`802313, 501662..501670`) and Greater Bloodthorns (`572116`) carry `Effect[0]` aura `15`
  (`SPELL_AURA_DAMAGE_SHIELD`, Shadow school).
- Tooltip: `"Bloodthorns sprout from an ally for $d, causing ${$m1+0+$sps*0.035} Shadow damage to attackers when hit."`
- The owner ruled (`Q-bm-3` `sp_only_edit_text`, `O-10`): add `+3.5%` Shadow SP scaling only (no `0.5 s` ICD; remove the
  ICD sentence in MPQ).

Adding `spell_bonus_data` `(0.035)` triggers a core double-dip: `AuraEffect::CalculateAmount` (`SpellAuraEffects.cpp:627`)
calls `caster->SpellDamageBonusDone(..., SPELL_DIRECT_DAMAGE)` when storing `m_amount`, and then
`Unit::DealDamageShieldDamage` (`Unit.cpp:2367`) reads `GetAmount()` and calls `caster->SpellDamageBonusDone(...)` a
second time (`+0.070 * SP`), while also inflating `aura_amount` above the base value asserted by
`bloodmage-bloodthorns-damage-4151.json`.

## Options

- Bind `aura_ascension_bloodmage_bloodthorns` to all 11 Bloodthorns spell IDs (`802313, 501662..501670, 572116`) with a
  `DoEffectCalcAmount` handler (`EFFECT_0, SPELL_AURA_DAMAGE_SHIELD`) that restores `amount = effect->GetOldAmount();`
  (saved at `SpellAuraEffects.cpp:609` prior to line `627`). Chosen: zero shared engine edits, keeps stored `aura_amount`
  at base (`22` on R7 / `10` on R3), and lets `Unit::DealDamageShieldDamage` apply `+0.035 * SP` exactly once.
- Edit `SpellAuraEffects.cpp:627` or `Unit.cpp:2367`. Rejected: modifies shared `ENGINE_FILES` affecting every class's
  damage shields.

## Decision

1. Add `aura_ascension_bloodmage_bloodthorns` in `src/server/coa/AscensionBloodmageTalents.cpp` restoring
   `amount = effect->GetOldAmount();` in `DoEffectCalcAmount`, registered in `AddSC_AscensionBloodmageTalents()`.
2. Bind `802313, 501662..501670, 572116` to `'aura_ascension_bloodmage_bloodthorns'` in
   `data/sql/updates/pending_db_world/rev_20261127_02_bloodmage_talents_scripts_procs.sql`.

## Consequences

- Bloodthorns and Greater Bloodthorns preserve base `aura_amount` and apply `+0.035 * Shadow SP` exactly once per damage
  shield retaliation.
- Build and gameplay verification run in the coordinator's post-merge verification pass for Lots 1–3.
