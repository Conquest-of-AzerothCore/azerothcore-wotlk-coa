# 0012. Obliteration Beam deals 20% more damage above 60 Insanity

- Status: accepted (provisional number, numbered at merge; owner ruling O-12 Q-cu-6, 2026-11-24)
- Date: 2026-11-25

## Context

Obliteration Beam 806897 (rank 7, server `Spell.dbc`, `SpellFamilyName` 31, `SpellFamilyFlags` `[8, 0, 0]`,
`Description[enUS]`): "Generates 10 Insanity. Unleash a beam of eldritch energy, dealing `${$m1+0+$sps*.65}` Shadow
damage to an enemy and all nearby enemies. While above 60 Insanity, deals `$573315s2%` more damage." Ranks 1-6
(`805572`, `807969`, `806893`-`806896`) carry the same sentence and all trigger damage spell 805573 (`SpellFamilyName`
31, `SpellFamilyFlags` `[131072, 0, 0]`, `Effect[0]` `SPELL_EFFECT_SCHOOL_DAMAGE` Shadow).

`AscensionCultist::Refresh` (`AscensionCultist.cpp:288`) maintains helper aura 573315 (*60 Insanity Aura*) via
`SetHelper(player, 573315, stacks > 60)`. Server `Spell.dbc` defines 573315 with Effect[0] aura 108 `SPELLMOD_COST`
(-100% on `EffectSpellClassMask[0..2]` = `[32, 0, 0]`) and Effect[1] aura 108 `SPELLMOD_DAMAGE` (+20% on
`EffectSpellClassMask[3..5]` = `[8192, 0, 0]`). Across `SpellFamilyName` 31, bit 8192 matches only 567530 (*Dreadnought
Prevented*, a zero-damage dummy marker) and matches neither 806897 (`[8, 0, 0]`) nor 805573 (`[131072, 0, 0]`).

Pre-fix conformance runs (`cu-a2`, and live pre-fix aura-probe runs `20261125-011318` and `20261125-011505` on
`cultist-806897-aura573315-probe.json`) confirmed that at 60 Insanity `aura` 573315 = 0 (damage 798) and at 61 Insanity
`aura` 573315 = 1 on the caster at the cast while 805573 still dealt 798 against the expected 958 (`floor(713 * 1.12 *
1.20)`). The `coabuildhub` snapshot renders 805572 with the same 20% sentence.

The project owner ruled (`O-12` `Q-cu-6`, 2026-11-24): fix the server so the 20% damage bonus applies once 573315 is
verified present on the caster above 60 Insanity.

## Options

- Set `Effect[1].SpellClassMask` of 573315 to `flag96(131072, 0, 0)` in `AscensionCultist::ApplyContracts`, matching
  triggered damage spell 805573 (the mask Abyssal Destruction 300605 already uses).
- Put `[8, 0, 0]` (wrapper 806897) on `Effect[1].SpellClassMask`. Rejected: `Unit::SpellDamageBonusDone`
  (`Unit.cpp:11329`) evaluates `SPELLMOD_DAMAGE` against the damage spell 805573, whereas wrapper 806897 uses
  `SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE` (`Unit::CalculateSpellDamage`, which reads `SPELLMOD_ALL_EFFECTS`, not
  `SPELLMOD_DAMAGE`).
- Edit `Spell.dbc` or SQL. Rejected: shipped DBC files stay untouched and Cultist spell contracts live in
  `AscensionCultistContracts.cpp`.

## Decision

`AscensionCultist::ApplyContracts` (`src/server/coa/AscensionCultistContracts.cpp`), keyed to spell id 573315, sets
`info->Effects[1].SpellClassMask = flag96(131072, 0, 0)`. Effect[0] (`SPELLMOD_COST` on `[32, 0, 0]`) is unchanged. No
shared file, DBC, SQL, or client text changes.

## Consequences

- Triggered damage spell 805573 of all 7 Obliteration Beam ranks (`805572`, `807969`, `806893`-`806897`) deals 20% more
  damage while `573315` is active (Insanity > 60). Across all 1,215 `SpellFamilyName` 31 rows in `Spell.dbc`, bit
  131072 in `SpellFamilyFlags[0]` matches 805573 alone; dummy marker 567530 (`8192`) has no damage effects;
  `shared_with` is empty.
- Existing scenarios `cultist-abyssal-destruction-single-reduction` and `cultist-4346-tentacle-free-at-60-insanity`
  passed in `20261125-013708` (build `2e5b678f0506`), and existing `806897` entries (`insanity` 10, `damage_base` 798,
  `damage_sp` 15358, `area_nearby` 4) were unchanged in `20261125-013848` and `20261125-013916`.
- Regressions (`20261125-013848` and `20261125-013916`, build `2e5b678f0506`, 6/6 ok, 0 flips): `806897 above_60` (61
  Insanity, `before_trigger_reads` and `ally_arm` confirming `aura` 573315 = 1, 805573 damage = 958) and `806897 at_60`
  (60 Insanity boundary control, `before_trigger_reads` confirming `aura` 573315 = 0, 805573 damage = 798).

## Observation: Other Cultist "Above 60 Insanity" Spells

- `801153` *Tentacle of C'Thun* (and `flags[0]=32` summons `572103`, `572115`, `572302`, `572311`, `680559`): reached by
  `573315` Effect[0] (`[32, 0, 0]`) and `SpellInfo.cpp:3282`.
- `300270` *Mind Leak* (`681256`), `301181` *Rapid Incantations* (`572859`), `680555` *Void-Enhanced Shield*, `680574`
  *Shadowy Symbiosis*: no class mask; reach the caster via `CultistThresholds` / `AscensionCultist.cpp:272-289`.
- `527268` *Instilling Fear* (`573272`, mask `[262144, 262144, 1074266112]`): reaches *Netherstrike* (`806222`,
  `806825`-`806828`, `578263`), *Gaze of C'Thun* procs (`520332`, `520333`), and *Eldritch Shock* (`808043`-`808045`,
  `808050`-`808052`).
- `560502` *Wavering Hope* (`630891`, mask `[4, 16384, 0]`): reaches all *Gaze of C'Thun* (`500110`, `502135`-`502143`)
  and *Twilight Shieldtoss* (`524876`, `804208`, `503487`-`503488`, `572715`, `572140`-`572141`) ranks.
- Non-ledger `TalentTab` 0 spells (`301979` *Dark Gaze*, `502125`-`502132` *Eldritch Smite of C'thun*, `573428` *Wave of
  Anger*) are not in `class_spells(25)`.
