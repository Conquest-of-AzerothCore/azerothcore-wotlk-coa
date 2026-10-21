-- Houndmaster's Whistle (#7443): a dead Shadowhound came back at full health when whistled; it now refuses with
-- "Your pet is dead", leaving Call From The Shadows to bring the hound back.
DELETE FROM `spell_script_names` WHERE `spell_id` = 801343 AND `ScriptName` = 'spell_ascension_witch_hunter_whistle';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (801343, 'spell_ascension_witch_hunter_whistle');
