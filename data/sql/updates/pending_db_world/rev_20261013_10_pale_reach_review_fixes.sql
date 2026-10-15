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
