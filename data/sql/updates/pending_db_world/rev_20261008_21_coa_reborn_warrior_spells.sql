-- Warcraft Reborn Warrior spells whose stock twins are built differently.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (-1100100, 1107384, 1112328, -1112311, 1146968, 1988256, -1101464) AND `ScriptName` IN
('spell_warr_charge', 'spell_warr_overpower', 'spell_warr_sweeping_strikes', 'spell_ascension_reborn_proc_trigger_spell',
'spell_ascension_reborn_shockwave', 'spell_ascension_reborn_single_minded_fury', 'spell_ascension_reborn_single_minded_fury_slam',
'spell_warr_slam');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(-1100100, 'spell_warr_charge'),
(1107384, 'spell_warr_overpower'),
(1112328, 'spell_warr_sweeping_strikes'),
(-1112311, 'spell_ascension_reborn_proc_trigger_spell'),
(1146968, 'spell_ascension_reborn_shockwave'),
(1988256, 'spell_ascension_reborn_single_minded_fury'),
(-1101464, 'spell_ascension_reborn_single_minded_fury_slam'),
(-1101464, 'spell_warr_slam');

DELETE FROM `spell_proc` WHERE `SpellId` IN (-1112311, 1112328);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`,
`SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
SELECT -1112311, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`,
`SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges` FROM `spell_proc` WHERE `SpellId` = -12311;
-- The stock 3.3.5 Sweeping Strikes row, not 12328's: Ascension reshaped 12328 to proc on melee abilities only, while the
-- Reborn spell keeps the DBC's melee swings and abilities (ProcFlags 0 = from the DBC) and its 5 charges.
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`,
`SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(1112328, 0, 4, 0, 0, 0, 0, 1, 2, 0, 2, 0, 0, 0, 0, 0);
