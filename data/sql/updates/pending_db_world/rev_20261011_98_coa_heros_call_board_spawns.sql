-- Hero's Call and Warchief's Command Boards at the client call board map points
DELETE FROM `gameobject` WHERE `guid` BETWEEN 7905403 AND 7905409;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation2`,
`rotation3`, `state`, `Comment`) VALUES
(7905403, 402000, 0, -10679.592773, 1025.414429, 32.7, 1.463, 0.667986646, 0.74417326, 1, 'Hero''s Call Board'),
(7905404, 402000, 0, -4899.702148, -963.564209, 501.5, 2.72271, 0.978147223, 0.207913468, 1, 'Hero''s Call Board'),
(7905405, 402000, 1, 9941.015625, 2275.197021, 1341.5, 0.017453, 0.008726389, 0.999961924, 1, 'Hero''s Call Board'),
(7905406, 402000, 530, -3934.833008, -11634.648438, -138.4, 2.07694, 0.861628701, 0.507539143, 1, 'Hero''s Call Board'),
(7905407, 402001, 1, -1258.383423, 70.345734, 127.9, 4.18879, 0.866025455, -0.499999911, 1, 'Warchief''s Command Board'),
(7905408, 402001, 0, 1558.452148, 239.822388, -43.1, 0.252436, 0.125883137, 0.992045077, 1, 'Warchief''s Command Board'),
(7905409, 402001, 530, 9488.196289, -7270.505859, 14.33, 4.64258, 0.731352273, -0.681999892, 1, 'Warchief''s Command Board');
