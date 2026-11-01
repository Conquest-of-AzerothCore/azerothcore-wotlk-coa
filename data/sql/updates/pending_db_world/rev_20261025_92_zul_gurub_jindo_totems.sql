-- Zul'Gurub: Jin'do's Powerful Healing Ward casts Ascension's Healing Stream (2118504) from his script instead of
-- its stock heal, so it gets a passive AI; the stream heals a share of his missing health every second.
UPDATE `creature_template` SET `AIName` = 'NullCreatureAI', `ScriptName` = '' WHERE `entry` = 14987;

DELETE FROM `spell_script_names` WHERE `spell_id` = 2118504 AND `ScriptName` = 'spell_jindo_coa_healing_stream';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2118504, 'spell_jindo_coa_healing_stream');
