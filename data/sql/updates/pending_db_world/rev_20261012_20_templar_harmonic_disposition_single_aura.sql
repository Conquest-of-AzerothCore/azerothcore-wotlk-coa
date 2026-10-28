-- Harmonic Disposition (560653) carries a periodic dummy effect, and Aura::CanStackWith lets periodic auras from
-- different casters stack. Two Templars in one party therefore gave every member one copy per Templar (#7331).
-- A one-spell group with SPELL_GROUP_STACK_RULE_EXCLUSIVE (1) keeps a single copy on each unit; the id sorts above
-- every existing group.
DELETE FROM `spell_group` WHERE `id` = 2110007;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(2110007, 560653);

DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 2110007;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(2110007, 1, 'Templar Harmonic Disposition: one aura per target whoever casts it');
