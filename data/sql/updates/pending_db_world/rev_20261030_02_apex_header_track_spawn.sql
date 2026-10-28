-- Header: QuestSortID is an AreaTable id; 0 renders "Missing header!".
UPDATE `quest_template` SET `QuestSortID` = 1519 WHERE `ID` = 17839;
UPDATE `quest_template` SET `QuestSortID` = 1637 WHERE `ID` = 17844;

-- A super track arrow only exists for objectives 0..3 (NPC/GO) and -1 (turn in);
-- item objectives are numbered 4..9 and have no slot. Keep the log reading as the
-- three hides by naming the kill objectives after them.
UPDATE `quest_template`
SET `RequiredNpcOrGo1` = 9916214, `RequiredNpcOrGoCount1` = 1,
    `RequiredNpcOrGo2` = 9916212, `RequiredNpcOrGoCount2` = 1,
    `RequiredNpcOrGo3` = 9916213, `RequiredNpcOrGoCount3` = 1,
    `ObjectiveText1` = 'Tide-Warped Hide',
    `ObjectiveText2` = 'Stormfang Pelt',
    `ObjectiveText3` = 'Scarred Owlcat Pelt',
    `RequiredItemId1` = 0, `RequiredItemId2` = 0, `RequiredItemId3` = 0
WHERE `ID` IN (17839, 17844);

UPDATE `quest_poi` SET `ObjectiveIndex` = 0 WHERE `QuestID` IN (17839, 17844) AND `id` = 0;
UPDATE `quest_poi` SET `ObjectiveIndex` = 1 WHERE `QuestID` IN (17839, 17844) AND `id` = 1;
UPDATE `quest_poi` SET `ObjectiveIndex` = 2 WHERE `QuestID` IN (17839, 17844) AND `id` = 2;

DELETE FROM `coa_client_quest_super_track` WHERE `ID` IN (10130, 10133);
INSERT INTO `coa_client_quest_super_track` (`ID`, `QuestID`, `ObjectiveIndex`, `NodeIndex`, `SuperTrackID`) VALUES
(10130, 17839, 0, 0, 21505),
(10130, 17839, 1, 0, 21508),
(10130, 17839, 2, 0, 21523),
(10130, 17839, -1, 0, 21589),
(10133, 17844, 0, 0, 21505),
(10133, 17844, 1, 0, 21508),
(10133, 17844, 2, 0, 21523),
(10133, 17844, -1, 0, 21603);

-- Keep the three apexes present; an hour between attempts made them look missing.
UPDATE `creature` SET `spawntimesecs` = 300 WHERE `id` IN (9916212, 9916213, 9916214);
