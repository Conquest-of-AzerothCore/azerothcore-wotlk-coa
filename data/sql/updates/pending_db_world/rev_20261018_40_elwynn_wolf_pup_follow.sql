-- Elwynn wolf pairs, follow-up (#8116): the formation follow closed gaps
-- at up to 1.5x leader speed with no arrival brake, so pups visibly
-- burst through their mothers and end up in front. SAI follow instead
-- inherits the leader's walk state and stops on arrival, trailing calmly.
-- Assist stays on the formation rows (distance-independent, verified in
-- CreatureGroup::MemberEngagingTarget), so those only lose the FOLLOW
-- flag here. Pups also start up to 22 yd out, which neither follower
-- closes gracefully, so each pup spawns 4 yd behind its mother's facing.
-- Young Wolf 299 additionally needs AIName SmartAI (was NullAI) for the
-- follow row to run; movement and combat are otherwise untouched. The
-- follow re-issues out of combat every 10 s, so it never yanks a pup off
-- a target and re-acquires after deaths. Seventh pup 79920 stays
-- unformationed and simply trails the nearest mother.
UPDATE `creature` SET `position_x` = -9277.9595, `position_y` = 92.0945, `position_z` = 70.4579 WHERE `guid` = 79651;
UPDATE `creature` SET `position_x` = -9211.2899, `position_y` = 45.6892, `position_z` = 75.6888 WHERE `guid` = 79894;
UPDATE `creature` SET `position_x` = -9281.8807, `position_y` = -11.7036, `position_z` = 70.6536 WHERE `guid` = 80270;
UPDATE `creature` SET `position_x` = -9319.9182, `position_y` = 77.4365, `position_z` = 61.58 WHERE `guid` = 80341;
UPDATE `creature` SET `position_x` = -9226.5928, `position_y` = -52.7761, `position_z` = 73.6102 WHERE `guid` = 79900;
UPDATE `creature` SET `position_x` = -9333.0074, `position_y` = 51.7111, `position_z` = 59.86 WHERE `guid` = 80343;
UPDATE `creature_formations` SET `groupAI` = 2 WHERE `memberGUID` IN (79651, 79894, 80270, 80341, 79900, 80343);
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 299;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 299 AND `source_type` = 0 AND `id` = 0 AND `link` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(299, 0, 0, 0, 1, 0, 100, 0, 1000, 1000, 10000, 10000, 0, 0, 29, 2, 3, 0, 0, 0, 0, 19, 525, 25, 0, 0, 0, 0, 0, 0, 'Young Wolf trails the nearest Mangy Wolf out of combat');
