-- The well-cave Weapon Crate only accepts interaction while it has a quest for the player (GO_FLAG_INTERACT_COND),
-- and sits tilted on the cave floor as placed in game with CoA World Edit.
DELETE FROM `gameobject_template_addon` WHERE `entry` = 2300631;
INSERT INTO `gameobject_template_addon` (`entry`, `faction`, `flags`, `mingold`, `maxgold`, `artkit0`, `artkit1`, `artkit2`, `artkit3`) VALUES
(2300631, 0, 4, 0, 0, 0, 0, 0, 0);
UPDATE `gameobject` SET `position_x` = -7798.084, `position_y` = 776.066, `position_z` = 96.913, `orientation` = 5.3742,
`rotation0` = 0.057302, `rotation1` = 0.117276, `rotation2` = -0.435251, `rotation3` = 0.890797 WHERE `guid` = 9920400;
