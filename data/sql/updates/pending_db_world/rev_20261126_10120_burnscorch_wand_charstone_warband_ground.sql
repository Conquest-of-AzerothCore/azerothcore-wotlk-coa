-- Burnscorch Wand (entry 254654, guid 6940209, Burning Steppes): restore to first-pass realm-dump
-- coordinates (guid 6900306, Z from realm dump). The map pass shifted it 0.80 yd northwest onto
-- higher terrain (128.3712), clipping it 0.117 yd into the ground.
UPDATE `gameobject`
SET `position_x` = -7985.380, `position_y` = -2114.510, `position_z` = 128.254
WHERE `guid` = 6940209 AND `id` = 254654 AND `map` = 0
AND `position_x` BETWEEN -7986.9 AND -7984.4
AND `position_y` BETWEEN -2115.5 AND -2112.9;

-- Charstone Warband (entry 1345022, guid 6975008, Burning Steppes): lower Z from 128.250 (copied
-- from Burnscorch Wand 5.1 yd away) to the terrain surface 127.7573 (matching ground pass guid
-- 6910019 at the same XY), eliminating the 0.493 yd float.
UPDATE `gameobject`
SET `position_z` = 127.7573
WHERE `guid` = 6975008 AND `id` = 1345022 AND `map` = 0
AND `position_x` BETWEEN -7982.2 AND -7980.2
AND `position_y` BETWEEN -2112.9 AND -2110.9;
