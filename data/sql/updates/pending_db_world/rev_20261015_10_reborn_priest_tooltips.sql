-- Warcraft Reborn Priest: Holy Nova heals party members with its own Reborn heal.
DELETE FROM `spell_linked_spell` WHERE `spell_trigger` IN (1115237, 1115430, 1115431, 1127799, 1127800, 1127801, 1125331, 1148077, 1148078) AND `type` = 0;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(1115237, 1123455, 0, 'Warcraft Reborn Holy Nova (rank1)'),
(1115430, 1123458, 0, 'Warcraft Reborn Holy Nova (rank2)'),
(1115431, 1123459, 0, 'Warcraft Reborn Holy Nova (rank3)'),
(1127799, 1127803, 0, 'Warcraft Reborn Holy Nova (rank4)'),
(1127800, 1127804, 0, 'Warcraft Reborn Holy Nova (rank5)'),
(1127801, 1127805, 0, 'Warcraft Reborn Holy Nova (rank6)'),
(1125331, 1125329, 0, 'Warcraft Reborn Holy Nova (rank7)'),
(1148077, 1148075, 0, 'Warcraft Reborn Holy Nova (rank8)'),
(1148078, 1148076, 0, 'Warcraft Reborn Holy Nova (rank9)');
