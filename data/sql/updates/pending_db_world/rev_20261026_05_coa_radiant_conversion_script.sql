-- Radiant Conversion (807453, #9014): while Dawn is active the Dawn button becomes Radiant Conversion, which consumes
-- Dawn's remaining charges and refunds 1 Solar Power for each. Its only effect is a script effect, handled by the
-- Sun Cleric ability script.
DELETE FROM `spell_script_names` WHERE `spell_id` = 807453 AND `ScriptName` = 'spell_ascension_sun_cleric_ability';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (807453, 'spell_ascension_sun_cleric_ability');
