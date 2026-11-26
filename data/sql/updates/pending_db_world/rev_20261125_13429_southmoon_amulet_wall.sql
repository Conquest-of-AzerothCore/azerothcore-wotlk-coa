-- #13429: Southmoon Amulet (guid 6942219, id 515843, Tanaris) sat at (-9271.600, -3086.300, 12.9566),
-- enclosed inside a solid stone wall of Tanarisruins04.wmo (roof z 25.10, south face 0.50 yd away).
-- Move it to its first-pass realm-dump XY (-9266.215, -3084.820) in the open courtyard at stock terrain z 14.421.
UPDATE `gameobject`
SET `position_x` = -9266.215,
    `position_y` = -3084.820,
    `position_z` = 14.421
WHERE `guid` = 6942219 AND `id` = 515843 AND `map` = 1;
