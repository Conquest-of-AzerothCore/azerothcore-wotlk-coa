START TRANSACTION;
DELETE FROM `spell_script_names` WHERE `spell_id` = 270804 AND `ScriptName` = 'spell_ascension_mystic_enchant_proc';
DELETE FROM `spell_proc` WHERE `SpellId` = 270804;
DELETE FROM `spell_bonus_data` WHERE `entry` = 270806;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(270806, 0.45, 0, 0.30, 0, 'Spell Slinger - Arcane Clearcasting consumption burst');
COMMIT;
