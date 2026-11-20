-- Append Karazhan after the open-ended Mythic Naxxramas bracket.
CREATE TEMPORARY TABLE `_coa_karazhan_manastorm_caches` LIKE `item_template`;
DELETE FROM `_coa_karazhan_manastorm_caches`;
INSERT INTO `_coa_karazhan_manastorm_caches`
SELECT * FROM `item_template` WHERE `entry` IN (1278083, 1278084);

UPDATE `_coa_karazhan_manastorm_caches`
SET `entry` = 1278085, `name` = 'Manastorm Cache: Mythic Karazhan', `description` = ''
WHERE `entry` = 1278083;

UPDATE `_coa_karazhan_manastorm_caches`
SET `entry` = 1278086, `name` = 'Manastorm Cache: Ascended Karazhan', `description` = ''
WHERE `entry` = 1278084;

START TRANSACTION;

INSERT IGNORE INTO `item_template`
SELECT * FROM `_coa_karazhan_manastorm_caches`;

DELETE FROM `reference_loot_template` WHERE `Entry` IN (9004001, 9004002);
INSERT INTO `reference_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`,
    `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT 9004001, `item`.`entry`, 0, 0, 0, 1, 1, 1, 1, 'Mythic Karazhan'
FROM `ascension_callboard_cache_reward` AS `source`
JOIN `item_template` AS `item` ON `item`.`entry` = `source`.`RewardItemId` + 1300000
WHERE `source`.`CacheItemId` = 1615014 AND `item`.`ItemLevel` > 99
UNION ALL
SELECT 9004002, `item`.`entry`, 0, 0, 0, 1, 1, 1, 1, 'Ascended Karazhan'
FROM `ascension_callboard_cache_reward` AS `source`
JOIN `item_template` AS `item` ON `item`.`entry` = `source`.`RewardItemId` + 200000
WHERE `source`.`CacheItemId` = 1615014 AND `item`.`ItemLevel` > 101;

DELETE FROM `item_loot_template` WHERE `Entry` IN (1278085, 1278086);
INSERT INTO `item_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`,
    `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(1278085, 1, 9004001, 100, 0, 1, 1, 1, 1, 'Mythic Karazhan'),
(1278086, 1, 9004002, 100, 0, 1, 1, 1, 1, 'Ascended Karazhan');

UPDATE `manastorm_cache_bracket`
SET `max_value` = 2000
WHERE `bracket_id` = 1027 AND `min_value` = 1901 AND `cache_item_entry` = 1278083;

DELETE FROM `manastorm_cache_bracket` WHERE `bracket_id` IN (1028, 1029);
INSERT INTO `manastorm_cache_bracket`
    (`bracket_id`, `track`, `selector_kind`, `min_value`, `max_value`, `cache_item_entry`, `enabled`, `comment`)
VALUES
(1028, 2, 2, 2001, 2100, 1278085, 1, 'Mythic Karazhan'),
(1029, 2, 2, 2101, 4294967295, 1278086, 1, 'Ascended Karazhan');

DELETE FROM `manastorm_cache_unlock_requirement` WHERE `track` = 2 AND `item_entry` IN (1278085, 1278086);
INSERT INTO `manastorm_cache_unlock_requirement` (`item_entry`, `track`, `required_completed_depth`, `enabled`) VALUES
(1278085, 2, 2000, 1),
(1278086, 2, 2100, 1);

COMMIT;

DROP TEMPORARY TABLE `_coa_karazhan_manastorm_caches`;
