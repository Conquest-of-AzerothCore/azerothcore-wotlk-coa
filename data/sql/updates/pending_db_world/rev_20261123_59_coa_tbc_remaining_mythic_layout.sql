-- Proposed Mythic layout inherits the original Heroic spawns.
UPDATE `creature`
SET `spawnMask` = `spawnMask` | 4
WHERE `map` IN (269, 552, 553, 554, 555, 556, 557, 558, 560, 585) AND (`spawnMask` & 2) <> 0;

UPDATE `gameobject`
SET `spawnMask` = `spawnMask` | 4
WHERE `map` IN (269, 552, 553, 554, 555, 556, 557, 558, 560, 585) AND (`spawnMask` & 2) <> 0;
