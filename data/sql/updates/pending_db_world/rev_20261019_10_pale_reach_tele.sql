-- .teleport had no destination for the Pale Reach; the entry stands at the Dunshire inn (Innkeeper Miralda).
DELETE FROM `game_tele` WHERE `id` = 2300 OR `name` = 'PaleReach';
INSERT INTO `game_tele` (`id`, `position_x`, `position_y`, `position_z`, `orientation`, `map`, `name`) VALUES
(2300, -7768.2, 601.5, 138.3, 3.14, 0, 'PaleReach');
