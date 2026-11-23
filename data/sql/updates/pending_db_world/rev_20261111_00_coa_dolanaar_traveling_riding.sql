-- Dolanaar's traveling riding NPCs: Sylindra Starweave <Traveling Riding Trainer> (449169), Maelira Rider <Traveling
-- Mount Merchant> (449168) and a Riding Striped Frostsaber (12358) stood together by the Dolanaar stable on Ascension
-- (gameplay footage). Entries, names, subnames and Maelira's two reins at 100g come from the db.exil.es mirror;
-- positions from in-game .gps matched to the footage. Level, flags and modifiers follow Garion Hunter and Pol Hunter
-- in Goldshire, with the Darnassus faction. Ascension's displays 449168/449169 do not resolve in the client, so
-- Sylindra uses 1727 (closest match) and Maelira 9270 (placeholder). Sylindra trains from Jartsam's riding list
-- (trainer 40) and his riding gossip (menu 4019), which teaches every Alliance race.
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`,
    `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`,
    `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`,
    `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`,
    `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`,
    `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`,
    `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`,
    `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(449169, 0, 0, 0, 0, 0, 'Sylindra Starweave', 'Traveling Riding Trainer', NULL, 4019, 10, 10, 0, 80, 83, 1,
    1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1,
    1.225, 1, 1, 1, 0, 0, 1, 0, 2, '', 0),
(449168, 0, 0, 0, 0, 0, 'Maelira Rider', 'Traveling Mount Merchant', NULL, 0, 10, 10, 0, 80, 128, 1,
    1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1,
    1.225, 1, 1, 1, 0, 0, 1, 0, 2, '', 0)
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

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (449168, 449169);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
    `VerifiedBuild`) VALUES
(449169, 0, 1727, 1, 1, 0),
(449168, 0, 9270, 1, 1, 0);

DELETE FROM `creature_default_trainer` WHERE `CreatureId` = 449169;
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`) VALUES
(449169, 40);

DELETE FROM `npc_vendor` WHERE `entry` = 449168;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES
(449168, 0, 12302, 0, 0, 0, 0),
(449168, 0, 12303, 0, 0, 0, 0);

DELETE FROM `creature` WHERE `guid` BETWEEN 9013400 AND 9013402;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`,
    `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`,
    `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`,
    `CreateObject`, `Comment`) VALUES
(9013400, 449169, 1, 0, 0, 1, 1, 0, 9897.029, 951.8342, 1312.0347, 4.0542593, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0,
    0, 'Sylindra Starweave, traveling riding trainer, by the Dolanaar stable'),
(9013401, 449168, 1, 0, 0, 1, 1, 0, 9898.83, 948.40497, 1312.6868, 3.6120934, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0,
    0, 'Maelira Rider, traveling mount merchant, beside Sylindra Starweave'),
(9013402, 12358, 1, 0, 0, 1, 1, 0, 9899.432, 946.29724, 1312.7339, 3.0967073, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0,
    0, 'Riding Striped Frostsaber on show beside Maelira Rider');

DELETE FROM `game_event_creature` WHERE `guid` BETWEEN 9013400 AND 9013402;

DELETE FROM `ascension_npc_overhead_icons` WHERE `creature_entry` = 449168;
INSERT INTO `ascension_npc_overhead_icons` (`creature_entry`, `spell_id`, `enabled`) VALUES
(449168, 982754, 1);
