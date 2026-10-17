-- The ten Tithe auras are separate spells, so every one a Templar casts stayed on the party next to the others (#7857).
-- A group with SPELL_GROUP_STACK_RULE_EXCLUSIVE_FROM_SAME_CASTER (2) keeps one Tithe per Templar, while Tithes from
-- different Templars still stack; the id sorts above every existing group.
START TRANSACTION;
DELETE FROM `spell_group` WHERE `id` = 2110009;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(2110009, 804782),
(2110009, 804783),
(2110009, 804784),
(2110009, 804815),
(2110009, 804816),
(2110009, 804817),
(2110009, 804818),
(2110009, 804819),
(2110009, 804820),
(2110009, 804821);

DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 2110009;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(2110009, 2, 'Templar Tithe auras: one Tithe per Templar on each target (#7857)');
COMMIT;
