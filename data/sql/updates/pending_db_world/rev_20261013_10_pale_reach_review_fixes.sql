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

-- Two Graysky Soldiers moved in the manor, from CoAWorldEdit (playtest 2026-10-15).
UPDATE `creature` SET `position_x` = -7796.931, `position_y` = 788.575, `position_z` = 143.508, `orientation` = 5.5509 WHERE `guid` = 9960869 AND `id` = 164027;
UPDATE `creature` SET `position_x` = -7798.260, `position_y` = 780.533, `position_z` = 143.507, `orientation` = 2.4643 WHERE `guid` = 9960878 AND `id` = 164027;

-- Graysky Soldier patrol 9920346 through the manor's three floors, from CoAWorldEdit (playtest 2026-10-15 20:32).
UPDATE `creature` SET `position_x` = -7799.049, `position_y` = 808.671, `position_z` = 148.995, `orientation` = 0.7563 WHERE `guid` = 9920346 AND `id` = 164027;
DELETE FROM `waypoint_data` WHERE `id` = 99203460;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `delay`, `move_type`, `action`, `action_chance`) VALUES
(99203460, 1, -7799.049, 808.671, 148.995, NULL, 0, 0, 0, 100),
(99203460, 2, -7790.102, 818.000, 148.995, NULL, 0, 0, 0, 100),
(99203460, 3, -7786.240, 817.268, 148.995, NULL, 0, 0, 0, 100),
(99203460, 4, -7784.765, 814.077, 148.995, NULL, 0, 0, 0, 100),
(99203460, 5, -7789.397, 807.824, 148.995, NULL, 0, 0, 0, 100),
(99203460, 6, -7795.253, 804.296, 148.995, NULL, 0, 0, 0, 100),
(99203460, 7, -7799.652, 800.717, 150.644, NULL, 0, 0, 0, 100),
(99203460, 8, -7812.287, 788.612, 150.644, 3.8115, 5000, 0, 0, 100),
(99203460, 9, -7802.502, 777.307, 157.930, NULL, 0, 0, 0, 100),
(99203460, 10, -7795.450, 782.044, 157.930, NULL, 0, 0, 0, 100),
(99203460, 11, -7797.667, 790.739, 157.926, NULL, 0, 0, 0, 100),
(99203460, 12, -7796.546, 798.903, 157.928, NULL, 0, 0, 0, 100),
(99203460, 13, -7795.417, 805.436, 157.928, NULL, 0, 0, 0, 100),
(99203460, 14, -7793.421, 809.195, 157.928, 0.8184, 10000, 0, 0, 100);

-- Graysky Soldier 9920347 stands 5 s at the end of the Darengar Manor garden walkway facing the Gilneas fountain
-- (-7752.58, 757.57), walks once round it 6.75 yd out (clear of the benches and cypress planters), and returns.
UPDATE `creature` SET `position_x` = -7759.400, `position_y` = 765.900, `position_z` = 151.258, `orientation` = 5.3984 WHERE `guid` = 9920347 AND `id` = 164027;
DELETE FROM `waypoint_data` WHERE `id` = 99203470;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `delay`, `move_type`, `action`, `action_chance`) VALUES
(99203470, 1, -7759.400, 765.900, 151.258, 5.3984, 5000, 0, 0, 100),
(99203470, 2, -7756.856, 762.793, 151.345, NULL, 0, 0, 0, 100),
(99203470, 3, -7758.895, 759.955, 151.306, NULL, 0, 0, 0, 100),
(99203470, 4, -7759.241, 756.478, 151.300, NULL, 0, 0, 0, 100),
(99203470, 5, -7757.803, 753.294, 151.306, NULL, 0, 0, 0, 100),
(99203470, 6, -7754.965, 751.255, 151.291, NULL, 0, 0, 0, 100),
(99203470, 7, -7751.488, 750.909, 151.288, NULL, 0, 0, 0, 100),
(99203470, 8, -7748.304, 752.347, 151.342, NULL, 0, 0, 0, 100),
(99203470, 9, -7746.265, 755.185, 151.353, NULL, 0, 0, 0, 100),
(99203470, 10, -7745.919, 758.662, 151.326, NULL, 0, 0, 0, 100),
(99203470, 11, -7747.357, 761.846, 151.320, NULL, 0, 0, 0, 100),
(99203470, 12, -7750.195, 763.885, 151.282, NULL, 0, 0, 0, 100),
(99203470, 13, -7753.672, 764.231, 151.290, NULL, 0, 0, 0, 100),
(99203470, 14, -7756.856, 762.793, 151.345, NULL, 0, 0, 0, 100);

-- Possessed Crows and Ravens are crow-sized: footage shows them a third of a crate's width, and the client's other
-- displays of raven.m2 run at 0.5-0.75. Scale 0.65 by user choice (2026-10-15).
UPDATE `creature_template_model` SET `DisplayScale` = 0.65 WHERE `CreatureID` IN (164371, 164944) AND `CreatureDisplayID` = 32546;

-- #40 and #115: critter-sized Butterflies and Scadeald Beetles. The Scadeald Moth's moth_low.m2 at its display scale 0.15
-- spans 1.2 yd; butterfly.m2 spans 7.2 yd and silithidscarab2.m2 is 5.6 yd long at scale 1.
UPDATE `creature_template_model` SET `DisplayScale` = 0.17 WHERE `CreatureID` = 161847 AND `CreatureDisplayID` = 86531;
UPDATE `creature_template_model` SET `DisplayScale` = 0.15 WHERE `CreatureID` = 164578 AND `CreatureDisplayID` = 95172;

-- Where the Veil Wanes (175048): Holga's progress text. No capture shows it; written in her voice from the offer and
-- completion texts (inferred, 2026-10-15).
DELETE FROM `quest_request_items` WHERE `ID` = 175048;
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(175048, 0, 0, '<Holga''s breathing is shallow and ragged.>$B$BYou came back... Are the rifts closed? Do the Horned Ones still walk in that cave?', 0);

-- #76: Holga wears Deadly Gladiator's Kodohide Robes 49045 and holds a Shadow Council Kris 2075359, picked by the user from
-- the wardrobe against AscenSS 071226-222341 and 072526-190028.
UPDATE `creature_display_preset` SET `item_chest` = 49045 WHERE `entry` = 164372 AND `display_id` = 50;
DELETE FROM `creature_equip_template` WHERE `CreatureID` = 164372;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(164372, 1, 2075359, 0, 0, 0);
UPDATE `creature` SET `equipment_id` = 1 WHERE `guid` = 9920636 AND `id` = 164372;

-- #78: closing a Blackwood Rift is the 10 s channel 365373 at the rift (broken by damage or movement); only a finished
-- channel counts, and the rift then vanishes until its 60 s respawn.
UPDATE `gameobject_template` SET `ScriptName` = 'go_coa_blackwood_rift' WHERE `entry` = 2300660;

-- Nightweave Cave thinned and two Horned One patrols, plus a duplicate Scadeald Bear, from CoAWorldEdit (playtest
-- 2026-10-15 21:25).
DELETE FROM `creature_addon` WHERE `guid` IN (9961584, 9961582, 9961571, 9961572, 9961568, 9920675, 9961573, 9961799, 9961778, 9961547, 9920664, 9920663, 9961430, 9961874, 9961434, 9961886, 9920679, 9961594, 9961813, 9961587, 9920680, 9961791, 9920666, 9961143, 9961132, 9961144, 9961593);
DELETE FROM `creature` WHERE `guid` IN (9961584, 9961582, 9961571, 9961572, 9961568, 9920675, 9961573, 9961799, 9961778, 9961547, 9920664, 9920663, 9961430, 9961874, 9961434, 9961886, 9920679, 9961594, 9961813, 9961587, 9920680, 9961791, 9920666, 9961143, 9961132, 9961144) AND `id` = 164373;
DELETE FROM `creature` WHERE `guid` = 9961593 AND `id` = 164039;
UPDATE `creature` SET `position_x` = -7458.684, `position_y` = 1277.388, `position_z` = 61.566, `orientation` = 1.0029, `wander_distance` = 0, `MovementType` = 2 WHERE `guid` = 9961863 AND `id` = 164373;
UPDATE `creature` SET `position_x` = -7474.972, `position_y` = 1322.493, `position_z` = 58.127, `orientation` = 2.0459, `wander_distance` = 0, `MovementType` = 2 WHERE `guid` = 9961590 AND `id` = 164373;
DELETE FROM `creature_addon` WHERE `guid` IN (9961863, 9961590);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9961863, 99618630, 0, 0, 1, 0, 0, ''),
(9961590, 99615900, 0, 0, 1, 0, 0, '');
DELETE FROM `waypoint_data` WHERE `id` IN (99618630, 99615900);
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `delay`, `move_type`, `action`, `action_chance`) VALUES
(99618630, 1, -7458.684, 1277.388, 61.566, NULL, 0, 0, 0, 100),
(99618630, 2, -7449.026, 1303.605, 67.705, NULL, 0, 0, 0, 100),
(99618630, 3, -7452.468, 1321.669, 71.915, NULL, 0, 0, 0, 100),
(99618630, 4, -7463.390, 1340.723, 73.025, NULL, 0, 0, 0, 100),
(99618630, 5, -7481.990, 1357.149, 73.962, NULL, 0, 0, 0, 100),
(99618630, 6, -7498.240, 1350.308, 73.787, NULL, 0, 0, 0, 100),
(99618630, 7, -7507.902, 1333.373, 73.917, NULL, 0, 0, 0, 100),
(99618630, 8, -7499.794, 1315.604, 74.091, NULL, 0, 0, 0, 100),
(99618630, 9, -7494.574, 1298.027, 74.165, 5.1796, 10000, 0, 0, 100),
(99615900, 1, -7474.972, 1322.493, 58.127, NULL, 0, 0, 0, 100),
(99615900, 2, -7500.063, 1331.039, 58.051, NULL, 0, 0, 0, 100),
(99615900, 3, -7521.951, 1324.153, 60.630, NULL, 0, 0, 0, 100),
(99615900, 4, -7542.620, 1315.593, 64.818, NULL, 0, 0, 0, 100),
(99615900, 5, -7547.977, 1298.214, 64.917, NULL, 0, 0, 0, 100),
(99615900, 6, -7548.169, 1285.602, 65.066, NULL, 0, 0, 0, 100),
(99615900, 7, -7529.270, 1285.483, 64.819, NULL, 0, 0, 0, 100),
(99615900, 8, -7511.833, 1277.711, 64.962, NULL, 0, 0, 0, 100),
(99615900, 9, -7494.700, 1266.442, 65.194, NULL, 0, 0, 0, 100),
(99615900, 10, -7485.189, 1271.496, 63.898, NULL, 0, 0, 0, 100),
(99615900, 11, -7471.376, 1280.529, 60.495, NULL, 0, 0, 0, 100),
(99615900, 12, -7463.159, 1272.900, 60.139, NULL, 0, 0, 0, 100),
(99615900, 13, -7471.002, 1254.207, 60.897, NULL, 0, 0, 0, 100),
(99615900, 14, -7482.830, 1246.147, 61.208, NULL, 0, 0, 0, 100),
(99615900, 15, -7499.459, 1239.731, 60.697, NULL, 0, 0, 0, 100),
(99615900, 16, -7516.095, 1231.828, 57.108, NULL, 0, 0, 0, 100),
(99615900, 17, -7522.411, 1214.071, 56.430, NULL, 0, 0, 0, 100),
(99615900, 18, -7527.335, 1195.088, 58.054, 4.4767, 10000, 0, 0, 100),
(99615900, 19, -7549.366, 1196.035, 60.167, NULL, 0, 0, 0, 100),
(99615900, 20, -7555.770, 1208.018, 63.227, NULL, 0, 0, 0, 100),
(99615900, 21, -7552.028, 1224.466, 66.130, NULL, 0, 0, 0, 100),
(99615900, 22, -7535.740, 1245.801, 67.294, 1.0492, 10000, 0, 0, 100);

-- Ealdir Ambusher 9961381 removed with CoAWorldEdit (playtest 2026-10-15).
DELETE FROM `creature_addon` WHERE `guid` = 9961381;
DELETE FROM `creature` WHERE `guid` = 9961381 AND `id` = 164926;

-- Raven 9961736 on the ground removed with CoAWorldEdit (playtest 2026-10-15).
DELETE FROM `creature_addon` WHERE `guid` = 9961736;
DELETE FROM `creature` WHERE `guid` = 9961736 AND `id` = 164371;

-- Jagged Cave Ealdir: 9920657 moved and asleep, 9920656 removed, with CoAWorldEdit (playtest 2026-10-15).
UPDATE `creature` SET `position_x` = -7338.697, `position_y` = 1202.354, `position_z` = 62.948, `orientation` = 5.5982, `wander_distance` = 0, `MovementType` = 0 WHERE `guid` = 9920657 AND `id` = 164043;
DELETE FROM `creature_addon` WHERE `guid` IN (9920656, 9920657);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9920657, 0, 0, 3, 1, 0, 0, '');
DELETE FROM `creature` WHERE `guid` = 9920656 AND `id` = 164043;

-- More Jagged Cave Ealdir edits with CoAWorldEdit (playtest 2026-10-15): three removed, 9920658 kneels.
DELETE FROM `creature` WHERE `guid` IN (9961507, 9961512, 9961484) AND `id` = 164043;
DELETE FROM `creature_addon` WHERE `guid` IN (9961507, 9961512, 9961484, 9920658);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9920658, 0, 0, 8, 1, 0, 0, '');

-- #76: Holga lies stretched out along the shore with her kris in hand (AscenSS 071226-222341): the dead stand state, facing
-- along the water's edge, weapon drawn.
UPDATE `creature` SET `orientation` = 1.4835 WHERE `guid` = 9920636 AND `id` = 164372;
DELETE FROM `creature_addon` WHERE `guid` = 9920636;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9920636, 0, 0, 7, 1, 0, 0, '');

-- Tin Vein 9991110 in Nightweave Cave moved with CoAWorldEdit (playtest 2026-10-15).
UPDATE `gameobject` SET `position_x` = -7515.176, `position_y` = 1271.890, `position_z` = 65.412, `orientation` = 0.7854, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.382683, `rotation3` = 0.92388 WHERE `guid` = 9991110 AND `id` = 1732;

-- Carden's Diary (2300689) offers No Matter the Cost (175043) until the quest is taken; afterwards reading it shows the
-- journal itself, the quest's own text (the only recorded writing; AscenSS 071126-233952, c3a0y5pCKpE 14:51).
UPDATE `gameobject_template` SET `ScriptName` = 'go_coa_cardens_diary' WHERE `entry` = 2300689;
DELETE FROM `npc_text` WHERE `ID` = 2300689;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`) VALUES
(2300689, '<Journal found beside a man''s body.>$B$B“My dearest Alanna. The days wither away without your smile. Often, I find myself remembering how we made the impossible possible; an Ealdir and a Crusader, hopelessly in love. Ready for anything. Willing to defy our own; the Light, the gods of the woods.$B$BYou know me well, Alanna. So you know what I intend to do. If we made the impossible possible once before, why not try again?$B$BThis is my promise:$B$BI will bring you back, no matter the cost. And I know where to begin:$B$BThe Three Sisters from your stories.”', '<Journal found beside a man''s body.>$B$B“My dearest Alanna. The days wither away without your smile. Often, I find myself remembering how we made the impossible possible; an Ealdir and a Crusader, hopelessly in love. Ready for anything. Willing to defy our own; the Light, the gods of the woods.$B$BYou know me well, Alanna. So you know what I intend to do. If we made the impossible possible once before, why not try again?$B$BThis is my promise:$B$BI will bring you back, no matter the cost. And I know where to begin:$B$BThe Three Sisters from your stories.”', 0, 0, 1);

-- Restless Corpses 9960181 and 9961693 removed from the Cresthairn church stairwell with CoAWorldEdit (playtest 2026-10-15).
DELETE FROM `creature_addon` WHERE `guid` IN (9960181, 9961693);
DELETE FROM `creature` WHERE `guid` IN (9960181, 9961693) AND `id` = 164051;

-- Father Elroth welcomes only a player who carries Aid for Cresthairn (175011), the quest that sends them to him
-- (playtest 2026-10-15: he greeted on every return).
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 1 AND `SourceEntry` = 164013 AND `SourceId` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 1, 164013, 0, 0, 47, 0, 175011, 10, 0, 0, 0, 0, '', 'Father Elroth - welcome only while Aid for Cresthairn is in the log');

-- Alanna keeps her live spawn (capture 653) facing and cowers as in the user's playtest screenshot (emote state 431).
UPDATE `creature` SET `position_x` = -7611.7, `position_y` = 1333.53, `position_z` = 126.466, `orientation` = 0.9798 WHERE `guid` = 9960209 AND `id` = 164374;
DELETE FROM `creature_addon` WHERE `guid` = 9960209;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9960209, 0, 0, 0, 1, 431, 0, '');

-- Restless Corpse and Exhumed Risen loot as seen in the crypt (YzysjpunNbs 10:24-16:40): copper and Linen Cloth (1 or 3) or
-- Wool Cloth (1-2). Money matches the same-level Jagged Cave Ealdir; the cloth chances are estimates from a handful of kills.
UPDATE `creature_template` SET `lootid` = `entry`, `mingold` = 16, `maxgold` = 50 WHERE `entry` IN (164051, 164052);
DELETE FROM `creature_loot_template` WHERE `Entry` IN (164051, 164052);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164051, 2589, 0, 20, 0, 1, 0, 1, 3, 'Restless Corpse - Linen Cloth'),
(164051, 2592, 0, 30, 0, 1, 0, 1, 2, 'Restless Corpse - Wool Cloth'),
(164052, 2589, 0, 20, 0, 1, 0, 1, 3, 'Exhumed Risen - Linen Cloth'),
(164052, 2592, 0, 30, 0, 1, 0, 1, 2, 'Exhumed Risen - Wool Cloth');

-- Sir Aldrin Nublar patrols his level of the Cresthairn crypt (user request 2026-10-15): the central corridor past both live
-- capture spots, Alanna's room, the round room and the south-east room, pausing 5 s in each room. Route laid along the
-- corridor centre lines from the WMO geometry. The second capture spawn 9961919 is the same knight seen elsewhere on it.
DELETE FROM `creature` WHERE `guid` = 9961919 AND `id` = 164053;
UPDATE `creature` SET `position_x` = -7636.250, `position_y` = 1261.250, `position_z` = 127.058, `wander_distance` = 0, `MovementType` = 2 WHERE `guid` = 9961333 AND `id` = 164053;
DELETE FROM `creature_addon` WHERE `guid` IN (9961333, 9961919);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9961333, 99613330, 0, 0, 1, 0, 0, '');
DELETE FROM `waypoint_data` WHERE `id` = 99613330;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `delay`, `move_type`, `action`, `action_chance`) VALUES
(99613330, 1, -7636.250, 1261.250, 127.058, NULL, 0, 0, 0, 100),
(99613330, 2, -7644.300, 1270.000, 127.058, NULL, 0, 0, 0, 100),
(99613330, 3, -7632.000, 1287.500, 127.040, NULL, 0, 0, 0, 100),
(99613330, 4, -7620.400, 1301.500, 127.045, NULL, 0, 0, 0, 100),
(99613330, 5, -7620.400, 1306.000, 127.045, NULL, 0, 0, 0, 100),
(99613330, 6, -7627.000, 1314.500, 127.045, NULL, 0, 0, 0, 100),
(99613330, 7, -7626.070, 1317.000, 127.048, NULL, 0, 0, 0, 100),
(99613330, 8, -7621.200, 1323.500, 126.510, NULL, 0, 0, 0, 100),
(99613330, 9, -7620.400, 1330.600, 126.789, 1.4586, 5000, 0, 0, 100),
(99613330, 10, -7621.200, 1323.500, 126.510, NULL, 0, 0, 0, 100),
(99613330, 11, -7626.070, 1317.000, 127.048, NULL, 0, 0, 0, 100),
(99613330, 12, -7628.500, 1315.570, 127.045, NULL, 0, 0, 0, 100),
(99613330, 13, -7630.500, 1315.930, 127.045, NULL, 0, 0, 0, 100),
(99613330, 14, -7639.800, 1324.100, 127.045, NULL, 0, 0, 0, 100),
(99613330, 15, -7651.500, 1309.500, 126.843, NULL, 0, 0, 0, 100),
(99613330, 16, -7657.600, 1303.600, 126.494, 3.9103, 5000, 0, 0, 100),
(99613330, 17, -7643.000, 1319.000, 127.045, NULL, 0, 0, 0, 100),
(99613330, 18, -7635.000, 1319.400, 127.045, NULL, 0, 0, 0, 100),
(99613330, 19, -7620.400, 1305.500, 127.045, NULL, 0, 0, 0, 100),
(99613330, 20, -7632.000, 1287.500, 127.040, NULL, 0, 0, 0, 100),
(99613330, 21, -7644.300, 1272.500, 127.058, NULL, 0, 0, 0, 100),
(99613330, 22, -7644.300, 1268.000, 127.058, NULL, 0, 0, 0, 100),
(99613330, 23, -7638.700, 1261.500, 127.058, NULL, 0, 0, 0, 100),
(99613330, 24, -7638.400, 1258.000, 127.439, NULL, 0, 0, 0, 100),
(99613330, 25, -7643.500, 1252.200, 127.007, NULL, 0, 0, 0, 100),
(99613330, 26, -7650.000, 1250.300, 126.517, 3.4260, 5000, 0, 0, 100),
(99613330, 27, -7643.500, 1252.200, 127.007, NULL, 0, 0, 0, 100),
(99613330, 28, -7638.400, 1258.000, 127.439, NULL, 0, 0, 0, 100);

-- Father Elroth's outfit, picked by the user from the wardrobe against AscenSS 071226-223752: Supreme Crown 23049,
-- Twill Shoulderpads 13064, Truefaith Vestments 19716, Keller's Girdle 6986, Molten Footguards 155827, Spellforce Rod 1664.
UPDATE `creature_display_preset` SET `item_head` = 23049, `item_shoulders` = 13064, `item_chest` = 19716, `item_waist` = 6986, `item_feet` = 155827 WHERE `entry` = 164013 AND `display_id` = 49;
DELETE FROM `creature_equip_template` WHERE `CreatureID` = 164013;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(164013, 1, 1664, 0, 0, 0);
UPDATE `creature` SET `equipment_id` = 1 WHERE `guid` = 9960193 AND `id` = 164013;

-- Innkeeper Auvrel wore shoulder display 87660 (lshoulder_leather_draenordungeon_c_01), whose model the client lacks, so it
-- drew as placeholder cubes; live footage (YzysjpunNbs 17:40) shows him without shoulders.
UPDATE `creature_display_preset` SET `item_shoulders` = 0 WHERE `entry` = 164131 AND `display_id` = 49;

-- Torric Graven's look from AscenSS 071126-233604 and 233703 (user's wardrobe picks; customization matched by rendering
-- every option): skin 8, short spiky hair 2 in dark grey 8, full beard 4, Gray Woolen Shirt 7947, Bloodsail Pants 30123,
-- Moldy Leather Boots 30472.
UPDATE `creature_display_preset` SET `skin` = 8, `face` = 0, `hair` = 2, `haircolor` = 8, `facialhair` = 4, `item_body` = 7947, `item_legs` = 30123, `item_feet` = 30472 WHERE `entry` = 164127 AND `display_id` = 49;

-- Innkeeper Auvrel's look (user's wardrobe picks against YzysjpunNbs 17:40): Torric Graven's skin 8, short spiky hair 2 and
-- full beard 4 in his own dark hair colour, Chestguard of Ensnared Nobility 147169, Bloodsail Pants 30123, Shadowweave Boots 1979.
UPDATE `creature_display_preset` SET `skin` = 8, `face` = 0, `hair` = 2, `facialhair` = 4, `item_body` = 0, `item_chest` = 147169, `item_legs` = 30123, `item_feet` = 1979 WHERE `entry` = 164131 AND `display_id` = 49;

-- Aisling's outfit (user's wardrobe picks against AscenSS 071126-233534): Umbral Undershirt of Lunar Communion 126805,
-- Black Mageweave Vest 19008, Ritual Vials of the Bloodseeker 136777, Umbral Skirt of Lunar Communion 126796; feet unchanged.
UPDATE `creature_display_preset` SET `item_body` = 126805, `item_chest` = 19008, `item_waist` = 136777, `item_legs` = 126796 WHERE `entry` = 164593 AND `display_id` = 50;

-- The Singing Witch (175044): Aisling's turn-in text, transcribed from live footage found by the user (2026-10-16).
DELETE FROM `quest_offer_reward` WHERE `ID` = 175044;
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`) VALUES
(175044, 0, 0, 0, 0, 0, 0, 0, 0, 'So Alanna believes only the Three Sisters can save her.$B$B<Aisling''s expression grows grave as she weighs the implications.>$B$BThose three have fickle appetites. They may help you, or punish your insolence for coming to them at all.$B$BEither way, whatever they do with you is not my problem. If you''re willing to risk standing before them, I''ll help you.', 0);

-- Possessed Crow 9961171 moved with CoAWorldEdit (playtest 2026-10-16); it sits through the template addon.
UPDATE `creature` SET `position_x` = -7624.051, `position_y` = 1186.906, `position_z` = 164.735, `orientation` = 4.8011, `wander_distance` = 0, `MovementType` = 0 WHERE `guid` = 9961171 AND `id` = 164944;

-- The Flowers That Sing (175331): Aisling's turn-in text from live footage (DuWTvw19xtg 34:17).
DELETE FROM `quest_offer_reward` WHERE `ID` = 175331;
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`) VALUES
(175331, 0, 0, 0, 0, 0, 0, 0, 0, 'Snowsong. A special plant, as you have surely noticed.$B$BI was beginning to think Hilda and Zelda had forgotten me.$B$BHere, for your trouble.', 0);

-- Cresthairn Guard (164134) dresses like the Dunshire Guard (user, 2026-10-16): the Graysky set without the helmet, male and
-- female bodies like 164124.
DELETE FROM `creature_template_model` WHERE `CreatureID` = 164134;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(164134, 0, 49, 1, 1, 0),
(164134, 1, 50, 1, 1, 0);
DELETE FROM `creature_display_preset` WHERE `entry` = 164134;
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164134, 49, 1, 0, 1, 9, 9, 9, 0, 9, 0, 0, 41081, 0, 144757, 51757, 153475, 144756, 144761, 144758, 21569, 170301),
(164134, 50, 1, 1, 1, 2, 3, 5, 1, 6, 0, 0, 41081, 0, 144757, 51757, 153475, 144756, 144761, 144758, 21569, 170301);

-- #15: Dunshire, Cresthairn and Graysky Guards carry a sword and a round shield (wJ2j4NOgjRI 41:36, DuWTvw19xtg 33:56):
-- Iron-Grip Shortsword 36517 and Sentry Buckler 3743, user's wardrobe picks (2026-10-16).
DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (164124, 164134, 164173, 164323, 164488, 164552, 164563, 9920072, 9920073);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(164124, 1, 36517, 3743, 0, 0),
(164134, 1, 36517, 3743, 0, 0),
(164173, 1, 36517, 3743, 0, 0),
(164323, 1, 36517, 3743, 0, 0),
(164488, 1, 36517, 3743, 0, 0),
(164552, 1, 36517, 3743, 0, 0),
(164563, 1, 36517, 3743, 0, 0),
(9920072, 1, 36517, 3743, 0, 0),
(9920073, 1, 36517, 3743, 0, 0);
UPDATE `creature` SET `equipment_id` = 1 WHERE `id` IN (164124, 164134, 164173, 164323, 164488, 164552, 164563, 9920072, 9920073);

-- Extra Dunshire Guards removed with CoAWorldEdit (playtest 2026-10-16).
DELETE FROM `creature` WHERE `guid` IN (9960886, 9920418, 9920419, 9960892, 9960885) AND `id` = 164124;
DELETE FROM `creature_addon` WHERE `guid` IN (9960886, 9920418, 9920419, 9960892, 9960885);

-- Torric Graven wears the vest Ulira Greyvale wears (Gilnean Footpad's Tunic 54934) over his Gray Woolen Shirt (user, 2026-10-16).
UPDATE `creature_display_preset` SET `item_chest` = 54934 WHERE `entry` = 164127 AND `display_id` = 49;

-- Graysky Royal Guards (164222) carry two Iron-Grip Shortswords 36517, the Graysky Guard sword (user, 2026-10-16).
DELETE FROM `creature_equip_template` WHERE `CreatureID` = 164222;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(164222, 1, 36517, 36517, 0, 0);
UPDATE `creature` SET `equipment_id` = 1 WHERE `id` = 164222;

-- The two Coldmere Keep balcony Royal Guards walk their own balcony end to end and back, 5 s at each end; routes laid
-- down the balcony centres from the keep geometry, and the two balconies never meet (user request 2026-10-16).
UPDATE `creature` SET `position_x` = -7204.7, `position_y` = 1288.5, `position_z` = 321.387, `wander_distance` = 0, `MovementType` = 2 WHERE `guid` = 9960264 AND `id` = 164222;
UPDATE `creature` SET `position_x` = -7280.5, `position_y` = 1272.0, `position_z` = 321.874, `wander_distance` = 0, `MovementType` = 2 WHERE `guid` = 9960836 AND `id` = 164222;
DELETE FROM `creature_addon` WHERE `guid` IN (9960264, 9960836);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9960264, 99602640, 0, 0, 1, 0, 0, ''),
(9960836, 99608360, 0, 0, 1, 0, 0, '');
DELETE FROM `waypoint_data` WHERE `id` IN (99602640, 99608360);
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `delay`, `move_type`, `action`, `action_chance`) VALUES
(99602640, 1, -7204.7, 1288.5, 321.387, 5.0736, 5000, 0, 0, 100),
(99602640, 2, -7203.0, 1284.0, 321.387, NULL, 0, 0, 0, 100),
(99602640, 3, -7201.83, 1276.0, 321.387, NULL, 0, 0, 0, 100),
(99602640, 4, -7196.22, 1266.0, 321.387, NULL, 0, 0, 0, 100),
(99602640, 5, -7193.5, 1258.5, 321.387, NULL, 0, 0, 0, 100),
(99602640, 6, -7192.11, 1251.5, 321.387, NULL, 0, 0, 0, 100),
(99602640, 7, -7185.7, 1237.0, 321.387, 1.9870, 5000, 0, 0, 100),
(99602640, 8, -7192.11, 1251.5, 321.387, NULL, 0, 0, 0, 100),
(99602640, 9, -7193.5, 1258.5, 321.387, NULL, 0, 0, 0, 100),
(99602640, 10, -7196.22, 1266.0, 321.387, NULL, 0, 0, 0, 100),
(99602640, 11, -7201.83, 1276.0, 321.387, NULL, 0, 0, 0, 100),
(99602640, 12, -7203.0, 1284.0, 321.387, NULL, 0, 0, 0, 100),
(99608360, 1, -7280.5, 1272.0, 321.874, 4.8580, 5000, 0, 0, 100),
(99608360, 2, -7280.06, 1269.0, 321.874, NULL, 0, 0, 0, 100),
(99608360, 3, -7275.56, 1257.0, 321.387, NULL, 0, 0, 0, 100),
(99608360, 4, -7270.67, 1250.0, 321.387, NULL, 0, 0, 0, 100),
(99608360, 5, -7268.5, 1239.0, 321.387, NULL, 0, 0, 0, 100),
(99608360, 6, -7265.72, 1231.5, 321.387, NULL, 0, 0, 0, 100),
(99608360, 7, -7262.83, 1227.0, 321.387, NULL, 0, 0, 0, 100),
(99608360, 8, -7261.44, 1223.5, 321.387, NULL, 0, 0, 0, 100),
(99608360, 9, -7254.4, 1201.0, 321.856, 1.8740, 5000, 0, 0, 100),
(99608360, 10, -7261.44, 1223.5, 321.387, NULL, 0, 0, 0, 100),
(99608360, 11, -7262.83, 1227.0, 321.387, NULL, 0, 0, 0, 100),
(99608360, 12, -7265.72, 1231.5, 321.387, NULL, 0, 0, 0, 100),
(99608360, 13, -7268.5, 1239.0, 321.387, NULL, 0, 0, 0, 100),
(99608360, 14, -7270.67, 1250.0, 321.387, NULL, 0, 0, 0, 100),
(99608360, 15, -7275.56, 1257.0, 321.387, NULL, 0, 0, 0, 100),
(99608360, 16, -7280.06, 1269.0, 321.874, NULL, 0, 0, 0, 100);
