START TRANSACTION;

UPDATE `item_template` SET `startquest` = 7490 WHERE `entry` = 18422;
UPDATE `item_template` SET `startquest` = 7495 WHERE `entry` = 18423;
UPDATE `item_template` SET `startquest` = 7783 WHERE `entry` = 19002;
UPDATE `item_template` SET `startquest` = 7781 WHERE `entry` = 19003;

DELETE FROM `creature_questender` WHERE (`id`, `quest`) IN ((4949, 7490), (29611, 7495), (14392, 7491), (14394, 7496));
INSERT INTO `creature_questender` (`id`, `quest`) VALUES
(4949, 7490), (29611, 7495), (14392, 7491), (14394, 7496);

DELETE FROM `creature_queststarter` WHERE (`id`, `quest`) IN ((4949, 7491), (29611, 7496));
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES
(4949, 7491), (29611, 7496);

DELETE FROM `creature_loot_template` WHERE `Entry` IN (10184, 110184, 210184, 310184) AND `Item` = 18423;
INSERT INTO `creature_loot_template`
    (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT `Entry`, 18423, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`,
    'Onyxia - Head of Onyxia (Alliance)'
FROM `creature_loot_template`
WHERE `Entry` IN (10184, 110184, 210184, 310184) AND `Item` = 18422 AND `Reference` = 0;

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 1 AND `ConditionTypeOrReference` = 6
    AND ((`SourceGroup` IN (10184, 110184, 210184, 310184) AND `SourceEntry` IN (18422, 18423))
        OR (`SourceGroup` IN (11583, 111583, 211583, 311583) AND `SourceEntry` IN (19002, 19003)));
INSERT INTO `conditions`
    (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `ConditionTypeOrReference`, `ConditionValue1`, `Comment`)
SELECT 1, `loot`.`Entry`, `loot`.`Item`, 6,
    IF(`loot`.`Item` IN (18422, 19002), 67, 469), 'Classic raid head matches the looting player faction'
FROM `creature_loot_template` AS `loot`
WHERE `loot`.`Reference` = 0 AND `loot`.`GroupId` = 0
    AND ((`loot`.`Entry` IN (10184, 110184, 210184, 310184) AND `loot`.`Item` IN (18422, 18423))
        OR (`loot`.`Entry` IN (11583, 111583, 211583, 311583) AND `loot`.`Item` IN (19002, 19003)));

COMMIT;
