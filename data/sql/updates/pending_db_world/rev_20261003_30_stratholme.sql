-- Stratholme fixes after ingame check (03.10.2026)
-- Cannon Master Willey: his own Crimson Riflemen (copy of 11054 with its AI) that the kit summons after he jumps onto
-- the cannon platform; about 20k health on Mythic (15.4k Heroic)

INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(9780720, 9780721, 9780722, 0, 0, 0, 'Crimson Rifleman', NULL, NULL, 0, 60, 60, 0, 67, 0, 1.0, 1.14286, 1.0, 1.0, 18.0, 0, 0, 1.0, 2000, 2000, 1.0, 1.0, 1, 0, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 1, 1.0, 1.0, 1.0, 1.0, 1.0, 0, 0, 1, 0, 0, '', 0),
(9780721, 0, 0, 0, 0, 0, 'Crimson Rifleman', NULL, NULL, 0, 60, 60, 0, 67, 0, 1.0, 1.14286, 1.0, 1.0, 18.0, 0, 0, 2.22, 2000, 2000, 1.0, 1.0, 1, 0, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 1, 1.0, 1.0, 1.0, 1.0, 1.0, 0, 0, 1, 0, 0, '', 0),
(9780722, 0, 0, 0, 0, 0, 'Crimson Rifleman', NULL, NULL, 0, 60, 60, 0, 67, 0, 1.0, 1.14286, 1.0, 1.0, 18.0, 0, 0, 2.91, 2000, 2000, 1.0, 1.0, 1, 0, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 1, 1.0, 1.0, 1.0, 1.0, 1.0, 0, 0, 1, 0, 0, '', 0)
ON DUPLICATE KEY UPDATE `difficulty_entry_1` = VALUES(`difficulty_entry_1`), `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`), `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`), `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`), `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`), `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`), `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`), `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`), `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`), `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (9780720, 9780721, 9780722);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(9780720, 0, 10820, 1.0, 1.0, 0),
(9780720, 1, 10822, 1.0, 1.0, 0),
(9780720, 2, 10821, 1.0, 1.0, 0),
(9780720, 3, 10823, 1.0, 1.0, 0),
(9780721, 0, 10820, 1.0, 1.0, 0),
(9780721, 1, 10822, 1.0, 1.0, 0),
(9780721, 2, 10821, 1.0, 1.0, 0),
(9780721, 3, 10823, 1.0, 1.0, 0),
(9780722, 0, 10820, 1.0, 1.0, 0),
(9780722, 1, 10822, 1.0, 1.0, 0),
(9780722, 2, 10821, 1.0, 1.0, 0),
(9780722, 3, 10823, 1.0, 1.0, 0);
DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (9780720);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(9780720, 1, 11763, 0, 2552, 0);

DELETE FROM `coa_dungeon_health` WHERE `map_id` = 329 AND `creature_entry` = 9780720;
INSERT INTO `coa_dungeon_health` (`map_id`, `difficulty`, `creature_entry`, `max_health`, `evidence`, `source`) VALUES
(329, 1, 9780720, 15400, 'assumption', 'Willey''s riflemen (03.10.2026); Crimson Rifleman'),
(329, 2, 9780720, 20000, 'assumption', 'Willey''s riflemen (03.10.2026); Crimson Rifleman');

-- The Unforgiven (10516): Mythic 373k (ingame), Heroic /1.30
DELETE FROM `coa_dungeon_health` WHERE `map_id` = 329 AND `creature_entry` = 10516;
INSERT INTO `coa_dungeon_health` (`map_id`, `difficulty`, `creature_entry`, `max_health`, `evidence`, `source`) VALUES
(329, 1, 10516, 286923, 'source', 'Heroic from Mythic (03.10.2026); The Unforgiven'),
(329, 2, 10516, 373000, 'source', 'ingame 373k (03.10.2026); The Unforgiven');
