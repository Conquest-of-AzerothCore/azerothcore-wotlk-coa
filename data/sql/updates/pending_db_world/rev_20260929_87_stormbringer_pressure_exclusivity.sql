-- #5218 (stacking half), #4891, #4422 Pressure auras lack exclusivity
--
-- Barometric Pressure (803563), Crushing Pressure (803564) and Atmospheric Pressure (803565) each carry
-- DurationIndex 21 (SpellDuration.dbc -1 ms, permanent by design) and each tooltip ends "Only 1 |cffffffff
-- Pressure|r spell can be active at a time.." Spell.dbc/coa-dbc-viewer map confirms each is a single-rank
-- SkillLineAbility with no rank chain. No `spell_group` row exists for any of the three (grep across
-- data/sql/updates finds none), so nothing stops Crushing and Barometric coexisting (#4891, #5218's stacking
-- clause) and a fresh Pressure cast never replaces an already-active one, which looks unremovable/permanent
-- to the reporter (#4422 - the -1 duration itself is correct and unchanged). Same shape as PR #4952's Aegis
-- fix (data/sql/updates/pending_db_world/rev_1790205511509246133.sql, spell_group 111010). Companion child
-- auras (e.g. Barometric's 803566 slow) are not included: they are removed by their own AuraScript::OnRemove
-- when the parent aura they are bound to is removed, so exclusivity on the three parent ids is sufficient.
START TRANSACTION;

DELETE FROM `spell_group` WHERE `id` = 1170;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(1170, 803563),
(1170, 803564),
(1170, 803565);

DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 1170;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(1170, 2, 'Local CoA: one Stormbringer Pressure aura per caster on each recipient');

COMMIT;
