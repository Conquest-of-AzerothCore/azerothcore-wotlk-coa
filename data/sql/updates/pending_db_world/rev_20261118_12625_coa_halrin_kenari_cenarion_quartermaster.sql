-- Halrin Kenari <Cenarion Circle Quartermaster> (115175) is the Ascension vendor for the Cenarion Circle rewards
-- (Formula: Enchant Bracer - Lesser Expertise 46514 and the Ascension rewards 856000-856033, 1312121,
-- 1519807-1519873) and had no template here. Name, subname, type, type_flags, HealthModifier and model come from the
-- captured WDB (creaturecache, 2026-09-07); level 57, faction 994, npcflag 3203, unit_flags 32768, speeds, attack
-- time, main hand 128306 and the Cenarion Hold position from a live sniff (wowsniff_12340, 2026-09-01). Model
-- 650603 is in neither the client nor the server DBC; the sniff's UNIT_FIELD_DISPLAYID 55 is used instead. The
-- vendor list is SUB npc_vendor (db.exil.es dump, 2026-10-04), matching the Exiles DB page.
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`,
    `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`,
    `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`,
    `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`,
    `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`,
    `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`,
    `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`,
    `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(115175, 0, 0, 0, 0, 0, 'Halrin Kenari', 'Cenarion Circle Quartermaster', NULL, 0, 57, 57, 0, 994, 3203, 1,
    1.14286, 1, 1, 20, 0, 0, 1, 2000, 2000, 1, 1, 1, 32768, 2048, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1,
    1.37, 1, 1, 1, 0, 999, 1, 0, 2, '', 0)
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

DELETE FROM `creature_template_model` WHERE `CreatureID` = 115175;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
    `VerifiedBuild`) VALUES
(115175, 0, 55, 1, 1, 0);

DELETE FROM `creature_equip_template` WHERE `CreatureID` = 115175;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(115175, 1, 128306, 0, 0, 0);

DELETE FROM `npc_vendor` WHERE `entry` = 115175;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES
(115175, 0, 46514, 0, 0, 0, 0),
(115175, 0, 856000, 0, 0, 0, 0),
(115175, 0, 856001, 0, 0, 0, 0),
(115175, 0, 856002, 0, 0, 0, 0),
(115175, 0, 856028, 0, 0, 0, 0),
(115175, 0, 856030, 0, 0, 0, 0),
(115175, 0, 856031, 0, 0, 0, 0),
(115175, 0, 856032, 0, 0, 0, 0),
(115175, 0, 856033, 0, 0, 0, 0),
(115175, 0, 1312121, 0, 0, 0, 0),
(115175, 0, 1519807, 0, 0, 0, 0),
(115175, 0, 1519808, 0, 0, 0, 0),
(115175, 0, 1519809, 0, 0, 0, 0),
(115175, 0, 1519862, 0, 0, 0, 0),
(115175, 0, 1519863, 0, 0, 0, 0),
(115175, 0, 1519864, 0, 0, 0, 0),
(115175, 0, 1519866, 0, 0, 0, 0),
(115175, 0, 1519868, 0, 0, 0, 0),
(115175, 0, 1519869, 0, 0, 0, 0),
(115175, 0, 1519870, 0, 0, 0, 0),
(115175, 0, 1519871, 0, 0, 0, 0),
(115175, 0, 1519872, 0, 0, 0, 0),
(115175, 0, 1519873, 0, 0, 0, 0);

DELETE FROM `creature` WHERE `guid` = 9074250;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`,
    `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`,
    `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`,
    `CreateObject`, `Comment`) VALUES
(9074250, 115175, 1, 0, 0, 1, 1, 1, -6866.81, 736.435, 45.6623, 5.19951, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0,
    'Halrin Kenari, Cenarion Circle Quartermaster, Cenarion Hold');

DELETE FROM `game_event_creature` WHERE `guid` = 9074250;
