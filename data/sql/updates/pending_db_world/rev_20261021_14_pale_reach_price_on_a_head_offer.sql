-- The Price On A Head (175038) is not taken from Raigh Anramor. Walking up the Ealdmaine Caverns past him after The
-- Ealdir Trial of Strength offers it (Redthedeer VOD DuWTvw19xtg, 00:42:32), each time the player enters the spot
-- until it is accepted. An invisible trigger there starts the quest through npc_coa_area_quest_offer.
DELETE FROM `creature_queststarter` WHERE `id` IN (164047, 9920211) AND `quest` = 175038;
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES
(9920211, 175038);

INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(9920211, 0, 0, 0, 0, 0, 'Ealdmaine Caverns Quest Offer', '', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 0, 0, 1, 1, 1, 33554432, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 130, 'npc_coa_area_quest_offer', 0) ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `unit_flags` = VALUES(`unit_flags`), `type` = VALUES(`type`), `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 9920211;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(9920211, 0, 11686, 1, 1, 0);

DELETE FROM `creature` WHERE `guid` = 9922300;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9922300, 9920211, 0, 0, 0, 1, 1, 0, -7450.889, 621.878, 128.108, 5.6402, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'The Price On A Head offer, up the cavern from Raigh Anramor');
