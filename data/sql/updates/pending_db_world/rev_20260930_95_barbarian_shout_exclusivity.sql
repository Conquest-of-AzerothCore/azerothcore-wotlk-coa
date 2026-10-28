START TRANSACTION;
DELETE FROM `spell_group` WHERE `id` = 1210;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(1210, 300857),
(1210, 300882),
(1210, 300883),
(1210, 300884),
(1210, 300885),
(1210, 300886),
(1210, 680302),
(1210, 681439),
(1210, 681440),
(1210, 681441);
DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 1210;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(1210, 2, 'Local CoA: one Barbarian shout (Brutal or Enduring) per caster on each recipient');
COMMIT;
