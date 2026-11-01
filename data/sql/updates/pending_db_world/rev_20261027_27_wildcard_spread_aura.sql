START TRANSACTION;
DELETE FROM `spell_script_names` WHERE `spell_id` = 281749 AND `ScriptName` = 'aura_wildcard_blaze';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (281749, 'aura_wildcard_blaze');
DELETE FROM `spell_proc` WHERE `SpellId` = 281749;
INSERT INTO `spell_proc` (`SpellId`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `AttributesMask`, `Chance`) VALUES
(281749, 69632, 0, 4, 0, 100);
COMMIT;
