-- Hero (class 10): the free-pick class of the Freepick and Wildcard realms.
DELETE FROM `playercreateinfo` WHERE `class` = 10;
INSERT INTO `playercreateinfo` (`race`, `class`, `map`, `zone`, `position_x`, `position_y`, `position_z`, `orientation`)
VALUES
(1, 10, 0, 12, -8949.95, -132.493, 83.5312, 0),
(2, 10, 1, 14, -618.518, -4251.67, 38.718, 0),
(3, 10, 0, 1, -6240.32, 331.033, 382.758, 6.17716),
(4, 10, 1, 141, 10311.3, 832.463, 1326.41, 5.69632),
(5, 10, 0, 85, 1676.71, 1678.31, 121.67, 2.70526),
(6, 10, 1, 215, -2917.58, -257.98, 52.9968, 0),
(7, 10, 0, 1, -6240.32, 331.033, 382.758, 0),
(8, 10, 1, 14, -618.518, -4251.67, 38.718, 0),
(10, 10, 530, 3431, 10349.6, -6357.29, 33.4026, 5.31605),
(11, 10, 530, 3526, -3961.64, -13931.2, 100.615, 2.08364);

DELETE FROM `player_class_stats` WHERE `Class` = 10;
INSERT INTO `player_class_stats`
(`Class`, `Level`, `BaseHP`, `BaseMana`, `Strength`, `Agility`, `Stamina`, `Intellect`, `Spirit`)
SELECT 10, `Level`, `BaseHP`, `BaseMana`, `Strength`, `Agility`, `Stamina`, `Intellect`, `Spirit`
FROM `player_class_stats` WHERE `Class` = 2;

DELETE FROM `playercreateinfo_item` WHERE `class` = 10;
INSERT INTO `playercreateinfo_item` (`race`, `class`, `itemid`, `amount`, `Note`) VALUES
(1, 10, 38, 1, 'Hero: Warrior starting outfit'),
(1, 10, 39, 1, 'Hero: Warrior starting outfit'),
(1, 10, 40, 1, 'Hero: Warrior starting outfit'),
(1, 10, 49778, 1, 'Hero: Warrior starting outfit'),
(1, 10, 6948, 1, 'Hero: Warrior starting outfit'),
(2, 10, 6125, 1, 'Hero: Warrior starting outfit'),
(2, 10, 139, 1, 'Hero: Warrior starting outfit'),
(2, 10, 140, 1, 'Hero: Warrior starting outfit'),
(2, 10, 12282, 1, 'Hero: Warrior starting outfit'),
(2, 10, 6948, 1, 'Hero: Warrior starting outfit'),
(3, 10, 38, 1, 'Hero: Warrior starting outfit'),
(3, 10, 39, 1, 'Hero: Warrior starting outfit'),
(3, 10, 40, 1, 'Hero: Warrior starting outfit'),
(3, 10, 12282, 1, 'Hero: Warrior starting outfit'),
(3, 10, 6948, 1, 'Hero: Warrior starting outfit'),
(4, 10, 6120, 1, 'Hero: Warrior starting outfit'),
(4, 10, 6121, 1, 'Hero: Warrior starting outfit'),
(4, 10, 6122, 1, 'Hero: Warrior starting outfit'),
(4, 10, 49778, 1, 'Hero: Warrior starting outfit'),
(4, 10, 6948, 1, 'Hero: Warrior starting outfit'),
(5, 10, 6125, 1, 'Hero: Warrior starting outfit'),
(5, 10, 139, 1, 'Hero: Warrior starting outfit'),
(5, 10, 140, 1, 'Hero: Warrior starting outfit'),
(5, 10, 49778, 1, 'Hero: Warrior starting outfit'),
(5, 10, 6948, 1, 'Hero: Warrior starting outfit'),
(6, 10, 6125, 1, 'Hero: Warrior starting outfit'),
(6, 10, 139, 1, 'Hero: Warrior starting outfit'),
(6, 10, 2361, 1, 'Hero: Warrior starting outfit'),
(6, 10, 6948, 1, 'Hero: Warrior starting outfit'),
(7, 10, 38, 1, 'Hero: Warrior starting outfit'),
(7, 10, 39, 1, 'Hero: Warrior starting outfit'),
(7, 10, 40, 1, 'Hero: Warrior starting outfit'),
(7, 10, 49778, 1, 'Hero: Warrior starting outfit'),
(7, 10, 6948, 1, 'Hero: Warrior starting outfit'),
(8, 10, 6125, 1, 'Hero: Warrior starting outfit'),
(8, 10, 139, 1, 'Hero: Warrior starting outfit'),
(8, 10, 25861, 1, 'Hero: Warrior starting outfit'),
(8, 10, 49778, 1, 'Hero: Warrior starting outfit'),
(8, 10, 6948, 1, 'Hero: Warrior starting outfit'),
(10, 10, 20904, 1, 'Hero: Warrior starting outfit'),
(10, 10, 20902, 1, 'Hero: Warrior starting outfit'),
(10, 10, 20903, 1, 'Hero: Warrior starting outfit'),
(10, 10, 23346, 1, 'Hero: Warrior starting outfit'),
(10, 10, 6948, 1, 'Hero: Hearthstone'),
(11, 10, 23473, 1, 'Hero: Warrior starting outfit'),
(11, 10, 23474, 1, 'Hero: Warrior starting outfit'),
(11, 10, 23475, 1, 'Hero: Warrior starting outfit'),
(11, 10, 23346, 1, 'Hero: Warrior starting outfit'),
(11, 10, 6948, 1, 'Hero: Warrior starting outfit');
