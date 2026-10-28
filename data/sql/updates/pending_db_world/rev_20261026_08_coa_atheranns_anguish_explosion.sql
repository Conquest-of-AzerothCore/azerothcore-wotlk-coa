-- Atherann's Anguish (570146, 680680) accumulates a share of the damage dealt to the target and then explodes "for
-- that amount" through 680681. The explosion's own spell power multiplier (0.25) added spell power on top of the
-- stored amount; it now deals the stored amount, with the explosion's damage modifiers still applying.
DELETE FROM `spell_bonus_data` WHERE `entry` = 680681;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(680681, 0, 0, 0, 0, 'CoA Bloodmage - Atherann''s Anguish explosion deals the stored damage');
