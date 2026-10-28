-- Deathknell quests the world map could not show: 4 CoA class-chain quests had no quest_poi rows at all (the map
-- lists only quests with markers), and Rude Awakening 363 had only its turn-in. Each now has a turn-in marker at
-- its ender's spawn, and an objective area where the target has a place: the client's QuestSuperTrack point for
-- 363 (SOURCED-CLIENT), else the outline of the target's spawns or of the spawns that drop the item (DERIVED).
-- Objectives on invisible kill-credit markers or unplaced items keep no area.
DELETE FROM `quest_poi` WHERE (`QuestID`, `id`) IN (
    (200039, 0), (200081, 0), (200081, 1), (200140, 0), (200168, 0), (200168, 1), (363, 1));
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`,
    `Priority`, `Flags`) VALUES
(200039, 0, -1, 0, 20, 0, 0, 1),
(200081, 0, 0, 0, 20, 0, 0, 1),
(200081, 1, -1, 0, 20, 0, 0, 1),
(200140, 0, -1, 0, 20, 0, 0, 1),
(200168, 0, 4, 0, 20, 0, 0, 1),
(200168, 1, -1, 0, 20, 0, 0, 1),
(363, 1, 0, 0, 20, 0, 0, 1);
DELETE FROM `quest_poi_points` WHERE (`QuestID`, `Idx1`) IN (
    (200039, 0), (200081, 0), (200081, 1), (200140, 0), (200168, 0), (200168, 1), (363, 1));
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`) VALUES
(200039, 0, 0, 1870, 1636),
(200081, 0, 0, 1723, 1811),
(200081, 1, 0, 1723, 1811),
(200140, 0, 0, 1863, 1563),
(200168, 0, 0, 1836, 1575),
(200168, 1, 0, 1864, 1568),
(363, 1, 0, 1752, 1611);
