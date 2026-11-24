-- Terrance Denman <Ring Vendor> (1532172, 1532173) sold the Ascension level-60 rings in Stormwind and Orgrimmar
-- and had no template here. Name, subname, type, type_flags, HealthModifier and movementId come from the captured
-- WDB (creaturecache, 2026-09-09/10); the vendor list is the Exiles DB page (db.exil.es dump, 2026-09-13). Only the
-- base tier is sold for now: the Inscribed, Etched and Runed upgrades (ItemExtendedCost 62592-64738, each taking the
-- previous ring) unlock with later raid releases. Positions are the owner's in-game picks (Mage Quarter, and the
-- Valley of Strength house under the flight path bridge reported in #10515). Models 660002 and 660003 are in neither
-- DBC, so unused stock displays stand in: human male 1428 in Stormwind, orc male 1909 in Orgrimmar. Level, faction
-- and unit_flags follow the neighbouring city vendors (Stanly McCormick 30730, Horthus 3323).
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`,
    `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`,
    `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`,
    `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`,
    `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`,
    `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`,
    `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`,
    `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(1532172, 0, 0, 0, 0, 0, 'Terrance Denman', 'Ring Vendor', NULL, 0, 35, 35, 0, 12, 128, 1, 1.14286, 1, 1, 20, 0,
    0, 1, 2000, 2000, 1, 1, 1, 32768, 2048, 0, 0, 7, 4096, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.11, 1, 1, 1, 0, 999, 1,
    0, 2, '', 0),
(1532173, 0, 0, 0, 0, 0, 'Terrance Denman', 'Ring Vendor', NULL, 0, 30, 30, 0, 29, 128, 1, 1.14286, 1, 1, 20, 0,
    0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 4096, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.11, 1, 1, 1, 0, 999, 1,
    0, 2, '', 0)
ON DUPLICATE KEY UPDATE `difficulty_entry_1` = VALUES(`difficulty_entry_1`),
    `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`),
    `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`),
    `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`),
    `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`),
    `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`),
    `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`),
    `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`),
    `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`),
    `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`),
    `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`),
    `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`),
    `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`),
    `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`),
    `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`),
    `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`),
    `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`),
    `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`),
    `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`),
    `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`),
    `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`),
    `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`),
    `VerifiedBuild` = VALUES(`VerifiedBuild`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (1532172, 1532173);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
    `VerifiedBuild`) VALUES
(1532172, 0, 1428, 1, 1, 0),
(1532173, 0, 1909, 1, 1, 0);

DELETE FROM `npc_vendor` WHERE `entry` IN (1532172, 1532173);
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES
(1532172, 0, 1540585, 0, 0, 0, 0),
(1532172, 0, 1540586, 0, 0, 0, 0),
(1532172, 0, 1540587, 0, 0, 0, 0),
(1532172, 0, 1540588, 0, 0, 0, 0),
(1532172, 0, 1544934, 0, 0, 0, 0),
(1532172, 0, 1544935, 0, 0, 0, 0),
(1532173, 0, 1540585, 0, 0, 0, 0),
(1532173, 0, 1540586, 0, 0, 0, 0),
(1532173, 0, 1540587, 0, 0, 0, 0),
(1532173, 0, 1540588, 0, 0, 0, 0),
(1532173, 0, 1544934, 0, 0, 0, 0),
(1532173, 0, 1544935, 0, 0, 0, 0);

DELETE FROM `creature` WHERE `guid` IN (9074251, 9074252);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`,
    `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`,
    `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`,
    `CreateObject`, `Comment`) VALUES
(9074251, 1532172, 0, 0, 0, 1, 1, 0, -8855.885, 853.7891, 99.60983, 1.1356559, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0,
    0, 'Terrance Denman, Ring Vendor, Stormwind Mage Quarter'),
(9074252, 1532173, 1, 0, 0, 1, 1, 0, 1703.4021, -4269.6055, 33.37447, 4.1142635, 300, 0, 0, 0, 0, 0, 0, 0, 0, '',
    0, 0, 'Terrance Denman, Ring Vendor, Orgrimmar Valley of Strength');

DELETE FROM `game_event_creature` WHERE `guid` IN (9074251, 9074252);
