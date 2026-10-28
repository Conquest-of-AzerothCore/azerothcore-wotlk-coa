-- CoA: 17003 'Slimy Solution' had no objective marker on the world map, only its turn-in pin.
--
-- The quest is collected with Simple Crystal Vial 157006 (its StartItem) from the Murloc Foragers and
-- Lurkers around the lake at Eastvale Lodging Camp, and it is credited through the kill-credit creature
-- 300220 '[KC] Slimy Murloc Spittle' (RequiredNpcOrGo1, count 10). 300220 has no spawn in the world at
-- all - the credit comes from the spellhit hook rev_20260923_01_coa_elwynn_quests.sql installed on the
-- murlocs (smart_scripts rows 'Murloc Forager/Lurker - On Spellhit Collect Slimy Murloc Spittle - Quest
-- Credit') - so no world object points the client at the objective. The only quest_poi row 17003 carried
-- was the turn-in pin rev_20260924_60_coa_quest_markers.sql wrote (id 0, ObjectiveIndex -1, at the Tower
-- of Azora), so a player with the quest open saw an empty map and no way to find the murlocs.
--
-- The marker is the murloc ground itself: 46 Murloc Forager and 732 Murloc Lurker spawn on both shores of
-- that lake (44 + 38 Elwynn spawns), between x -9959 and -8914 and y -1256 and -1059, while Eastvale
-- Lodging Camp stands at -9401 -1337. That is exactly what the quest text describes ("There are Murloc
-- Lurkers and Foragers near Eastvale Lodging Camp, both north and south of the lake", quest_template
-- .Details), and the two shores are 450 yd apart with the open lake between them, so each shore gets its
-- own marker: a player who reads only the west blue area would still miss the eastern murlocs.
--
-- One kill objective takes ObjectiveIndex 0 (NPC/object objectives are 0-3, item objectives 4-7; the same
-- convention rev_20261006_01 and rev_20261001_08 use with stock 376). poi id 1 and 2 because id 0 is the
-- turn-in, MapID 0 and WorldMapAreaId 30 (Elwynn Forest, the value the quest's own turn-in row uses),
-- Floor 0, Priority 0 and Flags 1 - the stock turn-in pattern rev_20260924_60 documents. The point sets
-- are rectangles around each shore's spawns, the way stock 52 'Protect the Frontier' draws this same lake
-- (quest_poi id 0, 12 points) and stock 7 'Kobold Camp Cleanup' draws the Northshire kobold camp.
--
-- Idempotent: delete of the exact keys followed by the insert.

DELETE FROM `quest_poi` WHERE (`QuestID`, `id`) IN ((17003, 1), (17003, 2));
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`)
VALUES
(17003, 1, 0, 0, 30, 0, 0, 1),
(17003, 2, 0, 0, 30, 0, 0, 1);

DELETE FROM `quest_poi_points` WHERE (`QuestID`, `Idx1`) IN ((17003, 1), (17003, 2));
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`)
VALUES
(17003, 1, 0, -9990, -1030),
(17003, 1, 1, -9770, -1030),
(17003, 1, 2, -9770, -1260),
(17003, 1, 3, -9990, -1260),
(17003, 2, 0, -9345, -1105),
(17003, 2, 1, -8890, -1105),
(17003, 2, 2, -8890, -1275),
(17003, 2, 3, -9345, -1275);
