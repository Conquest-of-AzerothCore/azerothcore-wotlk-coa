-- Worldforged Firemane Effigy (pickup 6941625, Dustwallow Marsh) floated 6.7 yd above the Den of Flame floor (#11119). Set it on the floor the server measures at its x/y (20.494; the reporter stood at 20.50).
UPDATE `gameobject` SET `position_z` = 20.494
WHERE `guid` = 6941625 AND `id` = 96148 AND `map` = 1 AND `position_z` BETWEEN 27.206 AND 27.226;
