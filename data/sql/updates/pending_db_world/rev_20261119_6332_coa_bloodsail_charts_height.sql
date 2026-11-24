-- Patch-WB1 replaced the two crates under these Bloodsail Charts and Orders with a Westfall table whose top is 2.955.
UPDATE `gameobject` SET `position_z` = 2.9555 WHERE `guid` = 12165 AND `id` = 2086 AND `map` = 0 AND `position_z` > 4;
UPDATE `gameobject` SET `position_z` = 2.9555 WHERE `guid` = 12156 AND `id` = 2087 AND `map` = 0 AND `position_z` > 4;
