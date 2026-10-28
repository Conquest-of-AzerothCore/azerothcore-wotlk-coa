DELETE FROM `spell_group` WHERE `id` = 2104883;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(2104883, 803649),
(2104883, 808060);

DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 2104883;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`) VALUES
(2104883, 4);
