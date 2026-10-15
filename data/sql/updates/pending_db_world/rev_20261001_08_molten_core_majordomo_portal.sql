-- Portal to Ragnaros' lair after Majordomo Executus turns friendly (go_ragnaros_portal_coa,
-- boss_majordomo_executus.cpp / instance_molten_core.cpp). Reuses the existing "Molten Core
-- Instance Portal" template (181623, display 6450) rather than inventing a new one. The spawn is
-- static (persists across restarts and instance resets) and not selectable until Majordomo's
-- encounter state reaches DONE, toggled by the instance script both live and on reload.
UPDATE `gameobject_template` SET `ScriptName` = 'go_ragnaros_portal_coa' WHERE `entry` = 181623;

DELETE FROM `gameobject` WHERE `guid` = 9000601;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`) VALUES
(9000601, 181623, 409, 0, 0, 1, 1, 851.933, -812.875, -229.601, 4.046, 0, 0, 0.8994864, -0.4369488, 0, 100, 1, '');
