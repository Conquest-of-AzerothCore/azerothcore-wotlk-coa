UPDATE `creature_template` SET `minlevel` = 63, `maxlevel` = 63, `DamageModifier` = 17.56 WHERE `entry` = 103654;
UPDATE `creature_template` SET `minlevel` = 63, `maxlevel` = 63, `DamageModifier` = 37.87 WHERE `entry` = 203654;

DELETE FROM `creature_template` WHERE `entry` = 105762;
DROP TEMPORARY TABLE IF EXISTS `coa_copy_105762`;
CREATE TEMPORARY TABLE `coa_copy_105762` AS SELECT * FROM `creature_template` WHERE `entry` = 5762;
UPDATE `coa_copy_105762` SET `entry` = 105762, `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0, `minlevel` = 61, `maxlevel` = 61, `DamageModifier` = 2.78, `AIName` = '', `ScriptName` = '';
INSERT INTO `creature_template` SELECT * FROM `coa_copy_105762`;
DROP TEMPORARY TABLE `coa_copy_105762`;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 105762;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) SELECT 105762, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild` FROM `creature_template_model` WHERE `CreatureID` = 5762;
DELETE FROM `creature_template_addon` WHERE `entry` = 105762;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) SELECT 105762, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras` FROM `creature_template_addon` WHERE `entry` = 5762;
DELETE FROM `creature_template_spell` WHERE `CreatureID` = 105762;
INSERT INTO `creature_template_spell` (`CreatureID`, `Index`, `Spell`, `VerifiedBuild`) SELECT 105762, `Index`, `Spell`, `VerifiedBuild` FROM `creature_template_spell` WHERE `CreatureID` = 5762;
DELETE FROM `creature_template_resistance` WHERE `CreatureID` = 105762;
INSERT INTO `creature_template_resistance` (`CreatureID`, `School`, `Resistance`, `VerifiedBuild`) SELECT 105762, `School`, `Resistance`, `VerifiedBuild` FROM `creature_template_resistance` WHERE `CreatureID` = 5762;
DELETE FROM `creature_template` WHERE `entry` = 205762;
DROP TEMPORARY TABLE IF EXISTS `coa_copy_205762`;
CREATE TEMPORARY TABLE `coa_copy_205762` AS SELECT * FROM `creature_template` WHERE `entry` = 5762;
UPDATE `coa_copy_205762` SET `entry` = 205762, `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0, `minlevel` = 61, `maxlevel` = 61, `DamageModifier` = 7.08, `AIName` = '', `ScriptName` = '';
INSERT INTO `creature_template` SELECT * FROM `coa_copy_205762`;
DROP TEMPORARY TABLE `coa_copy_205762`;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 205762;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) SELECT 205762, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild` FROM `creature_template_model` WHERE `CreatureID` = 5762;
DELETE FROM `creature_template_addon` WHERE `entry` = 205762;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) SELECT 205762, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras` FROM `creature_template_addon` WHERE `entry` = 5762;
DELETE FROM `creature_template_spell` WHERE `CreatureID` = 205762;
INSERT INTO `creature_template_spell` (`CreatureID`, `Index`, `Spell`, `VerifiedBuild`) SELECT 205762, `Index`, `Spell`, `VerifiedBuild` FROM `creature_template_spell` WHERE `CreatureID` = 5762;
DELETE FROM `creature_template_resistance` WHERE `CreatureID` = 205762;
INSERT INTO `creature_template_resistance` (`CreatureID`, `School`, `Resistance`, `VerifiedBuild`) SELECT 205762, `School`, `Resistance`, `VerifiedBuild` FROM `creature_template_resistance` WHERE `CreatureID` = 5762;
UPDATE `creature_template` SET `difficulty_entry_1` = 105762, `difficulty_entry_2` = 205762 WHERE `entry` = 5762;

DELETE FROM `creature_template` WHERE `entry` = 105763;
DROP TEMPORARY TABLE IF EXISTS `coa_copy_105763`;
CREATE TEMPORARY TABLE `coa_copy_105763` AS SELECT * FROM `creature_template` WHERE `entry` = 5763;
UPDATE `coa_copy_105763` SET `entry` = 105763, `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0, `minlevel` = 60, `maxlevel` = 60, `DamageModifier` = 2.78, `AIName` = '', `ScriptName` = '';
INSERT INTO `creature_template` SELECT * FROM `coa_copy_105763`;
DROP TEMPORARY TABLE `coa_copy_105763`;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 105763;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) SELECT 105763, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild` FROM `creature_template_model` WHERE `CreatureID` = 5763;
DELETE FROM `creature_template_addon` WHERE `entry` = 105763;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) SELECT 105763, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras` FROM `creature_template_addon` WHERE `entry` = 5763;
DELETE FROM `creature_template_spell` WHERE `CreatureID` = 105763;
INSERT INTO `creature_template_spell` (`CreatureID`, `Index`, `Spell`, `VerifiedBuild`) SELECT 105763, `Index`, `Spell`, `VerifiedBuild` FROM `creature_template_spell` WHERE `CreatureID` = 5763;
DELETE FROM `creature_template_resistance` WHERE `CreatureID` = 105763;
INSERT INTO `creature_template_resistance` (`CreatureID`, `School`, `Resistance`, `VerifiedBuild`) SELECT 105763, `School`, `Resistance`, `VerifiedBuild` FROM `creature_template_resistance` WHERE `CreatureID` = 5763;
DELETE FROM `creature_template` WHERE `entry` = 205763;
DROP TEMPORARY TABLE IF EXISTS `coa_copy_205763`;
CREATE TEMPORARY TABLE `coa_copy_205763` AS SELECT * FROM `creature_template` WHERE `entry` = 5763;
UPDATE `coa_copy_205763` SET `entry` = 205763, `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0, `minlevel` = 60, `maxlevel` = 60, `DamageModifier` = 7.08, `AIName` = '', `ScriptName` = '';
INSERT INTO `creature_template` SELECT * FROM `coa_copy_205763`;
DROP TEMPORARY TABLE `coa_copy_205763`;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 205763;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) SELECT 205763, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild` FROM `creature_template_model` WHERE `CreatureID` = 5763;
DELETE FROM `creature_template_addon` WHERE `entry` = 205763;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) SELECT 205763, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras` FROM `creature_template_addon` WHERE `entry` = 5763;
DELETE FROM `creature_template_spell` WHERE `CreatureID` = 205763;
INSERT INTO `creature_template_spell` (`CreatureID`, `Index`, `Spell`, `VerifiedBuild`) SELECT 205763, `Index`, `Spell`, `VerifiedBuild` FROM `creature_template_spell` WHERE `CreatureID` = 5763;
DELETE FROM `creature_template_resistance` WHERE `CreatureID` = 205763;
INSERT INTO `creature_template_resistance` (`CreatureID`, `School`, `Resistance`, `VerifiedBuild`) SELECT 205763, `School`, `Resistance`, `VerifiedBuild` FROM `creature_template_resistance` WHERE `CreatureID` = 5763;
UPDATE `creature_template` SET `difficulty_entry_1` = 105763, `difficulty_entry_2` = 205763 WHERE `entry` = 5763;

DELETE FROM `coa_dungeon_health` WHERE `map_id` = 43 AND `creature_entry` IN (3654, 5762, 5763);
INSERT INTO `coa_dungeon_health` (`map_id`, `difficulty`, `creature_entry`, `max_health`, `evidence`, `source`) VALUES
    (43, 1, 3654, 377077, 'model', 'Heroic from Mythic; same as Lord Cobrahn, who took as much damage as Mutanus in one Mythic+ run; Mutanus the Devourer'),
    (43, 2, 3654, 490200, 'model', 'same as Lord Cobrahn, who took as much damage as Mutanus in one Mythic+ run; Mutanus the Devourer'),
    (43, 1, 5762, 48855, 'model', 'Heroic from Mythic; same as Deviate Viper; Deviate Moccasin'),
    (43, 2, 5762, 63512, 'model', 'same as Deviate Viper; Deviate Moccasin'),
    (43, 1, 5763, 23688, 'model', 'Heroic from Mythic; same as Deviate Python; Nightmare Ectoplasm'),
    (43, 2, 5763, 30795, 'model', 'same as Deviate Python; Nightmare Ectoplasm');
