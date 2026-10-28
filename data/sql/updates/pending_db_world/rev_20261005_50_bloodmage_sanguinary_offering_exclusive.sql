-- Bloodmage: Sanguinary Offering and Greater Sanguinary Offering are one buff, not two.
--
-- Sanguinary Offering is a single-target stamina buff in trained ranks (chain first spell 706630,
-- ranks 706630-707339, plus Rank 6 707340 which has no spell_ranks row of its own), and Greater
-- Sanguinary Offering 680299 is the raid-wide form that grants the same buff to every ally in
-- reach. All of them are spell family 26, effect 0 SPELL_EFFECT_APPLY_AURA with aura 29 (MOD_STAT),
-- MiscValue 2 (stamina) and DurationIndex 30, and nothing expressed that they are the same buff, so
-- a target that received both the single-target and the raid-wide version held both auras and their
-- stamina stacked. #6448 reports exactly that at level 60.
--
-- One spell_group with SPELL_GROUP_STACK_RULE_EXCLUSIVE_HIGHEST (4), the rule the core's stock buffs
-- use and the Ranger Adaptations (2100002/2100003) already use for the same single-target + Greater
-- shape: Aura::CanStackWith refuses any two members regardless of caster, and
-- Unit::IsHighestExclusiveAuraEffect refuses a weaker cast while an equal or stronger one is already
-- on the target, so a Rank 1 offering (706630: 8 stamina) cannot replace an ally's Greater buff
-- (680299: 54). An equal or stronger cast replaces the weaker one, and the raid-wide cast does the
-- same on every target it reaches. SpellMgr resolves group lookups through the first rank of a
-- chain, so 706630 covers 707336-707339; 707340 carries no chain row and is listed as itself.
DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 2100004;
DELETE FROM `spell_group` WHERE `id` = 2100004;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(2100004, 706630), -- Sanguinary Offering (Rank 1, first in chain; covers 707336-707339)
(2100004, 707340), -- Sanguinary Offering (Rank 6, no spell_ranks row)
(2100004, 680299); -- Greater Sanguinary Offering
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`) VALUES (2100004, 4);
