-- Worldforged Mind's Eye Fragment (#10717): the realm-map pass (2026_09_23_05_worldforged_map.sql) put the pickup
-- at (-12359.1, -1161.4, 1.083) in the Mosh'Ogg cave rock, where worldserver vmap probes find no floor under it
-- at all. Move it to its catalog spot (2026_09_16_00_worldforged_pickups.sql guid 6901175's XY, wiped by the
-- realm-map pass), on the cave floor measured there (3.49, 0.52 under the catalog Z).

UPDATE `gameobject`
SET `position_x` = -12340.8, `position_y` = -1158.51, `position_z` = 3.49
WHERE `guid` = 6940749 AND `id` = 95752 AND `position_z` BETWEEN 1.0 AND 1.2;
