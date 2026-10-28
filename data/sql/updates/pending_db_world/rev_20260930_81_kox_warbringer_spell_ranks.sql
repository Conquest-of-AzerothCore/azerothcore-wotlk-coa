-- Warbringer ranks 802582-802586 were never chained to root 802581 in spell_ranks (Spell.dbc names all six
-- "Warbringer"), so GetFirstSpellInChain left ranks 2-6 outside the Knight of Xoroth Demonfire scripts (#5274, #5501).
DELETE FROM `spell_ranks` WHERE `first_spell_id` = 802581;
INSERT INTO `spell_ranks` (`first_spell_id`, `spell_id`, `rank`) VALUES
(802581, 802581, 1),
(802581, 802582, 2),
(802581, 802583, 3),
(802581, 802584, 4),
(802581, 802585, 5),
(802581, 802586, 6);
