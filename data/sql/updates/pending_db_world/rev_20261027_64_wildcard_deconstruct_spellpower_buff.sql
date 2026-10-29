-- Deconstruct 283344/954082 (talented via Deconstruction 283343, @req:20243@) sunders armor and deals weapon
-- damage natively (SpellFamilyFlags[1] 0x40 reuses the Devastate hack in Spell::EffectWeaponDmg), but never cast
-- Deconstruction 954083, so the caster never gained its +SP buff even though the Sunder Armor stacking worked.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_wildcard_deconstruct';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(283344, 'spell_wildcard_deconstruct'),
(954082, 'spell_wildcard_deconstruct');
