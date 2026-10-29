-- Running Wild 800175 transforms into creature 56332 (male worgen display 574); give female Bloodmages the female worgen display.
DELETE FROM `spell_script_names` WHERE `spell_id` = 800175 AND `ScriptName` = 'aura_ascension_bloodmage_female_worgen';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(800175, 'aura_ascension_bloodmage_female_worgen');
