# 0045. Sun Cleric extra spells owner rulings and server fixes

- Status: accepted (owner rulings Q-sc-ex-1 through Q-sc-ex-9, 2026-11-27)
- Date: 2026-11-27

## Context

During the Sun Cleric (class 27) `extra_spells` conformance audit (34 spells at level 60 plus unchained ranks), nine
owner rulings (`Q-sc-ex-1`..`Q-sc-ex-9`) and five settled server defects were identified from the installed server
`Spell.dbc` (`/srv/coa/server-data/dbc`), archived Ascension live combat logs (`coa-history`), Ascension Sidekick
class-kit snapshots, and server source inspection:

### 1. `Q-sc-ex-1` (`keep_tooltip_5`) — Radiant Cascade (`500141` / `502411`)

- **Tooltip (`502411`, Rank 6, `Spell.dbc` `Description[enUS]`):**
  `"Refract light into a restorative beam, healing an ally for ${$m1+$PPL1+$bh*0.141131}, and then jumps to up to $x1 additional allies, healing for less with each bounce."` (`$x1 = 4` -> literal `1 + 4 = 5` total targets.)
- **Effective data and server behaviour:**
  - `Spell.dbc` has `EffectChainTarget[0] = 4` (which AzerothCore treats as total targets including the primary), and
    archived live combat logs recorded `1,537` R6 casts hitting `4` targets (`0` hitting `5`).
  - `AscensionSunClericContracts.cpp` (`Named(info, 500141)`) overrides `info->Effects[0].ChainTarget = 5`, matching
    the tooltip literal (`1 + 4 = 5` total targets) and the existing `704565` (*Everglow*) conformance proof (`5 -> 7`).
- **Owner ruling (`Q-sc-ex-1`, 2026-11-27):** `keep_tooltip_5` — keep `info->Effects[0].ChainTarget = 5;` on all ranks
  of Radiant Cascade.

### 2. `Q-sc-ex-2` (`remove_sp`) — Sunflare (`800231` / `502386..502397`) and Grace (`504070`)

- **Tooltip (`502396`, Rank 12, `Spell.dbc` `Description[enUS]`):**
  `"Blast an enemy with the light of the sun, dealing ${$m1+0} to ${$M1+0} Holy damage."` (No `$SP` term.)
- **Effective data and server behaviour before fix:**
  - `AscensionSunClericData.h` listed `sp = 0.25000000f` on all 13 Sunflare ranks (`800231`, `502386..502397`), and
    `800231` carried `EffectBonusMultiplier[0] = 0.25` in `Spell.dbc` (already cleared by `AscensionStockCoefficients`).
  - `AscensionSunClericDevotion.cpp` (`504070` *Grace*) scaled Sunflare's bonus from `row.sp * bonusPercent` (`Effect[1]`
    adds `+10%` of spell power to Sunflare). Setting `row.sp = 0.0f` without adjusting `AscensionSunClericDevotion.cpp`
    would have zeroed Grace's `+10%` SP bonus on Sunflare.
- **Owner ruling (`Q-sc-ex-2`, 2026-11-27):** `remove_sp` — zero Sunflare's own SP coefficient across all 13 ranks and
  explicitly zero `BonusMultiplier` on all ranks of `800231`, while keeping `504070` (*Grace*) adding `+10%` SP to
  Sunflare (`Amount(504070, 1) / 100.0f * spellPower`) and keeping Dawnsear's `row.sp * bonusPercent` (ADR 0026).

### 3. `Q-sc-ex-3` (`buff_15_pct`) — Chosen of the Light (`800622` / `706442`)

- **Tooltips (`800622`, `Spell.dbc`):**
  - `Description[enUS]`: `"Become An'she's chosen one, reducing your damage taken by $s1% for $d.\r\n\r\nTaking damage while below 50% health will instantly heal you for $706442s1% of your maximum health. Can only occur once."`
  - `ToolTip[enUS]`: `"Damage taken reduced by ${$w1}%.\r\n\r\nTaking damage while below 50% health while this is active will instantly cause it to heal them for 15% of their maximum health."`
- **Defect and ambiguity before fix:**
  - `800622` `Effect[1]` (`SPELL_AURA_PROC_TRIGGER_SPELL`, `TriggerSpell = 706442`) had `ProcFlags = 0`,
    `ProcCharges = 0`, and zero C++ or SQL wiring; taking damage while below `50%` health never triggered `706442`.
  - `706442` (`SPELL_EFFECT_HEAL_PCT`, `SpellFamilyName = 33`, `AttributesEx3 = 0`) had `BasePoints = 9`, `DieSides = 1`
    (`10%` max health, conflicting with the buff tooltip's `15%`).
- **Owner ruling (`Q-sc-ex-3`, 2026-11-27):** `buff_15_pct` — set `706442` `DmgClass = SPELL_DAMAGE_CLASS_MAGIC`
  (matching `806479` Solar Prayer; raw `Spell.dbc` had `DmgClass = 0`, which caused `Unit::SpellHealingBonusDone` to
  return early before class healing modifiers) and `Effect[0].BasePoints = 14` (`15%` max health, `AttributesEx3 = 0`,
  yielding `15% * 0.8 = 12%` net under class heal tuning `887015` `-20%`), register `706442` in `ClientSpellPatches` so
  `$706442s1%` displays `15%`, and trigger `706442` once per `800622` application from `sun_cleric_scaling::OnDamage`
  when `player->HealthBelowPctDamaged(50, damage)`.

### 4. `Q-sc-ex-4` (`all_schools_and_auto`) — Dawnfall (`806118`)

- **Tooltip (`806118`, `Spell.dbc` `Description[enUS]`):**
  `"Bring down the light of An'she down at the target location for $d.\r\n\r\nWhile inside, allies receive $s3% increased healing from all sources and enemies take $s1% increased damage from you and are struck by a |cffffffffSolar Flare|R every $t2 sec.@s:807175:0@"`
- **Defect / ambiguity before fix:**
  - `806118` `Effect[0]` (`SPELL_AURA_MOD_DAMAGE_FROM_CASTER`, `+15%`) had `MiscValue = 126` (magic schools only,
    excluding Physical `0x01`), and stock `Unit::MeleeDamageBonusTaken` skips `SPELL_AURA_MOD_DAMAGE_FROM_CASTER` on
    melee auto-attacks (`spellProto == nullptr`), whereas the tooltip states `"enemies take 15% increased damage from
    you"` without a spell restriction.
- **Owner ruling (`Q-sc-ex-4`, 2026-11-27):** `all_schools_and_auto` — widen `806118` `Effect[0].MiscValue` to
  `SPELL_SCHOOL_MASK_ALL` for Physical spells and apply `806118` `Effect[0]` to the caster's melee auto-attacks inside
  `sun_cleric_scaling::ModifyMeleeDamage` without modifying `Unit.cpp`.

### 5. `Q-sc-ex-5` (`allow_overheal`) — Vows of Radiance (`803489`), Dawn (`803491`), Grace (`803719`), and Light (`807547`)

- **Tooltips (`Spell.dbc` `Description[enUS]`):**
  - `803489`, `803491`, `803719`: `"Direct ability damage or healing ..."` (no `"effective"` qualifier).
  - `807547`: `"Direct damage taken or direct healing taken by you ..."` (live logs show `5,121` `505197` procs
    triggered directly by `100%` overheals).
  - `807435` (*Vow of the Eclipse*): `"Direct ability damage or effective healing ..."` (explicitly requires effective
    healing).
- **Defect / ambiguity before fix:** `AscensionSunClericEvents.cpp` read `HealInfo::GetEffectiveHeal()` for every aura,
  suppressing procs on `100%` overheals for all Vows.
- **Owner ruling (`Q-sc-ex-5`, 2026-11-27):** `allow_overheal` — read `HealInfo::GetHeal()` for `803489`, `803491`,
  `803719`, and `807547`, while preserving `HealInfo::GetEffectiveHeal()` for `807435` (*Vow of the Eclipse*) and all
  other auras.

### 6. `Q-sc-ex-6` (`four_bounces_live`) — Vow of Dawn (`803491`) Fulfillment bounce count

- **Tooltip (`803491`, `Spell.dbc` `Description[enUS]`):**
  `"Direct ability damage or healing generates 1 |cFFFF9800Solar Power|r and bounces to $803492s1 additional nearby targets with less value per target struck.\r\n\r\n|cffffffffFulfillment|r: Doubles the amount of targets struck."`
- **Ambiguity before fix:** `AscensionSunClericEvents.cpp` computed `count = (count + 1) * 2 - 1` (`2 -> 5` extra
  bounces, `6` total targets) instead of doubling the bounce count (`2 -> 4` extra bounces, `5` total targets on a
  single-target spell).
- **Owner ruling (`Q-sc-ex-6`, 2026-11-27):** `four_bounces_live` — use `count *= 2;` (`2 -> 4` additional bounces).

### 7. `Q-sc-ex-7` (`fulfill_on_taken_live`) and settled target fix — Vow of Light (`807547` / `505197`)

- **Tooltip (`807547`, `Spell.dbc` `Description[enUS]`):**
  `"Direct damage taken or direct healing taken by you generates 1 |cFFFF9800Solar Power|r and heals the nearest nearby ally equal to $807750s1% of the amount.\r\n\r\n|cffffffffFulfillment|r: Doubles the amount of healing done."`
- **Defects before fix:**
  1. **Target selection (`AscensionSunClericEvents.cpp`):** `Allies(player, player, Radius(505197))` always included
     `player` at distance `0.0f`, so sorting by distance always healed `player` instead of the nearest nearby ally
     (live combat logs show `6,557` heals on other allies vs `2,711` on self).
  2. **Fulfillment on incoming events (`Q-sc-ex-7`):** `fulfillment` required `ownSpell && spell->GetScriptValue(Dawn)`,
     so incoming enemy hits and ally heals while Dawn (`807440`) was active never doubled `505197` or triggered
     Fulfillment passives (`805581`, `680622`, `704562`, `92136`, `707081`).
- **Owner ruling (`Q-sc-ex-7`, 2026-11-27) and settled fix:**
  - When `id == 807547 && !ownSpell && player->HasAura(Dawn)`, suppress Solar Power gain (`dawnEvent = true`), double
    `505197` (`fulfillment = true`), and apply the Fulfillment passive rewards via `FulfillTaken(player, event.GetActor())`
    without consuming Dawn charges or requiring a caster `Spell*`.
  - Remove `player` from `allies`, sort the remaining allies by distance and pick `allies.front()`, falling back to
    `player` only when no other ally is in range and `player->IsAlive()`.

### 8. `Q-sc-ex-8` (`keep_while_dawn`) — Vow of Grace (`803719`) Fulfillment mana-cost halving

- **Tooltip (`803719`, `Spell.dbc` `Description[enUS]`):**
  `"|cffffffffFulfillment|r: Halves the mana cost of all spells and abilities$?s707528[ and reduces their cooldown by $807446s2%][]."`
- **Server behaviour:** `SpellInfo::CalcPowerCost` (`src/server/game/Spells/SpellInfo.cpp:3307-3308`) halves mana cost
  for all family-33 spells whenever both `803719` and Dawn (`807440`) are active (`powerCost /= 2`).
- **Owner ruling (`Q-sc-ex-8`, 2026-11-27):** `keep_while_dawn` — keep `SpellInfo.cpp:3307` unchanged.

### 9. `Q-sc-ex-9` (`add_daybreak_r6`) — Daybreak Rank 6 (`572035`) progression chain

- **Defect before fix:** `src/server/coa/AscensionSpellProgressionData.h` ended the `500147` (*Daybreak*) progression
  chain at Rank 5 `503624` (level 46), omitting Rank 6 `572035` (level 58), even though `SpellRank.dbc` row `8801`,
  `SkillLineAbility.dbc` row `88314`, `spell_ranks` (`rev_20261026_06`), `trainer_spell` (`rev_20261115_91`), and
  `513` live combat-log casts confirm `572035` as Rank 6.
- **Owner ruling (`Q-sc-ex-9`, 2026-11-27):** `add_daybreak_r6` — add `{ 27, 500147, 572035, 58 }` to
  `AscensionSpellProgressionData.h`.

### 10. Settled server defects (`572390`, `681160`, `807240`, `570125`)

- **`572390` (*Greater Devotion of Dawn*):** `Effect[1]` (`SPELL_AURA_MOD_RANGED_ATTACK_POWER`, `+232`) had
  `TargetA = TARGET_UNIT_TARGET_ALLY` and `RadiusIndex = 0` while `Effect[0]` (`SPELL_AURA_MOD_ATTACK_POWER`, `+232`)
  had `TARGET_UNIT_CASTER_AREA_RAID` and `RadiusIndex = 12` (`100 yd`), denying ranged AP to raid/party allies and
  forcing an explicit ally target.
- **`681160` (*Greater Devotion of Grace*):** `Effect[1]` (`SPELL_AURA_MOD_POWER_COST_SCHOOL_PCT`, `-5%`) had
  `RadiusIndex = 0` (`RadiusEntry == nullptr`) while `Effect[0]` (`SPELL_AURA_MOD_POWER_REGEN`, `+33` MP5) had
  `RadiusIndex = 217` (`30 yd`), shrinking `Effect[1]` to leeway radius (`~2.66 yd`).
- **`807240` (*Rejuvenating Rays*):** Tooltip states `"Cannot be used in combat or indoors."`, yet `Spell.dbc` omitted
  both `SPELL_ATTR0_NOT_IN_COMBAT_ONLY_PEACEFUL` and `SPELL_ATTR0_ONLY_OUTDOORS`.
- **`570125` (*Judgement Day*):** Tooltip (`806121`) states `"incapacitating them for $570125d (8 sec vs players)."`,
  yet `GetDiminishingReturnsLimitDuration` (`src/server/game/Spells/SpellMgr.cpp`) had no entry for `570125`
  (`MECHANIC_KNOCKOUT` -> `DIMINISHING_DISORIENT`), falling through to the `10 s` default against players.

## Options

- Implement all contract, scaling, event, progression, and PvP DR fixes inside class-scoped Sun Cleric files and the
  existing `GetDiminishingReturnsLimitDuration` switch in `SpellMgr.cpp`, without SQL migrations or `Unit.cpp` edits.
  Chosen.
- Modify `Unit::MeleeDamageBonusTaken` in `Unit.cpp` for Dawnfall (`806118`) auto-attacks. Rejected: shared core engine
  changes reach all classes; `sun_cleric_scaling::ModifyMeleeDamage` already runs in `Unit::CalculateMeleeDamage` and
  scopes the bonus strictly to Sun Cleric `806118`.
- Add a SQL `spell_proc` migration for `800622` (*Chosen of the Light*). Rejected: handling `800622` in
  `sun_cleric_scaling::OnDamage` with `Aura::GetScriptValue(706442)` is SQL-free, respects `HealthBelowPctDamaged`, and
  guards once-per-application cleanly.

## Decision

1. **`src/server/coa/AscensionSunClericData.h`:** Zero `sp` (`0.00000000f`) on all 13 Sunflare ranks (`800231`,
   `502386..502397`) (`Q-sc-ex-2`).
2. **`src/server/coa/AscensionSunClericDevotion.cpp`:** Keep Dawnsear multiplying `row.sp * bonusPercent`; for Sunflare
   (`!dawnsear && sunflare`), add `std::max(0, player->SpellBaseDamageBonusDone(info->GetSchoolMask())) * bonusPercent`
   so Grace (`504070` `Effect[1]`) still grants `+10%` SP while Sunflare itself has `0%` SP (`Q-sc-ex-2`).
3. **`src/server/coa/AscensionSunClericContracts.cpp`:**
   - Keep `Named(info, 500141)` setting `Effects[0].ChainTarget = 5` (`Q-sc-ex-1`).
   - In `Named(info, 800231)`, set `info->Effects[EFFECT_0].BonusMultiplier = 0.0f` (`Q-sc-ex-2`).
   - For `706442`, set `info->DmgClass = SPELL_DAMAGE_CLASS_MAGIC` (matching `806479` Solar Prayer so class heal tuning
     `887015` `-20%` applies in `Unit::SpellHealingBonusDone`, yielding `15% * 0.8 = 12%` net) and
     `info->Effects[EFFECT_0].BasePoints = 14` (`15%`, `AttributesEx3` unchanged), and call
     `Ascension::ClientSpellPatches::Instance().Register(id)` (`Q-sc-ex-3`).
   - In `sun_cleric_scaling::OnDamage`, wire `800622` -> `706442` once per aura application via
     `chosen->GetScriptValue(706442)` and `player->HealthBelowPctDamaged(50, damage)` (`Q-sc-ex-3`).
   - For `806118`, set `info->Effects[EFFECT_0].MiscValue = SPELL_SCHOOL_MASK_ALL`, and in
     `sun_cleric_scaling::ModifyMeleeDamage`, add `dawnfall->GetAmount()` when the target carries the caster's `806118`
     `EFFECT_0` aura (`Q-sc-ex-4`).
   - For `572390`, set `Effects[EFFECT_1].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER_AREA_RAID)` and
     `Effects[EFFECT_1].RadiusEntry = sSpellRadiusStore.LookupEntry(12)`.
   - For `681160`, set `Effects[EFFECT_1].RadiusEntry = sSpellRadiusStore.LookupEntry(217)`.
   - For `RejuvenatingRays` (`807240`), set `Attributes |= SPELL_ATTR0_NOT_IN_COMBAT_ONLY_PEACEFUL |
     SPELL_ATTR0_ONLY_OUTDOORS`.
4. **`src/server/coa/AscensionSunCleric.h` and `AscensionSunCleric.cpp`:** Extract shared `ApplyFulfillmentRewards`
   helper and add `FulfillTaken(Player* player, Unit* target)` for taken-event Fulfillment without a caster `Spell*`
   (`Q-sc-ex-7`).
5. **`src/server/coa/AscensionSunClericEvents.cpp`:**
   - Read `HealInfo::GetHeal()` for `803489`, `803491`, `803719`, and `807547`, keeping `GetEffectiveHeal()` for
     `807435` and all other auras (`Q-sc-ex-5`).
   - Change Vow of Dawn (`803491`) Fulfillment bounce count from `(count + 1) * 2 - 1` to `count *= 2` (`Q-sc-ex-6`).
   - When `id == 807547 && !ownSpell && player->HasAura(Dawn)`, set `dawnEvent = true`, `fulfillment = true`, and call
     `FulfillTaken(player, event.GetActor())` without consuming Dawn charges (`Q-sc-ex-7`).
   - For `807547`, exclude `player` from `allies` before sorting by distance and picking `allies.front()`, falling back
     to `player` only when no other ally is in range and `player->IsAlive()`.
6. **`src/server/game/Spells/SpellInfo.cpp`:** Keep `803719 && 807440` halving mana cost unchanged (`Q-sc-ex-8`).
7. **`src/server/coa/AscensionSpellProgressionData.h`:** Add `{ 27, 500147, 572035, 58 }` after `{ 27, 500147,
   503624, 46 }` (`Q-sc-ex-9`).
8. **`src/server/game/Spells/SpellMgr.cpp` (`GetDiminishingReturnsLimitDuration`):** Add `if (spellproto->SpellFamilyName
   == 33 && spellproto->Id == 570125) return 8 * IN_MILLISECONDS;`.

No SQL, DBC, or `Unit.cpp` files are modified.

## Consequences

- Radiant Cascade (`500141` / `502411`) continues hitting `5` total targets (`7` with Everglow `704565`).
- Sunflare (`800231` / `502386..502397`) deals tooltip base damage with `0%` SP scaling on its own, while Grace
  (`504070`) still grants `+10%` SP to Sunflare and keeps Dawnsear's ADR 0026 scaling intact.
- Chosen of the Light (`800622`) heals once per application for `15%` max health (`12%` net under class tuning `887015`)
  when taking damage below `50%` health, and clients receive the patched `706442` `BasePoints` so cast and buff
  tooltips both read `15%`.
- Dawnfall (`806118`) increases all damage from the caster by `+15%` (magic spells, Physical spells, and melee
  auto-attacks).
- Vows of Radiance, Dawn, Grace, and Light proc on `100%` overheals; Vow of the Eclipse (`807435`) remains gated on
  effective healing.
- Vow of Dawn (`803491`) under Fulfillment bounces to `4` additional targets (`5` total on a single-target spell).
- Vow of Light (`807547`) heals the nearest nearby ally (falling back to self when alone), and fulfills on incoming
  direct hits/heals while Dawn is active without spending Dawn charges.
- Vow of Grace (`803719`) continues halving Sun Cleric spell mana costs while Dawn is active.
- Daybreak Rank 6 (`572035`, level 58) is part of the `500147` progression chain.
- Greater Devotion of Dawn (`572390`) buffs ranged AP across the raid within `100 yd`, Greater Devotion of Grace
  (`681160`) applies `-5%` cost reduction across `30 yd`, Rejuvenating Rays (`807240`) cannot be cast in combat or
  indoors, and Judgement Day (`570125`) caps at `8 s` against players before diminishing returns.
- No other class is reached: every change is gated by `SpellFamilyName == 33`, `CLASS_SUN_CLERIC`, or class `27`.
