DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 653223 AND `spell_effect` = 653225 AND `type` = 2;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(653223, 653225, 2, 'CoA Air Engraving - direct damage copies and casting haste');

DELETE FROM `spell_proc` WHERE `SpellId` = 653225;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(653225, 0, 0, 0, 0, 0, 0x00010154, 0x1, 0x2, 0, 0, 0x4, 0, 0, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 653225
    AND `ScriptName` = 'aura_ascension_runemaster_air_engraving';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(653225, 'aura_ascension_runemaster_air_engraving');
