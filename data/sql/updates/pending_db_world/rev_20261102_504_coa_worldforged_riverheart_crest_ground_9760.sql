-- Worldforged Riverheart Crest (Stranglethorn Vale, guid 6940969) floated 1.38 yd above the terrain (#9760).
-- Lower it onto the ground.
UPDATE `gameobject` SET `position_z` = 28.20095
WHERE `guid` = 6940969 AND `id` = 95741 AND `map` = 0
  AND `position_x` BETWEEN -11549.3 AND -11549.1 AND `position_y` BETWEEN -225.6 AND -225.4
  AND ABS(`position_z` - 29.577) < 0.01;
