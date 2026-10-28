-- COA-7106: the CoA class buffs that grant spell power stacked on one target, because rev_20261009_50 gave them no
-- shared category. Add one, like the Agility, Stamina and Attack power categories (2110001-2110006): the newest
-- spell power buff replaces the previous one whoever cast it (SPELL_GROUP_STACK_RULE_EXCLUSIVE).
-- First ranks cover their chains: 707684 -> 707685-707687, 572791 -> 572819-572905, 575040 -> 575041-575044.
-- The id sorts above every class group, so the rules within a class stay as they are.
DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 2110012;
DELETE FROM `spell_group` WHERE `id` = 2110012;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
-- Spell power: Witching Edict, Whispers of C'thun, Devotion of Radiance
(2110012, 707684),
(2110012, 681442),
(2110012, 572791),
(2110012, 573067),
(2110012, 575040),
(2110012, 575045);
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(2110012, 1, 'CoA class buffs: spell power');
