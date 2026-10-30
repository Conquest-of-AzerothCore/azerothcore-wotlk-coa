-- Reborn Blazing Speed (1131641, 1131642) twins stock 31641 but is redesigned: a 50% or 100% chance when hit by a melee
-- attack for more than 5% of maximum health, granting the Reborn buff 1131643 (6 sec). It kept no proc flags, and the
-- stock script it would inherit casts stock 31643 (8 sec) on any melee or ranged hit. Its rows take melee hits only, and
-- its own script checks the damage and casts the Reborn buff.
DELETE FROM `spell_proc` WHERE `SpellId` IN (1131641, 1131642);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(1131641, 0, 0, 0, 0, 0, 0x28, 0x1, 0x2, 0, 0, 0, 0, 0, 0, 0),
(1131642, 0, 0, 0, 0, 0, 0x28, 0x1, 0x2, 0, 0, 0, 0, 0, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` IN (1131641, 1131642);
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1131641, 'spell_ascension_reborn_blazing_speed'),
(1131642, 'spell_ascension_reborn_blazing_speed');
