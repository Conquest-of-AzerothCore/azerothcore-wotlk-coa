-- Transfer Life 801530 (#1442) channels only into the caster's Raised minions, as its tooltip states.
DELETE FROM `spell_script_names`
WHERE `spell_id` = 801530 AND `ScriptName` = 'spell_ascension_necromancer_transfer_life';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`)
VALUES (801530, 'spell_ascension_necromancer_transfer_life');
