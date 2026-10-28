-- Only the hunt quest exists. No contract, no breadcrumb, and the quest no longer
-- advertises a title: the module grants it when the quest is completed instead.

DELETE FROM `creature_queststarter` WHERE `quest` IN (9916200, 9916210);
DELETE FROM `creature_questender` WHERE `quest` IN (9916200, 9916210);
DELETE FROM `quest_template` WHERE `ID` IN (9916200, 9916210);

DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 19 AND `SourceEntry` IN (9916201, 9916211);

UPDATE `quest_template`
SET `RewardTitle` = 0
WHERE `ID` IN (9916201, 9916211);
