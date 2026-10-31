-- Road to De Other Side (map 937): Heroic/Mythic templates at +100000/+200000 for the hostile Bat of the Other Side
-- (162766, 162767), the last hostile Road creatures that fought with their Normal melee on every difficulty.
-- No log has a bat hit (the 2026-09-01 Road log only shows misses, parries and dodges), so Heroic is their Normal
-- DamageModifier of rev_20261029_85 times 1.544, the median Heroic / Normal of Road's trash there, and Mythic is
-- Heroic x 2.5 like the rest of Road's trash. Health stays with coa_dungeon_health (rev_20261029_82).

-- creature_template
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(262766,0,0,0,163814,0,'Bat of the Other Side','',NULL,0,60,60,0,14,0,1,1.14286,1,1,20,1,0,1.206,2000,0,1,1,1,0,0,0,0,1,1048576,162766,0,0,0,0,0,0,'',0,1,0.664,1,1,1,0,0,1,0,0,'',12340),
(262767,0,0,0,163814,0,'Bat of the Other Side','',NULL,0,60,60,0,14,0,1,1.14286,1,1,20,1,0,1.206,2000,0,1,1,1,0,0,0,0,1,1048576,162767,0,0,0,0,0,0,'',0,1,0.664,1,1,1,0,0,1,0,0,'',12340),
(362766,0,0,0,163814,0,'Bat of the Other Side','',NULL,0,60,60,0,14,0,1,1.14286,1,1,20,1,0,3.015,2000,0,1,1,1,0,0,0,0,1,1048576,162766,0,0,0,0,0,0,'',0,1,0.664,1,1,1,0,0,1,0,0,'',12340),
(362767,0,0,0,163814,0,'Bat of the Other Side','',NULL,0,60,60,0,14,0,1,1.14286,1,1,20,1,0,3.015,2000,0,1,1,1,0,0,0,0,1,1048576,162767,0,0,0,0,0,0,'',0,1,0.664,1,1,1,0,0,1,0,0,'',12340) ON DUPLICATE KEY UPDATE `difficulty_entry_1` = VALUES(`difficulty_entry_1`), `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`), `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`), `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`), `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`), `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`), `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`), `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`), `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`), `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- creature_template_model
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (262766, 262767, 362766, 362767);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(262766,0,141717,0.6,1,12340),
(262767,0,141717,0.6,1,12340),
(362766,0,141717,0.6,1,12340),
(362767,0,141717,0.6,1,12340);

-- creature_template_movement
DELETE FROM `creature_template_movement` WHERE `CreatureId` IN (262766, 262767, 362766, 362767);
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`, `Chase`, `Random`, `InteractionPauseTimer`) VALUES
(262766,1,0,1,0,0,0,0),
(262767,1,0,1,0,0,0,0),
(362766,1,0,1,0,0,0,0),
(362767,1,0,1,0,0,0,0);

UPDATE `creature_template` SET `difficulty_entry_1` = `entry` + 100000, `difficulty_entry_2` = `entry` + 200000 WHERE `entry` IN (162766, 162767);
