-- Follow-up to SQL 26 for caches 1278056, 1278058 and 1278060 only.
-- Reuses the installed SQL 26 item pools and preserves installed roll chances.
-- SQL 26 defaults: 10% optional families, 50% optional second Heroic MC item.
-- One explicit-chance group per family roll prevents global reference chance
-- rates changing its odds. The scoped C++ guard fixes one item per success.
-- Mythic 1-10 Dungeon gear remains intentional for 1278060's description.
-- No item templates, reference pools, conditions or progression are written.
-- Rebuild the module, apply SQL 26 first if absent, apply SQL 55, then restart.

DROP TEMPORARY TABLE IF EXISTS `tmp_ms_mc_roll`;
CREATE TEMPORARY TABLE `tmp_ms_mc_roll` (
    `Cache` INT UNSIGNED NOT NULL,
    `Item` INT UNSIGNED NOT NULL,
    `Reference` INT UNSIGNED NOT NULL,
    `Guaranteed` TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (`Cache`, `Item`)
) ENGINE=InnoDB;
DELETE FROM `tmp_ms_mc_roll`;
INSERT INTO `tmp_ms_mc_roll` (`Cache`, `Item`, `Reference`, `Guaranteed`) VALUES
(1278056, 1, 9002022, 1),
(1278056, 2, 9002001, 1),
(1278056, 3, 9002030, 0),
(1278058, 1, 9002001, 1),
(1278058, 2, 9002002, 0),
(1278058, 3, 9002030, 0),
(1278060, 1, 9002002, 1),
(1278060, 2, 9002002, 0),
(1278060, 3, 9002003, 0),
(1278060, 4, 9002010, 0),
(1278060, 5, 9002031, 0);

DROP TEMPORARY TABLE IF EXISTS `tmp_ms_mc_review_pool`;
CREATE TEMPORARY TABLE `tmp_ms_mc_review_pool` (
    `Entry` INT UNSIGNED NOT NULL PRIMARY KEY,
    `Expected` INT UNSIGNED NOT NULL
) ENGINE=InnoDB;
DELETE FROM `tmp_ms_mc_review_pool`;
INSERT INTO `tmp_ms_mc_review_pool` (`Entry`, `Expected`) VALUES
(9002001, 106), (9002002, 86), (9002003, 106), (9002010, 14),
(9002022, 122), (9002030, 611), (9002031, 6109);

DROP PROCEDURE IF EXISTS `ms_mc_roll_groups_20261007`;
DELIMITER $$
CREATE PROCEDURE `ms_mc_roll_groups_20261007`()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    IF (SELECT COUNT(*) FROM `information_schema`.`TABLES`
        WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'item_loot_template' AND `ENGINE` = 'InnoDB') <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'MC roll groups: InnoDB item loot required';
    END IF;
    START TRANSACTION;
    IF (SELECT COUNT(*) FROM `item_template`
        WHERE `entry` IN (1278056,1278058,1278060) AND (`Flags` & 4) <> 0 AND `ScriptName` = '') <> 3 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'MC roll groups: expected three scriptless HAS_LOOT caches';
    END IF;
    IF (SELECT COUNT(*) FROM `item_loot_template` WHERE `Entry` IN (1278056,1278058,1278060)) <> 11 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'MC roll groups: SQL 26 required; expected 11 root rows';
    END IF;
    IF EXISTS (
        SELECT 1 FROM `tmp_ms_mc_roll` AS `e`
        LEFT JOIN `item_loot_template` AS `r` ON `r`.`Entry` = `e`.`Cache` AND `r`.`Item` = `e`.`Item`
        WHERE `r`.`Item` IS NULL OR `r`.`Reference` <> `e`.`Reference`
            OR `r`.`Chance` <= 0 OR `r`.`Chance` > 100
            OR (`e`.`Guaranteed` = 1 AND `r`.`Chance` <> 100)
            OR `r`.`QuestRequired` <> 0 OR `r`.`LootMode` <> 1
            OR `r`.`GroupId` NOT IN (0, `e`.`Item`) OR `r`.`MinCount` <> 1 OR `r`.`MaxCount` <> 1
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'MC roll groups: root layout mismatch; inspect SQL 26 installation';
    END IF;
    IF EXISTS (
        SELECT 1 FROM `tmp_ms_mc_review_pool` AS `e`
        LEFT JOIN (SELECT `Entry`, COUNT(*) AS `N` FROM `reference_loot_template`
            WHERE `Entry` IN (9002001,9002002,9002003,9002010,9002022,9002030,9002031) GROUP BY `Entry`) AS `r`
            USING (`Entry`)
        WHERE COALESCE(`r`.`N`, 0) <> `e`.`Expected`
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'MC roll groups: SQL 26 pool counts mismatch';
    END IF;
    IF EXISTS (
        SELECT 1 FROM `reference_loot_template` AS `r`
        JOIN `tmp_ms_mc_review_pool` AS `e` USING (`Entry`)
        LEFT JOIN `item_template` AS `i` ON `i`.`entry` = `r`.`Item`
        WHERE `i`.`entry` IS NULL OR `i`.`class` NOT IN (2, 4) OR `i`.`InventoryType` = 0
            OR `i`.`RequiredLevel` > 60 OR `i`.`Quality` <> 4
            OR `r`.`Reference` <> 0 OR `r`.`Chance` <> 0 OR `r`.`QuestRequired` <> 0
            OR `r`.`LootMode` <> 1 OR `r`.`GroupId` <> 1 OR `r`.`MinCount` <> 1 OR `r`.`MaxCount` <> 1
            OR (`r`.`Entry` = 9002002 AND NOT (`i`.`description` LIKE '@Heroic Molten Core@%'
                OR `i`.`description` LIKE '@Heroic Raid@%'))
            OR (`r`.`Entry` = 9002003 AND NOT (`i`.`description` LIKE '@Mythic Molten Core@%'
                OR `i`.`description` LIKE '@Mythic Raid@%'))
            OR (`r`.`Entry` = 9002022 AND NOT (`i`.`description` LIKE '@Mythic Zul''Gurub@%'
                OR `i`.`description` LIKE '@Mythic Raid@%'))
            OR (`r`.`Entry` = 9002030 AND `i`.`description` <> '@Mythic Dungeon@')
            OR (`r`.`Entry` = 9002031 AND NOT (
                `i`.`description` LIKE '@Mythic 1@%' OR `i`.`description` LIKE '@Mythic 2@%'
                OR `i`.`description` LIKE '@Mythic 3@%' OR `i`.`description` LIKE '@Mythic 4@%'
                OR `i`.`description` LIKE '@Mythic 5@%' OR `i`.`description` LIKE '@Mythic 6@%'
                OR `i`.`description` LIKE '@Mythic 7@%' OR `i`.`description` LIKE '@Mythic 8@%'
                OR `i`.`description` LIKE '@Mythic 9@%' OR `i`.`description` LIKE '@Mythic 10@%'))
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'MC roll groups: invalid gear leaf or tier marker';
    END IF;
    IF EXISTS (SELECT 1 FROM `conditions`
        WHERE (`SourceTypeOrReferenceId` = 5 AND `SourceGroup` IN (1278056,1278058,1278060))
            OR (`SourceTypeOrReferenceId` = 10 AND `SourceGroup` IN
                (9002001,9002002,9002003,9002010,9002022,9002030,9002031))) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'MC roll groups: loot conditions require review';
    END IF;
    UPDATE `item_loot_template` SET `GroupId` = `Item` WHERE `Entry` IN (1278056,1278058,1278060);
    IF EXISTS (SELECT 1 FROM `item_loot_template`
        WHERE `Entry` IN (1278056,1278058,1278060) AND `GroupId` <> `Item`) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'MC roll groups: post-write group mismatch';
    END IF;
    COMMIT;
END$$
DELIMITER ;
CALL `ms_mc_roll_groups_20261007`();
DROP PROCEDURE `ms_mc_roll_groups_20261007`;

-- Expected 11 roots, GroupId equals Item; installed Chance values are preserved.
SELECT `Entry`, `Item`, `Reference`, `Chance`, `GroupId`, `MinCount`, `MaxCount`
FROM `item_loot_template` WHERE `Entry` IN (1278056,1278058,1278060) ORDER BY `Entry`, `Item`;
DROP TEMPORARY TABLE `tmp_ms_mc_review_pool`;
DROP TEMPORARY TABLE `tmp_ms_mc_roll`;
