-- GM teleport (.teleport DevModels) on the flat dev map 929 (AdtDevMap), picked in game with .gps.
DELETE FROM `game_tele` WHERE `id` = 10287;
INSERT INTO `game_tele` (`id`, `position_x`, `position_y`, `position_z`, `orientation`, `map`, `name`) VALUES
(10287, 10904.5, -2367.52, 0.00099887, 6.23211, 929, 'DevModels');
