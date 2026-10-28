-- Worldforged Kul Tiras Armplates (Tiragarde Keep, guid 6941894) was lowered from its recorded height
-- to the stock terrain by rev_20261006_65_worldforged_openworld_float_heights.sql, 4.18 yd below the
-- keep's own ground floor, so the pickup stood buried under the ruin instead of inside it (#9365).
UPDATE `gameobject` SET `position_z` = 25.243
WHERE `guid` = 6941894 AND `id` = 90598 AND `map` = 1
  AND `position_x` BETWEEN -271.7 AND -270.7 AND `position_y` BETWEEN -5135.3 AND -5134.3
  AND ABS(`position_z` - 21.064) < 0.01;
