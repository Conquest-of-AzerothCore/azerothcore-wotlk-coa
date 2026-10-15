-- Eruption (#546): the active description specifies 20% of the higher Fire/Nature power per Magma Geode.
-- Keep the native damage and modifier path; the scoped school selector does not add the two school bonuses.
DELETE FROM `spell_bonus_data` WHERE `entry` = 803140;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(803140, 0.2, 0, 0, 0, 'Primalist: Eruption - Magma Geode');
