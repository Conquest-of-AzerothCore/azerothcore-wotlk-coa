UPDATE `creature`
SET `spawnMask` = `spawnMask` | 15
WHERE `map` = 532 AND `spawnMask` & 1;

UPDATE `gameobject`
SET `spawnMask` = `spawnMask` | 15
WHERE `map` = 532 AND `spawnMask` & 1;
