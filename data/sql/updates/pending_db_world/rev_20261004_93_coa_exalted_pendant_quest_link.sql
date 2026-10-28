-- An Exalted Pendant 2300515 sparkled and stayed clickable for the whole of Death and Dishonor 1660032 because its
-- chest questId (Data8) names the quest. Without it, a pendant is active only while the player still needs one.
UPDATE `gameobject_template` SET `Data8` = 0 WHERE `entry` = 2300515;

-- Pendants show only to a player on Death and Dishonor, and can be clicked only while the player still needs one
-- (GO_FLAG_INTERACT_COND: the client needs the server's activation, which follows the quest loot).
DELETE FROM `gameobject_template_addon` WHERE `entry` = 2300515;
INSERT INTO `gameobject_template_addon` (`entry`, `faction`, `flags`, `mingold`, `maxgold`, `artkit0`, `artkit1`,
    `artkit2`, `artkit3`) VALUES
(2300515, 0, 4, 0, 0, 0, 0, 0, 0);

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 30 AND `SourceGroup` = 1 AND `SourceEntry` = 2300515;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
    `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
    `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(30, 1, 2300515, 0, 0, 47, 0, 1660032, 8, 0, 0, 0, 0, '', 'Exalted Pendant shows only while Death and Dishonor is in progress');
