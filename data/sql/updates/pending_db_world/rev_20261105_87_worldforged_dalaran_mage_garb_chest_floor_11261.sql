-- Worldforged Dalaran Mage Garb chest (pickup 6940244, Alterac) sat 1.9 yd under the floor of the Prisonhq building at its x/y (#11261): the alignment pass set the terrain height. Set it on the floor the server measures there (55.187).
UPDATE `gameobject` SET `position_z` = 55.187
WHERE `guid` = 6940244 AND `id` = 515365 AND `map` = 0 AND `position_z` BETWEEN 53.264 AND 53.284;
