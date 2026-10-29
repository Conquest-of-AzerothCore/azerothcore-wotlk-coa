-- Quest-objective ring and per-boss arrow come from RequiredNpcOrGo; completion on
-- pickup comes from RequiredItemId. Both are needed, and the kill objective carries no
-- text of its own, so the log names it from the creature rather than saying "slain".
UPDATE `quest_template`
SET `RequiredNpcOrGo1` = 9916214, `RequiredNpcOrGoCount1` = 1,
    `RequiredNpcOrGo2` = 9916212, `RequiredNpcOrGoCount2` = 1,
    `RequiredNpcOrGo3` = 9916213, `RequiredNpcOrGoCount3` = 1,
    `ObjectiveText1` = '', `ObjectiveText2` = '', `ObjectiveText3` = '',
    `RequiredItemId1` = 1009304, `RequiredItemCount1` = 1,
    `RequiredItemId2` = 1009302, `RequiredItemCount2` = 1,
    `RequiredItemId3` = 1009303, `RequiredItemCount3` = 1
WHERE `ID` IN (17839, 17844);
