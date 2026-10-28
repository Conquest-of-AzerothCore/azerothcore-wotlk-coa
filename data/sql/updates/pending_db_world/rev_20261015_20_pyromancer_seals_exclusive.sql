-- Seal of Alysrazor (800196 chain) and Seal of Al'ar (803649 chain) had no shared stack rule, so one Pyromancer
-- could keep both seals on the same target (#7705). A group with SPELL_GROUP_STACK_RULE_EXCLUSIVE_FROM_SAME_CASTER
-- (2) keeps one seal per Pyromancer on each target, as with a Paladin's blessings; stack rules read the first rank.
DELETE FROM `spell_group` WHERE `id` = 2110008;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(2110008, 800196),
(2110008, 803649);

DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 2110008;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(2110008, 2, 'Pyromancer seals: one seal per Pyromancer on each target');
