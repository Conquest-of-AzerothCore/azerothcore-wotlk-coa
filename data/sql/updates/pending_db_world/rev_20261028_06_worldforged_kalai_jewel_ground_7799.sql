-- #7799: Worldforged Kal'ai Jewel (guid 6940676, entry 95729, Kal'ai Ruins, Stranglethorn Vale) spawns
-- 3.55 yd below the ground, inside a ruin pillar; the realm-map marker XY is off by 16 yd from the
-- object's own recorded sighting, whose Z already matches its ground exactly. Move it to that sighting.
UPDATE `gameobject` SET `position_x` = -12176.242, `position_y` = -22.965, `position_z` = -10.968
    WHERE `guid` = 6940676 AND `id` = 95729;
