-- Venomancer (#4264): a Venomancer keeps only one Pheromone on each recipient. Members are the first rank of
-- Spider (803177), Beetle (803651) and Toxic (707689) Pheromones plus the unranked Greater variants
-- (680312, 803657, 712459); rank chains resolve through spell_ranks.
START TRANSACTION;
DELETE FROM `spell_group` WHERE `id` = 1138;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(1138, 803177),
(1138, 803651),
(1138, 707689),
(1138, 680312),
(1138, 803657),
(1138, 712459);
DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 1138;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(1138, 2, 'Local CoA: one Venomancer Pheromone per caster on each recipient');
COMMIT;
