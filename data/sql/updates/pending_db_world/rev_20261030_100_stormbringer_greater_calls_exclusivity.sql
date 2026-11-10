-- #10238 Call of the Storm and Greater Call of the Storm are both active
--
-- Greater Call of the Storm (578316) is the raid-wide form of Call of the Storm: the same
-- SPELL_AURA_MOD_STAT Intellect aura, the same 30-minute duration and the same magnitude as rank 5
-- (578315, AscensionSpellProgressionData.h: { 16, 578311, 578315, 56 }), only with
-- TARGET_UNIT_CASTER_AREA_RAID in place of TARGET_UNIT_TARGET_ALLY. Greater Call of the Wind (680291)
-- mirrors that relation for Call of the Wind rank 6 (503323), and neither Greater spell is in a
-- spell_ranks chain, so GetFirstRankSpell resolves each to itself. spell_group 1171
-- (rev_20260929_88_stormbringer_calls_exclusivity.sql, PR #5640) already makes one Call exclusive from
-- the same caster but left both Greater variants out because their Spell.dbc descriptions carry no
-- "Does not stack" clause, so a Call and its Greater form still stack on the same recipient and apply
-- the same buff twice. Same shape as the Illidari Intuition pair (group 1154): a Greater stat buff is
-- the same family as its normal form, not an additional buff. Templar raid versions (group 1160) are
-- grouped with their normal grants for the same reason. Adding both Greater variants keeps one
-- Stormbringer Call per caster on each recipient.
START TRANSACTION;

DELETE FROM `spell_group` WHERE `id` = 1171;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(1171, 578311),
(1171, 578312),
(1171, 578313),
(1171, 578314),
(1171, 578315),
(1171, 578316),
(1171, 804018),
(1171, 503319),
(1171, 503320),
(1171, 503321),
(1171, 503322),
(1171, 503323),
(1171, 680291);

DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 1171;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(1171, 2, 'Local CoA: one Stormbringer Call (of the Storm or Wind, including the Greater raid forms) per caster on each recipient');

COMMIT;
