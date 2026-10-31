# Skin Peeler Quest + Apex Mini Bosses

> **Status: locked.** All three apex hunts, the quest chain, the trophy hides, the reward and the shared scaling blueprint are finished and running. The diploma and the title are gone by decision: the reward is the Skin-Peeler 9000 alone.

---

## 1. Concept

The Skin-Peeler 9000 is no longer bought from the Bazaar. It is earned by doing what it automates: hunting three apex beasts and skinning their carcasses yourself.

---

## 2. Player-facing flow

1. At level 60, **Torvald Greyfeather** (Stormwind, Dwarven District) or **Zul'khar** (Orgrimmar, Valley of Honor) offers **The Three Apex Hunts**.
2. The quest carries three objectives, one per hide. Each hide drops from its own boss and only while the quest is held.
3. Return the three hides to the huntmaster. The reward is the **Skin-Peeler 9000**, a real one-hand dagger that carries the skinning bonus.

There is no level 58 contract stage and no follow-up chain. One quest, three hunts, one turn-in.

---

## 3. Huntmasters

| Field | Torvald Greyfeather | Zul'khar |
| --- | --- | --- |
| Entry | `9916113` | `9916114` |
| Spawn GUID | `9999266` | `9999265` |
| Map / position | `0`, `-9168.719, 768.735, 154.275` | `1`, `2003.636, -4645.846, 25.913` |
| Faction / flags | `35`, `npcflag 3` | `35`, `npcflag 3` |
| Base display / preset | `53` / Moonlit Great Lynx | `1478` / Emberlit Great Lynx |
| Respawn | `300 s` | `300 s` |
| Movement | stationary | stationary |

The appearance comes from `creature_display_preset` over the stock mirror-image exchange (`CMSG_GET_MIRRORIMAGE_DATA` `0x0401` → `SMSG_MIRRORIMAGE_DATA` `0x0402`); no custom model is involved. `AscensionCompat.cpp` sets `UNIT_FLAG2_MIRROR_IMAGE` for any creature with a preset, which is what makes the client request the paper doll.

Teleport: `.go creature 9999266` / `.go creature 9999265`.

---

## 4. The three apex bosses

All three are level 60 elites, faction `16`, passive on spawn and after reset, and only open the fight from `DamageTaken` (`CreatureAI::AttackedBy` is commented out in this core). Respawn is **30 minutes** (`creature.spawntimesecs = 1800`) for each.

| Boss | Entry | Spawn GUID | Map | Position |
| --- | --- | --- | --- | --- |
| Nytharos, the Drowned Oracle | `9916224` | `9999269` | `1` Azshara | `2269.03, -6608.37, 125.192` |
| Stormfang, the Crackling Fury | `9916222` | `9999267` | `0` Hinterlands | `146.714, -4587.26, 119.685` |
| Vaelthara, the Scarred Matriarch | `9916223` | `9999268` | `1` Feralas | `-3908.87, 1946.0, 81.0109` |

Teleports: `.go creature 9999269` / `9999267` / `9999268`.

> **Entries were renumbered.** They were `9916212`–`9916214` and are now `9916222`–`9916224`. The client caches NPC query responses in `npcs` keyed by creature entry and never re-queries a cached entry, so the quest item block added to `creature_questitem` was invisible on the old ids. New entries force a real `CMSG_CREATURE_QUERY`, which is what delivers those items to the client. Spawn GUIDs, path ids and loot are unchanged apart from the entry they point at.

### 4.1 Nytharos

One pressure layer at a time, never overlapping. Loop: melee window → Crushing Depths → Waterspouts → Tidal Bulwark → melee window.

| Ability | Spell | Behaviour |
| --- | --- | --- |
| Crushing Depths | `1004270`, carrier `1004311` | 4 s non-interruptible channel, 360°, 7 yd. 2.5% of each victim's pool per 0.7 s tick. |
| Waterspouts | aura `1004290`, slow `1004292` | 4/5/6 unselectable twisters 15–25 yd out, 15 s. Contact = 6% of pool + Soaked (−40% speed, 4 s). |
| Tidal Bulwark | `1004300` | 8 s absorb of 12 / 13.8 / 15% of his scaled pool. Pulses a 15 yd knockback on everyone within 10 yd every 3 s (2 s in phase 3). Unbroken, heals half of what remains. |
| Auto-attack | carrier `1004310` | 6% of the victim's pool before armour, every 2.0 s. |

Phases: 100–66% (10 s window), 66–33% (8 s), ≤33% (8 s, 6 spouts, 15% shield, 2 s pulse). A 6 s global gap is the floor between ability starts, and nothing starts while channelling, shielded, or while any spout lives.

### 4.2 Stormfang

| Ability | Spell | Behaviour |
| --- | --- | --- |
| Thunder Pounce | `1004112`, impact `1004116` | Leaps a non-tank within 30 yd; 6% of pool on landing plus a 15 yd knockback and 2 s stun. |
| Storm Howl | summons `9916211` | Two level-60 spirit wolves, 25 s lifetime. Their bites are 1% of the victim's pool. |
| Stormcall | `1004117`, tick `1004118` | 7 s self-root channel, 7 pulses of 100 nature to every hostile player within 50 yd. |
| Thunderclap / Rake | `100377` / `100331` | Every 12 s / 8 s on the current victim, deferred while Stormcall runs. |

Phases only shorten the Pounce, Howl and Stormcall cadences at 70% and 40%; there is no enrage. Yells at pull, 65% and 30%.

### 4.3 Vaelthara

| Ability | Spell | Behaviour |
| --- | --- | --- |
| Hunger | `1004200` + states `1004201`–`1004204` | +1 stack per landed melee, cap 20, decays after 3 s without contact. Starving <12 (−15% damage, −10% speed), Frenzied 12 (+35% damage), Gorged 20 (+60%, 10 s CC immunity). |
| Owlcat Rend | `1004210`, wounds `1004211`–`1004215` | Every third landed swing; 4% direct plus Festering Wound I–V at 20–100 per second for 12 s. |
| Bloodrush | `1004220`, impact `1004221` | Leaps the farthest engaged player, 6% of pool on landing. A stun or root mid-leap leaves her Winded (`2880`, 5 s). |
| Stalk | marker `1004230` | Fixates a random engaged player for 6 s, +1,000,000 threat, own Bloodrush. |
| Whirling Claws | `1004240` | 4% of pool within 12 yd plus a 20 yd knockback. |
| Desperation | `1004250` | Below 35%: +30% physical, +20% speed, +20% melee haste. Removed when healed back above 35%. |

Her auto-attacks always land: `OnBeforeRollMeleeOutcomeAgainst` zeroes miss, dodge, parry and block for her swings only, because a stalled swing stalls Hunger and the Rend ladder for reasons players cannot influence.

---

## 5. Quest data

| Field | Value |
| --- | --- |
| Quest ids | `17839` Alliance, `17844` Horde |
| Objectives | item objectives: `1009304` Tide-Warped Hide, `1009302` Stormfang Pelt, `1009303` Scarred Owlcat Pelt, count 1 each |
| Objective text | empty — the client names each objective from the item |
| NPC objectives | none |
| POI | ids `0`/`1`/`2` at objective index `4`/`5`/`6`, `Flags 3` (world-space); turn-in at `-1`, `Flags 1` |
| Super track | `coa_client_quest_super_track` `10130` / `10133`, objective `-1` only, nodes `21589` / `21603` |
| Quest flags | `524296` (`SHARABLE \| AUTO_ACCEPT`), the value stock quest `33` uses |
| Reward | `190191` Skin-Peeler 9000, amount 1 |
| Drops | `creature_loot_template`, 100%, `QuestRequired = 1` |

**Why the objectives are items and not creatures.** A creature objective makes the log line tick on the kill; item objectives tick when the hide is in the bags. The quest was specified as "picks up the pelt", so the objectives are the hides. This is also the shape of stock `33` (Wolves Across the Border): item objective, POI at the item index, quest-gated drops.

### 5.1 What draws the marker and the ring

Three independent pieces of data, none of them the objective list:

- **`creature_questitem`** (`9916222 → 1009302`, `9916223 → 1009303`, `9916224 → 1009304`). `QueryHandler.cpp` puts these six slots into `SMSG_CREATURE_QUERY_RESPONSE`, and `AscAttachFixes.cpp:836` `QuestRelevant` returns true when one of them is a `RequiredItemId` of a quest whose count is not yet met. That is the branch that marks a creature for an item objective.
- **`quest_poi` with `Flags 3`.** 23,423 rows in the database use `1` (map only) and 1,678 use `3` (map plus world space). Quest `33` carries `3` on its objective row, which is what puts the area on the ground.
- **`coa_client_quest_super_track`.** Item objectives cannot carry a node — the client only maps nodes for objective indexes 0–3 — so the only super track node is the `-1` turn-in, which is the return arrow.

The ring itself is stock client drawing, not DLL code: the reconstruction's only marker code is `AscAttachFixes.cpp` for `0x65C`, which swaps the `!` / `?` model above an NPC.

---

## 6. Reward

**The Skin-Peeler 9000** (`190191`):

| Field | Value |
| --- | --- |
| Class / subclass | `2` / `15` (one-hand dagger) |
| Inventory type | `13` |
| Item level / required level | `60` / `58` |
| Damage | `45–84`, `1.8 s` |
| Spell | `16718` skinning bonus, trigger on equip |
| Quality | `4` (epic) |
| `item_dbc` row | `190191, 2, 15, -1, 1, 41688, 13, 3` |

The `item_dbc` row is not optional: the client renders class, subclass, material, display and sheathe from `Item.dbc`, and an item without a matching row shows as an unusable blank.

**The diploma is removed.** Item `1009300`, its `item_dbc` row, its item script and the title id constant are all deleted, and the quest's reward pointer was moved from the diploma to the Skin-Peeler.

**A custom title cannot be delivered by the server.** `AscGlobalsG.cpp:102` reads the title name straight from the client's own `CharTitles.dbc` store (`0xAD3374`), male at `+0x08` and female at `+0x0C`. The reconstruction's complete patch surface is 26 tables in `AscDbcPatch.generated.inc` and six in `AscBridgeStore` (`MythicKeystones`, `SpellAffect`, `Creature`, `Quest`, `ItemAddon`, `VanityCollection`); `CharTitles` is in neither, no handler reads a table name off the wire, and the only server-run Lua channel (`AscHotPatch`, `0x8F0`) is absent from the shipped DLL. A title name therefore requires a client file, which is out of bounds.

---

## 7. Shared scaling blueprint

`ApexScaling.cpp` owns every apex number. All three bosses run the same constants, which is what keeps them from drifting apart.

| Constant | Value | Applies to |
| --- | --- | --- |
| `AUTO_PCT` | `3%` | every auto-attack, via `ModifyMeleeDamage` |
| `ABILITY_PCT` | `4%` | normal abilities, per victim |
| `HEAVY_PCT` | `6%` | telegraphed heavies (Pounce, Bloodrush landing) |
| `DOT_PCT` | `1.5%` | each DoT tick, via `ModifyPeriodicDamageAurasTick` |
| `WOLF_PCT` | `1%` | Stormfang's spirit wolves |
| group budget | `7%` of the averaged pool per tick | AoE batches |
| per-victim cap | `10%` | single AoE hit |
| `TTK` | `240 s` at 3+, `600 s` at 1–2 players | pool sizing |
| pool clamp | `0.75× – 40×` template pool | pool sizing |

**Percentage only.** Every offensive number is a share of the victim's own pool. The original spells keep their debuffs, sounds and visuals; only their flat damage is zeroed in `ModifySpellDamageTaken`, and the damage is re-delivered through a carrier spell (`1004310` physical, `1004311` nature) so armour, resistances, absorbs, crit and the combat log all stay on the engine path.

**The probe.** At pull the boss opens at `base × 4`, accumulates every point of damage that lands for **15 seconds** (melee, ranged, spells, DoTs, pets, procs), then sets its pool to

```
pool = dps × 0.85 × TTK
```

clamped to `0.75× – 40×` the template pool with the already-removed fraction preserved. The `0.85` is a sustain factor: the sample is an opening burst with cooldowns up and nobody moving.

- Sizing happens on the pool, never on a damage filter, so crit, haste, armour penetration and penetration keep their relative worth.
- The ceiling was raised from `12×` to `40×` because every group of three or more saturated it at 256,320: five players were fighting exactly the same pool as three.
- Resets restore the template pool and clear the probe, but only when **no players are still in reach** (`ApexScaling::StillEngaged`); a momentary evade during Vaelthara's leap used to reset her permanently.
- The small-group TTK of `600 s` is structural: one or two players cannot finish an apex boss, and that is a rule rather than a lucky roll.

**Interaction with upstream creature scaling.** `ScaleHealth` captures `GetMaxHealth()` at spawn and multiplies that, so whatever `CoACreatureScaling` already did to the pool is the starting point. The apex entries are deliberately absent from `coa_boss_flex`, because that table tells the server to skip its own health scaling and would strip the baseline. The pull-time log prints `base <n> (create <m> x<ratio>)`; with level scaling on, the ratio must read ~1.95 at 60.

---

## 8. Balance passes

### 8.1 Method

Every pass uses the same harness and the same criteria. A boss is only "locked" when all of the following pass:

| Suite | What it proves |
| --- | --- |
| Gear bands 50 → 80 | six item-level bands, boss health remaining inside a fixed window |
| Group sizes 1 → 5 | pool scales with headcount |
| Kill time at 3 players | TTK lands inside the 240 s target |
| Solo and duo | cannot kill in any realistic window |
| Probe edges | burst pull, late join, re-engage after leaving |
| Damage sources | spell, DoT, ranged and pet damage all feed the probe |
| Percentage parity | the same fight costs the same share at a 60k and a 300k pool |
| Pool share | equal percentages across different pool sizes |
| Wipe / evade | pool returns to the template value |
| Tank death | retarget without a stall |
| Soak | repeated pull cycles with no state leak |

Test assets, all under `apps/coa-gameplay-test/scenarios`:

| Boss | Scenarios |
| --- | ---: |
| Nytharos | 117 |
| Stormfang | 65 |
| Vaelthara | 64 |

### 8.2 Gear-band result (Nytharos, three players, 40 s window)

| Band | measured DPS | pool | remaining |
| --- | ---: | ---: | ---: |
| 50–55 | 151 | 36,176 | 79.5% |
| 55–60 | 205 | 49,168 | 75.9% |
| 60–64 | 177 | 42,432 | 76.2% |
| 65–70 | 198 | 47,424 | 77.4% |
| 70–75 | 286 | 68,752 | 75.0% |
| 75–80 | 257 | 61,712 | 74.9% |

A **4.6-point spread** across a range where raw output nearly doubles.

### 8.3 Pool by group size after the shared blueprint

| Boss | 1 player | 3 players | 5 players | Solo leaves |
| --- | ---: | ---: | ---: | ---: |
| Nytharos | 79,736 | 279,248 | 503,934 | 23,184 |
| Stormfang | 129,336 | 212,568 | 286,674 | 50,914 |
| Vaelthara | 133,212 | 164,478 | 305,048 | 39,745 |

### 8.4 Percentage parity (15 s, 60k vs 300k pool)

| Boss | 60k | 300k | spread |
| --- | ---: | ---: | ---: |
| Stormfang | 47.3% lost | 50.2% lost | 2.9 pts |
| Vaelthara | 55.6% lost | 53.5% lost | 2.1 pts |
| Stormfang wolves | 79.13% left | 79.12% left | 0.01 pts |

A flat-damage kit loses five times the share at the small pool.

### 8.5 Per-boss suite results

| Suite | Stormfang | Vaelthara |
| --- | --- | --- |
| Class matrix (32 classes/specs) | 31 pass, 1 blocked | 31 pass, 1 blocked |
| Gear bands | 6/6 | 6/6 |
| Group sizes | 5/5 | 5/5 |
| Kill time | pass | pass |
| Solo + duo | 2/2 | 2/2 |
| Probe edges | 2/2 | 2/2 |
| Damage sources | 3/3 | 3/3 |
| Parity | 2/2 | 2/2 |
| Pool at 1/3/5 | 3/3 | 3/3 |
| Wipe restore | pass | pass |
| Tank death | pass | pass |
| Soak | pass | pass |

### 8.6 Defects the passes found

1. **Auto-attack was 180% of the tank's bar per minute**, double the 90–110% target; halved from 6% to 3% per swing.
2. **An unbroken Tidal Bulwark healed the full absorb**, cancelling everything a low-DPS group produced; it now heals half of what remains.
3. **The spout step could stall the loop** when a summon outlived its despawn, so the shield step never ran; the step is now bounded by its own timer.
4. **Vaelthara stalled at roughly half health**: her leaps dropped combat for an instant and the probe read that as the end of the pull. The reset now requires no players in reach.
5. **A solo player could still kill both converted bosses** at the 400 s small-group target; it is now 600 s.
6. **Class scenarios used a human for every class**, which cannot be a shaman or druid; both were re-run with valid races.
7. **Stormfang's spirit wolves were the last flat-damage source**; they now bite for 1% of the victim's pool.

### 8.7 Harness limits

- **Death Knight** character creation times out at level 60 and 55 on the hero-class path. The same failure reproduces on a scenario that passed before, so it is the harness, not the boss.
- **Sub-spec activation** is rejected by the server, so the class matrix is 31 of 32.
- Gear fixtures must run **before** the boss is summoned: a hostile creature in the scene puts the characters in combat and they can no longer equip.
- A boss summoned by a player is friendly and will not engage; combat scenarios need the setup-time spawn.

---

## 9. Skinning behaviour

The companion skinning path is `Player::LootCreatureWithCompanion` called from `ProcessCompanionLoot`, and it is native in every respect:

- The skinning is a **triggered** cast of `8613`, so it resolves instantly with no cast bar.
- The cast runs through `Spell::CheckCast` for `SPELL_EFFECT_SKINNING`, which enforces the profession rules: skinnable flag present, corpse looted, and skill against creature level with `req = skill < 100 ? (level − 10) × 10 : level × 5`.
- A corpse that has not been looted yet is refused (`SPELL_FAILED_TARGET_NOT_LOOTED`); that is the profession rule, not a companion quirk. Loot the corpse and the next pass skins it.
- The skinning spell is only cast while the corpse is not yet `LOOT_SKINNING`, which is why the effect appears once per corpse rather than on every pass.

The LootBot skin-peeler appearance is a collection appearance (`category 61`, appearance `639807`). It automates the cast; it does not bypass the skill check.

---

## 10. Revision index

| Area | Revisions |
| --- | --- |
| Quest, items, POI | `rev_20261030_01` … `rev_20261030_18` |
| Fresh creature entries | `rev_20261030_15_apex_fresh_entries.sql` |
| Creature quest items | `rev_20261030_14_apex_creature_questitem.sql` |
| Reward and diploma removal | `rev_20261030_16_apex_reward_fixes.sql`, `rev_20261030_18_apex_remove_diploma.sql` |
| Huntmasters | `rev_20261024_03` … `rev_20261024_06` |
| Stormfang kit | `rev_20261024_07` … `rev_20261024_13`, `rev_20261025_01` |
| Vaelthara kit | `rev_20261025_03` … `rev_20261026_12`, `rev_20261026_70_rename_vaelthara.sql` |
| Nytharos kit | `rev_20261026_13` … `rev_20261026_40` |

All paths are under `data/sql/updates/pending_db_world`.

---

## 11. Known gaps

- **Death Knight and sub-spec coverage** remain unreachable in the harness, so those two cells of the class matrix are untested.
- **Custom title**: not deliverable without a client-side DBC; the diploma was removed instead.
- **Account-wide Skin-Peeler unlock** is not implemented; the tool is a normal item reward.
