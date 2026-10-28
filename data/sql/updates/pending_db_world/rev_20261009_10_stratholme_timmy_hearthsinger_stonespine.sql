-- Stratholme: Timmy the Cruel, Hearthsinger Forresten and Stonespine.

-- Timmy the Cruel stands in King's Square from the start, on every difficulty, at the hand-placed
-- spot. He no longer hides (invisible and friendly) until the Crimson guards around him are dead.
DELETE FROM `creature` WHERE `id` IN (10808, 110808, 210808) AND `guid` <> 9950289;
DELETE FROM `creature` WHERE `guid` = 9950289;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`) VALUES
(9950289, 10808, 329, 0, 0, 7, 1, 0, 3612.48, -3189.62, 131.654, 0.272784, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', NULL);
DELETE FROM `smart_scripts` WHERE `entryorguid` = 10808 AND `source_type` = 0 AND `id` IN (3, 4, 5, 6);
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceEntry` = 10808 AND `SourceGroup` = 6;

-- Hearthsinger Forresten is the boss past the rat trap. That spawn was Mythic only; it now stands
-- on every difficulty, and the stock one in Festival Lane goes so there is only one of him.
DELETE FROM `creature` WHERE `id` IN (10558, 110558, 210558) AND `guid` <> 9950081;
UPDATE `creature` SET `spawnMask` = 7, `curhealth` = 0 WHERE `guid` = 9950081;

-- Stonespine patrols the undead side with a Rockwing Screecher and two Rockwing Gargoyles in
-- formation. The 14 points were walked in game (as waypoint paths 1-14, one point each) and become
-- one cyclic path; Stonespine's spawn is point 11.
DELETE FROM `waypoint_data` WHERE `id` BETWEEN 1 AND 14 AND `point` = 1
    AND `position_x` BETWEEN 3800 AND 4050 AND `position_y` BETWEEN -3700 AND -3540;
DELETE FROM `waypoint_data` WHERE `id` = 521470;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `delay`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES
(521470,  1, 3872.88, -3563.18, 138.07, NULL, 0, 0, 0, 100, 0),
(521470,  2, 3852.86, -3588.08, 142.54, NULL, 0, 0, 0, 100, 0),
(521470,  3, 3830.07, -3624.04, 145.47, NULL, 0, 0, 0, 100, 0),
(521470,  4, 3831.25, -3653.51, 145.49, NULL, 0, 0, 0, 100, 0),
(521470,  5, 3853.00, -3678.81, 143.59, NULL, 0, 0, 0, 100, 0),
(521470,  6, 3890.26, -3677.50, 141.39, NULL, 0, 0, 0, 100, 0),
(521470,  7, 3921.06, -3665.24, 138.18, NULL, 0, 0, 0, 100, 0),
(521470,  8, 3942.81, -3648.15, 138.60, NULL, 0, 0, 0, 100, 0),
(521470,  9, 3957.99, -3642.60, 133.48, NULL, 0, 0, 0, 100, 0),
(521470, 10, 3995.22, -3623.87, 130.04, NULL, 0, 0, 0, 100, 0),
(521470, 11, 4001.21, -3586.74, 128.90, NULL, 0, 0, 0, 100, 0),
(521470, 12, 4007.83, -3555.16, 124.76, NULL, 0, 0, 0, 100, 0),
(521470, 13, 3975.93, -3555.69, 125.49, NULL, 0, 0, 0, 100, 0),
(521470, 14, 3971.38, -3575.77, 127.09, NULL, 0, 0, 0, 100, 0);

UPDATE `creature` SET `MovementType` = 2, `wander_distance` = 0 WHERE `guid` = 52147;
UPDATE `creature_addon` SET `path_id` = 521470 WHERE `guid` = 52147;
UPDATE `creature` SET `MovementType` = 0, `wander_distance` = 0 WHERE `guid` IN (53854, 53786, 53852);

-- groupAI 3: the group fights together; 515 adds 0x200, the members follow the leader.
-- Angles in degrees around the leader's facing.
DELETE FROM `creature_formations` WHERE `leaderGUID` = 52147 OR `memberGUID` IN (52147, 53854, 53786, 53852);
INSERT INTO `creature_formations` (`leaderGUID`, `memberGUID`, `dist`, `angle`, `groupAI`, `point_1`, `point_2`) VALUES
(52147, 52147, 0, 0,   3, 0, 0),
(52147, 53854, 3, 180, 515, 0, 0),
(52147, 53786, 4, 120, 515, 0, 0),
(52147, 53852, 4, 240, 515, 0, 0);
