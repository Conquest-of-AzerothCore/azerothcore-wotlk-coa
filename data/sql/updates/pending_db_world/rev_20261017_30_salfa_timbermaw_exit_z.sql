-- Salfa (11556), Winterspring exit of Timbermaw Hold, stood 0.65 yd below the terrain (z 586.148, ground 586.80 there,
-- measured in game with .npc move) and sank into the ground. Raise her onto the ground.
UPDATE `creature` SET `position_z` = 586.8 WHERE `guid` = 41642 AND `id` = 11556;
