START TRANSACTION;
DELETE FROM `spell_proc` WHERE `SpellId` IN (284374, 271746, 281701);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(284374, 0, 0, 0, 0, 0, 69904, 7, 2, 1, 2, 6, 0, 100, 0, 0),
(271746, 0, 0, 0, 0, 0, 256, 1, 2, 3, 2, 6, 0, 100, 0, 0),
(281701, 0, 0, 0, 0, 0, 87312, 7, 4, 0, 0, 6, 0, 100, 0, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` = 281705 AND `ScriptName` = 'aura_wildcard_shaken_spread';
DELETE FROM `spell_script_names` WHERE `spell_id` = 284374 AND `ScriptName` = 'aura_wildcard_card_restoration';
DELETE FROM `spell_script_names` WHERE `spell_id` = 271746 AND `ScriptName` = 'aura_wildcard_card_restoration';
DELETE FROM `spell_script_names` WHERE `spell_id` = 281701 AND `ScriptName` = 'aura_wildcard_card_restoration';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(281705, 'aura_wildcard_shaken_spread'),
(284374, 'aura_wildcard_card_restoration'),
(271746, 'aura_wildcard_card_restoration'),
(281701, 'aura_wildcard_card_restoration');
COMMIT;
