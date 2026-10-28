-- Seismic Wave (#5048): every rank's tooltip promises a heal of $m1 + $BH*.6 + $AP*.28 and damage of
-- $m2 + $BH*.3 + $AP*.28, but no rank had a spell_bonus_data row and the Spell.dbc coefficients are 0, so both
-- effects dealt only their base points. GetSpellBonusData falls back to rank 1, so one row covers all seven ranks.
-- The row holds one spell power coefficient for both effects: the damage's 0.3. The heal's other 0.3 is added by
-- spell_ascension_seismic_wave.
START TRANSACTION;
DELETE FROM `spell_bonus_data` WHERE `entry` = 805462;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(805462, 0.3, 0, 0.28, 0, 'Seismic Wave: heal gets another 0.3 SP from its script');
DELETE FROM `spell_script_names` WHERE `spell_id` = -805462 AND `ScriptName` = 'spell_ascension_seismic_wave';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (-805462, 'spell_ascension_seismic_wave');
COMMIT;
