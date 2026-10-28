-- Reaper Rites (#7733):
-- * one Rite per Reaper on each target: a Reaper's new Rite replaces that Reaper's previous Rite
--   (group 2100007, SPELL_GROUP_STACK_RULE_EXCLUSIVE_FROM_SAME_CASTER);
-- * one Rite of each stat on a target whoever cast it: the stronger one stays, and an equal one
--   cast later replaces the earlier (groups 2100001/2100005/2100006,
--   SPELL_GROUP_STACK_RULE_EXCLUSIVE_HIGHEST).
-- SpellMgr returns the rule of the lowest shared group id, so the per-stat groups keep the lower
-- ids. First ranks cover their chains: 575839 -> 575840-575841, 578126 -> 578127-578129,
-- 800198 -> 803310-803314; the Greater Rites have no chain.
DELETE FROM `spell_group_stack_rules` WHERE `group_id` IN (2100001, 2100005, 2100006, 2100007);
DELETE FROM `spell_group` WHERE `id` IN (2100001, 2100005, 2100006, 2100007);
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(2100001, 575839),
(2100001, 575842),
(2100005, 578126),
(2100005, 578130),
(2100006, 800198),
(2100006, 680298),
(2100007, 575839),
(2100007, 575842),
(2100007, 578126),
(2100007, 578130),
(2100007, 800198),
(2100007, 680298);
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(2100001, 4, 'Rite of Perseverance: one per target, strongest stays (#7733)'),
(2100005, 4, 'Rite of Power: one per target, strongest stays (#7733)'),
(2100006, 4, 'Rite of Resolve: one per target, strongest stays (#7733)'),
(2100007, 2, 'Reaper Rites: one Rite per Reaper on each target (#7733)');
