-- Replace only the Naxxramas root links to Wrath-tier tokens. The shared reference
-- pools themselves remain available to other encounters. Map 533 resolves the base
-- token to the difficulty's vendor item when a corpse or chest is opened.
START TRANSACTION;

CREATE TEMPORARY TABLE `_coa_naxx_token_sources` (
    `loot_id` INT UNSIGNED NOT NULL, `token` INT UNSIGNED NOT NULL,
    `group_id` TINYINT UNSIGNED NOT NULL, `chance` FLOAT NOT NULL, `count` TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (`loot_id`, `token`)
) ENGINE=InnoDB;

DELETE FROM `_coa_naxx_token_sources`;
INSERT INTO `_coa_naxx_token_sources` VALUES
(15928, 22353, 0, 100, 1),
(15931, 22354, 0, 100, 1),
(15932, 22349, 1, 0, 1),
(15932, 22352, 1, 0, 1),
(15932, 22354, 1, 0, 1),
(15936, 22356, 0, 100, 1),
(15952, 22357, 0, 100, 1),
(15953, 22355, 0, 100, 1),
(15954, 22356, 0, 100, 1),
(15956, 22355, 0, 100, 1),
(15990, 1510496, 0, 100, 1),
(16011, 22352, 0, 100, 1),
(16028, 22354, 0, 100, 1),
(16060, 22358, 0, 100, 1),
(16061, 22358, 0, 100, 1),
(29249, 22355, 0, 100, 2),
(29268, 22355, 0, 100, 2),
(29278, 22357, 0, 100, 2),
(29324, 22354, 0, 100, 2),
(29373, 22354, 0, 100, 2),
(29417, 22349, 1, 0, 1),
(29417, 22352, 1, 0, 1),
(29417, 22354, 1, 0, 1),
(29448, 22353, 0, 100, 2),
(29615, 22356, 0, 100, 2),
(29701, 22356, 0, 100, 2),
(29718, 22352, 0, 100, 2),
(29940, 22358, 0, 100, 2),
(29955, 22358, 0, 100, 2),
(30061, 1510496, 0, 100, 1);

DELETE FROM `creature_loot_template`
WHERE `Entry` IN (SELECT `loot_id` FROM `_coa_naxx_token_sources`)
    AND ((`Reference` = 0 AND (`Item` BETWEEN 40610 AND 40639 OR `Item` IN (22349, 22352, 22353, 22354, 22355, 22356, 22357, 22358, 1510496)))
        OR `Reference` IN (34133, 34377, 34380, 34381, 34382, 34383, 35087));
INSERT INTO `creature_loot_template`
    (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT `loot_id`, `token`, 0, `chance`, 0, 1, `group_id`, `count`, `count`, 'Naxxramas Tier 3 exchange'
FROM `_coa_naxx_token_sources`;

DELETE FROM `gameobject_loot_template`
WHERE `Entry` IN (25192, 25193)
    AND ((`Reference` = 0 AND (`Item` BETWEEN 40610 AND 40639 OR `Item` = 22349)) OR `Reference` = 34382);
INSERT INTO `gameobject_loot_template`
    (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
    (25192, 22349, 0, 100, 0, 1, 0, 1, 1, 'Four Horsemen Tier 3 chest token'),
    (25193, 22349, 0, 100, 0, 1, 0, 2, 2, 'Four Horsemen Tier 3 chest tokens');

DROP TEMPORARY TABLE `_coa_naxx_token_sources`;

COMMIT;
