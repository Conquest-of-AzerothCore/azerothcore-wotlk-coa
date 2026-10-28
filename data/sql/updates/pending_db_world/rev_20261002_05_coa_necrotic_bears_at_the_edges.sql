-- Necrotic Bears 161743 on the Cain estate move toward the estate's edges, so its field, paths and lake shore
-- stay clear (playtest). Each wandering bear's whole 5 yd wander circle, plus 1.5 yd, is walkable terrain (slope
-- <= 35 degrees, no building, water or 4 yd height step) and at least 6 yd from the stone and pebble paths; bears
-- stay 20+ yd apart and in the same area, and the moved ones 14+ yd from other creatures and 30+ yd from quest
-- givers and the Spirit Healer. 9010083 stands still behind the tomb, among its kobolds: even 2 yd of wander there
-- reaches the slope. Three bunched at the manor's back corner (playtest): 9010087 goes and 9010082 moves to the
-- author's spot south-east of the estate, wandering 4 yd to keep 2 yd from a fallen log 6 yd away.
UPDATE `creature` SET `position_x` = 1801.9, `position_y` = 1908.4, `position_z` = 157.369, `wander_distance` = 5
    WHERE `guid` = 9010080 AND `id` = 161743;
UPDATE `creature` SET `position_x` = 1951.3, `position_y` = 1923.9, `position_z` = 156.353, `wander_distance` = 5
    WHERE `guid` = 9010081 AND `id` = 161743;
UPDATE `creature` SET `position_x` = 1789.99, `position_y` = 1849.09, `position_z` = 158.258, `orientation` = 1.5156,
    `wander_distance` = 4 WHERE `guid` = 9010082 AND `id` = 161743;
UPDATE `creature` SET `position_x` = 1774.76, `position_y` = 1946.88, `position_z` = 154.217, `orientation` = 0.38,
    `wander_distance` = 0, `MovementType` = 0 WHERE `guid` = 9010083 AND `id` = 161743;
UPDATE `creature` SET `position_x` = 1892, `position_y` = 1896, `position_z` = 159.235, `wander_distance` = 5
    WHERE `guid` = 9010084 AND `id` = 161743;
UPDATE `creature` SET `position_x` = 1909.8, `position_y` = 1984, `position_z` = 158.127, `wander_distance` = 5
    WHERE `guid` = 9010085 AND `id` = 161743;
UPDATE `creature` SET `position_x` = 1826, `position_y` = 1889, `position_z` = 157.475, `wander_distance` = 5
    WHERE `guid` = 9010086 AND `id` = 161743;
DELETE FROM `creature` WHERE `guid` = 9010087 AND `id` = 161743;
