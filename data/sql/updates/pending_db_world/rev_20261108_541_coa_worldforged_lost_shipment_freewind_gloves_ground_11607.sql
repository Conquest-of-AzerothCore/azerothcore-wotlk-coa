-- Worldforged Lost Shipment (pickup 6941752, Thousand Needles) floated 1.24 yd above the ground at its x/y (#11607).
-- The ground where the reporter stood at (-5375.785, -2241.318) measures -54.425, so move the pickup there.
UPDATE `gameobject` SET `position_x` = -5375.7847, `position_y` = -2241.3181, `position_z` = -54.425
WHERE `guid` = 6941752 AND `id` = 97137 AND `map` = 1
  AND `position_x` BETWEEN -5376.8 AND -5376.6 AND `position_y` BETWEEN -2241.9 AND -2241.7
  AND `position_z` BETWEEN -53.4 AND -53.3;
