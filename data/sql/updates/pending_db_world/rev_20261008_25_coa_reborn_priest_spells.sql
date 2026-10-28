-- Warcraft Reborn Priest spells whose stock twins are built differently.
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((-1147540, 'spell_ascension_reborn_penance'), (-1147569, 'spell_pri_imp_shadowform'), (1147569, 'spell_pri_improved_shadowform'), (1147570, 'spell_pri_improved_shadowform'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(-1147540, 'spell_ascension_reborn_penance'),
(-1147569, 'spell_pri_imp_shadowform'),
(1147569, 'spell_pri_improved_shadowform'),
(1147570, 'spell_pri_improved_shadowform');

DELETE FROM `spell_proc` WHERE `SpellId` = -1147569;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
SELECT -1147569, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges` FROM `spell_proc` WHERE `SpellId` = -47569;
