-- A female human Exhausted Refugee for the Snowsong Valley watchtower (the user dressed some refugees as women): a copy of
-- the human refugee with the same talk window, prayer credit and outfit on the human female body.
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(164542,0,0,0,0,0,'Exhausted Refugee','',NULL,9920104,25,25,0,12,1,1,1.14286,1,1,20,0,0,1,0,0,1,1,1,768,0,0,0,7,0,0,0,0,0,0,0,0,'SmartAI',0,1,1,1,1,1,0,0,1,0,0,'',0) ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `npcflag` = VALUES(`npcflag`), `AIName` = VALUES(`AIName`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 164542;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(164542, 0, 50, 1, 1, 0);
DELETE FROM `creature_display_preset` WHERE `entry` = 164542;
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164542,50,1,1,1,3,8,4,1,7,0,0,0,0,5967,0,22147,0,26447,86103,0,0);
DELETE FROM `smart_scripts` WHERE `entryorguid` = 164542 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164542,0,0,1,62,0,100,0,9920104,0,0,0,0,0,33,164068,0,0,0,0,0,7,0,0,0,0,0,0,0,0,'Exhausted Refugee - On Gossip Option 0 Selected - Quest Credit \'Prayers offered\''),
(164542,0,1,2,61,0,100,0,0,0,0,0,0,0,72,0,0,0,0,0,0,7,0,0,0,0,0,0,0,0,'Exhausted Refugee - Linked - Close Gossip'),
(164542,0,2,3,61,0,100,0,0,0,0,0,0,0,83,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Exhausted Refugee - Linked - Remove Npc Flag Gossip'),
(164542,0,3,0,61,0,100,0,0,0,0,0,0,0,67,1,120000,120000,0,0,0,1,0,0,0,0,0,0,0,0,'Exhausted Refugee - Linked - Create Timed Event 1 (2 min)'),
(164542,0,4,0,59,0,100,0,1,0,0,0,0,0,82,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Exhausted Refugee - On Timed Event 1 - Add Npc Flag Gossip');
