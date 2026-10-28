-- Worldforged Abandoned Boots pickup (item 354159, GO 254259, guid 6941376, Tethris Aran/Desolace) kept the Z of
-- its pre-realm-map row (118.991) when the realm-map pass moved its XY to the realm marker 16 yd away; the ground
-- there is 119.725, so the pickup sat 0.73 yd underground.
UPDATE `gameobject` SET `position_z` = 119.73
 WHERE `guid` = 6941376 AND `id` = 254259 AND `map` = 1
   AND `position_x` BETWEEN 12.7 AND 13.7 AND `position_y` BETWEEN 1762.9 AND 1763.9
   AND ABS(`position_z` - 118.991) < 0.01;
