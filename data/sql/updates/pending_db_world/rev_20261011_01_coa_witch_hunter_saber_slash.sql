-- Issue #7194: Saber Slash (Fire) 680230 is the Inquisition melee generator, but nothing attached
-- the Witch Hunter ability script to it, so its hits never reached the damage-to-rage conversion.
-- Bind it the same way as the other Witch Hunter abilities.
DELETE FROM `spell_script_names` WHERE `spell_id` = 680230 AND `ScriptName` = 'spell_ascension_witch_hunter_ability';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (680230, 'spell_ascension_witch_hunter_ability');
