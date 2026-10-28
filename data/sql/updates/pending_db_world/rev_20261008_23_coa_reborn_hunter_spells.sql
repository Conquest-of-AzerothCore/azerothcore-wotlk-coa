-- Warcraft Reborn Hunter spells whose stock twins are built differently.
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((1119577, 'spell_hun_intimidation'), (1134477, 'spell_hun_misdirection'), (-1156342, 'spell_hun_lock_and_load'), (-1119184, 'spell_ascension_reborn_proc_trigger_spell'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1119577, 'spell_hun_intimidation'),
(1134477, 'spell_hun_misdirection'),
(-1156342, 'spell_hun_lock_and_load'),
(-1119184, 'spell_ascension_reborn_proc_trigger_spell');

DELETE FROM `spell_proc` WHERE `SpellId` IN (1134477, -1156342, -1119184);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
SELECT 1134477, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges` FROM `spell_proc` WHERE `SpellId` = 34477;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
SELECT -1156342, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges` FROM `spell_proc` WHERE `SpellId` = -56342;
-- Entrapment procs when a Frost Trap or Snake Trap activates (PROC_FLAG_DONE_TRAP_ACTIVATION).
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(-1119184, 0, 9, 16, 8192, 0, 2097152, 0, 4, 0, 2, 0, 0, 0, 0, 0);
