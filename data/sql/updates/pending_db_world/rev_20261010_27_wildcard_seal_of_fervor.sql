-- Seal of Fervor 272087 copies Seal of Righteousness 21084 (DBC ProcFlags 0x14, judgement in its effect 2 dummy) but
-- had neither its spell_proc row nor a script, so main hand auto attacks and Paladin melee abilities dealt no Fire
-- damage. Each now deals Seal of Fervor 272085 for the tooltip's 1 + MWS * (0.0085 * AP + 0.072 * SP).
DELETE FROM `spell_proc` WHERE `SpellId` = 272087;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(272087, 0, 0, 0, 0, 0, 0, 0x1, 0x2, 0, 0x2, 0, 0, 0, 0, 0);

DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_wildcard_seal_of_fervor';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(272087, 'aura_wildcard_seal_of_fervor');
