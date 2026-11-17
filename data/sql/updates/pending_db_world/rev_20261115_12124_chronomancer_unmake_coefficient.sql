-- Unmake (rank chain 804418): every rank's tooltip prices a tick at $m1 + $SP*coefficient, 0.1 for rank 1 804418
-- and 0.12 for ranks 2-11 (503784-503790, 504574, 574344, 574345). The server used the stock EffectBonusMultiplier
-- column instead, 0 on rank 1 and 0.0624 on the others, which CoA does not author. Each rank gets its own row because
-- the lookup falls back to the first rank, whose coefficient differs.
DELETE FROM `spell_bonus_data` WHERE `entry` IN (804418, 503784, 503785, 503786, 503787, 503788, 503789, 503790, 504574, 574344, 574345);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(804418, 0, 0.1, 0, 0, 'Chronomancer Unmake Rank 1'),
(503784, 0, 0.12, 0, 0, 'Chronomancer Unmake Rank 2'),
(503785, 0, 0.12, 0, 0, 'Chronomancer Unmake Rank 3'),
(503786, 0, 0.12, 0, 0, 'Chronomancer Unmake Rank 4'),
(503787, 0, 0.12, 0, 0, 'Chronomancer Unmake Rank 5'),
(503788, 0, 0.12, 0, 0, 'Chronomancer Unmake Rank 6'),
(503789, 0, 0.12, 0, 0, 'Chronomancer Unmake Rank 7'),
(503790, 0, 0.12, 0, 0, 'Chronomancer Unmake Rank 8'),
(504574, 0, 0.12, 0, 0, 'Chronomancer Unmake Rank 9'),
(574344, 0, 0.12, 0, 0, 'Chronomancer Unmake Rank 10'),
(574345, 0, 0.12, 0, 0, 'Chronomancer Unmake Rank 11');
