-- CoA Northshire class chain: Lost Pendant (200058) and A Quiet Life (200077) get the two markers
-- the world map draws for them - the objective area and the turn-in pin. Both quests had no
-- `quest_poi` row at all, not even a turn-in pin, so a player carrying either one saw a completely
-- unmarked map (the sibling A Quiet Life quests 200081/200083 got a row set with the hidden-statue
-- work, these two were missed).
--
-- 200058 Lost Pendant is an item objective: the quest wants Lost Pendant 663319 (RequiredItemId1),
-- which is what the one chest in the valley pays out (gameobject 9301103, guid 7912105, on the crate
-- at the Defias camp, -8956.38 -435.027). Item objectives take ObjectiveIndex 4 - the first item
-- slot - the way stock 6 'Bounty on Garrick Padfoot' (RequiredItemId1 182) uses 4 for its own item
-- objective, while NPC/gameobject objectives take ObjectiveIndex 0 (stock 7 'Kobold Camp Cleanup').
-- The area is the camp itself, drawn around the crate and the Defias Thugs (entry 38) that guard it:
-- the thugs stand at -8998.8 -390.3, -9028 -383.9, -8980.8 -411.6, -8951.5 -430, -8956.2 -422.4,
-- -8958.4 -431.3, -8956.9 -389.9 and -8963.1 -370.3, all inside the rectangle below, so the marker
-- covers the ground the quest text describes ("they ran me off. In my haste, I dropped my pendant").
--
-- 200077 A Quiet Life is an NPC/gameobject objective (RequiredNpcOrGo1 685037, ObjectiveIndex 0): the
-- invisible walk-in marker at the foot of the Northshire falls (creature 685037, guid 9003129,
-- -8739.5 -410.5) whose SmartAI credits the quest within 15 yd out of combat. The area covers the
-- falls and the bank in front of them, where Uther's Statue now stands (gameobject 9301105, guid
-- 7912102, -8739.86 -413.297, moved onto the bank by rev_20261007_70), so a player following the
-- marker reaches the place the quest text names ("Visit the waterfall in Northshire Valley").
--
-- Each quest also gets the turn-in pin a player needs once the objective is done: id 1,
-- ObjectiveIndex -1, one point on the trainer the quest is handed to - Chaplain Nysoni (50286,
-- spawned by guid 7500294 at -8853.76 -193.45) for 200058 and Brother William (50280, spawned by
-- guid 7500235 at -8907.19 -210.78) for 200077. 200081 carries the same pair (its objective id 0
-- and a turn-in id 1 on ObjectiveIndex -1), and the slimy-solution file above writes its turn-in pin
-- with a single point on the quest giver too; the `id` is only the row's own key, the client tells
-- the markers apart by ObjectiveIndex, so the objective keeps 0 and the pin takes 1.
--
-- Conventions, all from the same pattern rev_20261007_30_coa_slimy_solution_objective_marker.sql
-- uses: points are world coordinates, MapID 0 is the Eastern Kingdoms, WorldMapAreaId 30 is the map
-- area Elwynn Forest draws under both Northshire and the camp (stock 7 'Kobold Camp Cleanup' marks
-- the Northshire kobold camp the same way), Floor 0, Priority 0 and Flags 1. Each objective is a
-- four-corner rectangle, which is what makes the client paint a blue search area instead of dropping
-- a single pin; each pin is the single point stock and the sibling quests use for a turn-in.
--
-- Idempotent: delete of the exact keys followed by the insert.
--
-- Rollback: DELETE FROM `quest_poi` WHERE `QuestID` IN (200058, 200077);
--           DELETE FROM `quest_poi_points` WHERE `QuestID` IN (200058, 200077);

DELETE FROM `quest_poi` WHERE (`QuestID`, `id`) IN ((200058, 0), (200058, 1), (200077, 0), (200077, 1));
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`)
VALUES
(200058, 0, 4, 0, 30, 0, 0, 1),
(200058, 1, -1, 0, 30, 0, 0, 1),
(200077, 0, 0, 0, 30, 0, 0, 1),
(200077, 1, -1, 0, 30, 0, 0, 1);

DELETE FROM `quest_poi_points` WHERE (`QuestID`, `Idx1`) IN ((200058, 0), (200058, 1), (200077, 0), (200077, 1));
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`)
VALUES
(200058, 0, 0, -9035, -365),
(200058, 0, 1, -8940, -365),
(200058, 0, 2, -8940, -460),
(200058, 0, 3, -9035, -460),
(200058, 1, 0, -8854, -193),
(200077, 0, 0, -8785, -380),
(200077, 0, 1, -8695, -380),
(200077, 0, 2, -8695, -450),
(200077, 0, 3, -8785, -450),
(200077, 1, 0, -8907, -211);
