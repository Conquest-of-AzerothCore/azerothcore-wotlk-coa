-- Ideals Are Poison (175035): its five clues gave credit silently, while the clues of the Shadewell quests describe
-- what was found in a yellow emote. Each clue now has an invisible talker, the quest's own Clues found credit
-- (164511), which speaks the clue's line before the credit, as at Shadewell Spring.
DELETE FROM `creature` WHERE `guid` BETWEEN 9992005 AND 9992009;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9992005, 164511, 0, 0, 0, 1, 1, 0, -7594.1, 986.863, 133.986, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', 0, 0, 'Ideals Are Poison: Tangled Furs clue talker'),
(9992006, 164511, 0, 0, 0, 1, 1, 0, -7586.46, 888.928, 133.873, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', 0, 0, 'Ideals Are Poison: Trail in the Grass clue talker'),
(9992007, 164511, 0, 0, 0, 1, 1, 0, -7584.26, 815.291, 139.219, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', 0, 0, 'Ideals Are Poison: Notched Buckler clue talker'),
(9992008, 164511, 0, 0, 0, 1, 1, 0, -7594.22, 797.058, 139.004, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', 0, 0, 'Ideals Are Poison: Dried Footprints clue talker'),
(9992009, 164511, 0, 0, 0, 1, 1, 0, -7606.2, 738.69, 138.026, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', 0, 0, 'Ideals Are Poison: Blood Splatter clue talker');

DELETE FROM `creature_text` WHERE `CreatureID` = 164511;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(164511, 0, 0, 'Tufts of coarse red hair are caught in a tangle of furs. Abellon passed this way.', 41, 0, 100, 0, 0, 0, 0, 0, 'Ideals Are Poison - Tangled Furs'),
(164511, 1, 0, 'The grass is trampled by two sets of tracks, one hard on the heels of the other.', 41, 0, 100, 0, 0, 0, 0, 0, 'Ideals Are Poison - Trail in the Grass'),
(164511, 2, 0, 'A Cresthairn militia buckler, its rim notched by a heavy blow. It must be Cairn''s.', 41, 0, 100, 0, 0, 0, 0, 0, 'Ideals Are Poison - Notched Buckler'),
(164511, 3, 0, 'Footprints dried in the mud lead on toward the Ealdir lands. Neither brother turned back.', 41, 0, 100, 0, 0, 0, 0, 0, 'Ideals Are Poison - Dried Footprints'),
(164511, 4, 0, 'Blood is splattered across the stones. Someone was badly hurt here.', 41, 0, 100, 0, 0, 0, 0, 0, 'Ideals Are Poison - Blood Splatter');

DELETE FROM `smart_scripts` WHERE `entryorguid` BETWEEN 2300646 AND 2300650 AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(2300646, 1, 0, 1, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 19, 164511, 5, 0, 0, 0, 0, 0, 0, 'Tangled Furs - On Use - Talk clue line (closest clue talker)'),
(2300646, 1, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 164511, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Tangled Furs - Linked - Quest Credit Clues found'),
(2300647, 1, 0, 1, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 19, 164511, 5, 0, 0, 0, 0, 0, 0, 'Trail in the Grass - On Use - Talk clue line (closest clue talker)'),
(2300647, 1, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 164511, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Trail in the Grass - Linked - Quest Credit Clues found'),
(2300648, 1, 0, 1, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 19, 164511, 5, 0, 0, 0, 0, 0, 0, 'Notched Buckler - On Use - Talk clue line (closest clue talker)'),
(2300648, 1, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 164511, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Notched Buckler - Linked - Quest Credit Clues found'),
(2300649, 1, 0, 1, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 1, 3, 0, 0, 0, 0, 0, 19, 164511, 5, 0, 0, 0, 0, 0, 0, 'Dried Footprints - On Use - Talk clue line (closest clue talker)'),
(2300649, 1, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 164511, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Dried Footprints - Linked - Quest Credit Clues found'),
(2300650, 1, 0, 1, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 1, 4, 0, 0, 0, 0, 0, 19, 164511, 5, 0, 0, 0, 0, 0, 0, 'Blood Splatter - On Use - Talk clue line (closest clue talker)'),
(2300650, 1, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 164511, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Blood Splatter - Linked - Quest Credit Clues found');
