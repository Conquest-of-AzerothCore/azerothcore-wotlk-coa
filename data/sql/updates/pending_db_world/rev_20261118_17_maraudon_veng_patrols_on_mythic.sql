UPDATE `creature` SET `spawnMask` = 3 WHERE `guid` = 53970 AND `id` = 12243;

DELETE FROM `creature` WHERE `guid` = 9976349;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
    (9976349, 13738, 349, 0, 0, 4, 1, 1, 1055.28, -423.504, -31.7805, 1.75036, 86400, 0, 0, 0, 0, 2, 0, 0, 0, '', 0, 0, 'Veng, the Mythic Orange Crystals boss, walks the path of the Spirit of Veng');

DELETE FROM `creature_addon` WHERE `guid` = 9976349;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
    (9976349, 539700, 0, 0, 0, 0, 3, '');

DELETE FROM `creature_text` WHERE `CreatureID` = 13738;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
    (13738, 0, 0, 'Your presence desecrates this sacred tomb!', 12, 0, 100, 0, 0, 0, 0, 0, 'Veng - Aggro'),
    (13738, 1, 0, 'My wrath... never ends...', 14, 0, 100, 0, 0, 0, 0, 0, 'Veng - Death');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 13738 AND `source_type` = 0 AND `id` IN (0, 1);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
    (13738, 0, 0, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Veng - On Aggro - Say Line 0'),
    (13738, 0, 1, 0, 6, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Veng - On Death - Say Line 1');

UPDATE `creature_template` SET `speed_walk` = 1 WHERE `entry` = 13738;

UPDATE `smart_scripts` SET `event_type` = 9, `event_param1` = 0, `event_param2` = 0, `event_param3` = 3700, `event_param4` = 4200, `event_param5` = 8, `event_param6` = 40,
    `action_param2` = 0,
    `comment` = 'Veng - Ascension kit - Victim within 8-40 yards (every 3.7-4.2 s) - Cast ''Shoot'''
WHERE `entryorguid` = 13738 AND `source_type` = 0 AND `id` = 9000 AND `action_type` = 11 AND `action_param1` = 2100156;

DELETE FROM `creature_template` WHERE `entry` = 213738;
DROP TEMPORARY TABLE IF EXISTS `coa_veng_copy`;
CREATE TEMPORARY TABLE `coa_veng_copy` AS SELECT * FROM `creature_template` WHERE `entry` = 13738;
UPDATE `coa_veng_copy` SET `entry` = 213738, `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0,
    `minlevel` = 63, `maxlevel` = 63, `DamageModifier` = 45.15, `AIName` = '', `ScriptName` = '';
INSERT INTO `creature_template` SELECT * FROM `coa_veng_copy`;
DROP TEMPORARY TABLE `coa_veng_copy`;

DELETE FROM `creature_template_model` WHERE `CreatureID` = 213738;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
SELECT 213738, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild` FROM `creature_template_model` WHERE `CreatureID` = 13738;

DELETE FROM `creature_template_addon` WHERE `entry` = 213738;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`)
SELECT 213738, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras` FROM `creature_template_addon` WHERE `entry` = 13738;

DELETE FROM `creature_template_spell` WHERE `CreatureID` = 213738;
INSERT INTO `creature_template_spell` (`CreatureID`, `Index`, `Spell`, `VerifiedBuild`)
SELECT 213738, `Index`, `Spell`, `VerifiedBuild` FROM `creature_template_spell` WHERE `CreatureID` = 13738;

UPDATE `creature_template` SET `difficulty_entry_2` = 213738 WHERE `entry` = 13738;
