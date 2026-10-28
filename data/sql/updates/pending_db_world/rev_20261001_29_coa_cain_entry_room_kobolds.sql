-- Cain Family Crypt: the two Kobold Desecrators of the lowest hall (z 124; 9010130 and 9010131 from
-- rev_20260926_10) move up to the first room inside the entrance (z 141.4): one at the foot of the entry stairs and
-- one at its east end, at positions and facings taken in game with .gps (playtest). The lowest hall keeps the
-- relatives' remains.
UPDATE `creature` SET `position_x` = 1799.7672, `position_y` = 1967.7028, `position_z` = 141.4438,
    `orientation` = 2.9006 WHERE `guid` = 9010130 AND `id` = 161751;
UPDATE `creature` SET `position_x` = 1782.4592, `position_y` = 1972.5784, `position_z` = 141.4452,
    `orientation` = 4.491 WHERE `guid` = 9010131 AND `id` = 161751;
