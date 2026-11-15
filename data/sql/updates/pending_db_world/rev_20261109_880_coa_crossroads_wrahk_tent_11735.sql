-- Wrahk (guid 15098) stayed at the old tent spot when patch-WB1 moved Kil'hala; stand him inside her tent,
-- at the reporter's map point (51.92, 31.94), on the tent floor (#11735).
UPDATE `creature` SET `position_x` = -545.547, `position_y` = -2638.534, `position_z` = 97.166
WHERE `guid` = 15098 AND `id` = 3485 AND `map` = 1
  AND `position_x` BETWEEN -532.001 AND -531.999
  AND `position_y` BETWEEN -2670.001 AND -2669.999
  AND `position_z` BETWEEN 95.787 AND 95.789;
-- Kil'hala (guid 15097) stood 1.13 yd under the same tent floor; raise her to it (#11735).
UPDATE `creature` SET `position_z` = 97.140
WHERE `guid` = 15097 AND `id` = 3484 AND `map` = 1
  AND `position_x` BETWEEN -546.280 AND -546.278
  AND `position_y` BETWEEN -2640.231 AND -2640.229
  AND `position_z` BETWEEN 96.010 AND 96.012;
