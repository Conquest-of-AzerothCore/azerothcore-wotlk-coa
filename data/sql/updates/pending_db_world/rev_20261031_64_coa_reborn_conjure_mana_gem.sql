-- Reborn Conjure Mana Gem (1100759, 1103552, 1110053, 1110054, 1127101, 1142985) is a script effect naming its
-- Mana Agate item, where stock creates the item directly; with no script it created nothing.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (1100759, 1103552, 1110053, 1110054, 1127101, 1142985) AND `ScriptName` = 'spell_ascension_reborn_conjure_mana_gem';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1100759, 'spell_ascension_reborn_conjure_mana_gem'),
(1103552, 'spell_ascension_reborn_conjure_mana_gem'),
(1110053, 'spell_ascension_reborn_conjure_mana_gem'),
(1110054, 'spell_ascension_reborn_conjure_mana_gem'),
(1127101, 'spell_ascension_reborn_conjure_mana_gem'),
(1142985, 'spell_ascension_reborn_conjure_mana_gem');
