# 0024. Bloodmage family-26 EffectSpellClassMask corrections (Blood Plague, Gore Barrage, Eternal Curse, Dark Blood)

- Status: accepted (Bloodmage conformance Lot 2, 2026-11-26; provisional number)
- Date: 2026-11-26

## Context

Full bit-level audit of all `1,209` `SpellFamilyName = 26` records in `/srv/coa/server-data/dbc/Spell.dbc` identified four
Bloodmage passive/stance modifiers with incorrect or incomplete `EffectSpellClassMask` fields:

1. **Blood Plague `575335` (`Effect[0]` / `Effect[1]`)**: tooltip names `"Ravenous Strike and Claw Sweep"`. DBC mask
   `(0, 0x800001, 0)` wrongly included Bloodfang Bite / Crimson Maw (`0x800000`) and omitted Claw Sweep `(0, 0, 0x4000)`.
   Setting `flag96(0, 1, 16384)` matches solely Ravenous Strike R1–R10 and Claw Sweep R1–R8 (`18` spells, `0` false
   matches).
2. **Gore Barrage `807345` (`Effect[0]` `SPELLMOD_COST -30%`)**: tooltip names `"spells that cost health and Animated
   Blood"`. DBC mask `(0xD1140801, 0x88412001, 0x80210598)` missed `52` flagged `POWER_HEALTH` spells (Rotclaw, Dark
   Liturgy, Blood Veil, Vampyr's Kiss, Keleseth's Calamity, Darkfallen Lament, Infuse, Blood Howl, Monstrous Howl,
   Hemophobia, Hemal Excision, Gorge, Hematoma) and wrongly included `(1, 0x400000)` hitting Clotting `806214` (Rage).
   Setting `flag96(0xD1168841u, 0xA8012A05u, 0x90E315B8u)` matches `139` spells (`0` non-health spells with cost other
   than Animated Blood R1–R3).
3. **Eternal Curse Tank Stance Aura `807736` (`Effect[2]` `SPELLMOD_THREAT +50%`)**: tooltip names `"spells that cost
   health"`. DBC mask `(0x01010000, 0x201, 0x80200000)` missed `94` flagged `POWER_HEALTH` spells (including Hematoma
   `803392`, Bloodmoon Blast, Vampyr's Kiss, Dark Liturgy, Scarlet Delirium, Keleseth's Calamity, Valanar's Vengeance,
   Darkfallen Lament) and wrongly matched `(0, 0x10000)` (Apotheosis/Dark Feast Rage spells). Setting
   `flag96(0x91168840u, 0x88012A05u, 0x906311B0u)` matches all pure-health flagged bits plus Hemal Excision `(2, 0x20)`
   and Darkfallen Lament `(2, 0x1000)` (`119` spells; excludes mixed Rage-damage bits such as Blood Burst `(2, 0x8)`,
   Veinburst `(0, 0x100)`, Malediction `(0, 0x80)`, and Hemoburst `(2, 0x40000000)`).
4. **Dark Blood `804807` / `807919` (`Effect[0]` `SPELLMOD_COST -25% / -50%`)**: tooltip names `"abilities that require
   Cursed Form"`. DBC mask `(0x01000000, 0x900001, 0x04004889)` missed `33` flagged Cursed Form spells (Rotclaw, Reave,
   Blood Howl, Monstrous Howl, Aortic Assault, Terrify) and wrongly matched non-Cursed spells (`681304` Hemostasis,
   `806214` Clotting, `803326` Blood Burst). Setting `flag96(0x01400800u, 0x00800605u, 0x000A6880u)` matches `73` spells
   with `0` non-Cursed-Form spells that have a power cost.

## Options

- Override all four `EffectSpellClassMask` fields in `bloodmage_talent_contracts::OnLoadSpellCustomAttr`
  (`src/server/coa/AscensionBloodmageTalents.cpp`), registering `575335`, `807345`, `804807`, and `807919` in
  `ClientSpellPatches`. Chosen: exact bit-verified masks with zero shared engine edits and zero SQL changes.
- Add runtime hooks for every spell individually. Rejected: native `SPELLMOD_COST`, `SPELLMOD_THREAT`, and conditional
  crit handling already process `EffectSpellClassMask` directly for all flagged spells.

## Decision

Apply the four verified `flag96` masks in `bloodmage_talent_contracts::OnLoadSpellCustomAttr`
(`src/server/coa/AscensionBloodmageTalents.cpp`).

## Consequences

- Blood Plague boosts only Ravenous Strike and Claw Sweep (excluding Bloodfang Bite).
- Gore Barrage, Eternal Curse Tank Stance Aura, and Dark Blood cover all flagged qualifying family-26 spells without
  leaking onto non-qualifying Rage/Mortal-Form abilities.
- Flagless `(0, 0, 0)` spells (e.g., Bloodgale `681310`, Blood Bond `504627`, Enraging Wound `560589`) cannot be matched
  by `EffectSpellClassMask` alone and remain unaffected by mask-only updates.
- Build and gameplay verification run in the coordinator's post-merge verification pass for Lots 1–3.
