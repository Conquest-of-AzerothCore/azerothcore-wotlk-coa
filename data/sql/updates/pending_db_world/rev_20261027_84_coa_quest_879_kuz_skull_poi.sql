-- Stock quest 879 'Betrayal from Within' (Barrens, Camp Taurajo): the Kuz's Skull objective marker
-- (quest_poi id 0, ObjectiveIndex 4, base quest_poi_points.sql:8014) sits at (-3764, -1833), about 132
-- yards from Kuz's own spawn (creature.sql guid 14383, id 3436 'Kuz': -3814.72, -1955.13, map 1), well
-- outside the Razormane camp the pin points at (#7721). Nak (3434) and Lok Orcbane (3435) keep their own
-- markers (quest_poi ids 1 and 2) unchanged; only Kuz's pin moves, to his rounded spawn coordinates.
--
-- Idempotent: delete of the exact key followed by the insert.

DELETE FROM `quest_poi_points` WHERE `QuestID` = 879 AND `Idx1` = 0 AND `Idx2` = 0;
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`)
VALUES
(879, 0, 0, -3815, -1955);
