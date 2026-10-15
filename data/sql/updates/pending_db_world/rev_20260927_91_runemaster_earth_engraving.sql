-- Runemaster Weapon Engraving: Earth. Enchant 1002 equips Earth Engraving 653219, whose description reads "Your
-- direct damage has a $653221h% chance to deal ... Nature damage": its own effects are a dummy and a zero spell
-- modifier. The chance and the trigger of Weapon Engraving: Earth 653272 belong to 653221 ("Passive2", aura 42,
-- ProcChance 15), which nothing applied and whose Spell.dbc ProcFlags are 0. Earthen Fists 806982, Terraglyphs
-- 705551 and Volcanic Etching 705615 raise the proc chance of 653221 (family 38 mask2 0x2000000, unique to it).
-- 653221 now follows 653219 on and off the Runemaster, and procs like Fire Engraving 653211 on done auto attacks
-- and melee, ranged and magic damage spells on hit; Chance 0 keeps the Spell.dbc 15%.
DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 653219 AND `spell_effect` = 653221 AND `type` = 2;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(653219, 653221, 2, 'CoA Earth Engraving - Weapon Engraving: Earth proc aura');

-- Steam Conjurer 805743 (Runic talent): "Damage dealt by Weapon Engraving: Earth now has a $h% chance to cast Wild
-- Steam. Can only occur once every 3 sec." ProcFlags 0 in Spell.dbc, so it never procced. 653272 (family 38 mask1
-- 0x20000, unique to it) is a magic Nature SCHOOL_DAMAGE spell that is always cast by the Earth Engraving proc,
-- hence TRIGGERED_CAN_PROC; Chance 0 keeps the Spell.dbc 5%, with a 3 sec internal cooldown.
DELETE FROM `spell_proc` WHERE `SpellId` IN (653221, 805743);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(653221, 0, 0, 0, 0, 0, 0x00010154, 0x1, 0x2, 0, 0, 0, 0, 0, 0, 0),
(805743, 0, 38, 0, 0x00020000, 0, 0x00010000, 0x1, 0x2, 0, 0x2, 0, 0, 0, 3000, 0);
