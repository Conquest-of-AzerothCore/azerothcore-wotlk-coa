-- Worldforged Steel Helmet (#10627, guid 6942240) was lifted 9.15 yd above the Un'Goro ground by the
-- recorded-height pass; the ground under it is -216.653.
UPDATE `gameobject` SET `position_z` = -216.653
WHERE `guid` = 6942240 AND `id` = 96218 AND `map` = 1
  AND `position_x` BETWEEN -8233.7 AND -8232.7 AND `position_y` BETWEEN -1317.0 AND -1316.0
  AND `position_z` BETWEEN -207.6 AND -207.4;
