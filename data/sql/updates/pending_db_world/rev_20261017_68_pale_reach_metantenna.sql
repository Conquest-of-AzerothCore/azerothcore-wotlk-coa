-- Metantenna, as the user set it up in game:
-- Sardragar is a trogg like the Antennasplitter Troggs around him (model 3970), not a dwarf, and stands where he was placed.
DELETE FROM `creature_template_model` WHERE `CreatureID` = 164399;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(164399, 0, 3970, 1, 1, 0);
DELETE FROM `creature_display_preset` WHERE `entry` = 164399;
UPDATE `creature` SET `position_x` = -6994.25, `position_y` = -61.875, `position_z` = 398.778, `orientation` = 4.1356 WHERE `guid` = 9990001 AND `id` = 164399;
-- The Metantenna Mekgineers lie dead around the station and cannot be selected or attacked.
UPDATE `creature_template` SET `unit_flags` = 33555202 WHERE `entry` = 164397;
DELETE FROM `creature_template_addon` WHERE `entry` = 164397;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(164397, 0, 0, 0, 1, 0, 0, '29266');
-- The Metantenna Alarm-o-bot that gives and takes the station's WARNING! quests is friendly to everyone and stands where it was placed.
UPDATE `creature_template` SET `faction` = 35 WHERE `entry` = 164396;
UPDATE `creature` SET `position_x` = -7156.16, `position_y` = -340.929, `position_z` = 423.498, `orientation` = 2.8228 WHERE `guid` = 9962202 AND `id` = 164396;
