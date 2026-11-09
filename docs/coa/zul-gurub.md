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
| **log** | CoA combat log `2026-08-02-18.28.55 WoWCombatLog.txt` (db.exil.es archive, old-logs) | the longest live run: 11 players, 10 from Gri'lek on. No Jin'do, Hakkar, Gahz'ranka, Hazza'rah, Renataki or Wushoolay |
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
| 15082 Gri'lek | 318,182 (tester video, `rev_20261104_05`) | above 133k (not killed at 11); 3.5 million at 11 in the tester's video | Ground Slam 13 → 24 s first, 25 s repeat | — |
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
- Ohgan rank 1, Spawn of Mar'li display 959, Powerful Healing Ward named "Healing Stream Totem" (wdb). Ohgan's
  display 215271 is applied (section 7).
- Exiles-only spells never cast in the logs: Venoxis 2118081, 2118085, 2118045. Jeklik casts 2106125 Bat-tering
  Charge every 20 s in `2026-08-02-19.50.33`.

## 5. Trash and spawns

HealthModifier matches wdb on every trash entry and stays. Live kits from the log (all ids present in the client and
server Spell.dbc):

| entry | trash | change |
|---|---|---|
| 11338 | Hakkari Shadowcaster | 15232 → 350383, 20741 → 350386 |
| 11350 | Gurubashi Axe Thrower | add 2118900, 2118901, 2118905; 8269 → 340021 |
| 11351 | Gurubashi Headhunter | 15708 → 340009 |
| 11352 | Gurubashi Berserker | 15588 → 340080, 11130 → 340164, 8269 → 340021; Trauma 2118910 on every Thunderclap hit |
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
kill in the Normal video gives each player 175 Runes of Ascension and 2 Raider's Commendations; Hakkar gives 2500
runes, 6 commendations and Dungeon Spoils. 2500 exceeds a loot row's 8-bit count, so Hakkar's script hands those
runes to every player who tapped him. The variants take the Normal amounts. Dungeon Spoils on Hakkar: 2021814 on
Normal (video) and Ascended (as Ragnaros), Heroic 1202039 and Mythic 1027965 (sub). The Hakkar kill shows no Cache
of the Blood God, so Normal Hakkar drops none (user decision 2026-11-04); the higher tiers keep theirs.

Archive-only loot (approval needed): Battleweaver pieces as boss drops (sub only), 0 %-chance CoA pieces on bosses
and 43 trash greens, Edge 12504, Gahz'ranka 12503 and 1022739.

Left as is unless decided otherwise: quests 580290 and 580295 carry local Path to Ascension titles and MinLevel 8.

## 7. Changes on this branch

| change | migration or file | evidence |
|---|---|---|
| Heart of Hakkar is 92005 (rank 3, model 28887, HM 17.55, MM 1.755, faction 28); 9780022 stays an unused template | `rev_20261025_80`, `boss_hakkar_coa.cpp` | log, wdb |
| rank 1 on 11360, 11368, 11387-11391, 14826 (not trigger 14758); ManaModifier corrections; 14826 display 27651; guid 51391 → 11338 | `rev_20261025_81` | wdb, sub |
| Hakkar Normal: 97725 Offering Key 100 %, Cache of the Blood God 1400023 100 %; 13 boss sigils 1 %; Edge of Madness blood items 100 % | `rev_20261025_82` | wdb, exiles, sub |
| access rows for difficulties 0-3 at level 60; every map-309 spawn on `spawnMask` 15 | `rev_20261025_83` | dbc |
| Heroic, Mythic and Ascended templates for 61 families at +100000/+200000/+300000, health and melee damage ×1.44/×1.88/×2.32, `coa_boss_flex` hp_d1..d3 on the same ladder | `rev_20261025_84` | wdb (Hakkar, Mar'li, Arlokk, Bloodseeker Bat), Molten Core precedent |
| own loot ids for 39 boss variants, 642 rows; Hakkar caches 1400039 / 2400039 / 2500039; no Battleweaver pieces | `rev_20261025_85` | sub |
| the 27 Zandalar pieces at 3.333 % on the priests, Mandokir and Jin'do, each tier with its own item ids; Rune of Ascension 375250 ×175 and Raider's Commendation 400750 ×2 at 100 % on all 13 bosses and their variants; Hakkar ×6 commendations, Dungeon Spoils, and 2500 runes from his script | `rev_20261025_93`, `boss_hakkar_coa.cpp` | video, sub, Molten Core ids |
| quest reputation from the faction reward index (+250/+350/+500); MinLevel 10 and 60 | `rev_20261025_86` | wdb, exiles |
| Rin'wosho 14921 sells the 27 CoA reputation items | `rev_20261025_87` | wdb, sub |
| trash kits from the log; Fierce Blow 975011 and Berserking 1126297; SmartAI on 11361, 11387, 14880, 15068 | `rev_20261025_88` | log |
| boss timers from the log, Mar'li's Burrow and Poison Nova, Fierce Blow on bosses and adds; zealot, Ohgan, Chained Spirit, Bat Rider, Spawn of Mar'li and Zulian Prowler kits | `modules/mod-coa-raid-difficulty/src/*_coa.cpp`, stock `ZulGurub/*.cpp`, `rev_20261025_89` | log |
| Loa Avatars 666988-666992 (faction 35, level 63): each avatar is a passive spawn in its priest's temple (guids 9999801-9999805), respawned at every reset and pull if a past pull drained it; at 50 % the priest drains it with Drain Power (-99 % damage taken) until it dies, then gains the Gift of the Blood God and its second kit; Hakkar drains the avatar of every living priest at the pull and gains that Aspect when it dies | `rev_20261025_90`, `zg_coa_common.h` (`LoaAvatar`), the five priests, `boss_hakkar_coa.cpp` | wdb, log, dbc, video |
| Mar'li: Hatch Eggs at 17 s and every 30 s, in both forms and on every difficulty; Poison Bolt Volley in both forms | `boss_marli_coa.cpp` | video (DBM bar), tester |
| Thekal: no false death, no zealot revival, no tiger phase at full health; tiger form when the avatar dies; Rip comes only from Speed Slash cuts, and Speed Slash ends after 17 s | `boss_thekal_coa.cpp` | log, tester |
| boss achievements per difficulty: Normal, Heroic, Mythic and Ascended criteria get `achievement_criteria_data` scripts that match the exact difficulty | `rev_20261025_91`, `AscensionAchievementConditions.cpp` | dbc |
| Mandokir: Threatening Gaze 4 s, then Menacing Gaze 4 s; a hostile spell with a power cost on the global cooldown gives Sentenced to Die and Decapitate; Mounted out of combat; Bloodlord's Presence (no durability loss) at the pull; Whirlwind as each Berserker Charge lands, in the charge's place when nobody is out of melee (see the 2026-11-04 row) | `boss_mandokir_coa.cpp` | dbc, log |
| Gurubashi Berserker: Trauma lands with every Thunderclap hit, never as a cast of its own | `rev_20261102_93` | log |
| Edge of Madness: the Brazier of Madness has no lock (Gurubashi Mojo Madness not needed) and always summons Gri'lek; the encounter credits Gri'lek | `rev_20261102_94` | wdb, log |
| Jin'do: the Brain Wash Totem casts Brainwash 2118502; the Powerful Healing Ward casts Healing Stream 2118504 (1 % of missing health per second) and loses its stock heal and melee | `boss_jindo_coa.cpp`, `rev_20261025_92` | dbc, wdb (ward named "Healing Stream Totem") |
| tester feedback of 2026-11-03 with Pigeon's spell review: Poisonous Fangs, Furious Strikes, Shredding Claws and Razor Claws proc on melee hits, the snakes' Fangs stack Venoxis's own Virulent Poison while he fights; Gri'lek's Trauma has difficulty spells; Venoxis's and Hakkar's pools vanish on reset and death; Hakkar summons one Son per wave; Jin'do's shades despawn on his death and Banish lands on the pit floor; Mandokir's Mortal Strike needs melee range and his charge keeps threat; the Chained Spirit's resurrection leaves no resurrection timer; Bat Riders can be stunned and die by their Unstable Concoction; Arlokk takes panther form at 50 % for the rest of the fight; Spawn of Mar'li and Zulian Prowlers are elite, Parasitic Serpents level 60 | `rev_20261103_91`, the boss scripts, `boss_jeklik.cpp`, `SpellInfoCorrections.cpp` | tester, live log, dbc |
| tester answers checked against the live logs of 2025-12 to 2026-08: Jeklik's Terrifying Screech fears (2106137) everyone within 20 yards; Mar'li's Web Spray is cast at her victim, so its 20-yard webs land (35 yards since 2026-11-08); the Heart of Hakkar takes the damage it passes to Hakkar, and the siphon ends when it breaks | `boss_jeklik_coa.cpp`, `boss_marli_coa.cpp`, `boss_hakkar_coa.cpp` | tester, live log, dbc |
| tester feedback of 2026-11-04 checked against the live logs: Thekal's War Stomp 2118227 hits his target 12 s into tiger form and every 40 s, Speed Slash picks a new target every 2 s; three Parasitic Serpents 14884 break out when Venoxis's Parasitic Poison 2118041 ends or is dispelled; Arlokk vanishes (2118312) when she becomes a panther, Shadowsteps to a Ravage 11 s later and every 55 s, Claw Storm 18 s and Vanish 26 s after each Ravage (44 s since 2026-11-08), Claw Storm does not apply Razor Claws (it does since 2026-11-08), and her bleeds end with her death or with the bleeding player's death (the DBC keeps Razor Claws 2118326-2118329 through death, so a battle-resurrected player bled out again); Jin'do casts no Hex or Banish, his totems lose one health per hit (Brain Wash Totem 5, ward 15 or 25 above Normal), three Brain Wash Totems (five above Normal) at 16 s, the ward at 21 s and Animate Bones at 23 s, each on a 60/60/30 s cycle, the Blood Pit starts empty and the risen trolls use Fierce Blow; Will of Hakkar only on Mythic and Ascended, at 45 s; the heart floats 8 yd up with model 428001 at scale 2; a Son of Hakkar leaves its pool only where it dies; overlapping Pools of Corrupted Blood hurt like one; Ohgan's abilities start whoever pulls him | the boss scripts, stock `boss_mandokir.cpp`, `rev_20261104_00`, `rev_20261104_01` | tester, live log, dbc |
| Mar'li comes up from Burrow on the player farthest from her and stays on them for 8 s, untauntable, whatever threat the tank holds; the hunted player carries Menacing Gaze 2118141 meanwhile | `boss_marli_coa.cpp` | tester 2026-11-04, user decision |
| the Cache of the Blood God (1400023, 1400039, 2400039, 2500039) opens into one of Hakkar's own items for its tier, never the Heart: each has the loot flag, the `item_coa_dungeon_spoils` opener and Hakkar's 14 items in one equal-chance group; before, none had loot | `rev_20261104_00` | tester 2026-11-04 |
| Mar'li's Hatch Eggs marks the ten free eggs nearest the players, and each hatches one Spawn of Mar'li 10 s later; Evolve and Infest take the nearest free egg at once | `boss_marli_coa.cpp` | tester 2026-11-04 |
| Jeklik starts on the ground below her cave (-12273.9, -1407.77, 132.223), where stock landed her, and fights as a troll from the pull without the bat-form descent | `rev_20261104_04`, `boss_jeklik_coa.cpp` | tester and live videos 2026-11-04 |
| Jeklik's Bat-tering Charge 2106125 reaches only players out of melee within 25 yards (stock Jeklik's Charge, 8-25 yd); the DBC's 100 yd let her charge ranged players and healers at 30 yd and more | `boss_jeklik_coa.cpp` | tester 2026-11-04, vanilla 22911 |
| Mandokir: Mortal Strike, Mortal Strike, Berserker Charge, and Whirlwind begun as the charge lands, not on its own timer about a second later; a Mortal Strike due during the Whirlwind follows when it ends | `boss_mandokir_coa.cpp` | tester video 2026-11-04, live log 2026-08-02 |
| Gri'lek 15082 has 318,182 health per player on Normal (458,182, 598,182 and 738,182 above), from the tester's video of 3.5 million at 11 players; it was 108,341, about 1.19 million at 11 | `rev_20261104_05` | tester video 2026-11-04, user decision |
| Ohgan (14988 and its tiers) uses display 215271, model 15271 at a client scale of 2, with its own model info (bounding radius 0.7, combat reach 3); he runs in from the arena entrance when Mandokir is pulled instead of appearing at his side | `rev_20261104_03`, `boss_mandokir_coa.cpp` | wdb, dbc, tester 2026-11-04, user decision |
| tester feedback of 2026-11-08 checked against the live logs: Jeklik's Terrifying Screech comes the moment her charge stuns (12 of 12 landed charges), or in its place when nobody is in reach, not on its own timer; each Parasitic Serpent hunts a different player from Venoxis's threat list; serpents have 979 and Spawn of Mar'li 3,304 health per player on the ZG ladder; Gri'lek's Ground Slam is cast at his victim and his melee is calibrated to the live median hit (DamageModifier 85.7 / 123.4 / 161.1 / 198.8); Mar'li's Web Spray webs everyone in sight within 35 yards and she is hidden (display 22452) while burrowed; Mandokir cannot be attacked or selected on his ledge, charges a random player out of melee and rides Ohgan's double-size display 215271; Thekal's tiger form starts War Stomp's 2 s cast at 1 s and Speed Slash as it ends (3 s), Speed Slash keeps his threat list and every cut applies Rip; Arlokk Ravages her highest-threat target, a Claw Storm hit applies Razor Claws with an 8% chance (live: 34 of 452 hits) and Vanish follows 44 s after each Ravage; the Shade of Jin'do 14986 never melees and casts Seeking Shadow Bolts (2118556, a Seeking Shadow Bolt on every player every 4 s) until it dies; Hakkar can be taunted (CreatureImmunitiesId -273); the side Sons of Hakkar 49033/49034 respawn after 2 h; the Jinxed Hoodoo Pile's trap 180244 no longer summons the Gurubashi who casts Will of Hakkar | the boss scripts, `rev_20261108_02` | tester, live log, dbc, user decision |

Normal boss health is unchanged except Gri'lek's. Knockdown 520871 is not added: it is a player ability, and the bosses are immune
to it in the log.

## 8. Still open

1. Normal health: the measured per-player values above, from one 11-12 player clear, are not applied.
2. Ascended attunement: `Tutorial.dbc` 142 says Ascended needs an attunement begun at an NPC. Neither the NPC nor
   the quest is in any source, so Ascended opens without one; no NPC is invented.
3. Missing quests: their givers are unknown.
4. Rune, commendation and Dungeon Spoils amounts on Heroic, Mythic and Ascended copy Normal; Ascended Dungeon
   Spoils is 2021814 as on Ragnaros. Only the Normal video shows them.
5. The Mythic Heart of Hakkar 1319802 is inferred from the tier offset; the dump has no Mythic row.
6. Trash variants keep the Normal loot id; Edge of Madness variants use the sub 11.111 % chances.
7. DamageModifier follows the health ladder as in Molten Core; no log measures variant melee damage.
8. The logs carry no timings for trash abilities and Berserking: the Molten Core windows are used.
9. Archive-only spawn swaps other than 51391, the sub-only Hakkari Priest and the possible stacked duplicates.
10. Mar'li's Burrow lasts an estimated 3 s, and the gaze aura on her hunted player is chosen here (no log shows
    it); Storm Shield stays on Lor'Khan, although the log mostly shows it on Zath; 2118267 "Storm Shield - Extra" and Shred's Razor Claws part are not scripted.
11. Estimated, not in any data: the avatars' level 63, faction 35 and position (the temple spots, a 10 yd
    ring around Hakkar); Ohgan's arena entrance (-12274.7, -1913.96), the gap in the chained spirits' ring on
    the north-west side; the order drain → death → Gift and Aspect; Mandokir's gaze order and Bloodlord's Presence once
    at the pull; which totem casts which spell; exact-difficulty achievement credit (no credit for a lower
    difficulty).
12. Left out for lack of data: Realm of the Blood God 2118425 (its phase 4 content is missing), Mounted 2118411 on
    Ohgan, Jin'do's Rise 2118561 (his shades cast Seeking Shadow Bolts since 2026-11-08), Hakkar's Dormant Heart 2118651, Animate
    Blood 2118640/2118641, Rain of Blood 2118642 and the meteor split 2118646.
13. Tester questions of 2026-11-04 that await a decision: Sons of Hakkar loot, the shades' area damage and
    Mandokir's items. Jinxed Hoodoo's Will of Hakkar was removed on 2026-11-08 (user decision). Decided without a change here: the Blood Orb is skipped, and
    the battle resurrection limit gets its own change. Estimated: Jeklik's facing on the ground, and the 100 yd
    reach of Mar'li's egg search.
14. Checked only in game: the number and paths of the risen trolls and the totem positions.
15. Tester remarks of 2026-11-04 without a change:
    - Mandokir's Whirlwind "feels short": its 3 s cast and 6 s spin match the DBC and the live log, and a scenario
      checks the full 6 s.
    - Frenzy 2106613 at 65 % attack speed on Normal and Heroic, with extra damage on Mythic and Ascended: the
      server DBC, the client DBC, the Exiles DB and the SUB dump all give 30 % haste and 30 % more damage taken,
      with no tier variant. In the live log of 2026-08-02 his median swing drops from 2.47 s to 1.80 s under
      Frenzy, about 1.4 times faster, not the 1.65 of 65 %. Kept at 30 % (user decision, 2026-11-04).
    - Jin'do's shades taking no area damage may come from one class's ability; the tester retests it.
16. Tester feedback of 2026-11-08:
    - Not changed, the live logs disagree: Thekal's Frenzy every 90 s, Mandokir charging only ranged players, a
      bleed from Ohgan, Gri'lek's damage rising over the fight, Arlokk's melee bleeding everyone, a 30 s Arlokk
      cycle, and Hakkar's click box (the client model, identical on live). Hakkar's Dungeon Spoils already drop
      (§6).
    - No source yet: raid revive checkpoints, and the distance of Jin'do's totems.
    - Gri'lek's melee: the live logs carry no armor, so the calibrated DamageModifier is a floor. The server's mean
      hit before armor with his avatar was 4,598; the live median hit is 17,520.
