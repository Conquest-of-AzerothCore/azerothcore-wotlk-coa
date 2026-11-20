START TRANSACTION;

-- Harmonize Bloodforged signets with the corresponding rescaled Violet Eye reward.
UPDATE `item_template` AS `bloodforged`
JOIN `item_template` AS `signet` ON `bloodforged`.`entry` = `signet`.`entry` + 6000000
SET `bloodforged`.`RequiredLevel` = `signet`.`RequiredLevel`,
    `bloodforged`.`ItemLevel` = `signet`.`ItemLevel`,
    `bloodforged`.`stat_value1` = `signet`.`stat_value1`, `bloodforged`.`stat_value2` = `signet`.`stat_value2`,
    `bloodforged`.`stat_value3` = `signet`.`stat_value3`, `bloodforged`.`stat_value4` = `signet`.`stat_value4`,
    `bloodforged`.`stat_value5` = `signet`.`stat_value5`, `bloodforged`.`stat_value6` = `signet`.`stat_value6`,
    `bloodforged`.`stat_value7` = `signet`.`stat_value7`, `bloodforged`.`stat_value8` = `signet`.`stat_value8`,
    `bloodforged`.`stat_value9` = `signet`.`stat_value9`, `bloodforged`.`stat_value10` = `signet`.`stat_value10`
WHERE `signet`.`entry` BETWEEN 15097 AND 15100 OR `signet`.`entry` BETWEEN 29276 AND 29291;

-- Benchmarks are the Normal Karazhan armor values and level-60 Icebane frost-resistance gear.
UPDATE `item_template` AS `item`
JOIN (
    SELECT 31369 AS `entry`, 88 AS `ilvl`, 864 AS `armor`, 30 AS `frost`, 37 AS `s1`, 8 AS `s2`, 0 AS `s3`, 0 AS `s4`
    UNION ALL SELECT 31370, 90, 774, 32, 41, 0, 0, 0
    UNION ALL SELECT 31371, 88, 703, 28, 44, 14, 0, 0
    UNION ALL SELECT 31398, 88, 0, 25, 12, 0, 0, 0
    UNION ALL SELECT 33122, 92, 233, 0, 14, 22, 19, 0
    UNION ALL SELECT 33204, 90, 595, 0, 28, 10, 13, 46
) AS `budget` ON `item`.`entry` IN (`budget`.`entry`, `budget`.`entry` + 6000000)
SET `item`.`RequiredLevel` = 60, `item`.`ItemLevel` = `budget`.`ilvl`,
    `item`.`armor` = `budget`.`armor`, `item`.`frost_res` = `budget`.`frost`,
    `item`.`stat_value1` = `budget`.`s1`, `item`.`stat_value2` = `budget`.`s2`,
    `item`.`stat_value3` = `budget`.`s3`, `item`.`stat_value4` = `budget`.`s4`;

UPDATE `item_template`
SET `RequiredLevel` = CASE WHEN `RequiredLevel` > 60 THEN 60 ELSE `RequiredLevel` END,
    `ItemLevel` = CASE `RequiredReputationRank` WHEN 5 THEN 88 WHEN 6 THEN 90 WHEN 7 THEN 92 ELSE `ItemLevel` END
WHERE `entry` IN (29187, 31393, 31394, 31395, 31401, 33124, 33165, 33205, 33209);

UPDATE `item_template`
SET `RequiredLevel` = 60
WHERE `entry` IN (33208, 6033208) AND `RequiredLevel` > 60;

-- Keep Revered ammunition above the existing 26-DPS Fel Iron Shells.
UPDATE `item_template`
SET `RequiredLevel` = 60, `ItemLevel` = 90, `dmg_min1` = 28, `dmg_max1` = 28
WHERE `entry` IN (34581, 34582);

-- The Endurance inscription has a separate level gate in its enchantment record.
DELETE FROM `spellitemenchantment_dbc` WHERE `ID` = 2998;
INSERT INTO `spellitemenchantment_dbc`
    (`ID`, `Effect_1`, `EffectArg_1`, `Name_Lang_enUS`, `Name_Lang_Mask`, `Flags`, `MinLevel`)
VALUES
    (2998, 3, 35442, '+7 All Resistances.', 16712190, 1, 60);

COMMIT;
