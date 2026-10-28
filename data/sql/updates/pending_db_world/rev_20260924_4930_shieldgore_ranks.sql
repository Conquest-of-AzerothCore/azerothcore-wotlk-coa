-- Shieldgore ranks 2-7 need a chain to Rank 1 (804353) so Knight of Xoroth scripts recognize every rank.
DELETE FROM `spell_ranks` WHERE `first_spell_id` = 804353;
INSERT INTO `spell_ranks` (`first_spell_id`, `spell_id`, `rank`) VALUES
(804353, 804353, 1),
(804353, 806869, 2),
(804353, 806870, 3),
(804353, 806871, 4),
(804353, 806872, 5),
(804353, 806873, 6),
(804353, 806874, 7);
