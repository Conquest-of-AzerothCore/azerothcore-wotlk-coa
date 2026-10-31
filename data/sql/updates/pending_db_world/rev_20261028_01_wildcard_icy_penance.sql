-- Icy Penance: explicit per-bolt SP/AP coefficients from the channel tooltip; no double periodic scaling.
DELETE FROM `spell_bonus_data` WHERE `entry` IN (271324, 271337, 271338, 271339, 271340, 271333, 271334, 271335);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(271324, 0.58, 0, 0.078, 0, 'Wildcard Icy Penance rank 1'),
(271337, 0.58, 0, 0.078, 0, 'Wildcard Icy Penance rank 2'),
(271338, 0.58, 0, 0.078, 0, 'Wildcard Icy Penance rank 3'),
(271339, 0.58, 0, 0.078, 0, 'Wildcard Icy Penance rank 4'),
(271340, 0.58, 0, 0.078, 0, 'Wildcard Icy Penance rank 5'),
(271333, 0.58, 0, 0.078, 0, 'Wildcard Icy Penance rank 6'),
(271334, 0.58, 0, 0.078, 0, 'Wildcard Icy Penance rank 7'),
(271335, 0.58, 0, 0.078, 0, 'Wildcard Icy Penance rank 8');
