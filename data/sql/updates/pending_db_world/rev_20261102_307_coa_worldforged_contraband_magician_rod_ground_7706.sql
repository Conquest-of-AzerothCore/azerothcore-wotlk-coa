-- The Contraband Magician Rod pickup (Searing Gorge, guid 6940267) floated 1.12 yd above the terrain (#7706).
-- Set it on the terrain height at its position.
UPDATE `gameobject` SET `position_z` = 223.46
WHERE `guid` = 6940267 AND `id` = 1345026 AND `map` = 0
  AND `position_x` BETWEEN -6873.3 AND -6873.1
  AND `position_y` BETWEEN -1103.3 AND -1103.1
  AND ABS(`position_z` - 224.579) < 0.01;
