-- Worldforged Special Seashell (#10417): gameobject guid 6941124 (entry 95718) stood 30.5 yd north of the Ruined
-- Lifeboat (guid 74) after the realm-map conversion in 2026_09_23_05; the catalog position recorded in
-- 2026_09_16_00 (guid 6901141) is 2.1 yd from the wreck and matches the reporter's expectation. Restore it.
UPDATE `gameobject` SET `position_x` = -14654.301, `position_y` = 147.365, `position_z` = 2.262
 WHERE `guid` = 6941124 AND `id` = 95718 AND `map` = 0
   AND `position_x` BETWEEN -14656.4 AND -14656.2 AND `position_y` BETWEEN 178.3 AND 178.5
   AND ABS(`position_z` - 2.262) < 0.01;
