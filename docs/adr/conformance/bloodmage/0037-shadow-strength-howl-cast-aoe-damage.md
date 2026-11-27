# 0037. Shadow Strength deals AoE Shadow damage on Howl casts

- Status: accepted (Bloodmage conformance fix wave S-25c / O-11, 2026-11-26)
- Date: 2026-11-26

## Context

From server `Spell.dbc` (`/srv/coa/server-data/dbc`, `Description[enUS]`):
- Shadow Strength `801960` (confirmed matching 2026-09-01 client archive `q742IyqxrV0.csv` `t=11:24`): "Casting |cffffffffHowl|r spells now deal ${$536277m1+$536277ppl1+$STA*.25+$AGI*.25+$AP*.1} Shadow damage to all nearby enemies and triggering |cffffffffCall of the Darkwing|r now reduces the cooldown of all |cffffffffHowl|r spells by $/1000;556239S1 sec. Can only occur once per sec."
- `801960` only has two effects (`Effect[0]` -> `556239`, `Effect[1]` -> `556238`), both wired to the Call of the Darkwing cooldown reduction with its 1 sec ICD in `rev_20260920_49_bloodmage_shadow_strength_cooldowns.sql`. No effect slot or script triggered `536277` (`Effect[0] = SPELL_EFFECT_SCHOOL_DAMAGE`, `SchoolMask = 32`, `TargetA = 22 TARGET_SRC_CASTER`, `TargetB = 16 TARGET_UNIT_DEST_AREA_ENEMY`, `EffectRadiusIndex = 13` = `10 yd`).

Conformance check `801960 howl_shadow_damage` (`bloodmage.json [670]`) alerted (`0` damage vs expected `121..122` on Blood Howl `800782`), while `cd_*` and `icd_held`/`icd_reopen` (`[671..677]`) verified the Call of the Darkwing 1 sec ICD cooldown cut.

Scanning `Spell.dbc` for `SpellFamilyName == 26` and `SpellFamilyFlags[2] & (128 | 2048 | 131072)` yields every Howl spell (`500124, 501680..501686` Night Hunter's Howl, `800782` Blood Howl, `804207` Wicked Howl, `804811` Monstrous Howl, `806177` Shadow Howl) plus one non-Howl spell sharing bit `2048`: `800780` Blood Craving.

## Options

- Trigger `SPELL_SHADOW_STRENGTH_DAMAGE` (`536277`) in `bloodmage_secondary_casts::OnSpellCast` (`src/server/coa/AscensionBloodmageSecondary.cpp`) when `!spell->IsTriggered() && player->HasAura(SPELL_SHADOW_STRENGTH) && info->Id != SPELL_BLOOD_CRAVING && (info->SpellFamilyFlags[2] & (128u | 2048u | 131072u))`. Chosen: `Bloodmage(spell)` already guarantees `SpellFamilyName == 26`; excluding `800780` prevents Blood Craving from falsely triggering Howl damage; `536277` is triggered with `SpellFamilyFlags = [0, 0, 0]` so it cannot re-proc `800154` Grim Omen or `801960`'s own cooldown-reduction proc.
- Add a third synthetic effect slot to `801960` via `OnLoadSpellCustomAttr`. Rejected: `801960`'s single `spell_proc` row is bound to `Call of the Darkwing` (`801958`) at `FINISH` phase with `Cooldown = 1000`, incompatible with a `CAST`-phase Howl proc on the same aura.

## Decision

In `src/server/coa/AscensionBloodmageSecondary.cpp`:
- Add `SPELL_SHADOW_STRENGTH = 801960`, `SPELL_SHADOW_STRENGTH_DAMAGE = 536277`, and `SPELL_BLOOD_CRAVING = 800780` to `BloodmageSecondarySpells`.
- In `bloodmage_secondary_casts::OnSpellCast`, cast `SPELL_SHADOW_STRENGTH_DAMAGE` on `player` whenever `player->HasAura(SPELL_SHADOW_STRENGTH) && info->Id != SPELL_BLOOD_CRAVING && (info->SpellFamilyFlags[2] & (128u | 2048u | 131072u))`.

(The `0.25*STA + 0.25*AGI` base-value scaling and `0.10*AP` `spell_bonus_data` for `536277` live in the sibling fix-wave lots owning `AscensionBloodmageVitality.cpp` and coefficient SQL.)

## Consequences

- Casting any Bloodmage Howl spell with Shadow Strength (`801960`) learned triggers `536277` to damage nearby enemies within `10 yd`, while Blood Craving (`800780`) is excluded and `801960`'s Call of the Darkwing cooldown-reduction proc and 1 sec ICD remain unaffected.
- Verification targets (executed in the coordinator's merged fix-wave build per `O-8`): `801960 howl_shadow_damage` (`[670]`) and sibling `801960` checks (`[671..677]`).
