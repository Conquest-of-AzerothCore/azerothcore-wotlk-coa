-- A Grimtotem Marauder butchers a kodo on the side of the road below Red Cloud Mesa, placed in game: a Kodo Carcass
-- (new 9303002, the Dying Kodo's grey kodo 1453 lying dead, out of reach of clicks and blows) lies along the road, and
-- Marauder 9011037 stands at its flank working at it with the looping Use animation. Grimtotem Warrior 9011113 by
-- Malgorm's hut works with the same animation, and two Warriors and two Villagers sit (stand state 1).
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `exp`, `faction`,
    `npcflag`, `speed_walk`, `speed_run`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`,
    `unit_flags2`, `type`, `type_flags`, `VehicleId`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`,
    `ArmorModifier`, `RegenHealth`, `flags_extra`, `ScriptName`)
VALUES
(9303002, 'Kodo Carcass', NULL, NULL, 1, 1, 0, 35, 0, 1, 1.14286, 2000, 2000, 1, 33554434, 2048, 1, 0, 0, '', 0, 1, 1,
    1, 1, 0, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `faction` = VALUES(`faction`), `unit_flags` = VALUES(`unit_flags`),
    `type` = VALUES(`type`), `flags_extra` = VALUES(`flags_extra`);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 9303002;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(9303002, 0, 1453, 1, 1);

DELETE FROM `creature_template_addon` WHERE `entry` = 9303002;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`,
    `visibilityDistanceType`, `auras`) VALUES
(9303002, 0, 0, 7, 0, 0, 0, NULL);

DELETE FROM `creature` WHERE `guid` = 9011138;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`,
    `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`,
    `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`,
    `Comment`) VALUES
(9011138, 9303002, 1, 0, 0, 1, 1, 0, -3450.129, -835.71, 72.195, 1.6383, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0,
    'CoA Three Totems: Kodo Carcass on the side of the road below Red Cloud Mesa, placed in game');

UPDATE `creature` SET `position_x` = -3447.295, `position_y` = -833.26, `position_z` = 71.563, `orientation` = 3.4969,
    `MovementType` = 0, `wander_distance` = 0 WHERE `guid` = 9011037;
DELETE FROM `creature_addon` WHERE `guid` IN (9011037, 9011113, 9011114, 9011124, 9011121, 9011112);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`,
    `auras`) VALUES
(9011037, 0, 0, 0, 0, 69, 0, NULL),
(9011113, 0, 0, 0, 0, 69, 0, NULL),
(9011114, 0, 0, 1, 0, 0, 0, NULL),
(9011124, 0, 0, 1, 0, 0, 0, NULL),
(9011121, 0, 0, 1, 0, 0, 0, NULL),
(9011112, 0, 0, 1, 0, 0, 0, NULL);
