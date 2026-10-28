UPDATE `creature_template` AS `target`
INNER JOIN (
    SELECT `RequiredNpcOrGo1` AS `entry` FROM `quest_template`
    WHERE `RequiredNpcOrGo1` > 0 AND `RequiredNpcOrGoCount1` = 1
    UNION
    SELECT `RequiredNpcOrGo2` AS `entry` FROM `quest_template`
    WHERE `RequiredNpcOrGo2` > 0 AND `RequiredNpcOrGoCount2` = 1
    UNION
    SELECT `RequiredNpcOrGo3` AS `entry` FROM `quest_template`
    WHERE `RequiredNpcOrGo3` > 0 AND `RequiredNpcOrGoCount3` = 1
    UNION
    SELECT `RequiredNpcOrGo4` AS `entry` FROM `quest_template`
    WHERE `RequiredNpcOrGo4` > 0 AND `RequiredNpcOrGoCount4` = 1
    UNION
    SELECT `source`.`entry` AS `entry`
    FROM `creature_template` AS `source`
    INNER JOIN `creature_loot_template` AS `drop` ON `drop`.`Entry` = `source`.`lootid`
    INNER JOIN (
        SELECT `RequiredItemId1` AS `item` FROM `quest_template`
        WHERE `RequiredItemId1` > 0 AND `RequiredItemCount1` = 1
        UNION
        SELECT `RequiredItemId2` AS `item` FROM `quest_template`
        WHERE `RequiredItemId2` > 0 AND `RequiredItemCount2` = 1
        UNION
        SELECT `RequiredItemId3` AS `item` FROM `quest_template`
        WHERE `RequiredItemId3` > 0 AND `RequiredItemCount3` = 1
        UNION
        SELECT `RequiredItemId4` AS `item` FROM `quest_template`
        WHERE `RequiredItemId4` > 0 AND `RequiredItemCount4` = 1
        UNION
        SELECT `RequiredItemId5` AS `item` FROM `quest_template`
        WHERE `RequiredItemId5` > 0 AND `RequiredItemCount5` = 1
        UNION
        SELECT `RequiredItemId6` AS `item` FROM `quest_template`
        WHERE `RequiredItemId6` > 0 AND `RequiredItemCount6` = 1
    ) AS `objective` ON `objective`.`item` = `drop`.`Item`
    INNER JOIN (
        SELECT `unique_drop`.`Item`
        FROM `creature_loot_template` AS `unique_drop`
        INNER JOIN `creature_template` AS `unique_source` ON `unique_source`.`lootid` = `unique_drop`.`Entry`
        WHERE `unique_drop`.`Reference` = 0
        GROUP BY `unique_drop`.`Item`
        HAVING COUNT(DISTINCT `unique_source`.`entry`) = 1
    ) AS `exclusive_item` ON `exclusive_item`.`Item` = `drop`.`Item`
    WHERE `drop`.`Reference` = 0
    UNION
    SELECT `source`.`CreatureEntry` AS `entry`
    FROM `creature_questitem` AS `source`
    INNER JOIN (
        SELECT `RequiredItemId1` AS `item` FROM `quest_template`
        WHERE `RequiredItemId1` > 0 AND `RequiredItemCount1` = 1
        UNION
        SELECT `RequiredItemId2` AS `item` FROM `quest_template`
        WHERE `RequiredItemId2` > 0 AND `RequiredItemCount2` = 1
        UNION
        SELECT `RequiredItemId3` AS `item` FROM `quest_template`
        WHERE `RequiredItemId3` > 0 AND `RequiredItemCount3` = 1
        UNION
        SELECT `RequiredItemId4` AS `item` FROM `quest_template`
        WHERE `RequiredItemId4` > 0 AND `RequiredItemCount4` = 1
        UNION
        SELECT `RequiredItemId5` AS `item` FROM `quest_template`
        WHERE `RequiredItemId5` > 0 AND `RequiredItemCount5` = 1
        UNION
        SELECT `RequiredItemId6` AS `item` FROM `quest_template`
        WHERE `RequiredItemId6` > 0 AND `RequiredItemCount6` = 1
    ) AS `objective` ON `objective`.`item` = `source`.`ItemId`
    INNER JOIN (
        SELECT `ItemId` FROM `creature_questitem`
        GROUP BY `ItemId`
        HAVING COUNT(DISTINCT `CreatureEntry`) = 1
    ) AS `exclusive_item` ON `exclusive_item`.`ItemId` = `source`.`ItemId`
) AS `quest_target`
    ON `quest_target`.`entry` IN (`target`.`entry`, `target`.`KillCredit1`, `target`.`KillCredit2`)
SET `target`.`type_flags` = `target`.`type_flags` | 2147483648;
