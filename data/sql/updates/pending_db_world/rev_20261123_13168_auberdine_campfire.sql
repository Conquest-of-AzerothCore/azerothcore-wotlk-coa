-- #13168: the Auberdine campfire (48633) sat 0.40 yd under the ground beside Hollee; raise it onto the measured
-- ground (z 6.639).
UPDATE `gameobject` SET `position_z` = 6.639 WHERE `guid` = 48633 AND `id` = 103687;
