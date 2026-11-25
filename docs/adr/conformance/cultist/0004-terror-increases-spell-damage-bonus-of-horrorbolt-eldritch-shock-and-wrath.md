# 0004. Terror increases the spell damage bonus of Horrorbolt, Eldritch Shock, and Wrath of the Black Empire

- Status: accepted
- Date: 2026-11-25

## Context

Terror `300304` (server `Spell.dbc`, `Description[enUS]`): "Increases the spell damage bonus of Horrorbolt and Eldritch
Shock by $s2% and Wrath of the Empire by $s1%."

In server `Spell.dbc` (`4e4ed9ba1c2e`, `SpellFamilyName = 31`), `300304` carries two `SPELL_AURA_ADD_PCT_MODIFIER`
(`108`) effects on `EffectMiscValue = 24` (`SPELLMOD_BONUS_MULTIPLIER`):

- `Effect[0]`: `BasePoints = 19`, `DieSides = 1` (`$s1 = 20`), `EffectSpellClassMask[0..2] = [0, 32, 0]`, matching Wrath
  of the Black Empire (`800413`, `502166..502172`, `504904`; `SpellFamilyFlags = [0, 288, 0]`, `sp = 1.0f` in
  `AscensionCultistData.h`).
- `Effect[1]`: `BasePoints = 9`, `DieSides = 1` (`$s2 = 10`), `EffectSpellClassMask[3..5] = [0, 16, 524288]`, matching
  Horrorbolt (`800416`, `502173..502184`; `SpellFamilyFlags = [0, 16, 256]`, `sp = 0.71f` on Rank 1 and `0.714f` on
  Ranks 2-13) and Eldritch Shock damage (`808043..808045`; `SpellFamilyFlags = [0, 0, 524288]`, `sp = 0.4641f`).

Pending world SQL `rev_20260909_12_cultist_completion.sql` sets `spell_bonus_data` to `(0, 0, 0, 0)` for all ranks of
Horrorbolt, Wrath of the Black Empire, and Eldritch Shock so their spell power coefficients resolve in
`cultist_scaling::ModifySpellEffectBaseValue` (`src/server/coa/AscensionCultistContracts.cpp:277-292`). Because
`bonus->direct_damage == 0.0f`, `Unit::SpellDamageBonusDone` (`src/server/game/Entities/Unit/Unit.cpp:9951-9994`) skips
`modOwner->ApplySpellMod(spellProto->Id, SPELLMOD_BONUS_MULTIPLIER, coeff)` at `:9989`, and
`cultist_scaling::ModifySpellEffectBaseValue` added `row.sp * SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW)`
without applying `SPELLMOD_BONUS_MULTIPLIER`.

Conformance pair `prove-batchB-v3` (`20261124-195806` / `20261124-195848`, server build `0df5d16b6e6c`, commit
`1f991106edcf`) at `+50000` spell power measured `+0.017%` / `-0.027%` on Horrorbolt `502182` (expected `+10%`),
`-0.002%` / `+0.005%` on Eldritch Shock `808043` (expected `+10%`), and `-0.013%` / `-0.001%` on Wrath of the Black
Empire `502172` (expected `+20%`). Video `q742IyqxrV0` (2026-09-17) carries the exact `Spell.dbc` tooltip text; older
`bindmysoul` / `coabuildhub` snapshots show `+10%` Horrorbolt and `+20%` Wrath before Eldritch Shock was added.

## Options

- Apply `player->ApplySpellMod(info->Id, SPELLMOD_BONUS_MULTIPLIER, percent)` to `sp * 100.0f` in
  `cultist_scaling::ModifySpellEffectBaseValue` when `Any(info, {800416, 800413, 808043, 808044, 808045})`, matching
  `AscensionPyromancerContracts.cpp:220-225` and `Unit.cpp:9988-9990`. Chosen.
- Apply `SPELLMOD_BONUS_MULTIPLIER` unconditionally across every row in `CultistCoefficients`. Rejected: `504719`
  Horrorbolt Volley shares `SpellFamilyFlags = [0, 16, 256]` with Horrorbolt without being named by `300304`, and
  unobtainable `Spell.dbc` passives (`500722`, `300283`, `560703`) carry `MiscValue = 24` masks on other rows.

## Decision

In `cultist_scaling::ModifySpellEffectBaseValue` (`src/server/coa/AscensionCultistContracts.cpp`), when
`Any(info, {800416, 800413, 808043, 808044, 808045})`, scale `sp` through `percent = sp * 100.0f`,
`player->ApplySpellMod(info->Id, SPELLMOD_BONUS_MULTIPLIER, percent)`, `sp = percent / 100.0f`. No shared file, SQL,
DBC, or client text changes.

## Consequences

- With `300304` learned, `sp` increases by `+10%` on all 13 ranks of Horrorbolt (`800416`, `502173..502184`) and all 3
  damage ranks of Eldritch Shock (`808043..808045`), and by `+20%` on all 9 ranks of Wrath of the Black Empire
  (`800413`, `502166..502172`, `504904`).
- `300304` is the only `SPELLMOD_BONUS_MULTIPLIER` modifier in `Spell.dbc` and `SpellAffect.dbc` matching those 25
  spell IDs, so without `300304` learned their damage is unchanged. `504719` Horrorbolt Volley and all other
  `CultistCoefficients` rows are untouched.
- Regressions (counted pair `20261125-005701` / `20261125-005728`, build `ce353aa8ee31`):
  - `300304 behaviour_hit_ratio horrorbolt_sp` (`502182` at `+50000` SP): `+9.84%` (`44680.9` vs `40679.3`) and `+9.83%`
    (`44678.1` vs `40680.8`) against expected `+10%`, unlearned control unchanged.
  - `300304 behaviour_hit_ratio eldritch_shock_sp` (`808043` at `+50000` SP): `+9.86%` (`28985.2` vs `26384.8`) and
    `+9.85%` (`28983.6` vs `26385.8`) against expected `+10%`, unlearned control unchanged.
  - `300304 behaviour_hit_ratio wrath_sp` (`502172` at `+50000` SP): `+19.65%` (`68117.9` vs `56931.6`) and `+19.71%`
    (`68133.1` vs `56915.1`) against expected `+20%`, unlearned control unchanged.
