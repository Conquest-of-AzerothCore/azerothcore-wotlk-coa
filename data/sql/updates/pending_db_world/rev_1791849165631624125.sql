-- Warcraft Reborn Paladin: Exorcism, Holy Shock, Seal of Righteousness, Heart of the Crusader and Light's Grace do
-- what their tooltips say.
DELETE FROM `spell_bonus_data` WHERE `entry` = 1100879;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(1100879, 0.15, 0, 0.15, 0, 'Warcraft Reborn Paladin - Exorcism');

DELETE FROM `spell_script_names` WHERE `spell_id` IN (-1120473, 1121084, 1120337) AND `ScriptName` IN
('spell_pal_holy_shock', 'spell_pal_seal_of_righteousness', 'spell_pal_heart_of_the_crusader');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(-1120473, 'spell_pal_holy_shock'),
(1121084, 'spell_pal_seal_of_righteousness'),
(1120337, 'spell_pal_heart_of_the_crusader');

DELETE FROM `spell_proc` WHERE `SpellId` IN (1121084, 1120337, -1131833);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`,
`SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(1121084, 0, 0, 0, 0, 0, 20, 1, 2, 0, 2, 0, 0, 100, 0, 0),
(1120337, 0, 10, 8388608, 0, 0, 16, 5, 2, 0, 0, 0, 0, 100, 0, 0),
(-1131833, 0, 10, 2147483648, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0);
