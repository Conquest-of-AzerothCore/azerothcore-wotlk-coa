START TRANSACTION;
DELETE FROM `spell_script_names` WHERE `spell_id` = 277162 AND `ScriptName` = 'aura_wildcard_bloody_business';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (277162, 'aura_wildcard_bloody_business');
DELETE FROM `spell_script_names` WHERE `spell_id` = 288985 AND `ScriptName` = 'aura_wildcard_virulent_dominion';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (288985, 'aura_wildcard_virulent_dominion');
DELETE FROM `spell_proc` WHERE `SpellId` IN (277162, 288985, 288988);
INSERT INTO `spell_proc` (`SpellId`, `SpellFamilyName`, `SpellFamilyMask1`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `Chance`, `Charges`) VALUES
(277162, 0, 0, 87312, 0, 4, 0, 0, 2, 100, 0),
(288985, 0, 0, 87312, 0, 6, 0, 2, 1, 100, 0),
(288988, 15, 100663296, 524288, 1, 2, 3, 2, 0, 100, 1);
COMMIT;
