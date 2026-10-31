# Zul'Gurub restoration — state of play and plan

This documents the state of Zul'Gurub (map 309) on CoA before `feat/zg-restoration`, compared with the live
Ascension CoA raid, and what the branch is to change. As with [Molten Core](molten-core.md), every row is tagged with
the evidence it rests on, and every open point stays open rather than guessed.

## 1. Summary

Live CoA ran Zul'Gurub on four difficulties — Normal, Heroic, Mythic and Ascended — with per-boss achievements for
each (Normal, Heroic, Mythic, Ascended 10/25, Nightmare). The client still offers all four: `MapDifficulty` 67-70
(difficulty 0-3) and `LFGDungeons` 420/42/435/450 are present and byte-identical to the server's DBC.

The server only has Normal:

- `dungeon_access_template` holds one row for map 309 (id 20, difficulty 0, level 50). There are no 1xxxxx, 2xxxxx
  or 3xxxxx creature templates, every `difficulty_entry_1..3` is 0 and every spawn is `spawnMask` 1, so Heroic,
  Mythic and Ascended cannot be entered.
- Boss health in `coa_boss_flex` is "built, not measured" and runs above the one live clear on record.
- Several boss timers differ from that clear, and some boss, add and trash spells cast live are missing.
- Hakkar's Normal loot lacks the raid cache, the Offering Key and the sigil. Quest reputation, 57 quests and 27
  Zandalar vendor items are missing or wrong.

## 2. Evidence

| tag | source | what it holds for ZG |
|---|---|---|
| **log** | CoA combat log `2026-08-02-18.28.55 WoWCombatLog.txt` (db.exil.es archive, old-logs) | the only full live clear: 12 players, 11 from Hakkar on. No Jin'do, Gahz'ranka, Hazza'rah, Renataki or Wushoolay |
| **wdb** | client caches (AscensionDB, client captures) | creature ranks, HealthModifier, ManaModifier, displays; quests; items |
| **exiles** | db.exil.es export 2026-09-13 | boss kits (spell lists), absolute health, loot |
| **sub** | db.exil.es dump 2026-10-04 | loot per difficulty for all 13 bosses, spawns, quests, vendors |
| **dbc** | installed game client vs `data/dbc` | Map, MapDifficulty, LFGDungeons, DungeonEncounter, Spell, SpellDifficulty: identical |
| **tavern** | coatavern.com | items, spells and achievements only; NPC and quest pages return 404 |
| **descension** | Project Descension (78dcaeeb) | stock ZG scripts; WDB and Exiles staging rows for the Loa Avatars and Heart of Hakkar |
| **video** | YouTube c7iqfz04PmI (launch-day Normal, 7 bosses incl. Hakkar) and 6ihbw1PKc2E (Ascended, 2026-08-04: Arlokk, Thekal, Mar'li wipes) | Zandalar drops, per-kill runes and commendations, avatars in their temples, Mar'li's Ascended Hatch Eggs bar |

A value found only in an archive (exiles, sub, or a lone wdb row that contradicts other sources) needs approval before
it goes into a fix. Health in exiles and sub does not scale consistently against the log (ratios 5.4x-10.2x), so
neither is used as a health target.

## 3. Access and difficulties

| item | server | expected | evidence |
|---|---|---|---|
| `dungeon_access_template` | id 20, difficulty 0, level 50 | difficulties 0-3, level 60 (LFG target 57-60) | dbc |
| variant templates | none | entry + 100000 / 200000 / 300000 for bosses and trash, `difficulty_entry_1..3` | dbc, sub, tavern |
| attunement | none | Ascended requires an attunement begun "by speaking with the appropriate NPC"; NPC and quest unknown | dbc (`Tutorial.dbc` 142) |
| `lfg_dungeon_template` | none | unknown; nothing shows live ZG in RDF | — |
| release gate | `StageZulGurub` 4, dist `ReleaseStage` 3: closed by default | config decision | — |

## 4. Bosses

Measured health per player is net damage taken in the log divided by the group size; flex is assumed linear.

| boss | server `hp_d0` per player | measured per player | timers to retune (script → log) | missing live spells |
|---|---|---|---|---|
| 14517 Jeklik | 497,928 | 370,178 | Mass Fear 48 → 44 s, Greater Heal first 29 → 21 s, Call of Hir'eek first 20 → 22 s | — |
| 14507 Venoxis | 497,928 | 370,221 | Renew 24 → 28 s, Holy Nova 18 → 17 s | — |
| 14510 Mar'li | 497,928 | 370,327 | Web Spray 55 → 45 s, Poison Shock 25 → 45 s | 2118140 Burrow, 2118150 Poison Nova |
| 14509 Thekal | 248,964 | 188,435 | Disrupting Shout → 25.8 s, War Stomp and Speed Slash → 40 s | — |
| 14515 Arlokk | 497,928 | 367,800 | Claw Storm 20 → 55 s | — |
| 11382 Mandokir | 622,364 | 510,568 | Mortal Strike 10 → 12 s | — |
| 14834 Hakkar | 647,307 | 582,793 | Blood Scythe 12 → 15 s, Blood Siphon 90 → 59.5 s first, 79.5 s repeat | 2118607 Pool of Corrupted Blood |
| 15082 Gri'lek | 108,341 | above 133k (not killed at 11) | Ground Slam 13 → 24 s first, 25 s repeat | — |
| 11380 Jin'do, 15114 Gahz'ranka, 15083-15085 | — | no log | unknown | unknown |

All bosses and adds: Fierce Blow 975011 and Knockdown 520871 are cast live and absent on the server (Molten Core
precedent: `rev_20261005_10`/`_11`).

Adds still on stock AzerothCore kits, CoA kits seen in the log:

| entry | add | live kit |
|---|---|---|
| 11347 | Zealot Lor'Khan | 2118260 Greater Heal, 2118261-2118263 Storm Shield, 2118267, 2760204 Holy Ward |
| 11348 | Zealot Zath | 2118250 Sinister Strike, 2118252 Blind, 2118255 Disarm, 2118263, 2760204 |
| 14988 | Ohgan | 2106616 Shred Armor, 2106617 Dash, 570147 (role unknown) |
| 15117 | Chained Spirit | 2118426 Resurrection |
| 14750 | Gurubashi Bat Rider | 350048 Infected Bite in place of 16128 |
| 15041 | Spawn of Mar'li | 2118117 Growth |
| 15101 | Zulian Prowler | 2118350 Prowl, 2118351 Shred, 2118352 Shadowstep |
| 11357 | Son of Hakkar | 2118675 Pool of Poisoned Blood |

Archive-only boss points (approval needed):

- Heart of Hakkar: the log has 92005 (wdb rank 3, model 28887, HM 17.55); the script uses 9780022
  (`boss_hakkar_coa.cpp`), an id that is "Netherstorm Fel Quests" in sub.
- Ohgan rank 1 / display 215271, Spawn of Mar'li display 959, Powerful Healing Ward named "Healing Stream Totem"
  (wdb).
- Exiles-only spells never cast in the log: 2106125 Bat-tering Charge, Venoxis 2118081, 2118085, 2118045.

## 5. Trash and spawns

HealthModifier matches wdb on every trash entry and stays. Live kits from the log (all ids present in the client and
server Spell.dbc):

| entry | trash | change |
|---|---|---|
| 11338 | Hakkari Shadowcaster | 15232 → 350383, 20741 → 350386 |
| 11350 | Gurubashi Axe Thrower | add 2118900, 2118901, 2118905; 8269 → 340021 |
| 11351 | Gurubashi Headhunter | 15708 → 340009 |
| 11352 | Gurubashi Berserker | 15588 → 340080, 11130 → 340164, 8269 → 340021; add 2118910 |
| 11359 | Soulflayer | 8269 → 340021 |
| 11361, 15068 | Zulian Tiger, Zulian Guardian | no AI: add 24332 Rake, 24333 Ravage |
| 11368 | Bloodseeker Bat | add 2106151 Vampiric Bite, 2106156 Frenzied Dive |
| 11373, 14884 | Razzashi Cobra, Parasitic Serpent | 24097 → 2118075 |
| 11830 | Hakkari Priest | 22883 → 85309 |
| 14532 | Razzashi Venombrood | add 2118914 |
| 14821 | Razzashi Raptor | 8599 → 340031, 24339 → 350048 |
| 15043 | Zulian Crocolisk | 13445 → 340516 |
| 15111 | Mad Servant | 24611 → 350395, 24612 → 350399 |

Fierce Blow 975011 and Berserking 1126297 are cast by almost every trash type live.

wdb corrections: ManaModifier 11339, 11340, 11830, 11831, 14825 → 1.35; 11388 → 0.3375; 14883, 15111 → 0.65.
14826 Sacrificed Troll display 14391 → 27651.

Spawns: server 927, sub 807, 792 guids shared. The gap is AzerothCore pools and random-entry rolls, not extra
creatures. Open, archive-only: entry swaps on 51391 (→ 11338), 51389, 51392, 51394, 91457, 49139, 49195-49197;
sub-only guid 200616 Hakkari Priest; possible stacked duplicates 49149 and 52265-52271. The 37 gameobject templates
match sub.

## 6. Loot, items, reputation, quests, vendors

Tier item ids are confirmed by wdb and tavern: Heroic base + 300000, Mythic base + 1300000, Ascended base + 200000.
All 520 item ids that sub lists in ZG boss loot exist in `item_template`.

| item | server | expected | evidence |
|---|---|---|---|
| Hakkar Normal | no cache, key or sigil | 1400023 Cache of the Blood God 100 %, 97725 Offering Key 100 %, 60108 sigil 1 % | wdb, exiles, sub |
| boss sigils (13) | absent | 1 % each | exiles, sub |
| Edge of Madness blood items 19939-19942 | 20 % | 100 % | sub, TBC data |
| variant loot | unreachable | tiered ids per difficulty | sub only |
| Hakkar caches per tier | — | Heroic 1400039, Mythic 2400039, Ascended 2400039 (sub) or 2500039 (tavern, server item) | uncertain |
| quest reputation, 81 ZG quests | `RewardFactionOverride` → +100/150/200 | override 0 → +250/350/500 | wdb, exiles |
| MinLevel 8048, 8184-8192, 9208-9210 / 8183 | 58 / 58 | 10 / 60 | wdb, sub |
| missing quests | — | Zanza 1508184-1508189, [HEROIC] Paragons 208053-208079, Heart of Hakkar 208183/308183/408183, Inscriptions 208184-208198, Hero's Call 77878 | wdb, questcache; givers unknown |
| Rin'wosho 14921 | 22 items | plus 27 reputation-gated CoA items 195065-195097 | wdb, sub |

Both videos show Zandalar pieces dropping from bosses (Thekal: Zandalar Augur's Hauberk; Arlokk: Zandalar
Freethinker's Armguards), so the sub chances of 3.333 % on the priests, Mandokir and Jin'do are used. Every boss
kill in the Normal video gives each player Runes of Ascension and Raider's Commendations (2 per boss, 6 from Hakkar).
The video shows 175 runes per boss and 2500 from Hakkar; that exceeds a loot row's count (255), so the runes follow
Molten Core: one per boss. The Hakkar kill shows no Cache of the Blood God; the cache 1400023 stays by decision.

Archive-only loot (approval needed): Battleweaver pieces as boss drops (sub only), 0 %-chance CoA pieces on bosses
and 43 trash greens, Edge 12504, Gahz'ranka 12503 and 1022739, Dungeon Spoils 2021814 / 1202039 / 1027965 (sub; the
Hakkar video shows Dungeon Spoils).

Left as is unless decided otherwise: quests 580290 and 580295 carry local Path to Ascension titles and MinLevel 8.

## 7. Changes on this branch

| change | migration or file | evidence |
|---|---|---|
| Heart of Hakkar is 92005 (rank 3, model 28887, HM 17.55, MM 1.755, faction 28); 9780022 stays an unused template | `rev_20261025_80`, `boss_hakkar_coa.cpp` | log, wdb |
| rank 1 on 11360, 11368, 11387-11391, 14826 (not trigger 14758); ManaModifier corrections; 14826 display 27651; guid 51391 → 11338 | `rev_20261025_81` | wdb, sub |
| Hakkar Normal: 1400023 Cache of the Blood God 100 %, 97725 Offering Key 100 %; 13 boss sigils 1 %; Edge of Madness blood items 100 % | `rev_20261025_82` | wdb, exiles, sub |
| access rows for difficulties 0-3 at level 60; every map-309 spawn on `spawnMask` 15 | `rev_20261025_83` | dbc |
| Heroic, Mythic and Ascended templates for 61 families at +100000/+200000/+300000, health and melee damage ×1.44/×1.88/×2.32, `coa_boss_flex` hp_d1..d3 on the same ladder | `rev_20261025_84` | wdb (Hakkar, Mar'li, Arlokk, Bloodseeker Bat), Molten Core precedent |
| own loot ids for 39 boss variants, 642 rows; Hakkar caches 1400039 / 2400039 / 2500039; no Battleweaver pieces | `rev_20261025_85` | sub |
| the 27 Zandalar pieces at 3.333 % on the priests, Mandokir and Jin'do, each tier with its own item ids; Rune of Ascension 375250 ×1 and Raider's Commendation 400750 ×2 (Hakkar ×6) at 100 % on all 13 bosses and their variants | `rev_20261025_93` | video, sub, Molten Core ids |
| quest reputation from the faction reward index (+250/+350/+500); MinLevel 10 and 60 | `rev_20261025_86` | wdb, exiles |
| Rin'wosho 14921 sells the 27 CoA reputation items | `rev_20261025_87` | wdb, sub |
| trash kits from the log; Fierce Blow 975011 and Berserking 1126297; SmartAI on 11361, 11387, 14880, 15068 | `rev_20261025_88` | log |
| boss timers from the log, Mar'li's Burrow and Poison Nova, Fierce Blow on bosses and adds; zealot, Ohgan, Chained Spirit, Bat Rider, Spawn of Mar'li and Zulian Prowler kits | `modules/mod-coa-raid-difficulty/src/*_coa.cpp`, stock `ZulGurub/*.cpp`, `rev_20261025_89` | log |
| Loa Avatars 666988-666992 (faction 35, level 63): each avatar is a passive spawn in its priest's temple (guids 9999801-9999805), respawned at every reset and pull if a past pull drained it; at 50 % the priest drains it with Drain Power (-99 % damage taken) until it dies, then gains the Gift of the Blood God and its second kit; Hakkar drains the avatar of every living priest at the pull and gains that Aspect when it dies | `rev_20261025_90`, `zg_coa_common.h` (`LoaAvatar`), the five priests, `boss_hakkar_coa.cpp` | wdb, log, dbc, video |
| Mar'li: on Ascended, Hatch Eggs repeats every 30 s in the troll phase | `boss_marli_coa.cpp` | video (DBM bar) |
| Thekal: no false death, no zealot revival, no tiger phase at full health; tiger form when the avatar dies | `boss_thekal_coa.cpp` | log |
| boss achievements per difficulty: Normal, Heroic, Mythic and Ascended criteria get `achievement_criteria_data` scripts that match the exact difficulty | `rev_20261025_91`, `AscensionAchievementConditions.cpp` | dbc |
| Mandokir: Threatening Gaze 4 s, then Menacing Gaze 4 s; a hostile spell with a power cost on the global cooldown gives Sentenced to Die and Decapitate; Mounted out of combat; Bloodlord's Presence (no durability loss) at the pull | `boss_mandokir_coa.cpp` | dbc |
| Jin'do: the Brain Wash Totem casts Brainwash 2118502; the Powerful Healing Ward casts Healing Stream 2118504 (1 % of missing health per second) and loses its stock heal and melee | `boss_jindo_coa.cpp`, `rev_20261025_92` | dbc, wdb (ward named "Healing Stream Totem") |

Normal boss health is unchanged. Knockdown 520871 is not added: it is a player ability, and the bosses are immune
to it in the log.

## 8. Still open

1. Normal health: the measured per-player values above, from one 11-12 player clear, are not applied.
2. Ascended attunement: `Tutorial.dbc` 142 says Ascended needs an attunement begun at an NPC. Neither the NPC nor
   the quest is in any source, so Ascended opens without one; no NPC is invented.
3. Missing quests: their givers are unknown.
4. Dungeon Spoils are left out (archive-only ids); rune counts follow Molten Core, not the video's 175 / 2500.
5. The Mythic Heart of Hakkar 1319802 is inferred from the tier offset; the dump has no Mythic row.
6. Trash variants keep the Normal loot id; Edge of Madness variants use the sub 11.111 % chances.
7. DamageModifier follows the health ladder as in Molten Core; no log measures variant melee damage.
8. The logs carry no timings for trash abilities and Berserking: the Molten Core windows are used.
9. Archive-only spawn swaps other than 51391, the sub-only Hakkari Priest and the possible stacked duplicates.
10. Mar'li's Burrow lasts an estimated 3 s; Storm Shield stays on Lor'Khan, although the log mostly shows it on Zath;
    2118267 "Storm Shield - Extra" and Shred's Razor Claws part are not scripted.
11. Estimated, not in any data: the avatars' level 63, faction 35 and position (the temple spots, a 10 yd
    ring around Hakkar); the order drain → death → Gift and Aspect; Mandokir's gaze order and Bloodlord's Presence once
    at the pull; which totem casts which spell; exact-difficulty achievement credit (no credit for a lower
    difficulty).
12. Left out for lack of data: Realm of the Blood God 2118425 (its phase 4 content is missing), Mounted 2118411 on
    Ohgan, Jin'do's Seeking Shadow Bolts 2118550-2118556 and Rise 2118561, Hakkar's Dormant Heart 2118651, Animate
    Blood 2118640/2118641, Rain of Blood 2118642 and the meteor split 2118646.
