-- Warcraft Reborn spells whose own tooltips give other coefficients than their stock twins.
DELETE FROM `spell_bonus_data` WHERE `entry` IN (1101454, 1101455, 1101456, 1111687, 1111688, 1111689, 1127222, 1157946, 1119306);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(1101454, 0.048, 0, 0, 0, 'Warlock - Life Tap Rank 1 (Warcraft Reborn)'),
(1101455, 0.15, 0, 0, 0, 'Warlock - Life Tap Rank 2 (Warcraft Reborn)'),
(1101456, 0.27, 0, 0, 0, 'Warlock - Life Tap Rank 3 (Warcraft Reborn)'),
(1111687, 0.35, 0, 0, 0, 'Warlock - Life Tap Rank 4 (Warcraft Reborn)'),
(1111688, 0.5, 0, 0, 0, 'Warlock - Life Tap Rank 5 (Warcraft Reborn)'),
(1111689, 0.5, 0, 0, 0, 'Warlock - Life Tap Rank 6 (Warcraft Reborn)'),
(1127222, 0.5, 0, 0, 0, 'Warlock - Life Tap Rank 7 (Warcraft Reborn)'),
(1157946, 0.5, 0, 0, 0, 'Warlock - Life Tap Rank 8 (Warcraft Reborn)'),
(1119306, 0, 0, 0.5, 0, 'Hunter - Counterattack (Warcraft Reborn)');
