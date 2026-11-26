# 0012. Owner ruling Q-bm-13: Corrupted Blood increases all Bloodmage damage against afflicted targets

- Status: accepted (owner ruling Bloodmage Q-bm-13 / O-10, 2026-11-26; provisional number)
- Date: 2026-11-26

## Context

Server `Spell.dbc` (`SpellFamilyName = 26`):

- Corrupted Blood passive `704692`: `"When you use Taldaram's Torment on a Humanoid or Beast it now corrupts their
  blood, increasing your damage dealt against them by $532623s1%."`
- Corrupted Blood debuff `532623`: `Effect[0]` aura `271` (`SPELL_AURA_MOD_DAMAGE_FROM_CASTER`, `BasePoints = 9,
  DieSides = 1` -> `+10%`, `MiscValue = 0`), `EffectSpellClassMask = (6291456, 0, 0)` (restricting the bonus solely to
  Veinburst and Reave).

In `SpellInfo::IsAffected`, an empty `flag96()` matches every `SpellFamilyName == 26` spell when evaluated by
`Unit::SpellDamageBonusTaken` (`Unit.cpp:10142`) and `Unit::MeleeDamageBonusTaken` (`Unit.cpp:11738`), while melee
auto-attacks (`spellProto == nullptr`) bypass `SPELL_AURA_MOD_DAMAGE_FROM_CASTER` and pass through
`UnitScript::ModifyMeleeDamage` (`Unit.cpp:1969`).

The owner ruled (`Q-bm-13` `all_damage`, `O-10`): extend `532623`'s `+10%` damage bonus to all Bloodmage damage against
afflicted Humanoids and Beasts (with companion client debuff tooltip update in MPQ).

## Options

- Clear `532623` `Effects[EFFECT_0].SpellClassMask = flag96()` (with `ClientSpellPatches`) and apply `532623` `EFFECT_0`
  via `AddPct` inside `bloodmage_blood_scent_damage::ModifyMeleeDamage` for Bloodmage melee auto-attacks. Chosen: covers
  every Bloodmage spell and white auto-attack with zero shared engine edits.
- Edit `Unit::MeleeDamageBonusTaken` to evaluate aura `271` for null `spellProto`. Rejected: touches shared engine code
  unnecessarily for a single Bloodmage talent.

## Decision

1. In `src/server/coa/AscensionBloodmageTalents.cpp` (`bloodmage_talent_contracts::OnLoadSpellCustomAttr`): clear
   `info->Effects[EFFECT_0].SpellClassMask = flag96();` on `532623` and register `532623` in `ClientSpellPatches`.
2. In `bloodmage_blood_scent_damage::ModifyMeleeDamage`: when a Bloodmage (`CLASS_SON_OF_ARUGAL`) strikes a target
   carrying `532623` (`EFFECT_0`, caster GUID matching the attacker), apply `AddPct(amount, corrupted->GetAmount())`.

## Consequences

- Every `SpellFamilyName == 26` spell and white melee swing from the applying Bloodmage receives `+10%` damage against
  targets afflicted by Corrupted Blood `532623`.
- Build and gameplay verification run in the coordinator's post-merge verification pass for Lots 1–3.
