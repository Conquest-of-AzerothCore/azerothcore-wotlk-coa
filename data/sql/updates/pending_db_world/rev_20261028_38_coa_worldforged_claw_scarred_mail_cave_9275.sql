-- Worldforged Claw Scarred Mail (Dun Morogh, guid 6940256) stands on a hilltop at the realm-map
-- marker, 38.6 yd above the client's own sighting inside the cave below it ("on top of a mini
-- mountain instead of inside the cave"). Restore the client-recorded interior position (#9275).
UPDATE `gameobject` SET `position_x` = -5311.572, `position_y` = -99.422, `position_z` = 403.039
WHERE `guid` = 6940256 AND `id` = 95673 AND `map` = 0
  AND `position_x` BETWEEN -5322 AND -5321 AND `position_y` BETWEEN -118.9 AND -117.9
  AND ABS(`position_z` - 475.665) < 0.01;
