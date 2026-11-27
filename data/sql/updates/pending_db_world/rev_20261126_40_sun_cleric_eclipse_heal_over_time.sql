-- Vow of the Eclipse 807435: effective healing applies the friendly periodic heal 505370 (807437 effect 0). The
-- lifecycle script keeps its accumulated amount from being recalculated, as it does for the burn 505340.
DELETE FROM `spell_script_names` WHERE `spell_id` = 505370 AND `ScriptName` = 'aura_ascension_sun_cleric_lifecycle';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (505370, 'aura_ascension_sun_cleric_lifecycle');
