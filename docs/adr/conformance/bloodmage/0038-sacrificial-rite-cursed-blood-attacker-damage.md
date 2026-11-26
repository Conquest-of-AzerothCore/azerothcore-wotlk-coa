# 0038. Sacrificial Rite Cursed Blood deals Shadow damage when cursed attackers deal damage

- Status: accepted (Bloodmage conformance fix wave / O-11, 2026-11-26)
- Date: 2026-11-26

## Context

From server `Spell.dbc` (`/srv/coa/server-data/dbc`, `Description[enUS]`):
- Sacrificial Rite `800785` applies Cursed Blood `573250` to attackers (`rev_20260920_44_bloodmage_melee_event_procs.sql`, `Cooldown = 1000`).
- Cursed Blood `573250` (`SpellFamilyName = 26`, `DurationIndex = 28` = `5000 ms`, `ProcFlags = 0`): "Reduces healing received by $s1%$?s705732[, increases damage taken by $705732s1%,][] and dealing damage now causes you to take ${$806163m1+$806163ppl1+$sps*.5+$AP*.1} Shadow Damage. Lasts $d."
  - `Effect[0]`: aura `118` (`SPELL_AURA_MOD_HEALING_PCT`, `-40%`, `TargetA = 6 TARGET_UNIT_TARGET_ENEMY`).
  - `Effect[1]`: aura `42` (`SPELL_AURA_PROC_TRIGGER_SPELL`, `TriggerSpell = 806163`, **`TargetA = 1 TARGET_UNIT_CASTER`**).
  - `Effect[2]`: aura `87` (`SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN`, `TargetA = 6 TARGET_UNIT_TARGET_ENEMY`).
- Cursed Blood damage spell `806163` (`SpellFamilyName = 26`, `DmgClass = 1 MAGIC`, `SchoolMask = 32 SHADOW`, `BaseLevel = 58`, `SpellLevel = 58`, `MaxLevel = 0`, `Effect[0] = 2 SPELL_EFFECT_SCHOOL_DAMAGE`, `BasePoints = 70`, `DieSides = 1`, `RealPointsPerLevel = 0.25`, **`TargetA = 1 TARGET_UNIT_CASTER`**, `BonusMultiplier = 0.0`, description includes "Can only occur once per sec.").

Four stacked defects prevented `573250` from damaging cursed attackers (`bloodmage.json [539] cursed_blood_damage`, expecting `93 [92, 95]` = `71 + 0.5*SP + 0.1*AP`):
1. `573250` `Effect[1]` had `TargetA = TARGET_UNIT_CASTER`, so casting `573250` placed `Effect[1]` on the Bloodmage instead of the attacker.
2. `573250` had `ProcFlags = 0` and no `spell_proc` row, so `Effect[1]` never procced.
3. `806163` `Effect[0]` had `TargetA = TARGET_UNIT_CASTER`, so a cast by the Bloodmage would damage the Bloodmage instead of the attacker (and default `HandleProcTriggerSpellAuraProc` would have made the attacker cast `806163`).
4. `806163` had `BonusMultiplier = 0.0` and no `spell_bonus_data` entry, omitting the `+0.5 SP` and `+0.1 AP` terms.

## Options

- Fix both `TargetA` fields in `bloodmage_secondary_contracts::OnLoadSpellCustomAttr` (`573250 Effect[1]` to `TARGET_UNIT_TARGET_ENEMY` plus `SPELL_ATTR0_CU_NEGATIVE_EFF1`, and `806163 Effect[0]` to `TARGET_UNIT_TARGET_ENEMY`), bind `aura_ascension_bloodmage_cursed_blood` on `573250` to intercept `EFFECT_1` procs and have `GetCaster()` cast `806163` at `GetTarget()`, and add `spell_proc` (`573250`, `ProcFlags = 69908` DONE damage only, `SpellTypeMask = 1`, `SpellPhaseMask = 2`, `DisableEffectsMask = 1`, `Chance = 100`, `Cooldown = 1000`), `spell_script_names`, and `spell_bonus_data` (`806163`, `0.5, 0, 0.1, 0`) in `rev_20261127_03_bloodmage_secondary_procs.sql`. Chosen: keeps `806163` attributed to the Bloodmage (`caster`) using Bloodmage's SP/AP, fires only when the cursed victim deals damage (`event.GetActor() == victim` and DONE-only `ProcFlags`), and avoids any stray `573250` aura on the Bloodmage.
- Leave `573250 Effect[1]` on `TARGET_UNIT_CASTER` and trigger from `TAKEN` damage on the Bloodmage. Rejected: contradicts the tooltip ("dealing damage now causes you to take ... Shadow Damage" against any target, not only the Bloodmage) and puts a debuff aura on the Bloodmage.

## Decision

1. In `src/server/coa/AscensionBloodmageSecondary.cpp`:
   - Add `SPELL_CURSED_BLOOD = 573250` and `SPELL_CURSED_BLOOD_DAMAGE = 806163` to `BloodmageSecondarySpells`.
   - In `bloodmage_secondary_contracts::OnLoadSpellCustomAttr`, set `TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY)` on `573250 Effect[1]` (with `SPELL_ATTR0_CU_NEGATIVE_EFF1`) and on `806163 Effect[0]`.
   - Add and register `aura_ascension_bloodmage_cursed_blood` on `573250` (`DoCheckProc` requiring `event.GetActor() == GetTarget()` with live distinct caster and victim; `OnEffectProc` on `EFFECT_1, SPELL_AURA_PROC_TRIGGER_SPELL` calling `PreventDefaultAction()` and `caster->CastSpell(victim, SPELL_CURSED_BLOOD_DAMAGE, true)`).
2. In `data/sql/updates/pending_db_world/rev_20261127_03_bloodmage_secondary_procs.sql`:
   - Add `spell_proc` for `573250` (`ProcFlags = 69908`, `SpellTypeMask = 1`, `SpellPhaseMask = 2`, `DisableEffectsMask = 1`, `Chance = 100`, `Cooldown = 1000`).
   - Add `spell_script_names` `(573250, 'aura_ascension_bloodmage_cursed_blood')`.
   - Add `spell_bonus_data` `(806163, 0.5, 0, 0.1, 0, 'Bloodmage - Sacrificial Rite (Cursed Blood)')`.

## Consequences

- Attackers afflicted with Cursed Blood (`573250`) receive `Effect[1]` on themselves; when they deal damage (at most once per second), the Bloodmage inflicts `806163` Shadow damage (`71 + 0.5*SP + 0.1*AP` at level 60, `93` at reference naked stats) on the attacker.
- Because `Unit::TriggerAurasProcOnEvent` snapshots the actor's DONE procs before executing the victim's TAKEN procs (`Unit.cpp:14459-14487`), the initial hit that applies `573250` does not immediately self-proc `806163`; subsequent damage dealt by the cursed attacker triggers it cleanly.
- Verification targets (executed in the coordinator's merged fix-wave build per `O-8`): `800785 cursed_blood_damage` (`[539]`), sibling `800785` checks (`[533]`, `[538]`, `[540]`), and handwritten scenario `bloodmage-sacrificial-rite-cursed-blood.json`.
