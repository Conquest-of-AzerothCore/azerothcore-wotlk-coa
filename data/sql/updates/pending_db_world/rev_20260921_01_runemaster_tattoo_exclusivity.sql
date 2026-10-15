-- Runic Tattoos are alternative self buffs (#4424, #4444).
-- SkillLineAbility.dbc links these trainer-taught rank 6 spells to the existing chains.
-- Complete the chains so both rank supersession and the first-rank group lookup cover them.
DELETE FROM `spell_ranks` WHERE `spell_id` IN (803753, 803763, 807839);
INSERT INTO `spell_ranks` (`first_spell_id`, `spell_id`, `rank`) VALUES
(801106, 803753, 6), -- Fire
(803748, 803763, 6), -- Arcane
(807834, 807839, 6); -- Frost

-- Only the castable tattoos belong here, not their triggered helpers or similarly named passives.
-- The core resolves higher ranks to these roots; Air has no ranks.
DELETE FROM `spell_group` WHERE `id` = 111001;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(111001, 801094), -- Earth
(111001, 801106), -- Fire
(111001, 801107), -- Water
(111001, 802630), -- Air
(111001, 803748), -- Arcane
(111001, 807834); -- Frost

DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 111001;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(111001, 1, 'Runemaster: one active Runic Tattoo');
