-- Worldforged Thunderwalk Breastplate (#9166): pickup template 1345152 (guid 6942324) stands at the
-- realm-map marker XY in Mulgore, 1.38 yd under the terrain there. Restore its stored height to the
-- terrain.
UPDATE `gameobject` SET `position_z` = -55.40
WHERE `guid` = 6942324 AND `id` = 1345152 AND `map` = 1
  AND `position_x` BETWEEN -995.9 AND -994.9 AND `position_y` BETWEEN -577.0 AND -576.0
  AND ABS(`position_z` + 56.785) < 0.01;
