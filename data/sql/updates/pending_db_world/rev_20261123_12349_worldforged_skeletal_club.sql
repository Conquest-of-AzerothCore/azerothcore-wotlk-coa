-- #12349: Worldforged Skeletal Club (6941090) sat 1.63 yd under the floor the reporter stood on (z 60.955); the
-- first-pass z 62.013 floats 1.05 yd, so it rests on the measured floor at its position.
UPDATE `gameobject` SET `position_z` = 60.95 WHERE `guid` = 6941090 AND `id` = 340098;
