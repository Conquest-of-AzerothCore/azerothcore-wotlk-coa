-- Worldforged Fisher's Misfortune (pickup 6941737, Steamwheedle Port) lay 2.47 yd under the harbour seabed (#11370).
-- Move it to the reporter's x/y, where the server measures the ground at z 0.71.
UPDATE `gameobject` SET `position_x` = -6930.29, `position_y` = -4925.2, `position_z` = 0.71
WHERE `guid` = 6941737 AND `id` = 515834 AND `map` = 1
  AND `position_x` BETWEEN -6933.91 AND -6933.89
  AND `position_y` BETWEEN -4920.41 AND -4920.39
  AND `position_z` BETWEEN -13.14 AND -13.13;
