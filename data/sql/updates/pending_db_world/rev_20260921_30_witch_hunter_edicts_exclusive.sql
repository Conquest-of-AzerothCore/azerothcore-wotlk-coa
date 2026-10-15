-- Witch Hunter Edicts: one Edict per caster on each recipient. The normal and Greater versions of Knight's,
-- Inquisitor's and Witching Edict were separate spells with different auras and so all stacked.
DELETE FROM `spell_group` WHERE `id` = 1138;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(1138, 523485),
(1138, 706741),
(1138, 707684),
(1138, 523510),
(1138, 680303),
(1138, 681442);
DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 1138;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(1138, 2, 'Local CoA: one Witch Hunter Edict per caster on each recipient');
