-- Blackwing Lair raid gear uses distinct item families for Heroic, Mythic and Ascended.
START TRANSACTION;

DROP TEMPORARY TABLE IF EXISTS `_coa_bwl_loot_tiers`;
CREATE TEMPORARY TABLE `_coa_bwl_loot_tiers` (
    `creature_offset` INT UNSIGNED PRIMARY KEY,
    `gear_offset` INT UNSIGNED NOT NULL,
    `token_offset` INT UNSIGNED NOT NULL
) ENGINE=InnoDB;
DELETE FROM `_coa_bwl_loot_tiers`;
INSERT INTO `_coa_bwl_loot_tiers` VALUES
(100000, 300000, 100000),
(200000, 1300000, 1200000),
(300000, 200000, 200000);

DROP TEMPORARY TABLE IF EXISTS `_coa_bwl_gear_pools`;
CREATE TEMPORARY TABLE `_coa_bwl_gear_pools` (
    `base_pool` INT UNSIGNED PRIMARY KEY,
    `pool_suffix` INT UNSIGNED NOT NULL
) ENGINE=InnoDB;
DELETE FROM `_coa_bwl_gear_pools`;
INSERT INTO `_coa_bwl_gear_pools` VALUES
(30337, 30337), (30341, 30341), (30348, 30348), (30371, 30371), (30374, 30374),
(30380, 30380), (30382, 30382), (30395, 30395), (30487, 30487), (30551, 30551), (90030342, 30342);

DELETE FROM `reference_loot_template` WHERE `Entry` IN (
    90130337, 90130341, 90130342, 90130348, 90130371, 90130374, 90130380, 90130382, 90130395, 90130487, 90130551,
    90230337, 90230341, 90230342, 90230348, 90230371, 90230374, 90230380, 90230382, 90230395, 90230487, 90230551,
    90330337, 90330341, 90330342, 90330348, 90330371, 90330374, 90330380, 90330382, 90330395, 90330487, 90330551);
INSERT INTO `reference_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`,
    `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT 90000000 + `tier`.`creature_offset` + `pool`.`pool_suffix`, `source`.`Item` + `tier`.`gear_offset`,
    `source`.`Reference`, `source`.`Chance`, `source`.`QuestRequired`, `source`.`LootMode`,
    `source`.`GroupId`, `source`.`MinCount`, `source`.`MaxCount`, `source`.`Comment`
FROM `reference_loot_template` AS `source`
JOIN `_coa_bwl_gear_pools` AS `pool` ON `pool`.`base_pool` = `source`.`Entry`
CROSS JOIN `_coa_bwl_loot_tiers` AS `tier`;

UPDATE `creature_loot_template` AS `loot`
JOIN `_coa_bwl_loot_tiers` AS `tier`
    ON `loot`.`Entry` - (`loot`.`Entry` % 100000) = `tier`.`creature_offset`
JOIN `_coa_bwl_gear_pools` AS `pool` ON `loot`.`Reference` = `pool`.`base_pool`
SET `loot`.`Item` = 90000000 + `tier`.`creature_offset` + `pool`.`pool_suffix`,
    `loot`.`Reference` = 90000000 + `tier`.`creature_offset` + `pool`.`pool_suffix`
WHERE (`loot`.`Entry` % 100000) IN (11583, 11981, 11983, 12017, 12435, 13020, 14020, 14601);

UPDATE `creature_loot_template` AS `loot`
JOIN `_coa_bwl_loot_tiers` AS `tier`
    ON `loot`.`Entry` - (`loot`.`Entry` % 100000) = `tier`.`creature_offset`
SET `loot`.`Item` = 2500000 + (`loot`.`Item` % 100000) + `tier`.`token_offset`
WHERE (`loot`.`Entry` % 100000) IN (11583, 11981, 11983, 12017, 12435, 13020, 14020, 14601)
    AND `loot`.`Comment` = 'BWL Chromatic tier token';

DELETE FROM `creature_loot_template` WHERE `Entry` IN (
    112457, 112459, 112460, 112461, 112463, 112464, 112465, 112467,
    212457, 212459, 212460, 212461, 212463, 212464, 212465, 212467,
    312457, 312459, 312460, 312461, 312463, 312464, 312465, 312467);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`,
    `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT `source`.`Entry` + `tier`.`creature_offset`,
    CASE WHEN `source`.`Reference` = 0 AND `source`.`Item` IN (19354, 19358, 19362)
         THEN `source`.`Item` + `tier`.`gear_offset` ELSE `source`.`Item` END,
    `source`.`Reference`, `source`.`Chance`, `source`.`QuestRequired`, `source`.`LootMode`,
    `source`.`GroupId`, `source`.`MinCount`, `source`.`MaxCount`, `source`.`Comment`
FROM `creature_loot_template` AS `source`
CROSS JOIN `_coa_bwl_loot_tiers` AS `tier`
WHERE `source`.`Entry` IN (12457, 12459, 12460, 12461, 12463, 12464, 12465, 12467);

UPDATE `creature_template` AS `creature`
JOIN `_coa_bwl_loot_tiers` AS `tier`
    ON `creature`.`entry` - (`creature`.`entry` % 100000) = `tier`.`creature_offset`
SET `creature`.`lootid` = `creature`.`entry`
WHERE (`creature`.`entry` % 100000) IN (12457, 12459, 12460, 12461, 12463, 12464, 12465, 12467);

DROP TEMPORARY TABLE `_coa_bwl_gear_pools`;
DROP TEMPORARY TABLE `_coa_bwl_loot_tiers`;

COMMIT;
