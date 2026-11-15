-- Worldforged Drape of the Lost (pickup 6941650, Azshara graveyard) floated 4.99 yd above the ground the server
-- measures at its x/y (#11358). Lower only z onto that ground.
UPDATE `gameobject` SET `position_z` = 104.27
WHERE `guid` = 6941650 AND `id` = 254410 AND `map` = 1
  AND `position_z` BETWEEN 109.25 AND 109.27;
