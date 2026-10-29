-- Warcraft Reborn Mystic Enchants, one-off mechanics (AscensionMysticEnchantMechanics.cpp), continued: Ice Barrage
-- 1570523 (Frostbolt and Frostfire Bolt damage stores Icicles, Ice Lance damage launches them) and Wrathful Strikes
-- 1572261 (Predator's Wrath: your direct physical abilities add the Nature damage 1572264). Blood-Soaked Mutilation and
-- Predator's Wrath's Wrath in Cat Form are AllSpellScripts with no rows.
DELETE FROM `spell_proc` WHERE `SpellId` IN (1570523, 1572261);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(1570523, 0, 3, 0x00020020, 0x00001000, 0x00000000, 0x10000, 1, 0x2, 0x3, 0x0, 0, 0, 100, 0, 0),
(1572261, 0, 0, 0x00000000, 0x00000000, 0x00000000, 0x10, 1, 0x2, 0x3, 0x0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 1570523 AND `ScriptName` = 'spell_ascension_mystic_ice_barrage';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1570523, 'spell_ascension_mystic_ice_barrage');
