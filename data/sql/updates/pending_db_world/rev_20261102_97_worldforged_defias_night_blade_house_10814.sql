-- Worldforged Defias Night Blade (#10814): gameobject guid 6940342 (entry 90274) was authored inside the Yorgen
-- Farmstead house at (-11104.431641, -531.734375, 34.372692) and rev_20261014_95 moved it 10.3 yd south onto the terrain
-- outside. Restore the authored position.
UPDATE `gameobject` SET `position_x` = -11104.431641, `position_y` = -531.734375, `position_z` = 34.372692
 WHERE `guid` = 6940342 AND `id` = 90274 AND `map` = 0
   AND `position_x` BETWEEN -11103.3 AND -11103.1 AND `position_y` BETWEEN -542.17 AND -541.97
   AND ABS(`position_z` - 32.395) < 0.01;
