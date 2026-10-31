DELETE FROM `spell_bonus_data` WHERE `entry` IN (1101495, 1102812, 1102974, 1120167, 1124275, 1126573, 1160089, 1167485);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(1101495, 0, 0, 0.2, 0, 'Warcraft Reborn Hunter - Mongoose Bite'),
(1102812, 0.07, 0, 0.07, 0, 'Warcraft Reborn Paladin - Holy Wrath'),
(1102974, 0, 0, 0.18, 0, 'Warcraft Reborn Hunter - Wing Clip'),
(1120167, 0.1125, 0, 0.1125, 0, 'Warcraft Reborn Paladin - Seal of Light'),
(1124275, 0.15, 0, 0.15, 0, 'Warcraft Reborn Paladin - Hammer of Wrath'),
(1126573, 0, 0.04, 0, 0.04, 'Warcraft Reborn Paladin - Consecration'),
(1160089, 0, 0, 0.05, 0, 'Warcraft Reborn Druid - Faerie Fire (Feral)'),
(1167485, 0, 0, 0.4, 0, 'Warcraft Reborn Paladin - Hand of Reckoning');
