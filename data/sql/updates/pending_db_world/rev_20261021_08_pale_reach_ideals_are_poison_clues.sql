-- Ideals Are Poison (175035): each clue counts once per character and then stays in place without its sparkle until the
-- quest is abandoned (go_coa_ideals_are_poison_clue) instead of despawning for 15 s and counting again. The Blood
-- Splatter moves 0.7 yd onto even ground and it and the Dried Footprints decals tilt to the slope, so no edge sinks.
UPDATE `gameobject_template` SET `ScriptName` = 'go_coa_ideals_are_poison_clue' WHERE `entry` BETWEEN 2300646 AND 2300650;

DELETE FROM `smart_scripts` WHERE `entryorguid` BETWEEN 2300646 AND 2300650 AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(2300646, 1, 0, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 33, 164511, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Tangled Furs - On Use - Quest Credit Clues found'),
(2300647, 1, 0, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 33, 164511, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Trail in the Grass - On Use - Quest Credit Clues found'),
(2300648, 1, 0, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 33, 164511, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Notched Buckler - On Use - Quest Credit Clues found'),
(2300649, 1, 0, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 33, 164511, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Dried Footprints - On Use - Quest Credit Clues found'),
(2300650, 1, 0, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 33, 164511, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Blood Splatter - On Use - Quest Credit Clues found');

UPDATE `gameobject` SET `position_x` = -7606.2, `position_y` = 738.69, `position_z` = 138.026, `rotation0` = 0.007503, `rotation1` = -0.039405, `rotation2` = 0.629064, `rotation3` = 0.776318 WHERE `guid` = 9992004 AND `id` = 2300650;
UPDATE `gameobject` SET `position_z` = 139.004, `rotation0` = 0.006077, `rotation1` = -0.039328, `rotation2` = 0.509867, `rotation3` = 0.859332 WHERE `guid` = 9992003 AND `id` = 2300649;
