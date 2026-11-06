-- "Dangerous!" wanted board (guid 17154) in Tarren Mill: its spawn comes from a later retail sniff (build 42328) and
-- hovers 1.36 yd over this client's terrain. Move it to the spot picked in game, standing on the ground (raised 0.3 yd so its base does not sink into the slope).
UPDATE `gameobject` SET `position_x` = -15.4064, `position_y` = -919.596, `position_z` = 56.27, `orientation` = 2.56923,
  `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.959329, `rotation3` = 0.282292
WHERE `guid` = 17154 AND `id` = 2008 AND `position_z` BETWEEN 58.096 AND 58.098;
