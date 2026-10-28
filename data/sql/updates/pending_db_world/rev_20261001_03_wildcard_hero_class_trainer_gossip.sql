-- A Wildcard Hero trains the ranks of what it knows at any class trainer (Trainer::GetTrainerFor), but each class
-- trainer showed its training option to its own class only. A second condition group shows it to class 10 as well;
-- Trainer::IsTrainerValidForPlayer still hides it from a Hero not playing Wildcard.
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 15 AND `ElseGroup` = 10 AND `ConditionTypeOrReference` = 15
    AND `ConditionValue1` = 512 AND `Comment` = 'Wildcard Hero: training option at every class trainer';
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
    `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
    `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
SELECT DISTINCT 15, `c`.`SourceGroup`, `c`.`SourceEntry`, 0, 10, 15, 0, 512, 0, 0, 0, 0, 0, '',
    'Wildcard Hero: training option at every class trainer'
FROM `conditions` AS `c`
JOIN `gossip_menu_option` AS `o` ON `o`.`MenuID` = `c`.`SourceGroup` AND `o`.`OptionID` = `c`.`SourceEntry`
WHERE `c`.`SourceTypeOrReferenceId` = 15 AND `c`.`ConditionTypeOrReference` = 15 AND `c`.`NegativeCondition` = 0
    AND `c`.`ElseGroup` = 0 AND `o`.`OptionType` = 5;
