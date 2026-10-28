START TRANSACTION;
DELETE FROM `spell_bonus_data` WHERE `entry` = 270355;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(270355, 0, 0.05, 0, 0.05, 'Infected Blood - native level scaling plus tooltip SP/AP per tick');
COMMIT;
