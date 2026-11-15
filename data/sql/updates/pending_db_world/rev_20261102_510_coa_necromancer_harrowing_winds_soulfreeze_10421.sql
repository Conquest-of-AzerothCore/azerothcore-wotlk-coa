-- Soulfreeze (#10421): "All Frost damage you deal to Frozen targets" includes Harrowing Winds 707575, which is a
-- triggered splash without SPELL_ATTR3_NOT_A_PROC and so cannot proc auras; its hit rolls Soulfreeze directly.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_ascension_necromancer_harrowing_winds';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(707575, 'spell_ascension_necromancer_harrowing_winds');
