# 0014. Owner ruling Q-bm-16 and Bloodwell Eruption: Sanguine Rupture phantom aura, O-37 base values, and crit mask

- Status: accepted (owner rulings O-37, Bloodmage Q-bm-16 / O-10, 2026-11-26; provisional number)
- Date: 2026-11-26

## Context

Server `Spell.dbc` (`SpellFamilyName = 26`):

- Sanguine Rupture energize helper `802496` (triggered by `800775` `Effect[1]`) carries an undocumented `Effect[2]`
  (`SPELL_EFFECT_APPLY_AURA`, `SPELL_AURA_MOD_DAMAGE_PERCENT_DONE`, `+5%` Shadow, `DurationIndex = 0`) that inflated
  `800775` base damage by `+5%` (`0` live `SPELL_AURA_APPLIED` events across `12,173` energizes in archived logs).
- `561303` Cursed Ground (`EffectRealPointsPerLevel[0] = 1.02`, `MaxLevel = 0`), `803326` Blood Burst
  (`EffectRealPointsPerLevel[0] = 9.4`, `MaxLevel = 0`), and `803392` Hematoma (`EffectRealPointsPerLevel[0] = 0.95`,
  `MaxLevel = 0`) borrow `$m1` without `$ppl1` in their tooltips; under owner ruling `O-37`, server base values follow
  the displayed tooltip amount without per-level inflation.
- Bloodwell Eruption `560072`: `"Increases the radius of Sanguine Rupture by $s1 yds and its critical strike chance by
  $s2%."` `Effect[1]` (`SPELL_AURA_ADD_FLAT_MODIFIER`, `SPELLMOD_CRITICAL_CHANCE`, `+10%`) masks only `[0, 0,
  0x80000000]` (the cast wrapper `572907`), omitting the triggered damage spell `800775` (`[0, 0x200000, 0]`).

The owner confirmed `Q-bm-16` (`fix_all_o37`, `O-10`).

## Options

- In `bloodmage_talent_contracts::OnLoadSpellCustomAttr` (`src/server/coa/AscensionBloodmageTalents.cpp`): clear `802496`
  `Effects[EFFECT_2]` (`Effect = 0`, `ApplyAuraName = SPELL_AURA_NONE`), set
  `Effects[EFFECT_0].RealPointsPerLevel = 0.0f` for `561303`, `803326`, and `803392`, and OR `0x00200000` into `560072`
  `Effects[EFFECT_1].SpellClassMask[1]` (with `ClientSpellPatches`). Chosen: zero shared engine edits and exact mirror
  of `SPELL_CRIMSON_EXPEDITION` (`AscensionBloodmageTalents.cpp:1721-1724`).
- Edit `SpellInfo::CalcValue` globally. Rejected: affects non-Bloodmage spells.

## Decision

In `src/server/coa/AscensionBloodmageTalents.cpp` (`bloodmage_talent_contracts::OnLoadSpellCustomAttr`):

1. Clear `Effects[EFFECT_2].Effect` and `Effects[EFFECT_2].ApplyAuraName` on `802496` when it is
   `SPELL_AURA_MOD_DAMAGE_PERCENT_DONE`.
2. Set `Effects[EFFECT_0].RealPointsPerLevel = 0.0f;` on `561303`, `803326`, and `803392`.
3. Add `0x00200000` (`800775`) to `560072` `Effects[EFFECT_1].SpellClassMask[1]` and register `560072` in
   `ClientSpellPatches`.

## Consequences

- Sanguine Rupture `800775` no longer receives the phantom `+5%` Shadow aura and receives Bloodwell Eruption's `+10%`
  crit chance (with `800775` `+0.35` SP and `803392` `+0.15 SP / +0.10 AP` provided in SQL by the sibling lot).
- Cursed Ground (`561303`), Blood Burst (`803326`), and Hematoma (`803392`) use their displayed `$m1` base values per
  `O-37`.
- Build and gameplay verification run in the coordinator's post-merge verification pass for Lots 1–3.
