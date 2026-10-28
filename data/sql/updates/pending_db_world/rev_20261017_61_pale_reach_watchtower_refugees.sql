-- Light's Warmth (Snowsong Valley watchtower): the user's refugees, Sister Sarah and Soldier Rulven as dressed and posed in
-- game, on top of this branch's fires, Dry Stumps and prayer scripts (all kept). Same spots, mapped from the user's spawns
-- 99813xx/99814xx to these 99603xx/99604xx.
-- Sister Sarah is a dwarf woman; the refugees are human men except three dwarf men, who get their own copy of the
-- refugee (164541) with the same prayer menu and scripts as 164068.
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(164541,0,0,0,0,0,'Exhausted Refugee','',NULL,9997000,25,25,0,12,1,1,1.14286,1,1,20,0,0,1,0,0,1,1,1,768,0,0,0,7,0,0,0,0,0,0,0,0,'SmartAI',0,1,1,1,1,1,0,999,1,0,0,'',0) ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `npcflag` = VALUES(`npcflag`), `AIName` = VALUES(`AIName`), `faction` = VALUES(`faction`);
DELETE FROM `smart_scripts` WHERE `entryorguid` = 164541 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
SELECT 164541, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment` FROM `smart_scripts` WHERE `entryorguid` = 164068 AND `source_type` = 0;
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (164067, 164068, 164069, 164541);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(164067, 0, 54, 1, 1, 0),
(164068, 0, 49, 1, 1, 0),
(164069, 0, 49, 1, 1, 0),
(164541, 0, 53, 1, 1, 0);
DELETE FROM `creature_display_preset` WHERE `entry` IN (164067, 164068, 164069, 164541);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164067,54,3,1,1,3,9,5,7,3,0,11960,0,0,9706,0,22147,7769,26447,15993,0,0),
(164068,49,1,0,1,3,8,4,1,7,0,0,0,0,5967,0,22147,0,26447,86103,0,0),
(164069,49,1,0,1,3,8,4,1,7,0,0,0,147821,5202,11159,54948,71206,0,0,0,0),
(164541,53,3,0,1,3,8,3,1,7,0,0,0,0,12251,0,22147,44845,26447,15993,0,0);
UPDATE `creature` SET `id` = 164541 WHERE `guid` IN (9960399, 9960408, 9960410);
UPDATE `creature` SET `position_x` = -7002.77, `position_y` = 505.334, `position_z` = 350.394, `orientation` = 1.3853 WHERE `guid` = 9960398 AND `id` = 164067;
DELETE FROM `creature_addon` WHERE `guid` IN (9960399, 9960400, 9960401, 9960402, 9960403, 9960404, 9960406, 9960407, 9960408, 9960409, 9960410, 9960411);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9960399, 0, 0, 8, 1, 0, 0, ''),
(9960400, 0, 0, 3, 1, 0, 0, ''),
(9960401, 0, 0, 3, 1, 0, 0, ''),
(9960402, 0, 0, 1, 1, 0, 0, ''),
(9960403, 0, 0, 1, 1, 0, 0, ''),
(9960404, 0, 0, 3, 1, 0, 0, ''),
(9960406, 0, 0, 1, 1, 0, 0, ''),
(9960407, 0, 0, 1, 1, 0, 0, ''),
(9960408, 0, 0, 8, 1, 0, 0, ''),
(9960409, 0, 0, 3, 1, 0, 0, ''),
(9960410, 0, 0, 8, 1, 0, 0, ''),
(9960411, 0, 0, 3, 1, 0, 0, '');
