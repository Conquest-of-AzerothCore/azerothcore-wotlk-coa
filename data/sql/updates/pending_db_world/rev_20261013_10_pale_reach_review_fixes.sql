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
