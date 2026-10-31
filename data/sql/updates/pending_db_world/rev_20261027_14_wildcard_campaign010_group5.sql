START TRANSACTION;
DELETE FROM `spell_script_names` WHERE `spell_id` = 270561 AND `ScriptName` = 'aura_wildcard_dominant_shield';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (270561, 'aura_wildcard_dominant_shield');
DELETE FROM `spell_proc` WHERE `SpellId` = 270561;
INSERT INTO `spell_proc` (`SpellId`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `Chance`) VALUES
(270561, 69904, 1, 2, 3, 2, 100);
COMMIT;
