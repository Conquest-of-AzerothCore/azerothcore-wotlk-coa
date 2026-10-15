--
-- Earthmother's Binding (#567): the active heal scales with both bonus healing and attack power.
DELETE FROM `spell_bonus_data` WHERE `entry` = 805107;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(805107, 1, 0, 1, 0, 'Primalist: Earthmothers Binding');
