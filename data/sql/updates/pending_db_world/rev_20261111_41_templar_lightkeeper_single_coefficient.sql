-- Lightkeeper's burst 561277: the attack power term comes from TemplarCoefficients alone, as for the other
-- table-driven Templar hits (rev_20260909_04); the bonus row of rev_20260918_23 counted it a second time.
DELETE FROM `spell_bonus_data` WHERE `entry` = 561277;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(561277, 0, 0, 0, 0, 'Templar: explicit coefficient or actual result');
