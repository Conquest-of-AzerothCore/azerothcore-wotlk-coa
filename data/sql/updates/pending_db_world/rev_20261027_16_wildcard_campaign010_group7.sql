START TRANSACTION;
DELETE FROM `spell_script_names` WHERE `spell_id` = 270699 AND `ScriptName` = 'aura_wildcard_crushing_charge';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (270699, 'aura_wildcard_crushing_charge');
DELETE FROM `spell_proc` WHERE `SpellId` = 270699;
INSERT INTO `spell_proc` (`SpellId`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `Cooldown`, `Chance`) VALUES
(270699, 16, 1, 2, 3, 2, 3000, 100);
COMMIT;
