-- Footpad's Adaptation (523489 chain) and Woodsman's Adaptation (800266 chain) are different chains with no
-- shared stack rule, so one Ranger could keep both single-target Adaptations on the same target (#6113). On
-- Ascension the later single-target Adaptation from the same Ranger removes the earlier one, while other Rangers'
-- Adaptations and the Greater versions stay. A group with SPELL_GROUP_STACK_RULE_EXCLUSIVE_FROM_SAME_CASTER (2)
-- keeps one single-target Adaptation per Ranger on each target; stack rules read the first rank.
DELETE FROM `spell_group` WHERE `id` = 2110010;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(2110010, 523489),
(2110010, 800266);

DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 2110010;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(2110010, 2, 'Ranger Adaptations: one single-target Adaptation per Ranger on each target (#6113)');
