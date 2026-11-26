-- #12819: Lord Aliden Perenolde (2423) stood outside on the hill. The client's objective point for quest 507
-- (QuestSuperTrack 2413 -> SuperTrack 4215) is inside the Perenolde manor: place him and the map POI there, on the
-- manor floor (z 105.32, measured with spawn_ground_gap; the SuperTrack point at z 105.0 is 0.32 yd under it).
UPDATE `creature` SET `position_x` = 1273.19, `position_y` = -413.0, `position_z` = 105.32
WHERE `guid` = 16900 AND `id` = 2423 AND `map` = 0 AND `position_x` BETWEEN 1227.88 AND 1227.90
  AND `position_y` BETWEEN -317.50 AND -317.48;

UPDATE `quest_poi_points` SET `X` = 1273, `Y` = -413
WHERE `QuestID` = 507 AND `Idx1` = 0 AND `Idx2` = 0 AND `X` = 1228 AND `Y` = -317;
