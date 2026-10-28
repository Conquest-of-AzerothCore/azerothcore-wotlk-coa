-- CoA Elwynn: The Master's Orders (17002), King's Justice (17006) and Supply Run (100073) get an objective area
-- on the world map. Each quest only carried the turn-in pin rev_20260924_60_coa_quest_markers.sql wrote (id 0,
-- ObjectiveIndex -1), so a player with the quest open saw nothing on the map for the objective (#6038). 17003
-- Slimy Solution, the fourth quest in the report, already got its area from
-- rev_20261007_30_coa_slimy_solution_objective_marker.sql.
--
-- Every area is a rectangle about 30 yd outside the spawns rev_20260923_01_coa_elwynn_quests.sql placed for
-- that objective, the way rev_20261007_30 and rev_20261007_80 draw theirs:
--
-- 17002 wants 10 Depleted Mana Gems 157002 (RequiredItemId1, ObjectiveIndex 4) from the Defias Rogue Wizards
-- 474 "near Stone Cairn Lake" (quest text). Rev_20260923_01 places its wizards at the Stone Cairn standing
-- stones (guids 9002320-9002328 and 9002344-9002347, "on the path from the 17002 point"), among the stock
-- wizards there (81159-81176, 81294, 81299, 81311, 81320): all of them stand between x -9245 and -9013 and
-- y -1143 and -952, west of game_tele StoneCairnLake (-8983 -1206).
--
-- 17006 wants 8 Defias Bandits 116 (RequiredNpcOrGo1, ObjectiveIndex 0) and the Supply Cache 157013
-- (RequiredItemId1, ObjectiveIndex 4) from the Supply Cache object 96002. Both are the "Defias camp east of
-- Ridgepoint Tower" rev_20260923_01 builds: the cache (gameobject guid 7911201, -9767 -1560) and the camp's
-- bandits (9002244-9002254 and stock 81412, 81416, 81424) stand between x -9814 and -9738 and y -1608 and
-- -1530, so both objectives share the camp's rectangle.
--
-- 100073 wants 4 Stolen Supply Crates 5055564 (RequiredItemId1, ObjectiveIndex 4) from the Stolen Goods
-- objects 5055563 at the Bandit's Bastion; their 12 spawns (gameobject guids 7911230-7911241) stand between
-- x -9823 and -9758 and y -497 and -429.
--
-- MapID 0, WorldMapAreaId 30 (Elwynn Forest, the value each quest's own turn-in row uses), Floor 0, Priority 0
-- and Flags 1, the stock turn-in pattern rev_20260924_60 documents; id 0 stays the turn-in pin.
--
-- Idempotent: delete of the exact keys followed by the insert.

DELETE FROM `quest_poi` WHERE (`QuestID`, `id`) IN ((17002, 1), (17006, 1), (17006, 2), (100073, 1));
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`)
VALUES
(17002, 1, 4, 0, 30, 0, 0, 1),
(17006, 1, 0, 0, 30, 0, 0, 1),
(17006, 2, 4, 0, 30, 0, 0, 1),
(100073, 1, 4, 0, 30, 0, 0, 1);

DELETE FROM `quest_poi_points` WHERE (`QuestID`, `Idx1`) IN ((17002, 1), (17006, 1), (17006, 2), (100073, 1));
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`)
VALUES
(17002, 1, 0, -9275, -920),
(17002, 1, 1, -8985, -920),
(17002, 1, 2, -8985, -1175),
(17002, 1, 3, -9275, -1175),
(17006, 1, 0, -9845, -1500),
(17006, 1, 1, -9710, -1500),
(17006, 1, 2, -9710, -1640),
(17006, 1, 3, -9845, -1640),
(17006, 2, 0, -9845, -1500),
(17006, 2, 1, -9710, -1500),
(17006, 2, 2, -9710, -1640),
(17006, 2, 3, -9845, -1640),
(100073, 1, 0, -9855, -400),
(100073, 1, 1, -9725, -400),
(100073, 1, 2, -9725, -525),
(100073, 1, 3, -9855, -525);
