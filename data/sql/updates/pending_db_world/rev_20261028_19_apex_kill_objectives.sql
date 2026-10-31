-- A supertrack arrow is drawn per objective, and only objectives with a world
-- target can carry one. The quest therefore tracks the three kills as well as
-- the hides, which is how base quests are shaped.
UPDATE `quest_template`
SET `RequiredNpcOrGo1` = 9916214, `RequiredNpcOrGoCount1` = 1,
    `RequiredNpcOrGo2` = 9916212, `RequiredNpcOrGoCount2` = 1,
    `RequiredNpcOrGo3` = 9916213, `RequiredNpcOrGoCount3` = 1,
    `ObjectiveText1` = 'Nytharos slain',
    `ObjectiveText2` = 'Stormfang slain',
    `ObjectiveText3` = 'Vaelthara slain',
    `ObjectiveText4` = 'Hides returned'
WHERE `ID` IN (9916201, 9916211);
