UPDATE `gameobject` SET `position_z` = 63.3 WHERE `guid` = 20800 AND `id` = 1728;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 1728 AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(1728,1,0,0,20,0,100,0,524,0,0,0,0,0,50,1729,40,0,0,0,0,8,0,0,0,0,0.437117,-942.794,63.3,-2.54818,'Dusty Rug - On Quest \'Elixir of Agony\' Finished - Summon Gameobject \'Tainted Keg\'');
UPDATE `creature` SET `position_x` = -0.6, `position_y` = -946.5, `position_z` = 63.3 WHERE `guid` = 15891 AND `id` = 2284;
UPDATE `creature` SET `position_x` = -8.1, `position_y` = -944.3, `position_z` = 63.3 WHERE `guid` = 15892 AND `id` = 2284;
UPDATE `creature` SET `position_x` = -0.7, `position_y` = -938.0, `position_z` = 63.3 WHERE `guid` = 15893 AND `id` = 2284;
