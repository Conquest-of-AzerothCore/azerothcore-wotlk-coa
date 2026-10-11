-- Hero's Call and Warchief's Command Boards, placed in game near the client call board map points
DELETE FROM `gameobject` WHERE `guid` BETWEEN 7905403 AND 7905409;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation2`,
`rotation3`, `state`, `Comment`) VALUES
(7905403, 402000, 0, -10601.4, 1067.11, 36.0644, 1.2829, 0.598357852, 0.801228982, 1, 'Hero''s Call Board'),
(7905404, 402000, 0, -4899.702148, -963.564209, 501.5, 2.72271, 0.978147223, 0.207913468, 1, 'Hero''s Call Board'),
(7905405, 402000, 1, 9940.31, 2274.25, 1341.39, 1.5998, 0.717286417, 0.696778441, 1, 'Hero''s Call Board'),
(7905406, 402000, 530, -3934.833008, -11634.648438, -138.4, 2.07694, 0.861628701, 0.507539143, 1, 'Hero''s Call Board'),
(7905407, 402001, 1, -1248.5, 81.7473, 128.489, 5.19604, 0.517197, -0.855866382, 1, 'Warchief''s Command Board'),
(7905408, 402001, 0, 1556.43, 240.969, -43.1016, 6.24897, 0.017106819, -0.999853668, 1, 'Warchief''s Command Board'),
(7905409, 402001, 530, 9488.196289, -7270.505859, 14.33, 4.64258, 0.731352273, -0.681999892, 1, 'Warchief''s Command Board');
