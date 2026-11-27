# 0018. Transgression Demon creature type and Final Embrace Blood Curse gate and Crimson Maw swap

- Status: accepted (Bloodmage conformance S-10 / S-12, 2026-11-26; provisional number)
- Date: 2026-11-26

## Context

Server `Spell.dbc` (`SpellFamilyName = 26`):

- Transgression `801076`: `"Enter a unique Cursed Form for $d that does not disable the use of Mortal Form abilities...
  While in a Cursed Form you are treated as if you were a Demon."` `Effect[1]` is `SPELL_EFFECT_DUMMY` (`TargetA = 1`,
  `MiscValue = 524287`) with no `SPELL_AURA_MOD_SHAPESHIFT`, so `Unit::GetCreatureType()` stays `CREATURE_TYPE_HUMANOID`
  instead of `CREATURE_TYPE_DEMON`. `SpellShapeshiftForm.dbc` row `57` (`Cursed Form`) sets `SHAPESHIFT_FLAG_STANCE`
  (`flags1 = 3065`) and `creatureType = 3` (`CREATURE_TYPE_DEMON`), `0` family-26 spells set `StancesHigh` or
  `StancesNotHigh`, and `MortalAbilityForms[] = {680692, 801076}` already preserves weapon visibility and omits the
  restricting marker `802877`.
- Final Embrace `524865`: `"Requires Mortal Form. Gorge on blood magic, entering a dramatically improved Cursed Form
  for $d, transforming your Bloodfang Bite into Crimson Maw..."`
  - `524865` carries `ExcludeCasterAuraSpell = 562572` (blocking only Accursed Form, not Blood Curse `562720` or Eternal
    Curse `800157`), while `RuntimeExcludeCasterAuraSpell` only remaps `524861 -> 802877`.
  - `#10242` (`rev_20261126_10242_bloodmage_final_embrace_shapeshift.sql`) already links `524865 <-> 525047`
    (Shapeshift `57`, `ExcludeCasterAuraSpell = 562572`) via `spell_linked_spell` (`AddAura`), which is unaffected by
    setting `524865` `ExcludeCasterAuraSpell = 802877`.
  - No handler swapped Bloodfang Bite ranks (`800156, 501695..501697, 503613..503615, 572549..572551`) into Crimson Maw
    `803388` (`239/239` live casts in `ev1.md`).

## Options

- Set `801076` `Effects[EFFECT_1]` to `SPELL_EFFECT_APPLY_AURA` / `SPELL_AURA_MOD_SHAPESHIFT` / `MiscValue = 57` and
  `524865` `ExcludeCasterAuraSpell = AscensionBloodmage::CursedForm` (`802877`) in `OnLoadSpellCustomAttr` (both with
  `ClientSpellPatches`), and swap all 10 Bloodfang Bite ranks to `803388` via `learnSpell(803388, true)` +
  `SetTemporarySpellReplacement` in `bloodmage_talent_events::OnAuraApply`/`OnAuraRemove` (and `OnPlayerJustDied`).
  Chosen: zero core edits, preserves `#10242`'s `525047` link and `MortalAbilityForms` behavior.
- Hardcode `801076` in `Unit::GetCreatureType()` (`Unit.cpp`). Rejected: unnecessary `ENGINE_FILES` edit.

## Decision

In `src/server/coa/AscensionBloodmageTalents.cpp`:

1. In `bloodmage_talent_contracts::OnLoadSpellCustomAttr`:
   - Set `801076` `Effects[EFFECT_1]` to `SPELL_EFFECT_APPLY_AURA`, `SPELL_AURA_MOD_SHAPESHIFT`, `MiscValue = 57` and
     register `801076` in `ClientSpellPatches`.
   - Set `524865` `ExcludeCasterAuraSpell = AscensionBloodmage::CursedForm` (`802877`) and register `524865` in
     `ClientSpellPatches`.
2. Add `ApplyFinalEmbraceCrimsonMaw` and `ClearFinalEmbraceCrimsonMaw` called from `bloodmage_talent_events::OnAuraApply`,
   `OnAuraRemove` (before the death early return), and `bloodmage_cursed_form_death::OnPlayerJustDied`.

## Consequences

- Transgression `801076` sets `GetShapeshiftForm() == 57` (`CREATURE_TYPE_DEMON`) while keeping weapons visible and
  Mortal Form abilities castable; because `SPELL_AURA_MOD_SHAPESHIFT` (`57`) occupies the standard shapeshift slot,
  `801076` is mutually exclusive with other shapeshift forms (`525047` / `562572` / etc.) via standard WoW shapeshift
  rules.
- Final Embrace `524865` is blocked under any restricting Cursed Form (`802877`), keeps `#10242`'s `525047` link intact,
  and replaces all known Bloodfang Bite ranks with Crimson Maw `803388` for its duration (cleanly restoring on expiry,
  cancel, or death).
- Build and gameplay verification run in the coordinator's post-merge verification pass for Lots 1–3.
