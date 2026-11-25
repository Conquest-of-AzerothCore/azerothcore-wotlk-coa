# 0036. Tentacle of N'Zoth removes Thoughtseize when its target leaves range

- Status: accepted (owner ruling O-22, 2026-11-25)
- Date: 2026-11-25

## Context

Tentacle of N'Zoth `572103` (server `Spell.dbc`, `/srv/coa/server-data/dbc`, sha256 `4e4ed9ba1c2e...`,
`SpellFamilyName` 31, `Description[enUS]`):

> "Target an enemy and summon a Tentacle of N'Zoth on the ground near them that will silence them and deal
> `${$806596m2+$806596ppl2+$SP*.75}` Shadow damage every `$806596t2` sec for `$806596d`. If your target runs out of
> range, the tentacle will seek a new target. The tentacle gains health based on your Stamina. If the tentacle dies,
> the silence effect will end. You may only have 1 Old God Tentacle active at a time."

Effective `Spell.dbc` and SQL data:

- `572103` (`Tentacle of N'Zoth`): `RangeIndex = 11` (`SpellRange[11]`: `15.0 yd`, `"Fifteen yards"`), `DurationIndex =
  31` (`8000 ms`), `Effect[0] = SPELL_EFFECT_SUMMON` (28), `MiscValue = 501464`, `MiscValueB = 63`
  (`SUMMON_TYPE_TOTEM`), `EffectRadiusIndex[0] = 8` (`5.0 yd`).
- `806596` (`Thoughtseize`): `RangeIndex = 11` (`15.0 yd`), `DurationIndex = 31` (`8000 ms`), `AttributesEx = 16388`
  (`SPELL_ATTR1_IS_CHANNELED | SPELL_ATTR1_TRACK_TARGET_IN_CHANNEL`), `Effect[0] = MOD_SILENCE` (27), `Effect[1] =
  PERIODIC_DAMAGE` (3, `Amplitude = 2000 ms`), `SpellFamilyFlags = [0, 0, 0]`.
- `pending_db_world/rev_20260909_12_cultist_completion.sql`: binds `spell_ascension_cultist_ability` on `572103`,
  registers `creature_template` `501464` (`npc_ascension_cultist_summon`, display `28813`, scale `0.5`, combat reach
  `0.75 yd`). Against Harvest Golem `36` (`combat_reach = 1.275 yd`), the effective centre-to-centre threshold is
  `15.0 + 0.75 + 1.275 = 17.025 yd` (ADR 0034).

Before this fix (recorded in `cu-rfix5` review Finding I2 and ADR 0034 Observations (a) and (b), build `a17a35612e2e`):

- `npc_ascension_cultist_summon::ApplyThoughtseize` (`src/server/coa/AscensionCultistSummons.cpp:192-208`) emulated
  channeled `Thoughtseize` (`806596`) via `player->AddAura(Thoughtseize, target)` (`Unit.cpp:16806-16843`, setting
  caster GUID to `owner`) and ran only on the `6000 ms` `Pulse`. Unlike a native AzerothCore channel
  (`Spell.cpp:3474-3514`, which checks `!m_caster->IsWithinDistInMap(unit, range)` every update tick and calls
  `unit->RemoveAura(aurApp)` at `:3509`), `501464` never removed `806596` when an afflicted target left range or when
  `Target()` picked a replacement.
- In `572103 retarget_out_of_range` (`20261125-130620` / `20261125-130649` and `20261125-132735` / `20261125-132804`),
  at `t = 6800 ms` both the escaped `dummy` (`19.62–52.70 yd`) and the newly acquired `area1` simultaneously carried
  `806596 = 1`, and on natural `8000 ms` expiry `ClearThoughtseize(ExpiryGrace())` (ADR 0016) cleared `area1` while
  sparing `dummy`'s final tick out of range.
- With no other enemy in range (`20261125-124842`), `dummy` at `23.10 yd` kept `806596 = 1` until natural `8000 ms`
  expiry.

Live evidence: none archived on out-of-range Thoughtseize removal or retargeting timing (`ev1.md` has no `572103`;
`ev2.md` Q-cu-32 confirmed 4 ticks on stationary targets in live log 67 only).

Owner ruling `O-22` (2026-11-25): remove `Thoughtseize` (`806596`) from the previous target as soon as it leaves
range / the tentacle retargets (normal channel behaviour), rather than letting it run to expiry out of range.

## Options

- Check `501464`'s `afflicted` set on every `UpdateAI(uint32 diff)` tick against `ThoughtseizeRange()`, immediately
  remove `owner`'s `Thoughtseize` aura via `target->GetAura(Thoughtseize, owner)` from any afflicted unit that is
  missing, dead, or out of `IsWithinDistInMap(unit, range)`, and immediately invoke `ApplyThoughtseize(player)` to seek
  a replacement while stripping any previously afflicted unit that does not match the chosen target; keep `Pulse` at
  `6000 ms` and leave `500464` untouched. Chosen.
- Strip `806596` only on the `6000 ms` `Pulse`. Rejected: leaves an escaped target silenced and taking damage for up to
  `6000 ms` out of range (and never removes it if the target leaves range after `t = 6000 ms` under Eternal Grasp),
  contradicting O-22 ("as soon as it leaves range").
- Replace `player->AddAura` with a native `me->CastSpell(target, Thoughtseize, false)` channel from `501464`. Rejected:
  changes damage/credit attribution from `player` to `me`, breaking `AscensionCultistContracts.cpp:349-352` (Eldritch
  Obelisk `+100%` scaling on `Thoughtseize`), `AscensionCultistEvents.cpp:88` (Twilight Domination `520405` cooldown
  reduction on player-attributed `Thoughtseize` ticks), spell power scaling, and ADR 0016's `t = 0 ms` 4-tick timing.

## Decision

In `src/server/coa/AscensionCultistSummons.cpp` (`npc_ascension_cultist_summon`), strictly gated to `entry == 501464`:

1. Extract `RemoveThoughtseize(Unit* target, int32 graceMs = 0)` calling `target->GetAura(Thoughtseize, owner)` and
   removing the aura when `graceMs <= 0 || aura->GetDuration() > graceMs`. Keying on `owner` (`player->GetGUID()`)
   ensures one Cultist's tentacle never strips another Cultist's `Thoughtseize` from a shared enemy. Have
   `ClearThoughtseize(int32 graceMs = 0)` delegate to `RemoveThoughtseize`.
2. Add `UpdateThoughtseize(Player* player)`, invoked from `UpdateAI(uint32 diff)` when `me->GetEntry() == 501464`
   before `timers.Update(diff)`:
   - Returns immediately in O(1) when `afflicted` is empty (zero grid scans while idle).
   - For each `guid` in `afflicted`, checks `!unit || !unit->IsAlive() || !me->IsWithinDistInMap(unit, range)` with
     `range = ThoughtseizeRange()` (`15.0 yd` from `SpellRange[11]`, `17.025 yd` c2c against Harvest Golem `36`).
   - Removes `owner`'s `Thoughtseize` via `RemoveThoughtseize(unit)`, erases `guid` from `afflicted`, and invokes
     `ApplyThoughtseize(player)` on the same server tick to seek a replacement within `range`.
3. In `ApplyThoughtseize(Player* player)`, when `me->GetEntry() == 501464`:
   - Removes `owner`'s `Thoughtseize` from every `guid` in `afflicted` that does not equal the chosen `target` (or from
     all entries when `target == nullptr`), guaranteeing single-target exclusivity with zero overlap.
   - Updates `command = target->GetGUID()` when acquiring a target so `501464` remains anchored on the new target at
     the `6000 ms` `Pulse`.
4. `500464` (Presence of N'Zoth `803037` / Eldritch Tentacle `500707`), `ClearThoughtseize(ExpiryGrace())` on natural
   despawn (ADR 0016), `JustDied` (`tentacle_death_ends_silence`), `DoAction(4)` replacement, `DoAction(2)` Eldritch
   Command (`573311`), and all other Cultist summons remain unchanged.

No shared engine, DBC, SQL, tool, or client text changes.

## Consequences

- **Immediate removal & single-target tether:** When `501464`'s target leaves the `15.0 yd` (`17.025 yd` c2c) range,
  `owner`'s `Thoughtseize` (`806596`) is removed on the very next `UpdateAI` tick (`<= 50 ms`), before `501464`
  acquires any replacement target — neither dual-target affliction nor lingering out-of-range silence/DoT occurs.
- **No-other-target & target-return behaviour (observations where tooltip is silent, not owner rulings):**
  - When no other combat target is within `15 yd`, the escaped target still loses `806596` immediately on the next tick
    and `501464` remains alive until its natural `8000 ms` despawn (preserving ADR 0034 Observation (b)).
  - Because `Pulse` remains at `6000 ms` (existing cadence), if the escaped target walks back inside `15 yd` before the
    `6000 ms` `Pulse`, that `Pulse` re-applies `806596` until natural `8000 ms` despawn (where ADR 0016's
    `ClearThoughtseize(ExpiryGrace())` clears it cleanly because `~6000 ms > 200 ms`). If the target returns after
    `6000 ms`, no further `Pulse` fires before despawn and `806596` is not re-applied. This return-in-range cadence is
    an unruled observation and is intentionally not asserted in the committed regression scenarios.
- **Tick arithmetic preserved:**
  - In-range control (`0..8000 ms`, `Amplitude = 2000 ms`): `8000 / 2000 = 4` ticks on primary (`2, 4, 6, 8 s`, 4th tick
    spared by ADR 0016 `ExpiryGrace()`), `0` on secondary.
  - Out-of-range retarget at exit time `T_exit` (`0 < T_exit < 8000 ms`): primary receives `floor(T_exit / 2000)` ticks;
    secondary receives `806596` at `T_exit` and loses it on `501464` despawn at `8000 ms` (`ClearThoughtseize(200)`
    clears any aura with `> 200 ms` remaining), delivering `floor((8000 - T_exit) / 2000)` ticks. Total across both
    targets is `floor(T_exit / 2000) + floor((8000 - T_exit) / 2000) <= 4` (`3` whenever `T_exit` is not an exact
    multiple of `2000 ms`; previously `5` ticks landed because primary kept `806596` through `8000 ms`).
- **Two-Cultist ownership isolation:** `RemoveThoughtseize` matches `target->GetAura(Thoughtseize, owner)`, so when a
  shared enemy leaves Cultist A's tentacle range while remaining inside Cultist B's tentacle range, only Cultist A's
  `806596` is removed and Cultist B's `806596` stays active.
- **Preserved behaviour:** ADR 0016 4-tick base/SP delivery, `tentacle_death_ends_silence`,
  `presence_eternal_grasp_expiry` (creature `500464` with Eternal Grasp R2: 5 ticks over 12 s and clean expiry), ADR
  0017 Eternal Grasp duration scaling, and all 15 shared-summon spells remain intact.
- **Conformance tool gaps (no tool code changed):**
  - `apps/coa-gameplay-test/conformance/kinds/summon_retarget_out_of_range.py` already records `primary_aura` in `end`
    snapshots in raw `result.json`, but `summon_retarget_verdict` (`:454-508`) only judges `secondary_aura` (never
    `primary_aura == 0` or mid-snapshot non-overlap), always requires a secondary enemy (cannot judge a no-other-target
    arm), and does not read `spell_damage_count` on `dummy`/`area1`.
  - `metric_delta` has no option to issue `move_point` on a creature (`TARGET`) after `trigger_spell`.
- **Verification (worldserver build `539312883947`, `b95b241990dd+`):**
  - `572103` counted pairs (`cu-fix5-o22-prove-572103` runs `20261125-134612` / `20261125-134642` and refreshed
    `cu-fix5-h-prove-572103` runs `20261125-144748` / `20261125-144817`; `15/15 ok` in every run, `0` flips, all `5`
    ledger rows `behaviour`):
    - `572103 retarget_out_of_range` (`end` at `6800 ms`): `ok / ok`; control `area1 = 0` (`9.17` / `10.13 yd`),
      near (`21.35` / `22.49 yd`) and far (`40+ yd`) retargeted `area1 = 1` with raw `primary_aura = 0`.
    - `572103 retarget_short_delay` (`end` at `3300 ms`, `2700 ms` before `6000 ms` `Pulse`): `ok / ok`; control
      `area1 = 0` (`5.60` / `9.82 yd`), near (`26.35` / `23.10 yd`) and far retargeted `area1 = 1` with raw
      `primary_aura = 0`.
    - `search_inside_15yd` (`0 -> 1`), `search_beyond_15yd` (`0 -> 0`), `damage_base` (`536` / `524`, 4 ticks),
      `damage_sp` (`3892` / `3900`, 4 ticks), `presence_eternal_grasp_expiry` (5 ticks / 12 s),
      `tentacle_death_ends_silence`: all `ok / ok`.
  - Committed O-22 catalog gameplay scenarios (counted pair `20261125-142643` and `20261125-142712`,
    `VERIFY ALL: PASSED`, `3/3 passed` in both runs):
    - `apps/coa-gameplay-test/scenarios/cultist-tentacle-of-nzoth-o22-retarget-clears-primary.json`: control (`7.47` /
      `9.23 yd`) kept `dummy = 1`, `area1 = 0`, `4` ticks on `dummy`, `0` on `area1`; treatment (`22.70` / `25.33 yd`)
      asserted `dummy = 0` and `area1 = 1` at `2800`, `3300`, and `6800 ms`, clean `0/0` at `9500 ms`, `0` delta ticks
      on `dummy` (cumulative `4`), and `3` ticks on `area1` (`0 + 3 = 3 <= 4`).
    - `apps/coa-gameplay-test/scenarios/cultist-tentacle-of-nzoth-o22-no-other-target.json` (control + no-other-target
      arms only; unruled return-in-range cadence intentionally omitted): control (`11.55` / `6.78 yd`) kept
      `dummy = 1` and `4` ticks; out-of-range (`21.75` / `23.56 yd`) kept `501464 = 1` and `dummy = 0` at `2800` and
      `6800 ms`, clean `0/0` at `9500 ms`, `0` delta ticks (cumulative `4`).
    - `apps/coa-gameplay-test/scenarios/cultist-tentacle-of-nzoth-o22-two-cultists-owner-isolation.json`: `caster1`
      (`23.43` / `24.44 yd > 17.025 yd`) lost `806596` (`0`) while `caster2` (`12.11` / `10.11 yd <= 17.025 yd`) kept
      `806596` (`1`).
  - Shared-summon counted pair (`cu-fix5-o22-prove-shared`, runs `20261125-135133` and `20261125-135408`, 15 spells /
    61 entries): `60/61 ok` in both runs; 2 unrelated pre-existing test defects on summons untouched by the
    `entry == 501464`-gated diff were diagnosed and repaired in `cultist.json`:
    - `706911 portal_casts` had omitted `refill_power_after_setup_casts: {"power": 0}`, causing `76/96` casts of
      `500110` (`ManaCostPercentage = 15`) to fail with `SPELL_FAILED_NO_POWER` (`reason 85`), leaving `10` effective
      casts (`0.85^10 = 19.69%` zero-portal rate per run). Fixed with `refill_power_after_setup_casts: {"power": 0}`
      and `85` casts (`84` setup + `1` trigger, `0.85^85 = 1.001e-6` per run / `2.003e-6` per pair); 5-pair (10-run)
      proof of `706911`, `301068`, and `301200` (`cu-fix5-h-prove-portals`, `20261125-143333` through `20261125-144612`)
      passed `21/21 ok` in all 10 runs (`0` alerts, `0` flips, `0` OOM failures, `portal_casts` hits `7..22`, mean
      `11.7`).
    - `802728 tentacle_crit_damage` suffered 1-tick `total`/`count` measurement tearing against autonomous `50272`'s
      `1500 ms` channel (`~28.8%` tearing rate per run). Switched to synchronously commanded `50096` (`802044`/`802046`,
      zero autonomous ticks after warmup, matching `802048`); 5-pair (10-run) proof (`cu-fix5-h-prove-802728`, pilot
      `20261125-142800` + runs `20261125-142828` through `20261125-143237`) passed `2/2 ok` in all 10 runs (`0` alerts,
      `0` flips, exact `235` vs `214` = `+9.813%`, 99% CI `[+9.813%, +9.813%]`).
  - Existing `*nzoth*` / `*tentacle*` catalog scenarios (`20261125-135659`): **`13/13 passed`** (`VERIFY ALL: PASSED`).
- Ledger row 206 (`apps/coa-gameplay-test/conformance/classes/cultist_clauses.json`) links `retarget_short_delay`
  alongside `retarget_out_of_range`, `search_inside_15yd`, and `search_beyond_15yd`, and cites the three committed
  O-22 catalog gameplay scenarios in `reason` as supporting evidence.
- No other class is reached.
