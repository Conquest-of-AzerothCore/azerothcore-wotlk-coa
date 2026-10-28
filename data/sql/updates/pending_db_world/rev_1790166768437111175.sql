-- Packleader (504290) applies its native damage aura to summons when a Howl is cast. The shared family mask
-- also includes Blood Craving (800780), so the aura script rejects that source spell.
DELETE FROM `spell_proc` WHERE `SpellId` = 504290;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(504290, 0, 26, 0, 4, 133248, 81936, 0, 1, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 504290 AND `ScriptName` = 'aura_ascension_bloodmage_packleader';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(504290, 'aura_ascension_bloodmage_packleader');
