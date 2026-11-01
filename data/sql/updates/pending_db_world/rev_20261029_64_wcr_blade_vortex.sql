-- Warcraft Reborn Blade Vortex (enchant 1235768): damaging melee finishing moves, 20% per combo point, cut Blade
-- Flurry's cooldown by 5 sec and, under Blade Flurry, create a Blade Vortex (spell_ascension_mystic_blade_vortex).
DELETE FROM `spell_proc` WHERE `SpellId` = 1589904;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(1589904, 0, 8, 0, 0, 0, 0x10, 1, 0x2, 0, 0, 0, 0, 100, 0, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` = 1589904;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (1589904, 'spell_ascension_mystic_blade_vortex');
