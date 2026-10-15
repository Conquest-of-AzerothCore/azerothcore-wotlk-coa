-- Conquest of Azeroth: Tirisfal Glades quest map markers (WorldMapAreaId 20).
-- Turn-in and objective markers follow the enders and objects the Tirisfal files moved; new CoA quests
-- get a turn-in marker at their QuestSuperTrack turn-in point, and 1660053 an objective marker over its
-- camp. Exact keys only; re-applying is a no-op.
-- Not marked: 1660054 Stay a While: no QuestSuperTrack turn-in point. 6395 turn-in: its QuestSuperTrack turn-in
--   (1086) is on map 1; the stock marker at Elreth stays. 9302412, 9302413 (migration 09): no QuestSuperTrack
--   point.

-- ---------------------------------------------------------------------------
-- 1. Turn-in markers of moved enders
-- ---------------------------------------------------------------------------
-- Apothecary Johaan 1518 (guid 35231): 2259, 347 -> 2246, 396, QuestSuperTrack 1267.
UPDATE `quest_poi_points` SET `X` = 2246, `Y` = 396 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (365, 1, 0), (367, 3, 0), (368, 3, 0), (369, 1, 0));

-- Velma Warnam 4773 (guid 33711): 2255, 318 -> 2291, 359, QuestSuperTrack 3285.
UPDATE `quest_poi_points` SET `X` = 2291, `Y` = 359 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (14089, 0, 0));

-- Junior Apothecary Holland 10665 (guid 28412): 2363, 427 -> 2326, 399, QuestSuperTrack 1704.
UPDATE `quest_poi_points` SET `X` = 2326, `Y` = 399 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (5481, 1, 0), (5482, 1, 0));

-- Bountiful Feast Hostess 34654 (guid 52788): 2288, 383 -> 2354, 265, moved with the Brill feast
--   (rev_20260926_11).
UPDATE `quest_poi_points` SET `X` = 2354, `Y` = 265 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (14065, 9, 0));

-- ---------------------------------------------------------------------------
-- 2. Objective markers of moved objects
-- ---------------------------------------------------------------------------
-- 6395 Marla's Last Wish, objective 0 (Marla's Grave 178090, guid 45015): 1877, 1625 -> 1884, 1588,
--   QuestSuperTrack 6961.
UPDATE `quest_poi_points` SET `X` = 1884, `Y` = 1588 WHERE `QuestID` = 6395 AND `Idx1` = 0 AND `Idx2` = 0;

-- ---------------------------------------------------------------------------
-- 3. Turn-in markers for new CoA quests
-- ---------------------------------------------------------------------------
DELETE FROM `quest_poi` WHERE (`QuestID`, `id`) IN (
    (1660024, 0), (1660025, 0), (1660026, 0), (1660027, 0), (1660028, 0), (1660029, 0), (1660042, 0),
    (1660050, 0), (1660051, 0), (1660052, 0), (1660053, 0), (254053, 0), (254054, 0), (254055, 0), (254056, 0),
    (254057, 0), (254064, 0));
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`)
VALUES
(1660024, 0, -1, 0, 20, 0, 0, 1),
(1660025, 0, -1, 0, 20, 0, 0, 1),
(1660026, 0, -1, 0, 20, 0, 0, 1),
(1660027, 0, -1, 0, 20, 0, 0, 1),
(1660028, 0, -1, 0, 20, 0, 0, 1),
(1660029, 0, -1, 0, 20, 0, 0, 1),
(1660042, 0, -1, 0, 20, 0, 0, 1),
(1660050, 0, -1, 0, 20, 0, 0, 1),
(1660051, 0, -1, 0, 20, 0, 0, 1),
(1660052, 0, -1, 0, 20, 0, 0, 1),
(1660053, 0, -1, 0, 20, 0, 0, 1),
(254053, 0, -1, 0, 20, 0, 0, 1),
(254054, 0, -1, 0, 20, 0, 0, 1),
(254055, 0, -1, 0, 20, 0, 0, 1),
(254056, 0, -1, 0, 20, 0, 0, 1),
(254057, 0, -1, 0, 20, 0, 0, 1),
(254064, 0, -1, 0, 20, 0, 0, 1);
DELETE FROM `quest_poi_points` WHERE (`QuestID`, `Idx1`) IN (
    (1660024, 0), (1660025, 0), (1660026, 0), (1660027, 0), (1660028, 0), (1660029, 0), (1660042, 0),
    (1660050, 0), (1660051, 0), (1660052, 0), (1660053, 0), (254053, 0), (254054, 0), (254055, 0), (254056, 0),
    (254057, 0), (254064, 0));
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`)
VALUES
(1660024, 0, 0, 1870, 1839),
(1660025, 0, 0, 1870, 1839),
(1660026, 0, 0, 1936, 1974),
(1660027, 0, 0, 1870, 1839),
(1660028, 0, 0, 1874, 1844),
(1660029, 0, 0, 1866, 1846),
(1660042, 0, 0, 1870, 1844),
(1660050, 0, 0, 2258, 408),
(1660051, 0, 0, 2258, 408),
(1660052, 0, 0, 2248, 327),
(1660053, 0, 0, 2248, 327),
(254053, 0, 0, 1910, -153),
(254054, 0, 0, 1911, -153),
(254055, 0, 0, 1665, -369),
(254056, 0, 0, 2489, -393),
(254057, 0, 0, 2489, -393),
(254064, 0, 0, 2656, 1046);

-- ---------------------------------------------------------------------------
-- 4. Objective markers for new CoA quests
-- ---------------------------------------------------------------------------
-- 1660053 Scarlet Correspondence: the Rosewalk Scarlet camp, outline of the 15 Questie Scarlet points.
DELETE FROM `quest_poi` WHERE (`QuestID`, `id`) IN (
    (1660053, 1));
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`)
VALUES
(1660053, 1, 0, 0, 20, 0, 0, 1);
DELETE FROM `quest_poi_points` WHERE (`QuestID`, `Idx1`) IN (
    (1660053, 1));
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`)
VALUES
(1660053, 1, 0, 2397, 160),
(1660053, 1, 1, 2421, 96),
(1660053, 1, 2, 2490, 164),
(1660053, 1, 3, 2420, 203),
(1660053, 1, 4, 2414, 202);
