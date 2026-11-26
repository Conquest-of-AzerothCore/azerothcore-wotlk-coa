-- #13703: Restore Draconic Wand (guid 6941422, entry 254450, drops Azure Will 515619)
-- inside Nagapagoda01.wmo in Azshara to its first-pass realm-dump coordinates (row 6900205,
-- +0.791 yd above the pagoda floor at 133.154). rev_20261006_65 dropped it to bare terrain
-- (128.9285), burying it 4.23 yd beneath the pagoda floor.
UPDATE `gameobject`
SET `position_x` = 2502.735, `position_y` = -5426.102, `position_z` = 133.945
WHERE `guid` = 6941422 AND `id` = 254450;
