-- Elwynn Forest Defias Cutpurses (94) and Mangy Wolves (525) placed by the user in game: five cutpurses spread out
-- from their cluster, one wolf moved up the hill and one removed. Overrides rev_20260923_02 for 79876 and 80382.
UPDATE `creature` SET `position_x` = -9238.378, `position_y` = 233.049, `position_z` = 71.955, `orientation` = 6.2403
WHERE `guid` = 79877 AND `id` = 94;
UPDATE `creature` SET `position_x` = -9234.445, `position_y` = 247.257, `position_z` = 71.971, `orientation` = 6.2403
WHERE `guid` = 80282 AND `id` = 94;
UPDATE `creature` SET `position_x` = -9193.150, `position_y` = 157.008, `position_z` = 72.297, `orientation` = 5.4235
WHERE `guid` = 80279 AND `id` = 94;
UPDATE `creature` SET `position_x` = -9171.947, `position_y` = 203.774, `position_z` = 73.451, `orientation` = 5.7541
WHERE `guid` = 79885 AND `id` = 94;
UPDATE `creature` SET `position_x` = -9148.769, `position_y` = 222.133, `position_z` = 75.357, `orientation` = 5.7541
WHERE `guid` = 79653 AND `id` = 94;
UPDATE `creature` SET `position_x` = -9203.066, `position_y` = 474.050, `position_z` = 100.095, `orientation` = 5.0119
WHERE `guid` = 80382 AND `id` = 525;

DELETE FROM `creature_addon` WHERE `guid` = 79876;
DELETE FROM `game_event_creature` WHERE `guid` = 79876;
DELETE FROM `creature` WHERE `guid` = 79876 AND `id` = 525;
