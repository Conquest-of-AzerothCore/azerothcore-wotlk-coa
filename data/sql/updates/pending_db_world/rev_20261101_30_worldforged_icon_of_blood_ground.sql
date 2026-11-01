-- Worldforged Icon of Blood (#9680): the pickup in Swamp of Sorrows (gameobject guid 6940640, entry 254370)
-- floats 0.914 yd above the true ground (measured with spawn_ground_gap against the live map/vmap data;
-- exceeds the 0.8 yd placement tolerance). This guid was never touched by the realm-wide
-- worldforged_recorded_heights/zone-authoring passes. Lower it onto the measured ground.
UPDATE `gameobject` SET `position_z` = 23.55659 WHERE `guid` = 6940640 AND `id` = 254370;
