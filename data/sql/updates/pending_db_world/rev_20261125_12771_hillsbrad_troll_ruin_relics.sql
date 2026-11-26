-- #12771: the Troll Relics for quest 255122 (Long Forgotten History) and its Angered Spirits stood on the open hill
-- north of the troll ruin. Move the six relics and four spirits into the ruin core and re-centre the objective area
-- there. Each z is the vmap floor measured with point_ground_gap on a 5 yd grid (2026-11-25).
UPDATE `gameobject` SET `position_x` = 326, `position_y` = -1461, `position_z` = 42.35
WHERE `guid` = 9001624 AND `id` = 255065 AND `map` = 0
  AND ABS(`position_x` - 390.9) < 0.05 AND ABS(`position_y` + 1400.0) < 0.05;
UPDATE `gameobject` SET `position_x` = 321, `position_y` = -1481, `position_z` = 43.01
WHERE `guid` = 9001625 AND `id` = 255069 AND `map` = 0
  AND ABS(`position_x` - 354.7) < 0.05 AND ABS(`position_y` + 1381.4) < 0.05;
UPDATE `gameobject` SET `position_x` = 341, `position_y` = -1491, `position_z` = 44.03
WHERE `guid` = 9001626 AND `id` = 255070 AND `map` = 0
  AND ABS(`position_x` - 378.1) < 0.05 AND ABS(`position_y` + 1435.4) < 0.05;
UPDATE `gameobject` SET `position_x` = 336, `position_y` = -1511, `position_z` = 56.45
WHERE `guid` = 9001627 AND `id` = 255065 AND `map` = 0
  AND ABS(`position_x` - 400.6) < 0.05 AND ABS(`position_y` + 1366.7) < 0.05;
UPDATE `gameobject` SET `position_x` = 356, `position_y` = -1516, `position_z` = 57.11
WHERE `guid` = 9001628 AND `id` = 255069 AND `map` = 0
  AND ABS(`position_x` - 328.1) < 0.05 AND ABS(`position_y` + 1408.3) < 0.05;
UPDATE `gameobject` SET `position_x` = 346, `position_y` = -1466, `position_z` = 42.62
WHERE `guid` = 9001629 AND `id` = 255070 AND `map` = 0
  AND ABS(`position_x` - 419.4) < 0.05 AND ABS(`position_y` + 1428.3) < 0.05;

UPDATE `creature` SET `position_x` = 336, `position_y` = -1471, `position_z` = 42.26
WHERE `guid` = 9950848 AND `id` = 255495 AND `map` = 0
  AND ABS(`position_x` - 360.6) < 0.05 AND ABS(`position_y` + 1386.8) < 0.05;
UPDATE `creature` SET `position_x` = 331, `position_y` = -1486, `position_z` = 43.11
WHERE `guid` = 9950849 AND `id` = 255495 AND `map` = 0
  AND ABS(`position_x` - 377.2) < 0.05 AND ABS(`position_y` + 1425.1) < 0.05;
UPDATE `creature` SET `position_x` = 331, `position_y` = -1516, `position_z` = 56.61
WHERE `guid` = 9950851 AND `id` = 255495 AND `map` = 0
  AND ABS(`position_x` - 341.8) < 0.05 AND ABS(`position_y` + 1405.9) < 0.05;
UPDATE `creature` SET `position_x` = 351, `position_y` = -1476, `position_z` = 42.57
WHERE `guid` = 9950854 AND `id` = 255495 AND `map` = 0
  AND ABS(`position_x` - 354.9) < 0.05 AND ABS(`position_y` + 1438.7) < 0.05;

UPDATE `quest_poi_points` SET `X` = 314, `Y` = -1450
WHERE `QuestID` = 255122 AND `Idx1` = 0 AND `Idx2` = 0 AND `X` = 308 AND `Y` = -1347;
UPDATE `quest_poi_points` SET `X` = 364, `Y` = -1450
WHERE `QuestID` = 255122 AND `Idx1` = 0 AND `Idx2` = 1 AND `X` = 439 AND `Y` = -1347;
UPDATE `quest_poi_points` SET `X` = 364, `Y` = -1522
WHERE `QuestID` = 255122 AND `Idx1` = 0 AND `Idx2` = 2 AND `X` = 439 AND `Y` = -1455;
UPDATE `quest_poi_points` SET `X` = 314, `Y` = -1522
WHERE `QuestID` = 255122 AND `Idx1` = 0 AND `Idx2` = 3 AND `X` = 308 AND `Y` = -1455;
