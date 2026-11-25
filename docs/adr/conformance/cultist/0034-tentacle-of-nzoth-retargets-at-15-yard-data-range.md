# 0034. Tentacle of N'Zoth retargets at its 15-yard data range

- Status: accepted (owner ruling O-20, 2026-11-25)
- Date: 2026-11-25

## Context

Tentacle of N'Zoth `572103` (server `Spell.dbc`, `/srv/coa/server-data/dbc`, sha256 `4e4ed9ba1c2e...`,
`SpellFamilyName` 31, `Description[enUS]`):

> "Target an enemy and summon a Tentacle of N'Zoth on the ground near them that will silence them and deal
> `${$806596m2+$806596ppl2+$SP*.75}` Shadow damage every `$806596t2` sec for `$806596d`. If your target runs out of
> range, the tentacle will seek a new target. The tentacle gains health based on your Stamina. If the tentacle dies,
> the silence effect will end. You may only have 1 Old God Tentacle active at a time."

Effective `Spell.dbc` and `pending_db_world` data:

- `572103` (`Tentacle of N'Zoth`): `RangeIndex = 11` (`SpellRange[11]`: `RangeMin[0..1] = 0.0`,
  `RangeMax[0..1] = 15.0 yd`, `"Fifteen yards"`), `DurationIndex = 31` (`8000 ms`), `Effect[0] = SPELL_EFFECT_SUMMON`
  (28), `MiscValue = 501464`, `MiscValueB = 63` (`SUMMON_TYPE_TOTEM`), `EffectRadiusIndex[0] = 8` (`5.0 yd`).
- `806596` (`Thoughtseize`, exact twin `289151`): `RangeIndex = 11` (`15.0 yd`), `DurationIndex = 31` (`8000 ms`),
  `AttributesEx = 16388` (`SPELL_ATTR1_IS_CHANNELED | SPELL_ATTR1_TRACK_TARGET_IN_CHANNEL`), `Effect[0] = MOD_SILENCE`
  (27), `Effect[1] = PERIODIC_DAMAGE` (3, `Amplitude = 2000 ms`).
- `pending_db_world/rev_20260909_12_cultist_completion.sql`: binds `spell_ascension_cultist_ability` to `572103`,
  registers `creature_template` `501464` (`npc_ascension_cultist_summon`, display `28813` scale `0.5`, combat reach
  `0.75 yd` at runtime), and carries no range override on `572103` or `806596`.

Before this fix, `src/server/coa/AscensionCultistSummons.cpp` resolved targets for `501464` through the generic
`npc_ascension_cultist_summon::Target(Player*)` helper (`:220-239`), which hardcoded `me->IsWithinDistInMap(unit, 40)`
(`:226`) for keeping/accepting a target and `Nearby(me, 30)` (`:235`) for picking a replacement. `git log -L` traced
both numbers to initial implementation `e36bc50aad` (2026-09-10) as generic summon defaults.

Measured before the fix (`cu-te1`, `prove-pair-fix`, runs `20261125-121749` and `20261125-121820`, build
`d8eae35950ba`, 0 flips, clear-LOS south `-y` axis with `dummy` alive and `line_of_sight = true` at every check):

- Control (`-9 yd`): `13.41 yd` / `8.55 yd`, `area1 806596 = 0`.
- Near treatment (`-22 yd`): `21.21 yd` / `20.67 yd` (`> 15 yd`, `< 40 yd`), `area1` at `10.47 yd` / `7.80 yd`,
  `area1 806596 = 0` (**alert** in both runs).
- Far treatment (`-50 yd`): `47.59 yd` / `49.72 yd` (`> 40 yd`), `area1 806596 = 1`.

Live evidence: none found on retargeting distance (`ev1.md` has no `572103`; `ev2.md` Q-cu-32 examined 3 live
tentacles in log 67 for tick count only and confirmed the archived `"15 yd range"` tooltip header and identical
retargeting sentence).

Owner ruling `O-20` (2026-11-25): align Tentacle of N'Zoth's retargeting with its 15-yard game-data range, reading
both the drop-target and pick-target thresholds from the spell data at runtime rather than hardcoding numbers.

## Options

- Read `Thoughtseize` (`806596`)'s range at runtime from `sSpellMgr->GetSpellInfo(Thoughtseize)->GetMaxRange(false, me)`
  (`15.0 yd` from `SpellRange[11]`), pass it as both `keepRange` and `searchRange` into `Target(player, keepRange,
  searchRange)` exclusively for `entry == 501464`, and dispatch `entry == 501464` in `UpdateAI` directly to
  `ApplyThoughtseize(player)` before the generic `Target(player)` call. Chosen.
- Hardcode `15.0f` inside `Target(player)` for `entry == 501464`. Rejected: contradicts the ruling to read the range
  from spell data at runtime and duplicates `SpellRange[11]`.
- Change the generic `40` / `30` defaults of `Target(player)` for all Cultist summons. Rejected: other summons
  sharing `Target(player)` carry distinct tooltips and spell ranges (`801151` Mental Assault `30 yd`, `573311`
  Eldritch Command `40 yd`, `802046` Tentacle of Y'shaarj `10 yd` cone, `500707` Eldritch Tentacle `100 yd` /
  `803037` Presence of N'Zoth `Self`), and none carry an out-of-range retargeting clause.

## Decision

In `src/server/coa/AscensionCultistSummons.cpp` (`npc_ascension_cultist_summon`):

1. Add `float ThoughtseizeRange() const` returning `info ? info->GetMaxRange(false, me) : 0.0f` for `Thoughtseize`
   (`806596`, `RangeIndex = 11` -> `15.0f`).
2. Parameterize `Target(Player* player, float keepRange = 40.0f, float searchRange = 30.0f)` so `valid` checks
   `me->IsWithinDistInMap(unit, keepRange)` and the fallback scan calls `Nearby(me, searchRange)`. All other callers
   retain the `40.0f` / `30.0f` defaults unchanged, including `DoAction(2)` (Eldritch Command `573311`, `40 yd`).
3. In `ApplyThoughtseize(Player* player)`, when `me->GetEntry() == 501464`, resolve the target via
   `Target(player, range, range)` where `range = ThoughtseizeRange()`.
4. In `UpdateAI`, dispatch `if (entry == 501464) { ApplyThoughtseize(player); return; }` before the generic
   `Target(player)` call so `501464` does not query or face targets using the `40` / `30 yd` defaults.

Range measurement and boundary semantics: the tentacle (`501464`) is the caster of `Thoughtseize` (`806596`), so range
is measured from the tentacle (`me`) to the candidate target via `me->IsWithinDistInMap(unit, range)` and
`Nearby(me, range)` (`AnyUnitInObjectRangeCheck` -> `IsWithinDistInMap`). Because `WorldObject::_IsWithinDist` adds
`GetObjectSize() + obj->GetObjectSize()` (`UNIT_FIELD_COMBATREACH`), this matches `Unit::IsWithinCombatRange` and
AzerothCore's channeled-spell check (`Spell.cpp:3506`). Measured against fixture Harvest Golem (`36`, combat reach
`1.275 yd`) with `501464` (`owned_creature_combat_reach = 0.75 yd`), the effective center-to-center boundary is
`15.0 + 0.75 + 1.275 = 17.025 yd`.

No shared engine, DBC, SQL, or client text changes.

## Consequences

- `Tentacle of N'Zoth` (`572103`, creature `501464`) drops its initial target and scans for a new combat target using
  `Thoughtseize` (`806596`)'s runtime `SpellRange` (`15.0 yd` + combat reach) measured from the tentacle.
- **No-other-target observation (tooltip silent):** `572103`'s tooltip states only `"If your target runs out of range,
  the tentacle will seek a new target"` and is silent on what happens when no other target is in range. Exploratory
  probe `20261125-124842` (build `a17a35612e2e`, `dummy` moving `-22 yd` south with clear LOS and `alive = 1`) observed:
  - With no other enemy in range (`dummy` at `23.10 yd`): `501464` remains alive through its `6000 ms` pulse
    (`owned_creature_count = 1` at `6800 ms`, despawning to `0` by `9800 ms`) and does not prematurely remove the
    original target's already-applied `806596` aura (`1` at `6800 ms`, `0` after expiry).
  - With a second enemy `area1` engaged in combat at `24.19 yd` (`> 17.025 yd`, inside the former `30 yd` `Nearby`
    scan): `area1` stays at `aura 806596 = 0` (`dummy` at `22.75 yd`), confirming the replacement scan also enforces
    the `15 yd` data range.
- **Other summons sharing `Target(player)` (observations, unchanged):**
  - `500464` (Presence of N'Zoth `803037` `RangeIndex 1 = Self`, Eldritch Tentacle `500707` `RangeIndex 6 = 100 yd`)
    shares `ApplyThoughtseize` (`806596`, `RangeIndex 11 = 15 yd`) and `Target(player)` (`40` / `30 yd`). Its tooltips
    say `"attack a nearby enemy"` / `"attack nearby enemies"` with no out-of-range retarget clause; left unchanged and
    recorded here as an observation.
  - `50272` (Tentacle of C'Thun `801153`, Mental Assault `801151` `30 yd`), `50096` (Tentacle of Y'shaarj `802044`,
    slam `802046` `10 yd` cone), `500465` (Tentacle of Yogg-Saron `802042`, aura `802045` `15 yd`), `533030` (Void
    Portal `301988`, `30 yd` spells), `397771` (Manifestation of Y'shaarj `680573`, melee), and `DoAction(2)`
    (Eldritch Command `573311`, `40 yd`) remain unchanged.
- **Regressions (build `a17a35612e2e`, `14e3fe0b257e+`):**
  - `572103` counted pair (`cu-fix5-prove-572103`, runs `20261125-124949` and `20261125-125018`, `12/12 ok` both runs,
    `0` flips, all 5 rows `behaviour` in `fragment.json`):
    - `572103 retarget_out_of_range` (`summon_retarget_out_of_range`, unchanged geometry: control `-9 yd`, near
      `-22 yd`, far `-50 yd`, `max_range_yd = secondary_max_range_yd = 15.0`, clear LOS, `dummy` alive):
      - Run 1: control `9.88 yd` (`area1 = 0`), near `22.13 yd` (`area1 = 1` at `10.19 yd`), far `50.03 yd`
        (`area1 = 1` at `7.11 yd`), `ok`.
      - Run 2: control `6.73 yd` (`area1 = 0`), near `25.76 yd` (`area1 = 1` at `8.46 yd`), far `52.50 yd`
        (`area1 = 1` at `6.41 yd`), `ok`.
    - ADR 0016 four-tick checks intact: `damage_base` `532.0` / `528.0` (4 ticks), `damage_sp` `3888.0` / `3896.0`
      (4 ticks), `presence_eternal_grasp_expiry` `ok`/`ok`, all other `572103` entries `ok`/`ok`.
  - Tight inside-range probes (`20261125-124842` at `12.14 yd` and `20261125-125841` at `13.72 yd`, clear LOS,
    `alive = 1`, `area1` in combat at `6.97 yd` / `8.43 yd`): kept `dummy` (`area1 806596 = 0`). Because `572103`
    (`EffectRadiusIndex 8 = 5.0 yd`) summons `501464` randomly within `5 yd` of `dummy`, `control_move_dy = -9.0`
    (`4..14 yd <= 15.0 yd`) remains the tightest non-flaky control offset for `summon_retarget_out_of_range`.
  - Shared-summon counted pair (`cu-fix5-prove-shared`, runs `20261125-125217` and `20261125-125509`, 15 spells:
    `802044`, `802048`, `706187`, `802728`, `560321`, `520405`, `704878`, `704879`, `302015`, `681425`, `560715`,
    `706911`, `301200`, `301068`, `560301`): `61/61 ok` in both runs (`112` scenarios/run, `0` flips).
  - Existing `*nzoth*` / `*tentacle*` gameplay scenarios (`20261125-125753`): `13/13 passed` (`VERIFY ALL: PASSED`).
- Ledger row 206 (`apps/coa-gameplay-test/conformance/classes/cultist_clauses.json`) updated with its proved reason.
- No other class is reached.
