-- Runemaster Burned Etching 500476 (#1877): "While Weapon Engraving: Fire is active, your Elemental Burst now deals
-- $s1% increased damage as Fire damage and your chance to trigger Weapon Engraving: Fire is increased by
-- $500475s2%." The talent's only effect is a PROC_TRIGGER_SPELL of 500475 with Spell.dbc ProcFlags 0, so nothing
-- applied 500475. runemaster_burned_etching_engraving keeps 500475 on the Runemaster while both the talent and Fire
-- Engraving 653211 (the equip spell of the Weapon Engraving: Fire enchant 1000) are active. Its effect 1 is the
-- native +5 SPELLMOD_CHANCE_OF_SUCCESS on Fire Engraving; its effect 0 (Ascension aura 354, 10%, trigger 500474)
-- has ProcFlags 0 too: Elemental Burst hits (family 38 mask2 0x20000, magic class) now deal 10% of their damage
-- again as the Fire hit 500474. Chance 0 keeps the Spell.dbc 100%; the modifier effect does not proc.
DELETE FROM `spell_proc` WHERE `SpellId` = 500475;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(500475, 0, 38, 0, 0, 0x00020000, 0x00010000, 0x1, 0x2, 0, 0, 0x2, 0, 0, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 500475
    AND `ScriptName` = 'aura_ascension_runemaster_burned_etching';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(500475, 'aura_ascension_runemaster_burned_etching');
