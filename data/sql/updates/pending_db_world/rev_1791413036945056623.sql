-- Runemaster Weapon Engravings (#6088): normal Water and Arcane enchants were inert.
-- Water enchant 1001 equips dummy 653214; its tooltip names proc helper 653216 (30%).
-- Arcane enchant 1006 equips 653267 (40%), but neither helper had a native proc entry.
-- Match the direct-damage filters of Fire/Earth/Ice. Chance 0 preserves the DBC chance
-- and normal Master Engraver/Zenith modifiers. Arcane promises a 5-second internal cooldown.
DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 653214 AND `spell_effect` = 653216 AND `type` = 2;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(653214, 653216, 2, 'CoA Water Engraving - Weapon Engraving: Water proc aura');

DELETE FROM `spell_proc` WHERE `SpellId` IN (653216, 653267);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(653216, 0, 0, 0, 0, 0, 0x00010154, 0x1, 0x2, 0, 0, 0, 0, 0, 0, 0),
(653267, 0, 0, 0, 0, 0, 0x00010154, 0x1, 0x2, 0, 0, 0, 0, 0, 5000, 0);
