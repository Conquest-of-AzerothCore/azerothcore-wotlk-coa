-- Reborn Dark Fixation (1118778, 1118779) effect 2: Life Tap's self-inflicted damage, at the rank's percent, becomes
-- the Dark Fixation absorb shield (1118780).
DELETE FROM `spell_script_names` WHERE `spell_id` IN (1118778, 1118779) AND `ScriptName` = 'spell_ascension_reborn_dark_fixation';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1118778, 'spell_ascension_reborn_dark_fixation'),
(1118779, 'spell_ascension_reborn_dark_fixation');
