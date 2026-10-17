-- Kayren Soothallow (2401), Tarren Mill, stood 0.29 yd below the terrain (z 55.306, ground 55.591 there) and sank to
-- the knees. Raise her onto the ground.
UPDATE `creature` SET `position_z` = 55.6 WHERE `guid` = 15525 AND `id` = 2401;
