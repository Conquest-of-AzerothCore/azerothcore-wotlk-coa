START TRANSACTION;

UPDATE `dungeon_access_template`
SET `min_level` = 60
WHERE `map_id` = 533 AND `difficulty` BETWEEN 0 AND 3;

DELETE FROM `dungeon_access_template` WHERE `id` = 0 AND `map_id` = 0;
INSERT INTO `dungeon_access_template`
    (`map_id`, `difficulty`, `min_level`, `max_level`, `min_avg_item_level`, `comment`)
SELECT 533, `mode`.`difficulty`, 60, 0, 0, `mode`.`comment`
FROM (
    SELECT 2 AS `difficulty`, 'Naxxramas - Mythic' AS `comment`
    UNION ALL SELECT 3, 'Naxxramas - Ascended'
) AS `mode`
LEFT JOIN `dungeon_access_template` AS `existing`
    ON `existing`.`map_id` = 533 AND `existing`.`difficulty` = `mode`.`difficulty`
WHERE `existing`.`id` IS NULL;

COMMIT;
