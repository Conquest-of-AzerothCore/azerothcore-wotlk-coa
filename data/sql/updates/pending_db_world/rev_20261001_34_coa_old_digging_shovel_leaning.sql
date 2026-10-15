-- Old Digging Shovel 9303400 (the way back up out of the Cain manor cellar) stood upright in the middle of the cellar
-- floor (playtest). It now leans against the side wall at the foot of the cellar stair, where players coming down
-- still see it but do not walk into it: 4 yd from its old spot, its base 0.45 yd from a flat wall face
-- (surface.wall at 0.6 and 1.4 yd height), turned to the wall and tilted 15 degrees so the handle rests on it.
UPDATE `gameobject` SET `position_x` = 1942.5, `position_y` = 1964.0, `position_z` = 148.651, `orientation` = 0.79,
    `rotation0` = -0.050228, `rotation1` = 0.120475, `rotation2` = 0.381516, `rotation3` = 0.9151
    WHERE `guid` = 7916019 AND `id` = 9303400;
