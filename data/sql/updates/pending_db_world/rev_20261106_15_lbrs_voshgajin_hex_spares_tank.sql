-- Lower Blackrock Spire: Shadow Hunter Vosh'gajin's Hex hits everyone around her except her current target (#11385).
DELETE FROM `spell_script_names` WHERE `spell_id` = 16097 AND `ScriptName` = 'spell_blackrock_spire_voshgajin_hex';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (16097, 'spell_blackrock_spire_voshgajin_hex');
