-- Runemaster Convergence (801086): the next 10 Weapon Engravings triggered within 15 sec deal additional Elemental
-- damage (560241) to their target; each engraving consumes one charge.
DELETE FROM `spell_proc` WHERE `SpellId` = 801086;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(801086, 0, 38, 0x00020000, 0, 0, 0x00010000, 0x7, 0x2, 0, 0x2, 0x2, 0, 100, 0, 10);

DELETE FROM `spell_script_names` WHERE `spell_id` = 801086 AND `ScriptName` = 'aura_ascension_runemaster_convergence';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(801086, 'aura_ascension_runemaster_convergence');
