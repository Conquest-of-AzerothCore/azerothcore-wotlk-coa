START TRANSACTION;
DELETE FROM `spell_script_names` WHERE `spell_id` = 271126 AND `ScriptName` = 'aura_wildcard_flashpoint';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (271126, 'aura_wildcard_flashpoint');
DELETE FROM `spell_proc` WHERE `SpellId` IN (271126, 271121);
INSERT INTO `spell_proc` (`SpellId`, `SpellFamilyName`, `SpellFamilyMask0`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `Chance`, `Charges`) VALUES
(271126, 0, 0, 332116, 1, 2, 3, 2, 100, 0),
(271121, 3, 4194304, 65536, 1, 4, 0, 0, 100, 1);
COMMIT;
