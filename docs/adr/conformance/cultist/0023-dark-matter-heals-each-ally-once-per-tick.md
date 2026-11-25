# 0023. Dark Matter heals each ally once per tick

- Status: accepted (provisional number, numbered at merge)
- Date: 2026-11-25

## Context

Dark Matter 806382 (server `Spell.dbc`, `SpellFamilyName` 31, `Description[enUS]`): "Channeling Satiate now heals all
allies within `$807219a1` yds for `${$807219m1+$807219ppl1+$bh*.2}` every `$807124T2` sec for `$807219d`."

Effective `Spell.dbc` and `pending_db_world` data:

- `807124` (driver aura cast when channeling Satiate `804275` with `806382` learned): `Effect[1]` periodic tick every
  `1000 ms` (`$807124T2`), converted to `SPELL_AURA_PERIODIC_DUMMY` in `AscensionCultistContracts.cpp:208-209`.
- `807219` (heal spell): `Effect[0]` `SPELL_EFFECT_HEAL` (10), `BasePoints = 64`, `DieSides = 1` (`65`),
  `RealPointsPerLevel = 5.5`, `BaseLevel = SpellLevel = 34` -> `208` at level 60 and 0 SP (`608` at +2000 SP with the
  `0.20f` healing coefficient in `AscensionCultistData.h:118`; `spell_bonus_data` zeroed in
  `rev_20260909_12_cultist_completion.sql:633`). `TargetA = TARGET_SRC_CASTER` (22),
  `TargetB = TARGET_UNIT_SRC_AREA_ALLY` (30), `EffectRadiusIndex = 10` (`30.0 yd`, `$807219a1`).

Because `807219` is already an area heal around the caster, the loop in `aura_ascension_cultist_lifecycle::Tick`
(`src/server/coa/AscensionCultistAuras.cpp:230-231`, since initial commit `e36bc50aad`, no rationale given):

```cpp
for (Unit* ally : Allies(player, player, Radius(807219)))
    Cast(player, ally, 807219);
```

cast the area spell once per unit returned by `Allies()` (which includes the caster plus every grouped friendly unit
in range), healing every ally in the 30 yd radius `N` times per tick. Conformance pair `cu-g7b` `prove-final`
(`20261124-214632` / `20261124-214705`, build `5115cdc4966c`, `Spell.dbc` `4e4ed9ba`) measured:

- `806382 heal_base` (`N = 2`: caster + 1 ally): `416` per tick (`2` heals, expected `208` / `1` heal).
- `806382 heal_sp` (`N = 2`, +2000 SP): `1216` per tick (`2` heals, expected `608` / `1` heal).
- `806382 period` (`N = 2`): `event_interval_median_ms = 0 ms` (simultaneous double heals, expected `1000 +- 50 ms`).
- `806382 radius` (`N = 3`: caster + ally at 28.5 yd + ally2 at 31.5 yd): `3` heals on inner ally (expected `1`), `0`
  on outer ally2.

Scope exclusion: the duration mismatch between "Channeling Satiate" (6 s `804275`), `807124` (8 s), and `$807219d`
(10 s) is an open owner question and is not touched by this change; `806382 duration` remains an alert as before.

## Options

- Replace the `Allies()` loop with a single `Cast(player, player, 807219)` per `807124` tick so `807219`'s native
  `TARGET_SRC_CASTER` + `TARGET_UNIT_SRC_AREA_ALLY` (30 yd) target selection heals each ally inside 30 yd once.
- Change `807219` to single-target in `AscensionCultistContracts.cpp` and keep the loop. Rejected: `Allies()` uses
  `AnyUnitInObjectRangeCheck` (30 yd + 3.0 yd combat reaches = 33.0 yd), whereas `807219` natively uses player-to-player
  30.0 yd area targeting, and calling the area spell once is simpler and matches the DBC spell contract.

## Decision

In `aura_ascension_cultist_lifecycle::Tick` (`src/server/coa/AscensionCultistAuras.cpp`), replace the `Allies()` loop
for `807124` with a single `Cast(player, player, 807219)`. No shared engine file, DBC, SQL, or client text changes.

## Consequences

- Every grouped ally within 30 yd of the Cultist is healed once per 1 s tick of Dark Matter (`208` at 0 SP, `608` at
  +2000 SP), regardless of group size; allies outside 30 yd are not healed.
- No other spell is reached: `807124` is cast only for Dark Matter `806382`, `807219` is cast nowhere else, and
  shared helpers `Allies()` and `Cast()` are untouched. Existing Satiate-related conformance entries for `524879`
  (5/5 ok) and `807877` (3/3 ok) were unchanged in `prove-D`.
- Regressions (`prove-D`, runs `20261125-052430` and `20261125-052506`, build `8ee67ea7a9b4`, 14/15 ok, 1/15 expected
  owner-question alert on `806382 duration`, 0 flips):
  - `806382 radius` (1 ally inside at 28.5 yd -> `1` heal, 1 outside at 31.5 yd -> `0` heals),
  - `806382 period` (`1001 ms` / `1003 ms` median interval),
  - `806382 heal_base` (`208` exact, `1` heal at 0 SP),
  - `806382 heal_sp` (`608` exact, `1` heal at +2000 SP),
  - `806382 heal_once_2_allies` (2 allies inside at 10 yd and 20 yd -> `1` heal each),
  - `806382 heal_once_3_allies` (3 allies inside at 10, 20, 28.5 yd -> `1` heal each; 4th outside at 31.5 yd -> `0`).
- Owner question preserved: `806382 duration` still alerts (`aura = 0` at 9509 ms, `5` single ticks vs `9 +- 1`
  expected for `$807219d = 10 s`).
