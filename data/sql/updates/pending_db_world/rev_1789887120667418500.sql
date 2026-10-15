-- Bestial Wrath (#561): distribute the authored pet listener through the native pet-aura lifecycle.
DELETE FROM `spell_pet_auras` WHERE `spell` = 803347 AND `effectId` = 1 AND `pet` = 0;
INSERT INTO `spell_pet_auras` (`spell`, `effectId`, `pet`, `aura`) VALUES
(803347, 1, 0, 803349);

-- Owner critical damage restores pet Focus; pet critical damage restores owner Mana and debuffs the victim.
-- Include native direct/periodic damage and triggered pet abilities, while excluding healing and dummy slots.
DELETE FROM `spell_proc` WHERE `SpellId` IN (803347, 803349);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(803347, 0, 0, 0, 0, 0, 332116, 1, 2, 2, 2, 2, 0, 100, 0, 0),
(803349, 0, 0, 0, 0, 0, 332116, 1, 2, 2, 2, 4, 0, 100, 0, 0);
