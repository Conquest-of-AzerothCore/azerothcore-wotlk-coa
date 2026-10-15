-- Worrysome Idol (706917) periodically triggers 504829 ("Energize 10% Missing Mana"), whose default
-- ENERGIZE_PCT handler restores 10% of maximum mana unconditionally. The tooltip promises 10% of missing
-- mana instead. 504829 is shared with Star-Charged (500756, non-Cultist), so the script gates on the
-- Cultist class and leaves Star-Charged on the default handler.
DELETE FROM `spell_script_names` WHERE `spell_id` = 504829 AND `ScriptName` = 'spell_ascension_cultist_worrysome_idol';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (504829, 'spell_ascension_cultist_worrysome_idol');
