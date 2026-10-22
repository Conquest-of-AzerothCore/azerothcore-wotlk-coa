-- Jadefire Bone Hatchet (517210, guid 6941877, Felwood) floated in the air: the map pass moved it 6.5 yd off the post it
-- is embedded in on live, and the recorded-heights pass kept the post height. Put it back on the post, blade in the
-- wood, as placed in game.
UPDATE `gameobject` SET `position_x` = 3949.41, `position_y` = -590.93, `position_z` = 343.367, `orientation` = 2.22,
`rotation0` = -0.50575, `rotation1` = 0.251075, `rotation2` = -0.739252, `rotation3` = -0.366995
WHERE `guid` = 6941877 AND `id` = 517210;
