-- Voodoo Bonemaker pickup (guid 6941309) floated 1.4 yd above the ground (#10926).
UPDATE `gameobject` SET `position_z` = 17.285
WHERE `guid` = 6941309 AND `id` = 95726 AND `map` = 0
  AND `position_x` BETWEEN -12991.71 AND -12991.69 AND `position_y` BETWEEN 197.49 AND 197.51
  AND ABS(`position_z` - 18.733) < 0.01;
