-- Worldforged Cryptfiend Fang (#8112): gameobject guid 6940279 (template 1345027) sits on the mountain
-- surface above the Plaguewood Tunnel (Md_Stratholme_Plaguewood_Tunnel.wmo) instead of inside it. Its
-- spawn row (modules/mod-worldforged-pickups/2026_09_23_05_worldforged_map.sql:331, map 0,
-- 2846.800, -2586.100, z 178.408) keeps the realm map marker's own terrain height because no recorded
-- sighting fell within the module's 12 yd override radius of that marker (the nearest, z 85.743, is
-- 22.6 yd away at a different pin). The tunnel's own WMO collision mesh gives an up-facing floor of
-- z 86.8 at this exact XY, 1.9 yd below that 85.743 sighting at its own XY (floor 83.8 there) and well
-- inside the tunnel (floor 83.8-86.8, ceiling 94.0-95.4 across the area) that the module's own text
-- calls "the cave". Only the height changes; XY and orientation are the realm map position.
UPDATE `gameobject` SET `position_z` = 86.8
    WHERE `guid` = 6940279 AND `id` = 1345027 AND `map` = 0
        AND `position_x` BETWEEN 2846.7 AND 2846.9 AND `position_y` BETWEEN -2586.2 AND -2586.0;
