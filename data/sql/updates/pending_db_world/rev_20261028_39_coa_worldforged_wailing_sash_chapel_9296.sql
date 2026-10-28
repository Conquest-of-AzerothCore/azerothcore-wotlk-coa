-- Worldforged Wailing Sash (Chapel of Final Grace, Tirisfal, guid 6941315) was pulled down to the
-- stock terrain by later passes because the chapel has no vmap collision there, so every ground probe
-- read the table-top box as floating. Restore the client's own atlas sighting on the chapel table,
-- 0.3 yd from the reporter's own position (#9296).
UPDATE `gameobject` SET `position_x` = 1903.136, `position_y` = -155.898, `position_z` = 40.341
WHERE `guid` = 6941315 AND `id` = 517367 AND `map` = 0
  AND `position_x` BETWEEN 1907.7 AND 1908.7 AND `position_y` BETWEEN -172.7 AND -171.7
  AND ABS(`position_z` - 35.459) < 0.01;
