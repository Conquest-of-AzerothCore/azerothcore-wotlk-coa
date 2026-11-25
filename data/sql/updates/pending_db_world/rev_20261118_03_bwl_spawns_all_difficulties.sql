--
-- Difficulty templates do not enable spawns: BWL creatures and encounter objects need all four mode bits.
UPDATE `creature` SET `spawnMask` = `spawnMask` | 15 WHERE `map` = 469;
UPDATE `gameobject` SET `spawnMask` = `spawnMask` | 15 WHERE `map` = 469;
