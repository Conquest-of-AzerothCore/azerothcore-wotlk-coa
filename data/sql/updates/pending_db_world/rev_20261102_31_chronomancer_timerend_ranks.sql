-- Timerend ranks 2-7 chain to Rank 1 (801291) so effects naming Rank 1 reach the rank the player owns.
DELETE FROM `spell_ranks` WHERE `first_spell_id` = 801291;
DELETE FROM `spell_ranks` WHERE `spell_id` IN (801291, 501831, 501832, 501833, 501834, 501835, 572578);
INSERT INTO `spell_ranks` (`first_spell_id`, `spell_id`, `rank`) VALUES
(801291, 801291, 1),
(801291, 501831, 2),
(801291, 501832, 3),
(801291, 501833, 4),
(801291, 501834, 5),
(801291, 501835, 6),
(801291, 572578, 7);
