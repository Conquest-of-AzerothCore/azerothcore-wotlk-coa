START TRANSACTION;
DELETE FROM `spell_proc` WHERE `SpellId` IN (277160, 278135);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(277160, 0, 0, 0, 0, 0, 87312, 7, 4, 0, 0, 6, 0, 100, 0, 0),
(278135, 0, 0, 0, 0, 0, 87312, 7, 4, 0, 0, 6, 0, 100, 0, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` = 277160 AND `ScriptName` = 'aura_wildcard_card_restoration';
DELETE FROM `spell_script_names` WHERE `spell_id` = 278135 AND `ScriptName` = 'aura_wildcard_card_restoration';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(277160, 'aura_wildcard_card_restoration'),
(278135, 'aura_wildcard_card_restoration');
COMMIT;
