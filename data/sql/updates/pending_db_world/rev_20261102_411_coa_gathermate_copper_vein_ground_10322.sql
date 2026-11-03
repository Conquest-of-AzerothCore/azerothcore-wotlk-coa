-- The GatherMate import (#9555) placed Copper Vein 12010065 24.9 yd above the ground, so the node floats out of
-- reach (#10322). Set it on the ground height measured by the server (spawn_ground_gap).
UPDATE `gameobject` SET `position_z` = 148.54
WHERE `guid` = 12010065 AND `id` = 1731 AND `map` = 0 AND `position_z` BETWEEN 173.44 AND 173.46;
