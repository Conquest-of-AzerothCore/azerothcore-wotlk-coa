-- Standard "collect from a mob" shape: only the item objectives exist, so the log is
-- the three pelts and each one completes when it is picked up. No kill objectives,
-- therefore no "slain" lines.
UPDATE `quest_template`
SET `RequiredNpcOrGo1` = 0, `RequiredNpcOrGoCount1` = 0,
    `RequiredNpcOrGo2` = 0, `RequiredNpcOrGoCount2` = 0,
    `RequiredNpcOrGo3` = 0, `RequiredNpcOrGoCount3` = 0,
    `ObjectiveText1` = NULL, `ObjectiveText2` = NULL, `ObjectiveText3` = NULL
WHERE `ID` IN (17839, 17844);
