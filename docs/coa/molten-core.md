# Molten Core restoration — state of play

This documents the actual state of Molten Core (map 409) on CoA after `feat/mc-restoration`, and what the
branch changed. As with the other `docs/coa/` write-ups, this describes the real state, never the wished one:
every row below is tagged with the evidence it rests on, and every open point is left open rather than guessed.

## 1. Summary

Molten Core ships with four difficulties — Normal, Heroic, Mythic and Ascended — using CoA's usual
`entry`/`entry+100000`/`entry+200000`/`entry+300000` variant scheme, flexed for 10–25 players. Before this
branch, the raid was in a materially broken state:

- Loot, health and access rules were not CoA's own values on any difficulty.
- Two competing AI systems existed for the seven `coa_boss_ai`-driven bosses (Lucifron, Gehennas, Garr,
  Shazzrah, Baron Geddon, Sulfuron, Golemagg): a hand-written AzerothCore script per boss (dead code, since
  `coa_boss_ai`'s `ScriptName` wins resolution) and the data-driven `coa_boss_schedule`. Twelve SmartAI trash
  types had ability rows only for their base (Normal) entry, with none for their `+100000/200000/300000`
  variants — they lost every scripted ability above Normal. Three trash types (Lava Annihilator, Lava
  Elemental, Lava Reaver) had no AI at all, on any difficulty, despite having a real CoA kit.
- The "Damage Info" mechanism (a family of per-difficulty aura rows meant to feed a handful of boss spells'
  damage) had no server-side reader, so those spells dealt their DBC placeholder amount (about 2 damage) on
  every difficulty.
- Four trash creatures ran under names that didn't match CoA's, though role/level/rank already lined up.

This branch restores CoA's loot tables, health, and access rules on all four difficulties; wires the Damage
Info mechanism; completes Lucifron's, Golemagg's, Garr's and Shazzrah's kits within the evidence available;
retunes Ragnaros's three exclusive-caster spells to CoA's own ids; fixes Garr's Firesworn not respawning on a
wipe (#5391); replicates trash abilities onto their missing difficulty variants; gives three previously
silent trash types a kit; renames the four mismatched trash entries; stops Lucifron patrolling into
Magmadar's room; summons and buffs Shadow of Lucifron (12268) a few seconds after pull; restores Magmadar's
two head creatures (80642/80643) with a working ground-fire puddle; and fixes the raid schedule's event
clock so it keeps advancing while a boss briefly has no victim. A 32-run probe campaign also disproved
several suspected "tier split" defects (Sulfuron, Golemagg, Lucifron, Gehennas resolve their scheduled spell
ids through `SpellDifficulty.dbc` at cast time) — see [Verification](#verification).

A follow-up pass, driven by a 54-log combat-log corpus (see [Evidence: live combat logs](#evidence-live-combat-logs)),
adds three CoA-only encounter pieces the export only ever had as level-1/health-1 placeholder stubs: Ragnaros's
Son of Flame merge chain (Lesser → Son → Greater → Unstable, 12143/92026/92027/92028), Sulfuron's four
disciples (Corvus the Nimble plus three newly named adds on Mythic/Ascended), and
Majordomo's Sacrificial Chains add (92030). All three were confirmed in-game this session — see `verify-ABC.md`
under [Verification](#verification). What is *not* restored, and why, is in [§8](#8-known-gaps--needs-decision).

## 2. Access

- **Level**: 60 on every difficulty (`dungeon_access_template`, all four rows).
- **Ascended requires Attunement to the Core**: quest 7848 (Alliance) / 7487 (Horde), both given and ended by
  Lothos Riftwaker (NPC 14387, Blackrock Mountain). Completing either rewards item 666000, the Molten Core
  Medallion (Binds when picked up, +15 Fire Resistance, tooltip: "Possession of this medallion grants access
  to the Molten Core."). `dungeon_access_requirements` gates Ascended (difficulty id 124) on the matching quest
  per faction. Evidence: exiles-kit (quest/item/NPC records) + measured (the branch's own access SQL).
- Lothos's teleport into Molten Core is gated by the same quest state, consistent with the medallion's own
  tooltip; no separate teleport-specific gate exists beyond the quest/item pair.
- The quest reward previously included leveling XP; a CoA client-cache diff shows it retuned to a
  near-zero-XP "flag" quest at some point — consistent with its role as a gate, not a leveling quest.

## 3. Per boss

Evidence tags: **measured** (our own 42-log/89-pull corpus behind `coa_boss_schedule`, or a probe campaign run
this session), **exiles-kit** (CoA database export, db.exil.es, 2026-09-13), **dbm** (DBM-MC, Zidras/DBM-Warmane),
**snit-wa** (Snit's WeakAuras), **designed** (chosen without direct evidence, flagged as such).

### Evidence: live combat logs

A separate corpus backs the three CoA-only adds below: 54 combat logs (~10M records, 0 unparsed) run through
the user's own combat-log parser (generic log-to-structured-dataset tool: fights/casts/auras/damage per pull,
joined by creature entry and inferred difficulty). Coverage is uneven: Ragnaros 33 pulls (mostly wipes),
Lesser/Son of Flame 40N+72A/16N+28A, Sacrificial Chains 48/49 Majordomo pulls, Sulfuron's disciples 3
Mythic/Ascended pulls only, zero Normal/Heroic Sulfuron or Majordomo pulls. Gaps: no difficulty offset
survives in recorded GUIDs (difficulty is inferred, not read); no coordinates, so proximity mechanics (merge
range, summon placement) are timing-only; several adds (disciples, Sacrificial Chains, the "Hidden" cluster)
show 0 counted casts — only aura/health/damage-taken events are reliable for them. Full stats:
`logs/coverage.md`, `logs/mc-summary.md` (gitignored, `.agents/plans/mc-restoration/`).

### Lucifron (12118)

| | Reality (CoA kit + evidence) | Before this branch | After this branch | Evidence | Open question |
|---|---|---|---|---|---|
| Shadow Bolt | 2105212→2105213, area, 5.3s/15.1s | ran, placeholder ~2 dmg | Damage Info wired, real per-difficulty damage (800/1600/2400/3200) | measured + exiles-kit | — |
| Fierce Blow | 975011, tank, 8.4s/7.8s | ran | unchanged | measured | — |
| Curse of Lucifron | 2105206→2105207, area, 18.8s/79.9s | ran, placeholder dmg | Damage Info wired | measured | — |
| Suppressing Shadows | 2105218, area, 29.2s/25.1s | ran; landing effect (2105219) missing | landing effect 2105219 added to the row | designed (row shape), measured (timers) | — |
| Impending Doom | 2105201→2105205, area | absent — no schedule row at all | added, first 7s/period 20s | dbm (DBM-Warmane vanilla Doom, CD20/first7); no log ever recorded this cast | timer is a vanilla-CD borrow, not a measured Ascension interval |

Health: `coa_boss_flex` `hp_d0..d3` 588,759/785,012/1,181,513/1,722,727 (rebuilt from a direct CoA video
reading at Ascended; d0-d2 from Lucifron's own prior shape anchored on it — see §5).

Lucifron previously ran `MovementType=2` (WAYPOINT) on a path leading straight toward Magmadar's spawn,
matching the reported "wanders into Magmadar's room, with 2 adds" exactly (the Flamewaker Protectors follow
him via `creature_formations`). `rev_20260930_90` fixed the wandering (`MovementType=0`, `path_id` cleared,
the orphan `waypoint_data` rows dropped) but kept the export's own static anchor, which still sat in the open
corridor leading into Magmadar Cavern, not in Lucifron's own room — a second, independent part of the same
report. `rev_20260930_98` moves him into that room: world (959, -938, -181.997, o=5.729), computed by fitting
an affine pixel→world transform of the Molten Core world map against our own measured boss positions
(Lucifron, Magmadar, Gehennas, Garr, Shazzrah, Geddon, Sulfuron, Golemagg — map 409 `creature` rows) and
solving for the alcove the player circled on the map (south-west of the Magmadar Cavern mouth, north-east of
Ragnaros' Lair); ground and orientation confirmed live via GM teleport + `.gps` on slot 3 (solid floor,
FloorZ -181.997, closely matching the old Z and Magmadar's). The same revision removes Flamewaker Protector
(12119, guids 56606/56607) outright rather than relocating them with him — the player's own "no adds" account
is the decision now, superseding the export-placement reading in the superseded §8 item 7 below.
The spot was too close to the passage: `rev_20261001_30` moves him to the back of the alcove, (923.3191, -925.5587,
-189.90823, o=5.962888), read in game with `.gps` by the player standing where he should be (FloorZ -189.9082,
VMap and MMap height data present).

**Shadow of Lucifron (12268)** is summoned once, 5s after engage, via a small `coa_boss_summon` hook
(`summon_entry`/`summon_delay_ms`/`summon_buff_spell` columns on `coa_boss`, read by `CoaBossAI`) instead of a
bespoke boss script, since Lucifron keeps his existing measured `coa_boss_ai` schedule otherwise unchanged.
Lucifron casts buff 2105223 once at the summon (its two `MOD_DAMAGE_PERCENT_DONE` +39% Shadow effects land
one on the new Shadow, one back on himself — "increases his and his master's Shadow damage done"). Shadow's
kit: Shadow Bolt (2105254 dummy → 2105255 real hit, Damage Info 2105250-53, measured in-probe at
800/1600/2400/3200 vs. the DBC's 801/1601/2401/3201), Shadow Cleave (2105256, cone, 44% weapon damage) and
Dark Sundering (2105257, 44% weapon damage + stacking armor reduction). No static spawn or summon-spell
evidence exists for 12268 anywhere in the export; the summon delay and health (25% of Lucifron's own flex
figure, anchored to the Flamewaker Protector/Lucifron ratio) are `designed`, not measured — flagged in §8.

**Flamewaker Protector (12119)** no longer spawns at Lucifron at all (`rev_20260930_98`, player decision —
see §8 item 7). Before its removal it cast Dominate Mind (20604 — a real `MOD_POSSESS` aura, not a dummy) on
a random non-top-threat target every 5s, confirmed firing repeatedly in probe runs; vanilla Lucifron himself
carries Mind Control under this same id, so on CoA it had been wired to the add instead of to Lucifron's own
schedule. That ability has no replacement — it left the fight with the add, not moved onto Lucifron (§8 item
14 is resolved the same way: the question of where Dominate Mind belongs no longer applies to this
encounter).

### Magmadar (11982)

| | Reality | Before | After | Evidence | Open question |
|---|---|---|---|---|---|
| Body casts nothing (kept as stock melee/Frenzy/Panic); two head creatures (80642/80643) cast Enrage (2105307), Scorching Breath (2105360 dummy → hidden 2105361 → real hit 2105362-65), Lava Burst (2105357, Damage Info 2105351-54) and Lava Bomb ground fire (2105366 dummy → persistent-area 2105367-70) | stock `boss_magmadar` script only | new `boss_magmadar_coa.cpp`: on engage, `DoSummon`s both heads (`TEMPSUMMON_MANUAL_DESPAWN`, difficulty variant auto-resolved by `creature_template.difficulty_entry_1..3`) plus periodic Core Hound (11671) reinforcements | new head kit wired and cast on schedule; ground-fire puddle fixed (see below); heads share the body's health pool (see below) | exiles-kit (heads' spells) + measured (in-probe cast/damage confirmation, lm-validation.md) + MC_PV video ("PV = Magmadar") for the shared pool | Core Hound entry/count/cadence (2 hounds, first 45s/repeat 50s) is `designed`, not measured — see §8 |

The two heads don't exist as a static spawn or a vehicle passenger anywhere in the export — they are summoned
by the body's own script on engage, the same idiom already used for Garr's Firesworn. `Lava Burst`'s
placeholder damage resolves through the same `coa_spell_damage_info` mechanism as the rest of the branch
(measured d0-d3: 1600/2133/2666/3200). The ground-fire puddle (2105367-70) initially never produced a single
event in-probe: its follow-up cast used `target->CastSpell(...)`, so `EffectPersistentAA`/
`SelectImplicitAreaTargets` searched for the hit *player's* enemies around the dest point instead of the
raid's — fixed (`cafb24165`) by casting from the head instead, matching the already-working Scorching Breath
idiom; validated on all 4 difficulties (294-528 periodic damage ticks/run, correct per-difficulty spell id).

Every MC_PV video reading for the heads is annotated "PV = Magmadar" — they always display the same health as
the body. The prior 70% body / 15% per-head split of a shared Golemagg-derived total (rev_20260930_91) is
replaced: Magmadar now has his own direct CoA video reading (§5), both heads carry his row unchanged, and
`boss_magmadar_coa.cpp` makes the body the only damage target — heads are immune to all damage
(`SetImmuneToAll(true)` on `Reset()`) and mirror the body's current health every `UpdateAI` tick via
`InstanceScript::GetCreature(DATA_MAGMADAR)`, rather than holding an independent fraction of the total.

### Gehennas (12259)

| | Reality | Before | After | Evidence | Open question |
|---|---|---|---|---|---|
| Fierce Blow 975011, tank, 7.0s/8.5s | ran | unchanged | measured | — |
| Rain of Fire 2105407, area, 8.5s/30s | ran, placeholder dmg | Damage Info wired | measured + exiles-kit | Unquenchable Flames (2105411-14) is the spell's own built-in `EffectTriggerSpell`, not a separate cast — confirmed no gap |
| Incinerate 2105405→2105406, area, 9.5s/15.1s | ran, placeholder dmg | Damage Info wired | measured + exiles-kit | — |
| Curse of Gehennas 2105415→2105416, area, 11.1s/39.9s | ran | unchanged | measured | Dispel-punish proc (2105423/24) needs a `SpellScript`, not a schedule row — not added |
| Immolate 2105429→2105430, random non-tank, 15.4s/20s | ran, placeholder dmg | Damage Info wired | measured + exiles-kit | — |
| Conjure Flame Orb 2105417, tank, 50.7s/78.1s | ran | unchanged | measured | — |

Health: `hp_d0..d3` 884,118/1,178,824/1,774,235/2,586,957 (rebuilt from a direct CoA video reading at
Ascended — see §5).

### Garr (12057)

| | Reality | Before | After | Evidence | Open question |
|---|---|---|---|---|---|
| Fierce Blow 975011, tank, 12.0s/8.2s | only scheduled ability | unchanged | measured | Only 1 measured schedule row for Garr — sparsest of the 7 `coa_boss_ai` bosses; log-coverage gap or true current kit is unresolved |
| Antimagic Pulse, Magma Shackles, Separation Anxiety/Mass Eruption (dead C++ kit) | unreachable (`coa_boss_ai` wins over `boss_garr.cpp`) | replaced by a new `boss_garr_coa.cpp` (own BossAI) | Harden (self-buff, 20s), Land Slide (self, 20s/30s, knockback AoE), Unstoppable Force (self, 45s/45s: drops Harden, applies Cracked+Earth Fury, summons an extra Firesworn, 20s recovery) | designed (all four timers; no log ever recorded them) | Harden/Cracked/Earth Fury's real stack-counting cycle was simplified to a flat crack-and-recover loop; Land Slide's "charge through" is a self-centered AoE, not pathing |
| Firesworn respawn on wipe (#5391) | not respawned; instance script only had the Golemagg branch | fixed: `_garrFireswornGUIDs` tracked, respawned on `NOT_STARTED`/`FAIL` mirroring Golemagg | measured (code read) | — |
| Firesworn Eruption damage (#5388) | 19497 (~3000 dmg) flat on Normal/Heroic, 350126 (~4600) on Mythic/Ascended — a real `SpellDifficulty.dbc` family, not an Ascended value leaking onto Normal | unchanged | unchanged | exiles-kit + dbc | Not flex-scaled by raid size/gear the way boss casts are — needs a decision on whether that's the actual defect (§8) |

Health: `hp_d0..d3` 1,105,520/1,474,027/2,218,539/3,234,783 (rebuilt from a direct CoA video reading at
Ascended — see §5).

"Garr Earthquake"/"Garr Cave In" (Snit's WA ids 500297/500298) were checked directly against `Spell.dbc` this
session: neither id is an earthquake or cave-in spell (500297 is a cosmetic banner prop, 500298 an unrelated
proc buff) — treated as stale/recycled aura data, not a real Garr mechanic, and not built on.

### Shazzrah (12264)

| | Reality | Before | After | Evidence | Open question |
|---|---|---|---|---|---|
| Arcane Explosion 2105601, tank, 3.6s/8.4s | ran | unchanged | measured | — |
| Fierce Blow 975011, tank, 6.6s/9.2s | ran | unchanged | measured | — |
| Dampen Magic (self) 2105607→608, 14.1s/30.2s | ran | unchanged | measured | — |
| Blink 2105611, area, 14.6s/16.4s | ran as a plain teleport | Gate of Shazzrah's threat wipe (`ResetAllThreat`+`AddThreat`+`AttackStart`) bound via a new `SpellScript` | measured (timer) + measured (dead-code comparison to `boss_shazzrah.cpp`) | The wipe now always lands on the tank (`TARGET_AREA` resolves to the tank), not a random raid member as vanilla did |
| Arcane Instability 2105605→606, area, 18.4s/65.2s | ran | unchanged | measured | — |
| Mass Counterspell (self) 2105609→610, 23.6s/34.8s | targeted Shazzrah himself, both spells carry `SPELL_ATTR3_ONLY_ON_PLAYER` → `SPELL_FAILED_TARGET_NOT_PLAYER`, never landed | retargeted to tank (Dampen Magic) / area (Mass Counterspell) — `rev_20260930_87` | measured (docker cast-failure logs + Spell.dbc effect targets) | — |
| Arcane Force Nova 2105612→617, area, 44.3s/64.6s | appeared "never" cast in short probe windows | unchanged spell, but `coa_boss_ai`'s event clock previously stalled a tick whenever the boss briefly had no victim (e.g. mid-teleport); fixed (`35c4f405e`) so the clock advances on every elapsed tick | measured (confirmed firing in the 32-run campaign once the clock fix landed) | superseded below: the clock fix made it fire, but it still dealt no raid damage |

**Arcane Force Nova dealt no raid damage even after the clock fix (confirmed defect, fixed this session).**
rev_20261001_02 bound 2105617 (the dummy's completion cast) to the real per-difficulty amount via
`coa_spell_damage_info`, fixing the DBC placeholder (1 damage) — but left the cast itself pointed at
2105617, whose own `EffectImplicitTargetA` is `TARGET_UNIT_TARGET_ANY` (a single unit, whichever
target `CoaBossAI::Cast()` passed — the tank), not an area. Live Ghost reproduction confirmed it: one
Nova landed exactly one real hit (7413 on the tank) and zero on the rest of a 5-bot raid. The real
area spells are 2105613-16 themselves ("Arcane Force Nova - Hidden Area Damage", `Spell.dbc`:
`TARGET_UNIT_DEST_AREA_ENEMY`, `EffectRadiusIndex` 12 = 100yd, `SPELL_ATTR0_DO_NOT_DISPLAY`/
`DO_NOT_LOG` — Blizzard's own hidden-trigger-effect pattern, never meant to be cast directly) already
carrying the correct amount *and* the correct area target type; nothing ever cast them. No `Spell.dbc`
row (2105612/2105613-16/2105617 checked individually) carries `SpellDifficultyId` pointing at
`SpellDifficulty.dbc` group 2114, whose four `SpellID` columns happen to equal 2105613-16 — that
group is orphaned data the engine cannot reach by casting any one id, so `coa_boss_schedule`'s single,
difficulty-shared `effect` column could not name this per-tier family by itself (every other
dummy/effect pair in this table uses an id that is the same across tiers).

Fixed by letting `effect` differ per difficulty, the same shape `spell_d0..d3` already uses for casts
whose id genuinely differs by tier (`coa_boss_schedule` gains `effect_d1`/`effect_d2`/`effect_d3`
columns, `effect` renamed to `effect_d0`; `CoaBossAI.cpp`'s `ScheduleRow::effect`/`EffectFor()`
mirror `spell`/`SpellFor()`). Shazzrah's Nova row now names 2105613/2105614/2105615/2105616 directly
and the now-dead `coa_spell_damage_info`/`spell_script_names` rows for 2105617 are dropped.
Re-verified live (Ghost harness, slot 4, grouped 5-bot raid, Normal difficulty): the same Nova now
hits multiple distinct raid members in one cast (`SMSG_SPELL_GO` hit list `bot02,bot01`;
`SMSG_SPELLNONMELEEDAMAGELOG` 7298 pre-resist on bot02, 7784 pre-resist on bot01 — both within normal
roll variance of the Normal-tier corpus figure 6999), where the pre-fix build hit exactly one bot per
cast. Only 2 of the 5 raid members were hit in that run despite a 100yd effect radius comfortably
covering the whole encounter room; the other 3 bots' exact state at that tick (position/combat/LOS)
was not captured by the harness, so the cause of the partial hit count is not pinned down — flagged
as an open question, not re-opening the single-target defect this fix closes (the pre-fix build hit
*at most one* target ever; the post-fix build's own `SMSG_SPELL_GO` already reports a genuine
multi-target hit list for a single cast). Heroic, Mythic and Ascended were not re-verified live this
session (not yet run).

Health: `hp_d0..d3` 775,397/1,033,863/1,556,054/2,267,615 (rebuilt from a Bronzebeard video reading at
Ascended times the C=3.306 BB->CoA coefficient — see §5). Time Stop (2105618) and Mass Slow (2105619) exist in the kit with no schedule row and no
corroborating log/addon evidence — left as needs-decision, not added.

### Baron Geddon (12056)

| | Reality | Before | After | Evidence | Open question |
|---|---|---|---|---|---|
| Fire Strike / Fierce Fire Strike / Ignite Powers / Engulf in Flames / Living Bomb / Melt Through / Inferno / Armageddon (all 8 measured rows) | ran, several with placeholder Damage Info dmg | Damage Info wired for the placeholder rows | unchanged timers | measured | Inferno/Living Bomb/Ignite Powers run at roughly 1.5–3× vanilla DBM's cooldowns — consistent across all three, read as a deliberate Ascension retune, not left as a defect |

Inferno and Armageddon looked broken in early probe campaigns (Inferno never `cast_start`ing, Armageddon
starting but never completing) but both needed **no** code or data change: both are already fully
data-driven through existing `SpellDifficulty.dbc` groups. The real cause was a test-harness bug (probe
teleports dropping bots from Geddon's threat list, forcing repeated evades) — fixed in the disposable Ghost
harness, not this repo; see [Verification](#verification). Confirmed working on all 4 difficulties: Inferno
pulses 10× at 1s intervals for 875-1999 damage, Armageddon's 2105748 hits all 10 bots for 8.75-10.0M.

Health: `hp_d0..d3` 884,285/1,179,047/1,774,570/2,586,957 (rebuilt from a direct CoA video reading at
Ascended — see §5).

**Living Bomb explosion (designed, not corpus-evidenced — see §8).** The carrier aura (2105702-05) applies
`SPELL_AURA_PERIODIC_TRIGGER_SPELL_WITH_VALUE` (227) on effect 0, not `SPELL_AURA_PERIODIC_TRIGGER_SPELL` (23)
as its own self-damage trigger id might suggest; `spell_geddon_living_bomb_explosion_coa`
(`boss_geddon_coa.cpp`) originally registered its `AfterEffectRemove` hook against the wrong aura name (23),
so `AuraScript::CheckEffect` filtered it on every expiry and the handler never ran on any difficulty — the
carrier only ever saw its own periodic 2105706 ticks, confirmed in three live trials before the fix. Fixed by
binding the hook to 227, confirmed against `Spell.dbc` directly. Live re-verification (grouped 5-bot raid,
Ascended) after the fix: 3/3 natural expiries produced the explosion, each bystander within 5 yd took exactly
one 3200-damage hit (Normal-ladder figure; the far bot stayed outside 5 yd and never did), the carrier alone
took its own periodic ticks, and all 3 expiries knocked the actual carrier back (`SMSG_MOVE_KNOCK_BACK`, 3/3).
An earlier verification attempt with ungrouped bots wrongly reported zero bystander hits post-fix: each
ungrouped bot gets its own personal raid instance, so no bystander was ever on the same map — a harness
defect, not a mechanic defect, fixed by grouping the bots into one raid before entering the instance.

### Sulfuron Harbinger (12098)

| | Reality | Before | After | Evidence | Open question |
|---|---|---|---|---|---|
| Flame Spear / Hand of Ragnaros / Dark Strike / Inspire / Demoralizing Shout / Fierce Blow / Conflagrate (7 measured rows) | ran | unchanged | measured | The only boss whose schedule ids match vanilla exactly (not Ascension's custom 2105xxx range) — kit reads as largely untouched from vanilla |

Health: `hp_d0..d3` 441,316/588,422/885,626/1,291,304 (rebuilt from a direct CoA video reading at Ascended —
see §5). Add
"Flamewaker Priest" (11662, renamed on CoA to Corvus the Nimble — see §4) runs its own hand-written kit
unaffected by any of this.

Flame Spear/Hand of Ragnaros looked "missing" on Mythic/Ascended in an early literal-id check; they fire on
every difficulty, just as 350090/350108 on d2/d3 instead of the schedule's literal 19781/19780 (same ability
names via Spell.dbc, same cadence) — no DBC row actually links the two id pairs, so the schedule table's id
column is simply not representative for those two tiers; see [Verification](#verification).

**Sulfuron's four disciples.** The corpus's three Mythic/Ascended Sulfuron pulls each show exactly four
adds: Corvus the Nimble (11662) plus three previously-unimplemented, CoA-named disciples — Cull the Destroyer
(92031), Proxima the Opressor (92032), Ebon the Cruel (92033) — sharing one video health reading (6.5M/23p).
Corrected: the user's own report is that this fight does not differ by difficulty, so three of Corvus's four
spawns are replaced by the named disciples on every difficulty, not Mythic/Ascended only (no Normal/Heroic
pull exists in the log corpus to confirm this independently, unlike the Mythic/Ascended composition itself).
`coa_boss_summon` (widened for this add to "replace the nearest live creature of a given entry" alongside
plain summon-and-buff) no longer carries a difficulty gate at all — the `min_difficulty` column and its
`CoaBossAI.cpp` check were dropped once removing Sulfuron's gate left every row wanting every difficulty.
Each disciple runs a dummy→real-effect curse/self-heal pair read from `Spell.dbc`: Cull = Curse of Gehennas +
Cauterize (real heal), Proxima = Dampen Magic + Arcane Instability (Shazzrah's own measured cadences), Ebon =
Curse of Lucifron + Dark Mending (real heal); all three also carry a Shadow Bolt with no matching "- Damage
Info" family, so it still deals DBC placeholder damage. Confirmed in-game (`verify-ABC.md`,
`impl-D-fixes.md`): d0 and d2 both now spawn 1 Corvus + the three disciples, all casting over a 90s window.
Cadences are designed (every log entry reads `casts: 0`); Rapid Regeneration (804315) is left unwired, never
observed.

### Golemagg the Incinerator (11988)

| | Reality | Before | After | Evidence | Open question |
|---|---|---|---|---|---|
| Fierce Blow / Lava Burst (2105812→2105814) / Massive Stomp (2105817) | ran, Lava Burst had placeholder Damage Info dmg | Damage Info wired for Lava Burst | unchanged timers | measured | — |
| Magma Splash (2105802, tank) | dead-C++ only (`boss_golemagg.cpp`, unreachable) | added, 10s/18s | designed | no measured log confirms this exact interval |
| Molten Armor (2105806, tank) | dead-C++ only | added, 16s/32s | designed | same |
| Cave In (2105825/27/28, area, ground-fire) | dead-C++ only | added, ~4s after every Massive Stomp (first_ms=13000, period_ms=45100, tracking idx 2's 9000/45100) | measured (diag-golemagg-cavein.md, 8/8 casts across two corpus logs, 3.93-4.10s delay) | — |
| Pyroblast, Earthquake, enrage-at-10% (dead C++) | unreachable | not added | designed (per dead code) | no measured interval exists for these three in the 42-log corpus — see §8 |
| Yank (2105852) | not wired | not wired | not wired | Effect is an exotic chain-pull (id 124) with no plain cast/aura semantics the schedule engine can express |

Magma Splash/Cave In looked "missing" above Normal in an early literal-id check; both resolve through a real
`SpellDifficulty.dbc` family (rows 2122/2125) and fire on every difficulty with the same count/cadence as
Normal — a false alarm, not a defect; see [Verification](#verification).

Health: `hp_d0..d3` 1,104,793/1,473,058/2,217,081/3,232,656 (Magmadar has its own direct CoA video reading now;
Golemagg has none of its own and keeps the K=1.3645 family rescale — see §5). Add "Core Rager" (11672,
renamed on CoA to Cindermaw — see §4) carries "Stress" (2105858, a genuine self-stacking aura) in its CoA kit,
but its `ScriptName` (`npc_core_rager`, hand-written C++) always wins over SmartAI, so no data row for it
would run; reported, not fixed.

### Majordomo Executus (12018)

| | Reality | Before | After | Evidence | Open question |
|---|---|---|---|---|---|
| Stock kit: Magic Reflection, Damage Reflection, Aegis of Ragnaros, Teleport Random/Target, Separation Anxiety, Champion, Immunity | stock `boss_majordomo` script, all vanilla ids | unchanged | measured (stock file) | Ascension-only kit ids (2108014-2108033: Aegis of the Firelord, Molten/Shadow Shield, Broken Bond, Rising Anger, Empowered Shadow Nova/Blast Wave) are never cast; thematic name matches to the stock mechanics exist but are unverified — no measured log covers Majordomo (the 42-log corpus is scoped to the 8 schedule bosses) |

Health: `hp_d0..d3` 890,963/1,187,950/1,787,968/2,606,980 — no CoA/BB video reading of his own; the prior
Golemagg-derived row is kept but rescaled by K=1.3645 like Golemagg itself (§5).

**Sacrificial Chains (92030).** Present in 48 of the corpus's 49 Majordomo pulls (Heroic 6, Mythic 8,
Ascended 34) and no other boss's fights — Majordomo is the summoner. Median first spawn +29s after pull,
repeat cycle ~47-50s, each instance surviving ~10-24s to raid damage before dying. Wired via a small,
comment-tagged addition to inherited `boss_majordomo_executus.cpp` (one event, one summon call, unchanged)
plus `npc_sacrificial_chains_coa.cpp`.

Corrected: the chain does not self-cast a heal/re-sacrifice loop on itself. `mc-dataset.json`'s own
aggregation drops aura target names, so a direct WoWCombatLog re-query was needed: every logged
`SPELL_AURA_APPLIED` for Sacrifice (2108020) has "Sacrificial Chains" as source and a *player* as dest —
matching 2108020's own `Spell.dbc` implicit target (`TARGET_UNIT_TARGET_ENEMY`, not the caster). On spawn the
chain heals its target(s) to full (2108023) then applies Sacrifice (2108020) to a random set of nearby raid
members.

**Chain-target cap follows the flex raid size, not difficulty** (rule set by the user from CoA play, superseding
the earlier per-difficulty cap): the same non-GM, clamped-10..25 player count `coa_flex::CountPlayers`
(`FlexHealth.cpp`) uses for boss health — 10-14 players chains 1, 15-19 chains 2, 20-25 chains 3, identically on
every difficulty. `npc_sacrificial_chains_coa.cpp` calls `coa_flex::CountPlayers` (exposed via `FlexHealth.h`)
instead of duplicating that count. Confirmed live on slot 3 (Ghost harness, `.npc add temp 92030` directly on a
grouped raid, since keeping Majordomo in combat hits the evade-loop pitfall below): 10/15/20 players in the
instance chained 1/2/3 players respectively.

The raw per-spawn evidence does not cleanly fit these thresholds — re-derived directly from the four
WoWCombatLog files by chain-spawn GUID: Heroic (13p, one continuous pull, 6 spawns) chained 2 every time,
not the 1 the 10-14 band would predict; the Ascended 13p pull (25 spawns) chained 1 in 14/25 and 2 in 11/25
from the *same* raid size; the Ascended 15p pull (10/10) and the Mythic 17p pull (6/8, 2 in 2/8 at 3) are
closer to the 15-19→2 band but not exact. No 20-25p pull exists in the corpus to check the top band. The
real mechanism evidently has a random component beyond pure raid-size thresholding; the user's flex-size rule
is implemented as specified regardless, per their explicit instruction. Killing the chain frees its
captives: in every clean (non-wipe) sample the chain's own death and the debuff's removal from its target(s)
share the same log timestamp, well inside 2108020's real 300s duration, so this is an explicit on-death
cleanup, not the debuff expiring on its own; `npc_sacrificial_chains_coa.cpp` now does this in `JustDied`.
Berserk (2100213, measured id, rare — 1/56 Sacrifice applications) is kept as a small spawn-time roll, not a
"second loop" escalation (there is no loop to escalate). No periodic "roast" damage is implemented on
unfreed captives: 2108020 has no `EffectTriggerSpell` and no `SPELL_PERIODIC_DAMAGE` tied to spell id
2108020 appears anywhere in the four re-queried logs, so a timed kill would be invented, not evidenced — see
`impl-D-fixes.md`.

Health: measured per-player kills (Heroic 11,501, Mythic 19,553, Ascended 32,147 averaged); Normal has no
pull and uses the same Heroic×0.750 convention as other unmeasured rows (unchanged by this correction).
Confirmed in-game (`verify-ABC.md`, `impl-D-fixes.md`): the chain spawns on schedule; it now chains nearby
players (not itself) and killing it removes the debuff from them.

### Ragnaros (11502)

| | Reality | Before | After | Evidence | Open question |
|---|---|---|---|---|---|
| Hand of Ragnaros | vanilla id 19780 shared with Sulfuron (whose own schedule already resolves it correctly via `SpellDifficulty.dbc`) | `boss_ragnaros.cpp` cast 19780 on self — would have silently broken Sulfuron's correct Heroic+ resolution if patched by id override | repointed to CoA's own 2108612 (own `SpellDifficulty` group 2213), cast changed self→victim to match the new spell's target field | measured (dbc group) + designed (call-site fix) | — |
| Wrath of Ragnaros | exclusive caster (only `boss_ragnaros.cpp`) | 20566 | repointed to 2108623 (group 2215) | measured (exclusivity) + dbc | — |
| Magma Blast | exclusive caster, dummy effect with no native trigger | 20565 | repointed to 2108607; new `SpellScript` casts the damage effect 2108608, already bound to Damage Info from rev_83 | measured + dbc | — |
| Sulfuras Slam, both Super Nova groups, Magma Splash, Unbearable Heat, Magma Strike, Fire Strike/Fierce Fire Strike, Meteor | in the CoA kit, no stock choreography beat matches them | not wired | not wired | exiles-kit only | No safe mapping without a log or a maintainer ruling — listed in §8 |
| Submerge / Sons of Flame / knockback timers | stock, all vanilla, unchanged (180s submerge, 90s duration) | unchanged | unchanged | measured (stock file) | Whether the stock script's vanilla-id casts already resolve to the matching CoA ids via the core's own `SpellDifficulty` chain (as they do for Sulfuron) was not confirmed at runtime this session |

Health: `hp_d0..d3` 2,394,118/3,192,157/4,747,960/7,058,824 — d0 and d3 are both direct CoA video readings
(Normal and Ascended); d1/d2 follow his own prior d1/d0, d2/d0 ratios anchored on the new d0. He starts the
fight at 50% of this pool (`boss_ragnaros.cpp`, both realms' videos agree) — see §5.

**Son of Flame merge chain.** Confirmed on both Normal and Ascended: Lesser Son of Flame (12143, 40N+72A)
→ Son of Flame (92026, 16N+28A) → Greater Son of Flame (92027, 5N+9A) → Unstable Son of Flame (92028, 1 pull
only). Every transition's same-tier pair dies within 0-0.3s of the next tier's first appearance (n=64/15/1)
— timing only, the corpus has no coordinates. Implemented in a new `npc_son_of_flame_coa.cpp`: same-tier
adds within 5 yd for 1.5s merge at their midpoint [designed range/hold]. Kit: Fire Strike/Fierce Fire Strike
(2108704/2108705, the only counted casts at every tier) as a repeating melee alternation; Magma Strike
(Son+)/Cone of Fire (Greater+) are logged only as auras applied, so they fire once on engagement rather than
on a guessed timer. Health: Son (147,059/player) and Greater (229,412/player) are direct CoA-video Ascended
readings, trash-ratio-derived for d0-d2; Unstable has no reading at all — its d2 figure (2,434,084/player,
24.3M at 10 players) comes from the single unkilled pull's damage-taken lower bound (2,200,559 @ 15p) × the
family's 1.365 coefficient, about 13× the Greater's own figure — `[low confidence]`, the weakest number in
this migration. Confirmed in-game (`verify-ABC.md`): all three merges fire correctly in a clean single-pull
session (~1-2s / ~1-5s / ~12-16s), each despawning both parents and spawning exactly one of the next tier at
the expected health. Unstable's "Unstable Flames" finisher (2108749) is not wired — no trigger in evidence.

## 4. Trash

Evidence tags as in §3. "Kit gap" below distinguishes the two different problems found: losing abilities
above Normal (SmartAI rows existed only for the base entry) versus never having had any ability at all.

| Entry | CoA name | Gap found | Fix applied | Evidence | Open question |
|---|---|---|---|---|---|
| 11658 Molten Giant | — | zero abilities above Normal; Smash ran on every difficulty (rev_20260930_99) at a flat, unscaled base-entry value | replicated Smash/Knock Away rows onto all difficulties (rev_20260930_99); Smash now reads its real per-difficulty value (SpellDifficulty group 1818: 2018944/2018946/2018947/2018948) via `spell_coa_damage_info_hit` (§14) | measured (rows) + SpellDifficulty.dbc (tier order, via `mc_evidence.py`) | Knock Away's own family (SpellDifficulty group 1819: 2018949/2018950/2018951) is identified but not applied — single-target, out of §14's AoE scope |
| 11659 Molten Destroyer | — | zero above Normal; kit's "Ground Tremor"/"Magma Splash" family never cast at any difficulty; Massive Tremor ran on every difficulty (rev_20260930_99) at a flat, unscaled base-entry value | replicated Stunning Strike/Massive Tremor rows onto all difficulties (rev_20260930_99); Massive Tremor now reads its real per-difficulty value (SpellDifficulty group 1873, "Ground Tremor" family: 2100278/2100475/2100476/2100477) via `spell_coa_damage_info_hit` (§14) | measured (rows) + SpellDifficulty.dbc (tier order, via `mc_evidence.py`) | Stunning Strike's own family (2100135 D1) is identified but not applied — single-target, out of §14's AoE scope; Magma Splash (2105035-38, single-target DoT aura) still not added |
| 11661 Flamewaker | — | zero above Normal | replicated Strike/Fist of Ragnaros/Sunder Armor rows | measured | — |
| 11663 Flamewaker Healer | **Flamewaker Acolyte** | zero above Normal; kit's Shadow Nova/shield-bond mechanic never cast | replicated Shadow Shock/Shadow Bolt rows; renamed | measured (rows) + exiles-kit (name) | Which Shadow Bolt sibling (2108000-03) is the intended upgrade is ambiguous, not applied |
| 11664 Flamewaker Elite | — | zero above Normal; kit's Magma Strike/Molten Shield/Broken Bond never cast | replicated Fireball/Blast Wave/Fire Blast rows | measured | Same Blast Wave sibling ambiguity as above |
| 11665 Lava Annihilator | — | no AI at all, any difficulty, despite a 3-spell kit | `AIName='SmartAI'`, new flat rows for Flame Buffet/Fireball/Crush Armor on all 4 difficulties | designed (no cooldown evidence in the export at all) | Timers borrowed from Firewalker/Flameguard's cadence, not measured for this creature |
| 11666 Firewalker | — | zero above Normal | replicated Incite Flames/Fire Blossom rows | measured | Kit's redesigned siblings (2105018/19) look like a different design, not a tier — not swapped in |
| 11667 Flameguard | — | zero above Normal | replicated Cone of Fire/Melt Armor rows | measured | Kit's "Lava Breath"/"Engulf in Flames" ids appear shared across multiple MC NPCs, not creature-unique — not added |
| 11668 Firelord (trash) | — | zero above Normal | replicated Soul Burn/Summon Lava Spawn rows | measured | Soul Burn's sibling ordering contradicts the "classic id = smallest" assumption used elsewhere — flagged unknown, no upgrade proposed |
| 11669 Flame Imp | — | zero above Normal | replicated Fire Nova row | measured | Clean ascending sibling family (2105005-08) exists but was not swapped in |
| 11672 Core Rager | **Cindermaw** | CoA's own kit for Cindermaw has no Mangle-equivalent at all — the opposite direction of gap | not changed (C++, not data; Mangle stays) | exiles-kit | Whether `npc_core_rager`'s Mangle cast should be removed is a maintainer call, not applied here |
| 11673 Ancient Core Hound | — | zero above Normal; no fear ability on any difficulty | replicated Serrated Bite/Vicious Bite/undecoded-action rows; Mythic/Ascended given a fear (see §10 item 2) | measured | action type 88 is decoded (§10 item 2): `SMART_ACTION_CALL_RANDOM_RANGE_TIMED_ACTIONLIST`, params are a timed-actionlist id range, not spell ids |
| 12076 Lava Elemental | — | no AI at all, despite a 2-spell kit | `AIName='SmartAI'`, new flat row for Pyroclast Barrage on all 4 difficulties | designed | Fireball Volley (clean ascending family) not added — no cooldown evidence |
| 12099 Firesworn | — | kit's "Ignite" DoT never cast | not changed (C++, hand-written) | exiles-kit | No timer evidence to add it; #5388/#5391 do **not** trace to this gap (see §3 Garr) |
| 12100 Lava Reaver | — | no AI at all, despite a 2-spell kit | `AIName='SmartAI'`, new flat row for Strike; Cleave design (cone vs adjacent) left undecided | designed | — |
| 12101 Lava Surger | — | zero above Normal | replicated Surge row | measured | — |
| 12119 Flamewaker Protector | — | zero above Normal (kit has no higher-tier siblings at all for either spell — flat by kit design) | replicated Dominate Mind/Cleave rows | measured | See Lucifron's §3 note on whether Dominate Mind belongs here or on Lucifron |
| 12143 Son of Flame | **Lesser Son of Flame** | zero scripted abilities at any difficulty; summon-only, no static spawn to attach data to | renamed only; no AI added | exiles-kit (name); measured (no static spawn) | Whether to give it `AIName='SmartAI'` or script the cast at Ragnaros's summon call site is undecided |
| 11662 Flamewaker Priest | **Corvus the Nimble, Hand of the Harbinger** | none (kit not reviewed for spell content, only renamed) | renamed | exiles-kit (name, subname corroborates the Sulfuron-add pairing) | Exact spawn coordinates vs CoA's own placement not independently checked; spawn counts match |

Two entries with no scripted ability whatsoever and no CoA kit evidence either way (Core Hound 11671 — CoA's
own export doesn't clearly separate it from 11673; Flame of Ragnaros 13148 — the one entry with no difficulty
variants at all) had no change proposed.

## 5. Health

**Template health** (out-of-combat, non-flexed): Normal is CoA's own absolute health (db.exil.es export,
exiles-db-export-2026-09-13), expressed as a `HealthModifier` over this core's base health curve at the
matching level/class so the product lands on the recorded value. Heroic, Mythic and Ascended multiply that by
×1.44, ×1.88 and ×2.32 respectively — ratios read directly from CoA's client creature caches, which recorded
these exact multipliers against Normal for several MC creatures across the four tiers (Baron Geddon on all
three; Golemagg, Majordomo, Shazzrah and two Flamewakers on Ascended). Ragnaros (Ascended) is the one
exception, recorded at ×3.835 instead of ×2.32. This field is left as-is by the flex rebuild below: every
entity that also has a `coa_boss_flex` row gets its health overridden by `FlexHealth.cpp`'s
`OnCreatureSelectLevel` hook immediately at spawn in a raid map, so the static `HealthModifier` is inert for
those entities regardless of its value — keeping it as the export's own figure avoids mixing two sources for
one field.

**Flex health** (in-fight, `coa_boss_flex`, scaled by raid size 10–25 at spawn and at pull): fully rebuilt this
session from the user's own MC_PV video recordings — two Bronzebeard-realm (BB) videos and one CoA-realm
video, reading absolute health for most bosses and every trash type at a known player count, at varying
difficulties. Method, in order of preference:

1. A direct CoA-video reading (present for Lucifron, Magmadar, Gehennas, Garr, Baron Geddon, Sulfuron
   Harbinger, Corvus the Nimble, Ragnaros Normal+Ascended, Lesser Son of Flame Ascended), divided by its own
   "effective player count", used as-is for that difficulty.
2. Where a boss has a CoA reading for only one or two tiers, the rest are filled in from that boss's own
   *existing* `hp_d0:d1:d2:d3` relative shape, anchored on the new measured value(s) — not the generic trash
   ladder, since these bosses already carried a measured per-difficulty shape.
3. Two bosses with no CoA or BB reading of their own (Golemagg, Majordomo) have their whole existing row
   rescaled by **K = 1.3645** — the average CoA-video/current-design ratio (Ascended) across the six bosses
   that do have a direct CoA reading (a tight 1.363–1.365 cluster, read as one global "prior design → real CoA"
   rescale for this boss family).
4. Everything else with only a BB-video reading (Shazzrah, every trash type, Shadow of Lucifron) uses that
   reading × **C = 3.306** — the average CoA/BB ratio (Ascended) over the three bosses with both a CoA and a BB
   reading (Garr 3.300, Baron Geddon 3.299, Gehennas 3.317; Magmadar's own pair is a 3.14 outlier and excluded,
   unexplained). Trash readings are all at the Mythic tier; converted to Normal via ÷1.88, then to all four
   tiers via the same client-cache ratio 1:1.44:1.88:2.32 used for the static `HealthModifier` above.
5. Two trash types (Lava Spawn 12265, Flamewaker Protector 12119) have no reading anywhere — left un-flexed,
   no number invented for them.

Full per-entity table, the coefficients' derivation and every excluded/unspawned entity (three CoA-only named
Sulfuron priests, two CoA-only Son of Flame variants, Sacrificial Chains — all export placeholder stubs with
no `creature_template` row on this fork) are in `.agents/plans/mc-restoration/hp/hp-pools.md` (gitignored
working notes) and `rev_20260930_94_molten_core_health_pools.sql`'s own comments.

Ragnaros starts the fight at 50% health (both realms' videos agree: CoA Normal 20.3M/17 = 50% of 40.7M, CoA
Ascended 60M/17 = 50% of 120M) — `coa_boss_flex` holds his full pool; the 50% start is applied in
`boss_ragnaros.cpp` right before he becomes attackable, both on the initial intro and a post-wipe re-engage.
FlexHealth's own health-percentage-preserving recompute on combat entry carries that 50% through the flex
resize unchanged.

Magmadar's two heads no longer split his flex total 70/15/15 (rev_20260930_91); every video reading for them
is annotated "PV = Magmadar" (heads always display the same health as the body), so they now carry his row
unchanged and mirror his live health every tick, with the body the sole damage target (`boss_magmadar_coa.cpp`)
— see §3.

**Normal flex = Heroic × 0.750 was a guess** in the prior (now superseded) design; the new Normal figures
above are either a direct CoA reading (Lucifron, Magmadar, Gehennas, Garr, Baron Geddon, Sulfuron, Ragnaros) or
derived the same way as the other tiers (§8 still tracks trash timers/kits as designed, but health itself is
no longer a blanket 0.75 guess for the entities in the table above).

## 6. Damage per difficulty

CoA's boss kits contain a handful of spells whose direct-hit or periodic-damage effect is a DBC placeholder
(`EffectBasePoints` = 1, i.e. amount 2) rather than the real per-difficulty number. The real numbers live in a
separate family of "`<Boss> - <Spell> - Damage Info`" aura spells (dummy auras, one row per difficulty D0–D3,
`EffectBasePoints` stepping the real amount). Before this branch nothing read those auras, so the 12 bound
spells dealt ~2 damage on every difficulty regardless of the info auras' own D0–D3 values.

This branch adds a `coa_spell_damage_info` table (spell → its four info-spell ids) and two small server
scripts: `spell_coa_damage_info_hit` (`OnEffectHitTarget`, for the 9 direct-hit spells) and
`spell_coa_damage_info_periodic` (`DoEffectCalcAmount`, for the 3 periodic-damage spells), both resolving the
caster's raid difficulty (clamped like `FlexHealth.cpp` does) and reading the matching info spell's own
`EffectBasePoints` at cast/tick time. The 12 bound pairs: Lucifron Shadow Bolt (2105213←2105208-11),
Flamewaker Shadow Bolt (2105255←2105250-53), Flamewaker Incinerate (2105456←2105451-54), Firesworn Ignite
(2105563←2105557-60), Gehennas Incinerate (2105406←2105401-04), Gehennas Immolate periodic
(2105430←2105425-28), Gehennas Conflagrate periodic (2105436←2105431-34), Golemagg Lava Burst
(2105814←2105808-11), Magmadar Lava Burst (2105357←2105351-54, unreachable while Magmadar runs its stock
script), Sulfuron Conflagrate periodic (2105906←2105901-04), Ragnaros Magma Blast (2108608←2108603-06) and
Meteor (2108762←2108755-58, unwired — see §8). This is separate from `SpellDifficulty.dbc`'s own family
resolution, which does cover some MC spells directly (e.g. Gehennas's Rain of Fire, Sulfuron's Hand of
Ragnaros/Flame Spear) without needing the Damage Info mechanism at all.

## 7. Loot

Source: db.exil.es (hertigservices/ascension-data release, exiles-db-export-2026-09-13), the database behind
CoA's own community database site, read past its 20-row page cap. Every base and difficulty-variant entry
gets its own `lootid`; `creature_loot_template`/`reference_loot_template` were rebuilt in full rather than
patched.

The MC-specific reference groups were moved from the export's own numbering to **4090011–4090030** because
reference id **34026** already means something else on this fork (an AQ20 loot table) — reusing it verbatim
would have collided two unrelated raids' catalogs. World-drop references in the 24xxx range and 34002 already
matched and were reused unchanged.

Three export quirks that `LootMgr` rejects or flags at load were normalized during generation (not by hand):
29 rows with `Chance = 0` and `GroupId = 0` (garbled/duplicate export rows that never roll under either
database's own rules) were dropped rather than inserted; any row with `Chance >= 100` was forced to
`GroupId = 0` (matching the base game's own convention, e.g. reference 34002) instead of keeping the export's
group id, which had been pushing several groups' raw total chance past 100%; reference rows got
`MinCount = MaxCount` (this core doesn't support them differing and only logs a warning otherwise).

Known oddities inherited from the export, not introduced by this branch: several Heroic, Mythic and Ascended trash tables carry
Northrend gathering items (Rime-Crusted Herbs 44206, Flash-Frozen Flower 44207, Shattered Log 44208; Lava
Annihilator (3) drops them at 10%, 10% and 7.1%), kept as CoA's data has them. Stoneclad Libram 1310531 (Baron
Geddon) and Tome of Burning Passion 1310533 (Gehennas) have chance 0 without a group on Normal, so Normal
never drops them; their Mythic rows (10% and 9.1%) are kept.

Fiery Core (17010) and Lava Core (17011) carried an unverified placeholder rate set
(`d3b5e2677` replicated Normal's rates onto the Heroic/Mythic/Ascended variants verbatim) and,
for both items, several real Classic droppers were missing from the table entirely. Replaced
(`rev_20261001_82`) with each item's own Wowhead Classic "Dropped by" rate (Wayback snapshots,
item=17010/fiery-core 20251017200731 and item=17011/lava-core 20251204231747), applied identically
to all four difficulty variants (neither item has its own tiered id):

Lava Core rates were then halved at the player's request (rev_20261001_f1): the Lava Core column below shows the Classic rate before the halving.

| Creature | Fiery Core | Lava Core |
|---|---|---|
| Molten Destroyer (11659) | 26.7984% | 26.4793% |
| Lava Annihilator (11665) | 9.5333% (missing, added) | 38.2558% |
| Firewalker (11666) | 63.7854% | 13.4590% (missing, added) |
| Flameguard (11667) | 63.4973% | 13.4201% (missing, added) |
| Firelord trash (11668) | 44.3127% | 9.8471% (missing, added) |
| Baron Geddon (12056) | 78.4248% | — |
| Golemagg the Incinerator (11988) | — | 87.4824% |
| Garr (12057) | — | 72.8995% |
| Lava Elemental (12076) | 17.9430% (missing, added) | 56.2082% |
| Lava Reaver (12100) | 18.5946% (missing, added) | 55.6946% |
| Lava Surger (12101) | 12.6117% (missing, added) | 10.3356% |

### 7.1 Heroic/Mythic/Ascended boss loot restructure, flex tokens, legendaries and the Ingot

The exiles-db export's `creature_loot_template` rows for the 9 scheduled bosses are correctly grouped on
Normal (a guaranteed-reference Tier 1 token pick, guaranteed currency/flavor items, and one or more low-chance
epic/legendary groups) but were flattened to independent `GroupId = 0` rolls for every Heroic, Mythic and
Ascended variant: the T1 reference pool became N items each rolling independently at `100/N`%, the boss's
rare accent epic and (where present) its legendary row were promoted to an unconditional `Chance = 100`, and
the guaranteed currency rows and Sulfuron Ingot were dropped entirely. `.agents/plans/mc-restoration/diag-G4.md`
has the full read-only diagnosis; `.agents/plans/mc-restoration/gen_mc_loot_fix.py` is the corrective
post-processor (not a regeneration from the export) that rebuilt every scaled variant to mirror Normal's
structure:

- The scaled variant's own T1-pool items (same item ids the export already assigned per difficulty) move into
  a new `reference_loot_template` entry (ids `4090031`-`4090057`), picked via a `GroupId = 0`, `Chance = 100`
  row with `MinCount = MaxCount = 2` — the same baseline Normal now uses on every boss (Lucifron, Baron Geddon,
  Gehennas, Shazzrah and Sulfuron Harbinger were bumped from 1 pick to 2 to match Ragnaros/Garr/Golemagg/
  Magmadar, which already rolled 2).
- Normal's guaranteed currency/flavor rows (Personal Cache 1170083, Raider's Commendation 400750, Rune of
  Descension 375250, each boss's own key/quest item, and Ragnaros's shared world-drop reference 34002) are
  copied forward unchanged to every scaled variant that was missing them.
- The scaled variant's lone leftover `Chance = 100` item (the accent epic each boss already had, e.g. Molten
  Wristguards' difficulty-specific id for Lucifron) is demoted to its own low-chance `GroupId`, using the same
  percentage as Normal's equivalent group — not a new number. Baron Geddon has two such leftovers (its curio
  and its epic single) and both are demoted independently.
- **Legendaries**: Eye of Sulfuras (17204, Ragnaros), Bindings of the Windseeker left/right (18563 Baron
  Geddon / 18564 Garr) are added or re-demoted to Normal's own chance (4%, 3%, 4% respectively — matching the
  classic-era ~3-6% range per wowhead/wowpedia) wherever the scaled table had them at an unconditional 100%
  (Ragnaros Mythic/Ascended, Garr Heroic) or missing entirely (Ragnaros Heroic, Garr Mythic/Ascended, Baron
  Geddon on every scaled tier).
- **Sulfuron Ingot (17203)**: added to every scaled boss variant (previously present only on Normal) at that
  boss's own Normal chance, and to the Heroic Flameguard trash entry (111667) at the same 0.091% as its Normal
  entry. Golemagg's own rate was raised from 2% to 33% on **all four difficulties**, matching the classic
  ~33-34% figure (wowhead/wowpedia; CoA's original 2% was roughly an order of magnitude low per the G4
  diagnosis); every other boss's existing Normal ingot chance (2-4%) was left as-is and only copied forward.
- Ragnaros keeps several scaled-only `Chance = 100` rows with no Normal or legendary/epic counterpart
  (1202039, 1400040, 1319017, 1319138, 2400040, 219138/319138); these are left guaranteed rather than guessed
  at, mirroring Ragnaros's own Normal design (which already has several always-100% misc items beyond its
  epic/legendary/ingot groups). The small multi-item recipe/misc pools Normal carries in `GroupId 1/2/3/4/37`
  (patterns, trash-tier trinkets) were not reconstructed for the scaled variants — the export has no
  scaled-specific item ids for them, and inventing replacements was out of scope.

**Raid-size token bonus (C++, data-driven)**: `modules/mod-coa-raid-difficulty/src/FlexLoot.{h,cpp}` hooks
`MISCHOOK_ON_AFTER_LOOT_TEMPLATE_PROCESS` (the same pattern `AscensionBushcraft.cpp` uses for skinning bonus
loot) and, for any creature entry listed in the new `coa_mc_token_loot` table (one row per boss per
difficulty, migration `modules/mod-coa-raid-difficulty/data/sql/db-world/base/20_mc_boss_flex_loot.sql`),
rolls one additional item from that entry's own T1 reference pool when `coa_flex::CountPlayers` (shared with
`FlexHealth.cpp`) is 20 or more. Net result: 2 guaranteed Tier 1 pieces per boss kill below 20 players, 3 at
20+, on every difficulty. Because a live creature's `GetEntry()` stays its base entry on every raid difficulty
in this fork (see `FlexHealth.cpp`'s `BaseEntry()`), the lookup rebuilds the difficulty-specific key from the
base entry plus the map's own spawn mode rather than trusting `GetEntry()` to already carry the difficulty;
before this fix the bonus always resolved to the Normal row and drew from the Normal token pool regardless of
actual difficulty. Re-verified live post-fix (Lucifron, Ascended): a 20-bot kill dropped 3 T1 tokens
(218878, 219143×2), a 10-bot kill dropped 2 (218861, 212598) — every item from the Ascended pool (`reference_loot_template`
entry 4090051), none from the Normal pool (4090012).

**Correction (`rev_20261001_40_molten_core_real_tier_tokens.sql`): the guaranteed pool above was the wrong
item family.** The classic per-class Tier 1 armor pieces (Felheart Gloves 16805, Sorcerous Dagger 18878, ...)
genuinely drop through the mechanism just described, but they are not CoA's "T1 tokens" and read as unrelated
loot to players, which is why a user who ran two full MC clears reported seeing zero T1 tokens. The real
tokens are a separate item family, independently confirmed from AscensionDB's "Client captures" records
(modes `conquest-of-azeroth`/`season-9`/`season-10-freepick`, not just `Exiles DB`): class 15 (Misc),
subclass 0, quality 4, non-equip, reqlvl 60 items named `Molten <Slot>` (Tier 1: Tunic/Legguards/Headpiece/
Spaulders/Wristguards/Girdle/Handguards/Boots) and `Chromatic <Slot>` (Tier 2, BWL), one id per difficulty
tier (`25/26/27/37` prefixes for Normal/Heroic/Mythic/Ascended). Their own captured tooltip says so directly:
"This Token is a Global Token for Tier 1 `<Slot>` Slot items. This is Exchangeable at a Vendor found in
Stormwind (Major Mattingly) or Orgrimmar (Overlord Runthak)." `reference_loot_template` 4090012-4090057 (the
same ids FlexLoot.cpp/`coa_mc_token_loot` already read) now hold the 8-item Molten set for their difficulty,
shared across all nine scheduled bosses, instead of the classic armor; no C++ change was needed since the
pipeline was already fully data-driven. The export's own single low-chance per-boss `Molten <slot>` row
(e.g. 2522362 at 2% on Lucifron) and the Chromatic Legguards row on Ragnaros (the only MC boss confirmed to
drop a T2 token in the export, at 4%) are unchanged, aside from fixing a real tier-id swap on Ragnaros's
Mythic/Ascended rows (each was serving the other's token id). The token-for-gear exchange at Major Mattingly
(14394) and Overlord Runthak (14392) was out of scope for this fix — tokens now drop and are recognizable —
and is resolved separately in §8 item 13 (`feat/mc-vendors`).

**Second correction (`rev_20261001_50_molten_core_tokens_per_boss.sql`): the guaranteed pool was shared
across all nine bosses, not boss-specific.** `_40` pointed every boss's guaranteed-pick reference at the
full 8-item Molten set, so a kill could guarantee e.g. Lucifron dropping Molten Boots instead of his own
Wristguards. Re-reading the export's `creature_loot_template` per boss (not just the aggregate token item
list) shows each of the nine scheduled bosses already carries exactly one boss-specific token row, matching
Classic Molten Core's own one-slot-per-boss design: Lucifron -> Wristguards, Magmadar -> Legguards,
Gehennas -> Girdle, Garr -> Headpiece, Shazzrah -> Handguards, Baron Geddon -> Spaulders, Sulfuron
Harbinger -> Boots, Golemagg -> Tunic (each at the export's own 2-4% bonus chance, group-exclusive with
that boss's other rare rolls, left unchanged), and Ragnaros -> Chromatic Legguards (T2, 4%, left
unchanged). `_50` repoints each of the 32 Tier-1 reference ids (8 bosses x 4 difficulties) at that boss's
own tier-matched item only, so the guaranteed 2 (3 at 20+ players) pool picks resolve to 2-3 copies of the
boss's own token, per "if a boss has exactly one specific token, the count means copies of that token."

Ragnaros has no boss-specific row in the guaranteed-pool family anywhere in the export — his only token
row was the pre-existing low-chance (4%) Chromatic Legguards group, structurally the same kind of row every
other boss's own token sits in (never part of the guaranteed-pool mechanism). `_50` read that as meaning a
guaranteed 2-3 extra Chromatic Legguards per kill would invent a drop rate/count the export does not
support, and removed Ragnaros from the guaranteed-pool mechanism entirely (his `reference_loot_template`
rows, his `creature_loot_template` guarantee row and his `coa_mc_token_loot` rows were all deleted), leaving
only the 4% roll. T2 tokens in Molten Core, confirmed from the export, come only from Ragnaros, not from
Majordomo — see below.

**Third correction (`rev_20261001_51_molten_core_ragnaros_t2_token.sql`): Ragnaros's Chromatic Legguards
drop is guaranteed, per the player's own measured kills, overriding `_50`'s export-only reading above.**
The export's silence on a guaranteed row is not proof of a 4% rate — this fork is a reconstruction, and a
player who ran multiple Ragnaros kills and saw Chromatic Legguards every time outranks an absent row. `_51`
re-adds Ragnaros to the guaranteed-token mechanism on that basis: new single-item `reference_loot_template`
pools (4090058 Normal/4090059 Heroic/4090060 Mythic/4090061 Ascended, holding only the tier-matched
Chromatic Legguards id, `2522459`/`2622459`/`2722459`/`3722459`) back a `creature_loot_template` guarantee
row on `11502`/`111502`/`211502`/`311502` shaped exactly like the other eight bosses' own guarantee rows
(`Chance = 100`, `MinCount = MaxCount = 2`), and `coa_mc_token_loot` points each entry at its new reference
so `FlexLoot.cpp`'s existing raid-size bonus roll applies unchanged: 2 Chromatic Legguards per kill below 20
players, 3 at 20+, same as every Tier 1 boss. The old 4% `creature_loot_template` row on the same item
(`GroupId 5` Normal / `GroupId 3` Heroic/Mythic/Ascended, `Chance 4`) is deleted in the same migration so a
kill cannot drop Chromatic Legguards twice.

**Correction (`rev_20261001_73_molten_core_mythic_ascended_token_swap.sql`): the "25/26/27/37 =
Normal/Heroic/Mythic/Ascended" prefix convention stated above is backwards for the last pair.**
Every Molten-`<Slot>`/Chromatic Legguards token's own `item_template` row carries a decoded-WDB
tooltip tag identifying its own difficulty directly (`"@Heroic Raid@"`/`"@Mythic Raid@"`/
`"@Ascended Raid@"` prefixing the description; the Normal id has no tag) - this is the only
direct, non-inferred evidence of which numeric id serves which difficulty, and it is corroborated
by `buy_price` scaling strictly with difficulty (1.0M/1.5M/2.0M/2.5M) matching the Ascended->highest
order the health scaling already established (`hp_d0..d3` above). For every item in this family,
the **27-prefixed id is Ascended and the 37-prefixed id is Mythic** - the reverse of what was
assumed when `rev_20261001_50`/`_51` built the guaranteed-pool `reference_loot_template` entries:
each boss's Mythic reference entry (and Ragnaros's) held the 27-prefixed (actually Ascended) item
and its Ascended entry held the 37-prefixed (actually Mythic) item, for all 8 Tier-1 bosses plus
Ragnaros's Tier-2 Chromatic Legguards (18 rows total). `_73` swaps each pair back. Note this is the
opposite mechanism from the one flagged in the flex-items plan: the direct `creature_loot_template`
2-4% "own token" row on each Mythic/Ascended boss entry (e.g. Magmadar's 311982) already used the
correct id under this mapping and needed no change - only the guaranteed-pool reference entries
(the higher-volume drop vector read by `coa_mc_token_loot`/`FlexLoot.cpp`'s raid-size bonus roll)
were swapped. `coa_mc_item_pool` and `coa_mc_fire_lord_cache_pool` hold none of this item family
(they draw from the separate non-set-epic gear family, whose own +200000/+300000/+1300000
additive scaling was checked and is correct) - no pool rebuild was needed.

**Majordomo Executus drops no token of any kind.** He was never in the nine scheduled bosses'
guaranteed-pool mechanism (never added to `coa_mc_token_loot`), and the export confirms there is nothing to
add: his own "loot" is the Cache of the Firelord gameobject (179703, type Chest) that
`instance_molten_core.cpp`'s `SetBossState(DATA_MAJORDOMO_EXECUTUS, DONE)` makes lootable
(`SetLootRecipient`/7-day respawn) — stock AzerothCore's mechanism, not a CoA addition. The export's own
`gameobject_loot` row for the chest's loot id (16719) holds only stock classic filler (Limb Cleaver, two
quest items, Eye of Divinity/Ancient Petrified Leaf) with no Molten/Chromatic item anywhere; the
Heroic/Mythic/Ascended chest entries the export defines (279703/379703/479703) carry no loot id and no
loot rows of their own (one stray 0%-chance row on 379703 aside). This matches Classic's own design —
Majordomo does not drop tier loot himself when spared for the Ragnaros fight — so no token content is
added here, and no GameObject-loot hook was added to FlexLoot.cpp: there is no evidence of what it would
feed, and the existing creature-only hook (`&store != &LootTemplates_Creature` check) already leaves
gameobject loot alone rather than misapplying the creature-token logic to it.

### 7.2 Cache of the Fire Lord (2400040) opener

**Designed from player memory (no recorded data anywhere)** — `diag-K-firelord-cache.md` exhausted
every source available this session (the repo's own SQL/export, AscensionDB's client captures and
Exiles DB mirror, local WDB/addon snapshots) and found no itemized contents for 2400040 anywhere;
its on-use spell 93461 is a bare dummy shared by 50+ unrelated cache items fleet-wide, so clicking
it did nothing. The design below is the user's own recollection of live CoA, not a restoration of
measured data.

- **Behaviour**: opening the cache consumes it and gives one random piece of equippable gear
  (`item_template.class` 2 Weapon / 4 Armor, including rings/trinkets/cloaks/necks) from the
  **killed raid's own difficulty** — not the player's current raid difficulty setting. Reading the
  setting at open time would be exploitable (kill on Normal, switch to Ascended, open for
  Ascended-tier gear), so the difficulty is bound to the item the moment it is looted inside Molten
  Core (`Map::GetSpawnMode()`, the same 0 Normal/1 Heroic/2 Mythic/3 Ascended convention
  `coa_mc_token_loot`/`FlexLoot.cpp` already use) via a new `OnPlayerStoreNewItem` hook
  (`AscensionFireLordCache.cpp`), recorded in the characters-DB table
  `coa_mc_fire_lord_cache_tier` (`ItemGuid` -> `RaidDifficulty`) and cleared once the cache opens
  successfully. No class filtering is applied — trivial class-fit checks were not an obvious win
  here, unlike `AscensionPrestigiousCache.cpp`'s stat-preference logic, so every pool item is
  equally likely regardless of the opener's class.
- **Known limitation**: an item with no bound row — a GM-added cache, or one looted before this
  table existed — falls back to the player's *current* raid difficulty setting at open time
  (logged at `LOG_DEBUG`), which is exploitable exactly as above for that narrow case only; every
  cache looted through the normal kill path after this change is unaffected.
- **Pool, per raid difficulty**: `coa_mc_fire_lord_cache_pool` (world DB, `RaidDifficulty`,
  `ItemEntry`) is filled by a late pending SQL migration that recursively resolves
  `creature_loot_template`/`reference_loot_template` for the nine scheduled bosses plus Ragnaros,
  at each of the four difficulties, rather than hard-coding any item id. Excluded while resolving:
  every Tier 1 token reference (`4090011`-`4090057`, §7.1's own token pools) and
  `reference_loot_template` 34002 (AzerothCore's own generic classic-era world-drop pool, reused by
  thousands of unrelated creatures server-wide, not Molten Core's own itemization). Everything else
  that is not class 2/4 (consumables, quest items, reagents, recipes, currency-like Misc items, the
  two other unrelated "Cache of the Fire Lord"-named ids 1400024/1400040, Personal Cache 1170083,
  and the legendaries Eye of Sulfuras/Bindings of the Windseeker) falls out of the plain
  `item_template.class` filter with no manual id list. 2400040 itself is added to Ragnaros's
  Normal/Heroic loot at the same guaranteed rate it already has on Mythic/Ascended (111502/211502/
  311502/11502).
- **Pool size is data-driven.** The Mythic/Ascended-only 2-item floor this paragraph originally
  described was already fixed by `rev_20261001_42` (§7.1's token/epic restore left the pool's own
  CTE running before those rows existed; `_42` re-ran it once more, late) — live on slot 3 before
  this section's own change, all four tiers already held 71 items each. §7.3's gear relocation
  (moving those same items into `coa_mc_item_pool`) needed its own late rebuild, `rev_20261001_71`,
  to union that table back into the CTE's result; confirmed live post-deploy: still 71/71/71/71,
  unchanged, since the migration re-adds exactly the items it removed from
  `creature_loot_template`.

### 7.3 Random item drops per kill

On top of the guaranteed set tokens (§7.1), a kill by any of the 8 T1-token bosses, Majordomo
Executus or Ragnaros (creature loot only — Majordomo's Cache of the Firelord chest, §7.2, is
excluded for now) also drops N random items, N following the same flex player-count band
`FlexHealth.cpp`/`FlexLoot.cpp` already use (`coa_flex::CountPlayers`, clamped 10-25,
`coa_mc_item_count`): 10-14 players → 2 items, 15-19 → 3, 20-25 → 4.

**Pool construction.** Each of the 9 scheduled bosses' own Normal `creature_loot_template`
already carried a small group of non-set epic gear (class 2 Weapon / class 4 Armor, quality 4)
rolling independently at 0.154-0.571% per item — restored on every difficulty by
`rev_20261001_41` (§7.1) but never deduplicated against double-counting. Re-reading those groups
pairwise found no item shared by literally every boss (the earlier working assumption), but four
clean boss pairs each sharing one family of items: Golemagg/Baron Geddon (9 items), Magmadar/Garr
(9), Sulfuron Harbinger/Shazzrah (10), Lucifron/Gehennas (9) — 37 distinct items total. Those 37
are promoted into one common pool (`coa_mc_item_pool`, `CreatureEntry = 0`) available to every
boss's draw; each boss's own remaining items (Ragnaros's full 15-item pool, which shares with no
one, down to Baron Geddon's single leftover Stoneclad Libram) stay keyed to that boss's own base
entry. Majordomo Executus carries no `creature_loot_template` rows of his own at all (his real
loot is the Cache of the Firelord gameobject, §7.2) and so draws only from the common pool. Every
pool item keeps the export's own relative weight: since every item inside a given boss's original
group already rolled at an identical chance, a uniform weight of 1 per row preserves those ratios
exactly. `rev_20261001_70` deletes the old per-group rows (Normal `GroupId` 2/3/4, scaled
`GroupId` 10/11) so nothing drops twice; the CoA case/pack group (`GroupId` 37) and every
guaranteed/currency row are untouched.

**C++**: `modules/mod-coa-raid-difficulty/src/FlexItems.cpp`, a sibling of `FlexLoot.cpp` reusing
the same `MISCHOOK_ON_AFTER_LOOT_TEMPLATE_PROCESS` hook and the same base-entry-plus-spawn-mode
lookup convention. Items are drawn without replacement, weighted by `coa_mc_item_pool.Weight`; a
boss whose combined pool (common ∪ own) is smaller than N gives every item it has.

Live-verified for Lucifron/Magmadar (§9) and, in a later session, for Ragnaros on both Normal and
Ascended (`TestMCRagnarosKillCoA`, 10 bots): exactly 2 Chromatic Legguards plus exactly 2 pool
items (cross-checked against `coa_mc_item_pool` row membership, since Ragnaros's own many
always-guaranteed rows make the random items indistinguishable by eye) and the Fire Lord cache
item (2400040) on every kill. Ragnaros's own pool (`CreatureEntry = 11502`) was missing Band of
Sulfuras (19138/219138/319138/1319138) relative to the Classic Ragnaros loot table
(wowhead.com/classic/guide/ragnaros-molten-core-strategy-wow-classic, Wayback 20250918015449) —
added (`rev_20261001_81`) since clean tier clones already exist; it dropped live on the first
Ascended re-test. Everything else on Ragnaros's 15-item Normal pool matches the guide; three items
present in the export but not listed by the guide (Veil of Flame Worshipper 12572, Pyroclasmic
Longbow 15712, Blade of Dragon Bone 17083) were kept, not removed — the guide is not treated as an
exhaustive authority over the export. The 9 per-class Tier 2 leg pieces the guide also lists are
intentionally absent from this pool: this fork represents that slot with the single Chromatic
Legguards token instead (§7.1), not 9 separate class-specific drops.

**Majordomo Executus's Cache of the Firelord (179703) was never actually lootable.**
`GameObject::Use()` has no `GAMEOBJECT_TYPE_CHEST` case at all (confirmed by reading the stock
engine switch — it falls to `default:`, spell id stays 0, nothing happens), and a type-3 chest is
normally opened only via `Spell::EffectOpenLock`, reached by the client auto-casting the spell
matching its lock's `LockType.dbc` entry — a path nothing in this core ever drives for a bare
chest GO. The lock itself (57) is not the defect: its populated case resolves through LockType 5
("Open"), which maps to `SKILL_NONE` and always succeeds trivially. Confirmed live on slot 3 that
neither `CMSG_LOOT` (guarded to creature/vehicle GUIDs only) nor plain `CMSG_GAMEOBJ_USE` ever
opened the loot window. Fixed by `go_cache_of_the_firelord_coa` (`boss_majordomo_executus.cpp`),
which opens the chest directly from `GossipHello` — the same idiom `go_ragnaros_portal_coa`
already uses to short-circuit `Use()`. `FlexItems.cpp`'s hook already fires for gameobject loot the
same way it does for creature loot; extended to recognize the chest (keyed on Majordomo's own
common-pool-only entry, since the chest's difficulty comes from the looting player's map spawn
mode, not its own entry — it is one static spawn shared across every difficulty). Confirmed live,
Normal and Ascended, 10 bots: the Classic item pool (reference `12000`, already correct in the
export — 10 non-set epics plus the two class-quest items, cross-checked item-for-item against
wowhead.com/classic/guide/majordomo-executus-molten-core-strategy-wow-classic, Wayback
20260415180430) drops alongside exactly 2 tier-matched random items from the common pool.

## 8. Known gaps / needs decision

1. **~~Normal flex health = Heroic × 0.750 (#5389).~~ Resolved for the video-covered roster.** Every boss and
   trash type in §5's table now has a Normal figure that is either a direct CoA video reading (Lucifron,
   Magmadar, Gehennas, Garr, Baron Geddon, Sulfuron, Ragnaros) or derived the same way as its other tiers —
   the blanket ×0.750 guess no longer applies to any of them. It is not otherwise revisited outside Molten Core.
2. **#5388, Firesworn Eruption damage.** The DBC data does not support the bug report's framing
   ("Ascended-level damage on Normal") — Eruption is genuinely flat (~3000 dmg) across Normal/Heroic by design,
   with a real, higher-tier Mythic/Ascended id (~4600 dmg). The more likely defect is that this fixed AoE hit
   is not flex-scaled to raid size/gear the way boss casts are. Options: leave as designed-flat, or add a
   flex-style scale table for it.
3. **Garr's designed timers, and Harden/Land Slide simplified.** Antimagic Pulse and Magma Shackles from the
   dead C++ kit were not ported; Harden/Cracked/Earth Fury's real stack-counting cycle was flattened to a
   crack-and-recover loop, and Land Slide's "charge through anyone in the path" became a self-centered AoE.
   Options: accept the simplification, or invest in a stack-tracking implementation and real path traversal
   if a log ever substantiates the exact mechanic.
4. **Golemagg's designed timers, and Yank/Cindermaw Stress not wired.** Magma Splash/Molten Armor were
   added without a measured interval (dead C++ only, no log); Cave In's own timing is now measured (§9 item
   12, `diag-golemagg-cavein.md`). Pyroblast/Earthquake/the 10%-health enrage were
   not added at all — no measured evidence either confirms or rules them out from the 42-log corpus. Yank
   can't be expressed by the current schedule engine (exotic chain-pull effect). Cindermaw's Stress aura is
   inert because `npc_core_rager`'s hand-written `ScriptName` always wins over any SmartAI row. Options per
   item: capture more Golemagg logs before adding any of these, or accept the current 3-ability kit as final;
   decide whether Yank needs a new engine hook; decide whether Stress belongs in the hand-written script
   instead of data.
5. **Gehennas procs.** Curse of Gehennas's dispel-punish mana-burn (2105423/24) needs a `SpellScript`
   triggered on dispel, which the timer-based schedule engine has no hook for. Not added; needs either a new
   engine hook or acceptance that this proc is out of scope for the data-driven path.
6. **Ragnaros abilities not wired**: Sulfuras Slam, both Super Nova groups (2108627-30 and 2108662-65 — which
   is "base" vs. a variant is itself unresolved), Magma Splash, Unbearable Heat, Magma Strike, Fire
   Strike/Fierce Fire Strike, and Meteor timing (2108762, already bound to Damage Info via §6 but nothing
   casts it). None have a stock choreography beat to attach to without inventing one; needs a combat log or an
   explicit maintainer ruling per ability.
7. **~~Lucifron's Flamewaker Protectors vs. a player's memory.~~ Resolved: removed, by player decision
   (`rev_20260930_98`).** This item previously read the export's own static placement (2 adds ~4 yd from
   Lucifron) as outweighing a "no adds" report. On a direct, later in-game account of the correct spot and "no
   adds", the player's memory is the decision: Flamewaker Protector (12119, guids 56606/56607) is removed
   outright, not relocated with Lucifron to his corrected alcove position (also `rev_20260930_98`, see §3).
8. **Shadow of Lucifron (12268) timing.** The 5s summon delay and its Shadow Bolt/Cleave/Dark Sundering
   cadences are still `designed`, not measured — no static spawn or summon-spell evidence exists for this
   creature anywhere in the export. Its health is no longer designed (§5: a Bronzebeard video reading × the
   BB→CoA coefficient, replacing the old 25%-of-Lucifron placeholder). Awaiting the player's own logs for the
   remaining timings.
9. **Magmadar's Core Hound cadence.** The Core Hound (11671) reinforcement cadence (first 45s, repeat 50s) is
   still `designed` — no CoA log or export evidence places it. The head/body health split is resolved: the
   heads now mirror the body's own health (§3/§5) instead of holding a designed fraction of it.
10. **Majordomo's kit.** None of his Ascension-only abilities (2108014-2108033: Aegis of the Firelord,
   Molten/Shadow Shield, Broken Bond, Rising Anger, Empowered Shadow Nova/Blast Wave) are cast by him or his
   Flamewaker Healer/Elite adds; only vanilla-id stock abilities run. Thematic name matches to the stock
   mechanics are plausible but unverified — no log corpus covers Majordomo at all.
11. **Melee damage is not scaled per difficulty.** `creature_template.DamageModifier` (and every other stat
    field except health) is byte-identical across all four difficulty variants for every one of the 31 MC
    entries checked — the variant rows differ from Normal only in `HealthModifier` (§5) and, for the 7
    scheduled bosses, in spell substitutions. Melee autoattack damage is therefore the same on Ascended as on
    Normal. Needs a decision on whether melee should scale the way boss-cast damage now does (§6), and by what
    ratio.
12. **Lava Burst/Ignite tick damage.** The Damage Info mechanism (§6) is bound to a spell's initial-hit effect
    or (for the 3 periodic auras) the tick's own `DoEffectCalcAmount` — confirmed working for both shapes. What
    is not addressed: whether every periodic-damage instance across the boss kits (not just the 3 bound here)
    is correctly categorized as "hit" vs. "periodic" for Damage Info purposes; no cross-check beyond the 12
    bound pairs was performed.
13. **Trash timers are designed, not measured**, for the 15 replicated SmartAI entries (§4) and especially for
    Lava Annihilator/Lava Elemental/Lava Reaver's brand-new kits, since CoA's own export records essentially
    no real cooldown data for MC trash (almost every cast shows "1ms"/no cooldown in the export). All of these
    are flagged in §4's table; none claim measured status.
14. **~~Flamewaker Protector's Dominate Mind cadence.~~ Moot: the add is removed (`rev_20260930_98`, §8 item
    7).** It had confirmed firing on a flat 5s SmartAI cooldown against a random non-top-threat target, with
    two Protectors per pull doing this simultaneously. The open question of whether the ability belonged on
    Lucifron himself instead no longer applies — it left with the add, not moved.
15. **Heating Up (Baron Geddon, 2105746) is not wired.** A `MOD_DAMAGE_PERCENT_DONE` self-stack aura with no
    `EffectTriggerSpell` anywhere pointing at it and no roll on its own base points — the DBC gives no
    evidence of what triggers it or by how much. Left unimplemented rather than inventing a stack/percentage.
16. **Harbinger Priests' Damage Info is unmapped.** No "Harbinger Priest" info-aura family (2105950-53, seen
    in inventory) was matched to a live cast; not one of the 12 pairs wired in §6, left unmapped.
17. **Sulfuron's own Dark Strike (19777) is dead code** — never `cast_start`s from Sulfuron himself; the
    Flamewaker Priest add casts the identical id instead. Not changed, flagged in case that was unintended.
18. **Magmadar's CoA/BB health-coefficient outlier: accepted.** Every other boss with both readings lands the
    CoA/BB ratio at 3.30-3.32; Magmadar's pair gives 3.14. He has his own CoA reading, so no coefficient is used
    for him, and the user accepted the difference (the scale is right).
19. **CoA-only adds: implemented, per the combat-log corpus, except what remains below.** Cull the
    Destroyer, Proxima the Opressor and Ebon the Cruel (92031-92033) are now Sulfuron's other three
    disciples; Son of Flame and Greater Son of Flame (92026/92027) and Unstable Son of Flame (92028, the
    previously unnamed "larger add") complete Ragnaros's merge chain; Sacrificial Chains (92030) is
    Majordomo's. The player's "Flamewaker Elite skin" recollection for Sulfuron's adds is contradicted by the
    export's own model (display 12030, the plain Flamewaker skin) and not used. Remaining loose ends from
    this pass are items 22-28 below.
20. **Ragnaros's own health-design scale factor (~x2.85-2.86) differs from the rest of the boss family's
    (~x1.365).** Both are internally consistent with the two anchor points (his prior design vs. his own direct
    CoA readings at Normal and Ascended), but no explanation was sought beyond the base flex table's existing
    note that Ragnaros already needed a separate end-boss factor from the rest of the roster.
21. **A live in-game pull of the rebuilt health pools was not exercised this session** (Ragnaros's 50% start,
    Magmadar's head/body health mirroring under real damage, a flexed trash pack at a live player count).
    Confirmed instead by direct `coa_boss_flex` database inspection on slot 3 after deploy and a clean
    worldserver start/load; see `hp-pools.md`'s Verification section for why (no working GM credential for a
    SOAP/console check in this session) and what a follow-up should check.
22. **Unstable Son of Flame's health (24.3M at Mythic ×10, §3) is a damage-lower-bound extrapolation, not a
    reading** — 13× the Greater's own measured figure, plausible but unconfirmed; its finisher (2108749) is
    unwired with no trigger evidence.
23. **Merge distance/hold (5 yd/1.5s) and the disciples' six cast cadences are designed**, not measured — no
    coordinates exist in the corpus for the former, and every disciple/Sacrificial Chains cast shows
    `casts: 0` (aura-application counts only); cadences borrow the closest measured sibling kit instead.
24. **Sulfuron disciples' Shadow Bolt is designed/placeholder for the same reason as items 16/23**: no
    "- Damage Info" family exists for the Shadow Bolt ids. Sacrificial Chains no longer has a self-cast
    heal/Berserk loop — a WoWCombatLog re-query showed 2108020/2108023 land on nearby players, not the chain
    itself (see the Majordomo section above). The chain-target cap now follows the flex raid size (user rule,
    10-14/15-19/20-25 players → 1/2/3, same on every difficulty), not the per-difficulty cap measured earlier;
    confirmed live on slot 3 at 10/15/20 players, but the raw per-spawn logs do not fit the thresholds cleanly
    (see the Majordomo section above) — implemented as specified regardless.
25. **Ragnaros's "Hidden" emerge cluster (2108622-2108661, incl. 2108631 "Emerge - Hidden - Knockback") is
    not implemented** — the likely real submerge/emerge and add-phase machinery, but no cast from either
    Ragnaros GUID (11502/11503) matches it in the corpus; only Fire Strike (2108601/02) is ever seen.
26. **No Normal/Heroic Sulfuron or Majordomo pull exists in the corpus**; their new adds are wired for every
    difficulty on the Mythic/Ascended evidence plus this doc's general no-reason-to-gate reasoning, unconfirmed
    for those two tiers.
27. **Batches A-C's in-game verification (`verify-ABC.md`) is probe/Ghost-only** — the merge chain, disciple
    composition and Sacrificial Chains loop are confirmed there, but no full in-client MC clear has exercised
    any of the three additions.

## Verification

Two Ghost e2e probe campaigns on slot 3, 10 level-60 bots each, `MC_SECONDS=90`, boss followed via
server-truth `.npc info` positions, casts measured against `cast_start`/`cast_go`/`spell_damage`/
`melee`/`periodic`/`aura` packet events. Majordomo and Ragnaros were not pulled in either campaign;
trash is only in scope as boss-summoned adds, and no run produced a boss-summoned add (all nearby
"adds" were pre-existing MC trash/other bosses wandering into range, expected given MC's dense
layout).

- **`final2` campaign** (`7814ee846`, 32 runs, one per boss × difficulty for the other 8 bosses, all
  `--- PASS`): health forced to staged checkpoints then killed and looted, confirming `max_hp` against
  `coa_boss_flex.hp_d{0..3}` × 10, stage sequencing and loot every run — the campaign that disproved the
  suspected "tier split" defects (below).
- **`lm-validation` campaign** (`cafb24165`, 8 runs, Lucifron + Magmadar × 4 difficulties, after the
  Shadow of Lucifron and Magmadar heads/ground-fire work): confirmed the Shadow's summon (t≈5s buff,
  t≈9.5s first Shadow Bolt) and per-difficulty damage on all 4 diffs; confirmed both Magmadar heads
  summon and cast their full kit, including the ground-fire puddle once `cafb24165` fixed its inverted
  hostility check (294-528 periodic ticks/run).

| Boss | d0 | d1 | d2 | d3 |
|---|---|---|---|---|
| Lucifron | works (Impending Doom, Shadow of Lucifron summon+buff+kit) | works | works | works |
| Magmadar | works (heads summon, full kit incl. ground fire; Core Hound adds present) | works | works | works |
| Gehennas | works | works | works | works |
| Garr | works | works | works | works (loot not opened — probe gate) |
| Shazzrah | works (Dampen Magic/Mass Counterspell fixed; Arcane Force Nova fires once clock fix applied) | works | works | works |
| Baron Geddon | works (Inferno casts + 10×1s pulses; Armageddon casts and 2105748 explodes for 8.75-10.0M) | works | works | works |
| Sulfuron Harbinger | works (Conflagrate hp_pct 50%; Flame Spear/Hand of Ragnaros fire via resolved ids); Sulfuron's own Dark Strike is dead code (add casts it instead) | works | works (ids resolve to 350090/350108, not the schedule's literal 19781/19780) | works |
| Golemagg | works (Magma Splash/Cave In fire via resolved ids) | works | works | works |

Two fixes landed between the campaigns and are validated by them: the Shazzrah target fix (`d5f1ca687`,
Dampen Magic/Mass Counterspell were rejected with `SPELL_FAILED_TARGET_NOT_PLAYER` for targeting
Shazzrah himself) and the `CoaBossAI` event-clock fix (`35c4f405e`, `_events.Update(diff)` ran after the
`UpdateVictim()` bail-out, so any victim-less tick stalled every row's timer, making low-frequency casts
like Arcane Force Nova look "never fired" in a short window).

This campaign only checked that Arcane Force Nova *fired*, not that it dealt raid-wide damage once it
did — it did not, until the single-target-vs-area fix in §3 above.

Baron Geddon's Inferno/Armageddon needed no server-side fix — see §3 for the probe-harness root cause.

The "tier split" reports (Sulfuron, Golemagg, Lucifron Impending Doom, Gehennas Rain of Fire "missing"
above Normal) were all a literal-id comparison error: `coa_boss_schedule` names one base spell id per
row, and the core resolves the real per-tier id through `SpellDifficulty.dbc`
(`SpellMgr::GetSpellIdForDifficulty`) at cast time. Re-checking by spell *name* confirms all four
families fire with identical counts/intervals on every difficulty — no tier split, except Sulfuron's
Flame Spear/Hand of Ragnaros, where the resolved d2/d3 ids genuinely have no DBC row linking them back
to the schedule's own 19781/19780 (§3).

Probe pitfalls fixed across both campaigns: bots run at level 60 to satisfy the raid's access
requirement; bots are revived with huge health via `.modify hp` rather than god mode, since god-mode
damage does not appear in combat logs; the boss is followed via server-truth `.npc info` positions
since these bosses patrol, but the naive follow-teleport itself caused Baron Geddon's evade bug above
and had to be made combat-aware; bots stay alive (not ghosts) through the pull so telemetry keeps
flowing; loot is requested only after the corpse position is confirmed within loot distance, though the
gate still blocks a run whose boss ends up out of range at kill time (several runs per campaign, a
harness limitation, not a boss defect).

**`verify-ABC.md`** (slot 3 @ `a5286fa45`, Ghost e2e): Sulfuron disciples confirmed (d0 unchanged 4-Corvus
quad, d2 = 1 Corvus + Cull/Proxima/Ebon casting over 90s); Sacrificial Chains confirmed (spawns on
Majordomo's 29s/47s schedule, heal/Renew loop fires — Berserk and spawn-time Sacrifice not independently
captured, a test-observability gap); Son of Flame chain confirmed (all three merges fire correctly in a
clean single-pull session at the expected health; a Ghost-harness artifact, not a server defect, suppressed
combat on a chained multi-tier session's 2nd/3rd pull). No repository bugs found; the one bug found
(Majordomo-pull facing) was in the throwaway test, fixed in the scratchpad, not committed.

## 9. Batch G mechanics (2026-10-01)

Confirmed defects from `.agents/plans/mc-restoration/diag-G1.md`, `diag-G2.md` and `diag-G3.md` (combat-log
evidence + source reads), fixed individually below. See `impl-G-mechanics.md` for per-fix in-game verification.

1. **Six trash types restricted to Normal by `event_flags`, not just a missing variant.** Molten Giant
   (11658), Molten Destroyer (11659), Flamewaker (11661), Firewalker (11666), Flameguard (11667) and
   Firelord (11668) all carry `event_flags = 2` (`SMART_EVENT_FLAG_DIFFICULTY_0`) on their base-entry
   `smart_scripts` rows — the four difficulty variants reuse the base entry's rows, and `SmartScript::
   FillScript` filters by this flag, so the whole kit silently dropped above Normal. Cleared (not
   replicated — there was nothing to replicate, only a flag to remove). Their spells stay vanilla
   (unscaled) ids where no CoA-specific variant exists for this creature — a separate, documented gap,
   not fixed here (item 11 below, §8 item 11).
2. **Gehennas' Flamewaker adds (11661) given a `coa_boss_flex` row, 10% of Gehennas' own `hp_dN`.**
   The one MC trash type with no flex row at all (rev_20260930_94 omitted it), so it stayed flat while
   Gehennas scaled with raid size -- at 20 players, about 0.57% of his health instead of the
   Bronzebeard reading of roughly 10% the user remembers. Fixed per-difficulty, anchored on
   Gehennas' own measured `hp_dN`, not a fresh BB-video derivation.
3. **Firesworn's on-death Eruption (19497/350126) trimmed to melee range.** The DBC's own
   self-centered radius (SpellRadius.dbc id 12, 100 yd, shared by unrelated spells so left
   untouched) hit effectively the whole Garr room; `spell_firesworn_eruption_melee_coa`
   (boss_garr.cpp) filters the native area-target list down to melee range (3 yd past
   `GetMeleeRange`, which already includes combat reach) after selection, the same
   filter-after-select idiom `spell_magmadar_head_lava_bomb` already uses.
4. **Shazzrah's Arcane Force Nova (2105612 -> 2105613/14/15/16) cast as its own area spell.** The
   Damage Info retrofit above fixed the amount but left the dummy completing into 2105617, a
   single-target placeholder (`TARGET_UNIT_TARGET_ANY`) — live reproduction showed one real hit on the
   tank and zero on the rest of the raid. The real per-difficulty "Hidden Area Damage" spells
   (2105613-16) already carry the correct amount and the correct `TARGET_UNIT_DEST_AREA_ENEMY`
   targeting; `coa_boss_schedule.effect` is now per-difficulty (`effect_d0..d3`, mirroring
   `spell_d0..d3`) so `CoaBossAI` can cast them directly, and the dead 2105617 Damage Info/script rows
   are dropped (see the Shazzrah entry in §3 for the live before/after).
5. **Ancient Core Hound (11673) given SmartAI above Normal, plus Melt Armor.** Like the rest of MC
   trash, only the base entry had any `smart_scripts` rows; replicated onto 111673/211673/311673 and
   added Melt Armor (2105025, `SPELL_AURA_MOD_RESISTANCE_PCT`, stacks to 5) on all four difficulties --
   the kit's real tank-facing armor debuff, confirmed in the export but never wired on any tier. The
   "Ancient X" self-buff family and the undecoded action-type-88 row are unchanged.
6. **Sulfuron's disciples are static spawns, not a mid-fight swap.** Three of the four static
   Flamewaker Priest (11662) spawns around Sulfuron (guids 56679/56681/56682) are now Cull the
   Destroyer/Proxima the Opressor/Ebon the Cruel directly (`creature.id`); the `coa_boss_summon`
   replace-on-pull rows for entry 12098 are removed (rev_20260930_96, edited in place), so the room
   shows four distinct names/abilities from load, not a despawn/resummon a few hundred ms into
   combat. All four now share flags_extra 0x40000000 (knockback/pull immunity, matching the rest of
   MC's trash) and a new CreatureImmunitiesId (9920254) reproducing Corvus' own -254 mask minus
   SILENCE (the corpus shows it landing) and POLYMORPH/BANISH (left possible, per the task's "only
   certain classes could sheep/banish" framing) -- the shared -254 set itself is not edited in
   place.
7. **Shazzrah's Blink leaves a "Reflection of Shazzrah" (11504) behind, casting Mirrored Arcane
   Explosion (2105650).** The export's own record for 11504 is a placeholder stub (level 1,
   health_min/max 1, no combat stats) -- the same shape as Sacrificial Chains and the Son of Flame
   variants before they got real templates -- so its faction/level/combat template is designed off
   Shazzrah's own row and the lightest existing MC trash health figure (Flame Imp), not invented from
   nothing. Summoned at Shazzrah's pre-teleport spot (captured before the engine applies Blink's own
   teleport effect), casts its one spell via SmartAI on spawn, and despawns a few seconds later. One
   per Blink -- no corpus evidence for more.

   **Correction (live-play mechanic design, `rev_20261001_84_molten_core_shazzrah_reflection_persist.sql`):**
   the clone's original 6s timed despawn and one-shot cast undersold the mechanic the user actually plays
   against -- the strategy is that players must keep moving the boss so successive Blinks' clones spread
   out, since several of them casting Arcane Explosion from the same spot stacks unsustainable raid damage.
   The reflection now persists for the whole encounter instead of timing out: `boss_shazzrah_coa.cpp`
   summons it `TEMPSUMMON_MANUAL_DESPAWN`, rooted (`SetControlled(true, UNIT_STATE_ROOT)`) exactly where it
   spawned, passive (no threat list, never chases or melees) and `SetImmuneToAll(true)` (immune to every
   damage school and to CC, not killable or even damageable, while remaining visible and selectable). It
   casts Mirrored Arcane Explosion (2105650, a single flat `SPELL_EFFECT_SCHOOL_DAMAGE` self-centered
   Arcane nova -- `SpellDifficultyId` 0, no per-difficulty sibling family in `Spell.dbc`, confirmed via
   `coa-dbc-viewer`) on a repeating `SMART_EVENT_UPDATE_OOC` cadence instead of once. The corpus (74 pulls on
   entry 11504) never recorded a cast interval of its own for 2105650 (`casts: 0` in every pull, only
   aura/damage-taken evidence survives, the same gap as Sulfuron's disciples), so the cadence reuses
   Shazzrah's own measured Arcane Explosion schedule row unstaggered (`03_boss_schedule.sql`, 2105601,
   first 3600ms/period 8400ms) rather than inventing a reflection-specific number. `flags_extra` already
   carried 0x40000000 (knockback/pull immunity) on the base entry and all three difficulty variants from
   rev_20261001_05 -- unchanged, still correct. `instance_molten_core.cpp` tracks every live reflection's
   GUID (`OnCreatureCreate`/`OnCreatureRemove`) and despawns all of them the moment `DATA_SHAZZRAH` leaves
   `IN_PROGRESS` (`NOT_STARTED`/`FAIL`/`DONE` -- wipe, evade, kill or a reset), the same `SetBossState` choke
   point Garr's Firesworn and Golemagg's adds already use, so clones never count toward encounter state and
   never carry over between pulls. Live-verified on slot 3 (Ghost harness, grouped raid, GM-immortal tank):
   after 3 Blinks, 3 stationary clones stood exactly at their own blink spots, none took damage from
   `.damage`/spells/auto-attacks, each cast Arcane Explosion on the expected cadence, and a wipe cleared
   every clone instantly.
8. **Sacrificial Chains spawns at a fixed point and pacifies the players it chains.** The chain now
   spawns at `MajordomoSummonPos`, the exact room-center point the user stood on and read off
   `.gps` in game (742.1174, -1181.1216, floor Z -120.0913, map 409) -- replacing an earlier
   add-ring-centroid estimate. Chained players are teleported onto a 10 yd ring around the chain
   (shrunk in 2 yd steps toward the chain if the ground or line of sight does not hold at the full
   radius), evenly spread by angle across however many targets this chain actually took, instead of
   standing adjacent to it. For the debuff's duration they can neither move, cast nor attack
   (`spell_sacrificial_chains_sacrifice_coa`: root + `UNIT_FLAG_SILENCED` + `UNIT_FLAG_PACIFIED` on
   apply, reverted on remove) -- neither 2108020 nor 2108023 carries any such effect in Spell.dbc, so
   this reproduces live Ascension's measured 18-23s total cast-stop per chained player
   (diag-G3.md) server-side. Killing the chain still frees its captives (unchanged `JustDied`).
9. **Ragnaros submerges on health thresholds (~35%/~20%), not a flat 180s timer.** The 54-log
   corpus's two full kills both submerge the first time at ~35% HP and the second at ~20% (he starts
   at 50%), each lasting ~55-70s, each spawning 8 Lesser Son of Flame -- a fast-killing raid could
   cross both real thresholds well before the old 180s elapsed-time trigger ever fired, matching the
   "never submerges" report exactly. `EVENT_SUBMERGE` now polls health every 500ms instead of firing
   on a flat timer; the submerge/emerge choreography itself (8 sons, `HandleEmerge()`, early emerge
   once the sons die) is unchanged, only the trigger condition and the 90s->60s safety-ceiling
   duration. Both thresholds rest on only 2 independent kills -- a strong first estimate, not a final
   number.
10. **Baron Geddon's Living Bomb explodes on natural expiry.** 2105702-05 (the carrier aura) had no
    explosion anywhere in the DBC kit. Per the user's own memory, on `AURA_REMOVE_BY_EXPIRE` only
    (not dispel, not the carrier's death) the carrier now gets a light vertical launch and everyone
    else within 5 yd takes fire damage, based on vanilla Living Bomb's own explosion (20476, 3200)
    scaled by the same 1/1.44/1.88/2.32 ladder used everywhere else in this instance -- the user's
    coefficient choice, not a measured value for this spell.
11. **A portal to Ragnaros' lair appears once Majordomo is defeated.** `go_ragnaros_portal_coa`
    reuses the existing "Molten Core Instance Portal" template (181623, display 6450) rather than a
    new one; a static spawn at the room-center point (same point as the Sacrificial Chains,
    `MajordomoSummonPos`) stays not-selectable (`GO_FLAG_NOT_SELECTABLE`) until
    `DATA_MAJORDOMO_EXECUTUS` reaches `DONE`, toggled by the instance script both live and on
    `OnGameObjectCreate` (so it is also usable immediately on re-entering an instance where
    Majordomo is already dead). Using it teleports the clicking player to the Ragnaros lair entrance
    (`RagnarosLairEntranceCoa`), the exact point the user stood on and read off `.gps` in game
    (814.8772, -851.9799, floor Z -228.51599, map 409) -- only the clicker is teleported, not their
    group, matching every other single-player-use portal GO in this instance. The reused template
    carried `size = 5` (five times every comparable portal GO in `gameobject_template`, none of
    which ever actually spawned it in base data) -- corrected to `size = 1`
    (`rev_20261001_90_molten_core_majordomo_room_center_refine.sql`), the most likely cause of both
    the oversized visual and the reported click misses. The portal despawns only on instance reset,
    same as every other static MC spawn.
12. **Golemagg's Cave In is the remembered ground fire, timed off Massive Stomp.** Reverts the
    Magmadar-puddle reuse above (item 10 was superseded by this item and dropped — see commit
    history): `diag-golemagg-cavein.md`'s combat-log corpus shows Cave In's own DBC kit
    (2105825/2105827/2105828, a genuine `SPELL_EFFECT_PERSISTENT_AREA_AURA` ground patch, ~1500/2500/3000
    damage per tick pre-mitigation) landing 3.93-4.10s after every Massive Stomp cast, 8/8 times across
    two independent logs. `coa_boss_schedule` already carried a Cave In row but on an independent
    35s/55s clock; `coa_boss_ai` has no "cast B after A" hook (each row is its own `EventMap` entry), so
    the row's own `first_ms`/`period_ms` were retimed to 13000/45100 to track Massive Stomp's 9000/45100
    instead.
13. **~~T1/T2 token vendor exchange is not implemented.~~ Resolved (`feat/mc-vendors`, `impl-R-vendors.md`).**
    Major Mattingly (14394, Stormwind) and Overlord Runthak (14392, Orgrimmar) did **not** actually have the
    vendor npcflag, contrary to this doc's own earlier claim: `creature_template.npcflag` was 3
    (`UNIT_NPC_FLAG_GOSSIP|UNIT_NPC_FLAG_QUESTGIVER`), missing `UNIT_NPC_FLAG_VENDOR` (0x80) entirely, so no
    vendor window could ever have opened regardless of `npc_vendor` content — fixed to 131
    (`rev_20261001_61_molten_core_tier_vendor_npcflag.sql`). Per the player's own recollection of live CoA,
    talking to either NPC does not open a flat vendor window: it shows a gossip menu of 8 options ("Tokens T1
    Normal/Heroic/Mythic/Ascended", same four for T2), each opening a vendor list scoped to that tier only.
    Both NPCs now run `npc_coa_tier_token_vendor` (`src/server/coa/AscensionTierTokenVendor.cpp`), whose
    `OnGossipSelect` calls `WorldSession::SendListInventory(guid, vendorEntry)` with one of 8 reserved,
    non-creature `npc_vendor` keys (91000001-91000008) per option — the one piece of new C++ this fix needed,
    since the core's existing `vendorEntry` override (already used for `SetCurrentVendor`/`BuyItemFromVendorSlot`
    resolution) made per-tier sub-lists a `SendListInventory` argument, not a new mechanism.
    The exchange price itself needed no C++ and no class-split design: the client's own `ItemExtendedCost.dbc`
    (loaded verbatim, no SQL override — `src/server/game/DataStores/DBCStores.cpp`) already carries one row per
    Molten/Chromatic token id requiring exactly 1 of that token, confirming the tokens' tooltip and resolving
    `diag-P-token-exchange.md`'s open question (token-for-item, not gold-only).
    `rev_20261001_60_molten_core_tier_token_vendors.sql` adds 961 `npc_vendor` rows split across the 8 virtual
    lists (not duplicated per vendor, since both sell the same catalog): every class variant (including each
    set's faction "Bloodforged" skin, where a difficulty clone of it exists) of the nine classic Tier 1 sets
    (Arcanist/Prophecy/Felheart/Nightslayer/Cenarion/Giantstalker's/Earthfury/Lawbringer/Might, plus
    Transcendence as the Horde skin of Prophecy) and the nine Tier 2 BWL sets (Netherwind/Nemesis/Bloodfang/
    Stormrage/Dragonstalker's/Ten Storms/Judgement/Wrath/Faith), identified by `item_template.ItemSet`, class=4
    only — T0.5 and AQ40 Tier 2.5 sets untouched. Per-difficulty clones are picked by a confirmed, reproducible
    item-id-offset rule (entry+0 Normal, +300000 Heroic, +1300000 Mythic, +200000 Ascended — distinct from the
    creature offset convention) rather than guessed; no `AllowableClass`/armor-type/faction restriction applies
    to any of these 961 items (`FlagsExtra` is 0 on all of them, so `Player::BuyItemFromVendorSlot`'s
    Horde/Alliance gate never triggers), matching the "any class/armor type may buy" rule as-is.
    **Correction (`rev_20261001_83_molten_core_vendor_remove_bloodforged.sql`):** the "faction versions, both
    vendors list all" instruction above was wrong — Mattingly/Runthak must sell only the classic Tier 1/Tier 2
    pieces, never a "Bloodforged" variant, for any set or difficulty. `ItemSet` cannot separate the two (a
    Bloodforged piece keeps its base set's id, e.g. "Bloodforged Dragonstalker's Helm" still carries `ItemSet`
    215, not a distinct 60215/61215 as the client DBC's own set name would suggest); every Bloodforged row's
    `item_template.name` starts with the literal "Bloodforged " prefix instead, and that prefix is exact (no
    vendor row contains "Bloodforged" anywhere in its name without it). This removed 320 rows — 80 apiece from
    T1 Normal/Heroic and T2 Normal/Heroic (91000001/91000002/91000005/91000006); T1/T2 Mythic/Ascended
    (91000003/91000004/91000007/91000008) never carried a Bloodforged clone to begin with (see gap below), so
    they are unchanged. Current list sizes, all classic T1/T2 pieces only: T1 Normal 80, T1 Heroic 80, T1
    Mythic 80, T1 Ascended 80, T2 Normal 80, T2 Heroic 80, T2 Mythic 80, T2 Ascended 80 (640 rows total).
    Known gap: most sets' "Bloodforged" skin only had Normal+Heroic clones in this DB (no Mythic/Ascended item
    id exists for it) — moot now that Bloodforged versions are not sold at all.
    **Correction (`rev_20261001_84_molten_core_vendor_mythic_ascended_swap.sql`):** the Mythic and Ascended
    `ExtendedCost` ids above were picked under the same backwards "27=Mythic/37=Ascended" assumption already
    corrected for loot in `rev_20261001_73_molten_core_mythic_ascended_token_swap.sql` (ground truth, confirmed
    by each item's own "@Heroic/@Mythic/@Ascended Raid@" tooltip tag: `25xxxxx` Normal, `26xxxxx` Heroic,
    `37xxxxx` Mythic, `27xxxxx` Ascended). Decoding `ItemExtendedCost.dbc` directly showed the `403xx`/`406xx`
    id family used by lists 91000003/91000007 ("Tokens T1/T2 Mythic", items at the `+1300000` offset) actually
    requires a `2722xxx` token — Ascended, not Mythic — and the `302xx`/`305xx` family used by
    91000004/91000008 ("Tokens T1/T2 Ascended", items at the `+200000` offset) requires a `3722xxx` token —
    Mythic, not Ascended. The two families share per-slot suffixes, so the fix swaps `ExtendedCost` between the
    matching rows of each pair (320 rows: 80 per list × 4 lists); Normal/Heroic were already correct and
    untouched. Live Ghost e2e re-confirmed: a Mythic token buys the Mythic-list piece and is refused by the
    Ascended-list piece, and vice versa for the Ascended token.

## 10. Batch H (2026-10-01): melee damage ladder, Ragnaros submerge re-check, Ancient Core Hound fear

1. **Melee damage now scales per difficulty (user decision).** `creature_template.DamageModifier` was
   identical across Normal/Heroic/Mythic/Ascended for every MC creature (bosses and trash), so melee swing
   damage never scaled even though health (×1/1.44/1.88/2.32) and the Damage Info-bound boss spells (e.g.
   Lucifron Shadow Bolt 800/1600/2400/3200, a ×1/2/3/4 ladder) already did. A dedicated 54-log corpus pass
   (`.agents/plans/mc-restoration/research-H1-H2.md`) found the direct evidence too noisy to support its own
   melee-specific ratio: the best-covered creature (Ancient Core Hound, tank-proxy swings, all four
   difficulties) measured 1:1.25:1.11:1.73, non-monotonic (Mythic below Heroic); the cross-creature
   Normal→Ascended median across the 5 creatures with usable samples was only 1.13×, well short of either
   the health or the spell ladder, and no creature reached either one. Rather than invent an unmeasured
   melee-only constant from noisy, contradictory data, `DamageModifier` on every MC creature's Heroic/Mythic/
   Ascended `creature_template` row is set to the same ×1.44/1.88/2.32 already used (and client-cache
   confirmed) for health — `rev_20261001_11_molten_core_melee_damage_ladder.sql`. Normal is left unchanged:
   the corpus check against our own server's Ascended-realm log (Molten Giant swings, median 498, n=71,
   excluding the player) found Normal's own output already in a plausible range next to comparable corpus
   trash. Out of scope: Sacrificial Chains (92030) and Sulfuron's three named disciples (92031-92033), which
   have no difficulty-variant `creature_template` rows at all, and Magmadar's two head creatures (80642/
   80643), which carry `DamageModifier = 0` and never melee (immune to all damage, mirror the body's health).
   Flagged as designed (a consistency choice with the health ladder), not a melee measurement.
2. **Ancient Core Hound (11673) fears on Mythic and Ascended only, modeled on Magmadar's own fear.**
   Per the user's framing ("works like Magmadar's fear"), `.agents/plans/mc-restoration/research-H3.md`
   traced what Magmadar's fear actually is in live play: the body casts Panic (2105309, confirmed
   `SPELL_AURA_MOD_FEAR`, self + area-enemy target in `Spell.dbc`, `SpellDifficultyId` 0 so no
   per-difficulty variant exists) roughly every 40s flat, 157-196 times across the 54-log corpus — not the
   vanilla donor id (19408) `boss_magmadar_coa.cpp`'s C++ used to run. That gap is now fixed in the same
   script: `SPELL_PANIC_COA` is 2105309 and the body's `EVENT_PANIC_COA` repeats on a flat 40s (first cast
   still at the previous, unmeasured 9500ms offset), on every difficulty (Normal through Ascended, the body
   script is shared). Not the "Bellowing Roar"/"Ancient Dread/
   Fury/Despair/Hysteria" family (2105308/2105310-13) the task brief initially named, which exist as catalog
   ids but never fire in any of the 54 logs. The hound's own kit has no fear anywhere: its action-type-88
   random pool (now decoded, see the trash table above) is Ground Stomp/Cauterizing Flames/Withering Heat/
   Ancient Despair/Ancient Hysteria/Ancient Dread — stun, resistance and stat effects, not fear — confirmed
   both by static decoding and by the corpus (no Panic or any `MOD_FEAR` aura ever recorded on the hound, any
   difficulty). `rev_20261001_10_molten_core_ancient_core_hound_fear.sql` adds a Panic (2105309) self-cast
   row (first 8s, repeat 40s flat, borrowed from Magmadar's own measured cadence — no hound-specific fear
   cadence exists to measure) only to the Mythic and Ascended `creature_template` entries (211673/311673),
   leaving Normal/Heroic (11673/111673) untouched — this fork already gates MC trash by difficulty through
   separate per-tier entries, so no `event_flags` difficulty bit is needed on top of that split.
   **Superseded by item 4 below**: that premise was wrong — see item 4.
3. **Ragnaros's submerge duration re-checked against the corpus — no change.** The task asked to compare
   this session's live-measured 78.5s submerge→emerge cycle (`verify-G.md` item 9) against the corpus's
   diag-G3.md estimate of ~55-70s. A fresh extraction of all 4 measured submerge intervals across the 54-log
   corpus (2 kills × 2 submerges) gives 54.6/57.1/65.2/69.3s, median 61.15s — squarely inside the existing
   range, and the current code's 60s `EVENT_EMERGE` cap (set from this same diag-G3 evidence in a prior
   session) already sits right on that median. The 78.5s figure is a different metric: it is the time for a
   single automated Ghost-harness bot run to finish killing the eight Lesser Son of Flame adds (which lets
   Ragnaros emerge early via `SummonedCreatureDies`), not the submerge timer itself — confirmed by reading
   the test and the 60s cap firing regardless of add state. No code or data change made.
4. **Ancient Core Hound fear still never fired in game — item 2's per-entry split is dead on a real spawn.**
   The user reported no fear in play on Ascended. `Creature::UpdateEntry` always `SetEntry(Entry)` to the
   *base* `creature_template` entry (`Creature.cpp`) — only `m_creatureInfo` switches to the
   `difficulty_entry_1..3` variant for stats; `GetEntry()` never becomes 211673/311673 on a real spawn, any
   difficulty. `SmartScript::GetScript` falls back to `GetScript((int32)me->GetEntry())` (`SmartScript.cpp`),
   so a real spawn only ever loads the *base* entry's (11673) smart_scripts rows. The row item 2 added to
   211673/311673 never ran; the in-game "pass" that earlier appeared to confirm it used
   `.npc add temp 311673`, which spawns a temporary creature whose entry genuinely is 311673 — not a real
   Ancient Core Hound, and not representative of how MC trash actually spawns. The same flaw also made
   `rev_20261001_03_molten_core_core_hound_melt_armor.sql`'s rows 0-3 on 111673/211673/311673 dead (they are
   byte-for-byte copies of 11673's own rows, which already run on every difficulty via `event_flags = 0`,
   so they were redundant as well as dead), and `rev_20261001_05_molten_core_shazzrah_reflection.sql`'s
   summon-cast rows on 111504/211504/311504 (Reflection of Shazzrah, also summoned with its base entry and
   so also always `GetEntry() == 11504`). Fix (`rev_20261001_14_molten_core_hound_fear_base_entry.sql`,
   `rev_20261001_15_molten_core_variant_smart_scripts_audit.sql`): delete every dead variant-keyed row and
   re-assert the hound's full kit (rows 0-3 unchanged) plus the Panic cast (row 4) on the base entry
   (11673) alone, gating row 4 to Mythic+Ascended with `event_flags = 0x18`
   (`SMART_EVENT_FLAG_DIFFICULTY_2 | SMART_EVENT_FLAG_DIFFICULTY_3`, `SmartScriptMgr.h`) — the only
   mechanism that actually reaches a real spawn (`SmartScript::FillScript` filters by
   `obj->GetMap()->GetSpawnMode()` against `event_flags`, not by which `creature_template` entry the row is
   keyed to). The Shazzrah reflection's variant rows were pure duplicates of its base-entry row (already
   unconditional) and were only deleted, nothing moved. No other pending Molten Core SQL file keys
   `smart_scripts` on a `difficulty_entry_1..3` variant entry; `coa_boss_schedule`, `coa_boss_flex` and the
   `coa_boss_ai`-scripted bosses are all keyed on base entries already, and no MC creature has a
   `creature_formations` row in this branch. `tools/test_molten_core_smart_scripts_base_entry.py` replays
   every pending Molten Core SQL file's smart_scripts DELETE/INSERT statements in filename order and fails
   if any `(entryorguid, source_type = 0)` row still standing afterwards is keyed on a 1xxxxx/2xxxxx/3xxxxx
   variant entry.
   **Probe pitfall**: `.npc add temp <variant-entry>` spawns a creature whose *own* entry is that variant
   id — it does not exercise the `UpdateEntry`/`GetScript` base-entry fallback that a real, DB-spawned
   creature goes through. Verifying a difficulty-gated SmartAI row needs a persisted spawn (a `creature`
   table row on the base entry) on the target difficulty, not a temp-spawn of the variant id.

## 11. Batch I (2026-10-01): map-409 spawnMask restore

Heroic/Mythic/Ascended Molten Core were empty of every creature and gameobject: `02_mc_difficulty_spawns.sql`
(`modules/mod-coa-raid-difficulty/data/sql/db-world/base/`) puts every map-409 row on `spawnMask = 15` (all
four difficulty bits - the core only spawns a row into the grids of the difficulties whose bit is set, with
no fallback), but `rev_20260930_99_ASC_northshire_revamp.sql` (from main PR #5764, an unrelated Northshire
Valley field-level reconciliation) carries a section-4 cleanup statement that narrows it back down:
`UPDATE creature/gameobject SET spawnMask = 1 WHERE map IN (309, 531, 509, 469, 409) AND spawnMask = 15`. The
updater merges module and pending files into one list sorted purely by filename
(`UpdateFetcher::PathCompare`, `src/server/database/Updater/UpdateFetcher.cpp`), so the module's `02_...` file
always applies before any `rev_...` pending file; nothing after the ASC revamp put map 409 back to 15, so MC
has been Normal-only since that merge.

Fix: `rev_20261001_13_molten_core_restore_spawn_masks.sql` re-asserts `spawnMask = 15` on every map-409
`creature`/`gameobject` row, sorting after the revamp file by filename. This also corrects the Majordomo
portal gameobject added at `spawnMask = 1` in `rev_20261001_08_molten_core_majordomo_portal.sql` - its
visibility is already gated by the instance script's encounter state, not by the spawn mask, so it belongs on
all four difficulties like the rest of MC. `tools/test_molten_core_spawn_masks.py` replays the statement
order across both directories and fails if the final effective map-409 spawnMask is not 15, or if any later
file inserts a map-409 row with a narrower one.

## 12. Batch AC (2026-10-03): room-center position, chain ring, portal fixes, playerbots DPS exclusion

Live user report from a playerbots (mod-playerbots) raid test, with exact `.gps` readings this time instead
of estimates.

**Room-center point corrected.** The user stood at the room's real center and read it off `.gps` directly:
(742.1174, -1181.1216, floor Z -120.0913, orientation 5.7636776, map 409) — replacing `impl-K.md`'s
add-ring-centroid estimate (753.3, -1174.4, -119.1). `MajordomoSummonPos` (the Sacrificial Chains spawn
point) and the Ragnaros portal GO's static spawn (guid 9000601) both moved to this exact point.

**Chained players now stand on a ring, not adjacent to the chain.** `OnSacrificeApplied`
(`npc_sacrificial_chains_coa.cpp`) placed chained players 2 yd from the chain; per the user's visual
request, they are now placed on a 10 yd ring, evenly spread by angle across however many targets this chain
instance actually took, with the radius shrunk in 2 yd steps (down to a 4 yd floor) if the ground or line of
sight does not hold at the full 10 yd.

**The Ragnaros portal's destination point corrected the same way.** The user stood at the Ragnaros lair
entrance and read it off `.gps`: (814.8772, -851.9799, floor Z -228.51599, orientation 0.7247386, map 409) —
replacing `RagnarosLairEntranceCoa`'s earlier estimated midpoint. The portal still teleports only the
clicking player, not their group, matching every other single-use portal GO in this instance.

**The portal's oversized scale, and the most likely cause of the click-through reports.** The reused "Molten
Core Instance Portal" template (181623, display 6450) carried `size = 5` in the base data, despite never
being spawned anywhere in stock content; every comparable portal template in `gameobject_template`
(`Instance Portal`/`Instance Portal Green/Red/White`/`Mage Portal`/`Caverns of Time Portal`) uses `size = 1`.
`GameObject::Use()` already calls `AI()->GossipHello()` for any player as long as `GO_FLAG_NOT_SELECTABLE`
is clear — the same idiom the Cache of the Firelord chest uses successfully — and the `DATA_MAJORDOMO_
EXECUTUS == DONE` flag-toggle in `instance_molten_core.cpp` is symmetric on both the live `SetBossState`
transition and `OnGameObjectCreate` (instance reload), with no code path found that would leave it stuck
`NOT_SELECTABLE` once the encounter is done. The 5x scale mismatch — a model five times its logical size,
whose collision no longer lines up with the GO's reported position — is the only concrete defect found and
is corrected to `size = 1` (`rev_20261001_90_molten_core_majordomo_room_center_refine.sql`); re-confirm
click-through live after deploy in case a second cause remains.

**Why mod-playerbots refuses to DPS Majordomo after the 8 adds die (not our defect).** Reported: a human
player can attack and damage Majordomo once all 8 adds are dead (matching the K6b 20%-floor fix,
`DamageTaken`/`CompleteEncounter` in `boss_majordomo_executus.cpp`), but the user's playerbots group will
not. Our own `CanAIAttack` only returns `false` once `DATA_MAJORDOMO_EXECUTUS == DONE` (i.e. after the
20%-floor fight actually ends) — nothing in `SummonedCreatureDies`/`DamageTaken` changes Majordomo's
faction, react state, immunities or unit flags while the adds are dying or during the post-adds solo phase,
so there is no CoA-side flag/faction/evade-mode bug to find. The actual cause is in
`modules/mod-playerbots/src/Ai/Raid/MC/MCStrategy.cpp`,
`RaidMcStrategy::AppendTargetExclusions` (around line 124):

```cpp
if ((golemaggAlive && unit->GetEntry() == NPC_CORE_RAGER) || unit->GetEntry() == NPC_MAJORDOMO_EXECUTUS)
    exclusions.insert(guid);
```

This unconditionally excludes every creature with Majordomo's entry (12018) from bots' DPS/Attacker target
lists, with a comment stating the stale stock assumption directly: "Majordomo reflects and cannot die; his
encounter ends when the eight adds are dead." That was true of the stock encounter (and of this fork before
the K6b fix); it is no longer true on `feat/mc-restoration`, but the exclusion has no HP or boss-state check
— it fires regardless of how close to 20% Majordomo actually is — so no server-side flag or state change can
satisfy it. `mod-playerbots` is not part of this repository's tracked tree (not a submodule here; present
only in slot 2's build clone), so it was not modified as part of this task. Fixing bots' behavior requires
either removing the unconditional Majordomo branch from that exclusion rule upstream in mod-playerbots, or
gating it on something bots can observe (e.g. only exclude him while adds remain alive).

Verification: `python -B tools/verify_all.py --stages source --base origin/main` plus `codestyle-cpp.py`/
`codestyle-sql.py --files` on every touched file; live `.gps`/`.go xyz` re-check of the new room-center and
lair-entrance points, the chain ring radius, and the portal's scale/click behavior on a claimed slot — see
`impl-AC-majordomo.md`.

**Related finding, out of scope for this fix**: the same ASC revamp statement also narrows `spawnMask` on
other instance maps 309, 531, 509 and 469 (to 1) and map 249 (to 3). Those are not Molten Core and were not
touched here; flagged for the user to decide whether they need the same restore treatment.

## 12. Batch Z (2026-10-03): Baron Geddon's Inferno damage raised 20%

The user reported Inferno too light: raid frames barely dropped and the raid never came close to dying on
Ascended. Inferno's per-wave damage is real DBC data, not a placeholder: the channel 2105740
(`coa_boss_schedule` row `12056` idx 6) applies a `PERIODIC_TRIGGER_SPELL` aura on itself, ticking every
1000ms, whose `EffectTriggerSpell[1]` is resolved per difficulty by the core's own
`SpellMgr::GetSpellIdForDifficulty` (`SpellAuraEffects.cpp:5993`) through `SpellDifficulty.dbc` row 2119:
2105741 Normal, 2105742 Heroic, 2105743 Mythic, 2105744 Ascended. Each is a single `SCHOOL_DAMAGE` effect
with its own fixed `EffectBasePoints`/`EffectDieSides` in `Spell.dbc` (no SpellDifficulty indirection below
that), so none of them can be edited without a DBC edit:

| Difficulty | Spell | Pre-change range (DBC) | Pre-change avg |
|---|---|---|---|
| Normal | 2105741 | 875-999 | 937.5 |
| Heroic | 2105742 | 1167-1333 | 1250.0 |
| Mythic | 2105743 | 1459-1666 | 1562.5 |
| Ascended | 2105744 | 1750-1999 | 1874.5 |

Since nothing in the data marks one tier as already correct, the fix applies the same +20% to all four:
`spell_geddon_inferno_damage_coa` (`boss_geddon_coa.cpp`), registered on all four ids via
`rev_20261001_90_molten_core_geddon_inferno_damage.sql`, multiplies `GetHitDamage()` by one tunable constant,
`INFERNO_DAMAGE_MULTIPLIER = 1.20f`, in `OnEffectHitTarget` — after every other calculation, so the result is
exactly ×1.20 of whatever the engine would otherwise have dealt, regardless of caster-side bonuses.

Verified live on slot 4 with `TestMCRaidProbe` (`ConquestOfAzerothGhost/e2e/zzmcraid/raid_test.go`), a 10-bot
raid vs. a `.npc add`-spawned Baron Geddon at his own spawn point (747.547, -981.676, -178.401, map 409),
reading raw `SMSG_SPELLNONMELEEDAMAGELOG` (`amount` = damage + absorb + resist, i.e. pre-mitigation):

| Difficulty | Spell | Observed range (after) | Observed avg | Expected post-×1.20 range | avg/pre-avg ratio |
|---|---|---|---|---|---|
| Normal | 2105741 | 1050-1197 (n=100) | 1130.8 | 1050-1198.8 | 1.206 |
| Ascended | 2105744 | 2100-2398 (n=100) | 2247.76 | 2100-2398.8 | 1.199 |

Both observed ranges fall exactly inside the expected post-multiplier window computed from the DBC's own
`EffectBasePoints`/`EffectDieSides`, and both sampled averages land within 1% of the targeted 1.20 ratio (the
residual is random-roll noise from `EffectDieSides`, not drift in the multiplier). Heroic and Mythic were not
live-tested — the multiplier is a single constant applied identically to all four difficulty ids, with no
per-tier branch, so there is no mechanism by which they could scale differently.

## 13. Batch AI (2026-10-03): Ragnaros portal spawned dynamically, retyped for a working client click

Three live-play reports on top of batch AC's position/scale fix: the portal was visible from the start of the
Majordomo fight (should only exist after he is defeated); its position still read as wrong; and it still could
not be selected/clicked, even though `CMSG_GAMEOBJ_USE` reached the server (`go_ragnaros_portal_coa`'s own
`GossipHello` already teleports correctly once triggered).

**Visible before the kill — root cause.** `go_ragnaros_portal_coa` (guid 9000601) was a static `gameobject`
row, present from map load on every difficulty; only `GO_FLAG_NOT_SELECTABLE` gated it, toggled by
`SetBossState`/`OnGameObjectCreate`. That flag blocks `GameObject::Use()`'s early-return check
(`GameObject.cpp:1487`), not rendering — the client draws the model regardless of the flag, matching the
report exactly. Fixed by removing the static row (`DELETE FROM gameobject WHERE guid = 9000601`,
`rev_20261001_i1_molten_core_majordomo_portal_dynamic.sql`) and summoning it instead:
`instance_molten_core.cpp`'s new `SummonRagnarosPortal()` (`Map::SummonGameObject`, persistent — respawn time
0) is called from `SetBossState(DATA_MAJORDOMO_EXECUTUS, DONE)` for a live kill and from `OnPlayerEnter()` for
an instance already saved `DONE` (`GameObject::AddToWorld` invokes `InstanceScript::OnGameObjectCreate` for a
summoned object exactly as it does for a static spawn, so the existing GUID-tracking case needed no change).
The object simply does not exist before the encounter ends; nothing despawns it afterwards (no code touches
`_ragnarosPortalCoaGUID` outside creation/lookup, so it survives subsequent wipes/resets on other bosses, and a
full instance reset tears down the whole map like every other MC spawn).

**Position re-checked.** `rev_20261001_90`'s point (742.1174, -1181.1216, -120.0913) matches the user's fresh
`.gps` reading (742.1174, -1181.1216, floor Z -120.091324) exactly and was already live on the reporting slot
(deployed at `bcb68ecf3`, which includes `19ad28636`, the commit that added `rev_20261001_90`) — not a stale
position. One real mismatch found: `rev_20261001_90` updated only `position_x/y/z`, never `orientation`, which
stayed at `rev_20261001_08`'s original 4.046 (facing the old post-defeat spot) instead of the user's 5.7636776
— a ~99° facing error, folded into the new dynamic spawn's quaternion (`SummonGameObject`'s rotation2/3 =
`sin(5.7636776/2)`/`cos(5.7636776/2)` = 0.2568427/-0.9664532). No second gameobject row, duplicate guid
(99000601) or stale post-defeat spawn (851.9, -812.9, -229.6) exists anywhere in `data/sql/` — grepped
`gameobject`/`gameobject_template` across base, archive and every pending file; the only row at entry 181623
was the one static spawn already covered above, now removed.

**Not clickable — root cause.** `gameobject_template` 181623 ("Molten Core Instance Portal") is `type = 5`
(`GAMEOBJECT_TYPE_GENERIC`). Every other reuse of that exact type/name family in this fork's base data
(19527-19531 "Instance Portal"/"Instance Portal Green/Red/White"/"Mage Portal", 19503 "Caverns of Time
Portal") is pure decoration: stock Blizzard dungeons always pair it with a separate `areatrigger` that performs
the teleport on walk-in (this fork's own `rev_20260923_04_coa_inquisitorial_dungeon_portal.sql` uses the same
idiom for its type-31 portal doodads) — a type-5/31 object is never the thing a player clicks. `displayId`
6450's own `GameObjectDisplayInfo.dbc` bounding box is not zero (checked directly: min/max
(-0.273,-4.413,-1.470)/(0.273,4.413,7.222)), so the earlier "bad model" theory does not hold; the type is what
the client uses to decide whether an object offers an interact cursor at all, and `GameObject::Use()`'s
type-agnostic `AI()->GossipHello()` call before its own type `switch` (confirmed by reading `GameObject.cpp`)
is exactly why the server-side click still worked while the client-side one never could.

Fixed by retyping 181623 to `type = 10` (`GAMEOBJECT_TYPE_GOOBER`) with `displayId = 7161` ("Orb of
Translocation"), copying `gameobject_template` 180911/180912/182543/182546 field-for-field (all `Data0-20`
zero, no lock/quest/spell gate) — that exact type/displayId pair is spawned as real, static world objects in
this fork's own base data (`gameobject` guids 12932/13210/23108/23159, map 530, Netherstorm/Eco-Dome
teleporters), i.e. a combination already confirmed clickable in this client rather than an untested guess.
`go_ragnaros_portal_coa`'s `GossipHello` needed no change — it already worked once a player could actually
target the object.

Verification: `python -B tools/verify_all.py --stages source --base origin/main` (pre-existing,
unrelated `tools/test_comments.py` self-test failure on `origin/main` itself, confirmed via `git stash`) plus
`codestyle-cpp.py`/`codestyle-sql.py --files` on every touched file, both clean. Live re-check pending a free
slot: before `DATA_MAJORDOMO_EXECUTUS` is `DONE`, no `GO_RAGNAROS_PORTAL_COA` object should exist anywhere
near the room (`FindGameObjectByEntry` empty); after `.instance setbossstate molten_core 8 3` (or a real kill)
it should appear at the exact point, right-clickable, and `GAMEOBJ_USE` should teleport the clicker to
`RagnarosLairEntranceCoa`.

## 14. Batch AF (2026-10-03): Molten Giant/Molten Destroyer AoE damage (Smash/Massive Tremor) scaled per difficulty

User report: Molten Giant (11658) and especially Molten Destroyer (11659) were expected to deal Golemagg-Stomp-class
raid AoE damage, scaled per difficulty; on live, Ascended took almost nothing from them beyond the melee ladder.

Both already cast a real, native AoE ability on every difficulty since rev_20260930_99 (`§4`): Smash (18944,
`SCHOOL_DAMAGE`, `TARGET_SRC_CASTER`+`TARGET_UNIT_SRC_AREA_ENEMY`, SpellRadius 13 = 10 yd cleave) and Massive
Tremor (19129, same target shape, SpellRadius 23 = 40 yd, essentially room-wide for trash positioning) — unlike
Golemagg's Massive Stomp, these are not DBC-placeholder dummies, so the raid was never taking literally zero
damage from them, but the damage was the ability's own flat base points regardless of difficulty (rev_20260930_99's
own comment: "Their spells are vanilla (unscaled)").

The live Ascension combat-log corpus (`coa-combatlog-parser` `local/logs/ascension`, `mc-summary.md`) recorded
**zero casts of either ability's own per-difficulty DBC family, on any difficulty, in the entire corpus** — the
same SmartAI-difficulty-gate bug rev_20260930_99 fixed evidently affected the original live server too. The
family itself is real, not invented: `coa-combatlog-parser`'s `scripts/mc_evidence.py` (`load_spell_difficulty`)
decodes `SpellDifficulty.dbc` directly and reports Smash as group 1818 (`2018944`/`2018946`/`2018947`/`2018948`,
D0-D3) and Massive Tremor's family as "Ground Tremor", group 1873 (`2100278`/`2100475`/`2100476`/`2100477`,
D0-D3) — both confirmed present in each creature's own db.exil.es export kit `spells` list (11658, 11659) and
cross-checked against `mc-dataset.json`'s `spell_difficulty_map`. Real damage (this fork's "+1" Damage Info
convention) is Smash 300/599/723/902 and Massive Tremor 300/599/898/1197 for D0-D3 (DBC `EffectBasePoints`+1).

Implementation reused the existing `spell_coa_damage_info_hit` mechanism (`DamageInfo.cpp`, rev_20260930_83) —
no new C++. Unlike Golemagg (whose real spell was triggered fresh per player from a dummy hook), Smash/Massive
Tremor are already native multi-target AoE spells with a real `SCHOOL_DAMAGE` `EFFECT_0`, so the script was bound
directly to the live cast ids: `rev_20261001_e1_molten_core_giants_damage_info.sql` adds
`coa_spell_damage_info` rows for `18944`/`19129` (pointing at the two families above) and registers
`spell_coa_damage_info_hit` on both via `spell_script_names`.

**A real surprise found during live verification**: `SpellEffectInfo::CalcValue(caster)` is not a flat DBC
lookup — it runs through `sScriptMgr->ModifySpellEffectBaseValue`, this fork's open-world per-creature damage
scaling hook, using the *caster's* own level/stats. So the absolute numbers below are well above the raw
DBC base points; what the fix controls is the *difficulty family selected* (same base-point ratios as the DBC),
not raw unscaled damage. This was confirmed by temporarily instrumenting `ResolveDamage`/`SetDamage` with
`LOG_ERROR` (not part of the shipped commit) and inspecting the live mode/info-spell/`CalcValue` resolution
before removing it.

Verified live on slot 3 (`TestMCRaidProbe`, 6 grouped bots, `.modify hp` pool, Molten Giant/Destroyer's own
natural spawn near 955.057 -656.78 -199.603, map 409), both abilities hitting all 6 bots simultaneously per
cast on every run:

| Difficulty | Ability | n | min | max | mean | Expected bp ratio vs D0 | Observed mean ratio vs D0 |
|---|---|---|---|---|---|---|---|
| Normal (D0) | Smash | 12 | 1106 | 1509 | 1349.5 | 1.00 | 1.00 |
| Ascended (D3) | Smash | 18 | 3209 | 3641 | 3389.9 | 3.02 (902/299) | 2.51 |
| Normal (D0) | Massive Tremor | 11 | 1115 | 1289 | 1226.8 | 1.00 | 1.00 |
| Ascended (D3) | Massive Tremor | 12 | 4452 | 4603 | 4530.2 | 4.00 (1197/299) | 3.69 |

Both abilities scale meaningfully above Normal now (previously identical at every difficulty); the observed
ratios run somewhat below the raw DBC base-point ratios, consistent with `ModifySpellEffectBaseValue`/armor
mitigation compressing the gap rather than the family selection being wrong (`mode`/`infoSpell` resolution was
confirmed correct for both D0 and D3 during the instrumented run). Heroic/Mythic were not live-tested — both
families' D1/D2 members were confirmed present and correctly ordered via `SpellDifficulty.dbc` (`mc_evidence.py`),
not live-measured.

Knock Away (18945, single-target) and Stunning Strike (20276, single-target) were investigated and have their
own real families (group 1819: `2018949`/`2018950`/`2018951`; `2100135`), but are out of this fix's scope — the
report concerns AoE damage, and the task's instruction was to keep the melee/special-attack ladder as-is unless
the corpus showed otherwise. Not applied; see `docs/coa/molten-core.md` §4 table for the identified ids.

## 15. Batch AH (2026-10-03): Sacrificial Chains made immovable

The user reported Sacrificial Chains (92030) displaced across the room by a player's displacement ability,
despite the creature already carrying `flags_extra` 0x40000000 (the knockback/pull immunity flag `diag-K-combat.md`
item 1 had already confirmed was set via `rev_20261001_16`). That flag only protects a target inside
`Spell::EffectKnockBack` and `Spell::EffectPullTowards` (`src/server/game/Spells/SpellEffects.cpp`); every other
displacement path in this codebase was read for a gap (`Unit::KnockbackFrom`/`JumpTo`, `MotionMaster::MoveKnockbackFrom`/
`MoveJump`, `Unit::NearTeleportTo`, every CoA class file under `src/server/coa/` calling one of those on a unit
other than its own caster). Four real gaps were found, all unrelated to any specific class being reported — any of
them could have moved the chain:

- `Unit::KnockbackFrom` itself had no immunity check at all; a script calling `target->KnockbackFrom(...)` directly,
  bypassing `Spell::EffectKnockBack`, skipped the guard outright. `AscensionWitchHunterAbilities.cpp`'s point-blank
  knockback (spell ids 680236/680270-680273) does exactly this on every hit.
- `Spell::EffectTeleportUnits` never checked the flag at all.
- Four CoA-authored grip/pull/displace effects called `MotionMaster::MoveJump` or `Unit::NearTeleportTo` on an enemy
  target directly, with no immunity check of any kind: the Starcaller's `Pull()` (`AscensionStarcallerAuras.cpp`),
  the Chronomancer's `spell_ascension_displacement::Displace` (`AscensionChronomancerMovement.cpp`), the Reaper's
  `aura_ascension_reaper_harvesting_grounds::Leave` pull-back (`AscensionReaperSpellContracts.cpp`), and the Knight
  of Xoroth's and Necromancer summon's command-grip effects (`AscensionXorothSummons.cpp`,
  `AscensionNecromancerSummons.cpp`).

**Fix, in depth.** `Unit::IsImmuneToForcedMovement()` (`src/server/game/Entities/Unit/Unit.h`/`.cpp`) centralizes the
same world-boss/dungeon-boss/`IsImmuneToKnockback()` check `Spell::EffectKnockBack`/`EffectPullTowards` already use,
and is now checked inside `Unit::KnockbackFrom` itself (so every existing and future caller is covered for free,
with no behavior change for the two effect handlers that already guarded themselves before calling it),
`Spell::EffectTeleportUnits`, and each of the five CoA call sites above. Independently, `npc_sacrificial_chains_coa`
now roots itself (`SetControlled(true, UNIT_STATE_ROOT)`) on spawn and self-corrects in `UpdateAI` — a cheap
500 ms timer comparing its live position to `GetHomePosition()` and `NearTeleportTo`-ing back if the drift exceeds
0.5 yd — as a second, independent layer that catches any displacement path this pass missed, without touching its
damageability (still killable, so chained players are still freed on its death per §3's existing `JustDied`
cleanup).

Verification: `codestyle-cpp.py --files` on every touched file passed; `tools/verify_all.py --stages source
--base origin/main` passed except the pre-existing `tools/test_comments.py` self-test failure (documented in
every prior session on this branch, unrelated to any file this change touched). See `impl-AH-chain-immovable.md`
for the live evidence.
