-- Sprite Jumpsprocket and Lilliam Sparkspindle work under a white canvas pavilion with an anvil behind them in the
-- Dwarven District, matching realm footage; Billibub Cogspinner and Tinker James Randal moved nearby. Positions placed
-- in game with CoA World Edit; the guards' Tinker directions follow James Randal.
UPDATE `creature` SET `position_x` = -8338.043, `position_y` = 611.255, `position_z` = 95.659, `orientation` = 2.415 WHERE `guid` = 48358 AND `id` = 11026;
UPDATE `creature` SET `position_x` = -8335.265, `position_y` = 613.908, `position_z` = 95.763, `orientation` = 2.415 WHERE `guid` = 37611 AND `id` = 5518;
UPDATE `creature` SET `position_x` = -8365.131, `position_y` = 627.611, `position_z` = 95.198, `orientation` = 3.6347 WHERE `guid` = 37612 AND `id` = 5519;
UPDATE `creature` SET `position_x` = -8367.536, `position_y` = 665.944, `position_z` = 94.936, `orientation` = 4.7036 WHERE `guid` = 9004513 AND `id` = 650287;
UPDATE `points_of_interest` SET `PositionX` = -8367.536, `PositionY` = 665.944 WHERE `ID` = 9321013;

DELETE FROM `gameobject` WHERE `guid` IN (9999290, 9999291);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`,
    `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`,
    `VerifiedBuild`, `Comment`) VALUES
(9999290, 181301, 0, 1519, 10226, 1, 1, -8335.9, 610.6, 95.708, 2.217, 0, 0, 0.894934, 0.446198, 300, 100, 1, '', 0, 'Dwarven District gnome stall pavilion'),
(9999291, 174, 0, 1519, 10226, 1, 1, -8337.099, 608.751, 95.112, 0.6462, 0, 0, 0.317508, 0.948256, 300, 100, 1, '', 0, 'Dwarven District gnome stall anvil');
