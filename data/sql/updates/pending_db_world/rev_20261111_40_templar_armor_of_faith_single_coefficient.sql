-- Armor of Faith 801546: the attack power and spell power terms come from TemplarCoefficients alone, as for the
-- other table-driven Templar hits (rev_20260909_04); the bonus row counted them a second time.
DELETE FROM `spell_bonus_data` WHERE `entry` = 801546;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(801546, 0, 0, 0, 0, 'Templar: explicit coefficient or actual result');
