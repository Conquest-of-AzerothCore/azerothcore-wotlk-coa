-- Warcraft Reborn Feral Swiftness: the talent ranks (and the crossover Mystic Enchant) are dummies; the forms cast their
-- speed (Cat Form) and dodge passives (spell_ascension_reborn_feral_swiftness).
DELETE FROM `spell_script_names` WHERE `spell_id` IN (1100768, 1105487, 1109634) AND `ScriptName` = 'spell_ascension_reborn_feral_swiftness';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1100768, 'spell_ascension_reborn_feral_swiftness'),
(1105487, 'spell_ascension_reborn_feral_swiftness'),
(1109634, 'spell_ascension_reborn_feral_swiftness');
