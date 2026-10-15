-- Blood Binding 805200 ships ProcFlags 0, and no proc flag expresses "Scythe Rush directly after Cull". The Reaper's
-- next non-triggered cast after Cull 800930 or 800940 is checked in C++; when it is Scythe Rush 500359, 801334
-- strikes nearby enemies and this script roots each one it hits with 802752 for 3 sec.
DELETE FROM `spell_script_names` WHERE `spell_id` = 801334 AND `ScriptName` = 'spell_ascension_reaper_blood_binding_damage';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(801334, 'spell_ascension_reaper_blood_binding_damage');
