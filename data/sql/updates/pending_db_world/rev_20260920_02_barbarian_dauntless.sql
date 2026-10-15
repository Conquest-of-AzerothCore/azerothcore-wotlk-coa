-- Barbarian: Dauntless (804746) triggers from Whirling Advance damage instead of auto attacks.
DELETE FROM `spell_proc` WHERE `SpellId` = 804746;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(804746, 0, 0, 0, 0, 0, 69972, 1, 2, 9283, 2, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 804746 AND `ScriptName` = 'aura_ascension_barbarian_event';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (804746, 'aura_ascension_barbarian_event');
