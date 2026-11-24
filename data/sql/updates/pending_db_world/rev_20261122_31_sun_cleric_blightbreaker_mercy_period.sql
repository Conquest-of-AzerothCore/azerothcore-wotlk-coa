-- Mercy 504848: with Blightbreaker 707433, a +50% tick rate gives two thirds of its DBC period (owner ruling O-24).
DELETE FROM `spell_script_names` WHERE `spell_id` = 504848 AND `ScriptName` = 'aura_ascension_sun_cleric_mercy';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (504848, 'aura_ascension_sun_cleric_mercy');
