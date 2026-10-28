-- Foul Mandate and Grim Mandate share no spell_group, so one Necromancer could keep both on the same target.
-- Ascension combat logs from 2026-08 show a Necromancer's new Mandate removing that Necromancer's previous one
-- (37 swaps, none kept both), while Mandates from two Necromancers stayed together on one target.
-- Stack rule 2 (exclusive from the same caster) keeps one Mandate per Necromancer. The id sorts above 2106086,
-- 2106087 and 2110002, so their existing rank rules still apply. 800199 and 572787 are the first ranks of their chains.
START TRANSACTION;
DELETE FROM `spell_group` WHERE `id` = 2110011;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(2110011, 800199),
(2110011, 680286),
(2110011, 572787),
(2110011, 572790);

DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 2110011;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(2110011, 2, 'Necromancer Mandates: one Mandate per Necromancer on each target (#4136, #6046)');
COMMIT;
