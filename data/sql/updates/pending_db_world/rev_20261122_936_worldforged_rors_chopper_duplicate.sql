-- #12983: remove the duplicate Ror's Chopper in Deadwood Village, keep 6942099 next to Overlord Ror (first-pass row
-- 6900584) and lower it by its measured 1.35 yd ground gap
DELETE FROM `gameobject`
WHERE `guid` = 6942101 AND `id` = 517202 AND `map` = 1
  AND `position_x` BETWEEN 3606.550 AND 3606.650
  AND `position_y` BETWEEN -1147.350 AND -1147.250;
UPDATE `gameobject` SET `position_z` = 223.762
WHERE `guid` = 6942099 AND `id` = 517202 AND `map` = 1
  AND `position_x` BETWEEN 3519.050 AND 3519.150
  AND `position_y` BETWEEN -1125.350 AND -1125.250
  AND `position_z` BETWEEN 225.059 AND 225.159;
