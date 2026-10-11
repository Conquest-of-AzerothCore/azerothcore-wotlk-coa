-- CoA Goldshire: Defias Disruption (100071), Agria's Medicine (1660056), Seven Years of Bad Luck (1660057), Worm-Eaten
-- Apple (1660058), Goldshire's Generosity (1660059), Stay a While (1660060) and Extravagant Order (17001) get their
-- objective areas on the world map (#6977, #6982). All but 17001 only carried the turn-in pin
-- rev_20260924_60_coa_quest_markers.sql wrote (id 0, ObjectiveIndex -1) and 17001 had no POI at all, so a player
-- with the quest open saw nothing on the map for where to go. 100073 Supply Run got its
-- area from rev_20261007_90_coa_quest_6038_elwynn_objective_markers.sql.
--
-- Each area is a rectangle about 30 yd outside the spawns of the objective, drawn the way rev_20261007_90 draws
-- its own; ObjectiveIndex is 0-3 for the kill/go objectives and 4 + the RequiredItemId slot for the items:
--
-- 100071 wants 6 Defias Bandits 116 (ObjectiveIndex 0) and 4 Defias Rogue Wizards 474 (ObjectiveIndex 1) at the
-- Bandit's Bastion; their spawns (creature guids 9002206-9002237) stand between x -9838 and -9746 and y -497 and
-- -427, inside the rectangle of 100073.
--
-- 1660056 buys four ingredients at the Goldshire market (ObjectiveIndex 4-7, the fifth item 558960 is the quest's
-- StartItem): Elgris Blossom Petals from Ainora 162814, Dun Kazad Liquor Concentrate from Darron 162811, Pumpkin
-- Juice from Rowena 162809 and the Murloc Eyeball from Joaquin 162826. One area around each vendor.
--
-- 1660059 gathers Pumpkins 558961 (ObjectiveIndex 4, gameobjects 2300547 in two patches: guids 7911060-7911062
-- and 7911063-7911071), Melons 558962 (ObjectiveIndex 5, 2300548, guids 7911040-7911050) and Apples 558963
-- (ObjectiveIndex 6, 2300549, guids 7911080-7911103).
--
-- 1660057 inspects Mirror Shards (ObjectiveIndex 0; gameobjects 2300546, guids 7911000-7911016 and 8001305-8001307)
-- around the Spada manor.
--
-- 1660058 burns Kobold Warrens (ObjectiveIndex 0; gameobjects 2300579, guids 7911020-7911037) scattered west of
-- Goldshire.
--
-- 1660060 listens to the Arcane Projection of Aliscar 162943 (ObjectiveIndex 0; creature guid 9002020) on the east
-- entrance arch.
--
-- 17001 wants 4 Gem Encrusted Spider Silk 157001 (ObjectiveIndex 4) dropped by the Mine Spiders 43 and Mother Fang
-- 471 in the Jasperlode Mine (x -9066 to -9025, y -621 to -548). Its turn-in pin (id 0) is Tharynn Bouden's spawn
-- (creature guid 80327).
--
-- Aliscar Lend (creature guid 9002004, the book stall under the east entrance arch) faced 2.61, away from the
-- players who walk up to the stall. rev_20260923_00_coa_goldshire_quests.sql placed him there; his orientation turns
-- half a circle, 2.61 + pi, to 5.75159.
--
-- MapID 0, WorldMapAreaId 30 (Elwynn Forest, the value each quest's own turn-in row uses), Floor 0, Priority 0
-- and Flags 1; id 0 stays the turn-in pin of the quests that already have one.
--
-- Idempotent: delete of the exact keys followed by the insert.

DELETE FROM `quest_poi` WHERE (`QuestID`, `id`) IN ((17001, 0), (17001, 1), (100071, 1), (100071, 2), (1660056, 1), (1660056, 2), (1660056, 3), (1660056, 4), (1660057, 1), (1660058, 1), (1660059, 1), (1660059, 2), (1660059, 3), (1660059, 4), (1660060, 1));
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`)
VALUES
(17001, 0, -1, 0, 30, 0, 0, 1),
(17001, 1, 4, 0, 30, 0, 0, 1),
(100071, 1, 0, 0, 30, 0, 0, 1),
(100071, 2, 1, 0, 30, 0, 0, 1),
(1660056, 1, 4, 0, 30, 0, 0, 1),
(1660056, 2, 5, 0, 30, 0, 0, 1),
(1660056, 3, 6, 0, 30, 0, 0, 1),
(1660056, 4, 7, 0, 30, 0, 0, 1),
(1660057, 1, 0, 0, 30, 0, 0, 1),
(1660058, 1, 0, 0, 30, 0, 0, 1),
(1660059, 1, 4, 0, 30, 0, 0, 1),
(1660059, 2, 4, 0, 30, 0, 0, 1),
(1660059, 3, 5, 0, 30, 0, 0, 1),
(1660059, 4, 6, 0, 30, 0, 0, 1),
(1660060, 1, 0, 0, 30, 0, 0, 1);

DELETE FROM `quest_poi_points` WHERE (`QuestID`, `Idx1`) IN ((17001, 0), (17001, 1), (100071, 1), (100071, 2), (1660056, 1), (1660056, 2), (1660056, 3), (1660056, 4), (1660057, 1), (1660058, 1), (1660059, 1), (1660059, 2), (1660059, 3), (1660059, 4), (1660060, 1));
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`)
VALUES
(17001, 0, 0, -9494, 84),
(17001, 1, 0, -9100, -515),
(17001, 1, 1, -8995, -515),
(17001, 1, 2, -8995, -655),
(17001, 1, 3, -9100, -655),
(100071, 1, 0, -9855, -400),
(100071, 1, 1, -9725, -400),
(100071, 1, 2, -9725, -525),
(100071, 1, 3, -9855, -525),
(100071, 2, 0, -9855, -400),
(100071, 2, 1, -9725, -400),
(100071, 2, 2, -9725, -525),
(100071, 2, 3, -9855, -525),
(1660056, 1, 0, -9420, 55),
(1660056, 1, 1, -9355, 55),
(1660056, 1, 2, -9355, -10),
(1660056, 1, 3, -9420, -10),
(1660056, 2, 0, -9500, 95),
(1660056, 2, 1, -9435, 95),
(1660056, 2, 2, -9435, 30),
(1660056, 2, 3, -9500, 30),
(1660056, 3, 0, -9520, 70),
(1660056, 3, 1, -9455, 70),
(1660056, 3, 2, -9455, 5),
(1660056, 3, 3, -9520, 5),
(1660056, 4, 0, -9485, -50),
(1660056, 4, 1, -9420, -50),
(1660056, 4, 2, -9420, -115),
(1660056, 4, 3, -9485, -115),
(1660057, 1, 0, -9350, 535),
(1660057, 1, 1, -9240, 535),
(1660057, 1, 2, -9240, 395),
(1660057, 1, 3, -9350, 395),
(1660058, 1, 0, -9830, 240),
(1660058, 1, 1, -9600, 240),
(1660058, 1, 2, -9600, -80),
(1660058, 1, 3, -9830, -80),
(1660059, 1, 0, -9535, 105),
(1660059, 1, 1, -9470, 105),
(1660059, 1, 2, -9470, 35),
(1660059, 1, 3, -9535, 35),
(1660059, 2, 0, -9450, -10),
(1660059, 2, 1, -9365, -10),
(1660059, 2, 2, -9365, -95),
(1660059, 2, 3, -9450, -95),
(1660059, 3, 0, -9540, 140),
(1660059, 3, 1, -9465, 140),
(1660059, 3, 2, -9465, 55),
(1660059, 3, 3, -9540, 55),
(1660059, 4, 0, -9480, 5),
(1660059, 4, 1, -9410, 5),
(1660059, 4, 2, -9410, -80),
(1660059, 4, 3, -9480, -80),
(1660060, 1, 0, -9440, 25),
(1660060, 1, 1, -9375, 25),
(1660060, 1, 2, -9375, -40),
(1660060, 1, 3, -9440, -40);

UPDATE `creature` SET `orientation` = 5.75159 WHERE `guid` = 9002004;
