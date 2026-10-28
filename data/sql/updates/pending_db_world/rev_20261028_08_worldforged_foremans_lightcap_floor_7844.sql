-- #7844: Worldforged Foreman's Lightcap pickup (guid 6940496, entry 515403, Azurelode Mine,
-- Hillsbrad Foothills) floats 1.9 yd above the mine floor. Set it to Foreman Bonds' own floor height.
UPDATE `gameobject` SET `position_z` = 9.08 WHERE `guid` = 6940496 AND `id` = 515403;
