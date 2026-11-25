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

Effective `Spell.dbc` and SQL data:

- `572103` (`Tentacle of N'Zoth`): `RangeIndex = 11` (`SpellRange[11]`: `RangeMin[0..1] = 0.0`,
  `RangeMax[0..1] = 15.0 yd`, `"Fifteen yards"`), `DurationIndex = 31` (`8000 ms`), `Effect[0] = SPELL_EFFECT_SUMMON`
  (28), `MiscValue = 501464`, `MiscValueB = 63` (`SUMMON_TYPE_TOTEM`), `EffectImplicitTargetA[0] = 6`
  (`TARGET_UNIT_TARGET_ENEMY`), `EffectImplicitTargetB[0] = 74` (`TARGET_DEST_TARGET_RANDOM`),
  `EffectRadiusIndex[0] = 8` (`SpellRadius[8] = 5.0 yd`).
- `806596` (`Thoughtseize`, exact twin `289151`): `RangeIndex = 11` (`15.0 yd`), `DurationIndex = 31` (`8000 ms`),
  `AttributesEx = 16388` (`SPELL_ATTR1_IS_CHANNELED | SPELL_ATTR1_TRACK_TARGET_IN_CHANNEL`), `Effect[0] = MOD_SILENCE`
  (27), `Effect[1] = PERIODIC_DAMAGE` (3, `Amplitude = 2000 ms`), `SpellFamilyFlags = [0, 0, 0]`.
- `pending_db_world/rev_20260909_12_cultist_completion.sql`: binds `spell_ascension_cultist_ability` to `572103`,
  registers `creature_template` `501464` (`npc_ascension_cultist_summon`) and `creature_template_model` (`DisplayID =
  28813`, `DisplayScale = 0.5`), and carries no range override on `572103` or `806596`.
- Combat-reach recomputation from data: `creature_model_info.sql:22752` has `(28813, 0, 0, ...)`, so `Creature.cpp:
  3854, 3873` / `ObjectMgr.cpp:1931` fall back to `DEFAULT_COMBAT_REACH = 1.5f` (`ObjectDefines.h:45`), giving
  `501464` a combat reach of `1.5 * 0.5 = 0.75 yd`. Fixture dummy Harvest Golem (`36`, `creature_template_model`
  `DisplayID = 367`, `DisplayScale = 1.0`, `creature_model_info.sql:259` `(367, 0.79645, 1.275, ...)`) has combat
  reach `1.275 yd`.

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

Range measurement, modifier ownership, and boundary semantics:

- `GetMaxRange(false, me)` (`SpellInfo.cpp:3078-3097`) reads `SpellRange[11].RangeMax[0]` (`15.0f`) and applies
  `SPELLMOD_RANGE` through `me->GetSpellModOwner()` (`Unit.cpp:14519-14524`), which returns the owning `Player*`
  linked by `me->SetOwnerGUID(owner)` (`AscensionCultistSummons.cpp:136`). On pure Cultist (class 25), no Cultist
  `SPELLMOD_RANGE` talent matches `806596` (`300302`/`301347` mask `[131148, 10747952, 0]` vs `806596` `[0, 0, 0]`;
  `805115` restricted at `SpellInfo.cpp:1622`), so `ThoughtseizeRange()` evaluates to `15.0f` unconditionally; on a
  classless realm, an unmasked `AscensionReach` talent (`SpellInfo.cpp:1591-1607`) would extend it.
- The tentacle (`501464`) is the caster of `Thoughtseize` (`806596`), so range is measured from the tentacle (`me`)
  to the candidate target via `me->IsWithinDistInMap(unit, range)` (`Object.cpp:1257-1265, 1382-1385, 2898-2901`) and
  `Nearby(me, range)` (`AscensionCultist.cpp:226-237` -> `AnyUnitInObjectRangeCheck`, `GridNotifiers.h:1067`). Both
  add `GetObjectSize() + obj->GetObjectSize()` (`UNIT_FIELD_COMBATREACH`), the same combat-reach sum used by
  `Unit::IsWithinCombatRange` (`Unit.cpp:900-914`). Against Harvest Golem (`36`, combat reach `1.275 yd`) with
  `501464` (`0.75 yd`), the effective centre-to-centre boundary is `15.0 + 0.75 + 1.275 = 17.025 yd`.
- Note on normal AzerothCore channels (`Spell.cpp:3474-3514`): `Spell::update` uses the same `IsWithinDistInMap`
  combat-reach sum, but additionally adds xinef's `std::min(3.0f, range * 0.1f)` (`+1.5 yd`, breaking at `18.525 yd`
  centre-to-centre) and immediately removes the aura via `unit->RemoveAura(aurApp)` (`:3509`). `501464` applies
  `806596` with `player->AddAura` instead of a native channel, so it enforces the exact `15.0 yd` (+ combat reach)
  threshold without the `+1.5 yd` channel tolerance and does not strip the previous target's aura (see Observations).

No shared engine, DBC, SQL, or client text changes.

## Consequences

- `Tentacle of N'Zoth` (`572103`, creature `501464`) drops its initial target and scans for a new combat target using
  `Thoughtseize` (`806596`)'s runtime `SpellRange` (`15.0 yd` + combat reach = `17.025 yd` centre-to-centre against
  Harvest Golem `36`) measured from the tentacle.
- **Observations (not decisions):**
  - **(a) Previous target keeps Thoughtseize after retargeting — dual-target affliction (open for owner ruling):**
    `ApplyThoughtseize` (`AscensionCultistSummons.cpp:192-208`) calls `player->AddAura(Thoughtseize, target)` without
    removing `806596` from previously afflicted targets when they leave range or when `Target()` picks a replacement.
    In the committed `retarget_out_of_range` pair (`20261125-132735` and `20261125-132804`), at `t = 6800 ms` (after
    the `6000 ms` retarget pulse), `dummy` at `19.62–22.25 yd` (near) and `50.73–52.70 yd` (far) still holds
    `primary_aura = 1` simultaneously while `area1` carries `secondary_aura = 1`. On natural `8000 ms` expiry, ADR
    0016's `ClearThoughtseize(ExpiryGrace())` (`:178-186, 406`) clears `area1`'s freshly applied aura (`~6000 ms >
    200 ms`) while sparing `dummy`'s `<= 200 ms` aura so `dummy` still takes its 4th Shadow tick out of range. This
    contrasts with `Spell.cpp:3506-3510`, where a real channel removes the aura immediately on range exit. **Status:
    open for an owner ruling** (whether to strip `806596` from an out-of-range target when dropped/retargeted, and
    whether range should be checked more often than every `6000 ms`). No regression assertion is added on this
    behaviour yet.
  - **(b) No other target in range:** When the primary target leaves range and no other combat target is within range
    (`Target()` returns `nullptr`), `501464` stays alive until its natural `8000 ms` despawn (`UpdateAI` `:324,
    356-360` checks only owner liveness, `100 yd`, and phase) and the previous target keeps its already-applied
    `806596` aura until expiry. The tooltip is silent on no-other-target behaviour.
  - **(c) Presence of N'Zoth / Eldritch Tentacle (`500464`) unchanged:** Creature `500464` (`803037` `RangeIndex 1 =
    Self`, `500707` `RangeIndex 6 = 100 yd`) calls the same `ApplyThoughtseize` (`806596`, `15 yd`) through
    `Target(player)` (`AscensionCultistSummons.cpp:196-197, 375-376`) and still uses the hardcoded `40` / `30 yd`
    defaults. Its tooltips say `"attack a nearby enemy"` / `"attack nearby enemies"` with no out-of-range retargeting
    sentence; left unchanged per O-20's single-spell scope and recorded here as an observation.
  - Other summons sharing `Target(player)` (`50272` Tentacle of C'Thun `801153` / `801151` `30 yd`, `50096` Tentacle
    of Y'shaarj `802044` / `802046` `10 yd` cone, `500465` Tentacle of Yogg-Saron `802042` / `802045` `15 yd`,
    `533030` Void Portal `301988` `30 yd`, `397771` Manifestation of Y'shaarj `680573` melee, and `DoAction(2)`
    Eldritch Command `573311` `40 yd`) remain unchanged.
- **Placement precision and `5.0 yd` spawn-disk limit:** `572103` (`TARGET_DEST_TARGET_RANDOM`, `SpellRadius[8] =
  5.0 yd`, `Spell.cpp:1791-1796`) spawns `501464` randomly inside a `5.0 yd` disk around `dummy` (observed initial
  `primary_dist` `0.60–4.71 yd`). Any fixed `dummy`-relative `move_point` displacement `D` therefore yields
  `primary_dist` in `[|D| - 5.0, |D| + 5.0]` (`±5.0 yd` uncertainty). Under `summon_retarget_out_of_range`:
  - Tightest non-flaky control is `control_move_dy = -10.0` (`[5.0..15.0] yd <= 15.0 yd` required by
    `summon_retarget_out_of_range.py:427`).
  - Tightest non-flaky near treatment is `near_move_dy = -22.5` (`[17.5..27.5] yd > 17.025 yd`, removing the
    theoretical `0.025 yd` crescent overlap at `-22.0`).
  - Because `[|D| - 5.0, |D| + 5.0]` has width `10.0 yd`, no fixed `dummy`-relative displacement can deterministically
    place `dummy` inside `(17.025, 22.025)` (width `5.0 yd`) to exclude a `20 yd` server (`22.025 yd` c2c) on every
    run, nor pin `15.5–16.0 yd` keep vs `18.0–18.5 yd` switch (Run 2 happened to land at `19.62 yd < 22.025 yd`,
    while Run 1 landed at `22.25 yd`). Deterministically closing `keepRange` below `20 yd` requires a summon-relative
    creature movement/relocation harness extension (`CoAGameplayTest.cpp:8337-8349` `relocate around_owner` supports
    `Player*` only, and `kinds/summon_edge.py:130` self-casts at `CASTER` only).
- **Regressions (committed entries only, build `a17a35612e2e`, `14e3fe0b257e+`):**
  - `572103` counted pair (`cu-fix5-review-prove-572103`, runs `20261125-132735` and `20261125-132804`, `14/14 ok`
    both runs, `0` flips, all 5 ledger rows `behaviour` in `fragment.json`):
    - `572103 retarget_out_of_range` (`summon_retarget_out_of_range`, south `-y` clear LOS: control `-10.0 yd`, near
      `-22.5 yd`, far `-50.0 yd`, `max_range_yd = secondary_max_range_yd = 15.0`, `dummy` alive):
      - Run 1 (`20261125-132735`): control `9.52 yd` (`area1 = 0` at `7.99 yd`), near `22.25 yd` (`area1 = 1` at
        `7.55 yd`, `primary_aura = 1`), far `52.70 yd` (`area1 = 1` at `3.96 yd`, `primary_aura = 1`), `ok`.
      - Run 2 (`20261125-132804`): control `9.86 yd` (`area1 = 0` at `5.31 yd`), near `19.62 yd` (`area1 = 1` at
        `9.82 yd`, `primary_aura = 1`), far `50.73 yd` (`area1 = 1` at `5.19 yd`, `primary_aura = 1`), `ok`.
    - `572103 search_inside_15yd` (`metric_delta`, control for replacement search: `dummy` at `(3.0, 0.0)` survives
      control at `500,000 HP` and dies at `4000 ms` in treatment via `after_target_health: 240`, `select_after =
      dummy` dead, `area1` engaged via `573028` at `(14.5, 0.0)` = `[6.5..16.5] yd < 17.025 yd` from `501464`):
      `area1 806596` `0 -> 1`, `dummy alive` `1 -> 0`, `501464 count` `1 -> 1`, `ok` in both runs.
    - `572103 search_beyond_15yd` (`metric_delta`, `15 yd` vs old `30 yd` replacement search: identical layout with
      `area1` at `(26.0, 0.0)` = `[18.0..28.0] yd` from `501464`, strictly `> 17.025 yd` and `< 32.025 yd`):
      `area1 806596` `0 -> 0`, `dummy alive` `1 -> 0`, `501464 count` `1 -> 1`, `ok` in both runs (a server using
      the old `30 yd` scan afflicts `area1` and alerts).
    - ADR 0016 four-tick checks intact: `damage_base` `540.0` / `528.0` (4 ticks), `damage_sp` `3884.0` / `3896.0`
      (4 ticks), `presence_eternal_grasp_expiry` `ok`/`ok`, all other `572103` entries `ok`/`ok`.
  - Shared-summon counted pair (`cu-fix5-prove-shared`, runs `20261125-125217` and `20261125-125509`, 15 spells:
    `802044`, `802048`, `706187`, `802728`, `560321`, `520405`, `704878`, `704879`, `302015`, `681425`, `560715`,
    `706911`, `301200`, `301068`, `560301`): `61/61 ok` in both runs (`112` scenarios/run, `0` flips).
  - Existing `*nzoth*` / `*tentacle*` gameplay scenarios (`20261125-125753`): `13/13 passed` (`VERIFY ALL: PASSED`).
- Ledger row 206 (`apps/coa-gameplay-test/conformance/classes/cultist_clauses.json`) links all three committed labels
  (`retarget_out_of_range`, `search_inside_15yd`, `search_beyond_15yd`) and records the counted pair.
- No other class is reached.
