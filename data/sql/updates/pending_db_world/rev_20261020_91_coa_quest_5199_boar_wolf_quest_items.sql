-- Issues #5199, #5214, #6656: list Chunk of Boar Meat (769) and Lean Wolf Flank (1015) as creature quest items so
-- the default tooltip shows the objective of Pie for Billy (86), Stocking Jetsteam (317) and Seasoned Wolf Kabobs (90)
-- on the mobs that drop them.
-- This is a quality-of-life change approved by the user on 2026-10-20. It departs from live: the captured CoA
-- creaturecache.wdb (C:\CoA\SUB\WDB, 2026-09-05) lists neither item for these creatures, and no other source does.
-- Creatures: every creature_loot_template source of 769 or 1015 on origin/main b82b2dd056. Idx: the next free slot
-- after the existing creature_questitem rows (157/454: 723, 731; 330: 1006; 1190-1192: 3172; 3099/3100/3225: 354317).
DELETE FROM `creature_questitem` WHERE (`CreatureEntry`, `Idx`) IN (
(113, 0), (119, 0), (157, 2), (330, 1), (390, 0), (454, 2), (524, 0), (547, 0), (1125, 0), (1126, 0), (1127, 0),
(1190, 1), (1191, 1), (1192, 1), (1689, 0), (3099, 1), (3100, 1), (3225, 1),
(213, 0), (521, 0), (565, 0), (628, 0), (923, 0), (1258, 0), (3823, 0), (3824, 0), (3825, 0), (3861, 0), (3862, 0),
(3863, 0), (4274, 0), (10644, 0), (164084, 0));
INSERT INTO `creature_questitem` (`CreatureEntry`, `Idx`, `ItemId`, `VerifiedBuild`) VALUES
(113, 0, 769, 0),
(119, 0, 769, 0),
(157, 2, 769, 0),
(330, 1, 769, 0),
(390, 0, 769, 0),
(454, 2, 769, 0),
(524, 0, 769, 0),
(547, 0, 769, 0),
(1125, 0, 769, 0),
(1126, 0, 769, 0),
(1127, 0, 769, 0),
(1190, 1, 769, 0),
(1191, 1, 769, 0),
(1192, 1, 769, 0),
(1689, 0, 769, 0),
(3099, 1, 769, 0),
(3100, 1, 769, 0),
(3225, 1, 769, 0),
(213, 0, 1015, 0),
(521, 0, 1015, 0),
(565, 0, 1015, 0),
(628, 0, 1015, 0),
(923, 0, 1015, 0),
(1258, 0, 1015, 0),
(3823, 0, 1015, 0),
(3824, 0, 1015, 0),
(3825, 0, 1015, 0),
(3861, 0, 1015, 0),
(3862, 0, 1015, 0),
(3863, 0, 1015, 0),
(4274, 0, 1015, 0),
(10644, 0, 1015, 0),
(164084, 0, 1015, 0);
