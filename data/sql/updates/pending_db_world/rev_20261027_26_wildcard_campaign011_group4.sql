START TRANSACTION;
DELETE FROM `spell_script_names` WHERE `spell_id` = 271941 AND `ScriptName` IN ('spell_ascension_mystic_enchant_proc', 'aura_wildcard_glacial_pact');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (271941, 'aura_wildcard_glacial_pact');
DELETE FROM `spell_proc` WHERE `SpellId` = 271941;
INSERT INTO `spell_proc` (`SpellId`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `AttributesMask`, `Chance`) VALUES
(271941, 87312, 0, 4, 0, 100);
DELETE FROM `spell_script_names` WHERE `spell_id` = 275089 AND `ScriptName` = 'aura_wildcard_pack_tactics';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (275089, 'aura_wildcard_pack_tactics');
COMMIT;
