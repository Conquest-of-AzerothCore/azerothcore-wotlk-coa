-- Rite group 2100001 (Perseverance, Power, Resolve, plus each Greater form) was
-- published with SPELL_GROUP_STACK_RULE_EXCLUSIVE (1), so any Rite replaced any
-- other Rite on the target no matter who cast it: a Reaper's own Rite of Power
-- overwrote a bot's Rite of Resolve (#7733). The three Rites are three different
-- stats, not one buff: Perseverance is resistances (aura 143, MiscValue 126),
-- Power is Strength (aura 29, MiscValue 0) and Resolve is Stamina (aura 29,
-- MiscValue 2). Blessings are the model here: each stat family is its own
-- exclusive group, so Str, Stam and resist coexist while single-target and
-- Greater forms of the same stat stay exclusive.
-- Publish SPELL_GROUP_STACK_RULE_EXCLUSIVE_HIGHEST (4) per family, the rule the
-- core's stock buffs use and the Ranger Adaptations (2100002/2100003) and
-- Sanguinary Offering (2100004) already use for the same single-target +
-- Greater shape: Aura::CanStackWith refuses any two members regardless of
-- caster, and a weaker rank cannot replace a stronger one already on the
-- target. SpellMgr resolves lookups through the first rank of each chain, so
-- 575839 covers 575840-575841, 578126 covers 578127-578129 and 800198 covers
-- 803310-803314; the three Greater Rites have no chain and are listed as
-- themselves. No code changes are needed.
DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 2100001;
DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 2100005;
DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 2100006;
DELETE FROM `spell_group` WHERE `id` = 2100001;
DELETE FROM `spell_group` WHERE `id` = 2100005;
DELETE FROM `spell_group` WHERE `id` = 2100006;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(2100001, 575839), -- Rite of Perseverance (Rank 1, first in chain)
(2100001, 575842), -- Greater Rite of Perseverance
(2100005, 578126), -- Rite of Power (Rank 1, first in chain)
(2100005, 578130), -- Greater Rite of Power
(2100006, 800198), -- Rite of Resolve (Rank 1, first in chain)
(2100006, 680298); -- Greater Rite of Resolve
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`) VALUES
(2100001, 4),
(2100005, 4),
(2100006, 4);
