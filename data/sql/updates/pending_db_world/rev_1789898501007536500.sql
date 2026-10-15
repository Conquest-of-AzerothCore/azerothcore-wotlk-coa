--
-- Geode shared by Primal Shaman's Mask (#590), Terrasmash (#614), Rock Barrier and Stone Edge.
-- The active tooltip specifies 34.9 percent generic Spell Power and 8.5 percent Attack Power.
DELETE FROM `spell_bonus_data` WHERE `entry` = 804002;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(804002, 0.349, 0, 0.085, 0, 'Primalist - Geode');
