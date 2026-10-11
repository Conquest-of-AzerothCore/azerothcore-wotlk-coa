CREATE TABLE IF NOT EXISTS `coa_crows_cache_rewards` (
    `kind` TINYINT UNSIGNED NOT NULL,
    `item` INT UNSIGNED NOT NULL,
    `count` INT UNSIGNED NOT NULL DEFAULT 1,
    PRIMARY KEY (`kind`, `item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `coa_crows_cache_rewards`;
INSERT INTO `coa_crows_cache_rewards` (`kind`, `item`, `count`)
SELECT 0, `entry`, 1 FROM `item_template`
WHERE `entry` BETWEEN 6322798 AND 6323070 AND `RequiredLevel` = 60 AND `Quality` = 4
    AND `ItemLevel` = 95 AND `description` LIKE '%Heroic Bloodforged%';
DELETE FROM `coa_crows_cache_rewards` WHERE `kind` = 1;
INSERT INTO `coa_crows_cache_rewards` (`kind`, `item`, `count`) VALUES
(1, 967008, 20), (1, 967014, 20), (1, 967017, 20);

CREATE TEMPORARY TABLE `_crows_creature` LIKE `creature_template`;
DELETE FROM `_crows_creature`;
INSERT INTO `_crows_creature` SELECT * FROM `creature_template` WHERE `entry` = 17970;
UPDATE `_crows_creature` SET `entry` = 994310, `name` = 'Crow of the Cache', `subname` = '',
    `minlevel` = 60, `maxlevel` = 60, `faction` = 35, `npcflag` = 0, `lootid` = 0,
    `AIName` = 'NullCreatureAI', `MovementType` = 0, `ScriptName` = '';
INSERT IGNORE INTO `creature_template` SELECT * FROM `_crows_creature`;
DROP TEMPORARY TABLE `_crows_creature`;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 994310;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES (994310, 0, 17447, 4, 1);

CREATE TEMPORARY TABLE `_crows_object` LIKE `gameobject_template`;
DELETE FROM `_crows_object`;
INSERT INTO `_crows_object` SELECT * FROM `gameobject_template` WHERE `entry` = 994300;
UPDATE `_crows_object` SET `entry` = 994311, `name` = 'Crow\'s Cache', `type` = 10, `Data0` = 14,
    `ScriptName` = 'crows_cache_chest';
INSERT IGNORE INTO `gameobject_template` SELECT * FROM `_crows_object`;
UPDATE `_crows_object` SET `entry` = 994312, `name` = 'Dropped Crow\'s Cache';
INSERT IGNORE INTO `gameobject_template` SELECT * FROM `_crows_object`;
DROP TEMPORARY TABLE `_crows_object`;

UPDATE `item_template` SET `ScriptName` = 'item_crows_cache', `bonding` = 1 WHERE `entry` = 1615010;
DELETE FROM `spell_script_names` WHERE `spell_id` = 68398 AND `ScriptName` = 'CrowsCache::Opening';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (68398, 'CrowsCache::Opening');
