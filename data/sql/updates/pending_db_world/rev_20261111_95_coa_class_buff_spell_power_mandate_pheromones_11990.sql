-- COA-11990: Grim Mandate (Necromancer), Toxic Pheromones (Venomancer) and Mark of Blaumeux (Knight of Xoroth) also
-- grant spell power, but rev_20261025_67 left them out of the spell power category 2110012, so they stacked with
-- Witching Edict, Whispers of C'thun, Devotion of Radiance and each other. The newest spell power buff now replaces
-- the previous one.
-- Toxic Pheromones 707689 and Greater Toxic Pheromones 712459 also share group 1138 (one Pheromone per caster), which
-- sorts first, so two Venomancers' Toxic and Greater Toxic still stacked. Group 1116 makes that pair exclusive across
-- casters, like Witching Edict's group 1041.
DELETE FROM `spell_group` WHERE `id` = 2110012 AND `spell_id` IN (572787, 572790, 707689, 712459, 707693, 712460);
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(2110012, 572787),
(2110012, 572790),
(2110012, 707689),
(2110012, 712459),
(2110012, 707693),
(2110012, 712460);

DELETE FROM `spell_group` WHERE `id` = 1116;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(1116, 707689),
(1116, 712459);

DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 1116;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(1116, 1, 'Local CoA: Toxic Pheromones and Greater Toxic Pheromones');
