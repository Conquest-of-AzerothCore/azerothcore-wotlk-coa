-- BWL uses MC flex health for bosses, trash and combat adds. Normal trash is one MC difficulty step
-- above its comparable MC creature (1.44x). This is realm tuning, not measured Ascension parity.
-- Keep existing boss Normal pools and loot IDs, including the custom Chromatic-token loot tables.
DROP TEMPORARY TABLE IF EXISTS `_coa_bwl_scale_tiers`;
CREATE TEMPORARY TABLE `_coa_bwl_scale_tiers` (`offset` INT NOT NULL, `factor` DECIMAL(5, 2) NOT NULL);
DELETE FROM `_coa_bwl_scale_tiers`;
INSERT INTO `_coa_bwl_scale_tiers` (`offset`, `factor`) VALUES (100000, 1.44), (200000, 1.88), (300000, 2.32);

DROP TEMPORARY TABLE IF EXISTS `_coa_bwl_scale_base`;
CREATE TEMPORARY TABLE `_coa_bwl_scale_base` AS
SELECT * FROM `creature_template` WHERE `entry` IN (
    11583, 11981, 11983, 12017, 12416, 12420, 12422, 12435, 12457, 12458, 12459, 12460, 12461, 12463, 12464, 12465,
    12467, 12468, 12557, 13020, 13996, 14020, 14022, 14023, 14024, 14025, 14261, 14262, 14263, 14264, 14265, 14302,
    14401, 14456, 14601, 14605);
DROP TEMPORARY TABLE IF EXISTS `_coa_bwl_scale_ids`;
CREATE TEMPORARY TABLE `_coa_bwl_scale_ids` AS
SELECT `b`.`entry` + `d`.`offset` AS `entry` FROM `_coa_bwl_scale_base` `b` CROSS JOIN `_coa_bwl_scale_tiers` `d`;
DROP TEMPORARY TABLE IF EXISTS `_coa_bwl_scale_loot`;
CREATE TEMPORARY TABLE `_coa_bwl_scale_loot` AS
SELECT `entry`, `lootid` FROM `creature_template` WHERE `entry` IN (SELECT `entry` FROM `_coa_bwl_scale_ids`);

INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`,
    `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`,
    `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`,
    `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`,
    `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`,
    `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`,
    `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`,
    `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
SELECT `b`.`entry` + `d`.`offset`, 0, 0, 0, `b`.`KillCredit1`, `b`.`KillCredit2`, `b`.`name`, `b`.`subname`, `b`.`IconName`,
    `b`.`gossip_menu_id`, `b`.`minlevel`, `b`.`maxlevel`, `b`.`exp`, `b`.`faction`, `b`.`npcflag`, `b`.`speed_walk`,
    `b`.`speed_run`, `b`.`speed_swim`, `b`.`speed_flight`, `b`.`detection_range`, `b`.`rank`, `b`.`dmgschool`,
    ROUND(`b`.`DamageModifier` * `d`.`factor`, 4), `b`.`BaseAttackTime`, `b`.`RangeAttackTime`, `b`.`BaseVariance`,
    `b`.`RangeVariance`, `b`.`unit_class`, `b`.`unit_flags`, `b`.`unit_flags2`, `b`.`dynamicflags`, `b`.`family`, `b`.`type`,
    `b`.`type_flags`, COALESCE(`p`.`lootid`, `b`.`lootid`), `b`.`pickpocketloot`, `b`.`skinloot`, `b`.`PetSpellDataId`,
    `b`.`VehicleId`, `b`.`mingold`, `b`.`maxgold`, `b`.`AIName`, `b`.`MovementType`, `b`.`HoverHeight`,
    ROUND(`b`.`HealthModifier` * `d`.`factor`, 4), `b`.`ManaModifier`, `b`.`ArmorModifier`, `b`.`ExperienceModifier`,
    `b`.`RacialLeader`, `b`.`movementId`, `b`.`RegenHealth`, `b`.`CreatureImmunitiesId`, `b`.`flags_extra`, `b`.`ScriptName`,
    `b`.`VerifiedBuild`
FROM `_coa_bwl_scale_base` `b` CROSS JOIN `_coa_bwl_scale_tiers` `d`
LEFT JOIN `_coa_bwl_scale_loot` `p` ON `p`.`entry` = `b`.`entry` + `d`.`offset`
WHERE 1 = 1
ON DUPLICATE KEY UPDATE
    `HealthModifier` = VALUES(`HealthModifier`), `DamageModifier` = VALUES(`DamageModifier`),
    `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0;
UPDATE `creature_template` SET `difficulty_entry_1` = `entry` + 100000,
    `difficulty_entry_2` = `entry` + 200000, `difficulty_entry_3` = `entry` + 300000
WHERE `entry` IN (
    11583, 11981, 11983, 12017, 12416, 12420, 12422, 12435, 12457, 12458, 12459, 12460, 12461, 12463, 12464, 12465,
    12467, 12468, 12557, 13020, 13996, 14020, 14022, 14023, 14024, 14025, 14261, 14262, 14263, 14264, 14265, 14302,
    14401, 14456, 14601, 14605);

DELETE FROM `creature_template_addon` WHERE `entry` IN (SELECT `entry` FROM `_coa_bwl_scale_ids`);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`,
    `visibilityDistanceType`, `auras`)
SELECT `s`.`entry` + `d`.`offset`, `s`.`path_id`, `s`.`mount`, `s`.`bytes1`, `s`.`bytes2`, `s`.`emote`,
    `s`.`visibilityDistanceType`, `s`.`auras`
FROM `creature_template_addon` `s` CROSS JOIN `_coa_bwl_scale_tiers` `d`
WHERE `s`.`entry` IN (SELECT `entry` FROM `_coa_bwl_scale_base`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (SELECT `entry` FROM `_coa_bwl_scale_ids`);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
    `VerifiedBuild`)
SELECT `s`.`CreatureID` + `d`.`offset`, `s`.`Idx`, `s`.`CreatureDisplayID`, `s`.`DisplayScale`, `s`.`Probability`,
    `s`.`VerifiedBuild`
FROM `creature_template_model` `s` CROSS JOIN `_coa_bwl_scale_tiers` `d`
WHERE `s`.`CreatureID` IN (SELECT `entry` FROM `_coa_bwl_scale_base`);

DELETE FROM `creature_template_movement` WHERE `CreatureId` IN (SELECT `entry` FROM `_coa_bwl_scale_ids`);
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`, `Chase`, `Random`,
    `InteractionPauseTimer`)
SELECT `s`.`CreatureId` + `d`.`offset`, `s`.`Ground`, `s`.`Swim`, `s`.`Flight`, `s`.`Rooted`, `s`.`Chase`, `s`.`Random`,
    `s`.`InteractionPauseTimer`
FROM `creature_template_movement` `s` CROSS JOIN `_coa_bwl_scale_tiers` `d`
WHERE `s`.`CreatureId` IN (SELECT `entry` FROM `_coa_bwl_scale_base`);

DELETE FROM `creature_template_resistance` WHERE `CreatureID` IN (SELECT `entry` FROM `_coa_bwl_scale_ids`);
INSERT INTO `creature_template_resistance` (`CreatureID`, `School`, `Resistance`, `VerifiedBuild`)
SELECT `s`.`CreatureID` + `d`.`offset`, `s`.`School`, `s`.`Resistance`, `s`.`VerifiedBuild`
FROM `creature_template_resistance` `s` CROSS JOIN `_coa_bwl_scale_tiers` `d`
WHERE `s`.`CreatureID` IN (SELECT `entry` FROM `_coa_bwl_scale_base`);

DELETE FROM `creature_template_spell` WHERE `CreatureID` IN (SELECT `entry` FROM `_coa_bwl_scale_ids`);
INSERT INTO `creature_template_spell` (`CreatureID`, `Index`, `Spell`, `VerifiedBuild`)
SELECT `s`.`CreatureID` + `d`.`offset`, `s`.`Index`, `s`.`Spell`, `s`.`VerifiedBuild`
FROM `creature_template_spell` `s` CROSS JOIN `_coa_bwl_scale_tiers` `d`
WHERE `s`.`CreatureID` IN (SELECT `entry` FROM `_coa_bwl_scale_base`);

UPDATE `coa_boss_flex`
SET
    `hp_d1` = ROUND(`hp_d0` * 1.44),
    `hp_d2` = ROUND(`hp_d0` * 1.88), `hp_d3` = ROUND(`hp_d0` * 2.32)
WHERE `entry` IN (11583, 11981, 11983, 12017, 12435, 13020, 14020, 14601);

DELETE FROM `coa_boss_flex` WHERE `entry` IN (
    12416, 12420, 12422, 12457, 12458, 12459, 12460, 12461, 12463, 12464, 12465, 12467, 12468, 12557, 13996, 14022,
    14023, 14024, 14025, 14261, 14262, 14263, 14264, 14265, 14302, 14401, 14456, 14605);
INSERT INTO `coa_boss_flex` (`entry`, `hp_d0`, `hp_d1`, `hp_d2`, `hp_d3`, `comment`)
SELECT
    `m`.`entry`, ROUND(`mc`.`hp_d0` * 1.44), ROUND(ROUND(`mc`.`hp_d0` * 1.44) * 1.44),
    ROUND(ROUND(`mc`.`hp_d0` * 1.44) * 1.88), ROUND(ROUND(`mc`.`hp_d0` * 1.44) * 2.32),
    CONCAT('BWL trash: 1.44x MC Normal entry ', `m`.`mc_entry`, ' per player; realm tuning')
FROM `coa_boss_flex` `mc` JOIN (
    SELECT 12416 AS `entry`, 11666 AS `mc_entry`
    UNION ALL SELECT 12420, 11666
    UNION ALL SELECT 12422, 11671
    UNION ALL SELECT 12457, 11668
    UNION ALL SELECT 12458, 11661
    UNION ALL SELECT 12459, 11668
    UNION ALL SELECT 12460, 11658
    UNION ALL SELECT 12461, 11673
    UNION ALL SELECT 12463, 12100
    UNION ALL SELECT 12464, 11665
    UNION ALL SELECT 12465, 11668
    UNION ALL SELECT 12467, 11661
    UNION ALL SELECT 12468, 11668
    UNION ALL SELECT 12557, 11662
    UNION ALL SELECT 13996, 11669
    UNION ALL SELECT 14022, 11669
    UNION ALL SELECT 14023, 11669
    UNION ALL SELECT 14024, 11669
    UNION ALL SELECT 14025, 11669
    UNION ALL SELECT 14261, 11671
    UNION ALL SELECT 14262, 11671
    UNION ALL SELECT 14263, 11671
    UNION ALL SELECT 14264, 11671
    UNION ALL SELECT 14265, 11671
    UNION ALL SELECT 14302, 11665
    UNION ALL SELECT 14401, 11669
    UNION ALL SELECT 14456, 11671
    UNION ALL SELECT 14605, 11669
) `m` ON `mc`.`entry` = `m`.`mc_entry`;

DROP TEMPORARY TABLE `_coa_bwl_scale_loot`;
DROP TEMPORARY TABLE `_coa_bwl_scale_ids`;
DROP TEMPORARY TABLE `_coa_bwl_scale_base`;
DROP TEMPORARY TABLE `_coa_bwl_scale_tiers`;
