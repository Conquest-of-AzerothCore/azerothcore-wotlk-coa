-- Wild Hearts (429) and 15 more: these quest drops are in the creatures' loot and quest requirements but had no
-- creature_questitem row, so the client tooltip never showed them; the rows match Ascension's creature cache
DELETE FROM `creature_questitem` WHERE (`CreatureEntry`, `Idx`) IN ((199, 0), (422, 1), (544, 1), (545, 1), (548, 1), (578, 1), (1083, 1), (1765, 0), (1766, 0), (1923, 0), (6846, 1), (7428, 2), (7429, 2), (12431, 0), (14270, 1), (164062, 1));
INSERT INTO `creature_questitem` (`CreatureEntry`, `Idx`, `ItemId`, `VerifiedBuild`) VALUES
(199, 0, 729, 0),
(422, 1, 1468, 0),
(544, 1, 1468, 0),
(545, 1, 1468, 0),
(548, 1, 1468, 0),
(578, 1, 1468, 0),
(1083, 1, 1468, 0),
(1765, 0, 3164, 0),
(1766, 0, 3164, 0),
(1923, 0, 3164, 0),
(6846, 1, 7675, 0),
(7428, 2, 12436, 0),
(7429, 2, 12436, 0),
(12431, 0, 3164, 0),
(14270, 1, 1468, 0),
(164062, 1, 560345, 0);
