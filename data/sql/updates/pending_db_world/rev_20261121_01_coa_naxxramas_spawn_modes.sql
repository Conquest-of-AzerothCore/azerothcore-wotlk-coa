START TRANSACTION;

-- Mirror each existing layout into its paired higher mode.
UPDATE `creature`
SET `spawnMask` = `spawnMask` | ((`spawnMask` & 3) << 2)
WHERE `map` = 533;

UPDATE `gameobject`
SET `spawnMask` = `spawnMask` | ((`spawnMask` & 3) << 2)
WHERE `map` = 533;

-- The Obedience Crystals let every roster control Razuvious's Understudies.
UPDATE `creature`
SET `spawnMask` = `spawnMask` | 15
WHERE `map` = 533 AND `id` = 29912;

COMMIT;
