-- #481 Wingman (705098): bind the damage-taken reduction that scales with active War Falcons and Dragonhawks.
DELETE FROM `spell_script_names` WHERE `spell_id` = 705098 AND `ScriptName` = 'aura_ascension_ranger_wingman';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(705098, 'aura_ascension_ranger_wingman');
