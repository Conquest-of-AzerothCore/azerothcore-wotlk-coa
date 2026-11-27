# 0037. Cultist extra spells owner rulings and server fixes

- Status: accepted (owner rulings Q-cu-ex-1, Q-cu-ex-2, Q-cu-ex-3, standing ruling O-37, 2026-11-27)
- Date: 2026-11-27

## Context

During the Cultist (class 25) `extra_spells` conformance audit (31 spells at level 60), six server and specification
items were identified from server `Spell.dbc` (`/srv/coa/server-data/dbc`), live combat-log history (`coa-history`),
and server source inspection:

### 1. `Q-cu-ex-1` (`align_tooltip`) — Presence of Y'Shaarj (`803035`) / Despoiled Ground (`805180`)

- **Tooltip (`803035`, `Spell.dbc` `Description[enUS]`):**
  `"Assume a powerful |cFFFFFFFFPresence|r, giving damage dealt a $h% chance to curse the ground for $807632d, dealing ${$807632m1+$807632ppl1+$SP*.135+$AP*.075} Shadow damage every $807632t1 sec to enemies within.\r\n\r\n@ext:You may only have 1 |cFFFFFFFFPresence|r active at a time. :ext@"`
- **Effective data and server behaviour before fix:**
  - `803035` (*Presence of Y'Shaarj*, `SpellFamilyName = 31`, `ProcChance = 20`) triggers `805180` (*Despoiled Ground*)
    via `AscensionCultistEvents.cpp:102-104,256-260` with `SPELLVALUE_AURA_DURATION = ModifiedDuration(player, 807632)`
    (`12000 ms`).
  - `805180` (`SpellFamilyName = 31`, `DmgClass = 1`, `BaseLevel = 14`, `SpellLevel = 14`, `MaxLevel = 0`,
    `Effect[0] = SPELL_EFFECT_PERSISTENT_AREA_AURA` / `SPELL_AURA_PERIODIC_DAMAGE`, `Amplitude = 3000 ms`,
    `RadiusIndex = 14` = `8 yd`, `BonusMultiplier = 0.0`) had `BasePoints = 9`, `DieSides = 1`,
    `RealPointsPerLevel = 0.9` (`10 + int(46 * 0.9) = 51` at level 60) and **no entry** in `CultistCoefficients`
    (`src/server/coa/AscensionCultistData.h`).
  - The tooltip-referenced helper `807632` (*Presence of Y'Shaarj*, `BaseLevel = 14`, `SpellLevel = 14`, `MaxLevel = 0`,
    `BasePoints = 10`, `DieSides = 1`, `RealPointsPerLevel = 0.175`, giving `11 + int(46 * 0.175) = 19` at level 60)
    held the `{ 807632, 0, 0.135f, 0.075f, ... }` row in `AscensionCultistData.h:119` and a zeroed `spell_bonus_data`
    row (`rev_20260909_12_cultist_completion.sql:506,634`), even though `807632` is never cast.
  - Live combat logs (`coa-history`): `805180` has `10,437` `SPELL_PERIODIC_DAMAGE` events across `24` logs (`13`
    players; min `1`, max `1,347`, mean `254.5`) and `807632` has `0` events, confirming `805180` is the cast spell;
    player stats are absent from logs so logs alone do not distinguish base `19` vs `51`.
- **Owner ruling (`Q-cu-ex-1`, 2026-11-27):** `align_tooltip` — wire `0.135 * SP + 0.075 * AP` onto `805180` and align
  `805180`'s base damage and per-level scaling with the tooltip (`19` at level 60).

### 2. `Q-cu-ex-2` (`single_target`) — Whispers of Yogg-Saron (`572637`)

- **Tooltip (`572637`, `Spell.dbc` `Description[enUS]`):**
  `"Destabilizes magic used against the targeted party member. Reduces all spell damage taken by $S1% and reduces all healing taken by $S2%."`
- **Effective data and server behaviour before fix:**
  - `572637` (`SpellFamilyName = 31`, `BaseLevel = 32`, `DurationIndex = 6` = `10 min`, `RangeIndex = 4` = `30 yd`) had
    `Effect[0]` (`SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN`, `-5%`, `MiscValue = 126`) and `Effect[1]`
    (`SPELL_AURA_MOD_HEALING_PCT`, `-5%`, `MiscValue = 126`) both set to `TargetA = 56`
    (`TARGET_UNIT_CASTER_AREA_RAID`) and `RadiusIndex = 10` (`30 yd`) with no `ApplyContracts` override. Casting it
    buffed the entire party/raid within `30 yd` (including the caster) instead of the single targeted ally, unlike the
    other non-"Greater" Whispers.
  - Live combat logs (`coa-history`): `0` events across `186` logs (present in Ascension Sidekick `Heretic` kit).
- **Owner ruling (`Q-cu-ex-2`, 2026-11-27):** `single_target` — follow the tooltip and retarget both effects to a single
  allied target.

### 3. `Q-cu-ex-3` (`keep_live`) — Presence of N'Zoth (`803037`) / Thoughtseize (`806596`)

- **Tooltip (`803037`, `Spell.dbc`):**
  - `Description[enUS]`: `"Assume a dark |cFFFFFFFFPresence|r, giving damage dealt a $h% chance to summon |cffffffffTentacles|r on your back that attack a nearby enemy for $500707d.\r\n\r\n@ext:You may only have 1 |cFFFFFFFFPresence|r active at a time. :ext@"`
  - `ToolTip[enUS]`: `"Dealing damage has a chance to spawn a Tentacle on your back that will deal damage to enemies in melee range."`
- **Effective data and server behaviour:**
  - `803037` procs `500707` (*Eldritch Tentacle*, `8 s`, creature `500464`, `AscensionCultistEvents.cpp:261-267`),
    which applies `806596` (*Thoughtseize*, `RangeIndex = 11` = `15 yd`, `Effect[0] = SPELL_AURA_MOD_SILENCE`,
    `Effect[1] = SPELL_AURA_PERIODIC_DAMAGE` every `2 s`, SP coeff `0.75` in `AscensionCultistData.h:116`).
  - Live combat logs (`coa-history`): confirmed in live data (`1` log, `1` minion: `5` `SPELL_CAST_SUCCESS`, `5`
    `SPELL_AURA_APPLIED`, `12` `SPELL_PERIODIC_DAMAGE` ticks of `806596`, `143`–`327` damage, mean `254.3`).
- **Owner ruling (`Q-cu-ex-3`, 2026-11-27):** `keep_live` — keep `806596` (*Thoughtseize*) unchanged (including Silence
  and `15 yd` range), matching live `Spell.dbc` and combat logs, with no server or client text change.

### 4. Standing ruling `O-37` — Devour Magic (`520151` / `520152`)

- **Tooltip (`520151`, `Spell.dbc` `Description[enUS]`):**
  `"Devour $m1 harmful magic effect on a friendly target, dispelling it and healing you for ${$520152m1+$SP*.175}."`
- **Defect:** `520151` borrows `$520152m1` without `ppl`, so the client displays `174 + 0.175 * SP` at level 60. The
  triggered self-heal `520152` (`SpellFamilyName = 31`, `BaseLevel = 26`, `SpellLevel = 26`, `BasePoints = 173`,
  `DieSides = 1`) still carried `RealPointsPerLevel = 6.04122`, adding `int(34 * 6.04122) = +205` (`379 + 0.175 * SP`).
  Live combat logs (`167` heals across `11` logs / `6` players, including `3` players with minimums `243`, `263`, and
  `349` below the `379` floor) confirm `174`. Standing ruling `O-37` (2026-11-23, matching `500748` and `704473` in
  ADR 0027) aligns the server heal with the displayed tooltip value.

### 5. Greater Whispers of C'thun (`573067`) — missing `30 yd` raid radius

- **Tooltip (`573067`, `Spell.dbc` `Description[enUS]`):**
  `"Gift nearby allies with the madness of C'thun, increasing spell power by $s1 for $d."`
- **Defect:** `573067` (`SpellFamilyName = 31`, `TargetA = 56` `TARGET_UNIT_CASTER_AREA_RAID`) has `EffectRadiusIndex[0] = 0`
  (`RadiusEntry == nullptr`), reducing its effective AoE reach to `WorldObject::GetLeewayBonusRadius()` (`2.66 yd`).
  Live combat logs show `28` casts producing `344` buffs across `8` logs (`~12` allies per cast). Sibling raid buff
  `561392` (*Greater Whispers of Y'shaarj*) already assigns `SpellRadius[10]` (`30.0 yd`) in
  `AscensionCultistContracts.cpp:209-214`.

### 6. Tentacle of C'Thun (`801153`) — `> 60` Insanity free-cast threshold

- **Tooltip (`801153`, `Spell.dbc` `Description[enUS]`):**
  `"While above 60 |cffcfa6ffInsanity|r, the mana cost of this spell is removed."`
- **Defect:** `SpellInfo::CalcPowerCost` (`src/server/game/Spells/SpellInfo.cpp:3287`) checked `insanity >= 60`,
  waiving the mana cost at `60` Insanity instead of strictly above `60` (`61+`), disagreeing with the tooltip and every
  other Cultist `> 60` Insanity threshold (ADRs 0008, 0010).

### 7. Horrifying Presence (`500723`) — AoE taunt fails to redirect enemies without prior caster threat

- **Tooltip (`500723`, `Spell.dbc` `Description[enUS]`):**
  `"Taunts enemies within $a1 yds for $d, and significantly increases threat generation for $500717d."`
- **Defect:** `500723` carries only `Effect[0] = SPELL_AURA_MOD_TAUNT` (`TargetA = 22`, `TargetB = 15`, `RadiusIndex = 14`
  = `8 yd`) and no `SPELL_EFFECT_ATTACK_ME` (`114`). When an enemy is fighting another target and `caster` is not yet on
  its threat list, `ThreatManager::TauntUpdate()` iterates only existing `_myThreatListEntries` and skips `caster`,
  leaving the enemy on its previous victim (same engine defect fixed on Bloodmage `800782` *Blood Howl* S-18).

### 8. Eldritch Ritual (`804777`) / Faceless Destroyer (`50263`) — unowned summon spawns in `PHASEMASK_NORMAL`

- **Tooltip (`804777`, `Spell.dbc` `Description[enUS]`):**
  `"When 10 allies are channeling, the stone will be destroyed to bring forth a hostile |cffffffffFaceless Destroyer|r into the world for $804779d."`
- **Defect:** `AscensionCultistSummons.cpp:50-52` passes `summoner = nullptr` to `Map::SummonCreature` for entry `50263`
  so the Faceless Destroyer spawns hostile and unowned. In `Map::SummonCreature` (`Object.cpp:2298-2300`), a null
  `summoner` defaults `phase = PHASEMASK_NORMAL` (`1`), placing `50263` outside `player->GetPhaseMask()` in phased zones
  and test lanes.

## Options

- Apply minimal, spell-ID-scoped fixes for `801153`, `520152`, `573067`, `572637`, and `805180` in `SpellInfo.cpp`,
  `AscensionCultistData.h`, and `AscensionCultistContracts.cpp`, while keeping `807632`'s coefficient row intact for
  tooltip reads and making no code change for `803037` / `806596`. Chosen.
- Add a SQL `spell_bonus_data` zero row for `805180`. Rejected as unnecessary: in `Unit::SpellDamageBonusDone`
  (`src/server/game/Entities/Unit/Unit.cpp:9952-9998`), `coeff` starts from `Effects[0].BonusMultiplier` (`0.0f`), and
  when `bonus == nullptr` and `coeff == 0.0f` (`DmgClass == 1`), `DoneTotal` from SP/AP is `0` with no fallback to
  `CalculateDefaultCoefficient`. In `Unit::SpellDamageBonusTaken` (`Unit.cpp:10182-10203`), `if (coeff <= 0.0f)` runs
  identically whether `bonus` is absent or a zeroed row.
- Keep `572637` as raid AoE, keep `805180` at DBC base `51`, or strip Silence/range from `806596` under `803037`.
  Rejected by owner rulings `Q-cu-ex-1`, `Q-cu-ex-2`, and `Q-cu-ex-3`.

## Decision

1. **`src/server/game/Spells/SpellInfo.cpp` (`SpellInfo::CalcPowerCost`):** Change `if (Id == 801153 && insanity >= 60)`
   to `if (Id == 801153 && insanity > 60)`.
2. **`src/server/coa/AscensionCultistData.h` (`CultistCoefficients`):** Keep `{ 807632, 0, 0.135f, 0.075f, 0, 0, 0 }`
   so tooltip evaluation of `807632` remains aligned, and add `{ 805180, 0, 0.13500000f, 0.07500000f, 0.00000000f,
   0.00000000f, 0.00000000f }` in sorted spell-ID order between `804999` and `805573`.
3. **`src/server/coa/AscensionCultistContracts.cpp` (`AscensionCultist::ApplyContracts`):**
   - `520152`: set `info->Effects[0].RealPointsPerLevel = 0.0f;` (standing ruling `O-37`).
   - `573067`: set `info->Effects[0].RadiusEntry = sSpellRadiusStore.LookupEntry(10);` (`30.0 yd`, matching `561392`).
   - `572637`: for slots `0` and `1`, set `TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY)`, clear `TargetB`,
     and set `RadiusEntry = nullptr` (owner ruling `Q-cu-ex-2`; `info->_InitializeExplicitTargetMask()` refreshes the
     explicit target mask at the end of `ApplyContracts`).
   - `805180`: set `Effects[0].BasePoints = 10`, `DieSides = 1`, `RealPointsPerLevel = 0.175f`, and
     `BonusMultiplier = 0.0f` (owner ruling `Q-cu-ex-1`).
4. **`803037` (*Presence of N'Zoth*) / `806596` (*Thoughtseize*):** No server, SQL, or client text change (owner ruling
   `Q-cu-ex-3: keep_live`; Status 2 — conformant by owner ruling).
5. **`src/server/coa/AscensionCultistAbilities.cpp` (`OnSpellHitResult`):** For `id == 500723` on hostile targets with a
   threat list, seed minimum `1.0f` threat when `GetThreat(player) <= 0.0f` and invoke `TauntUpdate()`, matching
   Bloodmage `800782`.
6. **`src/server/coa/AscensionCultistSummons.cpp` (`Summon`):** For `entry == 50263`, call
   `summon->SetPhaseMask(player->GetPhaseMask(), true);` so the unowned Faceless Destroyer spawns in the summoner's
   phase.

No SQL, DBC, or client text files are modified.

## Consequences

- `801153` (*Tentacle of C'Thun*) costs normal mana at `<= 60` Insanity and `0` mana at `>= 61` Insanity.
- `520152` (*Devour Magic* self-heal) heals for `174 + 0.175 * Shadow SP` at level 60, matching `520151`'s tooltip.
- `573067` (*Greater Whispers of C'thun*) buffs party/raid allies within `30.0 yd` (`SpellRadius[10]`).
- `572637` (*Whispers of Yogg-Saron*) applies only to the single targeted ally (and enforces 1-Whisper exclusivity via
  `AscensionCultistAuras.cpp:60-65`).
- `805180` (*Despoiled Ground*) ticks every `3 s` for `19 + 0.135 * Shadow SP + 0.075 * AP` at level 60, matching
  `803035`'s tooltip without SP/AP double-dipping in `SpellDamageBonusDone`.
- `803037` (*Presence of N'Zoth*) keeps live `Thoughtseize` (`806596`) behaviour (Silence + `15 yd` range + Shadow DoT)
  recorded under `Q-cu-ex-3`.
- No other class is reached: every contract change is gated by `SpellFamilyName == 31` and exact spell ID, and the
  `SpellInfo.cpp` change is gated by `CLASS_CULTIST && SpellFamilyName == 31 && Id == 801153`.
- Runtime conformance scenarios for all six items are authored and verified in the subsequent verification phase on
  `feat/conformance-extra-cultist`.
