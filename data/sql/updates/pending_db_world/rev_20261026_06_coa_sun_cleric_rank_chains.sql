-- Daybreak rank 6 and Devotion of Radiance rank 5 (#9159): the trainer sells both, and the client's SpellRank.dbc
-- chains them after the previous rank (Daybreak 500147 rank 6 = 572035, Devotion of Radiance 575040 rank 5 =
-- 575044), but rev_20260903_01_live_class_baseline stopped each chain one rank short, so the server treated the
-- top rank as an unrelated spell.
DELETE FROM `spell_ranks` WHERE `spell_id` IN (572035, 575044);
INSERT INTO `spell_ranks` (`first_spell_id`, `spell_id`, `rank`) VALUES
(500147, 572035, 6),
(575040, 575044, 5);
