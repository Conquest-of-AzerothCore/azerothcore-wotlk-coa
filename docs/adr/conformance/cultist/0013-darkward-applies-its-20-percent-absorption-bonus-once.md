# 0013. Darkward applies its 20% absorption bonus once

- Status: accepted (provisional number, numbered at merge; owner ruling O-12 Q-cu-7, 2026-11-24)
- Date: 2026-11-25

## Context

Darkward 706181 (rank 2, server `Spell.dbc`, `SpellFamilyName` 31, `Description[enUS]`): "Increases the effectiveness
of your damage absorption effects by `$s1%`."

Server `Spell.dbc` defines 706181 with two active bonuses of +20% each:

- `Effect[0]`: aura 317 `SPELL_AURA_ASCENSION_MOD_ABSORB_AMOUNT_PCT`, BasePoints 19 with DieSides 1 (`$s1` = 20),
  MiscValue 127, unrestricted `EffectSpellClassMask` `[0, 0, 0]`. In `AuraEffect::CalculateAmount`
  (`SpellAuraEffects.cpp:639-657`), every `SpellFamilyName` 31 `SPELL_AURA_SCHOOL_ABSORB` (69) or
  `SPELL_AURA_MANA_SHIELD` (36) aura with `amount > 0` cast by a `CLASS_CULTIST` player is multiplied by the caster's
  aura 317 multiplier.
- `Effect[1]`: aura 108 `SPELL_AURA_ADD_PCT_MODIFIER`, `SPELLMOD_ALL_EFFECTS` (+20%) on `EffectSpellClassMask[3..5]` =
  `[0, 536870912, 67371008]`, applied beforehand in `Unit::CalculateSpellDamage` (`Unit.cpp:12986`).

Both paths stacked multiplicatively (`1.20 * 1.20 = 1.44x`) on spells matched by `Effect[1]`. Conformance pair
`20261124-184802` / `20261124-185021` (`cu-g1`, build `aa4bb0bc3311`, `Spell.dbc` `4e4ed9ba`) measured Void Shield
578115 absorbed damage at 811 / 803 before learning 706181 and 1100 / 1100 after (capped by a single 1100 Holy strike;
underlying 1.44x shield `[1117, 1195]`) against the expected `[931, 996]`.

The project owner ruled (`O-12` `Q-cu-7`, 2026-11-24): fix the server so the absorption bonus applies once (+20%),
matching Felsworn ADR 0025.

## Options

- Neutralize `Effect[1]` (`dummy(1)`) on 706181 in `AscensionCultist::ApplyContracts` and keep `Effect[0]` (aura 317).
- Neutralize `Effect[0]` (aura 317) instead. Rejected: `Effect[1]`'s class mask reaches only Void Shield, Forbidden
  Ritual, and Dark Veil; neutralizing aura 317 would strip Darkward's +20% bonus from Dreadnought (`567524`,
  `567548`-`567552`, `flags[2]` = 8192) and Twilight Guardian (`850002`, `flags` = `[0, 0, 0]`) and would not scale
  stat/spell-power coefficients added after `CalculateSpellDamage`.
- Edit `Spell.dbc` or SQL. Rejected: shipped DBC files stay untouched and Cultist spell contracts live in
  `AscensionCultistContracts.cpp`.

## Decision

`AscensionCultist::ApplyContracts` (`src/server/coa/AscensionCultistContracts.cpp`), keyed to spell id 706181, sets
`Effect[1]` to `SPELL_AURA_DUMMY` (`dummy(1)`). `Effect[0]` (aura 317) is unchanged. No shared file, DBC, SQL, or
client text changes.

## Consequences

- Every Cultist damage absorption family in `Spell.dbc` (`CultistShields` in `AscensionCultistData.h:134`) receives
  +20% once via `Effect[0]` (aura 317):
  1. *Void Shield* (`500715`, `502244`-`502247`, `806745`, `578114`, `578115`).
  2. *Forbidden Ritual* (`800105`, `502267`-`502275`, self and raid allies).
  3. *Dark Veil* (`520345` -> `520346`, Effect[0] ally shield and Effect[1] caster shield; deprecated non-absorb
     `C'Thun's Blade` `500735` / `555707`-`555714` on `flags[2]` = `67108864` also loses the stray `Effect[1]` bit).
  4. *Dreadnought* (`680750` -> `567524`, `567548`-`567552`).
  5. *Twilight Guardian* (`704889` -> `850002` on *Twilight Shieldtoss* `524876`-`572141`).
- Cheat-death sentinel `582591` *Embrace the Void* (`amount = -1` in `AscensionCultistAuras.cpp:119`) and enemy heal
  absorb `807854` *Rift* (aura 301) remain unaffected; `shared_with` is empty.
- Existing scenarios (`20261125-014334`: `cultist-darkward`, `cultist-twilight-guardian-shield-stack-12632`,
  `cultist-tales-of-woe-dark-veil`, `cultist-4929-dreadnought-suppresses-madness`) passed 4/4, and existing `582308`,
  `502273`, and `301182` conformance entries were unchanged in `20261125-015755` and `20261125-015825`.
- Regressions (`20261125-015755` and `20261125-015825`, build `27b393bb403c`, 16/16 ok, 0 flips): `706181 absorb` (Void
  Shield 981 / 993 in `[931, 996]`), `706181 absorb_ritual` (Forbidden Ritual 1245 / 1221 in `[1183, 1293]`),
  `706181 absorb_dark_veil` (Dark Veil caster 1162 / 1162), `706181 absorb_dark_veil_ally` (Dark Veil ally health 9208 /
  9208 vs 9015 control), `706181 absorb_dreadnought` (Dreadnought 3169 / 3169 vs 2641 control), and
  `704889 darkward_absorb` (Twilight Guardian absorb/damage ratio 1.1997 / 1.1999 vs 1.0000 control).

## Observation

`706180` (*Darkward* rank 1, +10%) sits in `TalentTab` 0 (not in `CharacterAdvancement.dbc`, `class_spells(25)`, or
`cultist_clauses.json`) with the same `Effect[0]` aura 317 + `Effect[1]` `SPELLMOD_ALL_EFFECTS` pair; left untouched as
outside the Cultist spell set and dispatch scope.
