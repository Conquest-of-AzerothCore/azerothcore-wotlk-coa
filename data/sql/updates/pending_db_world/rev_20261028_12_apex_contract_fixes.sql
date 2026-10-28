-- Fixes after the first in-game look at the apex contract.

-- 1. QuestType 0 is not a normal quest; the client renders an empty detail pane
--    for it. Every stock quest uses 2.
UPDATE `quest_template` SET `QuestType` = 2 WHERE `ID` BETWEEN 9916200 AND 9916211;

-- 2. Match the shape of the rows the client already carries: model name is an
--    empty string, never NULL.
UPDATE `itemdisplayinfo_dbc` SET `ModelName_1` = '' WHERE `ID` BETWEEN 990002 AND 990005;

-- 3. The hunt was offered alongside the contract. Gate it on the contract being
--    rewarded, so the board reads as a two step contract.
DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 19 AND `SourceEntry` IN (9916201, 9916211);

INSERT INTO `conditions`
(`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
 `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`,
 `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(19, 0, 9916201, 0, 0, 8, 0, 9916200, 0, 0, 0, 0, 0, '', 'Apex: contract rewarded before the hunts (Alliance)'),
(19, 0, 9916211, 0, 0, 8, 0, 9916210, 0, 0, 0, 0, 0, '', 'Apex: contract rewarded before the hunts (Horde)');
