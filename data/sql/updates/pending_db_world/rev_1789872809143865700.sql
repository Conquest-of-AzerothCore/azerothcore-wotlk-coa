-- Every active Geode Barrage rank (500402, 502769-502777) forwards its rolled base damage to 803138
-- three times. Their visible tooltip adds 36% Nature spell power and 9% attack power to EACH stone.
-- Put both coefficients on the direct-damage helper only; the channel itself must not add them again.
DELETE FROM `spell_bonus_data` WHERE `entry` = 803138;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(803138, 0.36, 0, 0.09, 0, 'Primalist: Geode Barrage - physical damage per stone');
