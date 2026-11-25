# 0011. Mind Rot grants its 30% critical strike bonus when dispelled

- Status: accepted (provisional number, numbered at merge; owner ruling O-12 Q-cu-2, 2026-11-24)
- Date: 2026-11-25

## Context

Mind Rot 300300 and Eldritch Screams 525049 append sub-description 560714 (server `Spell.dbc`, `Description[enUS]`):
"If this effect is dispelled, your critical strike chance is increased by `$560947s1%` for `$560947d`." Mind Rot 560943
(`ToolTip[enUS]`) states the same promise: "Dispelling this effect increases the Cultist's critical strike chance by
`$560947s1%` for `$560947d`."

Server `Spell.dbc` defines buff 560947 (*Mind Rot*, `SpellFamilyName` 31, DurationIndex 28 = 5000 ms, StackAmount 0,
Effect[0] aura 290 `SPELL_AURA_MOD_CRIT_PCT`, BasePoints 29 with DieSides 1 -> +30%, TargetA 1 `TARGET_UNIT_CASTER`),
and debuff 560943 carries Dispel 1 (`DISPEL_MAGIC`), but no DBC field, pending SQL row, or Cultist script cast 560947
when 560943 was dispelled.

Conformance pair `20261124-211849` / `20261124-212014` (`cu-g6`, build `aa4bb0bc3311`, `Spell.dbc` `4e4ed9ba`) measured
`aura` 560947 on the Cultist caster at 0 (expected 1) in both runs after Kobold Vermin (entry 6) dispelled 560943 with
Dispel Magic 527. The `coabuildhub` snapshot renders 300300 and 525049 with the same 30% for 5 seconds sentence;
`coa-history` holds no events for 560947.

The project owner ruled (`O-12` `Q-cu-2`, 2026-11-24): implement the buff so the Cultist who applied Mind Rot gains 30%
critical strike chance for 5 seconds when Mind Rot is dispelled, and not when it expires or is removed otherwise.

## Options

- Handle `AURA_REMOVE_BY_ENEMY_SPELL` for spell 560943 in `cultist_scaling::OnAuraRemove` (`UnitScript`,
  `AscensionCultistContracts.cpp`), casting 560947 on the Cultist `Owner(application->GetBase()->GetCaster())`.
- Attach an `AuraScript::AfterDispel` handler to 560943. Not available without SQL: `Aura::LoadScripts`
  (`SpellAuras.cpp:2452`) binds `AuraScript` instances exclusively from `ObjectMgr::_spellScriptsStore`, populated from
  `spell_script_names`, where 560943 has no row (`rev_20260909_12_cultist_completion.sql`), and SQL edits are outside
  this server-fix boundary.

In `Unit::RemoveAurasDueToSpellByDispel` (`Unit.cpp:6026`) and `Spell::EffectDispelMechanic` (`SpellEffects.cpp:2376`),
dispelling 560943 removes the aura with `AURA_REMOVE_BY_ENEMY_SPELL` and invokes `sScriptMgr->OnAuraRemove`
(`Unit.cpp:5703`). Non-dispel uses of `AURA_REMOVE_BY_ENEMY_SPELL` in the engine require positive Spellsteal targets,
exhausted absorb shields, or non-zero mechanics (560943 is negative, non-absorb, `Mechanic` = 0); expiry, cancel,
death, and overwrite pass `AURA_REMOVE_BY_EXPIRE`, `AURA_REMOVE_BY_CANCEL`, `AURA_REMOVE_BY_DEATH`, and
`AURA_REMOVE_BY_DEFAULT`. `AscensionTemplarAuras.cpp:225` and Felsworn ADR 0022 establish this `UnitScript` route.

## Decision

`cultist_scaling` (`src/server/coa/AscensionCultistContracts.cpp`) registers `UNITHOOK_ON_AURA_REMOVE` and casts 560947
on `Owner(application->GetBase()->GetCaster())` when `mode == AURA_REMOVE_BY_ENEMY_SPELL` and
`application->GetBase()->GetId() == 560943`. No shared file, DBC, SQL, or client text changes.

## Consequences

- Dispelling Mind Rot 560943 (applied by either Mind Rot 300300 or Eldritch Screams 525049) grants 560947 (+30%
  critical strike chance for 5 s) to the Cultist who applied that 560943 aura.
- Natural expiration, manual cancellation, death, and reapplication do not grant 560947.
- Both 560943 and 560947 have `SpellFamilyName` 31 and empty `shared_with`; no other spell or class is affected.
- Existing `300300` proc-rate scenarios (`periodic` and `channeled`) were rerun in `20261125-013143` and
  `20261125-013253` (build `3077a905bb28`, ok in both runs: 0.2451/0.2484 and 0.2521/0.2451) with no movement.
- Regressions (`20261125-013143` and `20261125-013253`, build `3077a905bb28`, 9/9 ok, 0 flips):
  - `300300`: `dispel_crit` (+30.0 `spell_crit_chance` and `aura` 560947 0 -> 1 on Dispel Magic 988),
    `dispel_crit_duration` (`aura` 560947 0 -> 1 at ~4.6 s -> 0 at ~5.2 s after dispel), and `dispel_expire_control`
    (`aura_apply_count` 560947 0 -> 0 after natural 10 s expiry with `spell_cast_count` 560943 >= 1).
  - `525049`: `dispel_crit` (`aura` 560947 0 -> 1 on Dispel Magic 527 x2), `dispel_crit_pct` (+30.0
    `spell_crit_chance` on Dispel Magic 988), `dispel_crit_duration` (`aura` 560947 0 -> 1 -> 0 bracketing 5000 ms),
    and `dispel_expire_control` (`aura_apply_count` 560947 0 -> 0 after natural 10 s expiry).
