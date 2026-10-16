-- Pale Reach fixes from the playtest review of PR #7047, one block per todo item (see the PR discussion).

-- #3: the Fel Cauldron Worldforged pickup (level 51) belongs to Felwood; the realm had no Worldforged pickups in Pale Reach.
DELETE FROM `gameobject` WHERE `guid` = 9920684 AND `id` = 517233;

-- #4: the quest cauldron is visible only while the sisters' chain needs it; everyone else sees a non-selectable copy.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `AIName`, `ScriptName`, `VerifiedBuild`)
VALUES
(2309001, 5, 300518, 'The Three Sisters', '', '', '', 1, 0, 0, 0, 0, 0, 0, '', '', 0)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`);

DELETE FROM `gameobject_template_addon` WHERE `entry` = 2309001;
INSERT INTO `gameobject_template_addon` (`entry`, `faction`, `flags`, `mingold`, `maxgold`) VALUES
(2309001, 0, 16, 0, 0);

DELETE FROM `gameobject` WHERE `guid` = 9999301;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(9999301, 2309001, 0, 0, 0, 1, 1, -7485.35, 663.074, 238.599, 0.05, 0, 0, 0.0249974, 0.999687, 300, 0, 1, 'Pale Reach: Three Sisters cauldron for players without the sisters quests');

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 30 AND `SourceGroup` = 1 AND `SourceEntry` IN (2300715, 2309001);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(30, 1, 2300715, 0, 0, 47, 0, 175203, 74, 0, 0, 0, 0, '', 'Three Sisters quest cauldron: The Three Sisters'' Wisdom in progress, complete or rewarded'),
(30, 1, 2300715, 0, 0, 47, 0, 175205, 1, 0, 0, 0, 0, '', 'Three Sisters quest cauldron: and News from Cresthairn not taken'),
(30, 1, 2309001, 0, 0, 47, 0, 175203, 33, 0, 0, 0, 0, '', 'Three Sisters plain cauldron: The Three Sisters'' Wisdom not taken or failed'),
(30, 1, 2309001, 0, 1, 47, 0, 175205, 106, 0, 0, 0, 0, '', 'Three Sisters plain cauldron: or News from Cresthairn taken, complete, failed or rewarded');

-- Playtest 2026-10-14: static Graysky Guards stacked on the Graysky Royal Guards at the keep gate; live sightings show only Royal Guards there.
DELETE FROM `creature` WHERE `guid` IN (9920754, 9920755) AND `id` = 164552;

-- Playtest 2026-10-14: the wandering Graysky Guard on the keep road duplicates the road patrol (user decision).
DELETE FROM `creature` WHERE `guid` = 9960838 AND `id` = 164173;

-- #79: the client reports the use on click (filter 2 fired then); filter 1 runs the teleport from the open-lock cast's completion.
UPDATE `smart_scripts` SET `event_param1` = 1 WHERE `entryorguid` IN (2310423, 2310427) AND `source_type` = 1 AND `id` = 0 AND `event_type` = 64;

-- Playtest 2026-10-14: the Scadeald mailbox beside the Plucked Rook Inn door (DuWTvw19xtg at 40:04); position and facing from the user's in-game .gps.
DELETE FROM `gameobject` WHERE `guid` = 9999302;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(9999302, 2310437, 0, 0, 0, 1, 1, -7125.164, 1019.128, 296.522, 3.417428, 0, 0, 0.990504, -0.137481, 300, 0, 1, 'Pale Reach: Graysky mailbox by the Plucked Rook Inn door');

-- #6: the live capture has both Ravens and Possessed Crows. Ravens stay level 1 and perch (sit) without the possession
-- aura; the export's captured kneel and cannibalize spawns keep their own rows and the two wanderers stand.
-- Possessed Crows are levels 18-21 as targeted in 2r0PE1dBarE, DuWTvw19xtg and F5g2uzWFLqA.
DELETE FROM `creature` WHERE `guid` = 9960829 AND `id` = 164371;
UPDATE `creature_template` SET `minlevel` = 18, `maxlevel` = 21 WHERE `entry` = 164944;
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 164371;

DELETE FROM `creature_template_addon` WHERE `entry` = 164371;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(164371, 0, 0, 1, 1, 0, 0, '');

DELETE FROM `creature_addon` WHERE `guid` IN (9961736, 9961872);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9961736, 0, 0, 0, 1, 0, 0, ''),
(9961872, 0, 0, 0, 1, 0, 0, '');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 164371 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `action_type`, `action_param1`, `action_param2`, `target_type`, `comment`) VALUES
(164371, 0, 0, 0, 7, 0, 100, 0, 91, 1, 0, 1, 'Raven - On evade - Clear sitting state before returning home; addon restores perch on arrival');

-- #8: Lyrielle pauses at both ends of her keep corridor walk instead of turning instantly (pause length inferred).
UPDATE `waypoint_data` SET `delay` = 5000 WHERE `id` = 99602080 AND `point` IN (1, 2);

-- #37: the SpawnHelper Ealdir Ambusher clone standing on the Oldmist road by Paulo Roble has no live counterpart.
DELETE FROM `creature` WHERE `guid` = 9920612 AND `id` = 9920070;

-- #38: Paulo Roble lies dead, posed like the Graysky soldier corpses.
UPDATE `creature_template` SET `unit_flags` = `unit_flags` | 768, `dynamicflags` = 32 WHERE `entry` = 164550;
DELETE FROM `creature_template_addon` WHERE `entry` = 164550;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(164550, 0, 0, 7, 1, 0, 0, '');

-- #41: the three SpawnHelper Jagged Cave Ealdir clones (template 9920071) double the live-captured cave spawns.
DELETE FROM `creature_addon` WHERE `guid` = 9920655;
DELETE FROM `waypoint_data` WHERE `id` = 9921011;
DELETE FROM `creature` WHERE `guid` IN (9920649, 9920651, 9920655) AND `id` = 9920071;

-- #99: the Graysky soldiers on the Kharadol Bridge (beside its quest objects) are corpses; the Kingsway and manor soldiers stay alive.
UPDATE `creature` SET `dynamicflags` = 32 WHERE `guid` IN (9960393, 9960394, 9960395, 9960396, 9960397) AND `id` = 164058;
DELETE FROM `creature_addon` WHERE `guid` IN (9960393, 9960394, 9960395, 9960396, 9960397);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9960393, 0, 0, 7, 1, 0, 0, ''),
(9960394, 0, 0, 7, 1, 0, 0, ''),
(9960395, 0, 0, 7, 1, 0, 0, ''),
(9960396, 0, 0, 7, 1, 0, 0, ''),
(9960397, 0, 0, 7, 1, 0, 0, '');

-- #101: all four Rockrend Guards are corpses (one already carried feign death).
UPDATE `creature_template` SET `dynamicflags` = 32 WHERE `entry` = 164325;
DELETE FROM `creature_addon` WHERE `guid` = 9960252;
DELETE FROM `creature_template_addon` WHERE `entry` = 164325;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(164325, 0, 0, 7, 1, 0, 0, '');

-- #46: the SpawnHelper Graysky Horse overlapping the live-captured Graysky Guard Horse in the Graysky stall.
DELETE FROM `creature` WHERE `guid` = 9920711 AND `id` = 164369;

-- #112: the Daumor Gryphons roost in their nests like the perched ones (sit + aura 365372, 0.8 yd above the nest, nest facing);
-- the four captured in flight above the nests move into the nearest free nests.
DELETE FROM `creature_template_addon` WHERE `entry` = 164188;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(164188, 0, 0, 1, 1, 0, 0, '365372');
UPDATE `creature` SET `position_x` = -7243.9, `position_y` = 382.6, `position_z` = 475.79, `orientation` = 5.361, `MovementType` = 0, `wander_distance` = 0 WHERE `guid` = 9960382 AND `id` = 164188;
UPDATE `creature` SET `position_x` = -7252.1, `position_y` = 395.1, `position_z` = 494.39, `orientation` = 4.426, `MovementType` = 0, `wander_distance` = 0 WHERE `guid` = 9960385 AND `id` = 164188;
UPDATE `creature` SET `position_x` = -7242.0, `position_y` = 417.7, `position_z` = 478.54, `orientation` = 4.993, `MovementType` = 0, `wander_distance` = 0 WHERE `guid` = 9960386 AND `id` = 164188;
UPDATE `creature` SET `position_x` = -7225.3, `position_y` = 468.5, `position_z` = 460.84, `orientation` = 0.399, `MovementType` = 0, `wander_distance` = 0 WHERE `guid` = 9960387 AND `id` = 164188;

-- Lord Cerios Locker stands in the Petitioner's Chamber (live spawn 634); the export dropped him in the air by the bandit cave.
UPDATE `creature` SET `position_x` = -8318.84, `position_y` = 306.292, `position_z` = 126.932, `orientation` = 4.8799 WHERE `guid` = 9960200 AND `id` = 164219;

-- The #6564 Stormwind Guard in attack stance by the bandit road; live sightings of 164427 are all inside Stormwind.
DELETE FROM `creature_addon` WHERE `guid` = 9999104;
DELETE FROM `creature` WHERE `guid` = 9999104 AND `id` = 164427;

-- Export spawns labelled with a live spawn id but standing elsewhere: move them to that live position, and drop the
-- Aerendyl copy whose live id points at the spawn 9960107 already holds.
UPDATE `creature` SET `position_x` = -7835.0, `position_y` = 983.337, `position_z` = 180.849, `orientation` = 6.2794 WHERE `guid` = 9960016 AND `id` = 164348;
UPDATE `creature` SET `position_x` = -7798.34, `position_y` = 567.693, `position_z` = 136.265, `orientation` = 5.4503 WHERE `guid` = 9960020 AND `id` = 164118;
UPDATE `creature` SET `position_x` = -8375.67, `position_y` = 667.452, `position_z` = 95.289, `orientation` = 3.5826 WHERE `guid` = 9960157 AND `id` = 164272;
DELETE FROM `creature` WHERE `guid` = 9960117 AND `id` = 164108;

-- Deepstone Cave (bandit cave) world edits 2026-10-14 (CoAWorldEdit export): thinned bandits and marauders, the stray
-- Elwynn skunk, the camp sleeper moved, and work, sleep and kneel poses.
DELETE FROM `creature_addon` WHERE `guid` IN (9920315, 9920317, 9920319, 9920322, 9920323, 9920327, 9920329, 9961411, 9961435, 9961479, 9961493, 9999105);
DELETE FROM `creature` WHERE `guid` IN (9920315, 9920317, 9920319, 9920322, 9920323, 9961411, 9961479) AND `id` = 164020;
DELETE FROM `creature` WHERE `guid` IN (9920327, 9920329, 9961435, 9961493) AND `id` = 164021;
DELETE FROM `creature` WHERE `guid` = 9999105 AND `id` = 17467;
UPDATE `creature` SET `orientation` = 4.955 WHERE `guid` = 9961498 AND `id` = 164021;
UPDATE `creature` SET `position_x` = -7784.223, `position_y` = 867.927, `position_z` = 57.117, `orientation` = 3.1732 WHERE `guid` = 9961212 AND `id` = 164020;
DELETE FROM `creature_addon` WHERE `guid` IN (9961212, 9961397, 9961474, 9961498);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9961212, 0, 0, 3, 1, 0, 0, ''),
(9961397, 0, 0, 0, 1, 69, 0, ''),
(9961474, 0, 0, 0, 1, 69, 0, ''),
(9961498, 0, 0, 8, 1, 0, 0, '');

-- Each Stolen Goods crate yields one Stolen Goods.
UPDATE `gameobject_loot_template` SET `MinCount` = 1, `MaxCount` = 1 WHERE `Entry` = 2300635 AND `Item` = 559855;

-- No One to Bring Her Flowers names her Martha Argos; the gravestone object read "Agros".
UPDATE `gameobject_template` SET `name` = 'Martha Argos Gravestone' WHERE `entry` = 2310431;

-- #10: the Stormwind Keep door sticks from the keep side until the character first opens it from the hallway.
UPDATE `gameobject_template` SET `ScriptName` = 'go_coa_stormwind_keep_door' WHERE `entry` = 2300653;

DELETE FROM `gameobject` WHERE `guid` = 9999303;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(9999303, 2300653, 0, 0, 0, 1, 1, -8279.854, 269.369, 127.203, 3.7895, 0, 0, 0.947982, -0.318324, 300, 0, 1, 'Stormwind Keep: Petitioner''s Chamber hallway door, fitted to the keep doorway');

-- They Grabbed Her By The Ankle: each clue counts once per character and then disappears for that character.
UPDATE `gameobject_template` SET `ScriptName` = 'go_coa_shadewell_clue' WHERE `entry` BETWEEN 2300672 AND 2300676;

-- #13: Road Bandit and Road Marauder outfits and weapons, picked from the user's in-game wardrobe lookup against footage.
-- Both: Shadowcraft Cap 22380, Forest Garb 143957, Blackened Defias Gloves 22146, Alabaster Plate Leggings 21658,
-- Huntsman's Boots 14791. The Marauder adds Huntsman's Shoulders 1170 and two Iron Skull Swords 25155; the Bandit
-- carries one Stiletto 2494.
UPDATE `creature_display_preset` SET `item_head` = 22380, `item_shoulders` = 0, `item_chest` = 143957, `item_hands` = 22146, `item_legs` = 21658, `item_feet` = 14791 WHERE `entry` = 164020 AND `display_id` = 49;
UPDATE `creature_display_preset` SET `item_head` = 22380, `item_shoulders` = 1170, `item_chest` = 143957, `item_hands` = 22146, `item_legs` = 21658, `item_feet` = 14791 WHERE `entry` = 164021 AND `display_id` = 49;
UPDATE `creature_equip_template` SET `ItemID1` = 2494, `ItemID2` = 0 WHERE `CreatureID` = 164020 AND `ID` = 1;
UPDATE `creature_equip_template` SET `ItemID1` = 25155, `ItemID2` = 25155 WHERE `CreatureID` = 164021 AND `ID` = 1;

-- Shadewell murlocs added near the keep with CoAWorldEdit (playtest 2026-10-15), at their final in-game positions.
DELETE FROM `creature` WHERE `guid` IN (9999205, 9999206, 9999207, 9999208, 9999209, 9999210);
INSERT INTO `creature` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(9999205, 164023, 0, 1, 1, 0, -8173.206, 289.181, 118.554, 2.7614, 120, 0, 0, 'Shadewell Murloc Raider, user world edit 2026-10-15'),
(9999206, 164023, 0, 1, 1, 0, -8181.908, 271.384, 118.584, 2.9507, 120, 0, 0, 'Shadewell Murloc Raider, user world edit 2026-10-15'),
(9999208, 164024, 0, 1, 1, 0, -8146.657, 321.627, 119.535, 2.7190, 120, 0, 0, 'Shadewell Murloc Seer, user world edit 2026-10-15'),
(9999209, 164024, 0, 1, 1, 0, -8181.556, 251.334, 121.021, 2.1771, 120, 0, 0, 'Shadewell Murloc Seer, user world edit 2026-10-15'),
(9999210, 164023, 0, 1, 1, 0, -8245.872, 253.917, 118.931, 0.3628, 120, 0, 0, 'Shadewell Murloc Raider, user world edit 2026-10-15');

-- Scadeald Fox moved and sat down with CoAWorldEdit (playtest 2026-10-15).
UPDATE `creature` SET `position_x` = -7683.801, `position_y` = 685.565, `position_z` = 146.286, `orientation` = 0.2222 WHERE `guid` = 9960705 AND `id` = 164083;
DELETE FROM `creature_addon` WHERE `guid` = 9960705;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9960705, 0, 0, 1, 1, 0, 0, '');

-- Stormwind Guard 9960738 walks the Oldmist forest path and back: the user's CoAWorldEdit route (2026-10-15) centred on
-- the path's dirt texture, smoothed and resampled (46 points out, the same points back).
UPDATE `creature` SET `position_x` = -8205.54, `position_y` = 410.29, `position_z` = 117.17, `orientation` = 3.2830, `wander_distance` = 0, `MovementType` = 2 WHERE `guid` = 9960738 AND `id` = 164427;
DELETE FROM `creature_addon` WHERE `guid` = 9960738;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9960738, 99607380, 0, 0, 1, 0, 0, '');
DELETE FROM `waypoint_data` WHERE `id` = 99607380;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `delay`, `move_type`, `action`, `action_chance`) VALUES
(99607380, 1, -8205.54, 410.29, 117.17, NULL, 0, 0, 0, 100),
(99607380, 2, -8211.5, 408.7, 116.99, NULL, 0, 0, 0, 100),
(99607380, 3, -8217.71, 408.49, 117.08, NULL, 0, 0, 0, 100),
(99607380, 4, -8221.95, 409.86, 117.05, NULL, 0, 0, 0, 100),
(99607380, 5, -8224.24, 412.14, 117.03, NULL, 0, 0, 0, 100),
(99607380, 6, -8225.04, 417.32, 117.17, NULL, 0, 0, 0, 100),
(99607380, 7, -8220.26, 427.98, 117.19, NULL, 0, 0, 0, 100),
(99607380, 8, -8219.02, 441.85, 117.35, NULL, 0, 0, 0, 100),
(99607380, 9, -8222.18, 449.46, 117.11, NULL, 0, 0, 0, 100),
(99607380, 10, -8225.34, 457.06, 116.83, NULL, 0, 0, 0, 100),
(99607380, 11, -8231.0, 463.28, 116.79, NULL, 0, 0, 0, 100),
(99607380, 12, -8236.65, 469.49, 116.97, NULL, 0, 0, 0, 100),
(99607380, 13, -8242.98, 473.09, 116.92, NULL, 0, 0, 0, 100),
(99607380, 14, -8251.42, 475.75, 116.4, NULL, 0, 0, 0, 100),
(99607380, 15, -8259.86, 478.41, 116.31, NULL, 0, 0, 0, 100),
(99607380, 16, -8267.0, 478.14, 116.5, NULL, 0, 0, 0, 100),
(99607380, 17, -8274.13, 477.87, 116.77, NULL, 0, 0, 0, 100),
(99607380, 18, -8286.96, 481.83, 119.08, NULL, 0, 0, 0, 100),
(99607380, 19, -8295.75, 483.05, 120.32, NULL, 0, 0, 0, 100),
(99607380, 20, -8299.71, 485.15, 120.92, NULL, 0, 0, 0, 100),
(99607380, 21, -8301.63, 487.89, 121.36, NULL, 0, 0, 0, 100),
(99607380, 22, -8302.3, 493.53, 121.57, NULL, 0, 0, 0, 100),
(99607380, 23, -8300.23, 502.39, 120.82, NULL, 0, 0, 0, 100),
(99607380, 24, -8297.56, 505.76, 120.5, NULL, 0, 0, 0, 100),
(99607380, 25, -8291.81, 509.86, 119.97, NULL, 0, 0, 0, 100),
(99607380, 26, -8286.06, 513.97, 119.21, NULL, 0, 0, 0, 100),
(99607380, 27, -8282.49, 517.76, 118.99, NULL, 0, 0, 0, 100),
(99607380, 28, -8278.43, 528.0, 118.3, NULL, 0, 0, 0, 100),
(99607380, 29, -8274.36, 538.24, 118.56, NULL, 0, 0, 0, 100),
(99607380, 30, -8270.12, 545.88, 118.37, NULL, 0, 0, 0, 100),
(99607380, 31, -8269.45, 549.99, 118.23, NULL, 0, 0, 0, 100),
(99607380, 32, -8274.45, 561.06, 116.64, NULL, 0, 0, 0, 100),
(99607380, 33, -8273.6, 570.79, 112.97, NULL, 0, 0, 0, 100),
(99607380, 34, -8274.48, 576.91, 109.89, NULL, 0, 0, 0, 100),
(99607380, 35, -8278.68, 588.55, 103.61, NULL, 0, 0, 0, 100),
(99607380, 36, -8283.28, 597.71, 100.19, NULL, 0, 0, 0, 100),
(99607380, 37, -8285.25, 604.52, 98.98, NULL, 0, 0, 0, 100),
(99607380, 38, -8285.4, 609.45, 98.21, NULL, 0, 0, 0, 100),
(99607380, 39, -8283.87, 618.08, 96.71, NULL, 0, 0, 0, 100),
(99607380, 40, -8282.33, 626.7, 95.09, NULL, 0, 0, 0, 100),
(99607380, 41, -8284.93, 639.0, 93.56, NULL, 0, 0, 0, 100),
(99607380, 42, -8286.4, 652.37, 93.43, NULL, 0, 0, 0, 100),
(99607380, 43, -8289.63, 656.99, 93.42, NULL, 0, 0, 0, 100),
(99607380, 44, -8299.01, 662.63, 93.07, NULL, 0, 0, 0, 100),
(99607380, 45, -8306.24, 668.43, 92.32, NULL, 0, 0, 0, 100),
(99607380, 46, -8313.48, 674.23, 92.0, NULL, 0, 0, 0, 100),
(99607380, 47, -8306.24, 668.43, 92.32, NULL, 0, 0, 0, 100),
(99607380, 48, -8299.01, 662.63, 93.07, NULL, 0, 0, 0, 100),
(99607380, 49, -8289.63, 656.99, 93.42, NULL, 0, 0, 0, 100),
(99607380, 50, -8286.4, 652.37, 93.43, NULL, 0, 0, 0, 100),
(99607380, 51, -8284.93, 639.0, 93.56, NULL, 0, 0, 0, 100),
(99607380, 52, -8282.33, 626.7, 95.09, NULL, 0, 0, 0, 100),
(99607380, 53, -8283.87, 618.08, 96.71, NULL, 0, 0, 0, 100),
(99607380, 54, -8285.4, 609.45, 98.21, NULL, 0, 0, 0, 100),
(99607380, 55, -8285.25, 604.52, 98.98, NULL, 0, 0, 0, 100),
(99607380, 56, -8283.28, 597.71, 100.19, NULL, 0, 0, 0, 100),
(99607380, 57, -8278.68, 588.55, 103.61, NULL, 0, 0, 0, 100),
(99607380, 58, -8274.48, 576.91, 109.89, NULL, 0, 0, 0, 100),
(99607380, 59, -8273.6, 570.79, 112.97, NULL, 0, 0, 0, 100),
(99607380, 60, -8274.45, 561.06, 116.64, NULL, 0, 0, 0, 100),
(99607380, 61, -8269.45, 549.99, 118.23, NULL, 0, 0, 0, 100),
(99607380, 62, -8270.12, 545.88, 118.37, NULL, 0, 0, 0, 100),
(99607380, 63, -8274.36, 538.24, 118.56, NULL, 0, 0, 0, 100),
(99607380, 64, -8278.43, 528.0, 118.3, NULL, 0, 0, 0, 100),
(99607380, 65, -8282.49, 517.76, 118.99, NULL, 0, 0, 0, 100),
(99607380, 66, -8286.06, 513.97, 119.21, NULL, 0, 0, 0, 100),
(99607380, 67, -8291.81, 509.86, 119.97, NULL, 0, 0, 0, 100),
(99607380, 68, -8297.56, 505.76, 120.5, NULL, 0, 0, 0, 100),
(99607380, 69, -8300.23, 502.39, 120.82, NULL, 0, 0, 0, 100),
(99607380, 70, -8302.3, 493.53, 121.57, NULL, 0, 0, 0, 100),
(99607380, 71, -8301.63, 487.89, 121.36, NULL, 0, 0, 0, 100),
(99607380, 72, -8299.71, 485.15, 120.92, NULL, 0, 0, 0, 100),
(99607380, 73, -8295.75, 483.05, 120.32, NULL, 0, 0, 0, 100),
(99607380, 74, -8286.96, 481.83, 119.08, NULL, 0, 0, 0, 100),
(99607380, 75, -8274.13, 477.87, 116.77, NULL, 0, 0, 0, 100),
(99607380, 76, -8267.0, 478.14, 116.5, NULL, 0, 0, 0, 100),
(99607380, 77, -8259.86, 478.41, 116.31, NULL, 0, 0, 0, 100),
(99607380, 78, -8251.42, 475.75, 116.4, NULL, 0, 0, 0, 100),
(99607380, 79, -8242.98, 473.09, 116.92, NULL, 0, 0, 0, 100),
(99607380, 80, -8236.65, 469.49, 116.97, NULL, 0, 0, 0, 100),
(99607380, 81, -8231.0, 463.28, 116.79, NULL, 0, 0, 0, 100),
(99607380, 82, -8225.34, 457.06, 116.83, NULL, 0, 0, 0, 100),
(99607380, 83, -8222.18, 449.46, 117.11, NULL, 0, 0, 0, 100),
(99607380, 84, -8219.02, 441.85, 117.35, NULL, 0, 0, 0, 100),
(99607380, 85, -8220.26, 427.98, 117.19, NULL, 0, 0, 0, 100),
(99607380, 86, -8225.04, 417.32, 117.17, NULL, 0, 0, 0, 100),
(99607380, 87, -8224.24, 412.14, 117.03, NULL, 0, 0, 0, 100),
(99607380, 88, -8221.95, 409.86, 117.05, NULL, 0, 0, 0, 100),
(99607380, 89, -8217.71, 408.49, 117.08, NULL, 0, 0, 0, 100),
(99607380, 90, -8211.5, 408.7, 116.99, NULL, 0, 0, 0, 100);

-- Graysky Soldier patrol 9920346 and two moved Graysky Soldiers in the manor, from CoAWorldEdit (playtest 2026-10-15).
-- Repeated route nodes at one spot are kept once.
UPDATE `creature` SET `position_x` = -7796.931, `position_y` = 788.575, `position_z` = 143.508, `orientation` = 5.5509 WHERE `guid` = 9960869 AND `id` = 164027;
UPDATE `creature` SET `position_x` = -7798.260, `position_y` = 780.533, `position_z` = 143.507, `orientation` = 2.4643 WHERE `guid` = 9960878 AND `id` = 164027;
UPDATE `creature` SET `position_x` = -7805.994, `position_y` = 792.000, `position_z` = 150.644, `orientation` = 3.1416 WHERE `guid` = 9920346 AND `id` = 164027;
DELETE FROM `waypoint_data` WHERE `id` = 99203460;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `delay`, `move_type`, `action`, `action_chance`) VALUES
(99203460, 1, -7805.994, 792.000, 150.644, 3.1416, 5000, 0, 0, 100),
(99203460, 2, -7811.000, 792.500, 150.644, NULL, 0, 0, 0, 100),
(99203460, 3, -7804.000, 794.000, 150.644, NULL, 0, 0, 0, 100),
(99203460, 4, -7802.337, 792.753, 150.644, NULL, 0, 0, 0, 100),
(99203460, 5, -7799.903, 790.711, 150.644, NULL, 0, 0, 0, 100),
(99203460, 6, -7801.000, 787.000, 150.644, NULL, 0, 0, 0, 100),
(99203460, 7, -7801.000, 788.724, 150.644, NULL, 0, 0, 0, 100),
(99203460, 8, -7801.827, 791.207, 150.644, NULL, 0, 0, 0, 100),
(99203460, 9, -7803.759, 791.690, 150.644, NULL, 0, 0, 0, 100),
(99203460, 10, -7811.000, 792.500, 150.644, 0.464, 10000, 0, 0, 100);

-- Graysky Soldier patrol 9920347 in the manor, from CoAWorldEdit (playtest 2026-10-15). Repeated route nodes at one spot
-- are kept once.
UPDATE `creature` SET `position_x` = -7771.000, `position_y` = 784.000, `position_z` = 149.966, `orientation` = 3.0000 WHERE `guid` = 9920347 AND `id` = 164027;
DELETE FROM `waypoint_data` WHERE `id` = 99203470;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `delay`, `move_type`, `action`, `action_chance`) VALUES
(99203470, 1, -7771.000, 784.000, 149.966, NULL, 0, 0, 0, 100),
(99203470, 2, -7765.461, 776.383, 150.581, 5.0341, 7000, 0, 0, 100),
(99203470, 3, -7766.000, 772.000, 150.724, NULL, 0, 0, 0, 100),
(99203470, 4, -7768.726, 775.407, 150.482, NULL, 0, 0, 0, 100),
(99203470, 5, -7770.458, 780.206, 150.255, NULL, 0, 0, 0, 100),
(99203470, 6, -7771.000, 784.000, 149.966, NULL, 0, 0, 0, 100),
(99203470, 7, -7766.591, 779.775, 150.354, NULL, 0, 0, 0, 100),
(99203470, 8, -7765.029, 775.088, 150.671, NULL, 0, 0, 0, 100),
(99203470, 9, -7766.000, 772.000, 150.724, NULL, 0, 0, 0, 100),
(99203470, 10, -7766.176, 772.220, 150.708, 2.2456, 10000, 0, 0, 100);

-- Possessed Crows and Ravens are crow-sized: footage shows them a third of a crate's width, and the client's other
-- displays of raven.m2 run at 0.5-0.75. Scale 0.65 by user choice (2026-10-15).
UPDATE `creature_template_model` SET `DisplayScale` = 0.65 WHERE `CreatureID` IN (164371, 164944) AND `CreatureDisplayID` = 32546;
