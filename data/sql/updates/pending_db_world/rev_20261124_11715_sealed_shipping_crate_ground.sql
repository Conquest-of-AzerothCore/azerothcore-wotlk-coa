-- Worldforged Sealed Shipping Crate (pickup 6941530, Un'Goro Crater, #11715) floated 0.65 yd over flat terrain: the
-- realm-map pass moved its x/y 6.6 yd and kept the first-pass height. New z: the server's ground height at the spawn.
UPDATE `gameobject` SET `position_z` = -268.509
WHERE `guid` = 6941530 AND `id` = 95939 AND `map` = 1
  AND `position_x` BETWEEN -7670.91 AND -7670.89
  AND `position_y` BETWEEN -1494.11 AND -1494.09
  AND `position_z` BETWEEN -267.87 AND -267.85;
