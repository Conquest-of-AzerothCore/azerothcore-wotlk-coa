-- Lightbringer 561277 and Norgannon's Wrath's blast 524740: the target counts among the stated enemies.
START TRANSACTION;
DELETE FROM `spell_script_names`
WHERE `spell_id` IN (561277, 524740) AND `ScriptName` = 'spell_ascension_templar_ability';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(561277, 'spell_ascension_templar_ability'),
(524740, 'spell_ascension_templar_ability');
COMMIT;
