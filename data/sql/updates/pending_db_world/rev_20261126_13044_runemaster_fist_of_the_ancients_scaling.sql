-- Fist of the Ancients (712326, ranks 1-7: 712326, 712330-712335):
-- Tooltip specifies ${$m1+0+$AP*.55+$SP*0.2} Elemental Damage.
DELETE FROM `spell_bonus_data` WHERE `entry` = 712326;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(712326, 0.2, 0, 0.55, 0, 'Ascension Fist of the Ancients - tooltip AP and SP scaling');
