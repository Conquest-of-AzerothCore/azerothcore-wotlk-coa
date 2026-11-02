-- Captain's Compass (515828, guid 6941523) in Lost Rigger's Cove took its z 14.851 from a sighting 10.2 yd away
-- (2026_09_23_06_worldforged_recorded_heights.sql); at its own x,y the measured spawn_ground_gap is 1.731 yd, so it
-- floats above the upper floor at 13.120, the height the #10647 reporter stood at.
UPDATE `gameobject` SET `position_z` = 13.120 WHERE `guid` = 6941523 AND `id` = 515828;
