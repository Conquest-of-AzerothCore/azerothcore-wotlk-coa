-- CoA Goldshire: Defias Disruption (100071) marks the Bandit's Bastion again (#6438).
--
-- rev_20261009_00_coa_quest_6977_goldshire_objective_markers.sql gave both objectives (6 Defias Bandits 116,
-- ObjectiveIndex 0; 4 Defias Rogue Wizards 474, ObjectiveIndex 1) one area around the Bastion spawns (creature guids
-- 9002206-9002237, x -9838 to -9746, y -497 to -427). rev_20261009_30_coa_quest_poi_restore.sql runs after it and
-- replaced them with ids 1-12 around every Defias Bandit and Rogue Wizard spawn in Elwynn (x -9890 to -9029,
-- y -1620 to 552), so the map spread the objective across the zone instead of the Bastion the quest text names.
-- The client's QuestSuperTrack row 1002 for 100071 points objective 0 at SuperTrack 8547, map 0
-- (-9792.55, -450.69), the Bastion.
--
-- id 0 stays the turn-in pin at Melika Isenstrider. MapID 0, WorldMapAreaId 30, Floor 0, Priority 0, Flags 1.
--
-- Idempotent: delete of the exact keys followed by the insert.

DELETE FROM `quest_poi` WHERE `QuestID` = 100071 AND `id` BETWEEN 1 AND 12;
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`)
VALUES
(100071, 1, 0, 0, 30, 0, 0, 1),
(100071, 2, 1, 0, 30, 0, 0, 1);

DELETE FROM `quest_poi_points` WHERE `QuestID` = 100071 AND `Idx1` BETWEEN 1 AND 12;
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`)
VALUES
(100071, 1, 0, -9855, -400),
(100071, 1, 1, -9725, -400),
(100071, 1, 2, -9725, -525),
(100071, 1, 3, -9855, -525),
(100071, 2, 0, -9855, -400),
(100071, 2, 1, -9725, -400),
(100071, 2, 2, -9725, -525),
(100071, 2, 3, -9855, -525);
