-- Necromancer ordinary and Greater Foul/Grim Mandates and Razorice grant matching effects.
-- Retain one strongest version of each additive buff per target, regardless of caster.
-- First-rank rows cover every trained rank through spell_ranks.
-- Chill of the Tomb already uses exclusive resistance (aura 143) and needs no group.
DELETE FROM `spell_group` WHERE `id` IN (2106086, 2106087, 2106088);
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(2106086, 800199),
(2106086, 680286),
(2106087, 572787),
(2106087, 572790),
(2106088, 500967),
(2106088, 572214);
DELETE FROM `spell_group_stack_rules` WHERE `group_id` IN (2106086, 2106087, 2106088);
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`) VALUES
(2106086, 4),
(2106087, 4),
(2106088, 4);
