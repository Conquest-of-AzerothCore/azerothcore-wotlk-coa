-- CoA Mulgore quest map markers: stock turn-in markers follow the enders moved by the Mulgore files
-- (QuestSuperTrack turn-in points); CoA Mulgore quests get a turn-in marker at their ender.
-- 1660070 has no QuestSuperTrack turn-in and gets none. Exact keys only; re-applying is a no-op.

-- ---------------------------------------------------------------------------
-- 1. Turn-in markers of moved stock enders
-- ---------------------------------------------------------------------------
-- Greatmother Hawkwind 2991: -3053, -522 -> -3059, -527
UPDATE `quest_poi_points` SET `X` = -3059, `Y` = -527 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (752, 0, 0));
-- Ancestral Spirit 2994: -993, -1109 -> -989, -1109
UPDATE `quest_poi_points` SET `X` = -989, `Y` = -1109 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (773, 0, 0));
-- Morin Cloudstalker 2988: -2299, -595 -> -2292, -582
UPDATE `quest_poi_points` SET `X` = -2292, `Y` = -582 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (751, 0, 0), (764, 3, 0), (765, 1, 0));
-- Brave Windfeather 3209: -2935, -248 -> -2895, -244
UPDATE `quest_poi_points` SET `X` = -2895, `Y` = -244 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (3376, 1, 0));
-- Kar Stormsinger 3690: -2276, -400 -> -2277, -402
UPDATE `quest_poi_points` SET `X` = -2277, `Y` = -402 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (14087, 0, 0));
-- Seer Ravenfeather 5888: -2882, -250 -> -2884, -249
UPDATE `quest_poi_points` SET `X` = -2884, `Y` = -249 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (1462, 0, 0), (1519, 1, 0), (1521, 0, 0));
-- Elder Bloodhoof 15575: -2103, -439 -> -2105, -446
UPDATE `quest_poi_points` SET `X` = -2105, `Y` = -446 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (8673, 0, 0));
-- Mulgore Flame Keeper 25936: -2322, -620 -> -2322, -614
UPDATE `quest_poi_points` SET `X` = -2322, `Y` = -614 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (11852, 0, 0));
-- Spring Gatherer 32798: -2332, -353 -> -2337, -356
UPDATE `quest_poi_points` SET `X` = -2337, `Y` = -356 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (13479, 1, 0), (13483, 1, 0));
-- Noblegarden Merchant 32837: -2345, -363 -> -2343, -365
UPDATE `quest_poi_points` SET `X` = -2343, `Y` = -365 WHERE (`QuestID`, `Idx1`, `Idx2`) IN (
    (13503, 1, 0));

-- ---------------------------------------------------------------------------
-- 2. Turn-in markers for the CoA Mulgore quests
-- ---------------------------------------------------------------------------
DELETE FROM `quest_poi` WHERE (`QuestID`, `id`) IN (
    (1660030, 0), (1660031, 0), (1660032, 0), (1660033, 0), (1660034, 0), (1660035, 0), (1660043, 0),
    (1660066, 0), (1660067, 0), (1660068, 0), (1660069, 0), (500004, 0));
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`)
VALUES
(1660030, 0, -1, 1, 9, 0, 0, 1),
(1660031, 0, -1, 1, 9, 0, 0, 1),
(1660032, 0, -1, 1, 9, 0, 0, 1),
(1660033, 0, -1, 1, 9, 0, 0, 1),
(1660034, 0, -1, 1, 9, 0, 0, 1),
(1660035, 0, -1, 1, 9, 0, 0, 1),
(1660043, 0, -1, 1, 9, 0, 0, 1),
(1660066, 0, -1, 1, 9, 0, 0, 1),
(1660067, 0, -1, 1, 9, 0, 0, 1),
(1660068, 0, -1, 1, 9, 0, 0, 1),
(1660069, 0, -1, 1, 9, 0, 0, 1),
(500004, 0, -1, 1, 9, 0, 0, 1);
DELETE FROM `quest_poi_points` WHERE (`QuestID`, `Idx1`) IN (
    (1660030, 0), (1660031, 0), (1660032, 0), (1660033, 0), (1660034, 0), (1660035, 0), (1660043, 0),
    (1660066, 0), (1660067, 0), (1660068, 0), (1660069, 0), (500004, 0));
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`)
VALUES
(1660030, 0, 0, -3361, -902),
(1660031, 0, 0, -3628, -1036),
(1660032, 0, 0, -3628, -1036),
(1660033, 0, 0, -3361, -902),
(1660034, 0, 0, -3644, -970),
(1660035, 0, 0, -3644, -970),
(1660043, 0, 0, -3644, -970),
(1660066, 0, 0, -2913, 7),
(1660067, 0, 0, -2296, -224),
(1660068, 0, 0, -2296, -224),
(1660069, 0, 0, -2354, -3),
(500004, 0, 0, -1965, -354);
