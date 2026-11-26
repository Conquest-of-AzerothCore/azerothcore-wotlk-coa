-- #13528, #13668 Barbarian: Spirit of Bloodshed aura target filter and Born in Blood proc chance
START TRANSACTION;

DELETE FROM `spell_script_names` WHERE `spell_id` = 712681 AND `ScriptName` = 'spell_ascension_spirit_of_bloodshed_aura';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(712681, 'spell_ascension_spirit_of_bloodshed_aura');

DELETE FROM `spell_proc` WHERE `SpellId` = 712468;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(712468, 0, 0, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 100, 0, 0);

COMMIT;
