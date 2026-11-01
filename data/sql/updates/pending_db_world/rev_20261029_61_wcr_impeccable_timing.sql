-- Warcraft Reborn Impeccable Timing (enchant 1235926): the enchant's periodic trigger grants Impeccable Timing every
-- 10 sec (spell_ascension_mystic_impeccable_timing); while it lasts, the next spell that can trigger Missile Barrage
-- (the stock talent's mask) triggers it, which uses it up.
DELETE FROM `spell_script_names` WHERE `spell_id` = 1584079 AND `ScriptName` = 'spell_ascension_mystic_impeccable_timing';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (1584079, 'spell_ascension_mystic_impeccable_timing');

DELETE FROM `spell_proc` WHERE `SpellId` = 1584081;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(1584081, 0, 3, 0x20000021, 0x9000, 0, 0x10000, 1, 2, 0, 0, 0, 0, 100, 0, 1);
