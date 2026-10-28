-- Continuum spells (#5021): Singularity Core 804438, Paradox Cannon 806203, Flux Emitter 804435 and
-- Aether Compression 804436 all end their own Description[enUS] with the identical line "Can only have
-- 1 |cFFC49A6CContinuum|r spell active at a time." No spell_group row existed for any of the four, so
-- all four could be active on the same caster simultaneously. Each is its own rank-1 CharacterAdvancement
-- entry (7854/6174/30856/7855), so none is rejected by LoadSpellGroups' first-rank requirement.
-- SPELL_GROUP_STACK_RULE_EXCLUSIVE_FROM_SAME_CASTER (2) matches the "at a time" wording exactly: the
-- same caster's new Continuum cast replaces their own previous one, mirroring the existing
-- one-active-per-caster self-buff policy (rev_20260907_02_exclusive_self_buffs.sql, groups 1128-1132).
START TRANSACTION;
DELETE FROM `spell_group` WHERE `id` = 1152;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(1152, 804438),
(1152, 806203),
(1152, 804435),
(1152, 804436);
DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 1152;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(1152, 2, 'Local Chronomancer: one active Continuum spell per caster');
COMMIT;
