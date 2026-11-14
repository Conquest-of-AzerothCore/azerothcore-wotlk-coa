-- Straight to the Heart (Normal 20016, Heroic 20017, Mythic 20018, Ascended 20019): criteria 12004-12007 are
-- BE_SPELL_TARGET of 2107157-2107160, one spell per difficulty, which AzerothCore counts only when
-- achievement_criteria_data holds a row for them. Hakkar's script credits the spell of the instance difficulty.
DELETE FROM `achievement_criteria_data` WHERE `criteria_id` IN (12004, 12005, 12006, 12007);
INSERT INTO `achievement_criteria_data` (`criteria_id`, `type`, `value1`, `value2`, `ScriptName`) VALUES
(12004, 0, 0, 0, ''),
(12005, 0, 0, 0, ''),
(12006, 0, 0, 0, ''),
(12007, 0, 0, 0, '');
