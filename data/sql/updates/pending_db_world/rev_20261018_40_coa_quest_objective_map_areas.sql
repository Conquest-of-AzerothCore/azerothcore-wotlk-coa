-- CoA quests: blue objective areas on the world map and quest tracker for 34 CoA-added quests.
--
-- These quests had only a turn-in pin (ObjectiveIndex -1, poi id 0), so while the quest was in progress the map
-- showed nothing - e.g. The Nature of Freedom (254064) gave no hint where the skeletons, zombies, banshees and
-- Mallek are. Each objective now gets an area: ObjectiveIndex 0-3 for RequiredNpcOrGo1-4, 4-9 for RequiredItemId1-6.
--
-- WHERE EACH AREA COMES FROM
--   The spawns that give the objective: the creature or gameobject itself, creatures whose KillCredit1/2 is the
--   credit entry, SmartAI sources of SET_QUEST_CREDIT (action 33) or ADD_ITEM (action 56), item droppers
--   (creature_loot_template) and loot containers (gameobject_loot_template), areatrigger rows, and the two
--   scripted spots in AscensionVultureCultQuests.cpp (Eyrie Moonwell for 1660015, Baby Night Elf 2300526 and
--   Eldya 161848 for 1660017). Spawns on the turn-in's map within 800 yd of the turn-in pin are grouped at 60 yd;
--   each group of 3+ spawns (up to 3 per objective) is drawn as its convex hull padded 15 yd, a single spot as a
--   40 x 40 yd box. WorldMapAreaId is the quest's own turn-in WorldMapAreaId (the spot lies inside it).
--   Cross-check: every QuestSuperTrack objective point of these quests (client DBC) lies inside the area drawn
--   for the same objective, except 254064 objective 1 (9 yd outside) and 1660021 objective 0, whose
--   SuperTrack point is the item handlers the area for objectives 4-7 covers. The start-zone class quests
--   have no QuestSuperTrack row.
--
-- Stay a While (1660054): objective 0 is Dark Priestess Ashara's sermon in Brill (credit 162921 from her action
--   list 16284700); her turn-in pin moves from WorldMapAreaId 22 (Western Plaguelands) to 20 (Tirisfal Glades),
--   the map page Brill is drawn on, as rev_20260926_14_coa_tirisfal_quest_markers.sql does for Brill's other quests.
--
-- Not covered: A Surprise Attack! and Call of the Dead (target is summoned), and the level 1-3 class tome quests
--   whose only objective is the start item they hand out (the turn-in pin is their marker).
--
-- Areas per quest:
--   200001 Falcons Are Friends
--     id 1, objective 0: creature 9300102, SmartAI quest credit
--   200004 Falcons Are Friends
--     id 1, objective 0: creature 9300152, SmartAI quest credit
--   200007 Falcons Are Friends
--     id 1, objective 0: creature 9300352, SmartAI quest credit
--   200010 Falcons Are Friends
--     id 1, objective 0: creature 9300202, SmartAI quest credit
--   200016 Falcons Are Friends
--     id 1, objective 0: creature 9300302, SmartAI quest credit
--   200025 Poisoning the World
--     id 1, objective 0: creature 9300350, SmartAI quest credit
--     id 2, objective 1: creature 503250, SmartAI quest credit
--     id 3, objective 2: creature 50294, SmartAI quest credit
--   200026 Poisoning the World
--     id 1, objective 0: creature 9300201, SmartAI quest credit
--     id 2, objective 1: creature 502925, SmartAI quest credit
--     id 3, objective 2: creature 9300200, SmartAI quest credit
--   200027 The Doctor Is In!
--     id 1, objective 0: creature 85031, SmartAI quest credit
--   200029 The Doctor Is In!
--     id 1, objective 0: creature 9300203, SmartAI quest credit
--   200031 Champion of Elune
--     id 1, objective 0: creature 685032, SmartAI quest credit
--   200032 Champion of Mu'sha
--     id 1, objective 0: creature 685033, SmartAI quest credit
--   200037 Call of the Shadowlands
--     id 1, objective 0: creature 9300103, SmartAI quest credit
--   200038 Call of the Shadowlands
--     id 1, objective 0: creature 9300353, SmartAI quest credit
--   200039 Call of the Shadowlands
--     id 1, objective 0: creature 9300255, SmartAI quest credit
--   200199 Call of the Shadowlands
--     id 1, objective 0: creature 9300154, SmartAI quest credit
--   254064 The Nature of Freedom
--     id 1, objective 0: creature 1522 x54, creature 1523 x23, creature 1520 x21, SmartAI quest credit
--     id 2, objective 1: creature 1530 x14, SmartAI quest credit
--     id 3, objective 1: creature 1530 x7, SmartAI quest credit
--     id 4, objective 2: creature 1534 x22, SmartAI quest credit
--     id 5, objective 3: creature 254584, SmartAI quest credit
--   254107 Unexpected Results
--     id 1, objective 0: creature 1922 x63, creature 822 x17, creature 118 x4, SmartAI quest credit
--     id 2, objective 0: creature 524 x54, creature 822 x8, SmartAI quest credit
--     id 3, objective 0: creature 524 x18, creature 822 x8, SmartAI quest credit
--   1660007 A Promising Path
--     id 1, objective 0: areatrigger 6137
--   1660010 Deciphering Radiation
--     id 1, objective 4: creature 161776 x20, SmartAI ADD_ITEM
--   1660011 Soaking the Masses
--     id 1, objective 0: creature 161786 x23, SmartAI quest credit
--   1660013 The Sister Who Never Returned
--     id 1, objective 0: creature 161727, SmartAI quest credit
--   1660015 Transsubstantiating the Flesh
--     id 1, objective 0: the Eyrie Moonwell (spell_coa_channeling_blessing_of_the_moon)
--     id 2, objective 4: the Eyrie Moonwell, where creature 161783 (drops the item) rises
--   1660017 A Trail of Petals
--     id 1, objective 0: gameobject 2300526 (Baby Night Elf) x13
--     id 2, objective 1: creature 161848 (Eldya), where the butterflies are delivered
--   1660019 The Way is Shut
--     id 1, objective 0: areatrigger 6139
--   1660021 So That He May Hear Again
--     id 1, objective 0: creature 161732, SmartAI quest credit
--     id 2, objective 4: creature 161860, SmartAI ADD_ITEM
--     id 3, objective 5: creature 161859, SmartAI ADD_ITEM
--     id 4, objective 6: creature 161862, SmartAI ADD_ITEM
--     id 5, objective 7: creature 161861, SmartAI ADD_ITEM
--   1660037 Unease Makes Tongues Wag
--     id 1, objective 0: gameobject 2300535, SmartAI quest credit
--     id 2, objective 1: gameobject 2300536, SmartAI quest credit
--     id 3, objective 2: gameobject 2300537, SmartAI quest credit
--   1660065 Stay a While
--     id 1, objective 0: creature 162841, SmartAI quest credit
--   1660072 The Aid of Theren-Dion
--     id 1, objective 0: creatures 162871/162872/162856/162870/162873 (14 spawns), SmartAI quest credit
--   1660075 Stay a While
--     id 1, objective 0: creature 162881, SmartAI quest credit
--   1660077 Thunderbrew's Hop
--     id 1, objective 4: gameobject 2300550 (Thunderbrew Hops) x22, SmartAI ADD_ITEM
--   1660080 Stay a While
--     id 1, objective 0: creature 162901, SmartAI quest credit
--   1660085 Elydna's Heirloom
--     id 1, objective 0: creature 161725, SmartAI quest credit
--   9302431 Call of the Shadowlands
--     id 1, objective 0: creature 9300206, SmartAI quest credit
--   1660054 Stay a While
--     id 1, objective 0: creature 162847 (Dark Priestess Ashara), gossip credit
--
-- Idempotent: delete of the exact keys followed by the insert.

DELETE FROM `quest_poi` WHERE (`QuestID`, `id`) IN (
    (200001, 1), (200004, 1), (200007, 1), (200010, 1), (200016, 1), (200025, 1), (200025, 2), (200025, 3),
    (200026, 1), (200026, 2), (200026, 3), (200027, 1), (200029, 1), (200031, 1), (200032, 1), (200037, 1),
    (200038, 1), (200039, 1), (200199, 1), (254064, 1), (254064, 2), (254064, 3), (254064, 4), (254064, 5),
    (254107, 1), (254107, 2), (254107, 3), (1660007, 1), (1660010, 1), (1660011, 1), (1660013, 1), (1660015, 1),
    (1660015, 2), (1660017, 1), (1660017, 2), (1660019, 1), (1660021, 1), (1660021, 2), (1660021, 3), (1660021, 4),
    (1660021, 5), (1660037, 1), (1660037, 2), (1660037, 3), (1660065, 1), (1660072, 1), (1660075, 1), (1660077, 1),
    (1660080, 1), (1660085, 1), (9302431, 1), (1660054, 1));
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`)
VALUES
(200001, 1, 0, 0, 1237, 0, 0, 1),
(200004, 1, 0, 0, 1238, 0, 0, 1),
(200007, 1, 0, 1, 1242, 0, 0, 1),
(200010, 1, 0, 1, 1243, 0, 0, 1),
(200016, 1, 0, 1, 1244, 0, 0, 1),
(200025, 1, 0, 1, 1242, 0, 0, 1),
(200025, 2, 1, 1, 1242, 0, 0, 1),
(200025, 3, 2, 1, 1242, 0, 0, 1),
(200026, 1, 0, 1, 1243, 0, 0, 1),
(200026, 2, 1, 1, 1243, 0, 0, 1),
(200026, 3, 2, 1, 1243, 0, 0, 1),
(200027, 1, 0, 0, 1225, 0, 0, 1),
(200029, 1, 0, 1, 1243, 0, 0, 1),
(200031, 1, 0, 1, 1242, 0, 0, 1),
(200032, 1, 0, 1, 1244, 0, 0, 1),
(200037, 1, 0, 0, 1237, 0, 0, 1),
(200038, 1, 0, 1, 1242, 0, 0, 1),
(200039, 1, 0, 0, 20, 0, 0, 1),
(200199, 1, 0, 0, 27, 0, 0, 1),
(254064, 1, 0, 0, 20, 0, 0, 1),
(254064, 2, 1, 0, 20, 0, 0, 1),
(254064, 3, 1, 0, 20, 0, 0, 1),
(254064, 4, 2, 0, 20, 0, 0, 1),
(254064, 5, 3, 0, 20, 0, 0, 1),
(254107, 1, 0, 0, 30, 0, 0, 1),
(254107, 2, 0, 0, 30, 0, 0, 1),
(254107, 3, 0, 0, 30, 0, 0, 1),
(1660007, 1, 0, 0, 27, 0, 0, 1),
(1660010, 1, 4, 0, 27, 0, 0, 1),
(1660011, 1, 0, 0, 27, 0, 0, 1),
(1660013, 1, 0, 1, 41, 0, 0, 1),
(1660015, 1, 0, 1, 41, 0, 0, 1),
(1660015, 2, 4, 1, 41, 0, 0, 1),
(1660017, 1, 0, 1, 41, 0, 0, 1),
(1660017, 2, 1, 1, 41, 0, 0, 1),
(1660019, 1, 0, 1, 4, 0, 0, 1),
(1660021, 1, 0, 1, 4, 0, 0, 1),
(1660021, 2, 4, 1, 4, 0, 0, 1),
(1660021, 3, 5, 1, 4, 0, 0, 1),
(1660021, 4, 6, 1, 4, 0, 0, 1),
(1660021, 5, 7, 1, 4, 0, 0, 1),
(1660037, 1, 0, 1, 4, 0, 0, 1),
(1660037, 2, 1, 1, 4, 0, 0, 1),
(1660037, 3, 2, 1, 4, 0, 0, 1),
(1660065, 1, 0, 1, 4, 0, 0, 1),
(1660072, 1, 0, 1, 41, 0, 0, 1),
(1660075, 1, 0, 1, 41, 0, 0, 1),
(1660077, 1, 4, 0, 27, 0, 0, 1),
(1660080, 1, 0, 0, 27, 0, 0, 1),
(1660085, 1, 0, 1, 41, 0, 0, 1),
(9302431, 1, 0, 1, 1243, 0, 0, 1),
(1660054, 1, 0, 0, 20, 0, 0, 1);

DELETE FROM `quest_poi_points` WHERE (`QuestID`, `Idx1`) IN (
    (200001, 1), (200004, 1), (200007, 1), (200010, 1), (200016, 1), (200025, 1), (200025, 2), (200025, 3),
    (200026, 1), (200026, 2), (200026, 3), (200027, 1), (200029, 1), (200031, 1), (200032, 1), (200037, 1),
    (200038, 1), (200039, 1), (200199, 1), (254064, 1), (254064, 2), (254064, 3), (254064, 4), (254064, 5),
    (254107, 1), (254107, 2), (254107, 3), (1660007, 1), (1660010, 1), (1660011, 1), (1660013, 1), (1660015, 1),
    (1660015, 2), (1660017, 1), (1660017, 2), (1660019, 1), (1660021, 1), (1660021, 2), (1660021, 3), (1660021, 4),
    (1660021, 5), (1660037, 1), (1660037, 2), (1660037, 3), (1660065, 1), (1660072, 1), (1660075, 1), (1660077, 1),
    (1660080, 1), (1660085, 1), (9302431, 1), (1660054, 1));
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`)
VALUES
(200001, 1, 0, -8781, -388),
(200001, 1, 1, -8781, -428),
(200001, 1, 2, -8821, -428),
(200001, 1, 3, -8821, -388),
(200004, 1, 0, -6133, 614),
(200004, 1, 1, -6133, 574),
(200004, 1, 2, -6173, 574),
(200004, 1, 3, -6173, 614),
(200007, 1, 0, 10708, 748),
(200007, 1, 1, 10708, 708),
(200007, 1, 2, 10668, 708),
(200007, 1, 3, 10668, 748),
(200010, 1, 0, -474, -4278),
(200010, 1, 1, -474, -4318),
(200010, 1, 2, -514, -4318),
(200010, 1, 3, -514, -4278),
(200016, 1, 0, -3026, -435),
(200016, 1, 1, -3026, -475),
(200016, 1, 2, -3066, -475),
(200016, 1, 3, -3066, -435),
(200025, 1, 0, 10478, 828),
(200025, 1, 1, 10478, 788),
(200025, 1, 2, 10438, 788),
(200025, 1, 3, 10438, 828),
(200025, 2, 0, 10454, 816),
(200025, 2, 1, 10454, 776),
(200025, 2, 2, 10414, 776),
(200025, 2, 3, 10414, 816),
(200025, 3, 0, 10407, 832),
(200025, 3, 1, 10407, 792),
(200025, 3, 2, 10367, 792),
(200025, 3, 3, 10367, 832),
(200026, 1, 0, -600, -4294),
(200026, 1, 1, -600, -4334),
(200026, 1, 2, -640, -4334),
(200026, 1, 3, -640, -4294),
(200026, 2, 0, -613, -4267),
(200026, 2, 1, -613, -4307),
(200026, 2, 2, -653, -4307),
(200026, 2, 3, -653, -4267),
(200026, 3, 0, -621, -4209),
(200026, 3, 1, -621, -4249),
(200026, 3, 2, -661, -4249),
(200026, 3, 3, -661, -4209),
(200027, 1, 0, -8609, -90),
(200027, 1, 1, -8609, -130),
(200027, 1, 2, -8649, -130),
(200027, 1, 3, -8649, -90),
(200029, 1, 0, -380, -4430),
(200029, 1, 1, -380, -4470),
(200029, 1, 2, -420, -4470),
(200029, 1, 3, -420, -4430),
(200031, 1, 0, 10730, 783),
(200031, 1, 1, 10730, 743),
(200031, 1, 2, 10690, 743),
(200031, 1, 3, 10690, 783),
(200032, 1, 0, -3430, -134),
(200032, 1, 1, -3430, -174),
(200032, 1, 2, -3470, -174),
(200032, 1, 3, -3470, -134),
(200037, 1, 0, -8658, -166),
(200037, 1, 1, -8658, -206),
(200037, 1, 2, -8698, -206),
(200037, 1, 3, -8698, -166),
(200038, 1, 0, 10524, 821),
(200038, 1, 1, 10524, 781),
(200038, 1, 2, 10484, 781),
(200038, 1, 3, 10484, 821),
(200039, 1, 0, 1880, 1576),
(200039, 1, 1, 1880, 1536),
(200039, 1, 2, 1840, 1536),
(200039, 1, 3, 1840, 1576),
(200199, 1, 0, -5580, -588),
(200199, 1, 1, -5580, -628),
(200199, 1, 2, -5620, -628),
(200199, 1, 3, -5620, -588),
(254064, 1, 0, 2490, 826),
(254064, 1, 1, 2501, 733),
(254064, 1, 2, 3011, 806),
(254064, 1, 3, 3012, 848),
(254064, 1, 4, 3008, 905),
(254064, 1, 5, 2988, 1072),
(254064, 1, 6, 2873, 1117),
(254064, 1, 7, 2829, 1132),
(254064, 1, 8, 2780, 1120),
(254064, 1, 9, 2628, 1061),
(254064, 1, 10, 2532, 992),
(254064, 1, 11, 2517, 960),
(254064, 1, 12, 2499, 918),
(254064, 2, 0, 2948, 756),
(254064, 2, 1, 3026, 640),
(254064, 2, 2, 3061, 638),
(254064, 2, 3, 3069, 651),
(254064, 2, 4, 3059, 681),
(254064, 2, 5, 2963, 788),
(254064, 3, 0, 2825, 717),
(254064, 3, 1, 2836, 680),
(254064, 3, 2, 2903, 611),
(254064, 3, 3, 2928, 619),
(254064, 3, 4, 2934, 684),
(254064, 3, 5, 2892, 724),
(254064, 4, 0, 2879, 553),
(254064, 4, 1, 2931, 525),
(254064, 4, 2, 3076, 656),
(254064, 4, 3, 3079, 692),
(254064, 4, 4, 3070, 696),
(254064, 4, 5, 2894, 740),
(254064, 5, 0, 2794, 733),
(254064, 5, 1, 2794, 693),
(254064, 5, 2, 2754, 693),
(254064, 5, 3, 2754, 733),
(254107, 1, 0, -9553, -508),
(254107, 1, 1, -9540, -1047),
(254107, 1, 2, -9506, -1110),
(254107, 1, 3, -9411, -1040),
(254107, 1, 4, -9347, -956),
(254107, 1, 5, -9314, -548),
(254107, 1, 6, -9375, -478),
(254107, 2, 0, -9939, -362),
(254107, 2, 1, -9854, -802),
(254107, 2, 2, -9718, -814),
(254107, 2, 3, -9686, -754),
(254107, 2, 4, -9602, -487),
(254107, 2, 5, -9646, -293),
(254107, 2, 6, -9664, -250),
(254107, 2, 7, -9901, -280),
(254107, 2, 8, -9925, -313),
(254107, 3, 0, -9925, -81),
(254107, 3, 1, -9865, -185),
(254107, 3, 2, -9682, -194),
(254107, 3, 3, -9679, -110),
(254107, 3, 4, -9680, -72),
(254107, 3, 5, -9737, 46),
(254107, 3, 6, -9844, 58),
(254107, 3, 7, -9891, -1),
(254107, 3, 8, -9923, -57),
(1660007, 1, 0, -6015, 719),
(1660007, 1, 1, -6015, 679),
(1660007, 1, 2, -6055, 679),
(1660007, 1, 3, -6055, 719),
(1660010, 1, 0, -5997, 452),
(1660010, 1, 1, -5920, 412),
(1660010, 1, 2, -5903, 410),
(1660010, 1, 3, -5886, 578),
(1660010, 1, 4, -5889, 583),
(1660010, 1, 5, -5919, 588),
(1660011, 1, 0, -5967, 477),
(1660011, 1, 1, -5965, 468),
(1660011, 1, 2, -5943, 459),
(1660011, 1, 3, -5881, 466),
(1660011, 1, 4, -5863, 561),
(1660011, 1, 5, -5866, 568),
(1660011, 1, 6, -5878, 579),
(1660011, 1, 7, -5926, 580),
(1660011, 1, 8, -5949, 547),
(1660013, 1, 0, 10817, 501),
(1660013, 1, 1, 10817, 461),
(1660013, 1, 2, 10777, 461),
(1660013, 1, 3, 10777, 501),
(1660015, 1, 0, 10854, 565),
(1660015, 1, 1, 10854, 525),
(1660015, 1, 2, 10814, 525),
(1660015, 1, 3, 10814, 565),
(1660015, 2, 0, 10855, 564),
(1660015, 2, 1, 10855, 524),
(1660015, 2, 2, 10815, 524),
(1660015, 2, 3, 10815, 564),
(1660017, 1, 0, 10858, 478),
(1660017, 1, 1, 10858, 420),
(1660017, 1, 2, 10801, 420),
(1660017, 1, 3, 10801, 478),
(1660017, 2, 0, 10710, 548),
(1660017, 2, 1, 10710, 508),
(1660017, 2, 2, 10670, 508),
(1660017, 2, 3, 10670, 548),
(1660019, 1, 0, -193, -4167),
(1660019, 1, 1, -193, -4207),
(1660019, 1, 2, -233, -4207),
(1660019, 1, 3, -233, -4167),
(1660021, 1, 0, -585, -4226),
(1660021, 1, 1, -585, -4266),
(1660021, 1, 2, -625, -4266),
(1660021, 1, 3, -625, -4226),
(1660021, 2, 0, -193, -4103),
(1660021, 2, 1, -193, -4143),
(1660021, 2, 2, -233, -4143),
(1660021, 2, 3, -233, -4103),
(1660021, 3, 0, -193, -4110),
(1660021, 3, 1, -193, -4150),
(1660021, 3, 2, -233, -4150),
(1660021, 3, 3, -233, -4110),
(1660021, 4, 0, -200, -4103),
(1660021, 4, 1, -200, -4143),
(1660021, 4, 2, -240, -4143),
(1660021, 4, 3, -240, -4103),
(1660021, 5, 0, -200, -4110),
(1660021, 5, 1, -200, -4150),
(1660021, 5, 2, -240, -4150),
(1660021, 5, 3, -240, -4110),
(1660037, 1, 0, -324, -4084),
(1660037, 1, 1, -324, -4124),
(1660037, 1, 2, -364, -4124),
(1660037, 1, 3, -364, -4084),
(1660037, 2, 0, -382, -4041),
(1660037, 2, 1, -382, -4081),
(1660037, 2, 2, -422, -4081),
(1660037, 2, 3, -422, -4041),
(1660037, 3, 0, -354, -4123),
(1660037, 3, 1, -354, -4163),
(1660037, 3, 2, -394, -4163),
(1660037, 3, 3, -394, -4123),
(1660065, 1, 0, 265, -4680),
(1660065, 1, 1, 265, -4720),
(1660065, 1, 2, 225, -4720),
(1660065, 1, 3, 225, -4680),
(1660072, 1, 0, 10051, 849),
(1660072, 1, 1, 10071, 827),
(1660072, 1, 2, 10097, 817),
(1660072, 1, 3, 10189, 842),
(1660072, 1, 4, 10193, 849),
(1660072, 1, 5, 10140, 911),
(1660072, 1, 6, 10126, 922),
(1660075, 1, 0, 9851, 812),
(1660075, 1, 1, 9851, 772),
(1660075, 1, 2, 9811, 772),
(1660075, 1, 3, 9811, 812),
(1660077, 1, 0, -5767, -585),
(1660077, 1, 1, -5760, -594),
(1660077, 1, 2, -5745, -603),
(1660077, 1, 3, -5734, -599),
(1660077, 1, 4, -5688, -550),
(1660077, 1, 5, -5709, -527),
(1660077, 1, 6, -5740, -541),
(1660077, 1, 7, -5760, -566),
(1660080, 1, 0, -5583, -585),
(1660080, 1, 1, -5583, -625),
(1660080, 1, 2, -5623, -625),
(1660080, 1, 3, -5623, -585),
(1660085, 1, 0, 10396, 765),
(1660085, 1, 1, 10396, 725),
(1660085, 1, 2, 10356, 725),
(1660085, 1, 3, 10356, 765),
(9302431, 1, 0, -620, -4268),
(9302431, 1, 1, -620, -4308),
(9302431, 1, 2, -660, -4308),
(9302431, 1, 3, -660, -4268),
(1660054, 1, 0, 2213, 353),
(1660054, 1, 1, 2213, 313),
(1660054, 1, 2, 2173, 313),
(1660054, 1, 3, 2173, 353);

UPDATE `quest_poi` SET `WorldMapAreaId` = 20 WHERE `QuestID` = 1660054 AND `id` = 0;
