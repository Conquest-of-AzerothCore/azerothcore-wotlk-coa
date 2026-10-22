-- Animal Spirit Visual Aura (#5309): Wildwalker's tamed beasts wear the spectral look; the aura applies to beasts only.
DELETE FROM `spell_script_names` WHERE `spell_id` = 574306 AND `ScriptName` = 'aura_ascension_primalist_animal_spirit_visual';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (574306, 'aura_ascension_primalist_animal_spirit_visual');
