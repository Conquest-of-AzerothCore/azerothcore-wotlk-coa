-- #13040: remove the duplicate Tattered Fabric outside the lower cave of Dreadmaul Rock, keep 6941200 (first-pass row
-- 6900300) and lower it by its measured 4.71 yd ground gap
DELETE FROM `gameobject`
WHERE `guid` = 6940476 AND `id` = 254647 AND `map` = 0
  AND `position_x` BETWEEN -8026.550 AND -8026.450
  AND `position_y` BETWEEN -2521.350 AND -2521.250;
UPDATE `gameobject` SET `position_z` = 221.726
WHERE `guid` = 6941200 AND `id` = 254647 AND `map` = 0
  AND `position_x` BETWEEN -7882.150 AND -7882.050
  AND `position_y` BETWEEN -2664.950 AND -2664.850
  AND `position_z` BETWEEN 226.382 AND 226.482;
