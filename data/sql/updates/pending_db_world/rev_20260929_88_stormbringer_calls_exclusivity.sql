-- #5498 Call of the Storm and Call of the Wind stack together
--
-- Call of the Storm base 578311 (ranks 578312/578313/578314/578315, AscensionSpellProgressionData.h) and
-- Call of the Wind base 804018 (ranks 503319/503320/503321/503322/503323) each tooltip "Does not stack with
-- |cffffffffCall of the {Wind|Storm}|r.." PR #4952 (data/sql/updates/pending_db_world/
-- rev_1790205511509246133.sql, spell_group 111010) already made the Aegis family exclusive and its own
-- description explicitly scopes Calls out ("a Call and an Aegis can still coexist"); no spell_group row
-- exists for either Call family (grep across data/sql/updates finds none), so a Call of the Storm and a Call
-- of the Wind still stack, matching the report's "call of wind and call of storm" clause. The Greater raid
-- variants (578316, 680291) are not included: their own Spell.dbc description carries no "Does not stack"
-- clause, so they are out of this issue's scope.
START TRANSACTION;

DELETE FROM `spell_group` WHERE `id` = 1171;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(1171, 578311),
(1171, 578312),
(1171, 578313),
(1171, 578314),
(1171, 578315),
(1171, 804018),
(1171, 503319),
(1171, 503320),
(1171, 503321),
(1171, 503322),
(1171, 503323);

DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 1171;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(1171, 2, 'Local CoA: one Stormbringer Call (of the Storm or Wind) per caster on each recipient');

COMMIT;
