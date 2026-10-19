-- Dun Kazad gryphon master Moer Stonefist (a dwarf, on the roost north-west of town), Grisalda stays at her post, and the
-- Dun Kazad <-> Graysky flights follow the route flown in game from Moer's roost to Graysky (landing beside Grisalda).
-- Points the old routes no longer use are parked on route 3, which no flight uses.
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(165622, 0, 0, 0, 0, 0, 'Moer Stonefist', 'Gryphon Master', NULL, 4360, 65, 65, 0, 1377, 8193, 1, 1.14286, 1, 1, 20, 1, 0, 4.6, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 1573, 0, 0, 0, 0, 0, 0, '', 0, 1, 22.5, 3, 1, 1, 0, 0, 1, -12, 2, '', 12340) ON DUPLICATE KEY UPDATE `difficulty_entry_1` = VALUES(`difficulty_entry_1`), `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`), `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`), `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`), `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`), `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`), `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`), `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`), `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`), `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 165622;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(165622, 0, 3007, 1, 1, 0);
DELETE FROM `creature` WHERE `guid` = 9999221;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9999221, 165622, 0, 0, 0, 1, 1, 0, -6724.11, -16.8294, 581.315, 5.20087, 300, 0, 0, 79290, 0, 0, 0, 0, 0, '', NULL, 0, NULL);
UPDATE `creature` SET `MovementType` = 0, `wander_distance` = 0 WHERE `guid` = 9920722 AND `id` = 164175;
UPDATE `creature_addon` SET `path_id` = 0 WHERE `guid` = 9920722;
DELETE FROM `taxipathnode_dbc` WHERE `ID` IN (39819, 39928, 39934, 39929, 39935, 39820, 39930, 39933, 39932, 39821, 39822, 39823, 39824, 39825, 39794, 39795, 39796, 39797, 39798, 39799, 39800, 39801, 39802, 39803, 39804, 39805, 39806, 39807, 39826, 39827, 39828, 39829, 39830, 39831, 39832, 39833, 39834, 39835, 39836, 39837, 39838, 39839, 39840, 39841, 39842, 39843, 39844, 39808, 39809, 39810, 39811, 39812, 39813, 39814, 39815, 39816, 39817, 39818);
INSERT INTO `taxipathnode_dbc` (`ID`, `PathID`, `NodeIndex`, `ContinentID`, `LocX`, `LocY`, `LocZ`, `Flags`, `Delay`, `ArrivalEventID`, `DepartureEventID`) VALUES
(39819, 1988, 0, 0, -6728.20, -17.23, 582.82, 0, 0, 0, 0),
(39928, 1988, 1, 0, -6764.50, -3.59, 575.82, 0, 0, 0, 0),
(39934, 1988, 2, 0, -6897.55, 41.03, 532.35, 0, 0, 0, 0),
(39929, 1988, 3, 0, -6961.69, 84.25, 506.92, 0, 0, 0, 0),
(39935, 1988, 4, 0, -6984.58, 182.45, 468.48, 0, 0, 0, 0),
(39820, 1988, 5, 0, -7022.18, 326.75, 439.65, 0, 0, 0, 0),
(39930, 1988, 6, 0, -7064.52, 488.00, 418.89, 0, 0, 0, 0),
(39933, 1988, 7, 0, -7096.26, 608.94, 403.31, 0, 0, 0, 0),
(39932, 1988, 8, 0, -7141.21, 725.88, 398.69, 0, 0, 0, 0),
(39821, 1988, 9, 0, -7223.56, 890.30, 392.69, 0, 0, 0, 0),
(39822, 1988, 10, 0, -7238.17, 1069.56, 386.66, 0, 0, 0, 0),
(39823, 1988, 11, 0, -7141.77, 1124.66, 365.87, 0, 0, 0, 0),
(39824, 1988, 12, 0, -7074.31, 1124.31, 338.98, 0, 0, 0, 0),
(39825, 1988, 13, 0, -7050.46, 1130.10, 328.65, 0, 0, 0, 0),
(39794, 1987, 0, 0, -7050.46, 1130.10, 328.65, 0, 0, 0, 0),
(39795, 1987, 1, 0, -7074.31, 1124.31, 338.98, 0, 0, 0, 0),
(39796, 1987, 2, 0, -7141.77, 1124.66, 365.87, 0, 0, 0, 0),
(39797, 1987, 3, 0, -7238.17, 1069.56, 386.66, 0, 0, 0, 0),
(39798, 1987, 4, 0, -7223.56, 890.30, 392.69, 0, 0, 0, 0),
(39799, 1987, 5, 0, -7141.21, 725.88, 398.69, 0, 0, 0, 0),
(39800, 1987, 6, 0, -7096.26, 608.94, 403.31, 0, 0, 0, 0),
(39801, 1987, 7, 0, -7064.52, 488.00, 418.89, 0, 0, 0, 0),
(39802, 1987, 8, 0, -7022.18, 326.75, 439.65, 0, 0, 0, 0),
(39803, 1987, 9, 0, -6984.58, 182.45, 468.48, 0, 0, 0, 0),
(39804, 1987, 10, 0, -6961.69, 84.25, 506.92, 0, 0, 0, 0),
(39805, 1987, 11, 0, -6897.55, 41.03, 532.35, 0, 0, 0, 0),
(39806, 1987, 12, 0, -6764.50, -3.59, 575.82, 0, 0, 0, 0),
(39807, 1987, 13, 0, -6728.20, -17.23, 582.82, 0, 0, 0, 0),
(39826, 3, 0, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39827, 3, 1, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39828, 3, 2, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39829, 3, 3, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39830, 3, 4, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39831, 3, 5, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39832, 3, 6, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39833, 3, 7, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39834, 3, 8, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39835, 3, 9, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39836, 3, 10, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39837, 3, 11, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39838, 3, 12, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39839, 3, 13, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39840, 3, 14, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39841, 3, 15, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39842, 3, 16, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39843, 3, 17, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39844, 3, 18, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39808, 3, 19, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39809, 3, 20, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39810, 3, 21, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39811, 3, 22, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39812, 3, 23, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39813, 3, 24, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39814, 3, 25, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39815, 3, 26, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39816, 3, 27, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39817, 3, 28, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0),
(39818, 3, 29, 0, 0.00, 0.00, 0.00, 0, 0, 0, 0);
