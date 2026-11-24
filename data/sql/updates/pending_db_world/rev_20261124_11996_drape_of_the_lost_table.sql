-- Worldforged Drape of the Lost (pickup 6941650, Azshara, #11996): rev_20261106_232 (#11358) lowered it onto the
-- ground the server finds below its x/y, which are tree roots 8.35 yd under the hillside. Restore the realm object's
-- recorded x/y (first-pass row 6900180, dump object 254410) on top of the Elvenstonetable01 stone table.
UPDATE `gameobject` SET `position_x` = 2692.86, `position_y` = -4015.19, `position_z` = 109.722
WHERE `guid` = 6941650 AND `id` = 254410 AND `map` = 1
  AND `position_z` BETWEEN 104.26 AND 104.28;
