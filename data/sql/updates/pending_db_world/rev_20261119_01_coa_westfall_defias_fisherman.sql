-- Defias guarding the Pilfered Lesser Healing Potions crate (gameobject guid 9001100) in Westfall, with the new
-- Defias Fisherman (35913).
-- The client's Creature.dbc names entry 35913 but its display 700004 is not in the client, and no capture has his
-- stats, loot or spawns. Level, look and weapon come from the PR author's review of original Ascension footage
-- (https://youtu.be/3Nl8pJ8tyWQ?t=6487): level 13, shirtless, green trousers, red bandana, fishing rod.
-- Stats, faction and loot are copied from Defias Trapper (504); the look is a stand-in preset built on the Trapper's
-- male display (2332) with the chest removed and green trousers (2082) in place of brown.
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`,
  `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`,
  `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`,
  `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`,
  `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`,
  `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`,
  `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`,
  `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(35913, 0, 0, 0, 0, 0, 'Defias Fisherman', '', NULL, 0, 13, 13, 0, 17, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000,
  1, 1, 1, 32768, 2048, 0, 0, 7, 134217728, 35913, 504, 0, 0, 0, 3, 27, '', 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, '', 0)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`),
  `faction` = VALUES(`faction`), `unit_flags` = VALUES(`unit_flags`), `type_flags` = VALUES(`type_flags`),
  `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`), `mingold` = VALUES(`mingold`),
  `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`), `HealthModifier` = VALUES(`HealthModifier`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 35913;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
  `VerifiedBuild`) VALUES
(35913, 0, 49, 1, 1, 0);
DELETE FROM `creature_display_preset` WHERE (`entry`, `display_id`) IN ((35913, 49));
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`,
  `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`,
  `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(35913, 49, 1, 0, 1, 5, 2, 5, 4, 4, 0, 144937, 0, 0, 0, 0, 2082, 154284, 156219, 0, 0, 0);
DELETE FROM `creature_equip_template` WHERE `CreatureID` = 35913;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(35913, 1, 6256, 0, 0, 0);
DELETE FROM `creature_loot_template` WHERE `Entry` = 35913;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
  `MinCount`, `MaxCount`, `Comment`) VALUES
(35913, 1, 1000112, 0, 0, 1, 5, 1, 1, 'Defias Fisherman - World Loot Level 12'),
(35913, 2, 1000113, 0, 0, 1, 5, 1, 1, 'Defias Fisherman - World Loot Level 13'),
(35913, 414, 0, 4.7468, 0, 1, 0, 1, 1, 'Defias Fisherman - Dalaran Sharp'),
(35913, 829, 0, 80, 1, 1, 0, 1, 1, 'Defias Fisherman - Red Leather Bandana'),
(35913, 1179, 0, 2.2364, 0, 1, 0, 1, 1, 'Defias Fisherman - Ice Cold Milk'),
(35913, 2287, 0, 0.0021, 0, 1, 0, 1, 1, 'Defias Fisherman - Haunch of Meat'),
(35913, 2589, 0, 38.0465, 0, 1, 0, 1, 3, 'Defias Fisherman - Linen Cloth'),
(35913, 2698, 0, 0.2, 0, 1, 0, 1, 1, 'Defias Fisherman - Recipe: Cooked Crab Claw'),
(35913, 4537, 0, 0.02, 0, 1, 0, 1, 1, 'Defias Fisherman - Tel''Abim Banana'),
(35913, 4541, 0, 0.02, 0, 1, 0, 1, 1, 'Defias Fisherman - Freshly Baked Bread'),
(35913, 4605, 0, 0.02, 0, 1, 0, 1, 1, 'Defias Fisherman - Red-speckled Mushroom'),
(35913, 5368, 0, 0.0021, 0, 1, 0, 1, 1, 'Defias Fisherman - Empty Wallet'),
(35913, 6256, 0, 5, 0, 1, 0, 1, 1, 'Defias Fisherman - Fishing Pole'),
(35913, 7997, 0, 2.0868, 0, 1, 0, 1, 1, 'Defias Fisherman - Red Defias Mask');
DELETE FROM `creature` WHERE `guid` BETWEEN 9950155 AND 9950160;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`,
  `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`,
  `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`,
  `CreateObject`, `Comment`) VALUES
(9950155, 35913, 0, 40, 919, 1, 1, 1, -10756.774, 1389.4547, 33.791695, 2.8617928, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0,
  0, 'Defias Fisherman (position from the PR author''s in-game .gps of the footage spot)'),
(9950156, 590, 0, 40, 919, 1, 1, 1, -10735.214, 1403.175, 34.829056, 3.3228478, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0,
  0, 'Defias Looter (position from the PR author''s in-game .gps of the footage spot)'),
(9950157, 589, 0, 40, 919, 1, 1, 1, -10729.958, 1384.9445, 35.818077, 0.6171224, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0,
  0, 'Defias Pillager (position from the PR author''s in-game .gps of the footage spot)'),
(9950158, 589, 0, 40, 919, 1, 1, 1, -10725.4795, 1383.271, 35.818077, 1.7245338, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0,
  0, 'Defias Pillager (position from the PR author''s in-game .gps of the footage spot)'),
(9950159, 589, 0, 40, 919, 1, 1, 1, -10747.861, 1369.7308, 34.83454, 1.8384256, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0,
  0, 'Defias Pillager (position from the PR author''s in-game .gps of the footage spot)'),
(9950160, 590, 0, 40, 919, 1, 1, 1, -10743.577, 1373.9274, 34.76121, 3.0416815, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0,
  0, 'Defias Looter sitting on the crate (position from the PR author''s in-game .gps of the footage spot)');
DELETE FROM `creature_addon` WHERE `guid` IN (9950155, 9950160);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`,
  `auras`) VALUES
(9950155, 0, 0, 0, 1, 379, 0, NULL),
(9950160, 0, 0, 0, 1, 426, 0, NULL);
DELETE FROM `gameobject` WHERE `guid` = 9001088;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
  `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(9001088, 179970, 0, 40, 919, 1, 1, -10743.41, 1373.9106, 34.762943, 3.0416815, 0, 0, 0.998752, 0.049935, 300, 100,
  1, '', 0, 'Replace Crate 02 the Defias Looter sits on (PR author''s in-game .gps of the footage spot)');
