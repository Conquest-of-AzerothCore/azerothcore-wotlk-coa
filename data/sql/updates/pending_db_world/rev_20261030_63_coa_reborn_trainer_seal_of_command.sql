-- The trainer's Seal of Command (1470375-1470379) is a copy of the Reborn talent seal (1120375-1120379) at an id no twin
-- rule reaches, so it had no proc entry or script and never struck. Each rank takes stock 20375's row, with the melee
-- hit proc flags stock's Spell.dbc supplies, and the stock script.
DELETE FROM `spell_proc` WHERE `SpellId` IN (1470375, 1470376, 1470377, 1470378, 1470379);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(1470375, 0, 10, 0, 0x00168000, 0, 0x4, 0x1, 0x2, 0, 0, 0, 0, 100, 0, 0),
(1470376, 0, 10, 0, 0x00168000, 0, 0x4, 0x1, 0x2, 0, 0, 0, 0, 100, 0, 0),
(1470377, 0, 10, 0, 0x00168000, 0, 0x4, 0x1, 0x2, 0, 0, 0, 0, 100, 0, 0),
(1470378, 0, 10, 0, 0x00168000, 0, 0x4, 0x1, 0x2, 0, 0, 0, 0, 100, 0, 0),
(1470379, 0, 10, 0, 0x00168000, 0, 0x4, 0x1, 0x2, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` IN (1470375, 1470376, 1470377, 1470378, 1470379);
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1470375, 'spell_pal_seal_of_command'),
(1470376, 'spell_pal_seal_of_command'),
(1470377, 'spell_pal_seal_of_command'),
(1470378, 'spell_pal_seal_of_command'),
(1470379, 'spell_pal_seal_of_command');
