-- The objective completes when the hide is looted, so the quest needs item
-- requirements again. The arrow to each boss is pushed separately: super track slot
-- 4 is the turn-in node only (stock quest 2 proves it), so it cannot point at items.
UPDATE `quest_template`
SET `RequiredNpcOrGo1` = 0, `RequiredNpcOrGoCount1` = 0,
    `RequiredNpcOrGo2` = 0, `RequiredNpcOrGoCount2` = 0,
    `RequiredNpcOrGo3` = 0, `RequiredNpcOrGoCount3` = 0,
    `RequiredItemId1` = 1009304, `RequiredItemCount1` = 1,
    `RequiredItemId2` = 1009302, `RequiredItemCount2` = 1,
    `RequiredItemId3` = 1009303, `RequiredItemCount3` = 1,
    `ObjectiveText1` = '', `ObjectiveText2` = '', `ObjectiveText3` = ''
WHERE `ID` IN (17839, 17844);

-- Item objectives are numbered from 4, and several areas may share one index.
UPDATE `quest_poi` SET `ObjectiveIndex` = 4 WHERE `QuestID` IN (17839, 17844) AND `id` IN (0, 1, 2);
UPDATE `quest_poi` SET `ObjectiveIndex` = -1 WHERE `QuestID` IN (17839, 17844) AND `id` = 3;

-- Return arrow: slot 4 is the turn-in node.
DELETE FROM `coa_client_quest_super_track` WHERE `ID` IN (10130, 10133);
INSERT INTO `coa_client_quest_super_track` (`ID`, `QuestID`, `ObjectiveIndex`, `NodeIndex`, `SuperTrackID`) VALUES
(10130, 17839, -1, 0, 21589),
(10133, 17844, -1, 0, 21603);
