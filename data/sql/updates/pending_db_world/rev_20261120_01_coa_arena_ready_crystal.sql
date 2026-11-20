INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `ScriptName`) VALUES
(9900053, 10, 8070, 'Arena Ready Crystal', 1, 'go_coa_arena_ready_crystal') ON DUPLICATE KEY UPDATE `size` = 1;
UPDATE `gameobject_template` SET `type` = 10, `displayId` = 8070, `name` = 'Arena Ready Crystal', `size` = 1,
    `ScriptName` = 'go_coa_arena_ready_crystal' WHERE `entry` = 9900053;
