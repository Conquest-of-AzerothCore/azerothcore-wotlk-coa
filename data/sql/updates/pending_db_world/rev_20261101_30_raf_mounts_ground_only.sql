-- Blazing Hippogryph (74856) and X-53 Touring Rocket (75973), both Recruit a Friend mount wrappers, are ground
-- mounts (#10460). They had no spell_script_names row for spell_ascension_local_mount, and the generic
-- spell_gen_mount bindings (spell_blazing_hippogryph, spell_x53_touring_rocket) cancel the mount that script
-- applies. SpellInfoCorrections turns their client mount spells into ground spells, so the client keeps their icons.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (74856, 75973)
AND `ScriptName` IN ('spell_ascension_local_mount', 'spell_blazing_hippogryph', 'spell_x53_touring_rocket');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(74856, 'spell_ascension_local_mount'),
(75973, 'spell_ascension_local_mount');

UPDATE `item_template` SET `RequiredLevel` = 1, `RequiredSkill` = 0, `RequiredSkillRank` = 0
WHERE `entry` IN (54069, 54860);
