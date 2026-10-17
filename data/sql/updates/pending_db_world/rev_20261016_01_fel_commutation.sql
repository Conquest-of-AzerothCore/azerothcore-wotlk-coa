-- Fel Commutation: portal object (8000053), crystals (9500101), quest credit creature (13514), the Orgrimmar,
-- Stormwind and Booty Bay spawns, and the Necromancer trainer (9004655) moved off the Orgrimmar portal.

DELETE FROM `npc_vendor` WHERE `entry` = 13514;
DELETE FROM `creature_default_trainer` WHERE `CreatureId` = 13514;
DELETE FROM `creature_equip_template` WHERE `CreatureID` = 13514 AND `ID` = 1;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES (13514, 0, 0, 0, 0, 0, 'Fel Commutation Credit', '', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, '', NULL) ON DUPLICATE KEY UPDATE `difficulty_entry_1` = VALUES(`difficulty_entry_1`), `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`), `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`), `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`), `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`), `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`), `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`), `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`), `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`), `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 13514 AND `Idx` = 0;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (13514, 0, 16480, 1, 1, NULL);
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES (8000053, 10, 12001, 'Fel Commutation Portal', '', '', '', 0.5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', NULL),
(9500101, 5, 6706, 'Fel Commutation Crystal', '', '', '', 0.3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', NULL) ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `unk1` = VALUES(`unk1`), `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`), `AIName` = VALUES(`AIName`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);
DELETE FROM `gameobject` WHERE `guid` = 9001406;
DELETE FROM `gameobject` WHERE `guid` = 9001407;
DELETE FROM `gameobject` WHERE `guid` = 9001408;
DELETE FROM `gameobject` WHERE `guid` = 9001409;
DELETE FROM `gameobject` WHERE `guid` = 9001410;
DELETE FROM `gameobject` WHERE `guid` = 9001425;
DELETE FROM `gameobject` WHERE `guid` = 9001426;
DELETE FROM `gameobject` WHERE `guid` = 9001427;
DELETE FROM `gameobject` WHERE `guid` = 9001411;
DELETE FROM `gameobject` WHERE `guid` = 9001412;
DELETE FROM `gameobject` WHERE `guid` = 9001413;
DELETE FROM `gameobject` WHERE `guid` = 9001414;
DELETE FROM `gameobject` WHERE `guid` = 9001415;
DELETE FROM `gameobject` WHERE `guid` = 9001416;
DELETE FROM `gameobject` WHERE `guid` = 9001417;
DELETE FROM `gameobject` WHERE `guid` = 9001418;
DELETE FROM `gameobject` WHERE `guid` = 9001419;
DELETE FROM `gameobject` WHERE `guid` = 9001420;
DELETE FROM `gameobject` WHERE `guid` = 9001421;
DELETE FROM `gameobject` WHERE `guid` = 9001422;
DELETE FROM `gameobject` WHERE `guid` = 9001423;
DELETE FROM `gameobject` WHERE `guid` = 9001424;
DELETE FROM `gameobject` WHERE `guid` = 9001428;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES (9001406, 8000053, 1, 0, 0, 1, 1, 1847.2312192511997, -4365.6331127135945, -13.226789674294576, 5.954818411603565, 0, 0, -0.163447, 0.986552, 300, 100, 1, '', NULL, 'AQC obj8000053 '),
(9001427, 8000053, 0, 0, 0, 1, 1, -8976.499855886093, 1042.6050646528677, 102.74195570192302, 2.830602387458285, 0, 0, -0.987935, -0.154869, 300, 100, 1, '', NULL, 'AQC obj8000053 '),
(9001407, 9500101, 1, 0, 0, 1, 1, 1849.4393229909372, -4365.796874930328, -12.336537694509982, 4.7124, 0, 0, 0.707103, -0.707111, 300, 100, 1, '', NULL, 'AQC obj9500101 '),
(9001410, 9500101, 1, 0, 0, 1, 1, 1845.3913601920588, -4364.748411602508, -12.309454037601322, 4.397396618477927, 0, 0, 0.809262, -0.587448, 300, 100, 1, '', NULL, 'AQC obj9500101 '),
(9001425, 9500101, 0, 0, 0, 1, 1, -8974.644902240414, 1041.7524660451763, 103.47929133861626, 1.2731805943326477, 0, 0, 0.594457, 0.804127, 300, 100, 1, '', NULL, 'AQC obj9500101 '),
(9001426, 9500101, 0, 0, 0, 1, 1, -8978.710471760947, 1042.7304346768806, 103.37220768170761, 1.5881839758547192, 0, 0, 0.713227, 0.700933, 300, 100, 1, '', NULL, 'AQC obj9500101 '),
(9001411, 2576, 1, 0, 0, 1, 1, 1847.3238220401945, -4365.49539739912, -14.44, 1.2473104291060872, 0, 0, 0.584006, 0.811749, 300, 100, 1, '', NULL, 'ACQC 3D view'),
(9001412, 180425, 1, 0, 0, 1, 1, 1845.9127269659155, -4364.918782105153, -13.273266492050405, 0.9453754364073492, 0, 0, 0.455281, 0.890348, 300, 100, 1, '', NULL, 'ACQC 3D view'),
(9001413, 180338, 1, 0, 0, 1, 1, 1846.0979403090685, -4365.189523201324, -13.288402360230828, 2.1862162944542893, 0, 0, 0.88806, 0.459727, 300, 100, 1, '', NULL, 'ACQC 3D view'),
(9001414, 180339, 1, 0, 0, 1, 1, 1845.683298633149, -4365.403371119036, -13.278402360230828, 2.1020822721057577, 0, 0, 0.867941, 0.496668, 300, 100, 1, '', NULL, 'ACQC 3D view'),
(9001415, 186328, 1, 0, 0, 1, 1, 1845.9093191201619, -4365.963737293635, -13.319396353081068, 6.191220970748789, 0, 0, -0.045966, 0.998943, 300, 100, 1, '', NULL, 'ACQC 3D view'),
(9001416, 180338, 1, 0, 0, 1, 1, 1848.8182365201249, -4366.253819867356, -13.292609803074347, 2.1862162944542893, 0, 0, 0.88806, 0.459727, 300, 100, 1, '', NULL, 'ACQC 3D view'),
(9001417, 180339, 1, 0, 0, 1, 1, 1848.4035948442054, -4366.4676677850675, -13.292609803074347, 2.1020822721057577, 0, 0, 0.867941, 0.496668, 300, 100, 1, '', NULL, 'ACQC 3D view'),
(9001418, 186328, 0, 0, 0, 1, 1, -8975.183900173786, 1042.9586083313663, 102.66934902313653, 3.067004946603509, 0, 0, -0.999305, -0.037285, 300, 100, 1, '', NULL, 'ACQC 3D view'),
(9001419, 180339, 0, 0, 0, 1, 1, -8974.948177023696, 1042.4022540317558, 102.62034301598676, 5.261051555140064, 0, 0, -0.489108, 0.872223, 300, 100, 1, '', NULL, 'ACQC 3D view'),
(9001420, 180338, 0, 0, 0, 1, 1, -8975.359040332209, 1042.1812336864589, 102.59034301598678, 5.3451855774885955, 0, 0, -0.451994, 0.892021, 300, 100, 1, '', NULL, 'ACQC 3D view'),
(9001421, 180425, 0, 0, 0, 1, 1, -8975.169150619731, 1041.9137516856952, 102.5554788841672, 4.104344719441656, 0, 0, -0.886359, 0.462999, 300, 100, 1, '', NULL, 'ACQC 3D view'),
(9001422, 180339, 0, 0, 0, 1, 1, -8977.686555510205, 1043.4191228206496, 102.39613557314325, 5.261051555140064, 0, 0, -0.489108, 0.872223, 300, 100, 1, '', NULL, 'ACQC 3D view'),
(9001423, 180338, 0, 0, 0, 1, 1, -8978.09741881872, 1043.1981024753527, 102.40613557314326, 5.3451855774885955, 0, 0, -0.451994, 0.892021, 300, 100, 1, '', NULL, 'ACQC 3D view'),
(9001424, 2576, 0, 0, 0, 1, 1, -8976.5900517873, 1042.4657610858771, 101.5087453762176, 4.406279712140393, 0, 0, -0.806645, 0.591037, 300, 100, 1, '', NULL, 'ACQC 3D view'),
(9001428, 8000053, 0, 0, 0, 1, 1, -14443.1, 502.024, 22.6662, 0, 0, 0, 0, 1, 300, 100, 1, '', NULL, 'ACQC 3D view');

UPDATE `creature` SET `position_x` = 1842.6174832686954, `position_y` = -4360.907450907754, `position_z` = -14.627, `orientation` = 2.2070116685753445 WHERE `guid` = 9004655;
