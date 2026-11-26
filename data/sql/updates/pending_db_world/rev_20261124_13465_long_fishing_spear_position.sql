-- #13465: the Long Fishing Spear hung 0.72 yd in the air beside the Bloodhoof canoe.
-- Restore the x/y of first-pass row 6900919 (2026_09_16_00, the realm dump spot) on the canoe; the height is kept.
UPDATE `gameobject` SET `position_x` = -2405.014, `position_y` = -324.354
WHERE `guid` = 6941920 AND `id` = 90340 AND `map` = 1
  AND `position_x` BETWEEN -2408.250 AND -2408.150 AND `position_y` BETWEEN -328.450 AND -328.350 AND `position_z` BETWEEN -12.406 AND -12.306;
