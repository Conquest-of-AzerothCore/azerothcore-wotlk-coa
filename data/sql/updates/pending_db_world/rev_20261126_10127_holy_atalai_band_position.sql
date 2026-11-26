-- Holy Atal'ai Band (entry 254368, guid 6940634, Swamp of Sorrows): restore to first-pass realm-dump
-- coordinates (guid 6900144, Z observed). The map pass shifted it 2.79 yd southwest into
-- Stranglethornruins02.m2 and 0.395 yd below terrain.
UPDATE `gameobject`
SET `position_x` = -10488.902, `position_y` = -4029.453, `position_z` = 17.417
WHERE `guid` = 6940634 AND `id` = 254368 AND `map` = 0
AND `position_x` BETWEEN -10492.0 AND -10488.0
AND `position_y` BETWEEN -4032.3 AND -4028.5;
