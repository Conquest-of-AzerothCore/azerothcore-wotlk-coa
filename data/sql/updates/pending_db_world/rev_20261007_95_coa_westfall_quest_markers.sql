-- CoA Westfall: world-map markers for the quests the Westfall restore brought back (#6774).
--
-- rev_20261004_10_coa_westfall_restore.sql (PR #6430, commit 64188b255) restored seventeen Westfall
-- quests - quest_template, quest_template_addon, creature/gameobject quest starters and enders, their
-- NPCs and objects and the smart scripts behind them - but it wrote no `quest_poi` / `quest_poi_points`
-- rows at all. Those two tables are the whole world-map marker system: ObjectMgr::LoadQuestPOI
-- (src/server/game/Globals/ObjectMgr.cpp:8549) loads them, QueryHandler (CMSG_QUEST_POI_QUERY) sends
-- them for the quests in the player's log, and QuestPOI.Enabled (= 1 in worldserver.conf) has to be on.
-- With no rows a carried quest draws no pin and no search area, which is exactly what issue #6774
-- reports for Militia Training (255057), The Missing Report (999913), Wanted: Lenore the Hoarder
-- (254042), Potions for Sentinel Hill (1313) and The Killing Fields (17014) - the quests work, the map
-- (M) is simply blank. The other twelve restored quests (17009, 17011, 17012, 26993, 26994, 26995,
-- 26996, 26997, 254043, 999914, 999933, 100466) were in the same state and are covered here too.
--
-- Every quest gets both halves of a marker: the objective (the target the quest sends the player to) and
-- the turn-in (the NPC or object the quest is handed back to), so a player sees where to go when the
-- quest is taken and where to return once it is done.
--
-- CONVENTIONS (the layout rev_20260924_60_coa_quest_markers.sql documents from stock data, and the one
-- rev_20261007_80_coa_northshire_class_objective_markers.sql follows)
--   ObjectiveIndex  -1 is the turn-in pin; 0-3 are the RequiredNpcOrGo slots 1-4 (a creature or object
--     objective); item objectives use 3 + slot, so RequiredItemId1 is 4, RequiredItemId2 is 5 and
--     RequiredItemId3 is 6. Stock 9 'The Killing Fields' carries 0-3 plus its turn-in -1, stock 12/13
--     'The People's Militia' carries 0 and 1, stock 22 'Goretusk Liver Pie' puts its six litters on 4,
--     and stock 38 'Westfall Stew' puts its four reagents on 4, 5, 6 and 7.
--   MapID 0 is the Eastern Kingdoms, Floor 0 and Priority 0 are the stock values, Flags 1 is the
--     ordinary marker flag, VerifiedBuild is left to its default as every sibling marker file does.
--   WorldMapAreaId 39 is the Westfall map area: every stock Westfall quest's own rows use it (9, 12, 13,
--     14, 22, 36, 38, 64, 104, 117, 132), so a marker written on it lands on the map the client already
--     draws for the zone. The one exception is 100466 below, whose objective sits in Stormwind City and
--     therefore uses 301, the value the stock rows for the city's flight master carry (quests 90, 120
--     121 and 6261 at -8954 521 / -8822 518 / -8836 490).
--   A four-corner rectangle paints a blue search area over the ground the objective lives on; a single
--     point is the pin stock uses for one unique target (104, 64) and for every turn-in (9, 12, 36).
--   `id` is only the row's own key within the quest, so the objective rows number up from 0 and the
--     turn-in takes the next free id; the client tells markers apart by ObjectiveIndex.
--
-- WHERE THE POINTS COME FROM
--   targets  SOURCED-CORE: the spawns the restore itself places, or the stock creature spawns for the
--     species the quest_template row asks for (RequiredNpcOrGo). Each rectangle below is the bounding
--     box of the actual spawn cluster in acore_world, rounded out to the nearest 5 yd, so it covers the
--     camp the quest text names and not the whole zone. Where a species stands in several separated
--     camps, each camp gets its own row on the same ObjectiveIndex (stock does the same for the six
--     Goretusk areas of quest 22).
--   turn-ins  SOURCED-CORE: the ender's spawn after the restore - creature_questender /
--     gameobject_questender - not the giver, so 26994's pin is on Saldean and 999914's on Archivist
--     Selnor, the way the quest is actually completed.
--
-- THE QUESTS (target -> return)
--   1313 Potions for Sentinel Hill   items 480201/480202/480203 -> Idona Wyther 255150 (-10511 1147).
--     The three crates are gameobjects 9001100/9001101/9001102 at -10723 1391 (Defias camp), -9999
--     1470 and -9845 1036, each given its own item slot 4, 5 and 6, so the map shows three camp areas.
--   17009 Sunken Treasure            no RequiredNpcOrGo/RequiredItem slot (the waterlogged trunk is
--     the ender, gameobject 96005 at -9784 1819), so it carries the turn-in pin alone - the pin is both
--     the goal and the return, like stock 36 'Westfall Stew' and 109 'Report to Gryan Stoutmantle',
--     which also carry only one -1 row.
--   17011 Riverpaw Genocide          Riverpaw Brute 124, Mongrel 123, Herbalist 501 (slots 0, 1, 2)
--     -> Farmer Demont 157002 (-11138 1818). Brutes: the north camp at -11110..-10970 1855..1960, the
--     mid-west group at -10885..-10810 1145..1345 and the south-west pair at -11110..-11040
--     740..1015. Mongrels: the coast band at -11100..-10510 1905..2020, the eastern group at
--     -10200..-10000 1640..1880 and the pair south-west of the camp at -10860..-10810 1750..1790.
--     Herbalists: the coast band at -11125..-10540 1860..2000 and the one at the camp's south edge,
--     -10860..-10810 1750..1790.
--   17012 Riverpaw Genocide          Riverpaw Bandit 452, Taskmaster 98, Mystic 453 (slots 0, 1, 2)
--     -> Farmer Demont 157002. Bandits: the Riverpaw camp at -11165..-11010 748..1070 and the second
--     group at -10885..-10805 1110..1350. Taskmasters and Mystics share the camp at -11220..-10975
--     675..1050 and -11215..-11090 705..900.
--   17014 The Killing Fields         Harvest Reaper 115 x15 (slot 0) -> Farmer Saldean 233
--     (-10129 1055). Reapers stand in the Dead Acre at -10855..-10740 710..890.
--   26993 The Killing Fields         Rusty Harvest Golem 480 x10 (slot 0) -> Farmer Furlbrow 237
--     (-9852 918). Golems: the Jansen Stead group at -10000..-9955 1075..1155 and the pumpkin-farm
--     group at -9900..-9785 945..1040.
--   26994 The Killing Fields         no objective (speak to Saldean); its one pin is Saldean 233.
--   26995 The Killing Fields         Harvest Golem 36 x10 (slot 0) -> Farmer Saldean 233. Four camps:
--     the Molsen Farm at -11020..-10930 1345..1395, the two northern farms at -10525..-10220
--     1745..1890, Saldean's own farm at -10255..-10185 1000..1055 and the road group at
--     -10200..-10145 1245..1350.
--   26996 The Killing Fields         Harvest Watcher 114 x10 (slot 0) -> Farmer Saldean 233. Four
--     groups: -10685..-10510 1585..1757, -10290..-10170 1370..1515, -10225..-10110 1080..1195 and
--     -9985..-9865 1157..1275.
--   26997 The Killing Fields         Harvest Reaper 115 x10 (slot 0) -> Farmer Saldean 233, the same
--     Dead Acre area as 17014.
--   254042 Wanted: Lenore the Hoarder  Lenore the Hoarder 991515 x1 (slot 0, one unique NPC)
--     -> Protector Gariel 490 (-10634 1181, where the restore moves her). The pin on Lenore is her spawn
--     in the Defias tower's upper floor, -10266 1782, above the Westfall Hoard the same quest's
--     follow-up loots.
--   254043 Take It Back              item 1252801 Westfall Supplies (slot 4, one object) -> Protector
--     Gariel 490. The supplies come from the Westfall Hoard, gameobject 9001103 at -10259 1767.
--   255057 Militia Training          Militia Recruits 255339 x6 (slot 0) -> Captain Olens 776786
--     (-10719 980). The recruits are the eight spawns the restore puts in the Sentinel Hill training
--     yard, -10748..-10722 965..1000, and Olens stands in that yard.
--   999913 The Missing Report        no objective slot; the ender is the Slain Protector 455339
--     (-9976 955), so the single pin is both the place the report is found and the place the quest is
--     handed in.
--   999914 The Half-Detailed Report  item 999920 (slot 4) from the Slain Protector 455339 -> Archivist
--     Selnor 776790 (-10679 958).
--   999933 The Spit-Soaked Report    item 999923 (slot 4) from the Half-Devoured Protector 455343
--     (-11030 790) -> Archivist Selnor 776790.
--   100466 Path to Ascension: Westfall  the objective is credit 100467, which the restore grants from
--     Dungar Longdrink's gossip (creature 352, Stormwind flight master at -8836 490), so that row is
--     written on Stormwind's map area 301; the return is Gryan Stoutmantle 234 in Westfall
--     (-10509 1045), the point stock quest 109 already uses for him.
--
-- Idempotent: these quests have no marker rows today (checked on acore_world: no `quest_poi` or
-- `quest_poi_points` row for any of the seventeen ids), so the delete is a no-op on a clean database
-- and re-applying the file replaces its own rows.
--
-- Rollback: DELETE FROM `quest_poi` WHERE `QuestID` IN
--   (1313,17009,17011,17012,17014,254042,254043,255057,26993,26994,26995,26996,26997,999913,999914,999933,100466);
--           DELETE FROM `quest_poi_points` WHERE `QuestID` IN
--   (1313,17009,17011,17012,17014,254042,254043,255057,26993,26994,26995,26996,26997,999913,999914,999933,100466);

DELETE FROM `quest_poi` WHERE `QuestID` IN
  (1313,17009,17011,17012,17014,254042,254043,255057,26993,26994,26995,26996,26997,999913,999914,999933,100466);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`)
VALUES
-- 1313 Potions for Sentinel Hill: one area per stolen crate, then the return to Idona Wyther.
(1313, 0, 4, 0, 39, 0, 0, 1),
(1313, 1, 5, 0, 39, 0, 0, 1),
(1313, 2, 6, 0, 39, 0, 0, 1),
(1313, 3, -1, 0, 39, 0, 0, 1),
-- 17009 Sunken Treasure: no objective slot; the trunk that ends the quest is the whole marker.
(17009, 0, -1, 0, 39, 0, 0, 1),
-- 17011 Riverpaw Genocide: Brutes (0), Mongrels (1), Herbalists (2), then Farmer Demont.
(17011, 0, 0, 0, 39, 0, 0, 1),
(17011, 1, 0, 0, 39, 0, 0, 1),
(17011, 2, 0, 0, 39, 0, 0, 1),
(17011, 3, 1, 0, 39, 0, 0, 1),
(17011, 4, 1, 0, 39, 0, 0, 1),
(17011, 5, 1, 0, 39, 0, 0, 1),
(17011, 6, 2, 0, 39, 0, 0, 1),
(17011, 7, 2, 0, 39, 0, 0, 1),
(17011, 8, -1, 0, 39, 0, 0, 1),
-- 17012 Riverpaw Genocide: Bandits (0), Taskmasters (1), Mystics (2), then Farmer Demont.
(17012, 0, 0, 0, 39, 0, 0, 1),
(17012, 1, 0, 0, 39, 0, 0, 1),
(17012, 2, 1, 0, 39, 0, 0, 1),
(17012, 3, 2, 0, 39, 0, 0, 1),
(17012, 4, -1, 0, 39, 0, 0, 1),
-- 17014 The Killing Fields: the Dead Acre reapers, then Farmer Saldean.
(17014, 0, 0, 0, 39, 0, 0, 1),
(17014, 1, -1, 0, 39, 0, 0, 1),
-- 26993 The Killing Fields: the two Rusty Harvest Golem groups, then Farmer Furlbrow.
(26993, 0, 0, 0, 39, 0, 0, 1),
(26993, 1, 0, 0, 39, 0, 0, 1),
(26993, 2, -1, 0, 39, 0, 0, 1),
-- 26994 The Killing Fields: nothing to kill, only the return to Farmer Saldean.
(26994, 0, -1, 0, 39, 0, 0, 1),
-- 26995 The Killing Fields: four Harvest Golem camps, then Farmer Saldean.
(26995, 0, 0, 0, 39, 0, 0, 1),
(26995, 1, 0, 0, 39, 0, 0, 1),
(26995, 2, 0, 0, 39, 0, 0, 1),
(26995, 3, 0, 0, 39, 0, 0, 1),
(26995, 4, -1, 0, 39, 0, 0, 1),
-- 26996 The Killing Fields: four Harvest Watcher groups, then Farmer Saldean.
(26996, 0, 0, 0, 39, 0, 0, 1),
(26996, 1, 0, 0, 39, 0, 0, 1),
(26996, 2, 0, 0, 39, 0, 0, 1),
(26996, 3, 0, 0, 39, 0, 0, 1),
(26996, 4, -1, 0, 39, 0, 0, 1),
-- 26997 The Killing Fields: the Dead Acre reapers again, then Farmer Saldean.
(26997, 0, 0, 0, 39, 0, 0, 1),
(26997, 1, -1, 0, 39, 0, 0, 1),
-- 254042 Wanted: Lenore the Hoarder: the wanted poster's mark in the Defias tower, then Protector Gariel.
(254042, 0, 0, 0, 39, 0, 0, 1),
(254042, 1, -1, 0, 39, 0, 0, 1),
-- 254043 Take It Back: the Westfall Hoard that holds the supplies, then Protector Gariel.
(254043, 0, 4, 0, 39, 0, 0, 1),
(254043, 1, -1, 0, 39, 0, 0, 1),
-- 255057 Militia Training: the training yard recruits, then Captain Olens.
(255057, 0, 0, 0, 39, 0, 0, 1),
(255057, 1, -1, 0, 39, 0, 0, 1),
-- 999913 The Missing Report: no objective slot; the fallen patroller is both the find and the return.
(999913, 0, -1, 0, 39, 0, 0, 1),
-- 999914 The Half-Detailed Report: the fallen patroller's report, then Archivist Selnor.
(999914, 0, 4, 0, 39, 0, 0, 1),
(999914, 1, -1, 0, 39, 0, 0, 1),
-- 999933 The Spit-Soaked Report: the half-devoured patroller's report, then Archivist Selnor.
(999933, 0, 4, 0, 39, 0, 0, 1),
(999933, 1, -1, 0, 39, 0, 0, 1),
-- 100466 Path to Ascension: Westfall: Dungar Longdrink's credit in Stormwind, then Gryan Stoutmantle.
(100466, 0, 0, 0, 301, 0, 0, 1),
(100466, 1, -1, 0, 39, 0, 0, 1);

DELETE FROM `quest_poi_points` WHERE `QuestID` IN
  (1313,17009,17011,17012,17014,254042,254043,255057,26993,26994,26995,26996,26997,999913,999914,999933,100466);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`)
VALUES
-- 1313: Pilfered Lesser Healing Potions (Defias camp), Pilfered Minor Healing Potions, Pilfered Elixirs.
(1313, 0, 0, -10785, 1330),
(1313, 0, 1, -10665, 1330),
(1313, 0, 2, -10665, 1450),
(1313, 0, 3, -10785, 1450),
(1313, 1, 0, -10060, 1410),
(1313, 1, 1, -9940, 1410),
(1313, 1, 2, -9940, 1530),
(1313, 1, 3, -10060, 1530),
(1313, 2, 0, -9905, 980),
(1313, 2, 1, -9785, 980),
(1313, 2, 2, -9785, 1095),
(1313, 2, 3, -9905, 1095),
(1313, 3, 0, -10511, 1147),
-- 17009: the Waterlogged Trunk itself.
(17009, 0, 0, -9784, 1819),
-- 17011: Riverpaw Brutes (north camp, mid-west group and south-west pair).
(17011, 0, 0, -11110, 1855),
(17011, 0, 1, -10970, 1855),
(17011, 0, 2, -10970, 1960),
(17011, 0, 3, -11110, 1960),
(17011, 1, 0, -10885, 1145),
(17011, 1, 1, -10810, 1145),
(17011, 1, 2, -10810, 1345),
(17011, 1, 3, -10885, 1345),
(17011, 2, 0, -11110, 740),
(17011, 2, 1, -11040, 740),
(17011, 2, 2, -11040, 1015),
(17011, 2, 3, -11110, 1015),
-- 17011: Riverpaw Mongrels (coast band, eastern group and the camp's south edge).
(17011, 3, 0, -11100, 1905),
(17011, 3, 1, -10510, 1905),
(17011, 3, 2, -10510, 2020),
(17011, 3, 3, -11100, 2020),
(17011, 4, 0, -10200, 1640),
(17011, 4, 1, -10000, 1640),
(17011, 4, 2, -10000, 1880),
(17011, 4, 3, -10200, 1880),
(17011, 5, 0, -10860, 1750),
(17011, 5, 1, -10810, 1750),
(17011, 5, 2, -10810, 1790),
(17011, 5, 3, -10860, 1790),
-- 17011: Riverpaw Herbalists (the coast band and the camp's south edge).
(17011, 6, 0, -11125, 1860),
(17011, 6, 1, -10540, 1860),
(17011, 6, 2, -10540, 2000),
(17011, 6, 3, -11125, 2000),
(17011, 7, 0, -10860, 1750),
(17011, 7, 1, -10810, 1750),
(17011, 7, 2, -10810, 1790),
(17011, 7, 3, -10860, 1790),
-- 17011: Farmer Demont.
(17011, 8, 0, -11138, 1818),
-- 17012: Riverpaw Bandits (the camp and the second group).
(17012, 0, 0, -11165, 748),
(17012, 0, 1, -11010, 748),
(17012, 0, 2, -11010, 1070),
(17012, 0, 3, -11165, 1070),
(17012, 1, 0, -10885, 1110),
(17012, 1, 1, -10805, 1110),
(17012, 1, 2, -10805, 1350),
(17012, 1, 3, -10885, 1350),
-- 17012: Riverpaw Taskmasters.
(17012, 2, 0, -11220, 675),
(17012, 2, 1, -10975, 675),
(17012, 2, 2, -10975, 1050),
(17012, 2, 3, -11220, 1050),
-- 17012: Riverpaw Mystics.
(17012, 3, 0, -11215, 705),
(17012, 3, 1, -11090, 705),
(17012, 3, 2, -11090, 900),
(17012, 3, 3, -11215, 900),
-- 17012: Farmer Demont.
(17012, 4, 0, -11138, 1818),
-- 17014: Harvest Reapers in the Dead Acre.
(17014, 0, 0, -10855, 710),
(17014, 0, 1, -10740, 710),
(17014, 0, 2, -10740, 890),
(17014, 0, 3, -10855, 890),
-- 17014: Farmer Saldean.
(17014, 1, 0, -10129, 1055),
-- 26993: Rusty Harvest Golems at the Jansen Stead and the pumpkin farm.
(26993, 0, 0, -10000, 1075),
(26993, 0, 1, -9955, 1075),
(26993, 0, 2, -9955, 1155),
(26993, 0, 3, -10000, 1155),
(26993, 1, 0, -9900, 945),
(26993, 1, 1, -9785, 945),
(26993, 1, 2, -9785, 1040),
(26993, 1, 3, -9900, 1040),
-- 26993: Farmer Furlbrow.
(26993, 2, 0, -9852, 918),
-- 26994: Farmer Saldean.
(26994, 0, 0, -10129, 1055),
-- 26995: Harvest Golems at Molsen Farm and the two northern farms.
(26995, 0, 0, -11020, 1345),
(26995, 0, 1, -10930, 1345),
(26995, 0, 2, -10930, 1395),
(26995, 0, 3, -11020, 1395),
(26995, 1, 0, -10525, 1745),
(26995, 1, 1, -10220, 1745),
(26995, 1, 2, -10220, 1890),
(26995, 1, 3, -10525, 1890),
-- 26995: Harvest Golems on Saldean's farm and along the road.
(26995, 2, 0, -10255, 1000),
(26995, 2, 1, -10185, 1000),
(26995, 2, 2, -10185, 1055),
(26995, 2, 3, -10255, 1055),
(26995, 3, 0, -10200, 1245),
(26995, 3, 1, -10145, 1245),
(26995, 3, 2, -10145, 1350),
(26995, 3, 3, -10200, 1350),
-- 26995: Farmer Saldean.
(26995, 4, 0, -10129, 1055),
-- 26996: Harvest Watchers, four groups.
(26996, 0, 0, -10685, 1585),
(26996, 0, 1, -10510, 1585),
(26996, 0, 2, -10510, 1757),
(26996, 0, 3, -10685, 1757),
(26996, 1, 0, -10290, 1370),
(26996, 1, 1, -10170, 1370),
(26996, 1, 2, -10170, 1515),
(26996, 1, 3, -10290, 1515),
(26996, 2, 0, -10225, 1080),
(26996, 2, 1, -10110, 1080),
(26996, 2, 2, -10110, 1195),
(26996, 2, 3, -10225, 1195),
(26996, 3, 0, -9985, 1157),
(26996, 3, 1, -9865, 1157),
(26996, 3, 2, -9865, 1275),
(26996, 3, 3, -9985, 1275),
-- 26996: Farmer Saldean.
(26996, 4, 0, -10129, 1055),
-- 26997: Harvest Reapers in the Dead Acre.
(26997, 0, 0, -10855, 710),
(26997, 0, 1, -10740, 710),
(26997, 0, 2, -10740, 890),
(26997, 0, 3, -10855, 890),
-- 26997: Farmer Saldean.
(26997, 1, 0, -10129, 1055),
-- 254042: Lenore the Hoarder on the Defias tower's upper floor.
(254042, 0, 0, -10266, 1782),
-- 254042: Protector Gariel.
(254042, 1, 0, -10634, 1181),
-- 254043: the Westfall Hoard that holds the supplies.
(254043, 0, 0, -10259, 1767),
-- 254043: Protector Gariel.
(254043, 1, 0, -10634, 1181),
-- 255057: the training yard the Militia Recruits stand in.
(255057, 0, 0, -10748, 965),
(255057, 0, 1, -10722, 965),
(255057, 0, 2, -10722, 1000),
(255057, 0, 3, -10748, 1000),
-- 255057: Captain Olens.
(255057, 1, 0, -10719, 980),
-- 999913: the Slain Protector, where the report is found and handed in.
(999913, 0, 0, -9976, 955),
-- 999914: the Half-Detailed Report on the Slain Protector.
(999914, 0, 0, -9976, 955),
-- 999914: Archivist Selnor.
(999914, 1, 0, -10679, 958),
-- 999933: the Spit-Soaked Report on the Half-Devoured Protector.
(999933, 0, 0, -11030, 790),
-- 999933: Archivist Selnor.
(999933, 1, 0, -10679, 958),
-- 100466: Dungar Longdrink at the Stormwind flight master.
(100466, 0, 0, -8836, 490),
-- 100466: Gryan Stoutmantle at Sentinel Hill.
(100466, 1, 0, -10509, 1045);
