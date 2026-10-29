-- Match the shape of CoA's own custom quests: one objective line, an empty (not
-- NULL) AreaDescription, and a build stamp.
UPDATE `quest_template`
SET `AreaDescription` = '',
    `VerifiedBuild` = 12340,
    `ObjectiveText1` = 'The three apex hides',
    `ObjectiveText2` = NULL,
    `ObjectiveText3` = NULL,
    `ObjectiveText4` = NULL
WHERE `ID` IN (17839, 17844);
