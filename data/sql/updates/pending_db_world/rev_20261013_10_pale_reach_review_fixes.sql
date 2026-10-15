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

-- #6: every Raven becomes a Possessed Crow (user decision): perched with the blue raven-aura eyes from the template addon;
-- the export's live-capture spawns keep their kneel and cannibalize poses with the aura added. Levels 18-21 as targeted in
-- 2r0PE1dBarE, DuWTvw19xtg and F5g2uzWFLqA.
DELETE FROM `creature` WHERE `guid` = 9960829 AND `id` = 164371;
UPDATE `creature` SET `id` = 164944, `MovementType` = 0, `wander_distance` = 0 WHERE `id` = 164371;
UPDATE `creature_template` SET `minlevel` = 18, `maxlevel` = 21 WHERE `entry` = 164944;

DELETE FROM `creature_addon` WHERE `guid` IN (9960029, 9960647, 9961725, 9961860, 9961932);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9960029, 0, 0, 8, 1, 0, 0, '365403'),
(9960647, 0, 0, 0, 1, 398, 0, '365403'),
(9961725, 0, 0, 0, 1, 398, 0, '365403'),
(9961860, 0, 0, 0, 1, 398, 0, '365403'),
(9961932, 0, 0, 8, 1, 0, 0, '365403');
