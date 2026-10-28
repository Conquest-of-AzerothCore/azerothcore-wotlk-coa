-- Illidari Intuition (800212) and Greater Illidari Intuition (680308) both apply SPELL_AURA_MOD_STAT/agility
-- directly to their target (not through a shared party-buff-slot aura id), so nothing native stops both being
-- active on the same target at once. spell_group 1078 already groups the differently themed Man'ari Intuition
-- pair (523478, 523495); this pair has no exclusivity entry at all. Group id 1154 confirmed free of 1140-1142
-- (taken by concurrent Starcaller/Chronomancer branches) at authoring time.
START TRANSACTION;
DELETE FROM `spell_group` WHERE `id` = 1154 AND `spell_id` IN (800212, 680308);
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(1154, 800212),
(1154, 680308);
DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 1154;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(1154, 2, 'Local CoA: one Illidari Intuition per caster on each recipient');
COMMIT;
