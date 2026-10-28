-- Skum's Overrun (2102624, a dummy in the DBC): run 25 yards ahead and trample (CoADungeonBossSpells.cpp)
DELETE FROM `spell_script_names` WHERE `spell_id` = 2102624;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (2102624, 'spell_coa_skum_overrun');
