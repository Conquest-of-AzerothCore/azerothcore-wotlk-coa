DELETE FROM `spell_group` WHERE `id` = 111010;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(111010, 680282),
(111010, 680316),
(111010, 680334);

DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 111010;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(111010, 2, 'Stormbringer Aegis - exclusive from same caster');
