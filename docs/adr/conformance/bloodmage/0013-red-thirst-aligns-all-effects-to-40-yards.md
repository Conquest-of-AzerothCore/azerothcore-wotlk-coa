# 0013. Owner ruling Q-bm-20: Red Thirst aligns melee/ranged haste and Worn Out radius to 40 yards

- Status: accepted (owner ruling Bloodmage Q-bm-20 / O-10, 2026-11-26; provisional number)
- Date: 2026-11-26

## Context

Server `Spell.dbc` (`SpellFamilyName = 26`):

- Red Thirst `520493`: `"Enrage allies within $a1 yds, increasing haste by $s1% for $d. After being affected by this
  spell, allies cannot benefit from similar effects for $804457d."`
- `Effect[0]` (`SPELL_AURA_MOD_CASTING_SPEED_NOT_STACK`, `+30%`) has `EffectRadiusIndex[0] = 23` (`40.0 yd`).
- `Effect[1]` (`SPELL_AURA_MOD_MELEE_RANGED_HASTE`, `+30%`) and `Effect[2]` (`SPELL_EFFECT_TRIGGER_SPELL` `804457` Worn
  Out) carry `EffectRadiusIndex = 12` (`100.0 yd`), applying melee/ranged haste and the 5-minute Worn Out lockout to
  allies between `40 yd` and `100 yd` who did not receive the spell haste buff.

The owner ruled (`Q-bm-20` `align_40yd`, `O-10`): align `Effect[1]` and `Effect[2]` to `40 yd`.

## Options

- Copy `info->Effects[EFFECT_0].RadiusEntry` onto `Effects[EFFECT_1]` and `Effects[EFFECT_2]` inside
  `bloodmage_talent_contracts::OnLoadSpellCustomAttr` (`src/server/coa/AscensionBloodmageTalents.cpp`). Chosen: concise,
  class-scoped, uses the exact `SpellRadiusEntry const*` loaded from `SpellRadius.dbc` for `Effect[0]`.
- Edit DBC directly. Rejected: server DBC files are not edited in git.

## Decision

In `src/server/coa/AscensionBloodmageTalents.cpp` (`bloodmage_talent_contracts::OnLoadSpellCustomAttr`), for `info->Id ==
520493`, set `info->Effects[EFFECT_1].RadiusEntry = info->Effects[EFFECT_0].RadiusEntry;` and
`info->Effects[EFFECT_2].RadiusEntry = info->Effects[EFFECT_0].RadiusEntry;`.

## Consequences

- All three Red Thirst effects (spell haste, melee/ranged haste, and Worn Out `804457`) share the `40 yd` radius named
  in the tooltip (`$a1`).
- Build and gameplay verification run in the coordinator's post-merge verification pass for Lots 1–3.
