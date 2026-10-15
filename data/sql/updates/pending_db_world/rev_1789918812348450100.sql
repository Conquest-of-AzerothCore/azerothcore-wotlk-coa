--
-- Pulverize (#1059): the rank area effect and its repeat each scale with 35% attack power.
DELETE FROM `spell_bonus_data` WHERE `entry` IN (800178, 500945);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`)
VALUES
(800178, 0, 0, 0.35, 0, 'Primalist - Totemic Smash area damage'),
(500945, 0, 0, 0.35, 0, 'Primalist - Pulverize area repeat');
