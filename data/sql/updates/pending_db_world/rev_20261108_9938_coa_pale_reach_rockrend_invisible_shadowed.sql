-- Three Shadowed (164328) in Rockrend Mine spawned inside the rock beside the tunnels: no floor under them (only the
-- terrain 130+ yd above), off the navmesh, unseen and out of reach while they hit players in the tunnel. Their
-- live-capture points (47124, 47147, 47185) were taken mid-move. Moved to the nearest open tunnel floor.
UPDATE `creature` SET `position_x` = -7074.0, `position_y` = 1240.5, `position_z` = 74.942
    WHERE `guid` = 9961914 AND `id` = 164328 AND `position_y` BETWEEN 1250.39 AND 1250.41;
UPDATE `creature` SET `position_x` = -7066.5, `position_y` = 1248.0, `position_z` = 75.195
    WHERE `guid` = 9961918 AND `id` = 164328 AND `position_y` BETWEEN 1249.24 AND 1249.26;
UPDATE `creature` SET `position_x` = -7092.0, `position_y` = 1307.0, `position_z` = 74.315
    WHERE `guid` = 9961908 AND `id` = 164328 AND `position_y` BETWEEN 1306.27 AND 1306.29;

-- Shadowed are about as tall as a player even while crouched on the realm (MD0GT_RsHQs 2:40:22, 2:09:00); the
-- import drew them too small; 1.6 was settled in game.
UPDATE `creature_template_model` SET `DisplayScale` = 1.6 WHERE `CreatureID` = 164328 AND `CreatureDisplayID` = 142372;
