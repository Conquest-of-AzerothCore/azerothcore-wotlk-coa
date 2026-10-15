-- Sea Serpent Form (803212) lacks SPELL_AURA_MOD_SHAPESHIFT (aura 36), unlike every other Venomancer
-- form -- Spider Form (800841), Beetle Form (803183), Weaver Form (804980), Venomwing Form (520307)
-- and Vizier Form (800912) each carry aura 36, so AzerothCore's native shapeshift handling already
-- keeps those five mutually exclusive. Sea Serpent Form is invisible to that mechanism in both
-- directions and can be held together with any of the other five (#5427).
--
-- One spell_group with SPELL_GROUP_STACK_RULE_EXCLUSIVE (1) covers all six: entering any one of them
-- removes whichever of the other five is active, the same precedent used for Reaper Rites
-- (rev_20260916_61_rite_buffs_exclusive.sql). None of the six has a rank chain (data/sql spell_ranks
-- has no row for any of them), so each is listed as itself.
DELETE FROM `spell_group` WHERE `id` = 1153;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(1153, 800841), -- Spider Form
(1153, 803183), -- Beetle Form
(1153, 804980), -- Weaver Form
(1153, 520307), -- Venomwing Form
(1153, 800912), -- Vizier Form
(1153, 803212); -- Sea Serpent Form

DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 1153;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`) VALUES (1153, 1);
