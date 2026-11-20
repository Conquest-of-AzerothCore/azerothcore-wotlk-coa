-- Karazhan reward pools use the rescaled normal boss and Chess equipment.
CREATE TEMPORARY TABLE `_coa_karazhan_callboard_items` (`entry` INT UNSIGNED PRIMARY KEY) ENGINE=InnoDB;
DELETE FROM `_coa_karazhan_callboard_items`;
INSERT INTO `_coa_karazhan_callboard_items` VALUES
(28453), (28454), (28477), (28502), (28503), (28504), (28505), (28506), (28507), (28508),
(28509), (28510), (28511), (28512), (28514), (28515), (28516), (28517), (28518), (28519),
(28520), (28521), (28522), (28523), (28524), (28525), (28528), (28529), (28530), (28545),
(28565), (28566), (28567), (28568), (28569), (28570), (28572), (28573), (28578), (28579),
(28581), (28582), (28583), (28584), (28585), (28586), (28587), (28588), (28589), (28590),
(28591), (28592), (28593), (28594), (28597), (28599), (28600), (28601), (28602), (28603),
(28604), (28606), (28608), (28609), (28610), (28611), (28612), (28621), (28631), (28633),
(28647), (28649), (28652), (28653), (28654), (28655), (28656), (28657), (28658), (28659),
(28660), (28661), (28662), (28663), (28666), (28669), (28670), (28671), (28672), (28673),
(28674), (28675), (28726), (28727), (28728), (28729), (28730), (28731), (28732), (28733),
(28734), (28735), (28740), (28741), (28742), (28743), (28744), (28745), (28746), (28747),
(28748), (28749), (28750), (28751), (28752), (28753), (28754), (28755), (28756), (28757),
(28762), (28763), (28764), (28765), (28766), (28767), (28768), (28770), (28771), (28772),
(28773), (28785);

CREATE TEMPORARY TABLE `_coa_karazhan_callboard_cache` LIKE `item_template`;
DELETE FROM `_coa_karazhan_callboard_cache`;
INSERT INTO `_coa_karazhan_callboard_cache`
SELECT * FROM `item_template` WHERE `entry` = 1615009;
UPDATE `_coa_karazhan_callboard_cache`
SET `entry` = 1615014, `name` = 'Callboard Cache (Karazhan)';

START TRANSACTION;

INSERT IGNORE INTO `item_template`
SELECT * FROM `_coa_karazhan_callboard_cache`;

UPDATE `item_template` SET `RequiredLevel` = 60 WHERE `entry` = 1297310;

DELETE FROM `ascension_callboard_cache_reward` WHERE `CacheItemId` = 1615014;
INSERT INTO `ascension_callboard_cache_reward` (`CacheItemId`, `RewardItemId`, `RewardItemLevel`, `StatType`, `ArmorClass`)
SELECT 1615014, `item`.`entry`, `item`.`ItemLevel`,
    CASE WHEN `prior`.`StatType` IS NOT NULL THEN `prior`.`StatType` ELSE 5 END, `item`.`subclass`
FROM `_coa_karazhan_callboard_items` AS `pool`
JOIN `item_template` AS `item` ON `item`.`entry` = `pool`.`entry`
LEFT JOIN `ascension_prestigious_cache_reward` AS `prior`
    ON `prior`.`CacheItemId` = 1297310 AND `prior`.`RewardItemId` = `item`.`entry`;

DELETE FROM `ascension_callboard_cache_tier` WHERE `CacheItemId` = 1615014;
INSERT INTO `ascension_callboard_cache_tier` (`ItemLevel`, `CacheItemId`) VALUES
(84, 1615014);

DELETE FROM `ascension_prestigious_cache_reward` WHERE `CacheItemId` = 1297310;
INSERT INTO `ascension_prestigious_cache_reward` (`CacheItemId`, `RewardItemId`, `RewardItemLevel`, `StatType`, `ArmorClass`)
SELECT 1297310, `RewardItemId`, `RewardItemLevel`, `StatType`, `ArmorClass`
FROM `ascension_callboard_cache_reward` WHERE `CacheItemId` = 1615014;

UPDATE `ascension_cache_content_token` AS `cache`
JOIN `item_template` AS `item` ON `item`.`entry` = `cache`.`RewardItemId`
SET `cache`.`RewardItemLevel` = `item`.`ItemLevel`
WHERE `cache`.`CacheItemId` = 1297310 AND `cache`.`RewardItemId` IN (29758, 29761);

COMMIT;

DROP TEMPORARY TABLE `_coa_karazhan_callboard_cache`;
DROP TEMPORARY TABLE `_coa_karazhan_callboard_items`;
