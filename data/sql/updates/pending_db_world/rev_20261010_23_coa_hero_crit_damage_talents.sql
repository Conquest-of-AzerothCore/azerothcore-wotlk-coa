-- Ascension's critical damage talents each read "Your spell critical strikes now deal 180% damage. This does not stack
-- with other similar effects." (SPELL_AURA_MOD_CRIT_DAMAGE_BONUS, all schools), but a Hero holding several summed them
-- (#7028). One same-effect group: only the highest of their crit damage bonuses counts. Talent.dbc first ranks: Ice
-- Shards, Holy Focus, Elemental Fury, Vengeance, Ruin, Runic Focus, Shadow Power, Predatory Instincts, Spell Power,
-- Burnout.
DELETE FROM `spell_group` WHERE `id` = 2106089;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(2106089, 11207),
(2106089, 14889),
(2106089, 16089),
(2106089, 16909),
(2106089, 17959),
(2106089, 33221),
(2106089, 33859),
(2106089, 35578),
(2106089, 44449),
(2106089, 61758);

DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 2106089;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(2106089, 3, 'Critical damage talents: only the highest bonus counts');
