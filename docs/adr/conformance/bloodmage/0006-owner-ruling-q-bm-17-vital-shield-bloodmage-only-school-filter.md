# 0006. Owner ruling Q-bm-17: Bloodmage-only Shadow and Nature filter for Vital Shield

- Status: accepted (owner ruling Bloodmage Q-bm-17 / O-10, 2026-11-26; provisional number)
- Date: 2026-11-26

## Context

Vital Shield `504849` (server `Spell.dbc`, `Description[enUS]`): "Protects the caster with vital magic, increasing your
Shadow and Nature healing received by $s1% and restoring $804309s1% of your maximum health every $t2 sec. Lasts $d."

Effective `Spell.dbc` and core engine behavior (`ev2.md`):

- `504849` `Effect[0]` is `APPLY_AURA` `SPELL_AURA_ASCENSION_MOD_HEALING_RECEIVED_PCT (319)` with `BasePoints = 14`,
  `DieSides = 1` (`+15%`), and `EffectMiscValue = 40` (`SPELL_SCHOOL_MASK_SHADOW | SPELL_SCHOOL_MASK_NATURE`). Out of
  all `28` spells in `Spell.dbc` using aura `319`, `504849` is the only spell with a restricted school mask
  (`MiscValue != 0 && MiscValue != 127`).
- `Unit::SpellHealingBonusTaken` (`src/server/game/Entities/Unit/Unit.cpp:10996`) applies
  `GetTotalAuraMultiplier(SPELL_AURA_ASCENSION_MOD_HEALING_RECEIVED_PCT)` unconditionally to all schools.
- Pre-fix measurement (`batch1/bm-r3`, `ev2.md`): Shadow (`504085`), Nature (`25297`), and self-heal `804309` (`2.3%`)
  passed, while Holy control Flash Heal `10917` (`SchoolMask = 2`) also increased by `+15.03%` / `+14.92%` (`alert`,
  expected `+0%`).

The project owner ruled (`Q-bm-17 bloodmage_only`, `O-10`, 2026-11-26) to fix Vital Shield strictly inside Bloodmage
C++ without modifying shared `Unit.cpp` or `SpellAuraEffects.cpp`.

## Options

- Convert `504849` `Effect[0]` from aura `319` to `SPELL_AURA_DUMMY` in `bloodmage_vitality_contracts::OnLoadSpellCustomAttr`
  (preserving `BasePoints = 14`, `DieSides = 1`, `MiscValue = 40`), and apply the school-masked `+15%` modifier in
  `bloodmage_vitality_scaling::ModifyHealReceived` (`src/server/coa/AscensionBloodmageVitality.cpp`). Chosen: requires
  zero edits to `Unit.cpp` or `SpellAuraEffects.cpp`, leaves all other 27 aura-319 spells untouched, preserves
  `GetAmount() == 15` and `GetMiscValue() == 40`, boosts Shadow and Nature direct heals, pure HoTs, and `804309`
  self-heals (`2% -> 2.3%`), and leaves Holy/Fire/Frost/Arcane/Physical heals unchanged.
- Filter aura `319` by `EffectMiscValue` directly in `Unit::SpellHealingBonusTaken` (`Unit.cpp:10996`). Rejected by
  owner ruling `Q-bm-17` (`bloodmage_only`).

## Decision

1. In `bloodmage_vitality_contracts::OnLoadSpellCustomAttr` (`src/server/coa/AscensionBloodmageVitality.cpp`), rewrite
   `504849` `Effects[EFFECT_0].ApplyAuraName` from `SPELL_AURA_ASCENSION_MOD_HEALING_RECEIVED_PCT` to `SPELL_AURA_DUMMY`.
2. Subscribe `UNITHOOK_MODIFY_HEAL_RECEIVED` on `bloodmage_vitality_scaling` and implement `ModifyHealReceived`:
   - Resolve `recipient` across the asymmetric engine call sites (`Unit::HealBySpell` `Unit.cpp:9308` passes
     `(healer, target)` whereas `AuraEffect::PeriodicTick` `SpellAuraEffects.cpp:6983` passes `(target, healer)`):
     use `first` when `first == second` or when `spellInfo` has `SPELL_AURA_PERIODIC_HEAL` without any direct heal/leech
     effect (`HEAL`, `HEAL_PCT`, `HEAL_MAX_HEALTH`, `HEAL_MECHANICAL`, `HEALTH_LEECH`), and `second` otherwise.
   - When `recipient` carries `504849` `EFFECT_0` and `uint32(spellInfo->GetSchoolMask()) & uint32(vital->GetMiscValue())`
     is non-zero, apply `AddPct(heal, vital->GetAmount())`.

## Consequences

- Vital Shield increases Shadow and Nature healing received (direct, pure HoT, and `804309` periodic self-heal) by
  `+15%` while leaving Holy healing (`10917`) and other schools at `1.0x`.
- Known boundary under the `no Unit.cpp / SpellAuraEffects.cpp edit` constraint: a cross-unit (`caster != target`)
  hybrid Shadow/Nature spell containing both a direct heal effect and `SPELL_AURA_PERIODIC_HEAL` passes identical
  `(A, B, spellInfo)` tuples in opposite argument orders at `Unit.cpp:9308` vs `SpellAuraEffects.cpp:6983`; pure direct
  heals, pure HoTs, and all self-heals resolve unambiguously.
- Post-fix build and runtime verification of `504849` conformance entries run after the fix-wave merge build (`O-8`).
