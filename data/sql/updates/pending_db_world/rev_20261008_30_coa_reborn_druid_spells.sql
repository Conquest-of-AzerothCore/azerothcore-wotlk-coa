-- Warcraft Reborn Druid spells whose stock twins are built differently.
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((-1116972, 'spell_dru_predatory_strikes'), (-1117002, 'spell_dru_feral_swiftness'), (1105487, 'spell_dru_feral_swiftness'), (1109634, 'spell_dru_feral_swiftness'), (-1133763, 'spell_dru_lifebloom'), (1161336, 'spell_dru_survival_instincts'), (-1148516, 'spell_ascension_reborn_eclipse'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(-1116972, 'spell_dru_predatory_strikes'),
(-1117002, 'spell_dru_feral_swiftness'),
(1105487, 'spell_dru_feral_swiftness'),
(1109634, 'spell_dru_feral_swiftness'),
(-1133763, 'spell_dru_lifebloom'),
(1161336, 'spell_dru_survival_instincts'),
(-1148516, 'spell_ascension_reborn_eclipse');

DELETE FROM `spell_proc` WHERE `SpellId` = -1148516;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
SELECT -1148516, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges` FROM `spell_proc` WHERE `SpellId` = -48516;
