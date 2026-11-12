-- Testament of Resolve reads "granting immunity to fear, charm, and horrify effects". Owner ruling 2026-11-12 (Q2):
-- charm means mind control, granted in Templar code; the lifecycle script adds the charm and possess immunities.
DELETE FROM `spell_script_names` WHERE `spell_id` = 804228 AND `ScriptName` = 'aura_ascension_templar_lifecycle';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (804228, 'aura_ascension_templar_lifecycle');
