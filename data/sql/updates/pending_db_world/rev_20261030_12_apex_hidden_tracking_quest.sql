-- A hidden tracking quest carries the world objectives for the three bosses. With
-- QUEST_FLAGS_TRACKING the client keeps it out of the quest log but still treats the
-- bosses as quest targets, which is what draws the ground ring. The visible quest keeps
-- the item objectives so it completes on pickup.
DELETE FROM `quest_template` WHERE `ID` IN (17840, 17845);
INSERT INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `Flags`, `LogTitle`,
 `LogDescription`, `QuestDescription`, `QuestCompletionLog`,
 `RequiredNpcOrGo1`, `RequiredNpcOrGoCount1`,
 `RequiredNpcOrGo2`, `RequiredNpcOrGoCount2`,
 `RequiredNpcOrGo3`, `RequiredNpcOrGoCount3`,
 `VerifiedBuild`) VALUES
(17840, 2, 60, 58, 1519, 1024, 'The Three Apex Hunts',
 'Hunt the three apex beasts.', '', '',
 9916214, 1, 9916212, 1, 9916213, 1, 12340),
(17845, 2, 60, 58, 1637, 1024, 'The Three Apex Hunts',
 'Hunt the three apex beasts.', '', '',
 9916214, 1, 9916212, 1, 9916213, 1, 12340);

DELETE FROM `creature_queststarter` WHERE `quest` IN (17840, 17845);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES
(9916113, 17840),
(9916114, 17845);

DELETE FROM `creature_questender` WHERE `quest` IN (17840, 17845);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES
(9916113, 17840),
(9916114, 17845);

-- POI for the hidden quest so the client has an area to work from as well
DELETE FROM `quest_poi` WHERE `QuestID` IN (17840, 17845);
DELETE FROM `quest_poi_points` WHERE `QuestID` IN (17840, 17845);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`) VALUES
(17840, 0, 0, 1, 181, 0, 0, 3),
(17840, 1, 1, 0, 26, 0, 0, 3),
(17840, 2, 2, 1, 121, 0, 0, 3),
(17845, 0, 0, 1, 181, 0, 0, 3),
(17845, 1, 1, 0, 26, 0, 0, 3),
(17845, 2, 2, 1, 121, 0, 0, 3);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`) VALUES
(17840, 0, 0, 2250, -6900), (17840, 0, 1, 2375, -6900), (17840, 0, 2, 2375, -6770), (17840, 0, 3, 2250, -6770),
(17840, 1, 0, 85, -4620), (17840, 1, 1, 240, -4620), (17840, 1, 2, 240, -4400), (17840, 1, 3, 85, -4400),
(17840, 2, 0, -3970, 1900), (17840, 2, 1, -3640, 1900), (17840, 2, 2, -3640, 2040), (17840, 2, 3, -3970, 2040),
(17845, 0, 0, 2250, -6900), (17845, 0, 1, 2375, -6900), (17845, 0, 2, 2375, -6770), (17845, 0, 3, 2250, -6770),
(17845, 1, 0, 85, -4620), (17845, 1, 1, 240, -4620), (17845, 1, 2, 240, -4400), (17845, 1, 3, 85, -4400),
(17845, 2, 0, -3970, 1900), (17845, 2, 1, -3640, 1900), (17845, 2, 2, -3640, 2040), (17845, 2, 3, -3970, 2040);
