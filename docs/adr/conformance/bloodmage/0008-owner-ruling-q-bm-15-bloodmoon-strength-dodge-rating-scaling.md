# 0008. Owner ruling Q-bm-15 / O-11: Bloodmoon Strength scales with 0.25 of dodge rating

- Status: accepted (owner rulings Bloodmage Q-bm-15 / O-10 and O-11, 2026-11-26; provisional number)
- Date: 2026-11-26

## Context

Bloodmoon Strength `578120` (server `Spell.dbc`, Level 50 Passive, `Description[enUS]`): "Periodic damage dealt by
Rotclaw now hits $s1% more often and your Bloodfang Bite, Claw Sweep, and Bloodbolt additionally scales with dodge
rating."

Effective `Spell.dbc` and pre-fix server state (`ev1.md`, `batch4/bm-rh7`):

- `578120` `Effect[0]` accelerates Rotclaw ticks (`SPELLMOD_ACTIVATION_TIME -50%`, verified passing `994.5 -> 492.5 ms`),
  while `Effect[1]` periodically triggers `560480` (`Eternal - Level 50 Passive`, `SPELLMOD_EFFECT1` static `+1` flat
  modifier on `EffectSpellClassMask = [0, 8519680, 16384]`). No C++ code read `CR_DODGE` for `578120` or `560480`.
- Full `Spell.dbc` scan of `SpellFamilyName = 26` verifies that `(SpellFamilyFlags[1] & 0x820000) ||
  (SpellFamilyFlags[2] & 0x4000)` matches exactly `27` spells: all 10 Bloodfang Bite ranks (`800156`, `501695..501697`,
  `503613..503615`, `572549..572551`, `Effect[0] = SPELL_EFFECT_SCHOOL_DAMAGE`), Crimson Maw `803388` (Final Embrace
  replacement of Bloodfang Bite, `Effect[0] = SPELL_EFFECT_SCHOOL_DAMAGE`), all 8 Claw Sweep ranks (`500169`,
  `500436..500441`, `500444`, `Effect[0] = SPELL_EFFECT_SCHOOL_DAMAGE`), and all 8 Bloodbolt ranks (`804685`,
  `806928..806932`, `578304`, `578305`, `Effect[0] = SPELL_EFFECT_HEALTH_LEECH`), with zero unintended matches.
- Live evidence (`ev1.md`): `0` events for `578120`/`560480` across 186 logs; tooltip video archive `q742IyqxrV0`
  (`t=10:14`) matches the unfigured dodge-rating wording verbatim.

The project owner ruled (`Q-bm-15` in `O-10` and confirmed rate in `O-11`, 2026-11-26) to add `+0.25 * CR_DODGE` flat
damage scaling on Bloodfang Bite, Claw Sweep, and Bloodbolt.

## Options

- Add `0.25 * double(player->GetUInt32Value(PLAYER_FIELD_COMBAT_RATING_1 + CR_DODGE))` in
  `bloodmage_vitality_scaling::ModifySpellEffectBaseValue` (`src/server/coa/AscensionBloodmageVitality.cpp`), widening
  its effect guard to allow `SPELL_EFFECT_SCHOOL_DAMAGE` alongside `SPELL_EFFECT_HEAL` and `SPELL_EFFECT_HEALTH_LEECH`.
  Chosen: `SpellEffectInfo::CalcValue` (`SpellInfo.cpp:523`) invokes `ModifySpellEffectBaseValue` on `EFFECT_0` for all
  27 matching spells before AP/SP bonuses and mitigation, reflects live `CR_DODGE` immediately on gear/buff changes
  without waiting for `578120`'s 5-second periodic trigger of `560480`, and requires zero new SQL script bindings.
- Drive `560480` via an `AuraScript` + `PlayerScript` equip/update poller. Rejected: redundant with
  `ModifySpellEffectBaseValue` and risks stale values between periodic refreshes.

## Decision

In `bloodmage_vitality_scaling::ModifySpellEffectBaseValue` (`src/server/coa/AscensionBloodmageVitality.cpp`), allow
`SPELL_EFFECT_SCHOOL_DAMAGE` in addition to `SPELL_EFFECT_HEAL` and `SPELL_EFFECT_HEALTH_LEECH` on `EFFECT_0`, and when
`caster->HasAura(578120)` and `((info->SpellFamilyFlags[1] & 0x820000) || (info->SpellFamilyFlags[2] & 0x4000))`, add
`0.25 * double(caster->ToPlayer()->GetUInt32Value(PLAYER_FIELD_COMBAT_RATING_1 + CR_DODGE))` cumulatively to the effect
base value.

## Consequences

- Bloodfang Bite (`572551` chain + `803388` Crimson Maw), Claw Sweep (`500444` chain), and Bloodbolt (`578305` chain)
  gain `+0.25 * CR_DODGE` flat damage whenever the Bloodmage holds `578120` Bloodmoon Strength (`+250` at `1000` dodge
  rating).
- Note that DBC `560480` retains its native `+1` flat `SPELLMOD_EFFECT1`; no second dodge-rating script should be bound
  to `560480` to avoid double-dipping.
- Post-fix build and runtime verification of `578120` dodge-scaling assertions run after the fix-wave merge build (`O-8`).
