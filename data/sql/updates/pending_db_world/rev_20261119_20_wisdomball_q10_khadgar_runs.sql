UPDATE `creature_template` SET `speed_run` = 0.9 WHERE `entry` = 9417004;
UPDATE `smart_scripts` SET `action_param1` = 2, `comment` = 'Khadgar (Escort) - Linked - Start escort (run, defensive; target self: no player stored, so it never ends on distance - C++ wisdomball_escort_wait stops him when no player is within 25 yd)' WHERE `entryorguid` = 9417004 AND `source_type` = 0 AND `id` = 2;
