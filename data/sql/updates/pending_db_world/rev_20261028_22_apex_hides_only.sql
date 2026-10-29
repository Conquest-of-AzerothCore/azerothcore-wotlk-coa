-- Only the three hides are objectives. The supertrack arrow works off the quest
-- POI and the node chains, not off extra kill objectives.
UPDATE `quest_template`
SET `RequiredNpcOrGo1` = 0, `RequiredNpcOrGoCount1` = 0,
    `RequiredNpcOrGo2` = 0, `RequiredNpcOrGoCount2` = 0,
    `RequiredNpcOrGo3` = 0, `RequiredNpcOrGoCount3` = 0,
    `RequiredNpcOrGo4` = 0, `RequiredNpcOrGoCount4` = 0,
    `ObjectiveText1` = '', `ObjectiveText2` = '', `ObjectiveText3` = '', `ObjectiveText4` = ''
WHERE `ID` IN (9916201, 9916211);
