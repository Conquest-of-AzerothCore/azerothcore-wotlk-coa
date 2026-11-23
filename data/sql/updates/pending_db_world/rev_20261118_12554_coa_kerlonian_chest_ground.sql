-- Patch-WB1 raised the ground at Kerlonian's camp in Ashenvale by about 0.47 yards; Kerlonian's Chest sat under it.
UPDATE `gameobject` SET `position_z` = 51.178 WHERE `guid` = 48510 AND `id` = 176634 AND `position_z` < 51.178;
