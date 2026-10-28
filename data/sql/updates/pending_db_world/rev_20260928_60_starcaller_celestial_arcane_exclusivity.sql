START TRANSACTION;
DELETE FROM `spell_group` WHERE `id` = 1150;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(1150, 300255),
(1150, 680301);
DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 1150;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(1150, 2, 'Local CoA: one Celestial Mind per caster on each recipient');
DELETE FROM `spell_group` WHERE `id` = 1151;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(1151, 573343),
(1151, 573348);
DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 1151;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(1151, 2, 'Local CoA: one Arcane Protection per caster on each recipient');
COMMIT;
