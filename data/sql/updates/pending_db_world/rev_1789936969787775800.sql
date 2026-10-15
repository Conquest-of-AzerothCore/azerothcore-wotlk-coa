--
-- Bloody Claws (#1936): the native pet area aura reacts to positive pet damage.
DELETE FROM `spell_proc` WHERE `SpellId` = 504874;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(504874, 0, 0, 0, 0, 0, 332116, 1, 2, 3, 2, 0, 0, 100, 0, 0);
SET @ScriptName = 'aura_ascension_primalist_bloody_claws';
DELETE FROM `spell_script_names` WHERE `spell_id` = 504874 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (504874, @ScriptName);
