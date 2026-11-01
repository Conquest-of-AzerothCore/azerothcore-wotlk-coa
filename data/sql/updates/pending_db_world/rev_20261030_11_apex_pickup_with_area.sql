-- Back to pickup completion: the objectives are the three hides again. The world-space
-- POI flag stays at 3, which is what draws the area on the ground (quest 33 carries it
-- on an item objective).
UPDATE `quest_template`
SET `RequiredNpcOrGo1` = 0, `RequiredNpcOrGoCount1` = 0,
    `RequiredNpcOrGo2` = 0, `RequiredNpcOrGoCount2` = 0,
    `RequiredNpcOrGo3` = 0, `RequiredNpcOrGoCount3` = 0,
    `ObjectiveText1` = NULL, `ObjectiveText2` = NULL, `ObjectiveText3` = NULL,
    `RequiredItemId1` = 1009304, `RequiredItemCount1` = 1,
    `RequiredItemId2` = 1009302, `RequiredItemCount2` = 1,
    `RequiredItemId3` = 1009303, `RequiredItemCount3` = 1
WHERE `ID` IN (17839, 17844);

-- item objectives are numbered from 4
UPDATE `quest_poi` SET `ObjectiveIndex` = 4 WHERE `QuestID` IN (17839, 17844) AND `id` = 0;
UPDATE `quest_poi` SET `ObjectiveIndex` = 5 WHERE `QuestID` IN (17839, 17844) AND `id` = 1;
UPDATE `quest_poi` SET `ObjectiveIndex` = 6 WHERE `QuestID` IN (17839, 17844) AND `id` = 2;

-- the item objectives cannot carry a node, only the turn-in can
DELETE FROM `coa_client_quest_super_track` WHERE `ID` IN (10130, 10133);
INSERT INTO `coa_client_quest_super_track` (`ID`, `QuestID`, `ObjectiveIndex`, `NodeIndex`, `SuperTrackID`) VALUES
(10130, 17839, -1, 0, 21589),
(10133, 17844, -1, 0, 21603);
