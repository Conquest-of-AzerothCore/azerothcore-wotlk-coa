INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `ScriptName`) VALUES
(9900053, 10, 6905, 'Arena Ready Crystal', 2, 'go_coa_arena_ready_crystal') ON DUPLICATE KEY UPDATE `size` = 2;
UPDATE `gameobject_template` SET `type` = 10, `displayId` = 6905, `name` = 'Arena Ready Crystal', `size` = 2,
    `ScriptName` = 'go_coa_arena_ready_crystal' WHERE `entry` = 9900053;
