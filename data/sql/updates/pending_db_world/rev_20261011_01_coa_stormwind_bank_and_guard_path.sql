-- Stormwind: Bank of Stormwind, Trade District and a guard patrol on the CoA city.
--
-- CoA rebuilt Stormwind City, and rev_20260923_03_coa_stormwind.sql moved the stock spawns into it. This finishes
-- the bank and the auction house area, and fixes a few spawns that still sat in furniture, under the ground or
-- off the CoA floor. Refs #5834.
--
-- WHAT CHANGES (all on map 0)
--   Bank of Stormwind      Kirsten, Scott and Thomas Burnside, the three further bankers in Ascension's data (creature
--                          entries 137354 to 137356, models 1450, 1436 and 1437, one spawn each, with John Burnside's
--                          flags and gossip); Olivia, Newton and John Burnside nudged 0.9 to 3.7 yd; two Guild Vaults
--                          moved 22 and 28 yd and two deleted; three benches deleted, two benches and two chairs nudged.
--   Auction house area     Melris Malagan and Justine Demalier moved 2.5 and 2.8 yd, Chromie and the Guardian of Time
--                          nudged 0.6 yd, Stony Tark moved 4.2 yd and turned.
--   Pig and Whistle        Reese Langston turned to face 2.296 (position unchanged).
--   Champion's Hall        Vik "Angry" Smalls (added by rev_20261008_02_pvp_vendors.sql) moved 1.7 yd out of a chair.
--   Elsewhere              Theridran moved 3.5 yd. The Stormwind copy of the Staff of Talons pickup (guid 6941138) is
--                          deleted: it stood 16.5 yd under the ground, and the Worldforged data has the pickup only in
--                          Stonetalon Mountains.
--   Guard patrol           the Stormwind City Guard path 798590 (guid 79859) goes from 44 to 42 points. The guard walked
--                          down the ramp and around the wagon, which the guard on the opposite side of the bridge does
--                          not do. The stretch from (-9028.7, 453.2) to (-9034.6, 442.6), which ran at z 78 to 93 and
--                          down to z 77.9 at (-9010.8, 419.6), is replaced by points at z 93.3 to 93.6 around (-9035, 443)
--                          to match the opposite guard. The opposite guard's path 798570 (guid 79857) has points 13 to 21
--                          (the same count) nudged 0.3 to 2.3 yd and re-heighted onto the same deck.
--
-- Each UPDATE matches guid and entry, so a row something else has changed is left alone.
-- Generated with Azeroth World Editor 0.6.0, project "Stormwind Fixes".

DELETE FROM `npc_vendor` WHERE `entry` = 137354;
DELETE FROM `npc_vendor` WHERE `entry` = 137355;
DELETE FROM `npc_vendor` WHERE `entry` = 137356;
DELETE FROM `creature_default_trainer` WHERE `CreatureId` = 137354;
DELETE FROM `creature_default_trainer` WHERE `CreatureId` = 137355;
DELETE FROM `creature_default_trainer` WHERE `CreatureId` = 137356;
DELETE FROM `creature_equip_template` WHERE `CreatureID` = 137354 AND `ID` = 1;
DELETE FROM `creature_equip_template` WHERE `CreatureID` = 137355 AND `ID` = 1;
DELETE FROM `creature_equip_template` WHERE `CreatureID` = 137356 AND `ID` = 1;
DELETE FROM `gameobject` WHERE `guid` = 41911;
DELETE FROM `gameobject` WHERE `guid` = 41914;
DELETE FROM `gameobject` WHERE `guid` = 26293;
DELETE FROM `gameobject` WHERE `guid` = 26298;
DELETE FROM `gameobject` WHERE `guid` = 26294;
DELETE FROM `gameobject` WHERE `guid` = 6941138 AND `id` = 254223;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (137354, 0, 0, 0, 0, 0, 'Kirsten Burnside', 'Banker', NULL, 699, 45, 45, 0, 12, 131073, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 3.064, 1, 1, 1, 0, 0, 1, 0, 2, '', NULL),
(137355, 0, 0, 0, 0, 0, 'Scott Burnside', 'Banker', NULL, 699, 45, 45, 0, 12, 131073, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 3.064, 1, 1, 1, 0, 0, 1, 0, 2, '', NULL),
(137356, 0, 0, 0, 0, 0, 'Thomas Burnside', 'Banker', NULL, 699, 45, 45, 0, 12, 131073, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 3.064, 1, 1, 1, 0, 0, 1, 0, 2, '', NULL) ON DUPLICATE KEY UPDATE `difficulty_entry_1` = VALUES(`difficulty_entry_1`), `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`), `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`), `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`), `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`), `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`), `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`), `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`), `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`), `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 137354 AND `Idx` = 0;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 137355 AND `Idx` = 0;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 137356 AND `Idx` = 0;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (137354, 0, 1450, 1, 1, NULL),
(137355, 0, 1436, 1, 1, NULL),
(137356, 0, 1437, 1, 1, NULL);
DELETE FROM `creature` WHERE `guid` = 9950072;
DELETE FROM `creature` WHERE `guid` = 9950073;
DELETE FROM `creature` WHERE `guid` = 9950074;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES (9950072, 137354, 0, 0, 0, 1, 1, 0, -8893.477387417532, 624.4205584197554, 99.57, 2.094, 540, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'AQC npc137354 '),
(9950073, 137355, 0, 0, 0, 1, 1, 0, -8898.677387417532, 621.4205584197554, 99.57, 2.094, 540, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'AQC npc137355 '),
(9950074, 137356, 0, 0, 0, 1, 1, 0, -8903.877387417533, 618.4205584197554, 99.57, 2.094, 540, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'AQC npc137356 ');
DELETE FROM `waypoint_data` WHERE `id` = 798570;
DELETE FROM `waypoint_data` WHERE `id` = 798590;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES (798570, 1, -8986.57, 504.235, 96.7474, NULL, 0, 0, 0, 0, 0, 100, 0),
(798570, 2, -8975.61, 512.586, 96.6796, NULL, 0, 0, 0, 0, 0, 100, 0),
(798570, 3, -8969.25, 518.163, 96.6381, NULL, 0, 0, 0, 0, 0, 100, 0),
(798570, 4, -8965.98, 522.474, 96.6123, NULL, 0, 0, 0, 0, 0, 100, 0),
(798570, 5, -8965.6, 526.179, 96.5967, NULL, 0, 0, 0, 0, 0, 100, 0),
(798570, 6, -8965.98, 522.474, 96.6123, NULL, 0, 0, 0, 0, 0, 100, 0),
(798570, 7, -8969.25, 518.163, 96.6381, NULL, 0, 0, 0, 0, 0, 100, 0),
(798570, 8, -8975.61, 512.586, 96.6796, NULL, 0, 0, 0, 0, 0, 100, 0),
(798570, 9, -8986.57, 504.235, 96.7474, NULL, 0, 0, 0, 0, 0, 100, 0),
(798570, 10, -8995.8, 496.151, 96.8077, NULL, 0, 0, 0, 0, 0, 100, 0),
(798570, 11, -9005.76, 488.378, 96.8446, NULL, 0, 0, 0, 0, 0, 100, 0),
(798570, 12, -9018.34, 478.527, 96.3723, NULL, 0, 0, 0, 0, 0, 100, 0),
(798570, 13, -9030.105165350491, 469.2078479214951, 94.45516508035796, NULL, 0, 0, 0, 0, 0, 100, 0),
(798570, 14, -9036.161979697912, 464.5275582617167, 94.38195836680038, NULL, 0, 0, 0, 0, 0, 100, 0),
(798570, 15, -9048.089437022689, 459.0851952827103, 94.36292490420058, NULL, 0, 0, 0, 0, 0, 100, 0),
(798570, 16, -9055.68358355398, 456.30081245769617, 95.67188757440238, NULL, 0, 0, 0, 0, 0, 100, 0),
(798570, 17, -9074.360629919724, 445.61401450927116, 93.33343618534921, NULL, 0, 0, 0, 0, 0, 100, 0),
(798570, 18, -9055.787744279598, 456.6930072516817, 95.64973257897275, NULL, 0, 0, 0, 0, 0, 100, 0),
(798570, 19, -9048.057364429169, 459.3195749847535, 94.2234639834944, NULL, 0, 0, 0, 0, 0, 100, 0),
(798570, 20, -9036.000649560889, 464.17237152095015, 94.27021440300943, NULL, 0, 0, 0, 0, 0, 100, 0),
(798570, 21, -9030.105165350491, 469.2078479214951, 94.45516508035796, NULL, 0, 0, 0, 0, 0, 100, 0),
(798570, 22, -9018.34, 478.527, 96.3723, NULL, 0, 0, 0, 0, 0, 100, 0),
(798570, 23, -9005.76, 488.378, 96.8446, NULL, 0, 0, 0, 0, 0, 100, 0),
(798570, 24, -8995.8, 496.151, 96.8077, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 1, -8954.75, 509.356, 96.5967, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 2, -8950.37, 508.745, 96.3526, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 3, -8954.75, 509.356, 96.5967, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 4, -8958.4, 509.049, 96.5968, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 5, -8962.92, 505.806, 96.6263, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 6, -8971.03, 499.344, 96.6947, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 7, -8982.33, 490.5, 96.7894, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 8, -8989.75, 484.423, 96.8526, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 9, -8996.95, 478.284, 96.8013, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 10, -9004.83, 472.23, 96.726, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 11, -9012.17, 466.045, 96.0164, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 12, -9017.54924682057, 461.63976635739857, 95.50131920656816, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 13, -9021.956139605716, 457.8349396476704, 94.09972184575336, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 14, -9025.495626332895, 454.7580273816808, 93.1917, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 15, -9027.149241326315, 453.3260281259122, 93.2955, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 16, -9030.5885540022, 450.0343988191529, 93.80322146836713, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 17, -9033.242745692824, 447.21687500896104, 94.08267849705183, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 18, -9039.943735585002, 439.15291230638957, 93.99284105081057, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 19, -9041.961146556681, 435.79569991382715, 93.64405221781986, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 20, -9044.544554958686, 433.7449055286731, 93.51192007098359, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 21, -9049.127000366372, 428.57541969135866, 93.99163170192173, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 22, -9055.330168860779, 423.7933481743306, 93.95365783592078, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 23, -9049.127000366372, 428.57541969135866, 93.99163170192173, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 24, -9044.544554958686, 433.7449055286731, 93.51192007098359, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 25, -9041.70428924376, 437.0824313881217, 93.78048964597298, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 26, -9039.662430818868, 439.2478084514827, 93.41450660022798, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 27, -9037.857249413619, 441.69423814590283, 93.83743564608048, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 28, -9035.283904863478, 444.51095893751005, 93.74755660974425, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 29, -9032.568107079325, 446.95207742089036, 93.1772848776415, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 30, -9032.568107079325, 446.95207742089036, 93.1772848776415, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 31, -9027.149241326315, 453.3260281259122, 93.2955, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 32, -9025.495626332895, 454.7580273816808, 93.1917, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 33, -9022.108978122553, 457.8010209745503, 94.53723826668602, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 34, -9017.54924682057, 461.63976635739857, 95.50131920656816, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 35, -9012.17, 466.045, 96.0164, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 36, -9004.83, 472.23, 96.726, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 37, -8996.95, 478.284, 96.8013, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 38, -8989.75, 484.423, 96.8526, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 39, -8982.33, 490.5, 96.7894, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 40, -8971.03, 499.344, 96.6947, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 41, -8962.92, 505.806, 96.6263, NULL, 0, 0, 0, 0, 0, 100, 0),
(798590, 42, -8958.4, 509.049, 96.5968, NULL, 0, 0, 0, 0, 0, 100, 0);

UPDATE `creature` SET `position_x` = -8825.318626689004, `position_y` = 628.5299564994078, `position_z` = 94.34606603055597, `orientation` = 4.03171 WHERE `guid` = 79694 AND `id` = 12480;
UPDATE `creature` SET `position_x` = -8826.937432029017, `position_y` = 630.1900476061152, `position_z` = 94.34933504325156, `orientation` = 3.82227 WHERE `guid` = 79693 AND `id` = 12481;
UPDATE `gameobject` SET `position_x` = -8930.314076138235, `position_y` = 613.5530851871755, `position_z` = 101.66735120937396, `orientation` = 0.5233023371894414, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.25867587350254617, `rotation3` = 0.9659641776317043 WHERE `guid` = 41913 AND `id` = 187329;
UPDATE `gameobject` SET `position_x` = -8932.17165555619, `position_y` = 616.8596951364942, `position_z` = 101.68410238674126, `orientation` = 0.5230983817937753, `rotation0` = 0, `rotation1` = 0, `rotation2` = -0.25857736535464926, `rotation3` = -0.965990551778975 WHERE `guid` = 41912 AND `id` = 187329;
UPDATE `creature` SET `position_x` = -8903.273340130112, `position_y` = 642.3116405897727, `position_z` = 99.5729015650918, `orientation` = 5.13 WHERE `guid` = 79684 AND `id` = 2455;
UPDATE `creature` SET `position_x` = -8908.419856795725, `position_y` = 639.3534996059274, `position_z` = 99.57966305039308, `orientation` = 5.24327952072322 WHERE `guid` = 79853 AND `id` = 2457;
UPDATE `creature` SET `position_x` = -8913.582758225193, `position_y` = 636.3455238917148, `position_z` = 99.5632434277479, `orientation` = 5.216374097606385 WHERE `guid` = 79678 AND `id` = 2456;
UPDATE `gameobject` SET `position_x` = -8936.197140370483, `position_y` = 629.0591347171805, `position_z` = 100.226, `orientation` = 5.21854, `rotation0` = 0, `rotation1` = 0, `rotation2` = -0.507538, `rotation3` = 0.861629 WHERE `guid` = 26678 AND `id` = 24532;
UPDATE `gameobject` SET `position_x` = -8931.507505883654, `position_y` = 631.7249962890083, `position_z` = 100.226, `orientation` = 5.21854, `rotation0` = 0, `rotation1` = 0, `rotation2` = -0.507538, `rotation3` = 0.861629 WHERE `guid` = 26680 AND `id` = 24533;
UPDATE `gameobject` SET `position_x` = -8934.004932173568, `position_y` = 627.1970003959418, `position_z` = 100.24665864211497, `orientation` = 1.69297, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.748955, `rotation3` = 0.662621 WHERE `guid` = 26681 AND `id` = 17267;
UPDATE `gameobject` SET `position_x` = -8931.003392938763, `position_y` = 628.6046031535391, `position_z` = 100.226, `orientation` = 2.61799, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.965925, `rotation3` = 0.258821 WHERE `guid` = 26682 AND `id` = 17265;
UPDATE `creature` SET `position_x` = -8738.92597912794, `position_y` = 1091.217924088795, `position_z` = 92.542, `orientation` = 5.353 WHERE `guid` = 90466 AND `id` = 5505;
UPDATE `creature` SET `position_x` = -8607.74, `position_y` = 398.98, `position_z` = 102.924, `orientation` = 2.2960288144982917 WHERE `guid` = 79751 AND `id` = 1327;
UPDATE `creature` SET `position_x` = -8767.944569045309, `position_y` = 418.5181834312098, `position_z` = 103.921, `orientation` = 3.85431 WHERE `guid` = 9948066 AND `id` = 48066;
UPDATE `creature` SET `position_x` = -8820.999937489745, `position_y` = 625.5026382376525, `position_z` = 94.35186742832215, `orientation` = 3.78035 WHERE `guid` = 9780361 AND `id` = 178081;
UPDATE `creature` SET `position_x` = -8821.64, `position_y` = 626.98, `position_z` = 94.4500913102702, `orientation` = 3.79461 WHERE `guid` = 5300682 AND `id` = 9780012;
UPDATE `creature` SET `position_x` = -8869.618649682956, `position_y` = 570.4189103504543, `position_z` = 94.64580803133305, `orientation` = 2.0553260067899424 WHERE `guid` = 7905316 AND `id` = 10157257;
