-- Warcraft Reborn Warlock spells whose stock twins are built differently.
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((-1127243, 'spell_warl_seed_of_corruption_dummy'), (-1148181, 'spell_warl_haunt'), (-1154347, 'spell_warl_improved_demonic_tactics'), (-1163156, 'spell_warl_decimation'), (1118094, 'spell_warl_nightfall'), (1118095, 'spell_warl_nightfall'), (-1118213, 'spell_warl_improved_drain_soul'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(-1127243, 'spell_warl_seed_of_corruption_dummy'),
(-1148181, 'spell_warl_haunt'),
(-1154347, 'spell_warl_improved_demonic_tactics'),
(-1163156, 'spell_warl_decimation'),
(1118094, 'spell_warl_nightfall'),
(1118095, 'spell_warl_nightfall'),
(-1118213, 'spell_warl_improved_drain_soul');

DELETE FROM `spell_proc` WHERE `SpellId` IN (-1127243, -1163156, -1118094);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
SELECT -1127243, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges` FROM `spell_proc` WHERE `SpellId` = -27243;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
SELECT -1163156, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges` FROM `spell_proc` WHERE `SpellId` = -63156;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
SELECT -1118094, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges` FROM `spell_proc` WHERE `SpellId` = -18094;
