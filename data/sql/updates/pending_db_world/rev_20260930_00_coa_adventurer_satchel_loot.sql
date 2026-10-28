UPDATE `item_template` SET `Flags` = `Flags` | 4, `ScriptName` = 'item_ascension_adventurer_cache'
WHERE `entry` IN (1397884, 1397886);

DELETE FROM `item_loot_template` WHERE `Entry` IN (1397884, 1397886);
INSERT INTO `item_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
`MinCount`, `MaxCount`, `Comment`)
SELECT `pool`.`Entry`, `item`.`entry`, 0, 0, 0, 1, 1, 1, CASE WHEN `item`.`class` = 4 THEN 1 ELSE 3 END,
'Adventurer satchel and rare cache - local supplies and world-drop armor'
FROM `item_template` AS `item`
JOIN (SELECT 1397884 AS `Entry`, 1 AS `MinQuality`, 2 AS `MaxQuality`
UNION ALL SELECT 1397886, 3, 3) AS `pool`
WHERE (`item`.`entry` IN
(117, 2287, 3770, 3771, 4599, 8952, 159, 1179, 1205, 1708, 1645, 8766,
118, 858, 929, 1710, 3928, 13446, 2455, 3385, 3827, 6149, 13443,
2589, 2592, 4306, 4338, 14047, 2770, 2771, 2772, 3858, 10620,
2447, 2450, 3355, 3820, 8838, 2318, 2319, 4234, 4304, 8170))
OR (`item`.`class` = 4 AND `item`.`Quality` BETWEEN `pool`.`MinQuality` AND `pool`.`MaxQuality`
AND `item`.`bonding` IN (0, 2) AND `item`.`RequiredLevel` <= 60 AND `item`.`maxcount` = 0 AND `item`.`entry` IN
(SELECT `Item` FROM `reference_loot_template` WHERE `Reference` = 0 AND `Entry` BETWEEN 1010000 AND 1039999));
