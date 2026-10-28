-- Dun Kazad as placed in game: the NPCs and objects added around the town (the gryphon roost, the tannery, the
-- alchemist's, the smithy and the inn), their poses, two guard patrols, object sizes, and Callum Titanus, Clothier.
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(165633, 0, 0, 0, 0, 0, 'Callum Titanus', 'Clothier', NULL, 0, 18, 18, 0, 55, 80, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 2, '', 12340) ON DUPLICATE KEY UPDATE `difficulty_entry_1` = VALUES(`difficulty_entry_1`), `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`), `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`), `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`), `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`), `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`), `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`), `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`), `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`), `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 165633;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(165633, 0, 1821, 1, 1, 51831);
DELETE FROM `creature_default_trainer` WHERE `CreatureId` = 165633;
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`) VALUES
(165633, 74);
DELETE FROM `npc_vendor` WHERE `entry` = 165633;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES
(165633, 0, 837, 0, 0, 0, 0),
(165633, 0, 838, 0, 0, 0, 0),
(165633, 0, 839, 0, 0, 0, 0),
(165633, 0, 840, 0, 0, 0, 0),
(165633, 0, 3428, 0, 0, 0, 0),
(165633, 0, 3589, 0, 0, 0, 0),
(165633, 0, 3590, 0, 0, 0, 0),
(165633, 0, 4781, 1, 9000, 0, 0),
(165633, 0, 4782, 1, 9000, 0, 0),
(165633, 0, 4786, 1, 9000, 0, 0),
(165633, 0, 16059, 0, 0, 0, 0),
(165633, 0, 16060, 0, 0, 0, 0);
DELETE FROM `creature` WHERE `guid` IN (9999221, 9999222, 9999223, 9999225, 9999226, 9999232, 9999233, 9999234, 9999235, 9999240, 9999241, 9999246, 9999251, 9999252, 9999253, 9999257, 9999258, 9999262);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9999221, 165622, 0, 0, 0, 1, 1, 0, -6724.11, -16.8294, 581.315, 5.20087, 300, 0, 0, 79290, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999222, 164403, 0, 0, 0, 1, 1, 1, -6611.11, -301.273, 578.294, 1.24324, 300, 0, 0, 2614, 0, 2, 0, 0, 0, '', NULL, 0, NULL),
(9999223, 164403, 0, 0, 0, 1, 1, 1, -6720.33, -154.161, 570.139, 1.80322, 300, 0, 0, 2614, 0, 2, 0, 0, 0, '', NULL, 0, NULL),
(9999225, 165623, 0, 0, 0, 1, 1, 0, -6627.89, -191.825, 570.542, 2.55878, 300, 0, 0, 574, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999226, 165624, 0, 0, 0, 1, 1, 0, -6629.08, -193.382, 570.543, 2.43704, 300, 0, 0, 1127, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999232, 164403, 0, 0, 0, 1, 1, 1, -6562.79, -286.966, 577.778, 4.30894, 300, 0, 0, 2614, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999233, 164403, 0, 0, 0, 1, 1, 1, -6565.29, -295.149, 577.758, 1.16579, 300, 0, 0, 2614, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999234, 165625, 0, 0, 0, 1, 1, 0, -6513.31, -363.474, 565.702, 2.73265, 300, 0, 0, 328, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999235, 165626, 0, 0, 0, 1, 1, 0, -6513.09, -370.006, 565.096, 4.20685, 300, 0, 0, 328, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999240, 165627, 0, 0, 0, 1, 1, 1, -6617.23, -104.42, 572.133, 2.03128, 300, 0, 0, 798, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999241, 165628, 0, 0, 0, 1, 1, 1, -6620.85, -106.412, 572.047, 1.21211, 300, 0, 0, 1024, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999246, 165629, 0, 0, 0, 1, 1, 1, -6647.38, -180.864, 570.549, 4.8076, 300, 0, 0, 2336, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999251, 165631, 0, 0, 0, 1, 1, 1, -6645.42, -185.589, 570.548, 3.35303, 300, 0, 0, 195, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999252, 165630, 0, 0, 0, 1, 1, 1, -6641.02, -188.462, 570.448, 4.7628, 300, 0, 0, 971, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999253, 727, 0, 0, 0, 1, 1, 1, -6485.33, -226.632, 568.455, 1.54031, 300, 0, 0, 1933, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999257, 165632, 0, 0, 0, 1, 1, 1, -6474.75, -234.713, 568.448, 3.04123, 300, 0, 0, 1024, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999258, 164173, 0, 0, 0, 1, 1, 1, -6477.87, -234.234, 568.453, 0.109317, 300, 0, 0, 484, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999262, 165633, 0, 0, 0, 1, 1, 0, -6655.4, -302.561, 578.885, 0.472187, 300, 0, 0, 417, 0, 0, 0, 0, 0, '', NULL, 0, NULL);
DELETE FROM `creature_addon` WHERE `guid` IN (9999221, 9999222, 9999223, 9999225, 9999226, 9999232, 9999233, 9999234, 9999235, 9999240, 9999241, 9999246, 9999251, 9999252, 9999253, 9999257, 9999258, 9999262);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9999221, 0, 0, 0, 1, 313, 0, NULL),
(9999222, 9921108, 0, 0, 0, 0, 0, NULL),
(9999223, 9921109, 0, 0, 0, 0, 0, NULL),
(9999251, 0, 0, 0, 1, 69, 0, NULL),
(9999253, 0, 0, 4, 1, 0, 0, NULL),
(9999258, 0, 0, 4, 1, 605, 0, NULL);
DELETE FROM `waypoint_data` WHERE `id` IN (9921108, 9921109);
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES
(9921108, 1, -6611.11, -301.273, 578.294, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921108, 2, -6610.19, -298.582, 577.715, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921108, 3, -6608.24, -292.829, 577.722, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921108, 4, -6605.7, -285.353, 577.731, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921108, 5, -6602.24, -275.173, 577.743, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921108, 6, -6597.48, -261.175, 577.761, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921108, 7, -6600.37, -270.04, 577.754, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921108, 8, -6604.84, -283.75, 577.737, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921108, 9, -6611.14, -301.112, 578.285, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921109, 1, -6720.33, -154.161, 570.139, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921109, 2, -6720.33, -154.161, 570.139, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921109, 3, -6721.75, -139.589, 570.611, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921109, 4, -6720.23, -110.513, 570.05, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921109, 5, -6710.68, -99.2404, 570.036, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921109, 6, -6697.79, -98.1249, 570.86, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921109, 7, -6686.88, -100.015, 570.146, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921109, 8, -6677.1, -109.155, 570.029, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921109, 9, -6679.27, -118.656, 570.071, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921109, 10, -6681.33, -127.719, 570.348, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921109, 11, -6683.24, -134.799, 570.418, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921109, 12, -6685.86, -142.219, 570.411, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921109, 13, -6689.75, -153.257, 570.013, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921109, 14, -6705.39, -165.24, 571.083, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921109, 15, -6720.18, -154.404, 570.139, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `gameobject` WHERE `guid` IN (9999362, 9999389, 9999390, 9999392, 9999393, 9999395, 9999396, 9999397, 9999398, 9999399, 9999402, 9999403, 9999404, 9999431, 9999435, 9999436, 9999437, 9999438, 9999440, 9999441, 9999453, 9999454, 9999460, 9999463, 9999466, 9999468, 9999469, 9999494);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(9999362, 182254, 0, 0, 0, 1, 1, -6728.54, -17.4286, 581.312, 2.52504, 0, 0, 0.952858, 0.303418, 300, 0, 1, '', NULL, NULL),
(9999389, 182254, 0, 0, 0, 1, 1, -6712.69, -14.8791, 581.374, 0.853714, 0, 0, 0.414012, 0.910271, 300, 0, 1, '', NULL, NULL),
(9999390, 179975, 0, 0, 0, 1, 1, -6717.48, -13.5728, 581.329, 0.880403, 0, 0, 0.426122, 0.904666, 300, 0, 1, '', NULL, NULL),
(9999392, 180037, 0, 0, 0, 1, 1, -6721.51, -13.1568, 581.331, 4.69587, 0, 0, 0.712924, -0.701241, 300, 0, 1, '', NULL, NULL),
(9999393, 2300823, 0, 0, 0, 1, 1, -6711.26, -17.7813, 581.31, 1.28174, 0, 0, 0.597893, 0.801576, 300, 0, 1, '', NULL, NULL),
(9999395, 1967, 0, 0, 0, 1, 1, -6725.77, -23.3903, 581.244, 2.26192, 0, 0, 0.904821, 0.425792, 300, 0, 1, '', NULL, NULL),
(9999396, 1967, 0, 0, 0, 1, 1, -6710.35, -20.5821, 581.358, 0.177468, 0, 0, 0.0886178, 0.996066, 300, 0, 1, '', NULL, NULL),
(9999397, 32349, 0, 0, 0, 1, 1, -6488.69, -248.48, 576.765, 1.06023, 0, 0, 0.505633, 0.862749, 300, 0, 1, '', NULL, NULL),
(9999398, 180324, 0, 0, 0, 1, 1, -6629.71, -191.723, 570.508, 5.6155, -0, -0, -0.327676, 0.94479, 300, 0, 1, '', NULL, NULL),
(9999399, 2300812, 0, 0, 0, 1, 1, -6631.78, -195.287, 571.697, 4.0324, -0, -0, -0.902437, 0.430822, 300, 0, 1, '', NULL, NULL),
(9999402, 17251, 0, 0, 0, 1, 1, -6628.17, -195.362, 570.62, 2.54857, 0, 0, 0.956361, 0.292187, 300, 0, 1, '', NULL, NULL),
(9999403, 2300813, 0, 0, 0, 1, 1, -6632.85, -196.976, 570.549, 4.64478, 0, 0, 0.7306, -0.682806, 300, 0, 1, '', NULL, NULL),
(9999404, 2551, 0, 0, 0, 1, 1, -6628.54, -190.519, 571.389, 1.9925, 0, 0, 0.839438, 0.543456, 300, 0, 1, '', NULL, NULL),
(9999431, 2300814, 0, 0, 0, 1, 1, -6628.99, -191.207, 571.396, 0.0402814, 0, 0, 0.0201394, 0.999797, 300, 0, 1, '', NULL, NULL),
(9999435, 2300817, 0, 0, 0, 1, 1, -6616.98, -102.457, 573.021, 1.90248, 0, 0, 0.814135, 0.580676, 0, 0, 1, '', NULL, NULL),
(9999436, 2300815, 0, 0, 0, 1, 1, -6618.85, -103.316, 573.02, 0.172247, 0, 0, 0.0860169, 0.996294, 300, 0, 1, '', NULL, NULL),
(9999437, 2300815, 0, 0, 0, 1, 1, -6619.65, -103.454, 573.02, 0.172247, 0, 0, 0.0860169, 0.996294, 300, 0, 1, '', NULL, NULL),
(9999438, 2300816, 0, 0, 0, 1, 1, -6619.65, -103.454, 573.02, 0.172247, 0, 0, 0.0860169, 0.996294, 300, 0, 1, '', NULL, NULL),
(9999440, 180324, 0, 0, 0, 1, 1, -6618.03, -102.938, 572.133, 5.0417, -0, -0, -0.581639, 0.813447, 300, 0, 1, '', NULL, NULL),
(9999441, 2166, 0, 0, 0, 1, 1, -6636.1, -104.496, 580.701, 0.3129, -0, -0, -0.155812, -0.987787, 300, 0, 1, '', NULL, NULL),
(9999453, 174, 0, 0, 0, 1, 1, -6647.37, -182.658, 570.548, 5.2215, -0, -0, -0.50626, 0.862381, 300, 0, 1, '', NULL, NULL),
(9999454, 2300818, 0, 0, 0, 1, 1, -6644.64, -188.787, 570.548, 5.6103, 0, 0, -0.330131, 0.943935, 300, 0, 1, '', NULL, NULL),
(9999460, 185318, 0, 0, 0, 1, 1, -6647.13, -186.009, 577.094, 3.82741, 0, 0, 0.941781, -0.336228, 300, 0, 1, '', NULL, NULL),
(9999463, 21630, 0, 0, 0, 1, 1, -6646.31, -185.188, 570.548, 3.7792, -0, -0, -0.949611, 0.313431, 300, 0, 1, '', NULL, NULL),
(9999466, 2300820, 0, 0, 0, 1, 1, -6646.51, -176.535, 571.148, 0.3552, 0.305943, -0.435768, -0.27516, -0.800495, 300, 0, 1, '', NULL, NULL),
(9999468, 2300821, 0, 0, 0, 1, 1, -6641.59, -189.6, 570.548, 0.3154, 0, 0, -0.157047, -0.987591, 300, 0, 1, '', NULL, NULL),
(9999469, 2300822, 0, 0, 0, 1, 1, -6639.51, -189.072, 570.348, 2.1736, 0, 0, -0.885143, -0.46532, 300, 0, 1, '', NULL, NULL),
(9999494, 23296, 0, 0, 0, 1, 1, -6643.09, -285.409, 588.472, 4.48165, 0, 0, 0.783803, -0.621009, 300, 0, 1, '', NULL, NULL);
DELETE FROM `gameobject_scale` WHERE `guid` IN (9999362, 9999389, 9999390, 9999392, 9999393, 9999395, 9999396, 9999397, 9999398, 9999399, 9999402, 9999403, 9999404, 9999431, 9999435, 9999436, 9999437, 9999438, 9999440, 9999441, 9999453, 9999454, 9999460, 9999463, 9999466, 9999468, 9999469, 9999494);
INSERT INTO `gameobject_scale` (`guid`, `scale`) VALUES
(9999403, 0.5),
(9999441, 0.59),
(9999453, 1.067),
(9999466, 0.98),
(9999494, 0.478);
-- Eight Horde Collaborators north of Graysky: the camp was too densely packed, so these were removed in game.
DELETE FROM `creature_addon` WHERE `guid` IN (9985037, 9985038, 9985039, 9985040, 9985041, 9985042, 9985043, 9985044);
DELETE FROM `creature` WHERE `guid` IN (9985037, 9985038, 9985039, 9985040, 9985041, 9985042, 9985043, 9985044) AND `id` IN (164443, 164445, 164446);
